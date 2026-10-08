class_name SchismSimulation
extends RefCounted

const SCHEMA = 3
const JOB_SCENES = {"laundry":"laundry", "cleaning":"cleaning", "freight":"freight"}
const ROUTES = {
 "room":["hall"], "hall":["room","street"],
 "street":["hall","bureau","laundry","cleaning","freight","shop"],
 "bureau":["street"], "laundry":["street"], "cleaning":["street"],
 "freight":["street"], "shop":["street"], "camp":[]
}

static func catalog() -> Dictionary:
 return JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))

static func initial() -> Dictionary:
 return {
  "schema":SCHEMA, "revision":0, "sequence":0, "serial":0, "rng":48193,
  "identity":{"name":"William","civic_id":"48193","registered":false,"appearance":"olive"},
  "needs":{"hunger":52.0,"thirst":46.0,"energy":58.0,"hygiene":48.0,"health":91.0},
  "credits":4, "illicit_credits":0, "tax_remainder":0, "tax_paid":0,
  "minute":360, "location":"room", "arrival_seen":false,
  "employment":"", "jobs":{"laundry":{"shifts":0,"trust":0,"warnings":0,"promoted":false},"cleaning":{"shifts":0,"trust":0,"warnings":0,"promoted":false},"freight":{"shifts":0,"trust":0,"warnings":0,"promoted":false}},
  "housing":{"tier":"municipal","address":"Block C / Room 17","rent":0,"deposit":0,"next_bill":1440,"arrears":0,"bills":0,"utilities":true},
  "items":[], "room_upgrades":[], "shift":{}, "ticket":false,"id_shown":false,
  "legal":{"suspicion":0,"offenses":0,"record":[],"camp":{}},
  "discoveries":["room"], "events":[], "decisions":[], "relief_day":-1,
  "settings":{"sound":true,"effects":true,"hints":true}, "last_receipt":{}
 }

static func migrate(old: Dictionary) -> Dictionary:
 if int(old.get("schema",1)) > SCHEMA:
  return {"error":"This save needs a newer SCHISM version. Your files have been preserved."}
 var s = old.duplicate(true)
 var defaults = initial()
 _defaults(s, defaults)
 s.schema = SCHEMA
 return s

static func _defaults(s: Dictionary, defaults: Dictionary) -> void:
 for key in defaults:
  if not s.has(key): s[key] = defaults[key].duplicate(true) if defaults[key] is Dictionary or defaults[key] is Array else defaults[key]
  elif s[key] is Dictionary and defaults[key] is Dictionary: _defaults(s[key],defaults[key])

static func apply(before: Dictionary, cmd: Dictionary) -> Dictionary:
 var s = before.duplicate(true)
 var events: Array = []
 var error = _execute(s,cmd,events)
 if error != "": return {"ok":false,"error":error,"state":before}
 s.revision = int(before.revision)+1
 s.sequence = int(before.sequence)+1
 for e in events:
  e["id"] = str(s.identity.civic_id)+":"+str(s.sequence)+":"+str(s.events.size())
  e["minute"] = s.minute
  s.events.append(e)
 if s.events.size()>120: s.events = s.events.slice(-120)
 _threshold_thought(before,s,events)
 return {"ok":true,"state":s,"events":events}

