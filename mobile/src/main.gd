extends Control
const PaperDocument = preload("res://src/paper_document.gd")
var job_selection = ""

const Sim = preload("res://src/simulation.gd")
const Visual = preload("res://src/presentation.gd")
const Prop = preload("res://src/prop.gd")
const Atmosphere = preload("res://src/environment.gd")
const Sound = preload("res://src/audio.gd")
const ClothActivity = preload("res://src/cloth_activity.gd")
const WorkActivity = preload("res://src/work_activity.gd")
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
var sheet_title = ""
var sheet_style = ""
var bag_page = 0

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
 var laundry_visual = {}
 if location=="laundry":
  laundry_visual = Visual.laundry_state(s); path = laundry_visual.asset
 if ResourceLoader.exists(path): texture.texture = load(path)
 texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var material = ShaderMaterial.new(); material.shader = load("res://shaders/recovered.gdshader")
 if not s.settings.effects: material.set_shader_parameter("instability",0); material.set_shader_parameter("tracking",0)
 if location=="laundry":
  var art = Visual.data().laundry
  material.set_shader_parameter("full_cart",load(art.full)); material.set_shader_parameter("cart_remaining",laundry_visual.remaining)
  material.set_shader_parameter("cart_rect",Vector4(art.cart_rect[0],art.cart_rect[1],art.cart_rect[2],art.cart_rect[3]))
  material.set_shader_parameter("running",laundry_visual.running); material.set_shader_parameter("motion",1.0 if s.settings.effects else 0.0)
 texture.name = "scene_art"; texture.material = material; area.add_child(texture)
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
 var caption = _label(_context(s,data.subtitle),19); caption.modulate = MUTED; caption.custom_minimum_size.y = 31; caption.autowrap_mode = TextServer.AUTOWRAP_OFF; caption.clip_text = true; caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; bottom.add_child(caption)
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
 var b = Button.new(); b.text = text; b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; b.custom_minimum_size = Vector2(0,64); b.pressed.connect(callback)
 return b

func _sheet(title: String,style: String="") -> void:
 _close_sheet()
 sheet_title = title; sheet_style = style
 modal = Control.new(); modal.name = "interaction_sheet"; modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(modal)
 var shade = ColorRect.new(); shade.color = Color(0,0,0,.58); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal.add_child(shade)
 # Plain Panel cannot grow to the minimum width of a long button. Content scrolls inside it.
 var panel = Panel.new(); panel.name = "sheet_panel"; panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 panel.offset_left = 10; panel.offset_right = -10; panel.offset_top = maxf(92,size.y*.14); panel.offset_bottom = -12; modal.add_child(panel)
 panel.add_theme_stylebox_override("panel",_box(Color("111911"),Color("66634b"),1))
 var margin = MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,12)
 panel.add_child(margin)
 var outer = VBoxContainer.new(); outer.add_theme_constant_override("separation",10); margin.add_child(outer)
 var row = HBoxContainer.new(); outer.add_child(row)
 var heading = _label(title,24); heading.name = "sheet_heading"; heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(heading)
 var close = _button("×",_close_sheet); close.name = "close_sheet"; close.custom_minimum_size.x = 64; row.add_child(close)
 var scroll = ScrollContainer.new(); scroll.name = "sheet_scroll"; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; outer.add_child(scroll)
 sheet_body = VBoxContainer.new(); sheet_body.name = "sheet_body"; sheet_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sheet_body.add_theme_constant_override("separation",12); scroll.add_child(sheet_body)

func _paper_sheet(title: String) -> void:
 _sheet(title)
 var holder = sheet_body; holder.name = "paperwork_holder"
 var paper = PaperDocument.new(); paper.name = "paperwork_art"; holder.add_child(paper)
 var writing = VBoxContainer.new(); writing.name = "sheet_body"
 writing.size_flags_horizontal = Control.SIZE_EXPAND_FILL; writing.add_theme_constant_override("separation",12)
 paper.add_child(writing); sheet_body = writing

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
 if title.begins_with("CIVIC") or title.begins_with("MUNICIPAL") or title.begins_with("C-184"): _paper_sheet(title)
 else: _sheet(title)
 _body(text)
 var close = _button("Put the paper down",_close_sheet); sheet_body.add_child(close)

