extends SceneTree
const Visual = preload("res://src/presentation.gd")
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

func paper_present(context: String) -> void:
 var paper = game.find_child("paperwork_art",true,false) as Control
 check(paper!=null,"physical clipboard is visible for "+context)
 if paper!=null:
  check(paper.get("artwork") is Texture2D,"clipboard raster loads for "+context)

func job_choice(id: String) -> CheckBox:
 return game.find_child("job_choice_"+id,true,false) as CheckBox

func select_job(id: String) -> void:
 var choice = job_choice(id)
 check(choice!=null,"vacancy checkbox exists for "+id)
 if choice==null: return
 choice.button_pressed = true
 await process_frame; await process_frame

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
 paper_present("residency registration")
 check(not quit_on_go_back,"Android Back is handled by the scene instead of quitting")
 var background = game.find_child("resident_background",true,false)
 check(background!=null and background.item_count==5,"five civilian histories appear on the residency paper")
 if background!=null: background.select(4)
 await click("Sign the residency")
 check(session.state.identity.registered,"registration real control commits")
 check(session.state.identity.background=="technical_apprentice" and session.state.items.size()==1 and session.state.items[0].metadata.background=="technical_apprentice","selected background and personal memento persist in authority")
 paper_present("arrival document")
 await click("Fold the paper")
 for target in ["hall","street","bureau"]:
  game._travel(target); await create_timer(.4).timeout
 await click_hotspot("ticket")
 await click("Put the paper down")
 await click_hotspot("clerk")
 await click("Slide your civic")
 paper_present("work authorization")
 for id in ["laundry","cleaning","freight"]:
  check(job_choice(id)!=null,"vacancy form lists "+id+" as a checkable field")
 var initial_job_state = session.state.duplicate(true)
 var sign_job = game.find_child("sign_job_authorization",true,false)
 check(sign_job!=null and sign_job.disabled,"unsigned work authorization requires a chosen vacancy")
 await select_job("cleaning")
 check(session.state==initial_job_state,"checking a vacancy does not spend time or change authority state")
 await select_job("laundry")
 check(job_choice("laundry").button_pressed and not job_choice("cleaning").button_pressed and not job_choice("freight").button_pressed,"vacancy form has exactly one checked field")
 check(session.state==initial_job_state,"changing a checked vacancy remains an unsaved local draft")
 game._close_sheet(); await process_frame; await process_frame
 check(session.state==initial_job_state,"closing an unsigned form does not assign employment")
 game._vacancies(); await process_frame; await process_frame
 check(game.find_child("sign_job_authorization",true,false).disabled,"reopened form needs a fresh deliberate choice")
 await select_job("laundry")
 sign_job = game.find_child("sign_job_authorization",true,false)
 check(not sign_job.disabled and sign_job.custom_minimum_size.y>=64,"signature target becomes touch sized after checking a vacancy")
 sign_job.pressed.emit()
 sign_job.pressed.emit() # The stale paper must not sign a second authorization.
 await process_frame; await process_frame
 check(session.state.employment=="laundry","signed job paper assigns native employment")
 check(int(session.state.revision)==int(initial_job_state.revision)+1,"repeated signature signal commits one authority transaction")
 paper_present("signed authorization")
 check(game.sheet_body.find_children("*","Label",true,false).any(func(label): return label.text.contains("SIGNED") and label.text.contains("Laundry")),"signed paper shows the authorized work")
 for target in ["street","laundry"]:
  game._travel(target); await create_timer(.4).timeout
 await click_hotspot("cart")
 await click("Pull the cart")
 check(session.state.shift.job=="laundry","incoming cart opens persistent job")
 check(Visual.laundry_state(session.state).remaining==4,"four garments visibly arrive")
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
 check(Visual.laundry_state(session.state).remaining==0,"all sorted garments empty the incoming cart")
 game._close_sheet()
 await click_hotspot("washer")
 await click("Pull the hatch")
 check(Visual.laundry_state(session.state).asset.ends_with("laundry-open-v2.png"),"opening the hatch changes the scene art")
 var cloth = game.find_child("cloth_load",true,false)
 await process_frame; await process_frame
 check(cloth!=null and cloth.size.x>=200 and cloth.size.y>=400,"physical loading surface is touch sized")
 if cloth!=null:
  check(cloth._card_rect(0).size.x>=64 and cloth._card_rect(0).size.y>=64 and cloth._target_rect().size.x>=64,"garment and drum have readable touch targets")
  var washer_scroll = game.find_child("sheet_scroll",true,false) as ScrollContainer
  var scroll_filter = washer_scroll.mouse_filter
  var scroll_deadzone = washer_scroll.scroll_deadzone
  var blank_touch = InputEventScreenTouch.new(); blank_touch.index = 0; blank_touch.pressed = true; blank_touch.position = Vector2(2,2)
  cloth._gui_input(blank_touch)
  check(washer_scroll.mouse_filter==scroll_filter and cloth.mouse_filter==Control.MOUSE_FILTER_PASS,"touching empty clothing space leaves normal sheet scrolling available")
  blank_touch.pressed = false; cloth._gui_input(blank_touch)
  var down = InputEventScreenTouch.new(); down.index = 0; down.pressed = true; down.position = cloth._card_rect(0).get_center()
  var drag = InputEventScreenDrag.new(); drag.index = 0; drag.position = cloth._target_rect().get_center()
  var up = InputEventScreenTouch.new(); up.index = 0; up.pressed = false; up.position = drag.position
  cloth._gui_input(down)
  check(washer_scroll.mouse_filter==Control.MOUSE_FILTER_IGNORE and washer_scroll.scroll_deadzone>1000000,"held garment prevents the sheet from interpreting the same drag as scrolling")
  cloth._gui_input(drag); cloth._gui_input(up)
  check(washer_scroll.mouse_filter==scroll_filter and washer_scroll.scroll_deadzone==scroll_deadzone,"releasing garment restores ordinary sheet scrolling")
  await process_frame; await process_frame
 check(session.state.shift.uniforms[0].loaded and session.state.shift.stage=="inspect","dragging first garment into drum commits only that garment")
 for index in range(1,4): await click("Load uniform %02d"%(index+1))
 check(session.state.shift.stage=="prepare" and session.state.shift.uniforms.all(func(g): return g.loaded),"four direct garment loads advance to machine controls")
 await click("Tip one")
 await click("Tip one")
 await click("STANDARD")
 await click("Push the hatch")
 await click("Press the green")
 check(Visual.laundry_state(session.state).running and Visual.laundry_state(session.state).asset.ends_with("laundry-running-v2.png"),"wash uses the running frame and animated glass")
 await create_timer(1.3).timeout
 for index in range(4): await click("Collect wet uniform %02d"%(index+1))
 check(session.state.shift.stage=="wet" and session.state.shift.uniforms.all(func(g): return g.unloaded),"four direct collections empty the washer")
 await click("Hang the bundle")
 check(Visual.laundry_state(session.state).asset.ends_with("laundry-open-v2.png"),"empty hatch remains open while cloth dries")
 var first_fold = session.state.shift.uniforms[0].folds
 var fold_surface = game.find_child("cloth_fold",true,false)
 check(fold_surface!=null,"folding cloth surface is present")
 if fold_surface!=null:
  check(fold_surface._region_rect().size.x>=64 and fold_surface._region_rect().size.y>=64,"marked fold region is touch sized")
  var fold_at = fold_surface._region_rect().get_center()
  var fold_down = InputEventScreenTouch.new(); fold_down.index = 0; fold_down.pressed = true; fold_down.position = fold_at
  var fold_up = InputEventScreenTouch.new(); fold_up.index = 0; fold_up.pressed = false; fold_up.position = fold_at
  fold_surface._gui_input(fold_down); fold_surface._gui_input(fold_up)
  await process_frame; await process_frame
 check(session.state.shift.uniforms[0].folds==first_fold+1,"touching marked cloth region saves one fold")
 for attempt in range(12):
  if session.state.shift.stage!="dry": break
  var next_fold_surface = game.find_child("cloth_fold",true,false)
  check(next_fold_surface!=null,"next fold surface remains available")
  if next_fold_surface==null: break
  await click(next_fold_surface.next_fold_text())
 check(session.state.shift.stage=="folded","folding sequence reaches outgoing cart")
 check(session.state.shift.uniforms.all(func(g): return int(g.folds)==Sim.fold_steps(g)),"all garments complete their type-specific folds")
 check(Visual.laundry_state(session.state).asset.ends_with("laundry-open-v2.png"),"folding cannot silently close the washer door")
 await click("Carry the stack")
 await click("Place folded")
 await click("Slide your timecard")
 check(session.state.credits==11 and session.state.shift.is_empty(),"native GUI shift settles once")
 if not session.state.shift.is_empty(): quit(1); return
 paper_present("wage receipt")
 await click("Fold the wage")
 await known_work_has_no_shortcuts()
 await click_hotspot("coworker")
 check(buttons().any(func(b): return b.text.begins_with("Help clear the station")),"postshift coworker offers a playable choice at the physical rota")
 await click("Help clear the station")
 check(session.state.city.flags.get("coworker_known",false) and session.state.items.any(func(item): return item.kind=="paste" and item.origin=="Coworker's spare ration"),"coworker choice saves a distinct ration")
 game._close_sheet()
 for target in ["street","hall"]: game._travel(target); await create_timer(.4).timeout
 await click_hotspot("neighbor")
 check(buttons().any(func(b): return b.text.begins_with("Carry the basket")),"hall neighbor offers help after first shift")
 await click("Carry the basket")
 check(session.state.city.flags.get("neighbor_known",false) and session.state.items.any(func(item): return item.kind=="soap" and item.origin=="Neighbor's spare supply"),"hall encounter saves its contact and physical reward")
 game._close_sheet()
 for target in ["street","service"]: game._travel(target); await create_timer(.4).timeout
 await click_hotspot("cabinet")
 check(buttons().any(func(b): return b.text.begins_with("Reseat the relay")),"service cabinet exposes a physical repair action")
 for resolution in [Vector2i(360,640),Vector2i(390,844),Vector2i(480,900)]:
  root.size = resolution; game.size = resolution
  await layout_check("service repair "+str(resolution))
 await click("Reseat the relay")
 check(session.state.city.flags.get("service_repaired",false) and session.state.items.any(func(item): return item.kind=="soap" and item.origin=="Maintenance cabinet spare supply"),"service repair persists and grants one supply")
 game._close_sheet()
 for resolution in [Vector2i(360,640),Vector2i(390,844),Vector2i(480,900)]:
  root.size = resolution
  game.size = resolution
  game._render_world()
  await process_frame; await process_frame
  for dock_name in ["status","bag","settings"]:
   var dock_control = game.find_child(dock_name,true,false)
   check(dock_control.global_position.y+dock_control.size.y<=game.size.y,"bottom controls stay fully visible at "+str(resolution))
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
  game._vacancies(); await layout_check("bureau "+str(resolution))
  paper_present("bureau "+str(resolution))
  for id in ["laundry","cleaning","freight"]:
   check(job_choice(id)!=null,"vacancy form retains "+id+" checkbox at "+str(resolution))
  check(game.find_child("sign_job_authorization",true,false)!=null,"vacancy form retains one signature control at "+str(resolution))
  game._registration(); await layout_check("registration "+str(resolution))
  paper_present("registration "+str(resolution))
  game._tenancy(); await layout_check("tenancy "+str(resolution))
  paper_present("tenancy "+str(resolution))
  game._settings(); await layout_check("settings "+str(resolution))
  game._bag(); await layout_check("empty bag "+str(resolution))
  game._close_sheet()
  session.state.location = "freight"; game._render_world(); await process_frame; await process_frame
  var timecard = game.find_children("hotspot_receipt","Button",true,false)[0]
  check(timecard.position.x+timecard.size.x<=timecard.get_parent().size.x,"edge timecard keeps its entire touch target on screen "+str(resolution))
  session.state.location = "laundry"
 session.state.location = "shop"; game._render_world(); game._shop(["bread"])
 await click("Take Wrapped black")
 await click("Look deeper")
 await click("Wrapped black")
 var bread_id = session.state.items[-1].id
 session.state.location = "room"; game._item_sheet(bread_id)
 await click("Place on the locker shelf")
 check(game._inventory().size()==4 and game._inventory().any(func(item): return item.kind=="note" and item.metadata.get("background","")=="technical_apprentice"),"stored food leaves the carried bag while earned items and memento remain")
 await click("Wrapped black")
 await click("Put it in your bag")
 check(game._inventory().size()==5,"locker food returns through a real contextual touch control")
 game.bag_page = 0
 game._bag(); await layout_check("memento, rewards and bread bag")
 await click("Look deeper")
 var physical_item = game.find_children("bag_item_"+bread_id,"Button",true,false)
 check(physical_item.size()==1,"actual bread instance appears inside the backpack")
 if not physical_item.is_empty(): physical_item[0].pressed.emit()
 await process_frame; await process_frame
 check(game.sheet_title.contains("BREAD"),"tapping the object inside the backpack opens its inspection")
 for kind in ["water","soap","tea","mug","paste","tape"]: Sim._item(session.state,kind,kind,"player","UI-only placement fixture",{})
 for resolution in [Vector2i(360,640),Vector2i(390,844),Vector2i(480,900)]:
  game.size = resolution; root.size = resolution; game._render_world(); game.bag_page = 0; game._bag(); await layout_check("populated bag "+str(resolution))
  var interior = game.find_child("backpack_interior",true,false)
  var objects = game.find_children("bag_item_*","Button",true,false)
  check(objects.size()==4,"backpack keeps four readable objects on a page "+str(resolution))
  for b in objects: check(b.size.x>=64 and b.size.y>=82 and interior.get_global_rect().encloses(b.get_global_rect()),"backpack object target stays inside its compartment "+str(resolution))
  await click("Look deeper")
  check(game.find_children("bag_item_*","Button",true,false).size()==4,"deeper pocket shows remaining real items "+str(resolution))
  await click("Look deeper")
  check(game.find_children("bag_item_*","Button",true,false).size()==3,"last pocket shows remaining real items "+str(resolution))
  await click("Previous pocket")
 game.audio.play("footsteps")
 check(game.audio.effects.volume_db<=-27,"travel contact is quieter than work controls")
 check(Visual.object_texture("uniform")!=null and Visual.object_texture("tape")!=null,"inspection objects use generated raster assets")
 await tax_ui_checks()
 game.queue_free(); await process_frame
 await create_timer(.15).timeout
 print("SCHISM UI: %d checks passed; %d failed."%[passed,failed])
 quit(1 if failed else 0)