static func _execute(s: Dictionary, c: Dictionary, e: Array) -> String:
 var action = str(c.get("action",""))
 if c.has("expected_revision") and int(c.expected_revision)!=int(s.revision): return "Your record changed. Try the object again."
 if action=="register":
  if s.identity.registered: return "Your residency is already registered."
  var name = str(c.get("name","")).strip_edges()
  if name.length()<2 or name.length()>24: return "Use a name of 2–24 characters."
  if str(c.get("appearance","olive")) not in ["olive","umber","sand"]: return "Choose an available appearance."
  s.identity.name = name; s.identity.appearance = c.get("appearance","olive"); s.identity.registered = true
  e.append({"type":"thought","text":"I need to find work."})
  return ""
 if not s.identity.registered: return "Complete the residency paper first."
 if action=="setting":
  if str(c.get("key","")) not in ["sound","effects","hints"] or not c.get("value") is bool: return "Unknown setting."
  s.settings[c.key] = c.value
  return ""
 var camp_active = not s.legal.camp.is_empty() and s.legal.camp.get("active",false)
 if camp_active and action not in ["camp_sort","camp_order","camp_meal","camp_sleep","camp_release"]: return "Your belongings and outside work are held until release."
 match action:
  "arrival": s.arrival_seen = true
  "travel":
   if not s.shift.is_empty(): return "Finish this work order before leaving."
   var target = str(c.get("to",""))
   if target not in ROUTES.get(s.location,[]): return "There is no doorway there."
   s.location = target
   if target not in s.discoveries: s.discoveries.append(target)
   _advance(s,5)
  "ticket":
   if s.location!="bureau": return "The dispenser is at the labor bureau."
   s.ticket = true
  "show_id":
   if s.location!="bureau" or not s.ticket: return "Take a ticket first."
   s.id_shown = true
  "apply_job":
   if s.location!="bureau" or not s.id_shown: return "Present identification at window 3."
   if not s.shift.is_empty(): return "Finish your current work order."
   var job = str(c.get("job",""))
   if not catalog().jobs.has(job): return "This vacancy does not exist."
   s.employment = job
   e.append({"type":"thought","text":"It'll have to do."})
  "begin_shift":
   var job = s.employment
   if not JOB_SCENES.has(job) or s.location!=JOB_SCENES[job]: return "This workplace needs its own work authorization. Visit window 3."
   if not s.shift.is_empty(): return "Your work order is already on the bench."
   if s.needs.energy<22 or s.needs.health<20: return "I need some rest before I can work."
   _begin_shift(s,job)
  "inspect_uniform", "inspect_pocket", "sort_uniform", "open_hatch", "load_washer", "dose", "cycle", "close_hatch", "start_wash", "unload", "dry", "fold", "dispatch":
   return _laundry(s,c,e)
  "found_choice": return _found_choice(s,c,e)
  "clean": return _cleaning(s,c,e)
  "inspect_crate", "route_crate", "open_crate", "manifest": return _freight(s,c,e)
  "settle_shift": return _settle(s,e)
  "buy":
   if s.location!="shop" or not s.shift.is_empty(): return "The vendor is at the food kiosk."
   var kind = str(c.get("kind","")); var goods = catalog().items
   if not goods.has(kind): return "The vendor doesn't stock that."
   if goods[kind].get("upgrade",false) and (kind in s.room_upgrades or not _owned(s,kind).is_empty()): return "I already have one."
   if s.credits<int(goods[kind].price): return "Not enough credits."
   s.credits -= int(goods[kind].price)
   _item(s,kind,goods[kind].label,"player","Food kiosk",goods[kind])
   e.append({"type":"sound","name":"coin"})
  "consume": return _consume(s,str(c.get("id","")),e)
  "install":
   if s.location!="room" or not s.shift.is_empty(): return "Put it in your room when you're home."
   var item = _find(s,str(c.get("id","")))
   if item.is_empty() or item.owner!="player" or not catalog().items.get(item.kind,{}).get("upgrade",false): return "That isn't a room possession you own."
   if item.kind in s.room_upgrades: return "It's already in place."
   item.owner = "room"; s.room_upgrades.append(item.kind)
   item.history.append({"minute":s.minute,"custody":"room"})
   e.append({"type":"thought","text":"It's small... but it's mine." if item.kind=="kettle" else "That makes a difference."})
  "drink":
   if s.location not in ["room","street","laundry"]: return "There's no public tap here."
   if s.location=="room" and not s.housing.utilities: return "The tap is dry. The public tap still works."
   var thirsty = s.needs.thirst<25
   _advance(s,5); s.needs.thirst = minf(100,s.needs.thirst+50)
   e.append({"type":"thought","text":"Better." if thirsty else "Cold. Tastes of pipes."})
  "wash":
   if s.location!="room": return "Use the sink in your room."
   var soap = _owned(s,"soap")
   var gain = 13 if soap.is_empty() else 42
   if not soap.is_empty():
    soap.metadata.uses = int(soap.metadata.get("uses",3))-1
    if soap.metadata.uses<=0: soap.owner = "consumed"
   _advance(s,15); s.needs.hygiene = minf(100,s.needs.hygiene+gain)
   e.append({"type":"thought","text":"At least I feel human."})
  "sleep":
   if s.location!="room" or not s.shift.is_empty(): return "I need to go home first."
   _advance(s,480,true)
   s.needs.energy = minf(100,s.needs.energy+(80 if "blanket" in s.room_upgrades else 68)+(8 if s.housing.tier!="municipal" else 0))
   if s.needs.hunger>20 and s.needs.thirst>20: s.needs.health = minf(100,s.needs.health+4)
   e.append({"type":"thought","text":"I'm done."})
  "relief":
   if s.location!="shop" or s.credits>2: return "The meal chit is for citizens with two credits or less."
   var day = int(s.minute/1440)
   if s.relief_day==day: return "One emergency ration each day. Water remains free."
   s.relief_day = day; s.needs.hunger = maxf(s.needs.hunger,45); s.needs.energy = maxf(s.needs.energy,24); s.needs.health = maxf(s.needs.health,25)
   e.append({"type":"thought","text":"I ate. That's something."})
  "promote":
   if s.location!="bureau" or not catalog().jobs.has(s.employment): return "Look at the internal vacancy notice at the bureau."
   var record = s.jobs[s.employment]
   if record.shifts<12: return "Twelve completed shifts are required."
   if record.promoted: return "Your appointment is already recorded."
   record.promoted = true
   _item(s,"key",catalog().jobs[s.employment].key,"player","Employment appointment",{"certification":s.employment})
   e.append({"type":"thought","text":"They gave me a key."})
  "rent":
   if s.location!="bureau" or not s.shift.is_empty(): return "Tenancy is handled at the bureau."
   var tier = str(c.get("tier",""))
   if tier=="municipal":
    s.housing.tier = tier; s.housing.address = "Block C / Room 17"; s.housing.rent = 0; s.housing.next_bill = (int(s.minute/1440)+1)*1440
   elif tier in ["private","apartment"]:
    if s.housing.tier==tier: return "This is already your tenancy."
    var price = 25 if tier=="private" else 80
    if s.housing.arrears>0: return "Settle your previous arrears first."
    if s.credits<price: return "The deposit is %d CR."%price
    s.credits -= price; s.housing.deposit = price; s.housing.tier = tier
    s.housing.address = "Block D / Room 8" if tier=="private" else "Block D / Apartment 21"
    s.housing.rent = 2 if tier=="private" else 4; s.housing.next_bill = (int(s.minute/1440)+1)*1440
    e.append({"type":"thought","text":"It's small... but it's mine."})
   else: return "Unknown tenancy."
  "pay_rent":
   if s.location not in ["room","bureau"]: return "Your tenancy paper is at home or the bureau."
   if s.housing.arrears<=0: return "No rent is owed."
   if s.credits<s.housing.arrears: return "I can't cover the arrears yet."
   s.credits -= int(s.housing.arrears); s.housing.arrears = 0; s.housing.bills = 0
  "play_tape":
   if s.location!="room" or "radio" not in s.room_upgrades or _owned(s,"tape").is_empty(): return "I need the tape and a working receiver at home."
   if "floor4" not in s.discoveries: s.discoveries.append("floor4")
   e.append({"type":"recording","text":"TRAINING / INCIDENT RESPONSE / FLOOR 4\n\n[damaged audio]\nCount the staff before the door closes.\nIf the count changes, repeat the count.\nDo not open a second work order.\n\nRecorded: 31 / 02 / 1998"})
  "camp_sort", "camp_order", "camp_meal", "camp_sleep", "camp_release": return _camp(s,c,e)
  _: return "Unknown interaction."
 return ""