func _registration() -> void:
 _paper_sheet("TEMPORARY CIVIC RESIDENCY")
 modal.find_child("close_sheet",true,false).disabled = true
 _body("DISTRICT IX\nHousing: Block C / Room 17\nBalance: 4 CR\nEmployment: UNASSIGNED",25)
 _body("Name for the registry",19)
 var name_input = LineEdit.new(); name_input.name = "resident_name"; name_input.text = "William"; name_input.max_length = 24; name_input.custom_minimum_size.y = 64; sheet_body.add_child(name_input)
 _body("Portrait tint / registry photograph",19)
 var appearance = OptionButton.new(); appearance.name = "appearance_tint"; appearance.custom_minimum_size.y = 64; appearance.add_item("Olive / cropped hair"); appearance.add_item("Umber / cropped hair"); appearance.add_item("Sand / cropped hair"); sheet_body.add_child(appearance)
 _body("Previous occupation / civilian history",19)
 var background = OptionButton.new(); background.name = "resident_background"; background.custom_minimum_size.y = 64
 var origins = ["factory_laborer","displaced_resident","former_bureaucrat","street_survivor","technical_apprentice"]
 for origin in origins: background.add_item(Sim.BACKGROUNDS[origin].label)
 sheet_body.add_child(background)
 var history = _body(Sim.BACKGROUNDS[origins[0]].text,20)
 background.item_selected.connect(func(index): history.text = Sim.BACKGROUNDS[origins[index]].text)
 _body("This describes where you came from. Every occupation and opportunity remains open to every resident.",19)
 _body("The train has gone. They gave you a key.\n\nTap objects to live here. Your bag and civic papers stay within reach. Time passes when you act.")
 var submit = _button("Sign the residency paper",func(): _do({"action":"register","name":name_input.text,"appearance":["olive","umber","sand"][appearance.selected],"background":origins[background.selected]},_arrival)); submit.name = "register"; sheet_body.add_child(submit)

func _arrival() -> void:
 _paper_sheet("BLOCK C  /  ROOM 17")
 _body("One key. A bed. A sink that runs cold.\n\nYour civic paper says you are expected to support yourself.\n\nThe labor bureau is across the courtyard. A free public tap and emergency meal chit remain available when you're broke.")
 _action("Fold the paper. Look around.",{"action":"arrival"})

func _hotspot(id: String) -> void:
 var s = Session.state
 var encounters = {"guard":"street_inspection","neighbor":"neighbor_help","coworker":"coworker_cover","cabinet":"service_repair","relay":"relay_detail"}
 if encounters.has(id): _encounter(encounters[id]); return
 match s.location:
  "room":
   match id:
    "door": _travel("hall")
    "bed":
     _sheet("METAL BED"); _prop("bed",180); _body("A thin mattress. Industrial noise through the wall.\nEight hours of your time. No cost while the app is closed."); _action("Pull the blanket over you",{"action":"sleep"})
    "sink":
     _sheet("CHIPPED SINK"); _prop("sink",150); _body("Cold water. The pipes knock before it arrives."); _action("Cup your hands and drink",{"action":"drink"}); _action("Wash face and hands",{"action":"wash"})
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
      _paper_sheet("WINDOW 3 / CIVIC IDENTIFICATION"); _body('The clerk holds out a hand.\n\n“Identification.”'); _action("Slide your civic ID under the glass",{"action":"show_id"},_vacancies)
     else: _bureau_counter()
    "vacancies": _vacancies()
    "tax": _tax_counter()
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
  "service":
   if id=="exit": _travel("street")

func _encounter(id: String) -> void:
 var available = Sim.available_encounters(Session.state)
 var encounter = available.filter(func(entry): return entry.id==id)
 if encounter.is_empty():
  var descriptions = {
   "street_inspection":["SERVICE GATE / OFFICER","Your civic paper still carries the inspection stamp. The officer returns to watching the gate."],
   "neighbor_help":["BLOCK C / NEIGHBOR","An empty basket rests beside the neighbor's door. They nod if they recognize you."],
   "coworker_cover":["TEXTILE SERVICES / ROTA","The rota lists no extra station you can cover right now. Your own work authorization is still valid."],
   "service_repair":["SERVICE CABINET","The relay is seated, the lamps are steady, and the gate officer has logged your help. The repaired recording unit is beside the gate."],
   "relay_detail":["RESTORED RELAY","The recorder needs the service cabinet's power. Once repaired, you can hear its recovered recording immediately."]
  }
  if id=="relay_detail" and Session.state.city.flags.get("relay_heard",false): descriptions[id][1] = "You copied the return count onto a paper in your bag. The relay repeats the same damaged recording."
  var detail = descriptions[id]; _sheet(detail[0]); _prop("paper" if id in ["street_inspection","coworker_cover"] else "relay" if id=="relay_detail" else "cabinet" if id=="service_repair" else "water",160); _body(detail[1]); return
 var event = encounter[0]
 _sheet(event.title.to_upper())
 _prop("paper" if id in ["street_inspection","coworker_cover"] else "relay" if id=="relay_detail" else "cabinet" if id=="service_repair" else "water",160)
 _body(event.text)
 for choice in event.choices: _action(choice.label,{"action":"event_choice","event":event.id,"choice":choice.id})

