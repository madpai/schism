extends Control

const Sim = preload("res://src/simulation.gd")
const Prop = preload("res://src/prop.gd")
const Atmosphere = preload("res://src/environment.gd")
const Sound = preload("res://src/audio.gd")
const INK = Color("d4d0b7")
const MUTED = Color("a3aa92")
const ACCENT = Color("c2b476")
var scene_data: Dictionary
var content: Control
var modal: Control
var sheet_body: VBoxContainer
var thought: Label
var thought_time = 0.0
var audio
var transition: ColorRect
var busy = false
var after_action: Callable
var pending_notices: Array = []
var official: Font
var human: Font
var animation_clock = 0.0

func _ready() -> void:
 official = load("res://assets/fonts/municipal.ttf")
 human = load("res://assets/fonts/thought.ttf")
 scene_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/scenes.json")).scenes
 _theme()
 audio = Sound.new(); add_child(audio)
 Session.changed.connect(_changed); Session.rejected.connect(_rejected)
 get_tree().root.size_changed.connect(_render_world)
 _render_world()
 if Session.recovery_error!="": _message("RESIDENCY RECOVERY",Session.recovery_error)
 elif not Session.state.identity.registered: _registration()
 elif not Session.state.arrival_seen: _arrival()

func _theme() -> void:
 var t = Theme.new(); t.default_font = official; t.default_font_size = 23
 t.set_color("font_color","Label",INK)
 t.set_color("font_color","Button",INK)
 t.set_color("font_hover_color","Button",Color("fff1c1"))
 t.set_color("font_disabled_color","Button",MUTED)
 t.set_stylebox("normal","Button",_box(Color("29342b"),Color("606c55")))
 t.set_stylebox("hover","Button",_box(Color("344537"),ACCENT))
 t.set_stylebox("pressed","Button",_box(Color("555a3b"),INK))
 t.set_stylebox("disabled","Button",_box(Color("222b23"),Color("424b3b")))
 t.set_stylebox("normal","LineEdit",_box(Color("111b15"),Color("74775e")))
 t.set_color("font_color","LineEdit",INK)
 t.set_color("font_placeholder_color","LineEdit",MUTED)
 t.set_constant("separation","VBoxContainer",12)
 theme = t

func _box(bg: Color,border: Color,width: int=1) -> StyleBoxFlat:
 var b = StyleBoxFlat.new(); b.bg_color = bg; b.border_color = border
 b.set_border_width_all(width); b.content_margin_left = 14; b.content_margin_right = 14
 b.content_margin_top = 10; b.content_margin_bottom = 10
 return b

func _clear(node: Node) -> void:
 for child in node.get_children(): node.remove_child(child); child.queue_free()

func _render_world() -> void:
 if not is_node_ready(): return
 if content:
  remove_child(content); content.queue_free()
 content = Control.new(); content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(content); move_child(content,0)
 var s = Session.state; var location = s.location; var data = scene_data[location].duplicate(true)
 if location=="room": data.title = s.housing.address.to_upper()
 var backdrop = ColorRect.new(); backdrop.color = Color("101913"); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); content.add_child(backdrop)
 var header = VBoxContainer.new(); header.position = Vector2(18,12); header.size = Vector2(size.x-36,86); content.add_child(header)
 var top = HBoxContainer.new(); header.add_child(top)
 var brand = _label("S C H I S M",30); brand.autowrap_mode = TextServer.AUTOWRAP_OFF; brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(brand)
 var time_label = _label("DAY %02d  %02d:%02d"%[int(s.minute/1440)+1,int(s.minute/60)%24,int(s.minute)%60],18); time_label.autowrap_mode = TextServer.AUTOWRAP_OFF; time_label.modulate = MUTED; top.add_child(time_label)
 var location_label = _label(data.title,20); location_label.autowrap_mode = TextServer.AUTOWRAP_OFF; header.add_child(location_label)
 var area = Control.new(); area.position = Vector2(0,100); area.size = Vector2(size.x,maxf(400,size.y-222)); content.add_child(area)
 area.clip_contents = true
 var texture = TextureRect.new(); texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; texture.stretch_mode = TextureRect.STRETCH_SCALE
 var path = "res://assets/scenes/"+data.asset
 if ResourceLoader.exists(path): texture.texture = load(path)
 texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var material = ShaderMaterial.new(); material.shader = load("res://shaders/recovered.gdshader")
 if not s.settings.effects: material.set_shader_parameter("instability",0); material.set_shader_parameter("tracking",0)
 texture.material = material; area.add_child(texture)
 var environment = Atmosphere.new(); environment.location = location; environment.state = s; environment.enabled = s.settings.effects; environment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); area.add_child(environment)
 for hotspot in data.hotspots:
  var rect = hotspot.rect
  var button = Button.new(); button.name = "hotspot_"+hotspot.id
  button.position = Vector2(rect[0]*area.size.x,rect[1]*area.size.y)
  button.size = Vector2(maxf(64,rect[2]*area.size.x),maxf(64,rect[3]*area.size.y))
  button.position.x = minf(button.position.x,area.size.x-button.size.x)
  button.position.y = minf(button.position.y,area.size.y-button.size.y)
  button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
  button.add_theme_stylebox_override("hover",_box(Color(.72,.75,.49,.035),Color(.8,.8,.55,.35)))
  button.add_theme_stylebox_override("pressed",_box(Color(.72,.75,.49,.13),ACCENT))
  button.custom_minimum_size = Vector2(64,64)
  button.focus_mode = Control.FOCUS_NONE
  button.pressed.connect(func(): if not busy: _hotspot(hotspot.id))
  area.add_child(button)
  if s.settings.hints:
   var badge = PanelContainer.new(); badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
   badge.add_theme_stylebox_override("panel",_box(Color(.035,.07,.045,.8),Color(.64,.67,.51,.4)))
   var label = _label("· "+hotspot.label,18); label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; badge.add_child(label)
   badge.size = Vector2(label.get_minimum_size().x+28,37)
   badge.position = Vector2(clampf(4,-button.position.x,area.size.x-button.position.x-badge.size.x),maxf(0,button.size.y-37)); button.add_child(badge)
 _scene_objects(area,s)
 _room_props(area,s)
 var bottom = VBoxContainer.new(); bottom.position = Vector2(16,size.y-114); bottom.size = Vector2(size.x-32,108); content.add_child(bottom)
 var caption = _label(_context(s,data.subtitle),19); caption.modulate = MUTED; caption.custom_minimum_size.y = 31; bottom.add_child(caption)
 var dock = HBoxContainer.new(); dock.add_theme_constant_override("separation",10); bottom.add_child(dock)
 var status = _button("CIVIC ID",_status); status.name = "status"; status.size_flags_horizontal = Control.SIZE_EXPAND_FILL; dock.add_child(status)
 var bag = _button("BAG  /  %d"%_inventory().size(),_bag); bag.name = "bag"; bag.size_flags_horizontal = Control.SIZE_EXPAND_FILL; dock.add_child(bag)
 var settings = _button("···",_settings); settings.name = "settings"; settings.custom_minimum_size.x = 64; dock.add_child(settings)
 if thought and is_instance_valid(thought): thought.queue_free()
 thought = _label("",23); thought.add_theme_font_override("font",human); thought.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; thought.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 thought.position = Vector2(18,size.y-215); thought.size = Vector2(size.x-36,80)
 thought.add_theme_color_override("font_shadow_color",Color.BLACK); thought.add_theme_constant_override("shadow_offset_x",2); thought.add_theme_constant_override("shadow_offset_y",2)
 thought.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(thought)
 if audio and audio.is_node_ready(): audio.scene(data.audio,s.settings.sound)