static func _begin_shift(s: Dictionary,job: String) -> void:
 var id = "%s-shift-%d"%[s.identity.civic_id,int(s.sequence)+1]
 s.shift = {"id":id,"job":job,"stage":"inspect" if job=="laundry" else "work","quality":100,"minutes":0,"risks":[],"selected":0}
 if job=="laundry":
  var completed = int(s.jobs.laundry.shifts)
  var category = ["general","factory","medical"][completed%3]
  var stain = {"general":"dirt","factory":"oil","medical":"blood"}[category]
  var uniforms: Array = []
  for n in range(4):
   uniforms.append({"type":"security" if n==1 and completed==0 else category,"stain":stain,"inspected":false,"pocket_checked":false,"sorted":false,"found":""})
  if completed==0 or completed%3==0:
   var object = _item(s,"credits","3 loose credits","found","Security uniform / logged pocket",{"amount":3,"risk":0.32,"evidence":"Security jacket S-184 had a logged pocket receipt."})
   object.rightful_owner = "Worker S-184"; uniforms[1].found = object.id
  elif completed==1:
   var object = _item(s,"tape","Damaged training tape","found","Factory uniform",{"risk":0.08,"evidence":"The uniform inventory log lists a training tape.","label":"TRAINING / INCIDENT RESPONSE / FLOOR 4"})
   object.rightful_owner = "Textile archive"; uniforms[2].found = object.id
  s.shift.uniforms = uniforms; s.shift.hatch_open = false; s.shift.loaded = false; s.shift.doses = 0; s.shift.cycle = "standard"
 elif job=="cleaning":
  s.shift.cleaned = []; s.shift.supplies = false; s.shift.desk_checked = false
  var object = _item(s,"note","Folded office memorandum","found","Civic Annex / desk",{"risk":0.18,"evidence":"The office camera recorded the empty desk drawer.","text":"FLOOR 4 staff list: 17 present / 18 paid. Do not reconcile."})
  object.rightful_owner = "Civic clerk"; s.shift.found = object.id
 else:
  s.shift.manifest_read = false; s.shift.crates = []
  for n in range(4): s.shift.crates.append({"serial":"IX-%d-%d"%[int(s.jobs.freight.shifts)+1,n+11],"destination":["BLOCK C","CLINIC","TEXTILES","CLINIC"][n],"inspected":false,"routed":false,"damaged":n==3,"opened":false})
  var object = _item(s,"bread","Uncounted bread parcel","found","Crate IX / damaged seal",{"risk":0.42,"evidence":"A numbered freight seal was missing at manifest reconciliation.","food":42,"shelf_days":3})
  object.rightful_owner = "Block C communal kitchen"; s.shift.found = object.id