func _travel(target: String) -> void:
 _close_sheet()
 if not Session.state.shift.is_empty(): _do({"action":"travel","to":target}); return
 busy = true
 var veil = ColorRect.new(); veil.color = Color(0,0,0,0); veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(veil)
 var tween = create_tween(); tween.tween_property(veil,"color:a",1.0,.14)
 await tween.finished
 busy = false; _do({"action":"travel","to":target})
 audio.travel(Session.state.location)
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
 var origin = Sim.BACKGROUNDS.get(s.identity.get("background","resident"),{})
 if not origin.is_empty(): _body("Civilian history: "+origin.label,20)
 _body("Security favors recorded: %d"%int(s.city.get("security_favor",0)),20)
 _body("Credits: %d CR\nEmployment: %s\nHousing: %s"%[int(s.credits),Sim.catalog().jobs.get(s.employment,{}).get("name","UNASSIGNED"),s.housing.address])
 if not s.employment.is_empty():
  var record = s.jobs[s.employment]; _body("Completed shifts: %d\nEmployer trust: %d\nWarnings: %d"%[int(record.shifts),int(record.trust),int(record.warnings)],20)
 if s.legal.offenses>0: _body("Civic record: %d inventory offenses"%int(s.legal.offenses),20)

func _inventory() -> Array:
 return Session.state.items.filter(func(item): return item.owner=="player" and item.get("storage","bag")=="bag")

func _bag() -> void:
 _sheet("YOUR BAG")
 _body("%d CR / Civic paper. Room key. Whatever else you kept."%int(Session.state.credits),19)
 var items = _inventory()
 bag_page = clampi(bag_page,0,maxi(0,int(ceil(items.size()/4.0))-1))
 var surface = Control.new(); surface.name = "backpack_interior"; surface.custom_minimum_size.y = 380; surface.clip_contents = true; sheet_body.add_child(surface)
 var lining = TextureRect.new(); lining.texture = load(Visual.data().backpack.asset); lining.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; lining.stretch_mode = TextureRect.STRETCH_SCALE; lining.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); lining.mouse_filter = Control.MOUSE_FILTER_IGNORE; surface.add_child(lining)
 for index in range(bag_page*4,mini(items.size(),bag_page*4+4)):
  var item = items[index]; var slot = index%4
  var card = _button("",func(): _item_sheet(item.id)); card.name = "bag_item_"+item.id
  card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
  card.anchor_left = .19+(slot%2)*.31; card.anchor_right = card.anchor_left+.30
  card.anchor_top = .25+int(slot/2)*.25; card.anchor_bottom = card.anchor_top+.24
  card.custom_minimum_size = Vector2(64,82)
  card.add_theme_stylebox_override("normal",StyleBoxEmpty.new()); card.add_theme_stylebox_override("hover",_box(Color(.65,.63,.4,.08),Color(.8,.8,.6,.3)))
  var object = Prop.new(); object.kind = item.kind; object.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); object.offset_bottom = -24; card.add_child(object)
  var name_tag = _label(item.label,16); name_tag.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); name_tag.offset_top = -28; name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE; name_tag.add_theme_color_override("font_shadow_color",Color.BLACK); name_tag.add_theme_constant_override("shadow_offset_y",2); card.add_child(name_tag)
  card.tooltip_text = item.label+" / "+item.serial; surface.add_child(card)
 if items.is_empty(): _body("The main compartment is empty. Just the paper and key in the side pocket.",20)
 else:
  _body("Tap an object to take a closer look.",18)
  # Readable tap alternatives do not require recognising an unfamiliar object silhouette.
  for index in range(bag_page*4,mini(items.size(),bag_page*4+4)):
   var item = items[index]; var label = _button(item.label+" / "+item.serial,func(): _item_sheet(item.id)); sheet_body.add_child(label)
 if items.size()>4:
  var pages = HBoxContainer.new(); sheet_body.add_child(pages)
  for direction in [-1,1]:
   var button = _button("Previous pocket" if direction<0 else "Look deeper",func(): bag_page += direction; _bag()); button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   button.disabled = bag_page+direction<0 or (bag_page+direction)*4>=items.size(); pages.add_child(button)

func _item_sheet(id: String) -> void:
 var item = Sim._find(Session.state,id)
 if item.kind=="note": _paper_sheet(item.label.to_upper())
 else: _sheet(item.label.to_upper()); _prop(item.kind,180)
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
 var button = Button.new(); button.text = label if Session.state.settings.hints else ""; button.add_theme_font_size_override("font_size",16)
 button.custom_minimum_size = Vector2(64,64)
 button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
 button.add_theme_stylebox_override("hover",_box(Color(.7,.7,.5,.04),Color(.7,.7,.5,.2)))
 button.add_theme_stylebox_override("pressed",_box(Color(.7,.7,.5,.12),ACCENT))
 button.add_theme_color_override("font_shadow_color",Color.BLACK); button.add_theme_constant_override("shadow_offset_y",2)
 # Zones are relative to the painted raster, including aspect-fit margins, not a vector silhouette.
 var fit = func():
  var art = prop.artwork_rect()
  button.position = art.position+zone.position*art.size
  button.size = Vector2(maxf(64,zone.size.x*art.size.x),maxf(64,zone.size.y*art.size.y))
  button.position.x = clampf(button.position.x,0,maxf(0,prop.size.x-button.size.x))
  button.position.y = clampf(button.position.y,0,maxf(0,prop.size.y-button.size.y))
 prop.resized.connect(fit); button.pressed.connect(func(): _do(cmd,next)); prop.add_child(button); fit.call_deferred()