func _room_props(area: Control,s: Dictionary) -> void:
 if s.location!="room": return
 var positions = {"kettle":Vector2(.54,.56),"mug":Vector2(.56,.38),"radio":Vector2(.55,.46),"fridge":Vector2(.59,.65)}
 for kind in positions:
  if kind in s.room_upgrades:
   var p = Prop.new(); p.kind = kind; p.position = positions[kind]*area.size; p.size = area.size*Vector2(.16,.13); area.add_child(p)
   var click = Button.new(); click.position = p.position; click.size = Vector2(maxf(p.size.x,64),maxf(p.size.y,64)); click.add_theme_stylebox_override("normal",StyleBoxEmpty.new()); click.pressed.connect(func(): _possession(kind)); area.add_child(click)

func _scene_objects(area: Control,s: Dictionary) -> void:
 if s.location=="room":
  var paper = Prop.new(); paper.kind = "paper"; paper.position = Vector2(.56,.8)*area.size; paper.size = Vector2(.14,.11)*area.size; area.add_child(paper)
 if s.location=="bureau" and s.ticket:
  var display = PanelContainer.new(); display.position = Vector2(.35,.15)*area.size; display.size = Vector2(.22,.1)*area.size
  display.mouse_filter = Control.MOUSE_FILTER_IGNORE; display.add_theme_stylebox_override("panel",_box(Color("11170f"),Color("525744")))
  var number = _label("C-184\nWINDOW 3",19); number.autowrap_mode = TextServer.AUTOWRAP_OFF; number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; number.mouse_filter = Control.MOUSE_FILTER_IGNORE; display.add_child(number); area.add_child(display)
 if s.location=="freight" and not s.shift.is_empty():
  for n in range(s.shift.crates.size()):
   var box = s.shift.crates[n]
   var button = Button.new(); button.position = Vector2(.22+.175*n,.45)*area.size; button.size = Vector2(.16,.13)*area.size; button.custom_minimum_size = Vector2(64,64)
   button.add_theme_font_size_override("font_size",18)
   if box.routed:
    button.text = "SENT"; button.disabled = true; button.add_theme_stylebox_override("disabled",_box(Color("272f23"),Color("717053")))
   else:
    button.text = box.serial; button.add_theme_stylebox_override("normal",_box(Color(.45,.41,.3,.22),Color(.65,.64,.45,.45))); button.pressed.connect(func(): _crate(n))
   area.add_child(button)

func _context(s: Dictionary,fallback: String) -> String:
 if s.location=="bureau" and s.ticket: return "C-184  /  WINDOW 3     •     %d CR"%int(s.credits)
 if not s.shift.is_empty():
  if s.shift.stage=="receipt": return "WORK COUNTED  /  collect the timecard     •     %d CR"%int(s.credits)
  return "ORDER %s  /  %s     •     %d CR"%[s.shift.id.right(3),str(s.shift.stage).to_upper(),int(s.credits)]
 return fallback+"     •     %d CR"%int(s.credits)

func _process(delta: float) -> void:
 animation_clock += delta
 if thought and is_instance_valid(thought) and thought_time>0:
  thought_time -= delta; thought.modulate.a = clampf(thought_time,0,1)

func _thought(text: String) -> void:
 if thought and is_instance_valid(thought): thought.text = '“'+text+'”'; thought.modulate.a = 1; thought_time = 4.5

func _label(text: String,points: int=23) -> Label:
 var label = Label.new(); label.text = text; label.add_theme_font_size_override("font_size",points); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 return label

func _button(text: String,callback: Callable) -> Button:
 var b = Button.new(); b.text = text; b.custom_minimum_size = Vector2(0,64); b.pressed.connect(callback)
 return b