static func _laundry(s: Dictionary,c: Dictionary,e: Array) -> String:
 if s.shift.is_empty() or s.shift.job!="laundry" or s.location!="laundry": return "Take a textile work order from the incoming cart."
 var w = s.shift; var action = c.action
 var index = int(c.get("index",w.selected))
 if index<0 or index>=w.uniforms.size(): return "That uniform is not in this batch."
 var u = w.uniforms[index]
 if action in ["inspect_uniform","inspect_pocket","sort_uniform"]:
  if w.stage!="inspect": return "The batch is already inside the machine."
  w.selected = index
  if action=="inspect_uniform": u.inspected = true
  if action=="inspect_pocket":
   if not u.inspected: return "Unfold the uniform first."
   u.pocket_checked = true
   if u.found!="" and _find(s,u.found).owner=="found": e.append({"type":"found","id":u.found})
  if action=="sort_uniform":
   if not u.inspected: return "Check its service label first."
   if u.sorted: return "It's already in the sorting bin."
   if str(c.get("bin","")) not in ["general","security","factory","medical"]: return "Choose a marked sorting bin."
   if c.bin!=u.type: w.quality -= 8
   if not u.pocket_checked: w.quality -= 5
   u.sorted = true
   _work_time(s,20)
  return ""
 match action:
  "open_hatch":
   if w.stage!="inspect": return "The hatch is locked during this cycle."
   w.hatch_open = true
  "load_washer":
   if w.stage!="inspect" or not w.hatch_open: return "Open the washer hatch."
   for garment in w.uniforms:
    if not garment.sorted: return "There are still uniforms on the inspection bench."
   w.loaded = true; w.stage = "prepare"; _work_time(s,20)
  "dose":
   if w.stage!="prepare" or not w.hatch_open: return "Add detergent before closing the hatch."
   if w.doses>=3: return "The dispenser is full."
   w.doses += 1
  "cycle":
   if w.stage!="prepare": return "Set the controls after loading."
   if str(c.get("cycle","")) not in ["standard","hot","sanitize"]: return "Unknown wash cycle."
   w.cycle = c.cycle
  "close_hatch":
   if w.stage!="prepare": return "Load the machine first."
   w.hatch_open = false
  "start_wash":
   if w.stage!="prepare" or w.hatch_open: return "Close the hatch before starting."
   var expected = "standard"
   for garment in w.uniforms:
    if garment.stain=="blood": expected = "sanitize"; break
    if garment.stain=="oil": expected = "hot"
   if w.cycle!=expected: w.quality -= 22; e.append({"type":"notice","text":"Wrong treatment. The service label calls for %s wash."%expected})
   if w.doses!=2: w.quality -= 12; e.append({"type":"notice","text":"Four uniforms require two measured detergent doses."})
   w.stage = "washed"; _work_time(s,60); e.append({"type":"sound","name":"washer"})
  "unload":
   if w.stage!="washed": return "Wait until the wash order is complete."
   w.hatch_open = true; w.stage = "wet"; _work_time(s,10)
  "dry":
   if w.stage!="wet": return "Take the washed bundle out first."
   w.stage = "dry"; _work_time(s,40)
  "fold":
   if w.stage!="dry": return "Dry the uniforms before folding."
   w.stage = "folded"; _work_time(s,20); e.append({"type":"sound","name":"cloth"})
  "dispatch":
   if w.stage!="folded": return "The outgoing cart needs folded uniforms."
   w.stage = "receipt"; _work_time(s,10)
  _: return "Unknown machine interaction."
 return ""