func _possession(kind: String) -> void:
 if kind=="fridge": _storage("fridge"); return
 _sheet(kind.to_upper()+"  /  YOUR ROOM")
 _prop(kind,170); _body(Sim.catalog().items.get(kind,{}).get("description","It belongs here now."))
 if kind=="radio": _action("Fit the damaged tape",{"action":"play_tape"})
 if kind=="kettle":
  var tea = Sim._owned(Session.state,"tea")
  if not tea.is_empty(): _action("Boil water and make tea",{"action":"consume","id":tea.id})
  else: _body("A tin of tea from the kiosk would make an evening of it.")

func _played_date(minute: int) -> String:
 return "Day %d / %02d:%02d"%[int(minute/1440)+1,int(minute/60)%24,minute%60]

func _bureau_counter() -> void:
 _paper_sheet("WINDOW 3 / ADMINISTRATIVE COUNTER")
 _body("MUNICIPAL ADMINISTRATION / DISTRICT IX",20)
 _body('The clerk points to two stacks of papers. “Work authorization. Civic taxes.”',22)
 var work = _button("Read the work authorization papers",_vacancies); sheet_body.add_child(work)
 var tax = _button("Present tax payment slip at the counter",_tax_counter); tax.name = "open_tax_counter"; sheet_body.add_child(tax)

func _tax_counter() -> void:
 var s = Session.state; var taxes = s.taxes
 var accrued = int(taxes.accrued); var due = int(taxes.due); var total = accrued+due
 var overdue = maxi(0,due-int(taxes.grace_due))
 _paper_sheet("WINDOW 3 / CIVIC TAX PAYMENT")
 _body("ASSESSMENT / CIVIC NUMBER "+s.identity.civic_id,20)
 _body("Unpaid balance: %d CR\nInvoiced: %d CR\nNew assessments: %d CR\nOverdue: %d CR\nYour wallet: %d CR"%[total,due,accrued,overdue,int(s.credits)],24)
 if total==0:
  _body("PAID / NO TAX DEBT\nThe clerk stamps the slip. No payment is required.",22)
 else:
  if accrued>0: _body("Next assessment deadline: "+_played_date(int(taxes.next_due)),20)
  if int(taxes.grace_due)>0:
   _body("Invoice in grace: %d CR\nOne played day to pay, until %s."%[int(taxes.grace_due),_played_date(int(taxes.grace_until))],20)
  if taxes.flagged:
   _body("UNPAID / SECURITY RECORD FLAGGED\nProceed directly here after a street warning. Ignoring payment or a gate inspection leads to compulsory work. Clear the debt to remove the flag.",22)
  _body("Your wages are paid in full. Settle assessed tax at this counter. Deadlines follow your actions; closing the phone adds no debt.",20)
  var full = _action("Slide %d CR across the counter / pay the full unpaid tax balance"%total,{"action":"pay_tax","amount":total,"expected_revision":int(s.revision)},_tax_counter)
  full.name = "tax_pay_full"; full.disabled = int(s.credits)<total or not s.shift.is_empty()
  if int(s.credits)<total:
   _body("Not enough credits for full payment. The clerk accepts an affordable part of the balance.",20)
   if int(s.credits)>0:
    var part = _action("Slide %d CR across the counter / make an affordable partial tax payment"%int(s.credits),{"action":"pay_tax","amount":int(s.credits),"expected_revision":int(s.revision)},_tax_counter)
    part.name = "tax_pay_partial"; part.disabled = not s.shift.is_empty()
   else: _body("Your wallet is empty. Payment remains available when you have credits.",20)
  elif total>1:
   var part = _action("Place 1 CR on the payment slip / pay part of the unpaid tax balance",{"action":"pay_tax","amount":1,"expected_revision":int(s.revision)},_tax_counter)
   part.name = "tax_pay_partial"; part.disabled = not s.shift.is_empty()
  if not s.shift.is_empty(): _body("Finish your work order before making a tax payment.",20)
 if not taxes.ledger.is_empty():
  var entry = taxes.ledger.back()
  _body("LAST LEDGER STAMP\n%s / %d CR\n%s"%[str(entry.type).to_upper(),int(entry.amount),_played_date(int(entry.minute))],19)

func _form_check(marked: bool) -> Texture2D:
 var ink = Color("30291c")
 var image = Image.create(32,32,false,Image.FORMAT_RGBA8); image.fill(Color.TRANSPARENT)
 for side in [Rect2i(3,3,26,2),Rect2i(3,27,26,2),Rect2i(3,3,2,26),Rect2i(27,3,2,26)]: image.fill_rect(side,ink)
 if marked:
  for n in range(7): image.fill_rect(Rect2i(7+n,14+n,3,3),ink)
  for n in range(13): image.fill_rect(Rect2i(12+n,20-n,3,3),ink)
 return ImageTexture.create_from_image(image)

