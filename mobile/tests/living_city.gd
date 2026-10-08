extends SceneTree
const Sim = preload("res://src/simulation.gd")
const Store = preload("res://src/save_store.gd")
var passed = 0
var failed = 0

func check(ok: bool,label: String) -> void:
 if ok: passed += 1
 else: failed += 1; printerr("FAIL LIVING CITY: "+label)

func act(s: Dictionary,c: Dictionary) -> Dictionary:
 var result = Sim.apply(s,c)
 check(result.ok,"accepted "+str(c))
 return result.state

func reject(s: Dictionary,c: Dictionary,label: String) -> void:
 var snapshot = s.duplicate(true)
 var result = Sim.apply(s,c)
 check(not result.ok and result.state==snapshot and s==snapshot,label)

func reload(s: Dictionary,store: RefCounted) -> Dictionary:
 check(store.save_state(s),"persist partial physical action")
 var restored = store.load_state()
 check(json_equivalent(restored,s),"reload retains garment progress, counters and needs within JSON precision")
 return restored

func laundry() -> void:
 var s = Sim.initial(); s.identity.registered = true; s.location = "laundry"; s.employment = "laundry"
 var start = s.minute
 s = act(s,{"action":"begin_shift"})
 for i in range(4):
  s = act(s,{"action":"inspect_uniform","index":i})
  s = act(s,{"action":"inspect_pocket","index":i})
  s = act(s,{"action":"sort_uniform","index":i,"bin":s.shift.uniforms[i].type})
 s = act(s,{"action":"open_hatch"})
 reject(s,{"action":"load_garment","index":0.5},"fractional garment index rejects atomically")
 reject(s,{"action":"load_garment","index":"0"},"string garment index rejects atomically")
 s = act(s,{"action":"load_garment","index":0})
 reject(s,{"action":"load_garment","index":0},"duplicate loading rejects atomically")
 check(s.shift.stage=="inspect" and s.shift.minutes==80,"partial load keeps inspection stage and time")
 var store = Store.new("user://living-city-test-"+str(Time.get_ticks_usec()))
 s = reload(s,store)
 for i in range(1,4): s = act(s,{"action":"load_garment","index":i})
 check(s.shift.stage=="prepare" and s.shift.minutes==100,"final load charges preparation once")
 for action in ["dose","dose","close_hatch","start_wash"]: s = act(s,{"action":action})
 s = act(s,{"action":"unload_garment","index":0})
 check(s.shift.stage=="washed" and s.shift.minutes==160,"partial unload keeps washed stage")
 s = reload(s,store)
 reject(s,{"action":"unload_garment","index":0},"duplicate unloading rejects")
 for i in range(1,4): s = act(s,{"action":"unload_garment","index":i})
 s = act(s,{"action":"dry"})
 reject(s,{"action":"fold_garment","index":0,"step":2},"skipping folds rejects without mutation")
 s = act(s,{"action":"fold_garment","index":0,"step":1})
 reject(s,{"action":"fold_garment","index":0,"step":1},"replayed fold rejects without mutation")
 s = reload(s,store)
 for i in range(4):
  for step in range(int(s.shift.uniforms[i].folds)+1,Sim.fold_steps(s.shift.uniforms[i])+1):
   s = act(s,{"action":"fold_garment","index":i,"step":step})
 check(s.shift.stage=="folded" and s.shift.minutes==230,"final fold charges once")
 for action in ["dispatch","settle_shift"]: s = act(s,{"action":action})
 check(s.minute-start==240 and s.credits==11 and s.jobs.laundry.shifts==1,"physical shift costs240min and settles full wage once")
 reject(s,{"action":"settle_shift"},"wage cannot replay")
 check(Sim.fold_steps({"type":"medical"})==2,"medical smock has shorter folding sequence")

func _initialize() -> void:
 laundry()
 city()
 migration()
 discoverability()
 restored_encounters()
 security_favor()
 print("SCHISM living city: %d checks passed; %d failed."%[passed,failed])
 quit(1 if failed else 0)

