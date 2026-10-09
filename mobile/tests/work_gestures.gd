extends SceneTree
const Work = preload("res://src/work_activity.gd")
var passed = 0
var failed = 0
var commands: Array = []
var ancestor_events: Array = []

func check(ok: bool,label: String) -> void:
 if ok: passed += 1
 else: failed += 1; printerr("FAIL WORK GESTURES: "+label)

func _initialize() -> void:
 _run.call_deferred()

func fixture(kind: String,progress: int=0,crate: Dictionary={},effects: bool=true) -> Dictionary:
 commands.clear(); ancestor_events.clear()
 var scroll = ScrollContainer.new()
 scroll.position = Vector2(20,20); scroll.size = Vector2(420,480)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.scroll_deadzone = 17
 root.add_child(scroll)
 scroll.gui_input.connect(func(event): ancestor_events.append(event))
 var content = VBoxContainer.new(); content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(content)
 var spacer = Control.new(); spacer.custom_minimum_size.y = 40; spacer.mouse_filter = Control.MOUSE_FILTER_PASS
 content.add_child(spacer)
 var work = Work.new(); work.work_kind = kind; work.progress = progress; work.crate = crate.duplicate(true); work.index = 2; work.effects = effects
 work.custom_minimum_size = Vector2(400,284)
 content.add_child(work)
 work.command_requested.connect(func(command): commands.append(command))
 var tail = Control.new(); tail.custom_minimum_size.y = 360; tail.mouse_filter = Control.MOUSE_FILTER_PASS
 content.add_child(tail)
 return {"scroll":scroll,"work":work,"filter":scroll.mouse_filter,"deadzone":scroll.scroll_deadzone,"horizontal_mode":scroll.horizontal_scroll_mode,"vertical_mode":scroll.vertical_scroll_mode}

func settle() -> void:
 await process_frame; await process_frame; await process_frame

func touch(at: Vector2,pressed: bool,canceled: bool=false) -> void:
 var event = InputEventScreenTouch.new()
 event.index = 0; event.pressed = pressed; event.canceled = canceled; event.position = at
 root.push_input(event,true)

func motion(at: Vector2,relative: Vector2) -> void:
 var event = InputEventScreenDrag.new()
 event.index = 0; event.position = at; event.relative = relative
 root.push_input(event,true)

func mouse(at: Vector2,pressed: bool,emulated: bool=true) -> void:
 var event = InputEventMouseButton.new()
 event.position = at; event.pressed = pressed; event.button_index = MOUSE_BUTTON_LEFT
 if emulated: event.device = InputEvent.DEVICE_ID_EMULATION
 root.push_input(event,true)

func mouse_motion(at: Vector2,relative: Vector2,emulated: bool=true) -> void:
 var event = InputEventMouseMotion.new()
 event.position = at; event.relative = relative; event.button_mask = MOUSE_BUTTON_MASK_LEFT
 if emulated: event.device = InputEvent.DEVICE_ID_EMULATION
 root.push_input(event,true)

func global_at(work: Control,local: Vector2) -> Vector2:
 return work.get_global_transform_with_canvas()*local

func restored(f: Dictionary,label: String) -> void:
 check(f.scroll.mouse_filter==f.filter and f.scroll.scroll_deadzone==f.deadzone and f.scroll.horizontal_scroll_mode==f.horizontal_mode and f.scroll.vertical_scroll_mode==f.vertical_mode,label+" restores exact scroll settings")
 check(f.work.mouse_filter==Control.MOUSE_FILTER_PASS and f.work.held==-1 and f.work.scroll_locks.is_empty(),label+" releases work gesture ownership")

func finish_animation(work: Control) -> void:
 work._process(Work.ACTION_SECONDS)

func sequence(kind: String,progress: int,crate: Dictionary,delta: Vector2,expected: Dictionary,mouse_first: bool=false) -> void:
 var f = fixture(kind,progress,crate); await settle()
 var start = global_at(f.work,f.work._region_rect().get_center())
 var target = global_at(f.work,f.work._region_rect().get_center()+delta)
 if mouse_first: mouse(start,true); touch(start,true)
 else: touch(start,true); mouse(start,true)
 check(f.work.held==0 and f.scroll.mouse_filter==Control.MOUSE_FILTER_IGNORE and f.scroll.scroll_deadzone==2147483647,kind+" acquires touch before ancestor scroll"+(" / mouse first" if mouse_first else " / touch first"))
 var original = f.scroll.scroll_vertical
 mouse_motion(target,target-start); motion(target,target-start)
 f.scroll.scroll_vertical = original+50
 await settle()
 check(f.scroll.scroll_vertical==original and ancestor_events.is_empty(),kind+" holds scroll offset during gesture")
 if mouse_first: mouse(target,false); touch(target,false)
 else: touch(target,false); mouse(target,false)
 restored(f,kind+" release")
 check(commands.is_empty() and f.work.animating,kind+" plays action before requesting a transaction")
 finish_animation(f.work)
 check(commands.size()==1 and commands[0]==expected,kind+" emits exactly its next saved action")
 finish_animation(f.work); touch(target,false); mouse(target,false)
 check(commands.size()==1,kind+" ignores duplicate animation and release")
 f.scroll.queue_free(); await settle()