static func _found_choice(s: Dictionary,c: Dictionary,e: Array) -> String:
 if s.shift.is_empty(): return "This object is no longer on the workbench."
 var item = _find(s,str(c.get("id","")))
 if item.is_empty() or item.owner!="found": return "That object's custody has already been decided."
 var visible = false
 if s.shift.job=="laundry":
  for u in s.shift.uniforms:
   if u.found==item.id and u.pocket_checked: visible = true
 elif s.shift.job=="cleaning": visible = s.shift.desk_checked and s.shift.found==item.id
 elif s.shift.job=="freight": visible = s.shift.crates[3].opened and s.shift.found==item.id
 if not visible: return "Inspect the place where the object was found first."
 var choice = str(c.get("choice",""))
 if choice not in ["keep","return","leave"]: return "Choose where to put the object."
 item.owner = {"keep":"player","return":"lost_property","leave":"origin"}[choice]
 item.history.append({"minute":s.minute,"custody":item.owner})
 if choice=="keep":
  item.legal = "unreported" if item.kind=="credits" else "unlawful"
  if item.kind=="credits": s.credits += int(item.metadata.amount); s.illicit_credits += int(item.metadata.amount)
  var roll = _random(s)
  s.shift.risks.append({"id":item.id,"roll":roll,"chance":item.metadata.get("risk",0.2),"evidence":item.metadata.get("evidence","Inventory discrepancy.")})
  e.append({"type":"thought","text":"Nobody would know."})
 elif choice=="return": s.jobs[s.shift.job].trust += 1
 s.decisions.append({"item":item.id,"choice":choice,"minute":s.minute})
 return ""