func _sheet(title: String) -> void:
 _close_sheet()
 modal = Control.new(); modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(modal)
 var shade = ColorRect.new(); shade.color = Color(0,0,0,.58); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal.add_child(shade)
 var panel = PanelContainer.new(); panel.position = Vector2(10,maxf(92,size.y*.19)); panel.size = Vector2(size.x-20,size.y-panel.position.y-12); modal.add_child(panel)
 panel.add_theme_stylebox_override("panel",_box(Color("17231a"),Color("7b8061"),2))
 var outer = VBoxContainer.new(); outer.add_theme_constant_override("separation",12); panel.add_child(outer)
 var row = HBoxContainer.new(); outer.add_child(row)
 var heading = _label(title,27); heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(heading)
 var close = _button("×",_close_sheet); close.name = "close_sheet"; close.custom_minimum_size.x = 64; row.add_child(close)
 var scroll = ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; outer.add_child(scroll)
 sheet_body = VBoxContainer.new(); sheet_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sheet_body.add_theme_constant_override("separation",13); scroll.add_child(sheet_body)

func _close_sheet() -> void:
 if modal and is_instance_valid(modal): remove_child(modal); modal.queue_free()
 modal = null

func _body(text: String,points: int=23) -> Label:
 var label = _label(text,points); sheet_body.add_child(label); return label

func _action(text: String,cmd: Dictionary,next: Callable=Callable()) -> Button:
 var b = _button(text,func(): _do(cmd,next)); sheet_body.add_child(b); return b

func _do(cmd: Dictionary,next: Callable=Callable()) -> void:
 if busy: return
 after_action = next
 _close_sheet()
 if not Session.command(cmd): after_action = Callable()

func _changed(events: Array) -> void:
 _render_world()
 if after_action.is_valid():
  var callback = after_action; after_action = Callable(); callback.call()
 for event in events:
  match event.type:
   "thought": _thought(event.text)
   "found": _found(event.id)
   "receipt": _receipt(event.data)
   "notice": pending_notices.append(event.text)
   "recording": _message("DAMAGED TRAINING RECORD",event.text)
   "sound": audio.play(event.name)
 if not pending_notices.is_empty() and modal==null:
  var text = "\n\n".join(pending_notices); pending_notices = []; _message("CIVIC NOTICE",text)

func _rejected(message: String) -> void:
 audio.play("buzzer"); _message("THE OBJECT DOESN'T MOVE",message)

func _message(title: String,text: String) -> void:
 _sheet(title); _body(text)
 var close = _button("Put the paper down",_close_sheet); sheet_body.add_child(close)

func _registration() -> void:
 _sheet("TEMPORARY CIVIC RESIDENCY")
 modal.find_child("close_sheet",true,false).disabled = true
 _body("DISTRICT IX\nHousing: Block C / Room 17\nBalance: 4 CR\nEmployment: UNASSIGNED",25)
 _body("Name for the registry",19)
 var name_input = LineEdit.new(); name_input.name = "resident_name"; name_input.text = "William"; name_input.max_length = 24; name_input.custom_minimum_size.y = 64; sheet_body.add_child(name_input)
 var appearance = OptionButton.new(); appearance.custom_minimum_size.y = 64; appearance.add_item("Olive / cropped hair"); appearance.add_item("Umber / cropped hair"); appearance.add_item("Sand / cropped hair"); sheet_body.add_child(appearance)
 _body("The train has gone. They gave you a key.\n\nTap objects to live here. Your bag and civic papers stay within reach. Time passes when you act.")
 var submit = _button("Sign the residency paper",func(): _do({"action":"register","name":name_input.text,"appearance":["olive","umber","sand"][appearance.selected]},_arrival)); submit.name = "register"; sheet_body.add_child(submit)

func _arrival() -> void:
 _sheet("BLOCK C  /  ROOM 17")
 _body("One key. A bed. A sink that runs cold.\n\nYour civic paper says you are expected to support yourself.\n\nThe labor bureau is across the courtyard. A free public tap and emergency meal chit remain available when you're broke.")
 _action("Fold the paper. Look around.",{"action":"arrival"})

func _hotspot(id: String) -> void:
 var s = Session.state
 match s.location:
  "room":
   match id:
    "door": _travel("hall")
    "bed":
     _sheet("METAL BED"); _body("A thin mattress. Industrial noise through the wall.\nEight hours of your time. No cost while the app is closed."); _action("Pull the blanket over you",{"action":"sleep"})
    "sink":
     _sheet("CHIPPED SINK"); _body("Cold water. The pipes knock before it arrives."); _action("Cup your hands and drink",{"action":"drink"}); _action("Wash face and hands",{"action":"wash"})
    "locker": _storage("locker")
    "paper": _tenancy()
  "hall":
   match id:
    "room": _travel("room")
    "stairs": _travel("street")
    "notice": _message("MUNICIPAL NOTICE","Resident labor authorization is issued at Window 3.\n\nAll residents must be accounted for.\n\nThis notice replaces an identical notice.")
  "street":
   if id=="tap": _do({"action":"drink"})
   else: _travel(id)
  "bureau":
   match id:
    "exit": _travel("street")
    "ticket":
     if s.ticket: _message("C-184  /  WINDOW 3","Your number is still on the display. There is no need to take another ticket.")
     else: _do({"action":"ticket"},func(): _message("C-184","The dispenser coughs out your number.\n\nC-184 / WINDOW 3\nHave your identification ready.")); audio.play("beep")
    "clerk":
     if not s.ticket: _thought("I suppose I need a ticket.")
     elif not s.id_shown:
      _sheet("WINDOW 3"); _body('The clerk holds out a hand.\n\n“Identification.”'); _action("Slide your civic ID under the glass",{"action":"show_id"},_vacancies)
     else: _vacancies()
    "vacancies": _vacancies()
  "laundry":
   match id:
    "exit": _travel("street")
    "cart": _cart()
    "washer", "controls", "detergent": _washer()
    "outgoing": _outgoing()
    "tray": _lost_property()
  "shop":
   match id:
    "exit": _travel("street")
    "food": _shop(["bread","paste"])
    "stew": _shop(["stew","tea"])
    "water": _shop(["water","soap"])
    "goods": _shop(["mug","blanket","shelf","kettle","radio","fridge"])
    "relief":
     _sheet("MUNICIPAL MEAL CHIT"); _body("For residents with two credits or less. One ration per played day. No repayment."); _action("Hand over your civic paper",{"action":"relief"})
  "cleaning": _cleaning(id)
  "freight": _freight(id)
  "camp": _camp(id)

