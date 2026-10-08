class_name SchismSimulation
extends RefCounted

const SCHEMA = 6
const COLD_ALLOWANCE = 3 * 1440
const BACKGROUNDS = {
 "resident":{"label":"District resident","text":"Block C is the only home I remember."},
 "factory_laborer":{"label":"Factory laborer","text":"My old textile label reads: dirt / standard, oil / hot, blood / sanitize. Four uniforms take two detergent doses. The laundry still hires through window 3."},
 "displaced_resident":{"label":"Displaced resident","text":"My relocation notice names Block C. A neighbor on the landing used to carry baskets for the displaced. I should look in after my first shift; they may remember me."},
 "former_bureaucrat":{"label":"Former bureaucrat","text":"An old count slip names the service corridor relay. Its return-count recording was damaged when the cabinet failed. I could restore it and hear what the clerks copied forward."},
 "street_survivor":{"label":"Street survivor","text":"My folded street map marks the free public tap. The food kiosk gives one emergency ration per day when I have 2 CR or less. Neither needs a work authorization."},
 "technical_apprentice":{"label":"Technical apprentice","text":"My training card marks a loose relay in the service corridor cabinet. Reseating it should restore the corridor lamps and the recorder. The kit is left inside; no certification is required."}
}
const JOB_SCENES = {"laundry":"laundry", "cleaning":"cleaning", "freight":"freight"}
const ROUTES = {
 "room":["hall"], "hall":["room","street"],
 "street":["hall","bureau","laundry","cleaning","freight","shop","service"],
 "bureau":["street"], "laundry":["street"], "cleaning":["street"],
 "freight":["street"], "shop":["street"], "service":["street"], "camp":[]
}

static func catalog() -> Dictionary:
 return JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))

static func initial() -> Dictionary:
 return {
  "schema":SCHEMA, "revision":0, "sequence":0, "serial":0, "rng":48193,
  "identity":{"name":"William","civic_id":"48193","registered":false,"appearance":"olive","background":"resident"},
  "needs":{"hunger":52.0,"thirst":46.0,"energy":58.0,"hygiene":48.0,"health":91.0},
  "credits":4, "illicit_credits":0, "tax_remainder":0, "tax_paid":0,
  "taxes":_initial_taxes(360),
  "minute":360, "location":"room", "arrival_seen":false,
  "employment":"", "jobs":{"laundry":{"shifts":0,"trust":0,"warnings":0,"promoted":false},"cleaning":{"shifts":0,"trust":0,"warnings":0,"promoted":false},"freight":{"shifts":0,"trust":0,"warnings":0,"promoted":false}},
  "housing":{"tier":"municipal","address":"Block C / Room 17","rent":0,"deposit":0,"next_bill":1440,"arrears":0,"bills":0,"utilities":true},
  "items":[], "room_upgrades":[], "shift":{}, "ticket":false,"id_shown":false,
  "legal":{"suspicion":0,"offenses":0,"record":[],"camp":{}},
  "discoveries":["room"], "events":[], "decisions":[], "relief_day":-1,
  "city":{"encounters":{},"flags":{},"security_favor":0,"supplies":{"metal":0,"fabric":0}},
  "settings":{"sound":true,"effects":true,"hints":true}, "last_receipt":{}
 }

