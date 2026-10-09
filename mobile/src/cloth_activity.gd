extends Control

# Presentation only: every cloth movement requests a saved authority transition.
signal command_requested(command: Dictionary)
const Visual = preload("res://src/presentation.gd")
const INK = Color("d4d0b7")
const EDGE = Color("777258")
var mode = "load"
var uniforms: Array = []
var selected = 0
var hatch_open = false
var font: Font
var garment_textures: Array[Texture2D] = []
var machine_texture: Texture2D
var folded_texture: Texture2D
var held = -1
var pressed_at = Vector2.ZERO
var pointer = Vector2.ZERO
var dragging = false
var requested = false
var active_touch = -1
var active_mouse = false
var consume_emulated_mouse = false
var gesture_filter = Control.MOUSE_FILTER_PASS
var scroll_locks: Array = []

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_PASS
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 font = load("res://assets/fonts/municipal.ttf")
 var isolation = ShaderMaterial.new(); isolation.shader = load("res://shaders/isolated.gdshader"); material = isolation
 # Retain all rasters beyond _draw(), including atlas resources on Android.
 machine_texture = Visual.washer_texture(hatch_open or mode=="unload",false)
 folded_texture = Visual.object_texture("folded")
 for garment in uniforms:
  garment_textures.append(Visual.object_texture("uniform",garment.stain if mode=="load" else "dirt"))
 resized.connect(queue_redraw)
 visibility_changed.connect(_visibility_changed)

func _visibility_changed() -> void:
 if not is_visible_in_tree(): _cancel_gesture()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_EXIT_TREE]:
  _cancel_gesture()

func _lock_scroll() -> void:
 gesture_filter = mouse_filter
 mouse_filter = Control.MOUSE_FILTER_STOP
 var ancestor = get_parent()
 while ancestor!=null:
  if ancestor is ScrollContainer:
   var scroll: ScrollContainer = ancestor
   # Do not disable scroll modes: that changes the sheet's minimum size.
   # Native ScrollContainer recognizes Android's emulated mouse stream, so
   # ignoring only the duplicate in our GUI handler lets it scroll the sheet.
   var fixed_x: float = scroll.get_h_scroll_bar().value
   var fixed_y: float = scroll.get_v_scroll_bar().value
   var lock = {"scroll":ancestor,"filter":ancestor.mouse_filter,"deadzone":ancestor.scroll_deadzone,
    "x":fixed_x,"y":fixed_y}
   lock.guard_x = func(_value: float):
    if is_instance_valid(scroll): scroll.get_h_scroll_bar().set_value_no_signal(fixed_x)
   lock.guard_y = func(_value: float):
    if is_instance_valid(scroll): scroll.get_v_scroll_bar().set_value_no_signal(fixed_y)
   ancestor.get_h_scroll_bar().value_changed.connect(lock.guard_x)
   ancestor.get_v_scroll_bar().value_changed.connect(lock.guard_y)
   ancestor.mouse_filter = Control.MOUSE_FILTER_IGNORE
   ancestor.scroll_deadzone = 2147483647
   scroll_locks.append(lock)
  ancestor = ancestor.get_parent()

func _unlock_scroll() -> void:
 for lock in scroll_locks:
  var scroll = lock.scroll
  if not is_instance_valid(scroll): continue
  scroll.get_h_scroll_bar().value_changed.disconnect(lock.guard_x)
  scroll.get_v_scroll_bar().value_changed.disconnect(lock.guard_y)
  scroll.mouse_filter = lock.filter
  scroll.scroll_deadzone = lock.deadzone
 scroll_locks.clear()
 mouse_filter = gesture_filter

func _cancel_gesture() -> void:
 held = -1; dragging = false; active_touch = -1; active_mouse = false
 _unlock_scroll()
 if is_inside_tree(): queue_redraw()

func _move(at: Vector2) -> void:
 pointer = at; dragging = dragging or pointer.distance_to(pressed_at)>12
 queue_redraw()