func click_hotspot(id: String) -> void:
 var found = game.find_children("hotspot_"+id,"Button",true,false)
 check(not found.is_empty(),"world hotspot exists: "+id)
 if not found.is_empty(): found[0].pressed.emit()
 await process_frame; await process_frame

func layout_check(context: String) -> void:
 await process_frame; await process_frame; await process_frame
 var panel = game.find_child("sheet_panel",true,false)
 var scroll = game.find_child("sheet_scroll",true,false)
 var bounds = Rect2(Vector2.ZERO,game.size)
 check(bounds.encloses(panel.get_global_rect()),"sheet panel stays within the phone: "+context)
 check(panel.get_global_rect().encloses(scroll.get_global_rect()),"scroll viewport stays within the panel: "+context)
 check(game.sheet_body.size.x<=scroll.size.x+.5,"content never forces horizontal overflow: "+context)
 var close = game.find_child("close_sheet",true,false)
 check(bounds.encloses(close.get_global_rect()),"close target always stays onscreen: "+context)
 for b in game.sheet_body.find_children("*","Button",true,false):
  check(b.get_global_rect().position.x>=panel.get_global_rect().position.x and b.get_global_rect().end.x<=panel.get_global_rect().end.x,"button width fits: "+context+" / "+b.text)
 var paper = game.find_child("paperwork_art",true,false) as Control
 if paper!=null:
  check(paper.get("artwork") is Texture2D,"clipboard has loaded raster artwork: "+context)
  check(paper.get_theme_constant("margin_top")==int(paper.size.x*.29),"metal clip keeps width-based top space: "+context)
  check(paper.is_ancestor_of(game.sheet_body),"live writing sits on the physical paper: "+context)
  check(paper.get_global_rect().position.x>=scroll.get_global_rect().position.x-1 and paper.get_global_rect().end.x<=scroll.get_global_rect().end.x+1,"paper stays inside the horizontal scroll viewport: "+context)
  var writing = paper.get_global_rect().grow_individual(-paper.size.x*.06,0,-paper.size.x*.06,0)
  for label in game.sheet_body.find_children("*","Label",true,false):
   check(label.get_global_rect().position.x>=writing.position.x-1 and label.get_global_rect().end.x<=writing.end.x+1,"writing stays over parchment: "+context)
  for b in game.sheet_body.find_children("*","Button",true,false):
   check(b.get_global_rect().position.x>=writing.position.x-1 and b.get_global_rect().end.x<=writing.end.x+1,"paper touch control stays over parchment: "+context)

