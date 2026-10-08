class_name SchismPresentation
extends RefCounted

# Draw commands outlive _draw() locals. Hold atlas/base textures through the render frame.
static var texture_cache: Dictionary = {}
static var authored_data: Dictionary = {}

static func data() -> Dictionary:
 if authored_data.is_empty(): authored_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/objects.json"))
 return authored_data

static func crop(path: String,rect: Array) -> AtlasTexture:
 var key = path+str(rect)
 if texture_cache.has(key): return texture_cache[key]
 var source: Texture2D = load(path)
 var atlas = AtlasTexture.new(); atlas.atlas = source
 atlas.region = Rect2(Vector2(rect[0],rect[1])*source.get_size(),Vector2(rect[2],rect[3])*source.get_size())
 atlas.filter_clip = true
 texture_cache[key] = atlas
 return atlas

static func object_texture(kind: String,condition: String="dirt") -> Texture2D:
 var d = data(); var key = kind
 if kind=="uniform" and condition in ["oil","blood"]: key = "uniform_"+condition
 if d.cells.has(key):
  var index = int(d.cells[key]); var cols = int(d.grid[0]); var rows = int(d.grid[1])
  return crop(d.atlas,[float(index%cols)/cols,float(index/cols)/rows,1.0/cols,1.0/rows])
 if d.crops.has(key): return crop(d.crops[key].asset,d.crops[key].rect)
 return null

static func laundry_state(s: Dictionary) -> Dictionary:
 var d = data().laundry
 var w = s.get("shift",{})
 if w.is_empty() or w.get("job","")!="laundry": return {"asset":d.full,"remaining":4,"running":false}
 var remaining = w.get("uniforms",[]).filter(func(u): return not u.get("sorted",false)).size() if w.stage=="inspect" else 0
 var running = w.stage=="washed"
 return {"asset":d.running if running else d.open if w.get("hatch_open",false) else d.closed,"remaining":remaining,"running":running}

static func washer_texture(hatch_open: bool,running: bool) -> Texture2D:
 var d = data().laundry
 return crop(d.running if running else d.open if hatch_open else d.closed,d.washer_crop)