func _run() -> void:
 root.size = Vector2i(480,900)
 await process_frame
 for kind in ["floor","desk","bin"]:
  for progress in range(3):
   var delta = Vector2(68,0) if kind in ["floor","desk"] or (kind=="bin" and progress==0) else Vector2(0,-68 if progress==1 else 68)
   await sequence(kind,progress,{},delta,{"action":"clean_step","object":kind,"step":progress+1},progress%2==0)
 var crate = {"inspected":false,"lifted":false,"stamped":false,"routed":false,"destination":"CLINIC"}
 await sequence("crate",0,crate,Vector2(68,0),{"action":"inspect_crate","index":2},true)
 crate.inspected = true
 await sequence("crate",0,crate,Vector2(0,-68),{"action":"lift_crate","index":2})
 crate.lifted = true
 await sequence("crate",0,crate,Vector2(0,68),{"action":"stamp_crate","index":2},true)
 crate.stamped = true
 var f = fixture("crate",0,crate); await settle()
 var start = global_at(f.work,f.work._region_rect().get_center())
 var lane = global_at(f.work,f.work._lane_rect(1).get_center())
 touch(start,true); mouse(start,true); motion(lane,lane-start); touch(lane,false); mouse(lane,false)
 finish_animation(f.work)
 check(commands.size()==1 and commands[0]=={"action":"route_crate","index":2,"destination":"CLINIC"},"crate drag reaches selected physical lane")
 restored(f,"crate lane")
 f.scroll.queue_free(); await settle()

 for kind in ["floor","desk","bin","crate"]:
  f = fixture(kind,0,crate if kind=="crate" else {},false); await settle()
  var destination = "CLINIC" if kind=="crate" else ""
  f.work.perform_step(destination)
  check(commands.size()==1 and not f.work.animating,kind+" large tap alternative and effects-off commit immediately")
  f.work.perform_step(destination)
  check(commands.size()==1,kind+" effects-off alternative cannot submit twice")
  f.scroll.queue_free(); await settle()

 for interruption in ["cancel","background","window focus","hidden","exit"]:
  f = fixture("floor"); await settle()
  start = global_at(f.work,f.work._region_rect().get_center())
  touch(start,true); mouse(start,true)
  if interruption=="cancel": touch(start,false,true)
  elif interruption=="background": f.work.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
  elif interruption=="window focus": f.work.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
  elif interruption=="hidden": f.work.hide()
  else: f.work.get_parent().remove_child(f.work)
  restored(f,interruption)
  mouse(start,false)
  check(commands.is_empty(),interruption+" discards unfinished work")
  if interruption=="exit": f.work.free()
  f.scroll.queue_free(); await settle()

 f = fixture("desk"); await settle()
 f.work.perform_step()
 check(f.work.animating and commands.is_empty(),"delayed action remains an uncommitted draft")
 f.work.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
 finish_animation(f.work)
 check(commands.is_empty() and not f.work.animating,"pause cancels delayed transaction before emission")
 f.scroll.queue_free(); await settle()

 f = fixture("floor"); await settle()
 start = global_at(f.work,f.work._region_rect().get_center())
 var outside = Vector2(470,800)
 touch(start,true); motion(outside,outside-start); touch(outside,false)
 restored(f,"outside release")
 finish_animation(f.work)
 check(commands.is_empty(),"release outside work area cancels action")
 f.scroll.queue_free(); await settle()

 f = fixture("floor"); await settle()
 start = global_at(f.work,Vector2(5,200))
 mouse(start,true); touch(start,true)
 check(f.work.held==-1 and not ancestor_events.is_empty(),"blank space remains scrollable")
 mouse(start,false); touch(start,false)
 var wheel = InputEventMouseButton.new(); wheel.position = start; wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN; wheel.pressed = true
 root.push_input(wheel,true); await settle()
 check(f.scroll.scroll_vertical>0,"scroll recovers after work gesture")
 f.scroll.queue_free(); await settle()

 print("SCHISM work gestures: %d checks passed; %d failed."%[passed,failed])
 quit(1 if failed else 0)