func known_work_has_no_shortcuts() -> void:
 var retained = session.state.duplicate(true)
 var fixture = retained.duplicate(true)
 fixture.location = "laundry"; fixture.jobs.laundry.shifts = 1
 Sim._begin_shift(fixture,"laundry")
 fixture.shift.hatch_open = true; fixture.shift.uniforms[0].sorted = true
 session.state = fixture; game._washer(); await process_frame; await process_frame
 check(not buttons().any(func(b): return b.text.begins_with("Familiar work")),"experienced worker has no bulk load control")
 check(buttons().any(func(b): return b.text.begins_with("Load uniform 01")),"experienced worker keeps individual load alternative")
 fixture.shift.stage = "washed"
 game._washer(); await process_frame; await process_frame
 check(not buttons().any(func(b): return b.text.begins_with("Familiar work")),"experienced worker has no bulk collection control")
 check(buttons().any(func(b): return b.text.begins_with("Collect wet uniform 01")),"experienced worker keeps individual collection alternative")
 fixture.shift.stage = "dry"
 game._washer(); await process_frame; await process_frame
 check(not buttons().any(func(b): return b.text.begins_with("Familiar work")),"experienced worker has no bulk folding control")
 check(game.find_child("cloth_fold",true,false)!=null and buttons().any(func(b): return b.text.begins_with("Fold the left sleeve")),"experienced worker still folds cloth manually")
 session.state = retained; game._close_sheet(); game._render_world(); await process_frame; await process_frame