func _travel(target: String) -> void:
 _close_sheet()
 if not Session.state.shift.is_empty(): _do({"action":"travel","to":target}); return
 busy = true; audio.play("door")
 var veil = ColorRect.new(); veil.color = Color(0,0,0,0); veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(veil)
 var tween = create_tween(); tween.tween_property(veil,"color:a",1.0,.14)
 await tween.finished
 busy = false; _do({"action":"travel","to":target})
 audio.play("footsteps")
 var fade = create_tween(); fade.tween_property(veil,"color:a",0.0,.2); fade.tween_callback(veil.queue_free)

func _status() -> void:
 var s = Session.state
 _sheet(s.identity.name.to_upper()+"  /  CIVIC ID "+s.identity.civic_id)
 var row = HBoxContainer.new(); sheet_body.add_child(row)
 var portrait = TextureRect.new(); portrait.custom_minimum_size = Vector2(140,250); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 if ResourceLoader.exists("res://assets/scenes/citizen-v1.png"): portrait.texture = load("res://assets/scenes/citizen-v1.png")
 var tint = Color(.8,.85,.75) if s.needs.hygiene<35 else Color.WHITE
 if s.identity.appearance=="umber": tint *= Color(.69,.63,.52)
 if s.identity.appearance=="sand": tint *= Color(1.08,1.02,.92)
 portrait.modulate = tint
 var condition_shader = ShaderMaterial.new(); condition_shader.shader = load("res://shaders/condition.gdshader")
 condition_shader.set_shader_parameter("grime",clampf((65.0-s.needs.hygiene)/65.0,0,1))
 condition_shader.set_shader_parameter("fatigue",clampf((55.0-s.needs.energy)/55.0,0,1))
 condition_shader.set_shader_parameter("injury",clampf((75.0-s.needs.health)/75.0,0,1))
 portrait.material = condition_shader; row.add_child(portrait)
 var stats = VBoxContainer.new(); stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(stats)
 for pair in [["hunger","Hunger / fed"],["thirst","Thirst / hydrated"],["energy","Energy"],["hygiene","Hygiene"],["health","Health"]]:
  stats.add_child(_label("%s  %d%%"%[pair[1],int(s.needs[pair[0]])],22))
  var bar = ProgressBar.new(); bar.value = s.needs[pair[0]]; bar.show_percentage = false; bar.custom_minimum_size.y = 8
  bar.add_theme_stylebox_override("background",_box(Color("283529"),Color("283529"),0)); bar.add_theme_stylebox_override("fill",_box(ACCENT if bar.value>=25 else Color("a8674c"),Color.TRANSPARENT,0)); stats.add_child(bar)
 var conditions: Array = []
 if s.needs.hunger<40: conditions.append("Hungry")
 if s.needs.thirst<40: conditions.append("Thirsty")
 if s.needs.energy<40: conditions.append("Tired eyes")
 if s.needs.hygiene<40: conditions.append("Stained clothing")
 if s.needs.health<65: conditions.append("Bruising")
 _body("Condition: "+(", ".join(conditions) if not conditions.is_empty() else "Getting by"))
 _body("Credits: %d CR\nEmployment: %s\nHousing: %s"%[int(s.credits),Sim.catalog().jobs.get(s.employment,{}).get("name","UNASSIGNED"),s.housing.address])
 if not s.employment.is_empty():
  var record = s.jobs[s.employment]; _body("Completed shifts: %d\nEmployer trust: %d\nWarnings: %d"%[int(record.shifts),int(record.trust),int(record.warnings)],20)
 if s.legal.offenses>0: _body("Civic record: %d inventory offenses"%int(s.legal.offenses),20)

func _inventory() -> Array:
 return Session.state.items.filter(func(item): return item.owner=="player" and item.get("storage","bag")=="bag")

func _bag() -> void:
 _sheet("WHAT YOU CARRY")
 _body("%d CR  /  Each object has a previous life."%int(Session.state.credits),20)
 var items = _inventory()
 if items.is_empty(): _body("Your pockets are empty. Your civic paper and room key are all you came with.")
 for item in items:
  var card = _button(item.label+"  /  "+item.serial,func(): _item_sheet(item.id)); sheet_body.add_child(card)
 if Session.state.location=="room":
  for kind in Session.state.room_upgrades:
   var b = _button(kind.to_upper()+"  /  in your room",func(): _possession(kind)); sheet_body.add_child(b)