func city() -> void:
 var s = Sim.initial(); s.identity.registered = true; s.location = "service"; s.minute = 1800; s.legal.suspicion = 5
 var before = s.duplicate(true); var options = Sim.available_encounters(s)
 check(options.any(func(option): return option.id=="street_inspection") and s==before,"encounter discovery is pure and deterministic")
 reject(s,{"action":"event_choice","event":"street_inspection","choice":"bribe"},"unknown choice rejects")
 reject(s,{"action":"event_choice","event":"street_inspection","choice":"present","expected_revision":99},"stale event revision rejects")
 s = act(s,{"action":"event_choice","event":"street_inspection","choice":"wait"})
 check(s.minute==1820 and s.legal.suspicion==3 and s.city.flags.inspection_day==1,"queue clears inspection with authored time and suspicion")
 reject(s,{"action":"event_choice","event":"street_inspection","choice":"present"},"inspection cooldown cannot replay")
 s.minute = 4680
 check(Sim.available_encounters(s).any(func(option): return option.id=="street_inspection"),"inspection returns after two played days")
 s.location = "hall"; s.minute = 2100; s.jobs.laundry.shifts = 1
 reject(s,{"action":"event_choice","event":"neighbor_help","choice":"share"},"sharing without carried food rejects atomically")
 var bread = Sim._item(s,"bread","Bread","player","Test kiosk",Sim.catalog().items.bread)
 s = act(s,{"action":"event_choice","event":"neighbor_help","choice":"share"})
 check(s.items[0].id==bread.id and s.items[0].owner=="neighbor" and s.items[0].history[-1].custody=="neighbor","neighbor food transfer retains custody identity")
 check(s.items[-1].kind=="soap" and s.minute==2105 and s.city.flags.neighbor_known,"neighbor reward and elapsed time")
 reject(s,{"action":"event_choice","event":"neighbor_help","choice":"carry"},"neighbor rewards cannot duplicate")
 s.location = "laundry"; s.employment = "laundry"
 s = act(s,{"action":"event_choice","event":"coworker_cover","choice":"help"})
 check(s.items[-1].kind=="paste" and s.minute==2130 and s.city.flags.coworker_known,"coworker gives a ration for time")
 s.location = "street"
 s = act(s,{"action":"travel","to":"service"})
 s = act(s,{"action":"event_choice","event":"service_repair","choice":"repair"})
 check(s.city.flags.service_repaired and s.items[-1].kind=="soap","service cabinet repair gives tangible reward")
 reject(s,{"action":"event_choice","event":"service_repair","choice":"repair"},"repair reward is once only")
 s.minute = 2580
 s = act(s,{"action":"event_choice","event":"relay_detail","choice":"listen"})
 check(s.items[-1].metadata.text.contains("17 present / 18 returned") and "relay_signal" in s.discoveries,"night relay yields persistent mystery note")
 reject(s,{"action":"event_choice","event":"relay_detail","choice":"listen"},"relay note cannot duplicate")
 var saved = Sim.migrate(JSON.parse_string(JSON.stringify(s)))
 check(json_equivalent(saved.city,s.city),"event decisions and cooldowns persist JSON migration")
 s.shift = {"job":"laundry"}
 check(Sim.available_encounters(s).is_empty(),"active work suppresses encounters")