static func migrate(old: Dictionary) -> Dictionary:
 if int(old.get("schema",1)) > SCHEMA:
  return {"error":"This save needs a newer SCHISM version. Your files have been preserved."}
 var old_schema = int(old.get("schema",1))
 var s = old.duplicate(true)
 if old_schema<=5: s.taxes = _initial_taxes(int(s.get("minute",360)))
 elif not s.get("taxes") is Dictionary or not _valid_taxes(s.taxes): return {"error":"The tax record needs recovery. Your files have been preserved."}
 for key in ["identity","needs","city","shift","taxes"]:
  if s.has(key) and not s[key] is Dictionary: return {"error":"The %s record needs recovery. Your files have been preserved."%key}
 if s.has("items") and not s.items is Array: return {"error":"The possession record needs recovery. Your files have been preserved."}
 if s.has("city"):
  for key in ["encounters","flags","supplies"]:
   if s.city.has(key) and not s.city[key] is Dictionary: return {"error":"The city record needs recovery. Your files have been preserved."}
 for key in ["jobs","housing","legal","settings"]:
  if s.has(key) and not s[key] is Dictionary: return {"error":"The %s record needs recovery. Your files have been preserved."%key}
 for key in ["room_upgrades","discoveries","events","decisions"]:
  if s.has(key) and not s[key] is Array: return {"error":"The %s record needs recovery. Your files have been preserved."%key}
 if old_schema>=6:
  if not s.get("city") is Dictionary or not s.get("legal") is Dictionary or not s.legal.has("camp"): return {"error":"The city or detention record needs recovery. Your files have been preserved."}
  for field in ["encounters","flags","supplies","security_favor"]:
   if not s.city.has(field): return {"error":"The city record needs recovery. Your files have been preserved."}
  for material in ["metal","fabric"]:
   if not s.city.supplies is Dictionary or not s.city.supplies.has(material): return {"error":"The supply record needs recovery. Your files have been preserved."}
 var restore_repair_favor = old_schema==5 and s.has("city") and not s.city.has("security_favor") and s.city.get("flags",{}).get("service_repaired",false)==true
 var defaults = initial()
 _defaults(s, defaults)
 if restore_repair_favor: s.city.security_favor = 1
 if not _whole_number(s.city.security_favor) or int(s.city.security_favor)<0 or int(s.city.security_favor)>100: return {"error":"The security favor record needs recovery. Your files have been preserved."}
 if not _valid_taxes(s.taxes): return {"error":"The tax record needs recovery. Your files have been preserved."}
 for key in ["metal","fabric"]:
  if not _whole_number(s.city.supplies.get(key)) or int(s.city.supplies[key])<0: return {"error":"The supply record needs recovery. Your files have been preserved."}
 if not s.legal.camp is Dictionary: return {"error":"The detention record needs recovery. Your files have been preserved."}
 if not s.legal.camp.is_empty():
  var camp = s.legal.camp
  if old_schema>=6:
   for field in ["reason","minimum_orders","debt_at_entry","worked_off","tax_pause_started","orders","started","active","sorted"]:
    if not camp.has(field): return {"error":"The detention record needs recovery. Your files have been preserved."}
  _defaults(camp,{"reason":"crime","minimum_orders":3,"debt_at_entry":0,"worked_off":0,"tax_pause_started":int(s.minute) if old_schema<=5 else int(camp.get("started",s.minute))})
  if not camp.get("active") is bool or not camp.get("sorted") is Array: return {"error":"The detention progress needs recovery. Your files have been preserved."}
  var seen_pieces = []
  for piece in camp.sorted:
   if not _whole_number(piece) or int(piece) not in [0,1,2] or int(piece) in seen_pieces: return {"error":"The detention sorting needs recovery. Your files have been preserved."}
   seen_pieces.append(int(piece))
  if camp.reason not in ["crime","tax","mixed"]: return {"error":"The detention reason needs recovery. Your files have been preserved."}
  for key in ["minimum_orders","debt_at_entry","worked_off","tax_pause_started","orders","started"]:
   if not _whole_number(camp.get(key)) or int(camp[key])<0: return {"error":"The detention counter needs recovery. Your files have been preserved."}
  if int(camp.minimum_orders)!=3 or int(camp.tax_pause_started)>int(s.minute): return {"error":"The detention clock needs recovery. Your files have been preserved."}
 if not s.identity.background is String or not BACKGROUNDS.has(s.identity.background): return {"error":"The background record needs recovery. Your files have been preserved."}
 for key in ["service_repaired","relay_heard","neighbor_known","coworker_known"]:
  if s.city.flags.has(key) and not s.city.flags[key] is bool: return {"error":"A city flag needs recovery. Your files have been preserved."}
 if s.city.flags.has("inspection_day") and (not _whole_number(s.city.flags.inspection_day) or int(s.city.flags.inspection_day)<0): return {"error":"The inspection day needs recovery. Your files have been preserved."}
 for id in s.city.encounters:
  var record = s.city.encounters[id]
  if not record is Dictionary: return {"error":"An encounter record needs recovery. Your files have been preserved."}
  for key in ["count","last_day","last_minute"]:
   if not _whole_number(record.get(key)) or int(record[key])<0: return {"error":"An encounter counter needs recovery. Your files have been preserved."}
  if not record.get("last_choice") is String: return {"error":"An encounter choice needs recovery. Your files have been preserved."}
 if not s.shift.is_empty() and s.shift.get("job")=="laundry":
  if not s.shift.get("uniforms") is Array: return {"error":"The laundry record needs recovery. Your files have been preserved."}
  for garment in s.shift.uniforms:
   if not garment is Dictionary: return {"error":"A garment record needs recovery. Your files have been preserved."}
   var stage = s.shift.get("stage","inspect")
   _defaults(garment,{"loaded":stage!="inspect","unloaded":stage in ["wet","dry","folded","receipt"],"folds":fold_steps(garment) if stage in ["folded","receipt"] else 0})
   if not garment.loaded is bool or not garment.unloaded is bool or not _whole_number(garment.folds) or int(garment.folds)<0 or int(garment.folds)>fold_steps(garment): return {"error":"A garment progress record needs recovery. Your files have been preserved."}
 for index in range(s.items.size()):
  var item = s.items[index]
  if not item is Dictionary: return {"error":"An item record needs recovery. Your files have been preserved."}
  if item.has("metadata") and not item.metadata is Dictionary: return {"error":"An item metadata record needs recovery. Your files have been preserved."}
  if item.has("history") and not item.history is Array: return {"error":"An item custody record needs recovery. Your files have been preserved."}
  var legacy_id = str(item.get("id","LEGACY-%s-%d"%[s.identity.civic_id,index]))
  _defaults(item,{"id":legacy_id,"kind":"unknown","label":"Recovered possession","owner":"player","rightful_owner":"player","serial":legacy_id,"origin":"Earlier residency record","condition":"worn","legal":"ordinary","acquired_minute":s.minute,"expiry_minute":0,"storage":"bag","cold_minutes":0,"metadata":{},"history":[]})
  s.serial = maxi(int(s.serial),index+1)
  var serial_text = str(item.serial).trim_prefix("R-")
  if str(item.serial).begins_with("R-") and serial_text.is_valid_int(): s.serial = maxi(int(s.serial),int(serial_text))
  # Preserve the former global fridge allowance for existing food exactly once.
  if old_schema<4 and "fridge" in s.room_upgrades and item.owner=="player" and item.expiry_minute>0:
   item.cold_minutes = COLD_ALLOWANCE
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
 s.illicit_credits = clampi(int(s.illicit_credits),0,int(s.credits))
 s.revision = int(before.revision)+1
 s.sequence = int(before.sequence)+1
 for e in events:
  e["event_id"] = str(s.identity.civic_id)+":"+str(s.sequence)+":"+str(s.events.size())
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
  var background = c.get("background","resident")
  if not background is String or not BACKGROUNDS.has(background): return "Choose an available background."
  s.identity.background = background
  if background!="resident": _item(s,"note","Personal memento","player","Before District IX",{"background":background,"text":BACKGROUNDS[background].text})
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
  "pay_tax": return _pay_tax(s,c,e)
  "event_choice": return _event_choice(s,c,e)
  "arrival": s.arrival_seen = true
  "travel":
   if not s.shift.is_empty(): return "Finish this work order before leaving."
   var target = str(c.get("to",""))
   if target not in ROUTES.get(s.location,[]): return "There is no doorway there."
   var from_street = s.location=="street"
   s.location = target
   if target not in s.discoveries: s.discoveries.append(target)
   _advance(s,5)
   if s.taxes.flagged:
    if from_street and target!="bureau": _enter_camp(s,e,"tax")
    elif target=="street": e.append({"type":"notice","text":"OVERDUE CIVIC TAX / INSPECTION FLAG\nProceed directly to the bureau payment counter. Another journey without payment leads to compulsory work."})
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
  "inspect_uniform", "inspect_pocket", "sort_uniform", "open_hatch", "load_washer", "load_garment", "unload_garment", "fold_garment", "dose", "cycle", "close_hatch", "start_wash", "unload", "dry", "fold", "dispatch":
   return _laundry(s,c,e)
  "found_choice": return _found_choice(s,c,e)
  "clean": return _cleaning(s,c,e)
  "inspect_crate", "route_crate", "open_crate", "manifest": return _freight(s,c,e)
  "settle_shift": return _settle(s,e)
  "buy":
   if s.location!="shop" or not s.shift.is_empty(): return "The vendor is at the food kiosk."
   var kind = str(c.get("kind","")); var goods = catalog().items
   if not goods.has(kind): return "The vendor doesn't stock that."
   if goods[kind].get("upgrade",false) and (kind in s.room_upgrades or s.items.any(func(item): return item.kind==kind and item.owner=="player")): return "I already have one."
   if s.credits<int(goods[kind].price): return "Not enough credits."
   s.credits -= int(goods[kind].price)
   _item(s,kind,goods[kind].label,"player","Food kiosk",goods[kind])
   e.append({"type":"sound","name":"coin"})
  "store_item": return _store_item(s,c,e)
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
   s.needs.energy = minf(100,s.needs.energy+(80 if "blanket" in s.room_upgrades else 68)+(16 if s.housing.tier=="apartment" else 8 if s.housing.tier=="private" else 0))
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
   uniforms.append({"type":"security" if n==1 and completed==0 else category,"stain":stain,"inspected":false,"pocket_checked":false,"sorted":false,"found":"","loaded":false,"unloaded":false,"folds":0})
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
 if c.has("index") and not _whole_number(c.index): return "Choose a garment on this workbench."
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
  "load_garment":
   if w.stage!="inspect" or not w.hatch_open: return "Open the washer hatch."
   if not u.sorted: return "Sort this garment before loading it."
   if u.loaded: return "That garment is already inside."
   u.loaded = true; w.selected = index
   if w.uniforms.all(func(g): return g.loaded):
    w.loaded = true; w.stage = "prepare"; _work_time(s,20)
   e.append({"type":"sound","name":"cloth"})
  "unload_garment":
   if w.stage!="washed": return "Wait until the wash order is complete."
   if u.unloaded: return "That garment is already on the drying rack."
   u.unloaded = true; w.hatch_open = true; w.selected = index
   if w.uniforms.all(func(g): return g.unloaded): w.stage = "wet"; _work_time(s,10)
   e.append({"type":"sound","name":"cloth"})
  "fold_garment":
   if w.stage!="dry": return "Dry the uniforms before folding."
   var needed = fold_steps(u)
   if u.folds>=needed: return "That garment is already folded."
   if not _whole_number(c.get("step")) or int(c.step)!=int(u.folds)+1: return "Fold the next marked region."
   u.folds += 1; w.selected = index
   if w.uniforms.all(func(g): return int(g.folds)==fold_steps(g)): w.stage = "folded"; _work_time(s,20)
   e.append({"type":"sound","name":"cloth"})
  "open_hatch":
   if w.stage not in ["inspect","prepare"]: return "The hatch is locked during this cycle."
   w.hatch_open = true
  "load_washer":
   if w.stage!="inspect" or not w.hatch_open: return "Open the washer hatch."
   for garment in w.uniforms:
    if not garment.sorted: return "There are still uniforms on the inspection bench."
   for garment in w.uniforms: garment.loaded = true
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
   for garment in w.uniforms: garment.unloaded = true
   w.hatch_open = true; w.stage = "wet"; _work_time(s,10)
  "dry":
   if w.stage!="wet": return "Take the washed bundle out first."
   w.stage = "dry"; _work_time(s,40)
  "fold":
   if w.stage!="dry": return "Dry the uniforms before folding."
   for garment in w.uniforms: garment.folds = fold_steps(garment)
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
 if c.has("index") and not _whole_number(c.index): return "Choose a garment on this workbench."
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
 s.tax_remainder = remainder%100; s.taxes.accrued += tax; s.credits += gross
 _tax_ledger(s,"assessment",tax)
 record.shifts += 1
 if quality>=85: record.trust += 1
 else: record.warnings += 1
 s.last_receipt = {"shift_id":w.id,"job":job,"gross":gross,"withholding":0,"net":gross,"tax_assessed":tax,"quality":quality}
 e.append({"type":"receipt","data":s.last_receipt.duplicate(true)})
 var detected: Array = []
 for risk in w.risks:
  if float(risk.roll)<float(risk.chance): detected.append(risk)
 s.shift = {}
 for risk in detected:
  var item = _find(s,risk.id)
  if item.owner in ["player","room","consumed"]:
   var consumed = item.owner=="consumed"
   if not consumed: item.owner = "confiscated"
   item.history.append({"minute":s.minute,"custody":"evidence_counted" if consumed else "confiscated"})
   if item.kind=="credits":
    var recover = mini(int(item.metadata.amount),int(s.credits)); s.credits -= recover; s.illicit_credits = maxi(0,int(s.illicit_credits)-recover)
   var fine = mini(2,int(s.credits)); s.credits -= fine
   s.legal.offenses += 1; s.legal.suspicion += 15
   var incident = {"evidence":risk.evidence,"fine":fine,"item":item.id,"minute":s.minute}
   s.legal.record.append(incident)
   e.append({"type":"notice","text":"Inventory inspection: %s\n%s %d CR fine. Your civic record is marked."%[risk.evidence,"Missing goods recorded." if consumed else "Object confiscated.",fine]})
 if s.legal.offenses>=3 and not detected.is_empty(): _enter_camp(s,e)
 return ""