static func _cleaning(s: Dictionary,c: Dictionary,e: Array) -> String:
 if s.location!="cleaning" or s.shift.is_empty() or s.shift.job!="cleaning": return "Take a sanitation work order first."
 var w = s.shift; var object = str(c.get("object",""))
 if object=="supplies": w.supplies = true; return ""
 if object=="inspect_desk":
  w.desk_checked = true
  if _find(s,w.found).owner=="found": e.append({"type":"found","id":w.found})
  return ""
 if object not in ["floor","desk","bin"]: return "That isn't on this cleaning order."
 if not w.supplies: return "Take the mop, cloth and fresh bag from the bucket."
 if object in w.cleaned: return "That surface is already clean."
 w.cleaned.append(object); _work_time(s,80)
 if w.cleaned.size()==3: w.stage = "receipt"
 e.append({"type":"sound","name":"mop"})
 return ""

static func _freight(s: Dictionary,c: Dictionary,e: Array) -> String:
 if s.location!="freight" or s.shift.is_empty() or s.shift.job!="freight": return "Take a freight work order first."
 var w = s.shift
 if c.action=="manifest": w.manifest_read = true; return ""
 var index = int(c.get("index",w.selected))
 if index<0 or index>=w.crates.size(): return "Unknown crate."
 var crate = w.crates[index]; w.selected = index
 if c.action=="inspect_crate": crate.inspected = true
 if c.action=="open_crate":
  if not crate.inspected or not crate.damaged or crate.routed: return "Inspect the damaged seal before routing the parcel."
  crate.opened = true
  if _find(s,w.found).owner=="found": e.append({"type":"found","id":w.found})
 if c.action=="route_crate":
  if crate.routed: return "That crate has already left this bench."
  if not crate.inspected: return "Read the label first."
  if str(c.get("destination","")) not in ["BLOCK C","CLINIC","TEXTILES"]: return "Unknown freight lane."
  if c.destination!=crate.destination: w.quality -= 18
  if not w.manifest_read: w.quality -= 5
  crate.routed = true; _work_time(s,60)
  var complete = true
  for box in w.crates:
   if not box.routed: complete = false
  if complete: w.stage = "receipt"
 return ""

static func _settle(s: Dictionary,e: Array) -> String:
 if s.shift.is_empty() or s.shift.stage!="receipt": return "The outgoing work hasn't been counted yet."
 var w = s.shift; var job = w.job; var record = s.jobs[job]
 if s.location!=JOB_SCENES[job]: return "Collect the timecard at your workplace."
 # Complete action time even if a future authored activity changes its stage lengths.
 if w.minutes<240: _work_time(s,240-int(w.minutes))
 var quality = clampi(int(w.quality),0,100)
 var gross = int(catalog().jobs[job].gross)+(1 if record.promoted else 0)-(1 if quality<60 else 0)
 var remainder = int(s.tax_remainder)+gross*12
 var tax = int(remainder/100)
 s.tax_remainder = remainder%100; s.tax_paid += tax; s.credits += gross-tax
 record.shifts += 1
 if quality>=85: record.trust += 1
 else: record.warnings += 1
 s.last_receipt = {"shift_id":w.id,"job":job,"gross":gross,"withholding":tax,"net":gross-tax,"quality":quality}
 e.append({"type":"receipt","data":s.last_receipt.duplicate(true)})
 var detected: Array = []
 for risk in w.risks:
  if float(risk.roll)<float(risk.chance): detected.append(risk)
 s.shift = {}
 for risk in detected:
  var item = _find(s,risk.id)
  if item.owner in ["player","room"]:
   item.owner = "confiscated"; item.history.append({"minute":s.minute,"custody":"confiscated"})
   if item.kind=="credits":
    var recover = mini(int(item.metadata.amount),int(s.credits)); s.credits -= recover; s.illicit_credits = maxi(0,int(s.illicit_credits)-recover)
   var fine = mini(2,int(s.credits)); s.credits -= fine
   s.legal.offenses += 1; s.legal.suspicion += 15
   var incident = {"evidence":risk.evidence,"fine":fine,"item":item.id,"minute":s.minute}
   s.legal.record.append(incident)
   e.append({"type":"notice","text":"Inventory inspection: %s\nObject confiscated. %d CR fine. Your civic record is marked."%[risk.evidence,fine]})
 if s.legal.offenses>=3 and not detected.is_empty(): _enter_camp(s,e)
 return ""