func _item_sheet(id: String) -> void:
 var item = Sim._find(Session.state,id)
 _sheet(item.label.to_upper())
 _prop(item.kind,180)
 _body("Serial: %s\nCondition: %s\nOrigin: %s\nPrevious owner: %s"%[item.serial,"spoiled" if Sim.is_spoiled(item,int(Session.state.minute)) else item.condition,item.origin,item.rightful_owner],20)
 _body("Kept in: "+str(item.get("storage","bag")).capitalize(),20)
 if item.metadata.has("text"): _body(item.metadata.text)
 if item.metadata.has("label"): _body(item.metadata.label)
 if item.kind=="credits": _body("These loose credits are already in your civic balance. The pocket receipt remains attached to the record.")
 var definition = Sim.catalog().items.get(item.kind,{})
 if definition.has("food") or definition.has("water"): _action("Unwrap and eat" if definition.has("food") else "Open and drink",{"action":"consume","id":id})
 if Session.state.location=="room":
  var kept = str(item.get("storage","bag"))
  if kept!="bag": _action("Put it in your bag",{"action":"store_item","id":id,"storage":"bag"},_bag)
  if kept!="locker": _action("Place on the locker shelf",{"action":"store_item","id":id,"storage":"locker"},func(): _storage("locker"))
  if kept!="fridge" and "fridge" in Session.state.room_upgrades and (definition.has("food") or definition.has("water")):
   _action("Put it in the cold cabinet",{"action":"store_item","id":id,"storage":"fridge"},func(): _storage("fridge"))
 if definition.get("upgrade",false): _action("Place in your room",{"action":"install","id":id})
 if item.kind=="tape": _action("Try the receiver's tape adapter",{"action":"play_tape"})

func _storage(place: String) -> void:
 _sheet("COLD CABINET / YOUR ROOM" if place=="fridge" else "LOCKER / YOUR ROOM")
 _prop("fridge" if place=="fridge" else "locker",130)
 _body("The motor hums. Food ages more slowly here." if place=="fridge" and Session.state.housing.utilities else "The cabinet is warm. The public tap still works." if place=="fridge" else "A shelf behind a door that locks. Things stay here when you leave.",20)
 var stored = Session.state.items.filter(func(item): return item.owner=="player" and item.get("storage","bag")==place)
 for item in stored:
  var card = _button(item.label+"  /  "+("SPOILED" if Sim.is_spoiled(item,int(Session.state.minute)) else item.serial),func(): _item_sheet(item.id)); sheet_body.add_child(card)
 if stored.is_empty(): _body("Empty. For now.")
 var carried = _inventory().filter(func(item): return place!="fridge" or Sim.catalog().items.get(item.kind,{}).has("food") or Sim.catalog().items.get(item.kind,{}).has("water"))
 if not carried.is_empty():
  _body("IN YOUR BAG",18)
  for item in carried: _action("Set down "+item.label,{"action":"store_item","id":item.id,"storage":place},func(): _storage(place))
 if place=="locker":
  for kind in Session.state.room_upgrades:
   var installed = _button(kind.to_upper()+" / in your room",func(): _possession(kind)); sheet_body.add_child(installed)

func _prop(kind: String,height: int=160,caption: String="") -> Control:
 var prop = Prop.new(); prop.kind = kind; prop.caption = caption; prop.custom_minimum_size = Vector2(0,height); sheet_body.add_child(prop); return prop

func _touch_prop(prop: Control,zone: Rect2,label: String,cmd: Dictionary,next: Callable=Callable()) -> void:
 var button = Button.new(); button.text = label; button.add_theme_font_size_override("font_size",18)
 button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 button.anchor_left = zone.position.x; button.anchor_top = zone.position.y
 button.anchor_right = zone.end.x; button.anchor_bottom = zone.end.y
 button.custom_minimum_size = Vector2(64,64)
 button.add_theme_stylebox_override("normal",_box(Color(.06,.1,.065,.68),Color(.7,.72,.5,.5)))
 button.pressed.connect(func(): _do(cmd,next)); prop.add_child(button)

func _possession(kind: String) -> void:
 if kind=="fridge": _storage("fridge"); return
 _sheet(kind.to_upper()+"  /  YOUR ROOM")
 _prop(kind,170); _body(Sim.catalog().items.get(kind,{}).get("description","It belongs here now."))
 if kind=="radio": _action("Fit the damaged tape",{"action":"play_tape"})
 if kind=="kettle":
  var tea = Sim._owned(Session.state,"tea")
  if not tea.is_empty(): _action("Boil water and make tea",{"action":"consume","id":tea.id})
  else: _body("A tin of tea from the kiosk would make an evening of it.")

func _vacancies() -> void:
 _sheet("WINDOW 3  /  RESIDENT WORK AUTHORIZATION")
 if not Session.state.id_shown:
  _body("The papers are behind glass. The clerk wants a ticket and your civic identification first."); return
 _body('“Three vacancies. All temporary.”',22)
 for id in ["laundry","cleaning","freight"]:
  var job = Sim.catalog().jobs[id]
  _body(job.name.to_upper(),24); _body("%d CR GROSS  /  %s"%[int(job.gross),job.description],20)
  _action("Sign "+job.name+" authorization",{"action":"apply_job","job":id})
 if not Session.state.employment.is_empty() and Session.state.jobs[Session.state.employment].shifts>=12:
  _body("NOTICE OF INTERNAL VACANCY\n"+Sim.catalog().jobs[Session.state.employment].advanced+"\nTwelve completed shifts. One more credit. A supply key.")
  _action("Present your completed shift record",{"action":"promote"})
 var tenancy = _button("Inspect the tenancy papers",_tenancy); sheet_body.add_child(tenancy)

