extends SceneTree
const Sim = preload("res://src/simulation.gd")
const Store = preload("res://src/save_store.gd")
var passed = 0
var failed = 0

func check(ok: bool, label: String) -> void:
 if ok: passed += 1
 else: failed += 1; printerr("FAIL TACTILE JOBS: "+label)

func act(s: Dictionary, command: Dictionary) -> Dictionary:
 var result = Sim.apply(s,command)
 check(result.ok,"accepted "+str(command)+": "+str(result.get("error","")))
 return result.state

func reject(s: Dictionary, command: Dictionary, label: String) -> void:
 var before = s.duplicate(true)
 var result = Sim.apply(s,command)
 check(not result.ok and result.state==before and s==before,label)

func worker(job: String) -> Dictionary:
 var s = Sim.initial()
 s.identity.registered = true; s.employment = job; s.location = job
 return act(s,{"action":"begin_shift"})

func finish_clean(s: Dictionary) -> Dictionary:
 if not s.shift.supplies: s = act(s,{"action":"clean","object":"supplies"})
 for surface in ["floor","desk","bin"]:
  for step in range(int(s.shift.work_steps[surface])+1,4):
   s = act(s,{"action":"clean_step","object":surface,"step":step})
 return s

func finish_freight(s: Dictionary) -> Dictionary:
 if not s.shift.manifest_read: s = act(s,{"action":"manifest"})
 for i in range(s.shift.crates.size()):
  var box = s.shift.crates[i]
  if not box.inspected: s = act(s,{"action":"inspect_crate","index":i})
  if not box.lifted: s = act(s,{"action":"lift_crate","index":i})
  if not box.stamped: s = act(s,{"action":"stamp_crate","index":i})
  if not box.routed: s = act(s,{"action":"route_crate","index":i,"destination":box.destination})
 return s

