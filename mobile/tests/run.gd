extends SceneTree
const Sim = preload("res://src/simulation.gd")
const Store = preload("res://src/save_store.gd")
var passed = 0
var failed = 0

func check(ok: bool,label: String) -> void:
 if ok: passed += 1
 else: failed += 1; printerr("FAIL: "+label)

func act(s: Dictionary,c: Dictionary) -> Dictionary:
 var r = Sim.apply(s,c)
 check(r.ok,"accepted "+str(c))
 return r.state

func resident(job: String="laundry") -> Dictionary:
 var s = Sim.initial()
 s = act(s,{"action":"register","name":"Test Citizen"})
 s = act(s,{"action":"arrival"})
 s = act(s,{"action":"travel","to":"hall"})
 s = act(s,{"action":"travel","to":"street"})
 s = act(s,{"action":"travel","to":"bureau"})
 s = act(s,{"action":"ticket"})
 s = act(s,{"action":"show_id"})
 s = act(s,{"action":"apply_job","job":job})
 s = act(s,{"action":"travel","to":"street"})
 s = act(s,{"action":"travel","to":job})
 return s

func laundry(s: Dictionary,choice: String="return",correct: bool=true) -> Dictionary:
 s = act(s,{"action":"begin_shift"})
 var cycle = "standard"
 for i in range(4):
  s = act(s,{"action":"inspect_uniform","index":i})
  s = act(s,{"action":"inspect_pocket","index":i})
  var u = s.shift.uniforms[i]
  if u.found!="": s = act(s,{"action":"found_choice","id":u.found,"choice":choice})
  if u.stain=="blood": cycle = "sanitize"
  elif u.stain=="oil" and cycle!="sanitize": cycle = "hot"
  s = act(s,{"action":"sort_uniform","index":i,"bin":u.type if correct else "medical"})
 s = act(s,{"action":"open_hatch"})
 for i in range(4): s = act(s,{"action":"load_garment","index":i})
 for a in ["dose","dose"]: s = act(s,{"action":a})
 s = act(s,{"action":"cycle","cycle":cycle if correct else "sanitize"})
 for a in ["close_hatch","start_wash"]: s = act(s,{"action":a})
 for i in range(4): s = act(s,{"action":"unload_garment","index":i})
 s = act(s,{"action":"dry"})
 for i in range(4):
  for step in range(1,Sim.fold_steps(s.shift.uniforms[i])+1): s = act(s,{"action":"fold_garment","index":i,"step":step})
 for a in ["dispatch","settle_shift"]: s = act(s,{"action":a})
 return s

