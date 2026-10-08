class_name SchismAudio
extends Node
var ambient: AudioStreamPlayer
var effects: AudioStreamPlayer
var current = ""
var enabled = true

func _ready() -> void:
 ambient = AudioStreamPlayer.new(); add_child(ambient); ambient.volume_db = -15
 effects = AudioStreamPlayer.new(); add_child(effects); effects.volume_db = -9

func scene(id: String,sound: bool) -> void:
 enabled = sound
 if not enabled: ambient.stop(); effects.stop(); return
 if current==id and ambient.playing: return
 current = id
 var path = "res://assets/audio/"+id+".wav"
 if ResourceLoader.exists(path):
  ambient.stream = load(path); ambient.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD; ambient.play()

func travel(location: String) -> void:
 # One soft cue; no repeated footstep loop or stacked door/step sound at every hop.
 play("footsteps" if location=="street" else "door")

func play(id: String) -> void:
 if not enabled: return
 var path = "res://assets/audio/"+id+".wav"
 if ResourceLoader.exists(path):
  effects.volume_db = -27 if id=="footsteps" else -23 if id=="door" else -12
  effects.stream = load(path); effects.play()

func _exit_tree() -> void:
 if ambient: ambient.stop(); ambient.stream = null
 if effects: effects.stop(); effects.stream = null