func _tenancy() -> void:
 var h = Session.state.housing
 _sheet("MUNICIPAL TENANCY RECORD")
 _body("%s\nRent: %d CR / played day\nArrears: %d CR\nUtilities: %s"%[h.address,int(h.rent),int(h.arrears),"working" if h.utilities else "interrupted"])
 if h.rent>0: _body("Next bill: Day %d\nDeposit on record: %d CR"%[int(h.next_bill/1440)+1,int(h.deposit)],20)
 _body("Your obligations advance with your actions. Closing the app does not add debt.",20)
 if h.arrears>0: _action("Pay the recorded arrears",{"action":"pay_rent"})
 if Session.state.location=="bureau":
  _action("Sign private room tenancy / 25 CR deposit",{"action":"rent","tier":"private"})
  _action("Sign apartment tenancy / 80 CR deposit",{"action":"rent","tier":"apartment"})
  _action("Return to municipal Room 17",{"action":"rent","tier":"municipal"})

func _cart() -> void:
 var s = Session.state
 _sheet("INCOMING UNIFORM CART")
 if s.shift.is_empty():
  _prop("uniform",210,"PROPERTY OF MUNICIPAL TEXTILE SERVICES")
  _body("Four uniforms. Pockets must be checked. Follow the service labels.\n\n7 CR gross. Four hours in the city; a few minutes in your hands.")
  _action("Pull the cart up to the inspection bench",{"action":"begin_shift"},_cart); return
 if s.shift.job!="laundry": return
 if s.shift.stage!="inspect": _body("The incoming cart is empty. The bundle is at the machine."); return
 var rack = GridContainer.new(); rack.columns = 2; rack.add_theme_constant_override("h_separation",10); rack.add_theme_constant_override("v_separation",12); sheet_body.add_child(rack)
 for i in range(s.shift.uniforms.size()):
  var u = s.shift.uniforms[i]
  var card = _button("UNIFORM %02d"%[i+1],func(): _uniform(i)); card.name = "uniform_%d"%i; card.custom_minimum_size = Vector2(0,176); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL; card.alignment = HORIZONTAL_ALIGNMENT_LEFT
  card.add_theme_font_size_override("font_size",18)
  var style = _box(Color("202a21"),Color("606c55")); style.content_margin_top = 136; card.add_theme_stylebox_override("normal",style)
  for state_name in ["hover","pressed","disabled"]:
   var state_style = style.duplicate(); state_style.bg_color = Color("2c372c") if state_name=="hover" else Color("1a211a"); card.add_theme_stylebox_override(state_name,state_style)
  var coat = Prop.new(); coat.kind = "uniform"; coat.condition = u.stain; coat.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); coat.offset_left = 10; coat.offset_right = -10; coat.offset_top = 8; coat.offset_bottom = 133; coat.modulate = Color(.55,.55,.5) if u.sorted else Color.WHITE; card.add_child(coat)
  card.disabled = u.sorted
  if u.sorted: card.text = "IN BIN / %02d"%[i+1]
  rack.add_child(card)
 _body("Sort by service label. Tap a uniform to unfold it and inspect its pockets.",20)

func _uniform(index: int) -> void:
 var s = Session.state; var u = s.shift.uniforms[index]
 _sheet("INSPECTION BENCH  /  UNIFORM %02d"%(index+1))
 var prop = _prop("uniform",230); prop.condition = u.stain
 if not u.inspected: _touch_prop(prop,Rect2(.57,.15,.32,.29),"SERVICE LABEL",{"action":"inspect_uniform","index":index},func(): _uniform(index))
 elif not u.pocket_checked: _touch_prop(prop,Rect2(.53,.3,.22,.28),"POCKET",{"action":"inspect_pocket","index":index},func(): _uniform(index))
 if not u.inspected:
  _body("A heavy municipal jacket. The service label is folded inside.")
  _action("Unfold and read the label",{"action":"inspect_uniform","index":index},func(): _uniform(index)); return
 _body("SERVICE: %s\nSTAIN: %s\nTREATMENT: %s"%[u.type.to_upper(),u.stain.to_upper(),"SANITIZE" if u.stain=="blood" else "HOT WASH" if u.stain=="oil" else "STANDARD WASH"],23)
 if not u.pocket_checked: _action("Turn out the jacket pockets",{"action":"inspect_pocket","index":index},func(): _uniform(index))
 elif u.found!="" and Sim._find(s,u.found).owner=="found":
  var button = _button("Inspect the object in the pocket",func(): _found(u.found)); sheet_body.add_child(button)
 else: _body("Pockets checked. Nothing left inside.",20)
 if not u.sorted:
  _body("Place in a service bin",19)
  var bins = GridContainer.new(); bins.columns = 2; bins.add_theme_constant_override("h_separation",10); bins.add_theme_constant_override("v_separation",10); sheet_body.add_child(bins)
  for category in ["general","security","factory","medical"]:
   var bin_button = _button("▤  "+category.to_upper(),func(): _do({"action":"sort_uniform","index":index,"bin":category},_cart)); bin_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; bins.add_child(bin_button)
 else: _body("The uniform is in its sorting bin.")

func _found(id: String) -> void:
 var item = Sim._find(Session.state,id)
 _sheet(item.label.to_upper())
 _prop(item.kind,210)
 _body("Origin: "+item.origin+"\n"+item.metadata.get("label",item.metadata.get("text","")))
 _body(item.metadata.get("evidence","There is no name on it."),20)
 if Session.state.credits<6: _thought("Nobody would know.")
 _action("Place in Lost Property tray",{"action":"found_choice","id":id,"choice":"return"})
 _action("Put in your pocket",{"action":"found_choice","id":id,"choice":"keep"})
 _action("Leave it where it was",{"action":"found_choice","id":id,"choice":"leave"})