func _vacancies() -> void:
 job_selection = ""
 _paper_sheet("WINDOW 3 / WORK AUTHORIZATION")
 if not Session.state.id_shown:
  _body("The papers are behind glass. The clerk wants a ticket and your civic identification first."); return
 _body("MUNICIPAL LABOR ALLOCATION\nTEMPORARY PLACEMENT FORM",24)
 _body("Civic number: "+Session.state.identity.civic_id+"\nApplicant: "+Session.state.identity.name,20)
 _body("Mark one vacancy. Your selection is a draft until you sign the authorization.",20)
 for id in ["laundry","cleaning","freight"]:
  var job = Sim.catalog().jobs[id]
  var field = CheckBox.new(); field.name = "job_choice_"+id
  field.text = job.name+" / %d CR gross"%int(job.gross); field.custom_minimum_size.y = 64
  field.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  field.add_theme_icon_override("checked",_form_check(true)); field.add_theme_icon_override("unchecked",_form_check(false))
  field.toggled.connect(func(marked):
   job_selection = id if marked else ""
   for other in ["laundry","cleaning","freight"]:
    if other!=id: modal.find_child("job_choice_"+other,true,false).set_pressed_no_signal(false)
   var signature = modal.find_child("sign_job_authorization",true,false)
   signature.disabled = job_selection.is_empty() or not Session.state.shift.is_empty()
  )
  sheet_body.add_child(field); _body(job.description,19)
 _body("APPLICANT SIGNATURE\n________________________________",20)
 var revision = int(Session.state.revision)
 var submission = {"done":false}
 var sign = _button("Sign here / "+Session.state.identity.name,func():
  if job_selection.is_empty() or submission.done: return
  submission.done = true
  _do({"action":"apply_job","job":job_selection,"expected_revision":revision},_signed_authorization)
 )
 sign.name = "sign_job_authorization"; sign.disabled = true; sign.add_theme_font_override("font",human); sheet_body.add_child(sign)
 if not Session.state.employment.is_empty(): _body("Current authorization: "+Sim.catalog().jobs[Session.state.employment].name,19)
 if not Session.state.employment.is_empty() and Session.state.jobs[Session.state.employment].shifts>=12:
  _body("NOTICE OF INTERNAL VACANCY\n"+Sim.catalog().jobs[Session.state.employment].advanced+"\nTwelve completed shifts. One more credit. A supply key.")
  _action("Present your completed shift record",{"action":"promote"})
 var tax = _button("Present tax payment slip at the counter",_tax_counter); tax.name = "open_tax_counter"; sheet_body.add_child(tax)
 var tenancy = _button("Inspect the tenancy papers",_tenancy); sheet_body.add_child(tenancy)

func _signed_authorization() -> void:
 var s = Session.state
 _paper_sheet("SIGNED / WORK AUTHORIZATION")
 _body("MUNICIPAL LABOR ALLOCATION\nAUTHORIZED / "+Sim.catalog().jobs[s.employment].name,24)
 _body("Civic number: "+s.identity.civic_id,20)
 _body("SIGNED / "+s.identity.name+"\n"+Sim.catalog().jobs[s.employment].name,24)
 var signature = _body(s.identity.name,36); signature.name = "authorization_signature"; signature.add_theme_font_override("font",human)
 _body("The clerk countersigns the checked vacancy. Your work record and belongings stay with you.",20)
 var done = _button("Fold the authorization",_close_sheet); sheet_body.add_child(done)

func _tenancy() -> void:
 var h = Session.state.housing
 _paper_sheet("MUNICIPAL TENANCY RECORD")
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

func _cloth_activity(mode: String,index: int=0) -> Control:
 var activity = ClothActivity.new(); activity.name = "cloth_"+mode
 activity.mode = mode; activity.uniforms = Session.state.shift.uniforms.duplicate(true)
 activity.selected = index; activity.hatch_open = Session.state.shift.get("hatch_open",false)
 activity.custom_minimum_size = Vector2(0,284 if mode=="fold" else 416)
 activity.command_requested.connect(func(command): _do(command,_washer))
 sheet_body.add_child(activity); return activity

