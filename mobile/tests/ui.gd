extends SceneTree
const Sim = preload("res://src/simulation.gd")
var game
var session
var passed = 0
var failed = 0

func check(ok: bool,label: String) -> void:
 if ok: passed += 1
 else: failed += 1; printerr("FAIL UI: "+label)

func buttons() -> Array:
 return game.find_children("*","Button",true,false)

func click(prefix: String) -> void:
 var selected = buttons().filter(func(b): return b.text.begins_with(prefix))
 check(not selected.is_empty(),"control present: "+prefix)
 if selected.is_empty(): return
 selected[0].pressed.emit()
 await process_frame
 await process_frame

func _initialize() -> void:
 _run.call_deferred()

func _run() -> void:
 await process_frame
 session = root.get_node("Session")
 session.state = Sim.initial()
 game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
 await process_frame; await process_frame
 check(game.modal!=null,"arrival registration visible")
 check(not quit_on_go_back,"Android Back is handled by the scene instead of quitting")
 await click("Sign the residency")
 check(session.state.identity.registered,"registration real control commits")
 await click("Fold the paper")
 for target in ["hall","street","bureau"]:
  game._travel(target); await create_timer(.4).timeout
 await click_hotspot("ticket")
 await click("Put the paper down")
 await click_hotspot("clerk")
 await click("Slide your civic")
 check(buttons().any(func(b): return b.text.contains("Laundry")),"all three vacancy papers present")
 await click("Sign Municipal Laundry")
 check(session.state.employment=="laundry","job paper assigns native employment")
 for target in ["street","laundry"]:
  game._travel(target); await create_timer(.4).timeout
 await click_hotspot("cart")
 await click("Pull the cart")
 check(session.state.shift.job=="laundry","incoming cart opens persistent job")
 check(game.find_children("uniform_*","Button",true,false).all(func(b): return b.custom_minimum_size.y>=176 and b.get_child_count()>0),"cart contains large physical garment targets")
 for n in range(4):
  await click("UNIFORM %02d"%(n+1))
  await click("Unfold")
  await click("Turn out")
  if not session.state.shift.uniforms[n].found.is_empty():
   check(buttons().any(func(b): return b.text=="Put in your pocket"),"physical found object has contextual custody choices")
   await click("Place in Lost Property")
   await click_hotspot("cart")
   await click("UNIFORM %02d"%(n+1))
  await click("▤  "+session.state.shift.uniforms[n].type.to_upper())
 game._close_sheet()
 await click_hotspot("washer")
 await click("Pull the hatch")
 await click("Lift the sorted")
 await click("Tip one")
 await click("Tip one")
 await click("STANDARD")
 await click("Push the hatch")
 await click("Press the green")
 await create_timer(1.3).timeout
 await click("Open the hatch")
 await click("Hang the bundle")
 await click("Fold sleeves")
 await click("Place folded")
 await click("Slide your timecard")
 check(session.state.credits==11 and session.state.shift.is_empty(),"native GUI shift settles once")
 await click("Fold the wage")
 for resolution in [Vector2i(360,640),Vector2i(390,844),Vector2i(480,900)]:
  root.size = resolution
  game.size = resolution
  game._render_world()
  await process_frame; await process_frame
  for b in game.find_children("hotspot_*","Button",true,false):
   check(b.size.x>=64 and b.size.y>=64,"hotspot minimum at "+str(resolution))
   for hint in b.find_children("*","Label",true,false):
    check(hint.autowrap_mode==TextServer.AUTOWRAP_OFF and hint.size.y<40,"object hint stays horizontal at "+str(resolution))
  game._status(); await process_frame; await process_frame
  check(game.modal.size.x==game.size.x,"status fits phone width "+str(resolution))
  game._close_sheet()
  game._washer(); await process_frame; await process_frame
  check(game.sheet_body.size.x<=resolution.x,"machine overlay fits width "+str(resolution))
  game._close_sheet()
  session.state.location = "freight"; game._render_world(); await process_frame; await process_frame
  var timecard = game.find_children("hotspot_receipt","Button",true,false)[0]
  check(timecard.position.x+timecard.size.x<=timecard.get_parent().size.x,"edge timecard keeps its entire touch target on screen "+str(resolution))
  session.state.location = "laundry"
 session.state.location = "shop"; game._render_world(); game._shop(["bread"])
 await click("Take Wrapped black")
 await click("Wrapped black")
 session.state.location = "room"; game._item_sheet(session.state.items[-1].id)
 await click("Place on the locker shelf")
 check(game._inventory().is_empty(),"stored food leaves the carried bag")
 await click("Wrapped black")
 await click("Put it in your bag")
 check(game._inventory().size()==1,"locker food returns through a real contextual touch control")
 game.queue_free(); await process_frame
 await create_timer(.15).timeout
 print("SCHISM UI: %d checks passed; %d failed."%[passed,failed])
 quit(1 if failed else 0)

func click_hotspot(id: String) -> void:
 var found = game.find_children("hotspot_"+id,"Button",true,false)
 check(not found.is_empty(),"world hotspot exists: "+id)
 if not found.is_empty(): found[0].pressed.emit()
 await process_frame; await process_frame
