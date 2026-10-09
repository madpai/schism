extends SceneTree

const Cloth = preload("res://src/cloth_activity.gd")
var passed = 0
var failed = 0
var commands: Array = []
var ancestor_events: Array = []

func check(ok: bool,label: String) -> void:
 if ok: passed += 1
 else: failed += 1; printerr("FAIL CLOTH: "+label)

func _initialize() -> void:
 _run.call_deferred()

func fixture(mode: String="load") -> Dictionary:
 commands.clear(); ancestor_events.clear()
 var scroll = ScrollContainer.new()
 scroll.position = Vector2(20,20); scroll.size = Vector2(420,480)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.scroll_deadzone = 17
 root.add_child(scroll)
 scroll.gui_input.connect(func(event): ancestor_events.append(event))
 var content = VBoxContainer.new(); content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(content)
 var spacer = Control.new(); spacer.custom_minimum_size.y = 40
 spacer.mouse_filter = Control.MOUSE_FILTER_PASS; content.add_child(spacer)
 var cloth = Cloth.new(); cloth.mode = mode; cloth.hatch_open = true
 cloth.custom_minimum_size = Vector2(400,420)
 for i in range(4): cloth.uniforms.append({"type":"worker","stain":"dirt","sorted":true,"loaded":false,"unloaded":false,"folds":0})
 content.add_child(cloth)
 cloth.command_requested.connect(func(command): commands.append(command))
 var tail = Control.new(); tail.custom_minimum_size.y = 360
 tail.mouse_filter = Control.MOUSE_FILTER_PASS; content.add_child(tail)
 return {"scroll":scroll,"cloth":cloth,"original_filter":scroll.mouse_filter,"original_deadzone":scroll.scroll_deadzone,
  "horizontal_mode":scroll.horizontal_scroll_mode,"vertical_mode":scroll.vertical_scroll_mode}

func settle() -> void:
 await process_frame; await process_frame; await process_frame

func touch(at: Vector2,pressed: bool,canceled: bool=false,index: int=0) -> void:
 var event = InputEventScreenTouch.new()
 event.index = index; event.pressed = pressed; event.canceled = canceled; event.position = at
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

func global_at(cloth: Control,local: Vector2) -> Vector2:
 return cloth.get_global_transform_with_canvas()*local

func restored(f: Dictionary,label: String) -> void:
 check(f.scroll.mouse_filter==f.original_filter and f.scroll.scroll_deadzone==f.original_deadzone and f.scroll.horizontal_scroll_mode==f.horizontal_mode and f.scroll.vertical_scroll_mode==f.vertical_mode,label+" restores ancestor settings")
 check(f.cloth.mouse_filter==Control.MOUSE_FILTER_PASS and f.cloth.held==-1 and f.cloth.scroll_locks.is_empty(),label+" releases garment ownership")