func _washer() -> void:
 var s = Session.state
 _sheet("INDUSTRIAL WASHER 03")
 if s.shift.is_empty():
  _prop("washer",270); _body("The machine is quiet. Today's uniforms are in the incoming cart."); return
 if s.shift.job!="laundry": _body("This machine needs a textile work order."); return
 var w = s.shift
 var tactile = w.stage in ["washed","dry"] or (w.stage=="inspect" and w.hatch_open)
 if not tactile:
  var prop = _prop("washer",270); prop.hatch_open = w.get("hatch_open",false); prop.active = w.stage=="washed"
  if w.stage=="inspect": _touch_prop(prop,Rect2(.42,.35,.52,.40),"HATCH",{"action":"open_hatch"},_washer)
  if w.stage=="prepare":
   if w.hatch_open: _touch_prop(prop,Rect2(.28,.025,.20,.20),"DOSE",{"action":"dose"},_washer)
   else: _touch_prop(prop,Rect2(.42,.35,.52,.40),"START",{"action":"start_wash"},_wash_animation)
 match w.stage:
  "inspect":
   if not w.hatch_open:
    _body("CAPACITY: 4 UNIFORMS\nTwo measured doses. Oil: hot wash. Blood: sanitize. Ordinary dirt: standard.",22)
    _action("Pull the hatch handle",{"action":"open_hatch"},_washer)
   else:
    _body("Lift each sorted garment from the basket into the open drum. Drag it, or tap its picture or label.",20)
    _cloth_activity("load")
    var loaded = 0
    for index in range(w.uniforms.size()):
     var garment = w.uniforms[index]
     if garment.get("loaded",false): loaded += 1; continue
     if garment.sorted: _action("Load uniform %02d / %s"%[index+1,garment.type],{"action":"load_garment","index":index},_washer)
    _body("%d / %d garments in the drum"%[loaded,w.uniforms.size()],20)
    if w.uniforms.any(func(garment): return not garment.sorted):
     var bench = _button("Return to the inspection bench",_cart); sheet_body.add_child(bench)
  "prepare":
   _body("Detergent: %d / 2 doses\nSelected cycle: %s\nHatch: %s"%[int(w.doses),w.cycle.to_upper(),"OPEN" if w.hatch_open else "CLOSED"])
   if w.hatch_open: _action("Tip one measured dose into the drawer",{"action":"dose"},_washer)
   var row = HBoxContainer.new(); row.add_theme_constant_override("separation",8); sheet_body.add_child(row)
   for cycle in ["standard","hot","sanitize"]:
    var knob = _button(cycle.to_upper(),func(): _do({"action":"cycle","cycle":cycle},_washer)); knob.size_flags_horizontal = Control.SIZE_EXPAND_FILL; knob.add_theme_font_size_override("font_size",21); row.add_child(knob)
   if w.hatch_open: _action("Push the hatch shut",{"action":"close_hatch"},_washer)
   else: _action("Press the green start switch",{"action":"start_wash"},_wash_animation)
  "washed":
   # Keep the established running shader visible until the short visual cycle finishes.
   var running = _prop("washer",230); running.active = not w.get("hatch_open",false); running.hatch_open = w.get("hatch_open",false)
   _body("The drain knocks. Lift the damp garments into the basket. Drag down, or tap each garment.",20)
   _cloth_activity("unload")
   for index in range(w.uniforms.size()):
    if not w.uniforms[index].get("unloaded",false): _action("Collect wet uniform %02d"%[index+1],{"action":"unload_garment","index":index},_washer)
  "wet":
   _body("Wet cloth drags at your wrists. Every garment is in the collection basket.")
   _prop("uniform",180,"CLEAN / DAMP")
   _action("Hang the bundle in the drying rack",{"action":"dry"},_washer)
  "dry":
   var next_index = -1; var complete = 0
   for index in range(w.uniforms.size()):
    var garment = w.uniforms[index]; var required = 2 if garment.type=="medical" else 3
    if int(garment.get("folds",0))>=required: complete += 1
    elif next_index<0: next_index = index
   _body("FOLDING BENCH / %d OF %d STACKED"%[complete,w.uniforms.size()],20)
   if complete>0: _prop("folded",90,"CLEAN / FOLDED")
   if next_index>=0:
    var garment = w.uniforms[next_index]
    _body("Uniform %02d / %s"%[next_index+1,str(garment.type).to_upper()],23)
    var activity = _cloth_activity("fold",next_index)
    _body("Tap the marked cloth region, or use the action below. Each fold stays saved.",20)
    _action(activity.next_fold_text(),{"action":"fold_garment","index":next_index,"step":int(garment.get("folds",0))+1},_washer)
  "folded":
   _prop("folded",180,"CLEAN / FOLDED")
   _body("Four uniforms stacked. The outgoing cart is waiting.")
   var outgoing = _button("Carry the stack to the outgoing cart",_outgoing); sheet_body.add_child(outgoing)
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
 _prop("folded",180,"FOLDED LOAD" if w.stage in ["folded","receipt"] else "AWAITING LOAD")
 if w.stage=="folded": _action("Place folded uniforms in the outgoing cart",{"action":"dispatch"},_outgoing)
 elif w.stage=="receipt": _action("Slide your timecard into the pay terminal",{"action":"settle_shift"})
 else: _body("Wet or unfolded uniforms are not accepted.")

func _lost_property() -> void:
 _paper_sheet("LOST PROPERTY / MUNICIPAL CUSTODY")
 var returned = Session.state.items.filter(func(item): return item.owner=="lost_property")
 if returned.is_empty(): _body("An empty steel tray. Pockets are to be checked before washing.")
 for item in returned: _body(item.label+"\nReceipt: "+item.serial,21)