static func _enter_camp(s: Dictionary,e: Array) -> void:
 for item in s.items:
  if item.owner=="player": item.owner = "held"; item.history.append({"minute":s.minute,"custody":"held"})
 s.legal.camp = {"active":true,"orders":0,"sorted":[],"started":s.minute,"address":s.housing.address}
 s.location = "camp"
 e.append({"type":"notice","text":"DETAINEE 91-447\nThree compulsory work orders. Outside tenancy and employment paused. Personal effects held at intake."})

static func _camp(s: Dictionary,c: Dictionary,e: Array) -> String:
 var camp = s.legal.camp
 if s.location!="camp" or camp.is_empty() or not camp.active: return "You have no active correction order."
 match c.action:
  "camp_sort":
   var index = int(c.get("index",-1))
   if index not in [0,1,2] or str(c.get("bin","")) not in ["metal","fabric"]: return "Sort the scrap into the marked bins."
   if index in camp.sorted: return "That piece is already counted."
   if c.bin!=["metal","fabric","metal"][index]: return "The counter rejects it. Check its material."
   camp.sorted.append(index); _advance(s,30)
   s.needs.energy = maxf(0,s.needs.energy-2)
  "camp_order":
   if camp.sorted.size()!=3: return "Three sorted pieces make one work order."
   if camp.orders>=3: return "Your work orders are complete."
   camp.orders += 1; camp.sorted = []
   e.append({"type":"notice","text":"WORK ORDER %d / 3 COUNTED\nZero wages."%int(camp.orders)})
  "camp_meal": s.needs.hunger = maxf(45,s.needs.hunger); s.needs.thirst = maxf(55,s.needs.thirst)
  "camp_sleep": _advance(s,120,true); s.needs.energy = minf(70,s.needs.energy+35)
  "camp_release":
   if camp.orders<3: return "Complete the three work orders before release."
   s.housing.next_bill += int(s.minute)-int(camp.started)
   for item in s.items:
    if item.owner=="held": item.owner = "player"; item.history.append({"minute":s.minute,"custody":"player"})
   camp.active = false; camp.released = s.minute; s.location = "room"
   s.needs.health = maxf(25,s.needs.health); s.needs.energy = maxf(22,s.needs.energy)
   e.append({"type":"thought","text":"My door. Still here."})
 return ""

static func _consume(s: Dictionary,id: String,e: Array) -> String:
 var item = _find(s,id)
 if item.is_empty() or item.owner!="player": return "I don't have that."
 var def = catalog().items.get(item.kind,{})
 if not def.has("food") and not def.has("water"): return "That isn't something to eat or drink."
 if item.get("expiry_minute",0)>0 and s.minute>=item.expiry_minute+(4320 if "fridge" in s.room_upgrades else 0): return "It's spoiled. I shouldn't eat it."
 if def.get("requires","")!="" and def.requires not in s.room_upgrades: return "I need a kettle in my room."
 if item.kind=="tea" and s.location!="room": return "The kettle is at home."
 var thirsty = s.needs.thirst<25
 item.owner = "consumed"; item.history.append({"minute":s.minute,"custody":"consumed"})
 s.needs.hunger = minf(100,s.needs.hunger+float(def.get("food",0)))
 s.needs.thirst = minf(100,s.needs.thirst+float(def.get("water",0)))
 s.needs.health = minf(100,s.needs.health+float(def.get("health",0)))
 e.append({"type":"thought","text":"God, I needed that." if item.kind=="stew" else "Better." if thirsty and def.has("water") else "That'll keep me going."})
 return ""

