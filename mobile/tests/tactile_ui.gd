extends SceneTree
const Sim = preload("res://src/simulation.gd")
const Work = preload("res://src/work_activity.gd")
var session
var game
var passed = 0
var failed = 0

func check(ok: bool,label: String) -> void:
 if ok: passed += 1
 else: failed += 1; printerr("FAIL TACTILE UI: "+label)

func _initialize() -> void:
 _run.call_deferred()

func settle() -> void:
 await process_frame; await process_frame; await process_frame

func button(name: String) -> Button:
 return game.find_child(name,true,false) as Button

func activity(kind: String):
 return game.find_child("work_"+kind,true,false)

func setup_job(job: String) -> void:
 game._close_sheet()
 session.state = Sim.initial()
 session.state.identity.registered = true
 session.state.arrival_seen = true
 session.state.location = job
 session.state.employment = job
 check(session.command({"action":"begin_shift"}),"begin isolated "+job+" shift through Session")
 game._render_world()

func resolution(size: Vector2i) -> void:
 root.size = size; game.size = size; game._render_world()
 await settle()

func layout(kind: String,context: String) -> void:
 await settle()
 var bounds = Rect2(Vector2.ZERO,game.size)
 var sheet_panel = game.find_child("sheet_panel",true,false) as Control
 var scroll = game.find_child("sheet_scroll",true,false) as ScrollContainer
 var close = button("close_sheet")
 var work = activity(kind)
 check(sheet_panel!=null and scroll!=null and close!=null and work!=null,"sheet parts exist: "+context)
 if sheet_panel==null or scroll==null or close==null or work==null: return
 check(bounds.encloses(sheet_panel.get_global_rect()) and sheet_panel.get_global_rect().encloses(scroll.get_global_rect()),"work sheet and scroll stay inside viewport: "+context)
 check(bounds.encloses(close.get_global_rect()) and close.size.x>=64 and close.size.y>=64,"close target visible and touch sized: "+context)
 check(work.size.x>=200 and work.size.y>=284 and work.get_global_rect().position.x>=scroll.get_global_rect().position.x-1 and work.get_global_rect().end.x<=scroll.get_global_rect().end.x+1,"retained work surface fits scroll width: "+context)
 check(work.artwork is Texture2D and work.artwork.get_width()>0 and work.artwork.get_height()>0,"painted object raster retained: "+context)
 check(work.material==null and close.material==null and game.modal.material==null,"readable work controls bypass scene shader: "+context)
 if work.next_action()!="":
  var target = work._region_rect()
  check(target.size.x>=64 and target.size.y>=64,"physical action region meets touch size: "+context)
  if work.next_action()=="route_crate":
   for lane in range(3):
    var destination = ["block_c","clinic","textiles"][lane]
    var route = button("route_"+destination)
    check(work._lane_rect(lane).size.x>=64 and work._lane_rect(lane).size.y>=64 and route!=null and route.size.x>=64 and route.size.y>=64,"lane and native alternative meet touch size: "+context+" / "+destination)
    if route!=null: check(route.material==null,"route label bypasses analogue effects: "+context+" / "+destination)
  else:
   var alternative = button("work_step_alternative")
   check(alternative!=null and alternative.size.x>=64 and alternative.size.y>=64,"native action alternative meets touch size: "+context)
   if alternative!=null: check(alternative.material==null,"native action label bypasses analogue effects: "+context)
 for control in game.sheet_body.find_children("*","Label",true,false):
  check(control.material==null,"readable label bypasses scene shader: "+context)

