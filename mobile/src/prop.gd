class_name SchismProp
extends Control

const Visual = preload("res://src/presentation.gd")
var kind = "uniform"
var caption = ""
var detail = ""
var condition = "dirt"
var progress = 0.0
var hatch_open = false
var active = false
var clock = 0.0
var font: Font

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 font = load("res://assets/fonts/municipal.ttf")
 if kind=="washer":
  var shader = ShaderMaterial.new(); shader.shader = load("res://shaders/recovered.gdshader")
  shader.set_shader_parameter("instability",0.0); shader.set_shader_parameter("tracking",0.0); shader.set_shader_parameter("degradation",0.0)
  material = shader
 else:
  var shader = ShaderMaterial.new(); shader.shader = load("res://shaders/isolated.gdshader"); material = shader

func _process(delta: float) -> void:
 if kind=="washer":
  if material: material.set_shader_parameter("running",active and Session.state.settings.effects)
  queue_redraw()

func artwork_rect() -> Rect2:
 var texture = Visual.washer_texture(hatch_open,active) if kind=="washer" else Visual.object_texture(kind,condition)
 if texture==null: return Rect2()
 var available = Vector2(size.x,maxf(0,size.y-(26 if caption!="" else 0)))
 var ratio = minf(available.x/texture.get_width(),available.y/texture.get_height())
 var dimensions = texture.get_size()*ratio
 return Rect2((available-dimensions)*.5,dimensions)

func _draw() -> void:
 var texture = Visual.washer_texture(hatch_open,active) if kind=="washer" else Visual.object_texture(kind,condition)
 if texture: draw_texture_rect(texture,artwork_rect(),false)
 if caption!="" and font:
  draw_string(font,Vector2(12,size.y-8),caption,HORIZONTAL_ALIGNMENT_CENTER,size.x-24,18,Color("d4d0b7"))