static func _enter_camp(s: Dictionary,e: Array,reason: String="crime") -> void:
 if not s.shift.is_empty() or s.legal.camp.get("active",false): return
 if reason=="crime" and s.taxes.flagged: reason = "mixed"
 for item in s.items:
  if item.owner=="player" and item.get("storage","bag")=="bag": item.owner = "held"; item.history.append({"minute":s.minute,"custody":"held"})
 s.legal.camp = {"active":true,"orders":0,"sorted":[],"started":s.minute,"address":s.housing.address,"reason":reason,"minimum_orders":3,"debt_at_entry":tax_summary(s).total,"worked_off":0,"tax_pause_started":s.minute}
 s.location = "camp"
 e.append({"type":"notice","text":"DETAINEE 91-447\nAt least three compulsory work orders; tax debt must be worked off for tax detention. Outside tenancy and employment paused. Personal effects held at intake."})

static func _camp(s: Dictionary,c: Dictionary,e: Array) -> String:
 var camp = s.legal.camp
 if s.location!="camp" or camp.is_empty() or not camp.active: return "You have no active correction order."
 match c.action:
  "camp_sort":
   if camp.orders>=int(camp.minimum_orders) and (camp.reason=="crime" or tax_summary(s).total==0): return "Your work orders are complete."
   if not _whole_number(c.get("index")): return "Choose a scrap piece."
   var index = int(c.get("index",-1))
   if index not in [0,1,2] or str(c.get("bin","")) not in ["metal","fabric"]: return "Sort the scrap into the marked bins."
   if index in camp.sorted: return "That piece is already counted."
   if c.bin!=["metal","fabric","metal"][index]: return "The counter rejects it. Check its material."
   camp.sorted.append(index); _advance(s,30)
   s.needs.energy = maxf(0,s.needs.energy-2)
  "camp_order":
   if camp.sorted.size()!=3: return "Three sorted pieces make one work order."
   if camp.orders>=int(camp.minimum_orders) and (camp.reason=="crime" or tax_summary(s).total==0): return "Your work orders are complete."
   camp.orders += 1; camp.sorted = []
   s.city.supplies.metal += 2; s.city.supplies.fabric += 1
   var retired = mini(1,int(tax_summary(s).total))
   if retired>0:
    _retire_tax(s,retired); s.taxes.worked_off += retired; camp.worked_off += retired; _tax_ledger(s,"work",retired)
   e.append({"type":"notice","text":"WORK ORDER %d / 3 COUNTED\nZero wages."%int(camp.orders)})
  "camp_meal": s.needs.hunger = maxf(45,s.needs.hunger); s.needs.thirst = maxf(55,s.needs.thirst)
  "camp_sleep": _advance(s,120,true); s.needs.energy = minf(70,s.needs.energy+35)
  "camp_release":
   if camp.orders<int(camp.minimum_orders): return "Complete the three work orders before release."
   if camp.reason in ["tax","mixed"] and tax_summary(s).total>0: return "The outstanding tax must be worked off before release."
   s.housing.next_bill += int(s.minute)-int(camp.started)
   var tax_pause = int(s.minute)-int(camp.tax_pause_started)
   s.taxes.next_due += tax_pause; s.taxes.grace_until += tax_pause
   for item in s.items:
    if item.owner=="held": item.owner = "player"; item.history.append({"minute":s.minute,"custody":"player"})
   camp.active = false; camp.released = s.minute; s.location = "room"
   s.needs.health = maxf(25,s.needs.health); s.needs.energy = maxf(22,s.needs.energy)
   e.append({"type":"thought","text":"My door. Still here."})
 return ""