func _receipt(data: Dictionary) -> void:
 _paper_sheet("SHIFT WAGE SLIP")
 _body("MUNICIPAL PAYROLL / DISTRICT IX\n"+Sim.catalog().jobs[data.job].name.to_upper(),22)
 _body("Gross: %d CR\nPaid in full: %d CR\nTax assessed: %d CR / unpaid\n\nService quality: %d%%"%[int(data.gross),int(data.net),int(data.get("tax_assessed",0)),int(data.quality)],27)
 var taxes = Session.state.taxes
 _body("Wallet: %d CR\nTotal unpaid tax: %d CR\nPresent your payment slip at Window 3 in the labor bureau. No tax is taken from your wage."%[int(Session.state.credits),int(taxes.due)+int(taxes.accrued)],20)
 _body("Next assessment deadline: "+_played_date(int(taxes.next_due))+". Each invoice allows one played day of grace.",20)
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

func _work_activity(kind: String,progress: int,next: Callable,crate: Dictionary={},index: int=0) -> Control:
 var activity = WorkActivity.new(); activity.name = "work_"+kind
 activity.work_kind = kind; activity.progress = progress; activity.crate = crate.duplicate(true)
 activity.index = index; activity.effects = Session.state.settings.effects
 activity.custom_minimum_size = Vector2(0,284)
 var revision = int(Session.state.revision)
 activity.command_requested.connect(func(command):
  command.expected_revision = revision
  _do(command,next)
 )
 sheet_body.add_child(activity)
 if activity.next_action()=="": return activity
 if activity.next_action()=="route_crate":
  var lanes = HBoxContainer.new(); lanes.add_theme_constant_override("separation",8); sheet_body.add_child(lanes)
  for destination in ["BLOCK C","CLINIC","TEXTILES"]:
   var button = _button(destination,func(): activity.perform_step(destination))
   button.name = "route_"+destination.replace(" ","_").to_lower()
   button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.custom_minimum_size.x = 0
   button.add_theme_font_size_override("font_size",18); lanes.add_child(button)
 else:
  var button = _button(activity.step_text(),func(): activity.perform_step())
  button.name = "work_step_alternative"; sheet_body.add_child(button)
 return activity

func _cleaning(id: String) -> void:
 if id=="exit": _travel("street"); return
 var s = Session.state
 _sheet("CIVIC ANNEX / "+id.to_upper())
 if s.shift.is_empty():
  _paper_sheet("CIVIC ANNEX / WORK ORDER")
  _body("A mop, a cloth, a fresh bin bag. Three surfaces on the order.\n8 CR gross.")
  _action("Take the sanitation order from the clipboard",{"action":"begin_shift"}); return
 if id=="receipt":
  _paper_sheet("CIVIC ANNEX / TIMECARD")
  if s.shift.stage=="receipt": _action("Stamp the sanitation timecard",{"action":"settle_shift"})
  else: _body("The floor, desk and bin still need to be counted.")
 elif id=="supplies":
  _prop("cleaning_supplies",180); _body("The bucket holds a mop, cloth and fresh bag.")
  if not s.shift.supplies: _action("Take the workplace supplies",{"action":"clean","object":"supplies"},func(): _cleaning("supplies"))
  else: _body("Mop, cloth and fresh bag collected. Take them to the floor, desk and bin.",20)
 elif id in ["floor","desk","bin"]:
  if not s.shift.supplies:
   _prop("cleaning_"+id,150); _body("Take the mop, cloth and fresh bag from the bucket first.")
   var supplies = _button("Reach into the supply bucket",func(): _cleaning("supplies")); sheet_body.add_child(supplies)
  else:
   _work_activity(id,int(s.shift.get("work_steps",{}).get(id,3 if id in s.shift.cleaned else 0)),func(): _cleaning(id))
  if id=="desk":
   if not s.shift.desk_checked:
    _body("A folded memorandum rests beside the ashtray.",20)
    _action("Inspect the forgotten paper",{"action":"clean","object":"inspect_desk"},func(): _cleaning("desk"))
   elif Sim._find(s,s.shift.found).get("owner","")=="found":
    var paper = _button("Look at the memorandum again",func(): _found(s.shift.found)); sheet_body.add_child(paper)