func cleaning() -> void:
 var s = worker("cleaning")
 var start = int(s.minute); var initial_revision = int(s.revision)
 reject(s,{"action":"clean_step","object":"floor","step":1},"cleaning requires physical supplies")
 reject(s,{"action":"clean","object":"floor"},"retired surface shortcut cannot complete work")
 s = act(s,{"action":"clean","object":"supplies"})
 reject(s,{"action":"clean_step","object":"floor","step":2},"cleaning cannot skip its first action")
 reject(s,{"action":"clean_step","object":"floor","step":0},"cleaning cannot replay unstarted step")
 reject(s,{"action":"clean_step","object":"floor","step":1.5},"fractional cleaning step rejects")
 reject(s,{"action":"clean_step","object":"unknown","step":1},"unknown surface rejects")
 s = act(s,{"action":"clean_step","object":"floor","step":1,"expected_revision":s.revision})
 check(s.shift.work_steps.floor==1 and s.shift.cleaned.is_empty() and int(s.minute)==start,"first cleaning motion persists without bulk time charge")
 reject(s,{"action":"clean_step","object":"floor","step":2,"expected_revision":initial_revision+1},"stale cleaning activation rejects")
 reject(s,{"action":"clean_step","object":"floor","step":1},"duplicate first cleaning motion rejects")
 s = act(s,{"action":"clean_step","object":"floor","step":2})
 reject(s,{"action":"clean_step","object":"floor","step":2},"duplicate middle cleaning motion rejects")
 check(int(s.minute)==start and int(s.shift.minutes)==0,"partial cleaning keeps original duration")
 s = act(s,{"action":"clean_step","object":"floor","step":3})
 check(s.shift.work_steps.floor==3 and s.shift.cleaned==["floor"] and int(s.minute)==start+80,"third motion charges floor once")
 reject(s,{"action":"clean_step","object":"floor","step":3},"completed surface cannot charge again")
 var found_id = str(s.shift.found)
 for item in s.items:
  if item.id==found_id: item.metadata["future_custody_note"] = {"keep":"original serial"}
 s = act(s,{"action":"clean","object":"inspect_desk"})
 s = act(s,{"action":"found_choice","id":found_id,"choice":"return"})
 var store = Store.new("user://tactile-clean-"+str(Time.get_ticks_usec()))
 check(store.save_state(s),"save a partly cleaned order")
 var restored = store.load_state()
 check(not restored.has("error") and restored.shift.work_steps.floor==3 and restored.shift.work_steps.desk==0 and restored.shift.minutes==80,"reload preserves each cleaning motion and charged duration")
 var found = restored.items.filter(func(item): return item.id==found_id)
 check(found.size()==1 and found[0].owner=="lost_property" and found[0].metadata.future_custody_note.keep=="original serial","reload retains found-property custody and unknown metadata")
 reject(restored,{"action":"clean_step","object":"floor","step":3},"saved completed cleaning action cannot replay")
 var newer = act(restored,{"action":"clean_step","object":"desk","step":1})
 check(store.save_state(newer),"write second verified generation of in-flight work")
 var corrupt = FileAccess.open(store.directory+"/slot1.json",FileAccess.WRITE)
 check(corrupt!=null,"open isolated newer generation for corruption test")
 if corrupt!=null: corrupt.store_string("corrupt generation"); corrupt.close()
 var recovered = store.load_state()
 var retained = recovered.get("items",[]).filter(func(item): return item.id==found_id)
 check(not recovered.has("error") and recovered.revision==restored.revision and recovered.shift.work_steps.desk==0 and retained.size()==1 and retained[0].metadata.future_custody_note.keep=="original serial","corrupt newest generation falls back to intact in-flight work and custody")
 restored = finish_clean(restored)
 check(restored.shift.stage=="receipt" and int(restored.minute)==start+240 and int(restored.shift.minutes)==240,"three surfaces reach receipt in original 240 minutes")
 reject(restored,{"action":"clean_step","object":"desk","step":3},"receipt cannot accept another cleaning motion")
 var before_cash = int(restored.credits); var before_tax = int(restored.taxes.accrued)
 restored = act(restored,{"action":"settle_shift"})
 check(restored.shift.is_empty() and restored.last_receipt.gross==8 and restored.last_receipt.quality==100 and restored.credits==before_cash+8 and restored.taxes.accrued==before_tax and restored.tax_remainder==96,"cleaning receipt preserves quality, gross wages and fractional tax")
 check(restored.jobs.cleaning.shifts==1 and restored.last_receipt.shift_id!="","one cleaning order earns one recorded wage")
 reject(restored,{"action":"settle_shift"},"cleaning wage cannot settle twice")
 check(store.save_state(restored),"save cleaning receipt")
 var receipt = store.load_state()
 check(receipt.shift.is_empty() and receipt.last_receipt.shift_id==restored.last_receipt.shift_id and receipt.credits==restored.credits,"cleaning receipt survives restart")
 reject(receipt,{"action":"settle_shift"},"restarted cleaning receipt cannot settle twice")

