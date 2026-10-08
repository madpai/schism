class_name SchismEnvironment
extends Control
var location = "room"
var state: Dictionary
var clock = 0.0
var enabled = true

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
 clock += delta
 if int(clock*20)!=int((clock-delta)*20): queue_redraw()

func _draw() -> void:
 var w = size.x; var h = size.y
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
  var shift = state.shift
  if shift.get("hatch_open",false):
   var center = Vector2(w*.49,h*.475)
   draw_circle(center,minf(w*.085,h*.06),Color("0b1510"))
   draw_arc(center+Vector2(-w*.12,0),w*.085,0,TAU,8,Color("969782"),7)
  if shift.stage=="washed":
   for i in range(6):
    var angle = clock*2+float(i)*TAU/6
    draw_circle(Vector2(w*.59,h*.475)+Vector2(cos(angle)*w*.04,sin(angle)*h*.03),w*.013,Color(.53,.62,.52,.6))
  if shift.stage in ["wet","dry","folded","receipt"]:
   draw_rect(Rect2(w*.78,h*.53,w*.17,h*.09),Color("78816b"))
 if location=="cleaning" and not state.get("shift",{}).is_empty():
  for area in state.shift.get("cleaned",[]):
   if area=="floor": draw_colored_polygon(PackedVector2Array([Vector2(w*.25,h*.8),Vector2(w*.7,h*.74),Vector2(w*.85,h*.86),Vector2(w*.37,h*.92)]),Color(.46,.54,.44,.18))
   if area=="bin": draw_rect(Rect2(w*.78,h*.72,w*.13,h*.17),Color(.1,.15,.12,.35))
 if location=="room":
  if "blanket" in state.get("room_upgrades",[]): draw_colored_polygon(PackedVector2Array([Vector2(w*.02,h*.61),Vector2(w*.27,h*.56),Vector2(w*.48,h*.76),Vector2(w*.1,h*.93)]),Color(.46,.34,.25,.8))
  if "shelf" in state.get("room_upgrades",[]): draw_rect(Rect2(w*.53,h*.36,w*.18,h*.015),Color("91826c"))
