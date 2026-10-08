class_name SchismEnvironment
extends Control
var location = "room"
var state: Dictionary
var clock = 0.0
var enabled = true
var propaganda: Label
var propaganda_frame = -1
const SLOGANS = ["YOUR SHIFT COUNTS", "REPORT. REPAIR. RETURN.", "EVERY RESIDENT ACCOUNTED FOR"]
const SERVICE_SLOGANS = ["YOUR SHIFT\nCOUNTS", "REPORT\nREPAIR\nRETURN", "ALL RESIDENTS\nACCOUNTED FOR"]

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(_update_propaganda)
 if location in ["street","bureau","service"]:
  # This physical display is a separate Control: readable type bypasses analogue effects.
  propaganda = Label.new(); propaganda.name = "propaganda_line"
  propaganda.mouse_filter = Control.MOUSE_FILTER_IGNORE
  propaganda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  propaganda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  propaganda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  propaganda.clip_text = true
  propaganda.clip_contents = true
  propaganda.add_theme_font_override("font",preload("res://assets/fonts/municipal.ttf"))
  propaganda.add_theme_font_size_override("font_size",14)
  propaganda.add_theme_color_override("font_color",Color("a9af82"))
  propaganda.add_theme_color_override("font_shadow_color",Color("111a13"))
  propaganda.add_theme_constant_override("shadow_offset_x",1)
  propaganda.add_theme_constant_override("shadow_offset_y",1)
  add_child(propaganda)
  _update_propaganda()

func _process(delta: float) -> void:
 if not enabled: return
 clock += delta
 if int(clock*20)!=int((clock-delta)*20):
  _update_propaganda()
  queue_redraw()

func _display_rect() -> Rect2:
 var rect = Rect2(.34,.34,.29,.044)
 if location=="bureau": rect = Rect2(.035,.405,.235,.046)
 elif location=="service": rect = Rect2(.173,.145,.158,.09)
 return Rect2(rect.position*size,rect.size*size)

func _update_propaganda() -> void:
 if propaganda==null: return
 var rect = _display_rect()
 propaganda.position = rect.position; propaganda.size = rect.size
 if location=="service": propaganda.add_theme_font_size_override("font_size",clampi(int(size.x*.021),9,16))
 var frame = (int(state.get("minute",360)/1440)+int(clock/12.0))%SLOGANS.size()
 if frame!=propaganda_frame:
  propaganda_frame = frame; propaganda.text = (SERVICE_SLOGANS[frame] if state.get("city",{}).get("flags",{}).get("service_repaired",false) else "AUX POWER\nFAULT") if location=="service" else SLOGANS[frame]

func _surveillance() -> void:
 var w = size.x; var h = size.y
 # Small wall-mounted housings and their dim inspection sweep share the scene palette.
 var anchor = Vector2(.31,.4)
 if location=="bureau": anchor = Vector2(.64,.255)
 elif location=="service": anchor = Vector2(.79,.10)
 var mount = anchor*size
 var sweep = sin(clock*.23)*.055 if enabled else 0.0
 var lens = mount+Vector2(w*(.032+sweep*.1),h*.016)
 if location=="service":
  # The corridor already contains its camera and screen. Illuminate their painted surfaces.
  lens = mount
  draw_circle(lens,maxf(1,w*.002),Color(.66,.42,.19,.35))
 else:
  draw_line(mount-Vector2(w*.012,h*.023),mount,Color("454c3d"),maxf(2,w*.006))
  draw_line(mount,lens,Color("68705a"),maxf(3,w*.009))
  var body = PackedVector2Array([lens+Vector2(-w*.026,-h*.009),lens+Vector2(w*.019,-h*.006),lens+Vector2(w*.017,h*.009),lens+Vector2(-w*.022,h*.007)])
  draw_colored_polygon(body,Color("68705a"))
  draw_line(lens+Vector2(w*.017,-h*.005),lens+Vector2(w*.016,h*.007),Color("17231a"),maxf(2,w*.006))
  draw_circle(lens+Vector2(w*.008,h*.005),maxf(1,w*.002),Color("9d6446"))
 var floor_y = .79 if location=="street" else .71
 var center_x = clampf(anchor.x+.1+sweep,.15,.88)
 if location=="service": center_x = .5+sweep
 draw_colored_polygon(PackedVector2Array([lens,Vector2(w*(center_x-.055),h*floor_y),Vector2(w*(center_x+.055),h*floor_y)]),Color(.63,.7,.48,.018))
 # A passing guard is suggested by a long floor shadow, never a geometric foreground figure.
 var pass_phase = fmod(clock,26.0)/26.0 if enabled else .46
 var shadow_x = w*(.23+pass_phase*.48)
 var shadow_y = h*(.69 if location=="bureau" else .76)
 var opacity = sin(pass_phase*PI)*.13
 var step = sin(clock*2.3)*w*.006 if enabled else 0.0
 draw_colored_polygon(PackedVector2Array([Vector2(shadow_x-w*.014,shadow_y),Vector2(shadow_x+w*.013,shadow_y),Vector2(shadow_x+w*.085+step,shadow_y+h*.105),Vector2(shadow_x+w*.06-step,shadow_y+h*.12)]),Color(.025,.04,.025,opacity))
 draw_circle(Vector2(shadow_x+w*.078,shadow_y+h*.108),w*.017,Color(.025,.04,.025,opacity))
 if location!="service":
  var display = _display_rect()
  draw_rect(display.grow(2),Color("394330"))
  draw_rect(display,Color("17231a"))