func _washer() -> void:
 var s = Session.state
 _sheet("INDUSTRIAL WASHER 03")
 var prop = _prop("washer",270)
 if s.shift.is_empty(): _body("The machine is quiet. Today's uniforms are in the incoming cart."); return
 var w = s.shift; prop.hatch_open = w.get("hatch_open",false); prop.active = w.stage=="washed"
 if w.stage=="inspect": _touch_prop(prop,Rect2(.22,.35,.56,.49),"HATCH",{"action":"open_hatch"},_washer)
 if w.stage=="prepare":
  if w.hatch_open: _touch_prop(prop,Rect2(.04,.05,.23,.22),"DOSE",{"action":"dose"},_washer)
  else: _touch_prop(prop,Rect2(.23,.4,.55,.39),"START",{"action":"start_wash"},_wash_animation)
 if w.stage=="washed": _touch_prop(prop,Rect2(.23,.4,.55,.39),"HANDLE",{"action":"unload"},_washer)
 match w.stage:
  "inspect":
   _body("CAPACITY: 4 UNIFORMS\nTwo measured doses. Oil: hot wash. Blood: sanitize. Ordinary dirt: standard.",22)
   _action("Pull the hatch handle",{"action":"open_hatch"},_washer)
   _action("Lift the sorted bundle into the drum",{"action":"load_washer"},_washer)
  "prepare":
   _body("Detergent: %d / 2 doses\nSelected cycle: %s\nHatch: %s"%[int(w.doses),w.cycle.to_upper(),"OPEN" if w.hatch_open else "CLOSED"])
   if w.hatch_open: _action("Tip one measured dose into the drawer",{"action":"dose"},_washer)
   var row = HBoxContainer.new(); row.add_theme_constant_override("separation",8); sheet_body.add_child(row)
   for cycle in ["standard","hot","sanitize"]:
    var knob = _button(cycle.to_upper(),func(): _do({"action":"cycle","cycle":cycle},_washer)); knob.size_flags_horizontal = Control.SIZE_EXPAND_FILL; knob.add_theme_font_size_override("font_size",21); row.add_child(knob)
   if w.hatch_open: _action("Push the hatch shut",{"action":"close_hatch"},_washer)
   else: _action("Press the green start switch",{"action":"start_wash"},_wash_animation)
  "washed":
   _body("The drain knocks. The drum slows to a stop.")
   _action("Open the hatch and take out the wet bundle",{"action":"unload"},_washer)
  "wet": _body("Wet cloth drags at your wrists."); _action("Hang the bundle in the drying rack",{"action":"dry"},_washer)
  "dry": _body("Warm cloth. Four empty uniforms."); _action("Fold sleeves, body, then stack",{"action":"fold"},_outgoing)
  _: _body("The folded load belongs in the outgoing cart.")

func _wash_animation() -> void:
 _washer(); busy = true
 _body("The glass vibrates. Something metallic taps inside.",20)
 await get_tree().create_timer(1.2).timeout
 busy = false
 # A phone interruption leaves the persistent washed stage available on resume.
 if modal and is_instance_valid(modal): _washer()

func _outgoing() -> void:
 _sheet("OUTGOING TEXTILE CART")
 if Session.state.shift.is_empty(): _body("Empty. Every coat has gone back to somebody else."); return
 var w = Session.state.shift
 _prop("uniform",180,"FOLDED LOAD" if w.stage in ["folded","receipt"] else "AWAITING LOAD")
 if w.stage=="folded": _action("Place folded uniforms in the outgoing cart",{"action":"dispatch"},_outgoing)
 elif w.stage=="receipt": _action("Slide your timecard into the pay terminal",{"action":"settle_shift"})
 else: _body("Wet or unfolded uniforms are not accepted.")

func _lost_property() -> void:
 _sheet("LOST PROPERTY / MUNICIPAL CUSTODY")
 var returned = Session.state.items.filter(func(item): return item.owner=="lost_property")
 if returned.is_empty(): _body("An empty steel tray. Pockets are to be checked before washing.")
 for item in returned: _body(item.label+"\nReceipt: "+item.serial,21)

func _receipt(data: Dictionary) -> void:
 _sheet("SHIFT WAGE SLIP")
 _body("MUNICIPAL PAYROLL / DISTRICT IX\n"+Sim.catalog().jobs[data.job].name.to_upper(),22)
 _body("Gross:          %d CR\nCivic withholding:  %d CR\nPaid:           %d CR\n\nService quality:  %d%%"%[int(data.gross),int(data.withholding),int(data.net),int(data.quality)],27)
 _body("Civic balance: %d CR\nThe fractional tax assessment carries to the next wage slip."%int(Session.state.credits),20)
 for notice in pending_notices: _body(notice,22)
 pending_notices = []
 var button = _button("Fold the wage slip",func():
  _close_sheet()
  if not pending_notices.is_empty():
   var text = "\n\n".join(pending_notices); pending_notices = []; _message("CIVIC INSPECTION",text)
 ); sheet_body.add_child(button)

func _shop(kinds: Array) -> void:
 _sheet("RAINLINE KIOSK  /  %d CR"%int(Session.state.credits))
 for kind in kinds:
  var item = Sim.catalog().items[kind]
  _body(item.label.to_upper(),24); _prop(kind,110); _body(item.description,21)
  _action("Take "+item.label+" / %d CR"%int(item.price),{"action":"buy","kind":kind},_bag)

