extends MarginContainer

# Painted object, with readable live writing kept outside the analogue effects.
const PAPER = preload("res://assets/ui/clipboard-v1.png")
const INK = Color("30291c")
var artwork: Texture2D = PAPER

func _ready() -> void:
 name = "paperwork_art"
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 custom_minimum_size.y = 500
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var t = Theme.new(); t.default_font = load("res://assets/fonts/municipal.ttf"); t.default_font_size = 23
 for kind in ["Label","Button","CheckBox","OptionButton","LineEdit"]:
  t.set_color("font_color",kind,INK); t.set_color("font_hover_color",kind,Color("151309"))
  t.set_color("font_pressed_color",kind,INK); t.set_color("font_disabled_color",kind,Color("78715d"))
 for kind in ["Button","CheckBox","OptionButton"]:
  for state in ["normal","hover","pressed","disabled"]:
   var box = StyleBoxFlat.new(); box.bg_color = Color(.62,.53,.32,.12 if state=="normal" else .25)
   box.border_color = Color("6a6046"); box.set_border_width_all(1)
   box.content_margin_left = 10; box.content_margin_right = 10; box.content_margin_top = 8; box.content_margin_bottom = 8
   t.set_stylebox(state,kind,box)
 var input = StyleBoxFlat.new(); input.bg_color = Color(.85,.79,.59,.6); input.border_color = Color("6a6046"); input.set_border_width_all(1)
 t.set_stylebox("normal","LineEdit",input); t.set_color("caret_color","LineEdit",INK)
 t.set_color("font_placeholder_color","LineEdit",Color("756950"))
 theme = t
 resized.connect(_fit); _fit()

func _fit() -> void:
 add_theme_constant_override("margin_left",int(size.x*.10))
 add_theme_constant_override("margin_right",int(size.x*.10))
 add_theme_constant_override("margin_top",int(size.x*.29))
 add_theme_constant_override("margin_bottom",int(size.x*.15))
 queue_redraw()

func _draw() -> void:
 # Preserve the clip and lower board proportions; only the quiet parchment center stretches.
 var scale = size.x/artwork.get_width()
 var top = 320*scale; var bottom = 128*scale
 draw_texture_rect_region(artwork,Rect2(0,0,size.x,top),Rect2(0,0,artwork.get_width(),320))
 draw_texture_rect_region(artwork,Rect2(0,top,size.x,maxf(0,size.y-top-bottom)),Rect2(0,320,artwork.get_width(),artwork.get_height()-448))
 draw_texture_rect_region(artwork,Rect2(0,size.y-bottom,size.x,bottom),Rect2(0,artwork.get_height()-128,artwork.get_width(),128))