func layout_matrix() -> void:
 for viewport in [Vector2i(360,640),Vector2i(390,844),Vector2i(480,900)]:
  await resolution(viewport)
  setup_job("cleaning")
  session.state.shift.supplies = true
  for kind in ["floor","desk","bin"]:
   for progress in range(4):
    session.state.shift.work_steps[kind] = progress
    if progress==3 and kind not in session.state.shift.cleaned: session.state.shift.cleaned.append(kind)
    if progress<3: session.state.shift.cleaned.erase(kind)
    game._cleaning(kind)
    await layout(kind,"%s / %s %d"%[str(viewport),kind,progress])
  setup_job("freight")
  for phase in range(5):
   var crate = session.state.shift.crates[0]
   crate.inspected = phase>=1; crate.lifted = phase>=2; crate.stamped = phase>=3; crate.routed = phase>=4
   game._crate(0)
   await layout("crate","%s / crate phase %d"%[str(viewport),phase])
  for index in range(3):
   var box = session.state.shift.crates[index]
   box.inspected = true; box.lifted = true; box.stamped = true; box.routed = false
   game._crate(index)
   await layout("crate","%s / route %s"%[str(viewport),box.destination])

func animated_step(kind: String,expected_action: String,expected_progress: int=-1,destination: String="") -> void:
 var prior_revision = int(session.state.revision)
 var work = activity(kind)
 check(work!=null and work.next_action()==expected_action,"next visible action is "+expected_action)
 if work==null: return
 var name = "route_"+destination.to_lower().replace(" ","_") if expected_action=="route_crate" else "work_step_alternative"
 var alternative = button(name)
 check(alternative!=null,"native alternative exists for "+expected_action)
 if alternative==null: return
 alternative.pressed.emit()
 check(work.animating and session.state.revision==prior_revision,"animated "+expected_action+" is an uncommitted visual draft")
 work._process(Work.ACTION_SECONDS)
 await settle()
 check(session.state.revision==prior_revision+1,"animated "+expected_action+" saves one Session command")
 var next_work = activity(kind)
 check(next_work!=null,"successful "+expected_action+" redraws same physical object")
 if next_work!=null and expected_progress>=0: check(next_work.progress==expected_progress,"saved cleaning progress redraws at step "+str(expected_progress))

func cleaning_flow() -> void:
 await resolution(Vector2i(390,844))
 setup_job("cleaning")
 game._cleaning("supplies"); await settle()
 var take = game.sheet_body.find_children("*","Button",true,false).filter(func(b): return b.text.begins_with("Take the workplace supplies"))
 check(take.size()==1,"physical supply bucket offers its action")
 if take.is_empty(): return
 take[0].pressed.emit(); await settle()
 check(session.state.shift.supplies,"supply collection persists through real sheet action")
 var starting_minute = int(session.state.minute)
 for kind in ["floor","desk","bin"]:
  game._cleaning(kind); await settle()
  for step in range(1,4):
   await animated_step(kind,"clean_step",step)
   check(session.state.shift.work_steps[kind]==step,"native alternative saves "+kind+" step "+str(step))
  check(int(session.state.minute)==starting_minute+80*session.state.shift.cleaned.size(),"completed "+kind+" charges original time once")
 check(session.state.shift.stage=="receipt","all three painted surfaces reach sanitation timecard")
 game._cleaning("receipt"); await settle()
 var settle_button = game.sheet_body.find_children("*","Button",true,false).filter(func(b): return b.text.begins_with("Stamp the sanitation timecard"))
 check(settle_button.size()==1,"sanitation receipt is physical timecard")
 if not settle_button.is_empty(): settle_button[0].pressed.emit(); await settle()
 check(session.state.shift.is_empty() and session.state.jobs.cleaning.shifts==1 and session.state.last_receipt.gross==8,"sanitation timecard pays exactly one gross wage")