static func is_spoiled(item: Dictionary,minute: int) -> bool:
 return int(item.get("expiry_minute",0))>0 and minute>=int(item.expiry_minute)+int(item.get("cold_minutes",0))

static func _store_item(s: Dictionary,c: Dictionary,e: Array) -> String:
 if s.location!="room" or not s.shift.is_empty(): return "My storage is at home."
 var item = _find(s,str(c.get("id","")))
 if item.is_empty() or item.owner!="player": return "That isn't mine to move."
 var destination = str(c.get("storage",""))
 if destination not in ["bag","locker","fridge"]: return "There is no storage there."
 if destination==item.get("storage","bag"): return "It's already there."
 if destination=="fridge":
  if not "fridge" in s.room_upgrades: return "I don't have a refrigerator."
  var definition = catalog().items.get(item.kind,{})
  if not definition.has("food") and not definition.has("water"): return "That doesn't belong in the cold cabinet."
  if is_spoiled(item,int(s.minute)): return "Cold won't fix spoiled food."
 item.storage = destination
 item.history.append({"minute":s.minute,"storage":destination})
 e.append({"type":"sound","name":"cloth"})
 return ""

static func _consume(s: Dictionary,id: String,e: Array) -> String:
 var item = _find(s,id)
 if item.is_empty() or item.owner!="player": return "I don't have that."
 var def = catalog().items.get(item.kind,{})
 if not def.has("food") and not def.has("water"): return "That isn't something to eat or drink."
 if item.get("storage","bag")!="bag" and s.location!="room": return "I left that at home."
 if is_spoiled(item,int(s.minute)): return "It's spoiled. I shouldn't eat it."
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
 var item = {"id":"IX-%s-%05d"%[s.identity.civic_id,int(s.serial)],"kind":kind,"label":label,"owner":owner,"rightful_owner":"player" if owner=="player" else origin,"serial":"R-%05d"%int(s.serial),"origin":origin,"condition":"worn" if metadata.get("upgrade",false) else "intact","legal":"ordinary","acquired_minute":s.minute,"expiry_minute":s.minute+int(metadata.get("shelf_days",0))*1440 if metadata.has("shelf_days") else 0,"storage":"bag","cold_minutes":0,"metadata":metadata.duplicate(true),"history":[{"minute":s.minute,"custody":owner}]}
 s.items.append(item)
 return item