func _input(event: InputEvent) -> void:
 # Once a garment owns the gesture, consume it before GUI dispatch. This
 # also keeps a release outside the cloth/scroll viewport from getting lost.
 if event is InputEventScreenTouch and event.device!=InputEvent.DEVICE_ID_EMULATION:
  if event.pressed and active_touch<0 and not active_mouse:
   consume_emulated_mouse = false
  elif active_touch==event.index:
   # Let releases reach Viewport as well, so it clears its touch/mouse
   # focus bookkeeping. Swallowing them globally leaves a stale GUI grab.
   if event.pressed: get_viewport().set_input_as_handled()
   if event.canceled: _cancel_gesture()
   elif not event.pressed: _release(get_global_transform_with_canvas().affine_inverse()*event.position)
 elif event is InputEventScreenDrag and event.device!=InputEvent.DEVICE_ID_EMULATION and active_touch==event.index:
  get_viewport().set_input_as_handled()
  _move(get_global_transform_with_canvas().affine_inverse()*event.position)
 elif event is InputEventMouseButton:
  if event.device==InputEvent.DEVICE_ID_EMULATION:
   # Godot sends this copy before the real touch. A new down must be hit
   # tested by GUI normally, including blank-space downs after a cloth drag.
   if event.pressed and event.button_index==MOUSE_BUTTON_LEFT and held<0:
    consume_emulated_mouse = false
   elif consume_emulated_mouse and event.pressed:
    get_viewport().set_input_as_handled()
  elif active_mouse and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
   if event.canceled: _cancel_gesture()
   else: _release(get_global_transform_with_canvas().affine_inverse()*event.position)
 elif event is InputEventMouseMotion:
  if event.device==InputEvent.DEVICE_ID_EMULATION and consume_emulated_mouse:
   get_viewport().set_input_as_handled()
  elif active_mouse:
   get_viewport().set_input_as_handled()
   _move(get_global_transform_with_canvas().affine_inverse()*event.position)

func fold_count(index: int) -> int:
 return 2 if uniforms[index].type=="medical" else 3

func next_fold_text() -> String:
 var count = int(uniforms[selected].get("folds",0))
 if uniforms[selected].type=="medical": return ["Bring both sleeves inward","Fold the hem over the body"][mini(count,1)]
 return ["Fold the left sleeve inward","Fold the right sleeve inward","Fold the hem over the body"][mini(count,2)]

func _target_rect() -> Rect2:
 return Rect2(16,size.y-151,size.x-32,135) if mode=="unload" else Rect2(16,12,size.x-32,204)

func _card_rect(index: int) -> Rect2:
 var width = (size.x-50)*.5
 if mode=="unload":
  return Rect2(20+(index%2)*(width+10),28+(index/2)*82,width,76)
 return Rect2(20+(index%2)*(width+10),238+(index/2)*82,width,76)

func _fold_rect() -> Rect2:
 return Rect2(size.x*.15,26,size.x*.7,size.y-68)

func _region_rect() -> Rect2:
 var cloth = _fold_rect()
 var steps = int(uniforms[selected].get("folds",0))
 if uniforms[selected].type=="medical" and steps==0: return Rect2(cloth.position,Vector2(cloth.size.x,maxf(64,cloth.size.y*.6)))
 if uniforms[selected].type=="medical" or steps>=2: return Rect2(cloth.position+Vector2(0,cloth.size.y*.55),Vector2(cloth.size.x, maxf(64,cloth.size.y*.4)))
 return Rect2(cloth.position+Vector2(0 if steps==0 else cloth.size.x*.62,cloth.size.y*.1),Vector2(maxf(64,cloth.size.x*.38),maxf(64,cloth.size.y*.5)))

func _available(index: int) -> bool:
 var garment = uniforms[index]
 return garment.get("sorted",false) and not garment.get("loaded",false) if mode=="load" else not garment.get("unloaded",false)

func _request(index: int) -> void:
 if requested: return
 requested = true
 var command = {"action":"load_garment" if mode=="load" else "unload_garment" if mode=="unload" else "fold_garment","index":index}
 if mode=="fold": command.step = int(uniforms[index].get("folds",0))+1
 command_requested.emit(command)

func _press(at: Vector2) -> void:
 if requested or held>=0: return
 pressed_at = at; pointer = at; dragging = false
 if mode=="fold":
  if _region_rect().has_point(at): held = selected
 else:
  for index in range(uniforms.size()):
   if _available(index) and _card_rect(index).has_point(at): held = index; break
 if held>=0: _lock_scroll()
 queue_redraw()

func _release(at: Vector2) -> void:
 if held<0: return
 var index = held; held = -1
 active_touch = -1; active_mouse = false
 _unlock_scroll()
 if mode=="fold":
  if _region_rect().has_point(at): _request(index)
 elif not dragging or _target_rect().has_point(at):
  _request(index)
 dragging = false; queue_redraw()