func migration() -> void:
 for background in Sim.BACKGROUNDS:
  var s = act(Sim.initial(),{"action":"register","name":"City Test","background":background})
  check(s.credits==4 and s.needs==Sim.initial().needs and s.identity.background==background,"background preserves equal starting economy "+background)
  check(s.items.size()==(0 if background=="resident" else 1),"nonresident gets one flavor memento "+background)
 var legacy = Sim.initial(); legacy.schema = 4; legacy.erase("city"); legacy.identity.erase("background")
 legacy.items = [{"metadata":{"future_note":{"author":"Unknown","value":72}},"history":[]}]
 var migrated = Sim.migrate(legacy)
 check(migrated.schema==6 and migrated.identity.background=="resident" and migrated.city.encounters.is_empty(),"legacy city fields gain safe defaults")
 check(migrated.items[0].metadata==legacy.items[0].metadata and migrated.items.size()==1,"migration preserves unknown metadata and grants no memento")
 for stage in ["inspect","prepare","washed","wet","dry","folded","receipt"]:
  var work = Sim.initial(); work.schema = 4
  work.shift = {"job":"laundry","stage":stage,"uniforms":[{"type":"medical","custom":"retain"}]}
  var restored = Sim.migrate(work)
  check(not restored.has("error") and restored.shift.uniforms[0].custom=="retain" and restored.shift.uniforms[0].folds==(2 if stage in ["folded","receipt"] else 0),"migrate laundry progress "+stage)
 for broken in [{"city":[]},{"city":{"encounters":[]}},{"city":{"encounters":{"x":4}}},{"identity":{"background":5}},{"shift":{"job":"laundry","uniforms":[{"folds":"2"}]}}]:
  var value = Sim.initial()
  for key in broken: value[key] = broken[key]
  var snapshot = value.duplicate(true)
  check(Sim.migrate(value).has("error") and value==snapshot,"malformed new fields preserve source for recovery")
 reject(Sim.initial(),{"action":"register","name":"City Test","background":"chosen_one"},"invalid background rejects before memento")

func discoverability() -> void:
 var clues = {"factory_laborer":"sanitize","displaced_resident":"neighbor","former_bureaucrat":"recording","street_survivor":"public tap","technical_apprentice":"corridor lamps"}
 for background in clues:
  var registered = act(Sim.initial(),{"action":"register","name":"City Test","background":background})
  check(registered.items[0].metadata.text.contains(clues[background]),"background memento supplies concrete clue "+background)
 var s = Sim.initial(); s.identity.registered = true; s.location = "hall"; s.minute = 600; s.jobs.laundry.shifts = 1
 var ordinary = Sim.available_encounters(s)[0]
 s.identity.background = "displaced_resident"
 var familiar = Sim.available_encounters(s)[0]
 check(familiar.text.contains("relocation queue") and ordinary.choices==familiar.choices,"background knowledge changes recognition without exclusive choices")
 var helped = Sim.apply(s,{"action":"event_choice","event":"neighbor_help","choice":"carry"})
 check(helped.ok and helped.events[0].text.contains("service corridor") and helped.events[0].text.contains("Fix it"),"neighbor points toward self-directed repair exploration")
 s = helped.state; s.location = "service"
 var repaired = Sim.apply(s,{"action":"event_choice","event":"service_repair","choice":"repair"})
 check(repaired.ok and repaired.events[0].text.contains("available now"),"repair completion reveals immediate recording")

# JSON stores every number as float and rounds decimal needs. Compare the saved
# semantics recursively, while preserving exact whole counters and bool/string types.
func json_equivalent(a: Variant,b: Variant) -> bool:
 if a is Dictionary and b is Dictionary:
  if a.size()!=b.size(): return false
  for key in a:
   if not b.has(key) or not json_equivalent(a[key],b[key]): return false
  return true
 if a is Array and b is Array:
  if a.size()!=b.size(): return false
  for i in range(a.size()):
   if not json_equivalent(a[i],b[i]): return false
  return true
 if (a is int or a is float) and (b is int or b is float):
  if floor(float(a))==float(a) and floor(float(b))==float(b): return float(a)==float(b)
  return absf(float(a)-float(b))<0.0000000001
 return typeof(a)==typeof(b) and a==b