static func _owned(s: Dictionary,kind: String) -> Dictionary:
 for item in s.items:
  if item.kind==kind and item.owner=="player" and (item.get("storage","bag")=="bag" or s.location=="room"): return item
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
 for item in s.items:
  if item.owner=="player" and item.get("storage","bag")=="fridge" and "fridge" in s.room_upgrades and s.housing.utilities and not is_spoiled(item,int(s.minute)):
   item.cold_minutes = mini(COLD_ALLOWANCE,int(item.get("cold_minutes",0))+minutes)
 s.minute += minutes
 s.needs.hunger = maxf(0,s.needs.hunger-hours*(1.5 if sleeping or camp else 4.0))
 s.needs.thirst = maxf(0,s.needs.thirst-hours*(2.0 if sleeping or camp else 6.0))
 s.needs.hygiene = maxf(0,s.needs.hygiene-hours)
 if not sleeping: s.needs.energy = maxf(0,s.needs.energy-hours)
 if s.needs.hunger<15 or s.needs.thirst<15: s.needs.health = maxf(10,s.needs.health-hours*1.5)
 if not camp:
  _tax_clock(s)
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

static func fold_steps(garment: Dictionary) -> int:
 return 2 if garment.get("type","")=="medical" else 3

static func _whole_number(value: Variant) -> bool:
 return value is int or (value is float and is_finite(value) and value==floor(value))

