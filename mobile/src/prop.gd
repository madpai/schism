class_name SchismProp
extends Control

var kind = "uniform"
var caption = ""
var detail = ""
var condition = "dirt"
var progress = 0.0
var hatch_open = false
var active = false
var font: Font
var clock = 0.0

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 font = load("res://assets/fonts/municipal.ttf")

func _process(delta: float) -> void:
 if active:
  clock += delta; queue_redraw()

func _draw() -> void:
 var w = size.x; var h = size.y
 var gray = Color("777f78"); var dark = Color("252e29"); var paper = Color("c6c3a5")
 if kind=="uniform":
  var pts = PackedVector2Array([Vector2(.26*w,.12*h),Vector2(.39*w,.06*h),Vector2(.5*w,.14*h),Vector2(.61*w,.06*h),Vector2(.75*w,.12*h),Vector2(.95*w,.4*h),Vector2(.79*w,.52*h),Vector2(.68*w,.37*h),Vector2(.72*w,.91*h),Vector2(.27*w,.91*h),Vector2(.31*w,.37*h),Vector2(.18*w,.52*h),Vector2(.05*w,.4*h)])
  draw_colored_polygon(pts,gray); draw_polyline(pts,dark,3)
  draw_line(Vector2(.5*w,.18*h),Vector2(.5*w,.9*h),dark,3)
  draw_rect(Rect2(w*.55,h*.28,w*.11,h*.18),dark,false,3)
  if condition!="clean":
   var stain = Color("594036") if condition=="blood" else Color("343c30") if condition=="oil" else Color("64604b")
   draw_colored_polygon(PackedVector2Array([Vector2(.3*w,.65*h),Vector2(.41*w,.58*h),Vector2(.47*w,.77*h),Vector2(.32*w,.83*h)]),stain)
 elif kind=="washer":
  draw_rect(Rect2(w*.04,h*.03,w*.92,h*.94),Color("626b5b"))
  draw_rect(Rect2(w*.1,h*.08,w*.8,h*.15),dark)
  for i in range(3):
   var p = Vector2(w*(.23+i*.27),h*.15)
   draw_circle(p,h*.047,Color("8b8f78")); draw_line(p,p+Vector2(0,-h*.035),paper,3)
  var center = Vector2(w*.5,h*.59); var radius = minf(w*.35,h*.3)
  draw_circle(center,radius,Color("9b967c")); draw_circle(center,radius*.87,dark)
  if hatch_open:
   draw_circle(center+Vector2(-radius*.78,0),radius*.8,Color("5b675e")); draw_circle(center+Vector2(-radius*.78,0),radius*.64,Color("18251f"))
  else:
   draw_circle(center,radius*.76,Color("12251f"))
   for i in range(5):
    var angle = float(i)*TAU/5+clock*2
    draw_circle(center+Vector2(cos(angle),sin(angle))*radius*.45,radius*.18,gray)
 elif kind in ["credits","coin"]:
  for i in range(3):
   var p = Vector2(w*(.28+i*.2),h*(.5+(.08 if i%2 else 0)))
   draw_circle(p,minf(w*.15,h*.27),Color("a7a37a")); draw_arc(p,minf(w*.12,h*.22),0,TAU,12,dark,2)
 elif kind=="tape":
  draw_rect(Rect2(w*.08,h*.15,w*.84,h*.68),Color("434c43"))
  draw_rect(Rect2(w*.2,h*.25,w*.6,h*.25),paper)
  draw_circle(Vector2(w*.31,h*.63),h*.1,dark); draw_circle(Vector2(w*.69,h*.63),h*.1,dark)
 elif kind in ["crate","scrap"]:
  draw_colored_polygon(PackedVector2Array([Vector2(.06*w,.28*h),Vector2(.31*w,.13*h),Vector2(.93*w,.24*h),Vector2(.73*w,.38*h)]),Color("928267"))
  draw_colored_polygon(PackedVector2Array([Vector2(.06*w,.28*h),Vector2(.73*w,.38*h),Vector2(.73*w,.92*h),Vector2(.06*w,.8*h)]),Color("706249"))
  draw_colored_polygon(PackedVector2Array([Vector2(.73*w,.38*h),Vector2(.93*w,.24*h),Vector2(.93*w,.76*h),Vector2(.73*w,.92*h)]),Color("514c3d"))
  draw_rect(Rect2(w*.2,h*.43,w*.39,h*.27),paper)
 elif kind in ["kettle","mug"]:
  draw_rect(Rect2(w*.3,h*.36,w*.44,h*.44),Color("99997e"))
  draw_arc(Vector2(w*.77,h*.48),w*.15,-PI*.6,PI*.6,10,Color("85886f"),5)
  if kind=="kettle":
   draw_colored_polygon(PackedVector2Array([Vector2(.3*w,.4*h),Vector2(.06*w,.27*h),Vector2(.15*w,.57*h)]),gray)
   draw_line(Vector2(w*.45,h*.22),Vector2(w*.61,h*.22),dark,5)
 elif kind=="radio":
  draw_rect(Rect2(w*.12,h*.32,w*.75,h*.44),Color("555f4c"))
  for i in range(5): draw_line(Vector2(w*.22,h*(.4+i*.06)),Vector2(w*.49,h*(.4+i*.06)),dark,2)
  draw_circle(Vector2(w*.7,h*.55),h*.1,Color("a7a27a")); draw_line(Vector2(w*.8,h*.34),Vector2(w*.86,h*.06),paper,3)
 elif kind=="locker":
  draw_rect(Rect2(w*.2,h*.08,w*.6,h*.84),Color("566052"))
  draw_rect(Rect2(w*.23,h*.11,w*.54,h*.78),dark,false,3)
  for y in [.3,.53,.75]: draw_line(Vector2(w*.24,h*y),Vector2(w*.76,h*y),Color("a09e82"),3)
 elif kind=="fridge":
  draw_rect(Rect2(w*.21,h*.06,w*.63,h*.9),gray); draw_line(Vector2(w*.23,h*.35),Vector2(w*.82,h*.35),dark,3)
  draw_line(Vector2(w*.73,h*.5),Vector2(w*.73,h*.67),dark,4)
 elif kind=="blanket":
  draw_rect(Rect2(w*.08,h*.2,w*.83,h*.62),Color("775d49")); draw_line(Vector2(w*.13,h*.4),Vector2(w*.89,h*.4),Color("a48c63"),3)
 elif kind in ["bread","paste","stew","water","soap","tea"]:
  if kind=="water":
   draw_rect(Rect2(w*.4,h*.13,w*.2,h*.15),paper); draw_rect(Rect2(w*.29,h*.28,w*.42,h*.59),Color("8fa69c"))
  elif kind=="stew":
   draw_circle(Vector2(w*.5,h*.57),minf(w*.35,h*.3),Color("858b74")); draw_circle(Vector2(w*.5,h*.52),minf(w*.3,h*.24),Color("645338"))
  else: draw_rect(Rect2(w*.12,h*.29,w*.75,h*.48),Color("a59670"))
 else:
  draw_rect(Rect2(w*.18,h*.14,w*.63,h*.7),paper)
 if caption!="" and font:
  draw_string(font,Vector2(12,h-8),caption,HORIZONTAL_ALIGNMENT_CENTER,w-24,19,paper)