func freight() -> void:
 var s = worker("freight")
 var start = int(s.minute); var initial_revision = int(s.revision)
 reject(s,{"action":"lift_crate","index":0},"crate cannot lift before inspection")
 reject(s,{"action":"stamp_crate","index":0},"crate cannot stamp before lifting")
 reject(s,{"action":"route_crate","index":0,"destination":s.shift.crates[0].destination},"crate cannot route before preparation")
 for action in ["inspect_crate","lift_crate","stamp_crate","route_crate"]:
  reject(s,{"action":action,"index":0.5,"destination":"BLOCK C"},action+" rejects fractional crate index")
  reject(s,{"action":action,"index":-1,"destination":"BLOCK C"},action+" rejects negative crate index")
  reject(s,{"action":action,"index":4,"destination":"BLOCK C"},action+" rejects missing crate")
 s = act(s,{"action":"manifest"})
 s = act(s,{"action":"inspect_crate","index":0})
 reject(s,{"action":"inspect_crate","index":0},"duplicate label inspection rejects")
 reject(s,{"action":"stamp_crate","index":0},"stamping cannot skip lift")
 s = act(s,{"action":"lift_crate","index":0})
 reject(s,{"action":"lift_crate","index":0},"duplicate lift rejects")
 reject(s,{"action":"stamp_crate","index":0,"expected_revision":initial_revision+1},"stale crate activation rejects")
 s = act(s,{"action":"stamp_crate","index":0})
 reject(s,{"action":"stamp_crate","index":0},"duplicate stamp rejects")
 check(s.shift.crates[0].lifted and s.shift.crates[0].stamped and int(s.minute)==start,"crate preparation persists without routing time")
 var destination = str(s.shift.crates[0].destination)
 s = act(s,{"action":"route_crate","index":0,"destination":destination})
 check(s.shift.crates[0].routed and s.shift.minutes==60 and int(s.minute)==start+60,"one routed crate charges sixty minutes once")
 reject(s,{"action":"route_crate","index":0,"destination":destination},"routed crate cannot charge twice")
 var found_id = str(s.shift.found)
 for item in s.items:
  if item.id==found_id: item.metadata["future_custody_note"] = {"kitchen":"preserve"}
 var store = Store.new("user://tactile-freight-"+str(Time.get_ticks_usec()))
 check(store.save_state(s),"save partly routed freight order")
 var restored = store.load_state()
 check(not restored.has("error") and restored.shift.crates[0].routed and restored.shift.crates[0].lifted and restored.shift.crates[0].stamped and restored.shift.minutes==60,"restart retains exact crate preparation and routing")
 var found = restored.items.filter(func(item): return item.id==found_id)
 check(found.size()==1 and found[0].owner=="found" and found[0].metadata.future_custody_note.kitchen=="preserve","restart retains unopened parcel custody and metadata")
 reject(restored,{"action":"route_crate","index":0,"destination":destination},"saved route cannot replay")
 reject(restored,{"action":"open_crate","index":3},"damaged parcel cannot open before label inspection")
 reject(restored,{"action":"found_choice","id":found_id,"choice":"return"},"unopened parcel cannot transfer custody")
 restored = act(restored,{"action":"inspect_crate","index":3})
 restored = act(restored,{"action":"open_crate","index":3})
 reject(restored,{"action":"open_crate","index":3},"damaged seal cannot reveal property twice")
 restored = act(restored,{"action":"found_choice","id":found_id,"choice":"return"})
 var returned = restored.items.filter(func(item): return item.id==found_id)
 check(returned.size()==1 and returned[0].owner=="lost_property" and returned[0].metadata.future_custody_note.kitchen=="preserve","opened parcel still supports individual custody choice and metadata")
 restored = finish_freight(restored)
 check(restored.shift.stage=="receipt" and restored.shift.minutes==240 and int(restored.minute)==start+240,"four prepared and routed crates take original 240 minutes")
 var before_cash = int(restored.credits); var before_tax = int(restored.taxes.accrued)
 restored = act(restored,{"action":"settle_shift"})
 check(restored.last_receipt.gross==9 and restored.last_receipt.quality==100 and restored.credits==before_cash+9 and restored.taxes.accrued==before_tax+1 and restored.tax_remainder==8,"freight keeps exact gross, quality and tax assessment")
 check(restored.jobs.freight.shifts==1 and restored.shift.is_empty(),"one freight order earns one recorded wage")
 reject(restored,{"action":"settle_shift"},"freight wage cannot settle twice")
 var wrong = worker("freight")
 wrong = act(wrong,{"action":"manifest"})
 wrong = act(wrong,{"action":"inspect_crate","index":0})
 wrong = act(wrong,{"action":"lift_crate","index":0})
 wrong = act(wrong,{"action":"stamp_crate","index":0})
 wrong = act(wrong,{"action":"route_crate","index":0,"destination":"CLINIC"})
 check(wrong.shift.quality==82 and wrong.shift.minutes==60,"wrong physical lane retains original quality penalty and time")
 wrong = finish_freight(wrong)
 wrong = act(wrong,{"action":"settle_shift"})
 check(wrong.last_receipt.quality==82 and wrong.last_receipt.gross==9 and wrong.jobs.freight.warnings==1,"misroute quality reaches receipt and warning without duplicate wage")