static func available_encounters(s: Dictionary) -> Array:
 var out: Array = []
 if not s.identity.registered or not s.shift.is_empty() or s.legal.camp.get("active",false): return out
 var day = int(s.minute/1440)
 var shifts = 0
 for job in s.jobs.values(): shifts += int(job.shifts)
 var definitions = [
  {"id":"street_inspection","title":"Service gate inspection","text":"The gate officer holds out a gloved hand beneath the service warning sign. Papers, then passage.","choices":[{"id":"present","label":"Present civic paper · 10 min"},{"id":"wait","label":"Wait in the inspection queue · 20 min"}],"ready":s.location=="service","cooldown":2},
  {"id":"neighbor_help","title":"The landing basket","text":"A neighbor struggles with a basket. Their hands shake.","choices":[{"id":"carry","label":"Carry the basket upstairs · 20 min"},{"id":"share","label":"Share carried bread or ration paste · 5 min"},{"id":"decline","label":"Keep walking"}],"ready":s.location=="hall" and shifts>=1,"cooldown":3},
  {"id":"coworker_cover","title":"An empty station","text":"One attendant never arrived. A coworker asks for help clearing their station.","choices":[{"id":"help","label":"Help clear the station · 25 min"},{"id":"decline","label":"Leave it for the next attendant"}],"ready":s.location=="laundry" and s.employment=="laundry" and s.jobs.laundry.shifts>=1,"cooldown":3},
  {"id":"service_repair","title":"Rattling service cabinet","text":"A loose relay chatters behind the cabinet door. Someone left a maintenance kit.","choices":[{"id":"repair","label":"Reseat the relay and secure the cover · 30 min"}],"ready":s.location=="service" and not s.city.flags.get("service_repaired",false),"cooldown":-1},
  {"id":"relay_detail","title":"Restored relay recording","text":"The repaired relay has recovered a damaged return-count recording. The playback switch is lit.","choices":[{"id":"listen","label":"Listen beside the cabinet · 10 min"}],"ready":s.location=="service" and s.city.flags.get("service_repaired",false) and not s.city.flags.get("relay_heard",false),"cooldown":-1}
 ]
 for definition in definitions:
  if not definition.ready: continue
  var previous = s.city.encounters.get(definition.id,{})
  if not (definition.id=="street_inspection" and s.taxes.flagged) and not previous.is_empty() and (definition.cooldown<0 or day-int(previous.last_day)<int(definition.cooldown)): continue
  if definition.id=="street_inspection" and int(s.city.security_favor)>0:
   definition.choices.append({"id":"favor","label":"Mention the service repair · 5 min"})
  out.append({"object":{"street_inspection":"guard","neighbor_help":"neighbor","coworker_cover":"coworker","service_repair":"cabinet","relay_detail":"relay"}[definition.id],"id":definition.id,"title":definition.title,"text":definition.text+_background_encounter_text(str(s.identity.background),str(definition.id)),"choices":definition.choices.duplicate(true)})
 return out

