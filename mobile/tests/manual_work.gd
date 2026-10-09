extends SceneTree
const Sim = preload("res://src/simulation.gd")
var passed = 0
var failed = 0

func check(ok: bool,label: String) -> void:
 if ok: passed += 1
 else: failed += 1; printerr("FAIL MANUAL WORK: "+label)

func act(s: Dictionary,c: Dictionary) -> Dictionary:
 var result = Sim.apply(s,c)
 check(result.ok,"accepted "+str(c))
 return result.state

func reject(s: Dictionary,c: Dictionary,label: String) -> void:
 var snapshot = s.duplicate(true)
 var result = Sim.apply(s,c)
 check(not result.ok and result.state==snapshot and s==snapshot,label)

func reject_bulk(s: Dictionary) -> void:
 for action in ["load_washer","unload","fold"]:
  reject(s,{"action":action},"experienced worker cannot batch-complete "+action+" at "+s.shift.stage)

func prepared_worker() -> Dictionary:
 var s = Sim.initial()
 s.identity.registered = true; s.employment = "laundry"; s.location = "laundry"
 s.jobs.laundry.shifts = 1
 s = act(s,{"action":"begin_shift"})
 for i in range(4):
  s = act(s,{"action":"inspect_uniform","index":i})
  s = act(s,{"action":"inspect_pocket","index":i})
  if s.shift.uniforms[i].found!="": s = act(s,{"action":"found_choice","id":s.shift.uniforms[i].found,"choice":"return"})
  s = act(s,{"action":"sort_uniform","index":i,"bin":s.shift.uniforms[i].type})
 return act(s,{"action":"open_hatch"})

func finish_stage(s: Dictionary) -> Dictionary:
 var stage = s.shift.stage
 if stage=="inspect":
  for i in range(4):
   if not s.shift.uniforms[i].loaded: s = act(s,{"action":"load_garment","index":i})
 elif stage=="prepare":
  while s.shift.doses<2: s = act(s,{"action":"dose"})
  var cycle = "standard"
  for garment in s.shift.uniforms:
   if garment.stain=="blood": cycle = "sanitize"; break
   if garment.stain=="oil": cycle = "hot"
  s = act(s,{"action":"cycle","cycle":cycle})
  s = act(s,{"action":"close_hatch"})
  s = act(s,{"action":"start_wash"})
 elif stage=="washed":
  for i in range(4):
   if not s.shift.uniforms[i].unloaded: s = act(s,{"action":"unload_garment","index":i})
 elif stage=="wet": s = act(s,{"action":"dry"})
 elif stage=="dry":
  for i in range(4):
   for step in range(int(s.shift.uniforms[i].folds)+1,Sim.fold_steps(s.shift.uniforms[i])+1):
    s = act(s,{"action":"fold_garment","index":i,"step":step})
 elif stage=="folded": s = act(s,{"action":"dispatch"})
 elif stage=="receipt": s = act(s,{"action":"settle_shift"})
 return s

func legacy_stages() -> void:
 var s = prepared_worker()
 var start = s.minute-80
 while not s.shift.is_empty():
  var stage = s.shift.stage
  var legacy = s.duplicate(true)
  legacy.schema = 4
  for garment in legacy.shift.uniforms:
   for field in ["loaded","unloaded","folds"]: garment.erase(field)
   garment["future_metadata"] = {"maker":"unclassified"}
  var restored = Sim.migrate(JSON.parse_string(JSON.stringify(legacy)))
  check(not restored.has("error") and restored.shift.stage==stage,"legacy "+stage+" save retains completed stage")
  check(restored.shift.uniforms[0].future_metadata.maker=="unclassified","legacy "+stage+" preserves unknown garment metadata")
  if stage in ["folded","receipt"]:
   check(restored.shift.uniforms.all(func(garment): return int(garment.folds)==Sim.fold_steps(garment)),"legacy completed folds stay completed")
  while not restored.shift.is_empty(): restored = finish_stage(restored)
  check(restored.minute-start==240 and restored.last_receipt.quality==100 and restored.jobs.laundry.shifts==2,"legacy "+stage+" resumes without recharging completed work")
  reject(restored,{"action":"settle_shift"},"legacy "+stage+" wages settle once")
  s = finish_stage(s)

func experienced_shift() -> void:
 var s = prepared_worker()
 var start = s.minute-80
 reject_bulk(s)
 s = act(s,{"action":"load_garment","index":0})
 reject(s,{"action":"load_garment","index":0},"duplicate load does not charge or move garment twice")
 reject_bulk(s)
 check(s.shift.minutes==80,"partial loading charges no extra time")
 s = finish_stage(s)
 check(s.shift.minutes==100,"last individual load charges original twenty minutes once")
 reject_bulk(s)
 s = finish_stage(s)
 reject_bulk(s)
 s = act(s,{"action":"unload_garment","index":0})
 reject(s,{"action":"unload_garment","index":0},"duplicate collection rejects without mutation")
 check(s.shift.minutes==160,"partial collection charges no extra time")
 s = finish_stage(s)
 check(s.shift.minutes==170,"last individual collection charges original ten minutes once")
 s = finish_stage(s)
 reject_bulk(s)
 s = act(s,{"action":"fold_garment","index":0,"step":1})
 reject(s,{"action":"fold_garment","index":0,"step":1},"duplicate folding step rejects without mutation")
 reject(s,{"action":"fold_garment","index":0,"step":3},"folding cannot skip a physical step")
 check(s.shift.minutes==210,"partial folding charges no extra time")
 s = finish_stage(s)
 check(s.shift.minutes==230,"last fold charges original twenty minutes once")
 reject_bulk(s)
 s = finish_stage(s)
 reject_bulk(s)
 s = finish_stage(s)
 check(s.minute-start==240 and s.last_receipt.quality==100 and s.last_receipt.gross==7 and s.credits==11,"experienced manual shift preserves duration, quality and full wages")
 check(s.jobs.laundry.shifts==2,"experienced manual work counts one completed order")
 reject(s,{"action":"settle_shift"},"completed order cannot be farmed through settlement replay")

func _initialize() -> void:
 experienced_shift()
 legacy_stages()
 print("SCHISM manual work: %d checks passed; %d failed."%[passed,failed])
 quit(1 if failed else 0)
