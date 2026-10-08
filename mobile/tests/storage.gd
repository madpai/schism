extends SceneTree
const Sim = preload("res://src/simulation.gd")
const Store = preload("res://src/save_store.gd")
var passed = 0
var failed = 0

func check(ok: bool,label: String) -> void:
 if ok: passed += 1
 else: failed += 1; printerr("FAIL STORAGE: "+label)

func act(s: Dictionary,c: Dictionary) -> Dictionary:
 var result = Sim.apply(s,c); check(result.ok,"accepted "+str(c)); return result.state

func home() -> Dictionary:
 var s = Sim.initial(); s.identity.registered = true; s.arrival_seen = true; s.credits = 200
 for location in ["hall","street","shop"]: s = act(s,{"action":"travel","to":location})
 s = act(s,{"action":"buy","kind":"fridge"}); var cabinet = s.items[-1].id
 s = act(s,{"action":"buy","kind":"bread"})
 for location in ["street","hall","room"]: s = act(s,{"action":"travel","to":location})
 return act(s,{"action":"install","id":cabinet})

func _initialize() -> void:
 var s = home(); var id = s.items[-1].id; var serial = s.items[-1].serial
 var snapshot = s.duplicate(true)
 var denied = Sim.apply(s,{"action":"store_item","id":id,"storage":"unknown"})
 check(not denied.ok and s==snapshot,"invalid storage rejects without mutation")
 s = act(s,{"action":"store_item","id":id,"storage":"locker"})
 check(s.items[-1].owner=="player" and s.items[-1].serial==serial and s.items[-1].history[-1].storage=="locker","storage changes location, not identity or legal ownership")
 var away = act(s,{"action":"travel","to":"hall"})
 check(not Sim.apply(away,{"action":"consume","id":id}).ok,"cannot eat food left at home from another scene")
 check(not Sim.apply(away,{"action":"store_item","id":id,"storage":"bag"}).ok,"cannot teleport belongings into bag from outside")
 s = act(s,{"action":"store_item","id":id,"storage":"bag"})
 s = act(s,{"action":"store_item","id":id,"storage":"fridge"})
 Sim._advance(s,1440)
 check(s.items[-1].cold_minutes==1440,"actual powered refrigeration earns elapsed preservation time")
 s.housing.utilities = false; Sim._advance(s,1440)
 check(s.items[-1].cold_minutes==1440,"utility interruption adds no cold preservation")
 s = act(s,{"action":"store_item","id":id,"storage":"bag"})
 Sim._advance(s,1400)
 check(s.items[-1].cold_minutes==1440 and not Sim.is_spoiled(s.items[-1],int(s.minute)),"taking food out retains earned cooling but stops accruing more")
 Sim._advance(s,1500)
 check(Sim.is_spoiled(s.items[-1],int(s.minute)) and not Sim.apply(s,{"action":"consume","id":id}).ok,"food eventually spoils according to actual warm time")
 check(not Sim.apply(s,{"action":"store_item","id":id,"storage":"fridge"}).ok,"cannot resurrect spoiled food by refrigerating it")
 var fresh = home(); var fresh_id = fresh.items[-1].id
 fresh = act(fresh,{"action":"store_item","id":fresh_id,"storage":"fridge"})
 for n in range(3): Sim._advance(fresh,1440)
 check(fresh.items[-1].cold_minutes==4320 and not Sim.is_spoiled(fresh.items[-1],int(fresh.minute)),"refrigerator banks at most three extra played days")
 Sim._advance(fresh,4300); check(not Sim.is_spoiled(fresh.items[-1],int(fresh.minute)),"stored bread remains usable near its extended deadline")
 Sim._advance(fresh,30); check(Sim.is_spoiled(fresh.items[-1],int(fresh.minute)),"refrigeration is bounded, not unlimited food preservation")
 var bag = home(); var bag_id = bag.items[-1].id; Sim._advance(bag,5000)
 check(bag.items[-1].cold_minutes==0 and not Sim.apply(bag,{"action":"consume","id":bag_id}).ok,"owning an appliance never refrigerates carried food")
 var legacy = home(); legacy.schema = 3; legacy.minute += 5000
 legacy.items[-1].erase("storage"); legacy.items[-1].erase("cold_minutes"); legacy.items[-1].metadata.custom_owner_note = "Do not lose this"
 var migrated = Sim.migrate(legacy)
 check(migrated.schema==4 and migrated.items[-1].cold_minutes==4320 and migrated.items[-1].metadata.custom_owner_note=="Do not lose this","v3 upgrade preserves the old fridge allowance, identity and unknown metadata")
 check(Sim.apply(migrated,{"action":"consume","id":migrated.items[-1].id}).ok,"previously usable food remains usable after upgrade")
 check(Sim.migrate(migrated).items[-1].cold_minutes==4320,"migration cannot grant preservation twice")
 var sparse = Sim.migrate({"schema":3,"items":[{"id":"IX-48193-00100","serial":"R-00100","metadata":{}}]})
 check(sparse.serial==100,"migration recovers the item serial counter to avoid future duplicate identities")
 var no_fridge = home(); no_fridge.room_upgrades.erase("fridge")
 check(not Sim.apply(no_fridge,{"action":"store_item","id":no_fridge.items[-1].id,"storage":"fridge"}).ok,"uninstalled appliances provide no storage")
 no_fridge = act(no_fridge,{"action":"store_item","id":no_fridge.items[-1].id,"storage":"locker"})
 Sim._enter_camp(no_fridge,[])
 check(no_fridge.items[-1].owner=="player" and no_fridge.items[-1].storage=="locker","camp custody leaves household storage at home")
 check(not Sim.apply(no_fridge,{"action":"consume","id":no_fridge.items[-1].id}).ok,"detention cannot remotely access household food")
 var store = Store.new("user://storage-test-"+str(Time.get_ticks_usec()))
 check(store.save_state(migrated),"write migrated preservation and item location")
 var loaded = store.load_state()
 check(loaded.items[-1].storage=="bag" and loaded.items[-1].cold_minutes==4320,"save/load preserves storage and accrued cooling")
 var future = Sim.migrate({"schema":5})
 check(future.has("error"),"unsupported future storage records remain protected")
 print("SCHISM storage: %d checks passed; %d failed."%[passed,failed]); quit(1 if failed else 0)
