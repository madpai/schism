extends "res://src/cloth_activity.gd"

# Reuse the garment gesture owner, including Android duplicate-event handling
# and exact ancestor scroll restoration. This control never changes saved state.
var work_kind = "floor"
var progress = 0
var crate: Dictionary = {}
var index = 0
var effects = true
var artwork: Texture2D
var action_clock = 0.0
var animating = false
var emitted = false
var pending_command: Dictionary = {}
var chosen_lane = -1
const LANES = ["BLOCK C","CLINIC","TEXTILES"]
const ACTION_SECONDS = 0.42

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_PASS
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 font = load("res://assets/fonts/municipal.ttf")
 # Keep the original painted crop alive across render frames. Text and targets
 # use ordinary canvas drawing, outside the world's analogue shader.
 artwork = Visual.object_texture("crate" if work_kind=="crate" else "cleaning_"+work_kind)
 resized.connect(queue_redraw)
 visibility_changed.connect(_visibility_changed)
 set_process(false)

func next_action() -> String:
 if work_kind!="crate": return "clean_step" if progress<3 else ""
 if crate.get("routed",false): return ""
 if not crate.get("inspected",false): return "inspect_crate"
 if not crate.get("lifted",false): return "lift_crate"
 if not crate.get("stamped",false): return "stamp_crate"
 return "route_crate"

func step_text() -> String:
 if next_action()=="": return "Work counted / this object is finished"
 if work_kind=="floor": return "Mop muddy band %d of 3"%(progress+1)
 if work_kind=="desk": return "Wipe dirty patch %d of 3"%(progress+1)
 if work_kind=="bin": return ["Tie the bag closed","Lift the heavy bag out","Fit a fresh bag over the rim"][progress]
 return {"inspect_crate":"Turn the crate and read its label","lift_crate":"Lift the crate onto the trolley","stamp_crate":"Press the checked-seal stamp","route_crate":"Slide the crate into an outgoing lane"}[next_action()]

func gesture_text() -> String:
 if next_action()=="": return "All three parts are saved" if work_kind!="crate" else "Parcel sent"
 if next_action()=="route_crate": return "DRAG CRATE TO A LANE BELOW"
 if work_kind in ["floor","desk"] or next_action()=="inspect_crate" or (work_kind=="bin" and progress==0): return "SWIPE ACROSS THE OUTLINED AREA"
 if next_action()=="lift_crate" or (work_kind=="bin" and progress==1): return "PULL UPWARD"
 return "PUSH DOWNWARD"

func _work_rect() -> Rect2:
 return Rect2(16,12,size.x-32,size.y-58-(76 if next_action()=="route_crate" else 0))

func _region_rect() -> Rect2:
 var rect = _work_rect()
 if work_kind=="floor":
  var height = maxf(64,rect.size.y/3)
  return Rect2(rect.position+Vector2(0,progress*(rect.size.y-height)/2),Vector2(rect.size.x,height))
 if work_kind=="desk":
  var width = maxf(64,rect.size.x/3)
  return Rect2(rect.position+Vector2(progress*(rect.size.x-width)/2,0),Vector2(width,rect.size.y))
 return rect.grow(-8)

func _lane_rect(lane: int) -> Rect2:
 var width = (size.x-48)/3
 return Rect2(16+lane*(width+8),size.y-116,width,68)

func _press(at: Vector2) -> void:
 if requested or held>=0 or next_action()=="": return
 if not _region_rect().has_point(at): return
 pressed_at = at; pointer = at; dragging = false; held = 0
 _lock_scroll(); queue_redraw()

func _release(at: Vector2) -> void:
 if held<0: return
 var displacement = at-pressed_at
 held = -1; active_touch = -1; active_mouse = false
 _unlock_scroll()
 var accepted = false
 var destination = ""
 var action = next_action()
 if action=="route_crate":
  for lane in range(3):
   if _lane_rect(lane).has_point(at): destination = LANES[lane]; accepted = true; break
 elif work_kind in ["floor","desk"] or action=="inspect_crate" or (work_kind=="bin" and progress==0):
  accepted = absf(displacement.x)>=48 and absf(displacement.x)>absf(displacement.y)*.65
 elif action=="lift_crate" or (work_kind=="bin" and progress==1): accepted = displacement.y<=-48
 else: accepted = displacement.y>=48
 if action!="route_crate" and not _work_rect().grow(12).has_point(at): accepted = false
 dragging = false
 if accepted: perform_step(destination)
 queue_redraw()