static func _event_choice(s: Dictionary,c: Dictionary,e: Array) -> String:
 var id = str(c.get("event","")); var choice = str(c.get("choice","")); var found = false
 for encounter in available_encounters(s):
  if encounter.id==id and encounter.choices.any(func(option): return option.id==choice): found = true; break
 if not found: return "That encounter or choice is no longer available."
 var minutes = 0; var text = ""
 match id:
  "street_inspection":
   minutes = 5 if choice=="favor" else 10 if choice=="present" else 20
   s.legal.suspicion = maxi(0,int(s.legal.suspicion)-2)
   s.city.flags.inspection_day = int(s.minute/1440)
   text = "The officer remembers the repaired lights. A quick check, then a nod." if choice=="favor" else "The officer compares the number twice. Then waves me through."
  "neighbor_help":
   if choice=="share":
    var food: Dictionary = {}
    for item in s.items:
     if c.has("item_id") and item.id!=str(c.item_id): continue
     if item.owner=="player" and item.storage=="bag" and item.kind in ["bread","paste"] and not is_spoiled(item,int(s.minute)): food = item; break
    if food.is_empty(): return "I need unspoiled bread or ration paste in my bag."
    food.owner = "neighbor"; food.history.append({"minute":s.minute,"custody":"neighbor"}); minutes = 5
   elif choice=="carry": minutes = 20
   if choice!="decline":
    _item(s,"soap","Soap","player","Neighbor's spare supply",catalog().items.soap)
    s.city.flags.neighbor_known = true
   text = "They press a spare bar of soap into my hand. \"The service corridor cabinet rattles. It used to power the lamps and a recording relay. Fix it and there might be something left to hear.\"" if choice!="decline" else "The basket scrapes another step behind me."
  "coworker_cover":
   if choice=="help":
    minutes = 25; _item(s,"paste","Ration paste","player","Coworker's spare ration",catalog().items.paste); s.city.flags.coworker_known = true
   text = "A ration pouch changes hands. No supervisor notices." if choice=="help" else "The empty station stays empty."
  "service_repair":
   minutes = 30; s.city.flags.service_repaired = true; s.city.security_favor = mini(100,int(s.city.security_favor)+1)
   _item(s,"soap","Soap","player","Maintenance cabinet spare supply",catalog().items.soap)
   text = "The cabinet quiets and the corridor lamps come back on. The gate officer acknowledges the repair. The relay playback light is on: its restored recording is available now."
  "relay_detail":
   minutes = 10; s.city.flags.relay_heard = true
   var note = "SERVICE RELAY / RECORDED RETURN COUNT\n17 present / 18 returned. Leave the extra name on the sheet."
   _item(s,"note","Relay count transcription","player","Service relay",{"text":note})
   if "relay_signal" not in s.discoveries: s.discoveries.append("relay_signal")
   text = note
 s.city.encounters[id] = {"count":int(s.city.encounters.get(id,{}).get("count",0))+1,"last_day":int(s.minute/1440),"last_minute":int(s.minute),"last_choice":choice}
 s.decisions.append({"event":id,"choice":choice,"minute":int(s.minute)})
 if s.decisions.size()>120: s.decisions = s.decisions.slice(-120)
 _advance(s,minutes)
 if id=="street_inspection" and s.taxes.flagged:
  _enter_camp(s,e,"tax")
  return ""
 e.append({"type":"thought","text":text})
 return ""