func tax_ui_checks() -> void:
 # Isolated presentation fixtures exercise authority payment buttons and bounds;
 # these balances are not an ordinary-life economy claim.
 var retained = session.state.duplicate(true)
 session.state = Sim.initial(); session.state.identity.registered = true; session.state.arrival_seen = true
 session.state.location = "bureau"; session.state.ticket = true; session.state.id_shown = true
 session.state.taxes.due = 2; session.state.taxes.grace_due = 1; session.state.taxes.accrued = 1
 session.state.taxes.flagged = true
 game._render_world(); await process_frame; await process_frame
 await click_hotspot("tax")
 paper_present("bureau tax payment")
 check(game.sheet_title.contains("CIVIC TAX"),"physical bureau counter opens the payment slip")
 check(game.sheet_body.find_children("*","Label",true,false).any(func(label): return label.text.contains("One played day") and label.text.contains("until Day")),"payment slip shows one-day grace and an exact played deadline")
 check(game.find_child("tax_pay_full",true,false)!=null and game.find_child("tax_pay_partial",true,false)!=null,"counter offers full and affordable partial payments")
 var partial = game.find_child("tax_pay_partial",true,false)
 var revision = int(session.state.revision)
 partial.pressed.emit()
 partial.pressed.emit() # Old button retains the old revision until end-of-frame free.
 await process_frame; await process_frame
 check(session.state.credits==3 and Sim.tax_summary(session.state).total==2 and session.state.tax_paid==1,"duplicate stale partial-payment tap charges exactly once")
 check(int(session.state.revision)==revision+1,"stale payment button cannot create a second state revision")
 game._tax_counter(); await process_frame; await process_frame
 var full = game.find_child("tax_pay_full",true,false); full.pressed.emit()
 await process_frame; await process_frame
 check(session.state.credits==1 and Sim.tax_summary(session.state).total==0 and session.state.tax_paid==3,"full payment clears the remaining tax through authority")
 check(game.find_child("tax_pay_full",true,false)==null and game.sheet_body.find_children("*","Label",true,false).any(func(label): return label.text.contains("NO TAX DEBT")),"paid counter contains no redundant payment action")
 session.state.taxes.due = 5; session.state.taxes.grace_due = 3; session.state.taxes.accrued = 2
 session.state.taxes.flagged = true; session.state.credits = 2
 game._tax_counter(); await process_frame; await process_frame
 full = game.find_child("tax_pay_full",true,false)
 check(full.disabled,"unaffordable full tax payment is disabled")
 partial = game.find_child("tax_pay_partial",true,false)
 check(partial!=null and not partial.disabled and partial.text.contains("2 CR"),"short wallet offers its affordable whole-credit payment")
 var before = session.state.duplicate(true)
 full.pressed.emit(); await process_frame; await process_frame
 check(session.state==before,"authority rejects unaffordable payment even if disabled control signal is invoked")
 session.state.taxes.due = 123456; session.state.taxes.grace_due = 123456; session.state.taxes.accrued = 17
 session.state.credits = 9; session.state.taxes.flagged = false
 for resolution in [Vector2i(360,640),Vector2i(390,844),Vector2i(480,900)]:
  root.size = resolution; game.size = resolution; game._render_world(); game._tax_counter()
  await layout_check("long tax payment labels "+str(resolution))
  paper_present("tax payment "+str(resolution))
  for payment in game.find_children("tax_pay_*","Button",true,false):
   check(payment.custom_minimum_size.y>=64 and payment.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART,"tax action remains touch sized and wrapped "+str(resolution))
  game._receipt({"job":"laundry","gross":7,"net":7,"withholding":0,"tax_assessed":1,"quality":100})
  await layout_check("full wage and assessed tax "+str(resolution))
  paper_present("wage slip "+str(resolution))
  check(game.sheet_body.find_children("*","Label",true,false).any(func(label): return label.text.contains("Paid in full: 7 CR") and label.text.contains("Tax assessed: 1 CR")),"wage slip distinguishes full cash paid from unpaid assessed tax")
 session.state.location = "camp"
 session.state.legal.camp = {"active":true,"orders":3,"minimum_orders":3,"reason":"tax","sorted":[],"worked_off":3}
 session.state.taxes.due = 2; session.state.taxes.accrued = 0; session.state.taxes.grace_due = 0
 for resolution in [Vector2i(360,640),Vector2i(390,844),Vector2i(480,900)]:
  root.size = resolution; game.size = resolution; game._render_world(); game._camp("clerk")
  await layout_check("tax correction release "+str(resolution))
  paper_present("detention clerk "+str(resolution))
  check(game.find_child("camp_request_release",true,false).disabled,"three orders with unpaid tax keep release guarded "+str(resolution))
 game._camp("scrap"); await process_frame; await process_frame
 check(buttons().any(func(button): return button.text=="▤ METAL"),"additional tax work remains available after minimum three orders")
 session.state.taxes.due = 0; game._camp("clerk"); await process_frame; await process_frame
 check(not game.find_child("camp_request_release",true,false).disabled,"minimum work plus cleared debt opens tax release")
 session.state.legal.camp.reason = "crime"; session.state.taxes.due = 9
 game._camp("clerk"); await process_frame; await process_frame
 check(not game.find_child("camp_request_release",true,false).disabled,"crime-only intake retains its three-order release rule")
 game._camp("scrap"); await process_frame; await process_frame
 check(not buttons().any(func(button): return button.text=="▤ METAL"),"completed crime-only production does not invite unnecessary extra orders")
 session.state = retained; game._close_sheet(); game._render_world()