func _gui_input(event: InputEvent) -> void:
 # Either Android's mouse copy or its raw touch may arrive first. Acquire
 # once, then raw touch owns movement/release and duplicates are swallowed.
 if event is InputEventScreenTouch:
  if event.index!=0 or event.device==InputEvent.DEVICE_ID_EMULATION: return
  var interacting = held>=0
  if event.canceled: _cancel_gesture()
  elif event.pressed:
   _press(event.position); interacting = held>=0
   if interacting: active_touch = event.index; consume_emulated_mouse = true
  else: _release(event.position)
  if interacting: accept_event()
 elif event is InputEventScreenDrag:
  if event.index!=0 or held<0: return
  _move(event.position); accept_event()
 elif (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION:
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and held<0:
   _press(event.position)
   if held>=0: active_touch = 0; consume_emulated_mouse = true
  if held>=0 or consume_emulated_mouse: accept_event()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=InputEvent.DEVICE_ID_EMULATION:
  var interacting = held>=0
  if event.pressed:
   _press(event.position); interacting = held>=0
   if interacting: active_mouse = true
  elif event.canceled: _cancel_gesture()
  else: _release(event.position)
  if interacting: accept_event()
 elif event is InputEventMouseMotion and held>=0 and event.device!=InputEvent.DEVICE_ID_EMULATION:
  _move(event.position); accept_event()

func _text(at: Vector2,text: String,points: int=18) -> void:
 if font: draw_string(font,at,text,HORIZONTAL_ALIGNMENT_CENTER,size.x-40,points,INK)

func _draw_fit(texture: Texture2D,rect: Rect2,tint: Color=Color.WHITE) -> void:
 if texture==null: return
 var ratio = minf(rect.size.x/texture.get_width(),rect.size.y/texture.get_height())
 var dimensions = texture.get_size()*ratio
 draw_texture_rect(texture,Rect2(rect.position+(rect.size-dimensions)*.5,dimensions),false,tint)

func _draw() -> void:
 draw_style_box(_surface(),Rect2(Vector2.ZERO,size))
 if mode=="fold":
  _draw_fold(); return
 var target = _target_rect()
 draw_rect(target,Color("333b2e")); draw_rect(target,EDGE,false,2)
 if mode=="load" and machine_texture:
  _draw_fit(machine_texture,target.grow(-5))
  if dragging: draw_rect(target,Color(.7,.72,.4,.2)); draw_rect(target,INK,false,3)
  _text(Vector2(20,230),"OPEN DRUM" if hatch_open else "PULL THE HATCH FIRST")
 else:
  if machine_texture: _draw_fit(machine_texture,Rect2(15,5,size.x-30,213))
  _text(Vector2(20,size.y-18),"WET CLOTH / COLLECTION BASKET")
 for index in range(uniforms.size()):
  if not _available(index):
   if mode=="unload" and uniforms[index].get("unloaded",false):
    var collected = Rect2(22+index*(size.x-44)/4,size.y-123,(size.x-48)/4,83)
    if garment_textures[index]: _draw_fit(garment_textures[index],collected,Color(.76,.84,.78))
   continue
  var rect = _card_rect(index)
  if mode=="load": draw_rect(rect,Color("273027")); draw_rect(rect,EDGE,false,1)
  if not (held==index and dragging) and garment_textures[index]:
   _draw_fit(garment_textures[index],Rect2(rect.position+Vector2(5,0),Vector2(rect.size.x-10,rect.size.y-19)),Color.WHITE if mode=="load" else Color(.76,.84,.78))
  if font: draw_string(font,rect.position+Vector2(0,rect.size.y-4),"%02d / %s"%[index+1,str(uniforms[index].type).to_upper()],HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,16,INK)
 if held>=0 and dragging and garment_textures[held]: _draw_fit(garment_textures[held],Rect2(pointer-Vector2(40,48),Vector2(80,96)))

func _draw_fold() -> void:
 var rect = _fold_rect()
 var steps = int(uniforms[selected].get("folds",0))
 var texture = garment_textures[selected]
 if texture:
  if steps>=fold_count(selected): draw_texture_rect(folded_texture,rect,false)
  elif steps==0: draw_texture_rect(texture,rect,false)
  elif steps==1 and fold_count(selected)==3:
   # The sleeve moves across the same painted body, retaining material continuity.
   draw_texture_rect_region(texture,Rect2(rect.position+Vector2(rect.size.x*.15,0),Vector2(rect.size.x*.85,rect.size.y)),Rect2(Vector2(texture.get_width()*.15,0),Vector2(texture.get_width()*.85,texture.get_height())))
   draw_texture_rect_region(texture,Rect2(rect.position+Vector2(rect.size.x*.33,rect.size.y*.15),Vector2(rect.size.x*.23,rect.size.y*.5)),Rect2(Vector2.ZERO,Vector2(texture.get_width()*.3,texture.get_height()*.6)),Color(.83,.86,.76))
  else:
   draw_texture_rect_region(texture,Rect2(rect.position+Vector2(rect.size.x*.22,0),Vector2(rect.size.x*.56,rect.size.y)),Rect2(Vector2(texture.get_width()*.25,0),Vector2(texture.get_width()*.5,texture.get_height())))
 var region = _region_rect()
 draw_rect(region,Color(.7,.68,.4,.12)); draw_rect(region,EDGE,false,2)
 _text(Vector2(20,size.y-14),"FOLD %d / %d"%[steps+1,fold_count(selected)])

func _surface() -> StyleBoxFlat:
 var box = StyleBoxFlat.new(); box.bg_color = Color("1d251d"); box.border_color = EDGE; box.set_border_width_all(1)
 return box
