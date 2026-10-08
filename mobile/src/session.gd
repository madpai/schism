extends Node
const Sim = preload("res://src/simulation.gd")
const Store = preload("res://src/save_store.gd")

signal changed(events: Array)
signal rejected(message: String)

var state: Dictionary
var store
var recovery_error = ""

func _ready() -> void:
 # Testing may choose an isolated directory, never a live player profile.
 var path = "user://residency"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--save-dir="): path = arg.trim_prefix("--save-dir=")
 store = Store.new(path)
 var loaded = store.load_state()
 if loaded.has("error"):
  recovery_error = loaded.error; state = Sim.initial()
 else: state = loaded
 get_tree().auto_accept_quit = false

func command(cmd: Dictionary) -> bool:
 if recovery_error!="": rejected.emit(recovery_error); return false
 var result = Sim.apply(state,cmd)
 if not result.ok: rejected.emit(result.error); return false
 if not store.save_state(result.state): rejected.emit(store.last_error); return false
 state = result.state
 changed.emit(result.events)
 return true

func flush() -> void:
 if recovery_error=="" and not store.save_state(state): rejected.emit(store.last_error)

func _notification(what: int) -> void:
 if store==null: return
 if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]: flush()
 if what==NOTIFICATION_WM_CLOSE_REQUEST:
  flush(); get_tree().quit()