func _run() -> void:
 root.size = Vector2i(480,900)
 await process_frame
 var f = fixture(); await settle()
 var start = global_at(f.cloth,f.cloth._card_rect(0).get_center())
 var target = global_at(f.cloth,f.cloth._target_rect().get_center())
 var before = f.scroll.scroll_vertical
 mouse(start,true); touch(start,true)
 check(f.cloth.held==0 and f.cloth.active_touch==0,"viewport touch acquires actual garment")
 check(f.scroll.mouse_filter==Control.MOUSE_FILTER_IGNORE and f.scroll.scroll_deadzone==2147483647,"gesture locks ancestor without changing layout modes")
 var layout_size = f.scroll.size
 mouse_motion(target,target-start); motion(target,target-start)
 check(f.cloth.dragging and f.cloth.pointer.distance_to(f.cloth._target_rect().get_center())<1,"raw touch moves garment in local coordinates")
 check(ancestor_events.is_empty(),"touch and emulated mouse never reach ScrollContainer during garment drag")
 # Headless DisplayServer does not claim touchscreen support, so native
 # mouse-based touch inertia cannot be exercised here. Simulate its range
 # update explicitly and verify the same offset guard used on Android.
 f.scroll.scroll_vertical = before+90
 await settle()
 check(f.scroll.scroll_vertical==before and f.scroll.size==layout_size,"inertia cannot move sheet or resize its bounded viewport")
 mouse(target,false); touch(target,false)
 check(commands.size()==1 and commands[0]=={"action":"load_garment","index":0},"release requests exactly one individual garment")
 restored(f,"release")
 touch(target,false); mouse(target,false)
 check(commands.size()==1,"duplicate release and emulation cannot request twice")
 var other = Button.new(); other.position = Vector2(20,550); other.size = Vector2(400,64)
 var clicked: Array = []
 other.pressed.connect(func(): clicked.append(true)); root.add_child(other)
 var other_at = other.get_global_rect().get_center()
 mouse(other_at,true); mouse(other_at,false)
 check(clicked.size()==1,"release clears Viewport mouse grab so unrelated controls still work")
 other.queue_free(); await settle()
 var blank = global_at(f.cloth,Vector2(5,225))
 ancestor_events.clear(); mouse(blank,true); touch(blank,true)
 check(f.cloth.held==-1 and not ancestor_events.is_empty(),"blank touch returns to ordinary parent scrolling")
 mouse(blank,false); touch(blank,false)
 var wheel = InputEventMouseButton.new(); wheel.position = blank
 wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN; wheel.pressed = true
 root.push_input(wheel,true); await settle()
 check(f.scroll.scroll_vertical>before,"real GUI wheel scroll works after release")
 f.scroll.queue_free(); await settle()

 for interruption in ["cancel","background","window focus","hidden","exit"]:
  f = fixture(); await settle()
  start = global_at(f.cloth,f.cloth._card_rect(0).get_center())
  touch(start,true); mouse(start,true)
  motion(start+Vector2(0,-40),Vector2(0,-40))
  if interruption=="cancel": touch(start,false,true)
  elif interruption=="background": f.cloth.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
  elif interruption=="window focus": f.cloth.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
  elif interruption=="hidden": f.cloth.hide()
  else: f.cloth.get_parent().remove_child(f.cloth)
  restored(f,interruption)
  mouse(start,false)
  check(commands.is_empty(),interruption+" does not perform abandoned work")
  if interruption=="exit": f.cloth.free()
  f.scroll.queue_free(); await settle()

 f = fixture(); await settle()
 start = global_at(f.cloth,f.cloth._card_rect(0).get_center())
 touch(start,true)
 var outside = Vector2(470,800)
 motion(outside,outside-start); touch(outside,false)
 restored(f,"outside release")
 check(commands.is_empty(),"drop outside washer cancels rather than loading")
 f.scroll.queue_free(); await settle()

 for mode in ["unload","fold"]:
  f = fixture(mode); await settle()
  start = global_at(f.cloth,f.cloth._region_rect().get_center() if mode=="fold" else f.cloth._card_rect(0).get_center())
  touch(start,true); mouse(start,true); touch(start,false); mouse(start,false)
  check(commands.size()==1 and commands[0].action==("fold_garment" if mode=="fold" else "unload_garment"),mode+" retains a forgiving direct tap")
  if mode=="fold": check(commands[0].step==1,"fold requests only its next saved step")
  restored(f,mode+" tap")
  f.scroll.queue_free(); await settle()

 f = fixture(); await settle()
 start = global_at(f.cloth,f.cloth._card_rect(0).get_center())
 target = global_at(f.cloth,f.cloth._target_rect().get_center())
 mouse(start,true,false); mouse_motion(target,target-start,false); mouse(target,false,false)
 check(commands.size()==1,"desktop mouse retains individual drag without touch copies")
 restored(f,"mouse release")
 other = Button.new(); other.position = Vector2(20,550); other.size = Vector2(400,64)
 clicked.clear(); other.pressed.connect(func(): clicked.append(true)); root.add_child(other)
 other_at = other.get_global_rect().get_center()
 mouse(other_at,true,false); mouse(other_at,false,false)
 check(clicked.size()==1,"desktop release clears Viewport mouse grab")
 other.queue_free()
 f.scroll.queue_free(); await settle()
 print("SCHISM cloth gestures: %d checks passed; %d failed."%[passed,failed])
 quit(1 if failed else 0)
