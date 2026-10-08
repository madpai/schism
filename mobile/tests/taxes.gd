extends SceneTree
const Sim = preload("res://src/simulation.gd")
const Store = preload("res://src/save_store.gd")
var passed = 0
var failed = 0
func check(ok: bool,label: String) -> void:
 if ok: passed += 1
 else: failed += 1; printerr("FAIL TAX: "+label)
func act(s: Dictionary,c: Dictionary) -> Dictionary:
 var result = Sim.apply(s,c); check(result.ok,"accepted "+str(c)); return result.state
func reject(s: Dictionary,c: Dictionary,label: String) -> void:
 var before = s.duplicate(true); var result = Sim.apply(s,c)
 check(not result.ok and result.state==before and s==before,label)
func citizen() -> Dictionary:
 var s = Sim.initial(); s.identity.registered = true; return s
func order(s: Dictionary) -> Dictionary:
 for i in range(3): s = act(s,{"action":"camp_sort","index":i,"bin":["metal","fabric","metal"][i]})
 return act(s,{"action":"camp_order"})
func _initialize() -> void:
 var s = citizen(); var rng = s.rng; s.taxes.accrued = 5
 Sim._advance(s,4319); check(s.taxes.accrued==5 and s.taxes.due==0,"no early three-day bill")
 Sim._advance(s,1); check(s.taxes.due==5 and s.taxes.grace_due==5 and not s.taxes.flagged,"bill enters one-day grace at exact boundary")
 Sim._advance(s,1439); check(not s.taxes.flagged,"grace remains until exact expiry")
 Sim._advance(s,1); check(s.taxes.flagged and s.taxes.grace_due==0,"debt flagged at grace expiry")
 s.location = "bureau"; s.credits = 20; s.taxes.accrued = 3
 s = act(s,{"action":"pay_tax","amount":2,"expected_revision":s.revision})
 check(s.taxes.due==3 and s.taxes.accrued==3 and s.tax_paid==2 and s.credits==18,"payment retires oldest overdue before accrued")
 reject(s,{"action":"pay_tax","amount":2,"expected_revision":s.revision-1},"stale partial payment cannot repeat")
 for invalid in [0,-1,0.5,"1",true,99]: reject(s,{"action":"pay_tax","amount":invalid},"invalid payment atomic "+str(invalid))
 s.taxes.grace_due = 2; s.taxes.flagged = true
 s = act(s,{"action":"pay_tax","amount":2})
 check(s.taxes.due==1 and s.taxes.grace_due==1 and s.taxes.accrued==3 and not s.taxes.flagged,"payment retires overdue then grace")
 s = act(s,{"action":"pay_tax","amount":2})
 check(s.taxes.due==0 and s.taxes.grace_due==0 and s.taxes.accrued==2,"payment retires grace before accrued")
 var empty = citizen(); Sim._advance(empty,14000)
 check(empty.taxes.due==0 and not empty.taxes.flagged and empty.taxes.next_due>empty.minute,"empty billing cycles advance without flag")
 empty.taxes.accrued = 1; check(not empty.taxes.flagged,"new accrual not overdue after empty cycles")
 var leap = citizen(); leap.taxes.accrued = 4; Sim._advance(leap,15000)
 check(leap.taxes.due==4 and leap.taxes.grace_due==0 and leap.taxes.flagged,"long advance expires older grace before later zero bills")
 check(leap.taxes.ledger[0].type=="bill" and leap.taxes.ledger[1].type=="grace_expired","chronological billing ledger")
 var work = citizen(); work.location = "freight"; work.employment = "freight"
 work.shift = {"id":"tax-test","job":"freight","stage":"receipt","minutes":240,"quality":100,"risks":[]}
 work = act(work,{"action":"settle_shift"})
 check(work.credits==13 and work.tax_paid==0 and work.taxes.accrued==1 and work.tax_remainder==8,"gross wages assessed with fractional carry without withholding")
 check(work.last_receipt.net==9 and work.last_receipt.withholding==0 and work.last_receipt.tax_assessed==1,"receipt distinguishes assessed and paid")
 reject(work,{"action":"settle_shift"},"wage and tax assessment once only")
 var legacy = citizen(); legacy.schema = 5; legacy.minute = 7000; legacy.tax_paid = 8; legacy.tax_remainder = 23; legacy.erase("taxes")
 legacy.last_receipt = {"withholding":1,"net":6}
 var migrated = Sim.migrate(legacy)
 check(migrated.schema==6 and migrated.taxes.due==0 and migrated.taxes.next_due==11320 and migrated.tax_paid==8 and migrated.tax_remainder==23,"migration grants no debt or refund and preserves old paid carry")
 check(migrated.last_receipt==legacy.last_receipt,"historical wage receipt untouched")
 for invalid in [{"due":-1},{"accrued":"1"},{"grace_due":1},{"flagged":true},{"worked_off":0.5},{"ledger":{}}]:
  var bad = citizen()
  for key in invalid: bad.taxes[key] = invalid[key]
  var before = bad.duplicate(true)
  check(Sim.migrate(bad).has("error") and bad==before,"malformed tax record preserved for recovery "+str(invalid))
 var detained = citizen(); detained.location = "hall"; detained.taxes.due = 5; detained.taxes.flagged = true
 var bag = Sim._item(detained,"note","Personal note","player","Home",{"unknown":{"keep":77}})
 var locker = Sim._item(detained,"soap","Soap","player","Home",{}); locker.storage = "locker"
 detained = act(detained,{"action":"travel","to":"street"})
 check(detained.location=="street" and not detained.legal.camp.get("active",false),"street warning leaves a direct payment opportunity")
 var office = act(detained,{"action":"travel","to":"bureau"})
 office.credits = 5; office = act(office,{"action":"pay_tax","amount":5})
 office = act(office,{"action":"travel","to":"street"})
 office = act(office,{"action":"travel","to":"hall"})
 check(office.location=="hall" and not office.taxes.flagged,"overdue office payment avoids compulsory work")
 detained = act(detained,{"action":"travel","to":"laundry"})
 check(detained.location=="camp" and detained.legal.camp.reason=="tax" and detained.legal.camp.debt_at_entry==5,"ignoring payment warning enforces overdue on next journey")
 check(detained.items[0].owner=="held" and detained.items[1].owner=="player","detention holds bag only")
 var camp_start = detained.minute; var due = detained.taxes.next_due; var wallet = detained.credits
 var snapshot = detained.duplicate(true); Sim._enter_camp(detained,[],"tax")
 check(detained==snapshot,"camp entry idempotent")
 reject(detained,{"action":"pay_tax","amount":1},"detention cannot access cash tax counter")
 for n in range(3): detained = order(detained)
 check(detained.taxes.due==2 and detained.city.supplies.metal==6 and detained.city.supplies.fabric==3,"three work orders supply city and retire three debt")
 reject(detained,{"action":"camp_release"},"debt beyond three requires more orders")
 reject(detained,{"action":"camp_order"},"empty work order cannot replay reward")
 for n in range(2): detained = order(detained)
 check(detained.credits==wallet and detained.tax_paid==0 and detained.taxes.worked_off==5 and detained.legal.camp.worked_off==5,"work-off creates no wages or cash tax payment")
 check(detained.taxes.next_due==due,"camp action time pauses tax clock")
 var duration = detained.minute-camp_start
 detained = act(detained,{"action":"camp_release"})
 check(detained.taxes.next_due==due+duration and detained.location=="room" and detained.items[0].owner=="player" and detained.items[0].metadata.unknown.keep==77,"release resumes deadline and preserves unknown custody metadata")
 reject(detained,{"action":"camp_release"},"release replay rejects")
 var guard = citizen(); guard.location = "service"; guard.city.security_favor = 1; guard.taxes.due = 2; guard.taxes.flagged = true
 guard.city.encounters.street_inspection = {"count":1,"last_day":0,"last_minute":350,"last_choice":"present"}
 check(Sim.available_encounters(guard).any(func(option): return option.id=="street_inspection"),"flagged inspection bypasses previous stamp cooldown")
 guard = act(guard,{"action":"event_choice","event":"street_inspection","choice":"favor"})
 check(guard.location=="camp" and guard.taxes.due==2,"security favor cannot evade tax enforcement")
 var midshift = citizen(); midshift.location = "laundry"; midshift.employment = "laundry"; midshift.taxes.accrued = 2
 midshift = act(midshift,{"action":"begin_shift"}); Sim._advance(midshift,6000)
 check(midshift.taxes.flagged and midshift.location=="laundry" and not midshift.shift.is_empty(),"tax clock flags debt without midshift detention")
 snapshot = midshift.duplicate(true); Sim._enter_camp(midshift,[],"tax")
 check(midshift==snapshot,"camp entry cannot interrupt active shift")
 var active_legacy = citizen(); Sim._enter_camp(active_legacy,[]); active_legacy.schema = 5; active_legacy.erase("taxes")
 Sim._advance(active_legacy,500); active_legacy.legal.camp.erase("tax_pause_started")
 migrated = Sim.migrate(active_legacy)
 check(migrated.legal.camp.tax_pause_started==migrated.minute and migrated.taxes.next_due==migrated.minute+4320,"legacy active detention pause begins at migration minute")
 check(s.rng==rng and detained.rng==rng and guard.rng==rng,"taxes and compulsory work use no random rolls")
 var short = citizen(); short.taxes.due = 1; short.taxes.flagged = true; Sim._enter_camp(short,[],"tax")
 short = order(short); reject(short,{"action":"camp_release"},"paid debt still requires minimum three work orders")
 short = order(short); short = order(short); short = act(short,{"action":"camp_release"})
 check(short.taxes.worked_off==1 and short.city.supplies.metal==6,"minimum sentence keeps working after debt retired")
 var mixed = citizen(); mixed.taxes.due = 1; mixed.taxes.flagged = true; Sim._enter_camp(mixed,[])
 check(mixed.legal.camp.reason=="mixed","crime detention includes overdue tax reason")
 var actual = citizen(); actual.taxes.accrued = 4; actual.items = [{"metadata":{"custom":"keep"},"owner":"player","kind":"note","id":"persisted"}]
 var store = Store.new("user://tax-test-"+str(Time.get_ticks_usec()))
 check(store.save_state(actual),"save outstanding accrual")
 actual = store.load_state(); Sim._advance(actual,5760)
 check(actual.taxes.flagged and actual.taxes.due==4,"float-restored tax clock bills and expires grace")
 actual.location = "bureau"; actual.credits = 10
 actual = act(actual,{"action":"pay_tax","amount":1})
 check(store.save_state(actual),"save partial payment")
 actual = store.load_state()
 check(actual.taxes.due==3 and actual.tax_paid==1 and actual.items[0].metadata.custom=="keep","reload retains debt payment and unknown metadata")
 actual = act(actual,{"action":"pay_tax","amount":3})
 check(not actual.taxes.flagged,"reloaded balance can be fully settled")
 var lost_city = citizen(); lost_city.city.erase("encounters")
 check(Sim.migrate(lost_city).has("error"),"schema6 missing encounter history blocks recovery")
 var lost_camp = citizen(); lost_camp.legal.erase("camp")
 check(Sim.migrate(lost_camp).has("error"),"schema6 missing detention blocks recovery")
 var missing = citizen(); missing.taxes.erase("due")
 check(Sim.migrate(missing).has("error"),"schema6 missing debt cannot default to zero")
 var malformed = citizen(); Sim._enter_camp(malformed,[]); malformed.legal.camp.sorted = [0,0]
 check(Sim.migrate(malformed).has("error"),"duplicate persisted scrap progress rejects")
 reject(short,{"action":"camp_sort","index":0,"bin":"metal"},"released camp cannot sort again")
 print("SCHISM taxes: %d checks passed; %d failed."%[passed,failed]); quit(1 if failed else 0)
