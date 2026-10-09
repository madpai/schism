extends SceneTree
const Sim = preload("res://src/simulation.gd")
var s: Dictionary
var failed = false

func act(c: Dictionary) -> void:
 var result = Sim.apply(s,c)
 if not result.ok:
  failed = true; printerr("FAIL BALANCE: %s: %s"%[c,result.error]); return
 s = result.state

func _initialize() -> void:
 s = Sim.initial()
 for c in [{"action":"register","name":"Ordinary Citizen"},{"action":"arrival"},{"action":"travel","to":"hall"},{"action":"travel","to":"street"},{"action":"travel","to":"bureau"},{"action":"ticket"},{"action":"show_id"},{"action":"apply_job","job":"laundry"},{"action":"travel","to":"street"}]: act(c)
 for shift in range(5):
  act({"action":"drink"})
  act({"action":"travel","to":"laundry"}); act({"action":"begin_shift"})
  var cycle = "standard"
  for n in range(4):
   act({"action":"inspect_uniform","index":n}); act({"action":"inspect_pocket","index":n})
   var u = s.shift.uniforms[n]
   if u.found!="": act({"action":"found_choice","id":u.found,"choice":"return"})
   if u.stain=="oil": cycle = "hot"
   if u.stain=="blood": cycle = "sanitize"
   act({"action":"sort_uniform","index":n,"bin":u.type})
  act({"action":"open_hatch"})
  for n in range(4): act({"action":"load_garment","index":n})
  for action in ["dose","dose"]: act({"action":action})
  act({"action":"cycle","cycle":cycle})
  for action in ["close_hatch","start_wash"]: act({"action":action})
  for n in range(4): act({"action":"unload_garment","index":n})
  act({"action":"dry"})
  for n in range(4):
   for step in range(1,Sim.fold_steps(s.shift.uniforms[n])+1): act({"action":"fold_garment","index":n,"step":step})
  for action in ["dispatch","settle_shift"]: act({"action":action})
  act({"action":"travel","to":"street"})
  var tax = int(Sim.tax_summary(s).total)
  if tax>0:
   act({"action":"travel","to":"bureau"}); act({"action":"pay_tax","amount":tax}); act({"action":"travel","to":"street"})
  act({"action":"drink"}); act({"action":"travel","to":"shop"})
  act({"action":"buy","kind":"bread"})
  var bread = s.items[-1].id; act({"action":"consume","id":bread})
  if shift==0: act({"action":"buy","kind":"soap"})
  if shift==4: act({"action":"buy","kind":"kettle"})
  act({"action":"travel","to":"street"}); act({"action":"travel","to":"hall"}); act({"action":"travel","to":"room"})
  act({"action":"wash"}); act({"action":"sleep"})
  if s.needs.health<90 or s.credits<0 or s.needs.energy<90:
   failed = true; printerr("FAIL BALANCE: ordinary legal survival became unrecoverable")
  if shift<4:
   act({"action":"travel","to":"hall"}); act({"action":"travel","to":"street"})
 var kettle = ""
 for item in s.items:
  if item.kind=="kettle" and item.owner=="player": kettle = item.id
 act({"action":"install","id":kettle})
 if not "kettle" in s.room_upgrades or s.jobs.laundry.shifts!=5 or s.credits!=1 or s.tax_paid!=4:
  failed = true; printerr("FAIL BALANCE: five legal shifts should fund food, soap, tax and an installed kettle with 1 CR remaining")
 if not failed: print("SCHISM balance: five ordinary shifts, five meals, soap, 4 CR tax, installed kettle, 1 CR saved; healthy and rested. No injected resources.")
 quit(1 if failed else 0)