func restored_encounters() -> void:
 var cases = [
  {"event":"street_inspection","choice":"present","location":"service","minute":1800,"reward":""},
  {"event":"neighbor_help","choice":"carry","location":"hall","minute":600,"reward":"soap"},
  {"event":"coworker_cover","choice":"help","location":"laundry","minute":630,"reward":"paste"},
  {"event":"service_repair","choice":"repair","location":"service","minute":630,"reward":"soap"},
  {"event":"relay_detail","choice":"listen","location":"service","minute":1140,"reward":"note"}
 ]
 for example in cases:
  var s = Sim.initial(); s.identity.registered = true; s.location = example.location; s.minute = example.minute
  s.employment = "laundry"; s.jobs.laundry.shifts = 1
  if example.event=="relay_detail": s.city.flags.service_repaired = true
  var store = Store.new("user://restored-encounter-"+example.event+"-"+str(Time.get_ticks_usec()))
  s = reload(s,store)
  check(s.minute is float,"real JSON restore supplies float minute "+example.event)
  var options = Sim.available_encounters(s)
  check(options.any(func(option): return option.id==example.event),"restored encounter remains eligible "+example.event)
  s = act(s,{"action":"event_choice","event":example.event,"choice":example.choice})
  if example.reward!="": check(s.items[-1].kind==example.reward,"restored event grants authored reward "+example.event)
  check(s.city.encounters[example.event].count==1,"restored event records one choice "+example.event)
  var awarded = s.items.size(); var minute = s.minute
  s = reload(s,store)
  check(not Sim.available_encounters(s).any(func(option): return option.id==example.event),"cooldown eligibility survives actual save/reload "+example.event)
  reject(s,{"action":"event_choice","event":example.event,"choice":example.choice},"restored event cannot replay reward "+example.event)
  check(s.items.size()==awarded and s.minute==minute,"duplicate restored choice preserves reward/time "+example.event)

func security_favor() -> void:
 var s = Sim.initial(); s.identity.registered = true; s.location = "service"; s.minute = 1380
 var options = Sim.available_encounters(s)
 check(options.any(func(option): return option.id=="street_inspection") and options.any(func(option): return option.id=="service_repair"),"service officer and repair available on first night")
 reject(s,{"action":"event_choice","event":"street_inspection","choice":"favor"},"unearned favor rejects")
 s = act(s,{"action":"event_choice","event":"service_repair","choice":"repair"})
 check(s.city.security_favor==1 and s.city.flags.service_repaired,"repair restores lights and earns one security favor")
 check(Sim.available_encounters(s).any(func(option): return option.id=="relay_detail"),"recording available immediately after night repair")
 s = act(s,{"action":"event_choice","event":"relay_detail","choice":"listen"})
 check(s.minute==1420 and s.items[-1].metadata.text.contains("RECORDED RETURN COUNT"),"recording plays immediately without waiting")
 var store = Store.new("user://security-favor-"+str(Time.get_ticks_usec()))
 s = reload(s,store); s.legal.suspicion = 5
 var inspection: Dictionary = {}
 for option in Sim.available_encounters(s):
  if option.id=="street_inspection": inspection = option
 check(inspection.choices.size()==3 and inspection.choices.any(func(choice): return choice.id=="favor"),"reloaded service officer recognizes favor")
 for choice in ["present","wait","favor"]:
  var result = Sim.apply(s,{"action":"event_choice","event":"street_inspection","choice":choice})
  check(result.ok and result.state.minute-s.minute==({"present":10,"wait":20,"favor":5}[choice]) and result.state.legal.suspicion==3,"service officer authored choice "+choice)
  check(result.state.city.security_favor==1,"inspection does not consume repair favor "+choice)
 s = act(s,{"action":"event_choice","event":"street_inspection","choice":"favor"})
 s = reload(s,store)
 reject(s,{"action":"event_choice","event":"street_inspection","choice":"favor"},"favor stamp retains cooldown through reload")
 var legacy = Sim.initial(); legacy.schema = 5; legacy.city.erase("security_favor"); legacy.city.flags.service_repaired = true
 var migrated = Sim.migrate(legacy)
 check(migrated.city.security_favor==1 and Sim.migrate(migrated).city.security_favor==1,"unreleased repaired save earns migration favor exactly once")
 legacy.schema = 4
 check(Sim.migrate(legacy).city.security_favor==0,"schema4 city remains neutral during migration")
 legacy.schema = 5; legacy.city.security_favor = 0
 check(Sim.migrate(legacy).city.security_favor==0,"explicit zero favor is preserved")
 for bad in [-1,101,0.5,"1",true]:
  legacy.city.security_favor = bad
  check(Sim.migrate(legacy).has("error"),"malformed security favor is held for recovery "+str(bad))
 for location in ["hall","laundry"]:
  var anytime = Sim.initial(); anytime.identity.registered = true; anytime.location = location; anytime.employment = "laundry"; anytime.jobs.laundry.shifts = 1; anytime.minute = 1380
  check(not Sim.available_encounters(anytime).is_empty(),"job-history encounter available at night "+location)