static func _background_encounter_text(background: String,event: String) -> String:
 var knowledge = {
  "factory_laborer":{"coworker_cover":"I remember clearing an absent worker's station on the factory line. Someone still has to count their output.","service_repair":"The chatter sounds like a loose contact on the old line. The kit here should be enough."},
  "displaced_resident":{"neighbor_help":"I recognize them from the relocation queue. They carried somebody else's basket then, too."},
  "former_bureaucrat":{"street_inspection":"The guard wants the civic number facing up. I used to file these inspection sheets.","relay_detail":"Recorded return count. I remember those sheets: extra names were copied forward, never crossed out.","service_repair":"This cabinet carried the return counts to the clerks. Repairing it may recover the recording."},
  "street_survivor":{"street_inspection":"The queue moves eventually. The public tap is still free after the guard lets me through.","neighbor_help":"A shared ration can mean more than a promise. Bread or paste from my bag would do."},
  "technical_apprentice":{"service_repair":"The training card named this cabinet. Reseat the relay, secure the cover; the tools are already here.","relay_detail":"The recorder is working again. That repeated voice is stored on the relay, not a mechanical rattle."}
 }
 var text = str(knowledge.get(background,{}).get(event,""))
 return "\n\n"+text if text!="" else ""

static func _initial_taxes(minute: int) -> Dictionary:
 return {"accrued":0,"due":0,"grace_due":0,"next_due":minute+4320,"grace_until":minute+5760,"flagged":false,"worked_off":0,"ledger":[]}

static func tax_summary(s: Dictionary) -> Dictionary:
 var t = s.taxes
 return {"accrued":int(t.accrued),"due":int(t.due),"grace_due":int(t.grace_due),"overdue":int(t.due)-int(t.grace_due),"total":int(t.due)+int(t.accrued),"next_due":int(t.next_due),"grace_until":int(t.grace_until),"flagged":t.flagged,"paid":int(s.tax_paid),"worked_off":int(t.worked_off)}

static func _valid_taxes(t: Dictionary) -> bool:
 for key in ["accrued","due","grace_due","next_due","grace_until","worked_off"]:
  if not _whole_number(t.get(key)) or int(t[key])<0: return false
 if not t.get("flagged") is bool or not t.get("ledger") is Array: return false
 if t.ledger.size()>120: return false
 if int(t.grace_due)>int(t.due) or t.flagged!=(int(t.due)>int(t.grace_due)): return false
 if int(t.next_due)<=0 or int(t.grace_until)<=0: return false
 if int(t.grace_due)>0 and int(t.grace_until)>=int(t.next_due): return false
 for entry in t.ledger:
  if not entry is Dictionary or not entry.get("type") is String: return false
  if not _whole_number(entry.get("minute")) or int(entry.minute)<0 or not _whole_number(entry.get("amount")) or int(entry.amount)<0: return false
 return true

static func _tax_ledger(s: Dictionary,type: String,amount: int,minute: int=-1) -> void:
 s.taxes.ledger.append({"type":type,"amount":amount,"minute":int(s.minute) if minute<0 else minute})
 if s.taxes.ledger.size()>120: s.taxes.ledger = s.taxes.ledger.slice(-120)

static func _tax_clock(s: Dictionary) -> void:
 var t = s.taxes
 while true:
  # An older bill's grace must expire before a later billing cycle is assessed.
  if int(t.grace_due)>0 and int(t.grace_until)<=int(s.minute) and int(t.grace_until)<=int(t.next_due):
   _tax_ledger(s,"grace_expired",int(t.grace_due),int(t.grace_until)); t.grace_due = 0
  elif int(t.next_due)<=int(s.minute):
   var boundary = int(t.next_due); var bill = int(t.accrued)
   t.due += bill; t.accrued = 0; t.grace_due = bill; t.grace_until = boundary+1440; t.next_due = boundary+4320
   _tax_ledger(s,"bill",bill,boundary)
  else: break
 t.flagged = int(t.due)>int(t.grace_due)

static func _retire_tax(s: Dictionary,amount: int) -> void:
 var t = s.taxes
 var overdue_payment = mini(amount,int(t.due)-int(t.grace_due)); t.due -= overdue_payment; amount -= overdue_payment
 var grace_payment = mini(amount,int(t.grace_due)); t.grace_due -= grace_payment; t.due -= grace_payment; amount -= grace_payment
 t.accrued -= amount
 t.flagged = int(t.due)>int(t.grace_due)

static func _pay_tax(s: Dictionary,c: Dictionary,e: Array) -> String:
 if s.location!="bureau" or not s.shift.is_empty() or s.legal.camp.get("active",false): return "Tax payments are taken at the bureau counter after work."
 if not _whole_number(c.get("amount")) or int(c.amount)<=0: return "Choose a positive whole-credit payment."
 var amount = int(c.amount)
 if amount>int(s.credits): return "I cannot pay more credits than I have."
 if amount>int(tax_summary(s).total): return "That is more than the outstanding tax."
 _retire_tax(s,amount); s.credits -= amount; s.tax_paid += amount; _tax_ledger(s,"payment",amount)
 e.append({"type":"thought","text":"The clerk stamps the payment. Keep the receipt."})
 return ""
