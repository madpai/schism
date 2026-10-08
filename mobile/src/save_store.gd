class_name SchismSaveStore
extends RefCounted
const Sim = preload("res://src/simulation.gd")

var directory: String
var last_error = ""
var blocked = false

func _init(path: String="user://residency") -> void:
 directory = path

func _read(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var parser = JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK: return {}
 var raw = parser.data
 if not raw is Dictionary: return {}
 if raw.get("format","")!="schism-local-v1" or not raw.get("payload") is String: return {}
 if str(raw.get("sha256",""))!=raw.payload.sha256_text(): return {}
 var payload_parser = JSON.new()
 if payload_parser.parse(raw.payload)!=OK: return {}
 var state = payload_parser.data
 if not state is Dictionary or not state.get("identity") is Dictionary: return {}
 if not state.get("needs") is Dictionary or not state.get("items",[]) is Array: return {}
 if int(state.get("revision",-1))!=int(raw.get("revision",-2)): return {}
 for key in ["hunger","thirst","energy","hygiene","health"]:
  if not state.needs.get(key) is float and not state.needs.get(key) is int: return {}
  if state.needs[key]<0 or state.needs[key]>100: return {}
 return state

func load_state() -> Dictionary:
 last_error = ""; blocked = false
 var candidates: Array = []
 var any_file = false
 for slot in range(2):
  var path = directory+"/slot%d.json"%slot
  any_file = any_file or FileAccess.file_exists(path)
  var state = _read(path)
  if not state.is_empty(): candidates.append(state)
 if candidates.is_empty():
  if any_file:
   blocked = true; last_error = "Both residency records are unreadable. Save files were preserved. Restore a backup instead of creating a new resident."
   return {"error":last_error}
  return Sim.initial()
 candidates.sort_custom(func(a,b): return int(a.revision)>int(b.revision))
 var migrated = Sim.migrate(candidates[0])
 if migrated.has("error"): blocked = true; last_error = migrated.error
 return migrated

func save_state(state: Dictionary) -> bool:
 last_error = ""
 if blocked: last_error = "The residency files are held for recovery. No overwrite was attempted."; return false
 if int(state.get("schema",0))!=Sim.SCHEMA: last_error = "Cannot save an unsupported residency version."; return false
 var err = DirAccess.make_dir_recursive_absolute(directory)
 if err!=OK: last_error = "Cannot create the save directory (%d)."%err; return false
 var revisions: Array = []
 for slot in range(2): revisions.append(int(_read(directory+"/slot%d.json"%slot).get("revision",-1)))
 var chosen = 0 if revisions[0]<=revisions[1] else 1
 var target = directory+"/slot%d.json"%chosen
 var temp = target+".pending"
 var payload = JSON.stringify(state)
 var envelope = {"format":"schism-local-v1","revision":state.revision,"sha256":payload.sha256_text(),"payload":payload}
 var file = FileAccess.open(temp,FileAccess.WRITE)
 if file==null: last_error = "Storage could not open your residency record."; return false
 file.store_string(JSON.stringify(envelope)); file.flush()
 var write_error = file.get_error(); file.close()
 if write_error!=OK or _read(temp).is_empty(): last_error = "Your residency write could not be verified. The previous save is safe."; return false
 err = DirAccess.rename_absolute(temp,target)
 if err!=OK: last_error = "Storage could not commit your residency record (%d)."%err; return false
 return true