static func _item(s: Dictionary,kind: String,label: String,owner: String,origin: String,metadata: Dictionary) -> Dictionary:
 s.serial = int(s.serial)+1
 var item = {"id":"IX-%s-%05d"%[s.identity.civic_id,int(s.serial)],"kind":kind,"label":label,"owner":owner,"rightful_owner":"player" if owner=="player" else origin,"serial":"R-%05d"%int(s.serial),"origin":origin,"condition":"worn" if metadata.get("upgrade",false) else "intact","legal":"ordinary","acquired_minute":s.minute,"expiry_minute":s.minute+int(metadata.get("shelf_days",0))*1440 if metadata.has("shelf_days") else 0,"metadata":metadata.duplicate(true),"history":[{"minute":s.minute,"custody":owner}]}
 s.items.append(item)
 return item

static func _owned(s: Dictionary,kind: String) -> Dictionary:
 for item in s.items:
  if item.kind==kind and item.owner=="player": return item
 return {}

static func _find(s: Dictionary,id: String) -> Dictionary:
 for item in s.items:
  if item.id==id: return item
 return {}

static func _work_time(s: Dictionary,minutes: int) -> void:
 s.shift.minutes += minutes; _advance(s,minutes)
 s.needs.energy = maxf(0,s.needs.energy-float(minutes)/16.0)
 s.needs.hygiene = maxf(0,s.needs.hygiene-float(minutes)/40.0)

static func _advance(s: Dictionary,minutes: int,sleeping: bool=false) -> void:
 var hours = float(minutes)/60.0
 var camp = not s.legal.camp.is_empty() and s.legal.camp.get("active",false)
 s.minute += minutes
 s.needs.hunger = maxf(0,s.needs.hunger-hours*(1.5 if sleeping or camp else 4.0))
 s.needs.thirst = maxf(0,s.needs.thirst-hours*(2.0 if sleeping or camp else 6.0))
 s.needs.hygiene = maxf(0,s.needs.hygiene-hours)
 if not sleeping: s.needs.energy = maxf(0,s.needs.energy-hours)
 if s.needs.hunger<15 or s.needs.thirst<15: s.needs.health = maxf(10,s.needs.health-hours*1.5)
 if not camp:
  while s.minute>=s.housing.next_bill:
   if s.housing.rent>0:
    if s.credits>=s.housing.rent: s.credits -= int(s.housing.rent)
    elif s.housing.bills<4:
     s.housing.arrears += int(s.housing.rent); s.housing.bills += 1
    if s.housing.bills>=4:
     s.housing.tier = "municipal"; s.housing.address = "Block C / Room 17"; s.housing.rent = 0
   s.housing.next_bill += 1440

static func _random(s: Dictionary) -> float:
 # Park-Miller generator: bounded integer product, serialized stream, no UI randomness.
 s.rng = (int(s.rng)*48271)%2147483647
 return float(s.rng)/2147483647.0

static func _threshold_thought(before: Dictionary,s: Dictionary,e: Array) -> void:
 if e.any(func(event): return event.type=="thought"): return
 var lines = {"hunger":["Could eat something.","I'm getting hungry.","I need to eat soon.","I'm starving. I can't keep working like this."],"thirst":["I'm thirsty.","My mouth is completely dry.","I need water.","I can't swallow."],"energy":["I'm getting tired.","I can barely keep my eyes open.","I need to lie down.","I'm done."],"hygiene":["My shirt smells.","I need a wash.","I can feel the grime.","I don't feel human."]}
 for need in lines:
  var thresholds = [60,40,25,12]
  for i in range(thresholds.size()-1,-1,-1):
   if before.needs[need]>thresholds[i] and s.needs[need]<=thresholds[i]:
    e.append({"type":"thought","text":lines[need][i]}); return