func perform_step(destination: String="") -> void:
 # The 64-unit native buttons call this same path as a successful gesture.
 # A step can only emit once; reopening derives the next step from the save.
 if requested or next_action()=="" or not is_visible_in_tree(): return
 var action = next_action()
 if action=="route_crate" and destination not in LANES: return
 requested = true; animating = true; action_clock = 0.0
 pending_command = {"action":action}
 if work_kind=="crate": pending_command.index = index
 else: pending_command.object = work_kind; pending_command.step = progress+1
 if action=="route_crate": pending_command.destination = destination; chosen_lane = LANES.find(destination)
 set_process(true); queue_redraw()
 if not effects: _finish_action()

func _process(delta: float) -> void:
 if not animating: return
 action_clock = minf(ACTION_SECONDS,action_clock+delta)
 queue_redraw()
 if action_clock>=ACTION_SECONDS: _finish_action()

func _finish_action() -> void:
 if not animating or emitted or not is_visible_in_tree(): return
 animating = false; emitted = true; set_process(false)
 command_requested.emit(pending_command.duplicate(true))

func _cancel_gesture() -> void:
 super._cancel_gesture()
 # Closing/backgrounding before the short movement ends discards the draft.
 # There is no timer, delayed callback or replayed resource transaction.
 animating = false; pending_command.clear(); set_process(false)
 if not emitted: requested = false
 action_clock = 0.0; chosen_lane = -1

func _draw() -> void:
 draw_style_box(_surface(),Rect2(Vector2.ZERO,size))
 var rect = _work_rect()
 draw_rect(rect,Color("31372b"))
 var fraction = action_clock/ACTION_SECONDS if animating else 0.0
 if work_kind=="crate": _draw_crate(rect,fraction)
 else: _draw_cleaning(rect,fraction)
 if next_action()!="" and not animating:
  draw_rect(_region_rect(),Color(.76,.72,.43,.08))
  draw_rect(_region_rect(),EDGE,false,2)
 if next_action()=="route_crate":
  for lane in range(3):
   var target = _lane_rect(lane)
   draw_rect(target,Color("414732")); draw_rect(target,INK if chosen_lane==lane else EDGE,false,2)
   if font: draw_string(font,target.position+Vector2(0,40),LANES[lane],HORIZONTAL_ALIGNMENT_CENTER,target.size.x,17,INK)
 _text(Vector2(20,size.y-18),gesture_text(),17)