func _draw() -> void:
 var w = size.x; var h = size.y
 if location=="service" and not state.get("city",{}).get("flags",{}).get("service_repaired",false):
  draw_rect(Rect2(Vector2.ZERO,size),Color(.015,.025,.02,.28))
 if location in ["street","bureau","service"]: _surveillance()
 if location in ["street","room","hall"]:
  for n in range(24):
   var x = fmod(float(n)*47.7,w)
   var y = fmod(float(n)*103.0+clock*210,h)
   if location=="street" or (location=="room" and x>w*.66 and y<h*.31):
    draw_line(Vector2(x,y),Vector2(x-2,y+12),Color(.66,.76,.7,.14),1)
 if enabled and location not in ["street","shop"]:
  draw_rect(Rect2(Vector2.ZERO,size),Color(.72,.8,.6,0.018+sin(clock*1.7)*.009))
 if location=="street":
  var tap = Vector2(w*.15,h*.83)
  draw_line(tap+Vector2(0,h*.055),tap+Vector2(0,-h*.025),Color("707d6b"),7)
  draw_line(tap+Vector2(0,-h*.025),tap+Vector2(w*.035,-h*.025),Color("889082"),7)
  draw_line(tap+Vector2(-w*.018,-h*.04),tap+Vector2(w*.018,-h*.04),Color("adab86"),4)
 if location=="cleaning":
  if state.get("shift",{}).is_empty() or "floor" not in state.shift.get("cleaned",[]):
   for n in range(5):
    var mark = Vector2(w*(.34+n*.065),h*(.74+float(n%2)*.04))
    draw_circle(mark,w*.016,Color(.25,.2,.14,.6))
 if location=="laundry" and not state.get("shift",{}).is_empty():
  if state.shift.stage in ["folded","receipt"]:
   var cloth = preload("res://src/presentation.gd").object_texture("folded")
   if cloth: draw_texture_rect(cloth,Rect2(w*.82,h*.49,w*.17,h*.13),false)
 if location=="cleaning" and not state.get("shift",{}).is_empty():
  for area in state.shift.get("cleaned",[]):
   if area=="floor": draw_colored_polygon(PackedVector2Array([Vector2(w*.25,h*.8),Vector2(w*.7,h*.74),Vector2(w*.85,h*.86),Vector2(w*.37,h*.92)]),Color(.46,.54,.44,.18))
   if area=="bin": draw_rect(Rect2(w*.78,h*.72,w*.13,h*.17),Color(.1,.15,.12,.35))
 if location=="room":
  if "blanket" in state.get("room_upgrades",[]): draw_colored_polygon(PackedVector2Array([Vector2(w*.02,h*.61),Vector2(w*.27,h*.56),Vector2(w*.48,h*.76),Vector2(w*.1,h*.93)]),Color(.46,.34,.25,.8))
  if "shelf" in state.get("room_upgrades",[]): draw_rect(Rect2(w*.53,h*.36,w*.18,h*.015),Color("91826c"))