func migrations() -> void:
 var cleaning_old = worker("cleaning")
 cleaning_old.schema = 5; cleaning_old.shift.cleaned = ["floor"]
 cleaning_old.shift.erase("work_steps"); cleaning_old.shift.minutes = 80; cleaning_old.minute += 80
 cleaning_old.shift["future_work_note"] = {"station":"annex"}
 var cleaned = Sim.migrate(JSON.parse_string(JSON.stringify(cleaning_old)))
 check(not cleaned.has("error") and cleaned.shift.work_steps.floor==3 and cleaned.shift.work_steps.desk==0 and cleaned.shift.future_work_note.station=="annex","legacy completed floor derives three actions without losing unknown shift fields")
 reject(cleaned,{"action":"clean_step","object":"floor","step":3},"migrated completed floor cannot charge again")
 cleaned = finish_clean(cleaned)
 check(cleaned.shift.minutes==240,"legacy partly completed cleaning adds only remaining surface time")
 cleaned = act(cleaned,{"action":"settle_shift"})
 check(cleaned.jobs.cleaning.shifts==1 and cleaned.last_receipt.gross==8,"legacy cleaning settles once after remaining actions")

 var freight_old = worker("freight")
 freight_old.schema = 5; freight_old.shift.crates[0].inspected = true; freight_old.shift.crates[0].routed = true
 freight_old.shift.crates[0].erase("lifted"); freight_old.shift.crates[0].erase("stamped")
 freight_old.shift.crates[1].erase("lifted"); freight_old.shift.crates[1].erase("stamped")
 freight_old.shift.minutes = 60; freight_old.minute += 60
 freight_old.shift.crates[0]["future_label"] = "keep"
 var routed = Sim.migrate(JSON.parse_string(JSON.stringify(freight_old)))
 check(not routed.has("error") and routed.shift.crates[0].lifted and routed.shift.crates[0].stamped and not routed.shift.crates[1].lifted and routed.shift.crates[0].future_label=="keep","legacy routing derives prior handling and preserves unknown crate fields")
 reject(routed,{"action":"route_crate","index":0,"destination":routed.shift.crates[0].destination},"migrated routed crate cannot charge again")
 routed = finish_freight(routed)
 check(routed.shift.minutes==240,"legacy partly routed freight adds only remaining crate time")
 routed = act(routed,{"action":"settle_shift"})
 check(routed.jobs.freight.shifts==1 and routed.last_receipt.gross==9,"legacy freight settles once after remaining crates")

 for job in ["cleaning","freight"]:
  var old_receipt = worker(job)
  old_receipt.schema = 5; old_receipt.shift.stage = "receipt"
  old_receipt.shift.minutes = 240; old_receipt.minute += 240
  if job=="cleaning":
   old_receipt.shift.cleaned = ["floor","desk","bin"]
   old_receipt.shift.erase("work_steps")
  else:
   for crate in old_receipt.shift.crates:
    crate.inspected = true; crate.routed = true
    crate.erase("lifted"); crate.erase("stamped")
  var prior_minute = int(old_receipt.minute)
  var recovered_receipt = Sim.migrate(JSON.parse_string(JSON.stringify(old_receipt)))
  check(not recovered_receipt.has("error") and recovered_receipt.shift.stage=="receipt","legacy "+job+" completed work order opens at receipt")
  recovered_receipt = act(recovered_receipt,{"action":"settle_shift"})
  check(recovered_receipt.minute==prior_minute and recovered_receipt.jobs[job].shifts==1 and recovered_receipt.last_receipt.gross==(8 if job=="cleaning" else 9),"legacy "+job+" receipt pays once without adding time")
  reject(recovered_receipt,{"action":"settle_shift"},"legacy "+job+" receipt cannot pay twice")

 var bad_clean = worker("cleaning")
 bad_clean.shift.work_steps.floor = 3
 var bad_clean_before = bad_clean.duplicate(true)
 check(Sim.migrate(bad_clean).has("error") and bad_clean==bad_clean_before,"inconsistent cleaning progress blocks recovery without mutating input")
 var bad_freight = worker("freight")
 bad_freight.shift.crates[0].stamped = true
 var bad_freight_before = bad_freight.duplicate(true)
 check(Sim.migrate(bad_freight).has("error") and bad_freight==bad_freight_before,"impossible freight sequence blocks recovery without mutating input")

func _initialize() -> void:
 cleaning()
 freight()
 migrations()
 print("SCHISM tactile jobs: %d checks passed; %d failed."%[passed,failed])
 quit(1 if failed else 0)