func _freight(id: String) -> void:
 if id=="exit": _travel("street"); return
 var s = Session.state
 _sheet("FREIGHT DEPOT / "+id.to_upper())
 if s.shift.is_empty():
  _prop("crate",180); _body("Four parcels. Three outgoing lanes.\n9 CR gross. Every seal is counted."); _action("Pull the freight manifest from its clip",{"action":"begin_shift"}); return
 var w = s.shift
 if id=="manifest":
  _paper_sheet("FREIGHT DEPOT / MANIFEST")
  _body("IX freight manifest\n11 → BLOCK C\n12 → CLINIC\n13 → TEXTILES\n14 → CLINIC / damaged seal")
  if not w.manifest_read: _action("Compare and mark the manifest",{"action":"manifest"},func(): _freight("manifest"))
  else: _body("The manifest is marked. Turn each parcel to check its own label.",20)
 elif id=="receipt":
  _paper_sheet("FREIGHT DEPOT / TIMECARD")
  if w.stage=="receipt": _action("Stamp the freight timecard",{"action":"settle_shift"})
  else: _body("There are still parcels on the bench.")
 elif id.begins_with("lane_"):
  var destination = {"lane_a":"BLOCK C","lane_b":"CLINIC","lane_c":"TEXTILES"}[id]
  # A lane opens the physical parcel; it never bypasses turning/lifting/stamping.
  var remaining = -1
  if int(w.selected)>=0 and int(w.selected)<w.crates.size() and not w.crates[int(w.selected)].routed: remaining = int(w.selected)
  else:
   for n in range(w.crates.size()):
    if not w.crates[n].routed: remaining = n; break
  if remaining>=0: _crate(remaining)
  else: _body("Outgoing lane: "+destination+"\nEvery parcel is sent. Collect the timecard.")
 else:
  for n in range(w.crates.size()):
   var box = w.crates[n]
   if box.routed: continue
   var button = _button(box.serial+" / "+("label checked" if box.inspected else "unread label"),func(): _crate(n)); sheet_body.add_child(button)

func _crate(index: int) -> void:
 var box = Session.state.shift.crates[index]
 _sheet("PARCEL "+box.serial)
 _work_activity("crate",0,func(): _crate(index),box,index)
 if not box.inspected: return
 _body("DESTINATION: "+box.destination+"  /  SEAL: "+("DAMAGED" if box.damaged else "INTACT"),20)
 if box.damaged and not box.opened and not box.routed:
  _action("Lift the damaged lid and inspect contents",{"action":"open_crate","index":index},func(): _crate(index))
 elif box.opened and Sim._find(Session.state,Session.state.shift.found).get("owner","")=="found":
  var found = _button("Look inside the opened parcel again",func(): _found(Session.state.shift.found)); sheet_body.add_child(found)

func _camp(id: String) -> void:
 var s = Session.state; var camp = s.legal.camp
 var minimum = int(camp.get("minimum_orders",3)); var reason = str(camp.get("reason","crime"))
 var debt = int(s.taxes.due)+int(s.taxes.accrued)
 var remaining = maxi(0,minimum-int(camp.orders))
 if id=="clerk": _paper_sheet("DETAINEE 91-447 / %d ORDERS REMAINING"%remaining)
 else: _sheet("DETAINEE 91-447 / %d ORDERS REMAINING"%remaining)
 _body("INTAKE: "+{"crime":"Inventory offenses","tax":"Unpaid civic tax","mixed":"Inventory offenses and unpaid civic tax"}.get(reason,reason),20)
 match id:
  "bunk": _prop("camp_bunk",170); _body("The blanket smells of the last occupant."); _action("Lie down on the camp bunk",{"action":"camp_sleep"})
  "meal": _prop("stew",160); _body("Thin paste. Metal cup. No charge and no comfort."); _action("Eat the camp ration",{"action":"camp_meal"})
  "clerk":
   _body("CORRECTION / WORK RECORD",20)
   _body("Orders counted: %d / %d minimum\nTax debt remaining: %d CR\nTax worked off here: %d CR"%[int(camp.orders),minimum,debt,int(camp.get("worked_off",0))],23)
   _body("Each completed order supplies the city with 2 metal pieces and 1 fabric piece. It earns no wages and works off up to 1 CR of tax debt. Outside bills and employment remain paused.",20)
   if reason in ["tax","mixed"]:
    _body("Release requires the minimum work orders AND no tax debt. Additional work orders remain available until the unpaid balance is cleared.",20)
   else: _body("Your inventory correction requires %d orders. Tax debt does not extend this intake."%minimum,20)
   var release = _action("Present the completed work orders / request release",{"action":"camp_release","expected_revision":int(s.revision)})
   release.name = "camp_request_release"; release.disabled = remaining>0 or (reason in ["tax","mixed"] and debt>0)
   if release.disabled: _body("The release window stays shut until the recorded requirements are met.",20)
  "scrap":
   _prop("scrap",150)
   _body("Sort three pieces. Metal to the steel bin; fabric to the cloth bin.")
   _body("CITY SUPPLIES: %d metal / %d fabric\nTax balance: %d CR / each counted order works off up to 1 CR."%[int(s.city.supplies.metal),int(s.city.supplies.fabric),debt],20)
   var finished = int(camp.orders)>=minimum and (reason=="crime" or debt==0)
   if finished:
    _body("The required production is counted. Present the work record at the release window.",20); return
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
 _body("SCHISM 0.5 / District IX\nLocal single-player residency.\nNo account or connection needed.",19)
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