func freight_flow() -> void:
 setup_job("freight")
 game._freight("manifest"); await settle()
 var mark = game.sheet_body.find_children("*","Button",true,false).filter(func(b): return b.text.begins_with("Compare and mark the manifest"))
 check(mark.size()==1,"painted freight manifest offers marking action")
 if mark.is_empty(): return
 mark[0].pressed.emit(); await settle()
 check(session.state.shift.manifest_read,"manifest mark persists")
 var start = int(session.state.minute)
 for index in range(4):
  game._crate(index); await settle()
  await animated_step("crate","inspect_crate")
  check(session.state.shift.crates[index].inspected,"crate "+str(index)+" inspection saves")
  if index==3:
   var found_id = str(session.state.shift.found)
   var open = game.sheet_body.find_children("*","Button",true,false).filter(func(b): return b.text.begins_with("Lift the damaged lid"))
   check(open.size()==1,"damaged crate exposes separate physical lid action")
   if not open.is_empty(): open[0].pressed.emit(); await settle()
   check(session.state.shift.crates[index].opened,"damaged lid opening saves")
   var returned = game.sheet_body.find_children("*","Button",true,false).filter(func(b): return b.text.begins_with("Place in Lost Property tray"))
   check(returned.size()==1,"found parcel presents custody choice")
   if not returned.is_empty(): returned[0].pressed.emit(); await settle()
   var item = Sim._find(session.state,found_id)
   check(item.owner=="lost_property","freight discovery can be returned without bypassing crate work")
   game._crate(index); await settle()
  await animated_step("crate","lift_crate")
  check(session.state.shift.crates[index].lifted,"crate "+str(index)+" lift saves")
  await animated_step("crate","stamp_crate")
  check(session.state.shift.crates[index].stamped,"crate "+str(index)+" stamp saves")
  await animated_step("crate","route_crate",-1,str(session.state.shift.crates[index].destination))
  check(session.state.shift.crates[index].routed and session.state.shift.minutes==(index+1)*60,"crate "+str(index)+" routes to its named lane once")
 check(int(session.state.minute)==start+240 and session.state.shift.stage=="receipt","four routed parcels preserve original four-hour shift")
 game._freight("receipt"); await settle()
 var stamp = game.sheet_body.find_children("*","Button",true,false).filter(func(b): return b.text.begins_with("Stamp the freight timecard"))
 check(stamp.size()==1,"freight receipt is physical timecard")
 if not stamp.is_empty(): stamp[0].pressed.emit(); await settle()
 check(session.state.shift.is_empty() and session.state.jobs.freight.shifts==1 and session.state.last_receipt.gross==9 and session.state.last_receipt.quality==100,"freight timecard pays one clean wage")

func cancellation() -> void:
 setup_job("cleaning")
 session.state.shift.supplies = true
 game._cleaning("floor"); await settle()
 var before = int(session.state.revision)
 button("work_step_alternative").pressed.emit()
 check(activity("floor").animating,"closing test starts animated draft")
 game._close_sheet()
 await settle()
 check(session.state.revision==before and session.state.shift.work_steps.floor==0,"closing work sheet discards uncommitted animation")
 game._cleaning("floor"); await settle()
 var old = activity("floor")
 before = int(session.state.revision)
 check(session.command({"action":"setting","key":"hints","value":false}),"separate command advances authority revision")
 old.perform_step()
 old._process(Work.ACTION_SECONDS)
 await settle()
 check(session.state.revision==before+1 and session.state.shift.work_steps.floor==0,"stale work control cannot commit after revision changes")
 check(game.sheet_title=="THE OBJECT DOESN'T MOVE","stale action explains rejected object movement")
 session.state.settings.effects = false
 game._cleaning("floor"); await settle()
 old = activity("floor"); before = int(session.state.revision)
 var alt = button("work_step_alternative")
 alt.pressed.emit(); alt.pressed.emit()
 await settle()
 check(session.state.revision==before+1 and session.state.shift.work_steps.floor==1,"effects-off double activation commits exactly one saved step")

func _run() -> void:
 await process_frame
 session = root.get_node("Session")
 session.state = Sim.initial()
 session.state.identity.registered = true
 session.state.arrival_seen = true
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await settle()
 await layout_matrix()
 await cleaning_flow()
 await freight_flow()
 await cancellation()
 game._close_sheet()
 game.queue_free()
 await settle()
 game = null
 session = null
 print("SCHISM tactile UI: %d checks passed; %d failed."%[passed,failed])
 quit(1 if failed else 0)