func _initialize() -> void:
 var original = Sim.initial()
 var s = resident()
 check(s.identity.registered and s.employment=="laundry","physical bureau assigns employment")
 check(s.needs.hunger<52 and s.needs.thirst<46,"travel decays needs by simulation time")
 var invalid = Sim.apply(s,{"action":"buy","kind":"bread"})
 check(not invalid.ok and invalid.state==s,"off-site purchase rejects atomically")
 check(not Sim.apply(s,{"action":"travel","to":"room"}).ok,"invalid scene teleport rejects")
 check(not Sim.apply(s,{"action":"setting","key":"credits","value":true}).ok,"settings cannot edit money")
 check(not Sim.apply(s,{"action":"begin_shift","expected_revision":-1}).ok,"stale revision rejects")
 var before = s.duplicate(true)
 s = laundry(s)
 check(s.last_receipt.gross==7 and s.last_receipt.withholding==0 and s.last_receipt.net==7,"first laundry gross and carried tax")
 check(s.credits==11 and s.jobs.laundry.shifts==1 and s.jobs.laundry.trust==2,"wages, returned property, clean history")
 check(s.tax_remainder==84 and s.shift.is_empty(),"fractional withholding carried and shift removed")
 check(s.last_receipt.quality==100,"correct physical preparation gives quality")
 check(s.minute-before.minute==240,"shift advances exactly four simulation hours")
 check(before.credits==4 and before.jobs.laundry.shifts==0,"pure reducer leaves input intact")
 check(not Sim.apply(s,{"action":"settle_shift"}).ok,"duplicate wage settlement rejected")
 s.needs.energy = 100; s.needs.thirst = 100; s.needs.hunger = 100
 s = laundry(s,"keep")
 check(s.tax_paid==0 and s.taxes.accrued==1 and s.tax_remainder==68,"second shift assesses carried tax for manual payment")
 check(s.items.any(func(x): return x.kind=="tape" and x.owner=="player"),"later mystery object has persistent ownership")
 var bad = resident(); bad = laundry(bad,"leave",false)
 check(bad.last_receipt.quality<60 and bad.last_receipt.gross==6 and bad.jobs.laundry.warnings==1,"bad treatment damages work and produces warning")
 var theft = resident(); theft.rng = 1
 theft = laundry(theft,"keep")
 check(theft.legal.offenses==1 and theft.legal.record[0].evidence.contains("logged pocket"),"detection explains actual evidence")
 check(theft.credits==9 and theft.illicit_credits==0,"confiscated credits and capped fine conserve wallet")
 check(theft.items[0].owner=="confiscated","confiscation retains item identity")
 var escaped = resident(); escaped.rng = 1000000
 escaped = laundry(escaped,"keep")
 check(escaped.legal.offenses==0 and escaped.credits==14 and escaped.illicit_credits==3,"uncaught petty theft grants unreported credits")
 var inspect = act(resident(),{"action":"begin_shift"})
 var iid = inspect.shift.uniforms[1].found
 check(not Sim.apply(inspect,{"action":"found_choice","id":iid,"choice":"keep"}).ok,"cannot take hidden item before pocket inspection")
 inspect = act(inspect,{"action":"inspect_uniform","index":1}); inspect = act(inspect,{"action":"inspect_pocket","index":1})
 inspect = act(inspect,{"action":"found_choice","id":iid,"choice":"return"})
 check(not Sim.apply(inspect,{"action":"found_choice","id":iid,"choice":"keep"}).ok,"item custody cannot be replayed")
 check(not Sim.apply(inspect,{"action":"travel","to":"street"}).ok,"work order prevents abandoning evidence by exit")
 var shop = resident(); shop = act(shop,{"action":"travel","to":"street"}); shop = act(shop,{"action":"travel","to":"shop"})
 shop = act(shop,{"action":"buy","kind":"bread"}); var bread = shop.items[-1].id
 shop = act(shop,{"action":"consume","id":bread})
 check(shop.credits==1 and shop.needs.hunger>80 and shop.items[-1].owner=="consumed","food purchase and consumption retain history")
 check(not Sim.apply(shop,{"action":"consume","id":bread}).ok,"consumable cannot duplicate")
 shop = act(shop,{"action":"buy","kind":"water"}); shop.needs.thirst = 10
 shop = act(shop,{"action":"consume","id":shop.items[-1].id})
 check(shop.needs.thirst==60,"bottled water recovery")
 check(not Sim.apply(shop,{"action":"buy","kind":"stew"}).ok,"insufficient funds reject")
 shop = act(shop,{"action":"relief"}); check(not Sim.apply(shop,{"action":"relief"}).ok,"relief bounded per played day")
 shop = act(shop,{"action":"travel","to":"street"}); shop = act(shop,{"action":"drink"})
 check(shop.needs.thirst>95,"free public tap prevents thirst softlock")
 shop = act(shop,{"action":"travel","to":"hall"}); shop = act(shop,{"action":"travel","to":"room"})
 shop.needs.energy = 4; var minute = shop.minute; shop = act(shop,{"action":"sleep"})
 check(shop.needs.energy==72 and shop.minute==minute+480,"sleep advances time and restores baseline energy")
 shop.needs.hygiene = 20; shop = act(shop,{"action":"wash"}); check(shop.needs.hygiene>32,"sink hygiene without soap")
 var upgrade = shop.duplicate(true); upgrade.credits = 120; upgrade.location = "shop"
 for kind in ["kettle","soap","radio","fridge"]: upgrade = act(upgrade,{"action":"buy","kind":kind})
 upgrade.location = "room"
 for item in upgrade.items.duplicate(true):
  if item.kind in ["kettle","radio","fridge"]: upgrade = act(upgrade,{"action":"install","id":item.id})
 check("kettle" in upgrade.room_upgrades and upgrade.items.any(func(x): return x.kind=="kettle" and x.owner=="room"),"room upgrade is actual owned instance")
 check(not Sim.apply(upgrade,{"action":"install","id":upgrade.items[-1].id}).ok,"installation cannot repeat")
 upgrade.needs.hygiene = 0; upgrade = act(upgrade,{"action":"wash"})
 check(upgrade.needs.hygiene==42 and Sim._owned(upgrade,"soap").metadata.uses==2,"soap is consumed per wash")
 var expired = shop.duplicate(true); expired.location = "shop"; expired.credits = 10
 expired = act(expired,{"action":"buy","kind":"bread"}); var expired_id = expired.items[-1].id
 expired.minute += 5000; check(not Sim.apply(expired,{"action":"consume","id":expired_id}).ok,"food storage life expires on action time")
 expired.room_upgrades.append("fridge"); check(not Sim.apply(expired,{"action":"consume","id":expired_id}).ok,"owning a fridge cannot revive spoiled food in a bag")
 var housing = shop.duplicate(true); housing.location = "bureau"; housing.credits = 25
 housing = act(housing,{"action":"rent","tier":"private"})
 check(housing.housing.rent==2 and housing.credits==0,"private room deposit and daily rent")
 for day in range(12): Sim._advance(housing,1440)
 check(housing.housing.tier=="municipal" and housing.housing.arrears==8,"bounded arrears and unconditional fallback shelter")
 housing.credits = 8; housing = act(housing,{"action":"pay_rent"}); check(housing.credits==0 and housing.housing.arrears==0,"pay actual arrears")
 var progress = resident(); progress.jobs.laundry.shifts = 11; progress.location = "bureau"
 check(not Sim.apply(progress,{"action":"promote"}).ok,"vacancy checks actual shift history")
 progress.jobs.laundry.shifts = 12; progress = act(progress,{"action":"promote"})
 check(progress.jobs.laundry.promoted and not Sim._owned(progress,"key").is_empty(),"earned appointment grants a real key")
 var cleaner = resident("cleaning"); cleaner = act(cleaner,{"action":"begin_shift"})
 check(not Sim.apply(cleaner,{"action":"clean","object":"floor"}).ok,"cleaning needs workplace supplies")
 cleaner = act(cleaner,{"action":"clean","object":"supplies"})
 for object in ["floor","desk","bin"]: cleaner = act(cleaner,{"action":"clean","object":object})
 cleaner = act(cleaner,{"action":"settle_shift"}); check(cleaner.last_receipt.gross==8 and cleaner.jobs.cleaning.shifts==1,"cleaning has complete playable wage order")
 var freight = resident("freight"); freight = act(freight,{"action":"begin_shift"}); freight = act(freight,{"action":"manifest"})
 for n in range(4):
  freight = act(freight,{"action":"inspect_crate","index":n})
  if n==3:
   freight = act(freight,{"action":"open_crate","index":n})
   freight = act(freight,{"action":"found_choice","id":freight.shift.found,"choice":"return"})
  freight = act(freight,{"action":"route_crate","index":n,"destination":freight.shift.crates[n].destination})
 freight = act(freight,{"action":"settle_shift"}); check(freight.last_receipt.gross==9 and freight.last_receipt.withholding==0 and freight.last_receipt.tax_assessed==1 and freight.last_receipt.quality==100,"freight labels, manifest, ownership and wages")
 var eaten = resident("freight"); eaten.rng = 1
 eaten = act(eaten,{"action":"begin_shift"}); eaten = act(eaten,{"action":"manifest"})
 for n in range(4):
  eaten = act(eaten,{"action":"inspect_crate","index":n})
  if n==3:
   eaten = act(eaten,{"action":"open_crate","index":n})
   var parcel = eaten.shift.found
   eaten = act(eaten,{"action":"found_choice","id":parcel,"choice":"keep"})
   eaten = act(eaten,{"action":"consume","id":parcel})
  eaten = act(eaten,{"action":"route_crate","index":n,"destination":eaten.shift.crates[n].destination})
 eaten = act(eaten,{"action":"settle_shift"})
 check(eaten.legal.offenses==1 and eaten.items[0].owner=="consumed" and eaten.items[0].history[-1].custody=="evidence_counted","consuming stolen goods cannot erase manifest evidence or fines")
 var camp = resident(); camp.legal.offenses = 2; camp.rng = 1; camp.housing.rent = 2
 camp = laundry(camp,"keep")
 check(camp.location=="camp" and camp.legal.camp.active,"repeated detected theft enters playable camp")
 var due = camp.housing.next_bill; var started = camp.minute; var balance = camp.credits
 check(not Sim.apply(camp,{"action":"travel","to":"street"}).ok,"custody blocks outside navigation")
 check(not Sim.apply(camp,{"action":"camp_release"}).ok,"release requires actual completed orders")
 camp = act(camp,{"action":"camp_meal"}); camp = act(camp,{"action":"camp_sleep"})
 for order in range(3):
  for n in range(3): camp = act(camp,{"action":"camp_sort","index":n,"bin":["metal","fabric","metal"][n]})
  camp = act(camp,{"action":"camp_order"})
 check(camp.credits==balance and camp.housing.next_bill==due,"camp pays zero wages and pauses rent")
 var duration = camp.minute-started
 camp = act(camp,{"action":"camp_release"})
 check(camp.location=="room" and not camp.legal.camp.active and camp.housing.next_bill==due+duration,"release resumes billing at exact paused boundary")
 check(camp.legal.offenses==3,"record survives release")
 # Save tests use an isolated location and real atomic generations.
 var path = "user://tests-"+str(Time.get_ticks_usec()); var store = Store.new(path)
 check(store.save_state(inspect),"save active pocket choice")
 var loaded = store.load_state()
 check(loaded.shift.uniforms[1].pocket_checked and loaded.items[0].owner=="lost_property","active work reload preserves resolved custody")
 check(store.save_state(s),"second generation persists")
 check(store.load_state().last_receipt.shift_id==s.last_receipt.shift_id and int(store.load_state().last_receipt.net)==int(s.last_receipt.net),"receipt survives reload")
 # Highest generation slot is 1 after two writes; corrupt it and recover first.
 var f = FileAccess.open(path+"/slot1.json",FileAccess.WRITE); f.store_string("broken"); f.close()
 check(store.load_state().revision==inspect.revision,"corrupt latest generation recovers verified previous")
 var partial = FileAccess.open(path+"/slot0.json.pending",FileAccess.WRITE); partial.store_string("half-written"); partial.close()
 check(store.load_state().revision==inspect.revision,"interrupted pending write cannot replace good state")
 var migrated = Sim.migrate({"schema":1,"revision":9,"identity":{"name":"Old"},"items":[{"id":"history","metadata":{"unknown":"keep me"}}]})
 check(migrated.schema==Sim.SCHEMA and migrated.identity.name=="Old" and migrated.items[0].metadata.unknown=="keep me" and migrated.jobs.has("freight"),"migration preserves old identity and unknown item metadata")
 check(migrated.items[0].owner=="player" and migrated.items[0].serial=="history" and migrated.items[0].history is Array,"older item records gain inspectable custody fields without losing identity")
 check(Sim.migrate({"schema":Sim.SCHEMA+1}).has("error"),"future saves reject without wiping")
 var future = s.duplicate(true); future.schema = Sim.SCHEMA+1
 var payload = JSON.stringify(future)
 var ff = FileAccess.open(path+"/slot1.json",FileAccess.WRITE); ff.store_string(JSON.stringify({"format":"schism-local-v1","revision":future.revision,"payload":payload,"sha256":payload.sha256_text()})); ff.close()
 check(store.load_state().has("error") and not store.save_state(s),"future generation blocks overwrite")
 check(original==Sim.initial(),"baseline initial data untouched by all tests")
 print("SCHISM: %d checks passed; %d failed."%[passed,failed])
 quit(1 if failed else 0)