func _draw_cleaning(rect: Rect2,fraction: float) -> void:
 if work_kind in ["floor","desk"] and artwork!=null:
  # Fill the close-up without distorting the painted surface. Grime and
  # gesture bands remain over the painting instead of empty sidebars.
  var ratio = maxf(rect.size.x/artwork.get_width(),rect.size.y/artwork.get_height())
  var source_size = rect.size/ratio
  draw_texture_rect_region(artwork,rect,Rect2((artwork.get_size()-source_size)*.5,source_size))
 else: _draw_fit(artwork,rect)
 if work_kind in ["floor","desk"]:
  for part in range(3):
   var patch = Rect2(rect.position+Vector2(0,part*rect.size.y/3),Vector2(rect.size.x,rect.size.y/3)) if work_kind=="floor" else Rect2(rect.position+Vector2(part*rect.size.x/3,0),Vector2(rect.size.x/3,rect.size.y))
   var cleaned = part<progress
   var fade = fraction if part==progress else 0.0
   if cleaned or fade>0:
    draw_rect(patch,Color(.55,.57,.43,.27*(1.0 if cleaned else fade)))
    draw_line(patch.position+Vector2(9,patch.size.y-8),patch.end-Vector2(9,8),Color(.77,.78,.62,.6*(1.0 if cleaned else fade)),2)
   if not cleaned:
    for mark in range(3):
     var at = patch.position+Vector2(patch.size.x*(.22+.23*mark),patch.size.y*.48)
     draw_circle(at,8,Color(.12,.14,.10,.52*(1.0-fade)))
  if held>=0 or animating:
   var zone = _region_rect()
   var point = pointer if held>=0 else zone.position+Vector2(zone.size.x*fraction,zone.size.y*.5)
   if work_kind=="floor":
    draw_line(point+Vector2(28,-68),point,Color("a19a73"),6)
    draw_line(point-Vector2(23,0),point+Vector2(23,0),Color("b7b79b"),15)
    draw_line(point-Vector2(22,-8),point+Vector2(22,8),Color("767e68"),3)
   else:
    draw_rect(Rect2(point-Vector2(23,15),Vector2(46,30)),Color("adb2a0"))
    draw_line(point-Vector2(16,0),point+Vector2(17,0),Color("76856f"),3)
 elif work_kind=="bin":
  var center = rect.get_center()
  var bag_y = center.y-55*(fraction if progress==1 else 0.0)
  if progress<2:
   var points = PackedVector2Array([Vector2(center.x-38,bag_y+62),Vector2(center.x-44,bag_y-8),Vector2(center.x-17,bag_y-39),Vector2(center.x+15,bag_y-39),Vector2(center.x+43,bag_y-8),Vector2(center.x+37,bag_y+62)])
   draw_colored_polygon(points,Color("252b25"))
   if progress>=1 or animating:
    var tie_width = 18.0 if progress>=1 else 38.0-20.0*fraction
    draw_line(Vector2(center.x-tie_width,bag_y-35),Vector2(center.x+tie_width,bag_y-35),INK,5)
  else:
   var top = rect.position.y+20+(1.0 if progress>=3 else fraction)*32
   draw_rect(Rect2(center.x-48,top,96,85),Color(.63,.66,.52,.7))
   draw_line(Vector2(center.x-52,top),Vector2(center.x+52,top),INK,6)
  if progress>=3: _text(Vector2(20,rect.end.y-8),"FRESH LINER FITTED",18)

func _draw_crate(rect: Rect2,fraction: float) -> void:
 var action = next_action()
 var target = rect.grow(-18)
 var center = target.get_center()
 var offset = Vector2.ZERO
 if crate.get("lifted",false): offset.y = -12
 if animating:
  if action=="lift_crate": offset.y = -35*sin(fraction*PI*.5)
  if action=="route_crate" and chosen_lane>=0: offset = (_lane_rect(chosen_lane).get_center()-center)*fraction
 if held>=0 and dragging: offset = pointer-pressed_at
 var turn = sin(fraction*PI)*.14 if animating and action=="inspect_crate" else 0.0
 draw_set_transform(center+offset,turn,Vector2(1.0,1.0))
 _draw_fit(artwork,Rect2(-target.size*.5,target.size))
 if crate.get("inspected",false):
  var label_rect = Rect2(-58,-10,116,34)
  draw_rect(label_rect,Color("c4c0a0"))
  if font: draw_string(font,Vector2(-56,13),str(crate.get("destination","")),HORIZONTAL_ALIGNMENT_CENTER,112,16,Color("252c22"))
 if crate.get("stamped",false) or (animating and action=="stamp_crate" and fraction>.5):
  draw_rect(Rect2(-31,30,62,25),Color("a89468"),false,3)
  if font: draw_string(font,Vector2(-29,49),"IX / OK",HORIZONTAL_ALIGNMENT_CENTER,58,15,INK)
 if animating and action=="stamp_crate":
  var stamp_y = -80+105*sin(fraction*PI*.5)
  draw_rect(Rect2(-13,stamp_y,26,30),Color("7c7458"))
  draw_rect(Rect2(-34,stamp_y+25,68,14),Color("b1a779"))
 draw_set_transform(Vector2.ZERO)
 if crate.get("lifted",false):
  draw_line(Vector2(rect.position.x+25,rect.end.y-12),Vector2(rect.end.x-25,rect.end.y-12),EDGE,5)
  draw_circle(Vector2(rect.position.x+42,rect.end.y-7),6,INK)
  draw_circle(Vector2(rect.end.x-42,rect.end.y-7),6,INK)