func _cleaning(id: String) -> void:
 if id=="exit": _travel("street"); return
 var s = Session.state
 _sheet("CIVIC ANNEX / "+id.to_upper())
 if s.shift.is_empty():
  _body("A mop, a cloth, a fresh bin bag. Three surfaces on the order.\n8 CR gross.")
  _action("Take the sanitation order from the clipboard",{"action":"begin_shift"}); return
 if id=="receipt":
  if s.shift.stage=="receipt": _action("Stamp the sanitation timecard",{"action":"settle_shift"})
  else: _body("The floor, desk and bin still need to be counted.")
 elif id=="supplies": _body("The bucket holds a mop, cloth and fresh bag."); _action("Take the workplace supplies",{"action":"clean","object":"supplies"})
 elif id=="desk":
  _body("There is a folded memorandum beside the ashtray.")
  _action("Inspect the forgotten paper",{"action":"clean","object":"inspect_desk"})
  _action("Wipe around the desk objects",{"action":"clean","object":"desk"})
 elif id=="floor": _body("Old muddy footprints. A darker stain beneath the chair."); _action("Push the mop across the floor",{"action":"clean","object":"floor"})
 elif id=="bin": _body("A heavy black bag. Something rattles inside."); _action("Tie off the bag and fit a fresh one",{"action":"clean","object":"bin"})

func _freight(id: String) -> void:
 if id=="exit": _travel("street"); return
 var s = Session.state
 _sheet("FREIGHT DEPOT / "+id.to_upper())
 if s.shift.is_empty():
  _prop("crate",180); _body("Four parcels. Three outgoing lanes.\n9 CR gross. Every seal is counted."); _action("Pull the freight manifest from its clip",{"action":"begin_shift"}); return
 var w = s.shift
 if id=="manifest":
  _body("IX freight manifest\n11 → BLOCK C\n12 → CLINIC\n13 → TEXTILES\n14 → CLINIC / damaged seal")
  _action("Compare and mark the manifest",{"action":"manifest"})
 elif id=="receipt":
  if w.stage=="receipt": _action("Stamp the freight timecard",{"action":"settle_shift"})
  else: _body("There are still parcels on the bench.")
 elif id.begins_with("lane_"):
  var destination = {"lane_a":"BLOCK C","lane_b":"CLINIC","lane_c":"TEXTILES"}[id]
  _body("Outgoing lane: "+destination)
  _action("Slide the inspected parcel into this lane",{"action":"route_crate","index":w.selected,"destination":destination})
 else:
  for n in range(w.crates.size()):
   var box = w.crates[n]
   if box.routed: continue
   var button = _button(box.serial+" / "+("label checked" if box.inspected else "unread label"),func(): _crate(n)); sheet_body.add_child(button)

func _crate(index: int) -> void:
 var box = Session.state.shift.crates[index]
 _sheet("PARCEL "+box.serial)
 _prop("crate",230)
 if not box.inspected: _action("Turn the crate and read its label",{"action":"inspect_crate","index":index},func(): _crate(index)); return
 _body("DESTINATION: "+box.destination+"\nSEAL: "+("DAMAGED" if box.damaged else "INTACT"),26)
 if box.damaged and not box.opened: _action("Lift the damaged lid and inspect contents",{"action":"open_crate","index":index})
 for destination in ["BLOCK C","CLINIC","TEXTILES"]: _action("Slide into "+destination+" lane",{"action":"route_crate","index":index,"destination":destination})

func _camp(id: String) -> void:
 var camp = Session.state.legal.camp
 _sheet("DETAINEE 91-447 / %d ORDERS REMAINING"%(3-int(camp.orders)))
 match id:
  "bunk": _body("The blanket smells of the last occupant."); _action("Lie down on the camp bunk",{"action":"camp_sleep"})
  "meal": _prop("stew",160); _body("Thin paste. Metal cup. No charge and no comfort."); _action("Eat the camp ration",{"action":"camp_meal"})
  "clerk":
   _body("Three production orders. No wages. Outside bills remain paused.")
   _action("Present the completed work orders",{"action":"camp_release"})
  "scrap":
   _body("Sort three pieces. Metal to the steel bin; fabric to the cloth bin.")
   for n in range(3):
    if n in camp.sorted: continue
    _body(["Bent steel plate","Oily uniform offcut","Copper pipe stub"][n],24)
    var row = HBoxContainer.new(); sheet_body.add_child(row)
    for bin in ["metal","fabric"]:
     var button = _button("▤ "+bin.to_upper(),func(): _do({"action":"camp_sort","index":n,"bin":bin},func(): _camp("scrap"))); button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(button)
   if camp.sorted.size()==3: _action("Push the sorted tray beneath the counter",{"action":"camp_order"},func(): _camp("scrap"))

func _settings() -> void:
 _sheet("PAUSE / LOCAL RESIDENCY")
 _body("Your life is saved after every action. Pausing or closing SCHISM freezes personal time.",21)
 for pair in [["sound","Machine soundscape"],["effects","Analog instability"],["hints","Object labels"]]:
  _action(pair[1]+" / "+("ON" if Session.state.settings[pair[0]] else "OFF"),{"action":"setting","key":pair[0],"value":not Session.state.settings[pair[0]]},_settings)
 _body("SCHISM 0.2 / District IX\nLocal single-player residency.\nNo account or connection needed.",19)
 var save = _button("Save and put the phone down",func(): Session.flush(); _close_sheet()); sheet_body.add_child(save)

func _notification(what: int) -> void:
 if audio and audio.is_node_ready():
  if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
   audio.ambient.stream_paused = true; audio.effects.stream_paused = true
  if what in [NOTIFICATION_APPLICATION_RESUMED,NOTIFICATION_APPLICATION_FOCUS_IN]:
   audio.ambient.stream_paused = false; audio.effects.stream_paused = false
 if what==NOTIFICATION_WM_GO_BACK_REQUEST:
  if not Session.state.identity.registered: return
  if modal and is_instance_valid(modal): _close_sheet()
  else: _settings()
