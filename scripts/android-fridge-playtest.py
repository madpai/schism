#!/usr/bin/env python3
"""Explicit, reversible Android QA fixture for expensive household storage."""
import sys,json,time,hashlib,subprocess,tempfile
from pathlib import Path
if '--allow-qa-fixture' not in sys.argv:
 raise SystemExit('Use a fresh isolated QA emulator and explicitly pass --allow-qa-fixture. This test temporarily seeds 200 CR; it restores both original save slots afterward.')
sys.argv.remove('--allow-qa-fixture')
if '--output' not in sys.argv:sys.argv.extend(['--output','docs/playtests/android-v020'])
root=Path(__file__).resolve().parents[1]
exec(compile((root/'scripts/android-playtest.py').read_text().split('installed_path=')[0],'qa-functions','exec'))
backups=[]
for slot in range(2):
 r=subprocess.run(ADB+['exec-out','run-as',PACKAGE,'cat',f'files/residency/slot{slot}.json'],capture_output=True)
 backups.append(r.stdout if r.returncode==0 else None)
if state() is None:raise SystemExit('First complete a QA citizen arrival in the isolated emulator.')
try:
 # Only the newly created, isolated QA emulator citizen receives this explicit test fixture.
 original=state();fixture=json.loads(json.dumps(original));fixture['credits']=200;fixture['location']='shop';fixture['revision']+=1
 payload=json.dumps(fixture,separators=(',',':'));envelope={'format':'schism-local-v1','revision':fixture['revision'],'payload':payload,'sha256':hashlib.sha256(payload.encode()).hexdigest()}
 file=Path('/tmp/schism-qa-fridge-fixture.json');file.write_text(json.dumps(envelope))
 adb('shell','am','force-stop',PACKAGE);adb('push',str(file),'/data/local/tmp/schism-qa-fridge-fixture.json');adb('shell','run-as',PACKAGE,'cp','/data/local/tmp/schism-qa-fridge-fixture.json','files/residency/slot0.json');launch();time.sleep(3)
 hotspot('goods');click('Take Refurbished cold');close();hotspot('food');click('Take Wrapped black');close()
 hotspot('exit');hotspot('hall');hotspot('room')
 adb('shell','input','tap','680','2314');time.sleep(.5);click('Refurbished cold');click('Place in your room');shot('room-with-fridge')
 # Tap the installed cabinet, rather than opening an appliance menu elsewhere.
 adb('shell','input','tap','723','1560');time.sleep(.5)
 click('Set down Wrapped black');shot('fridge-stored')
 bread=next(x for x in state()['items'] if x['kind']=='bread' and x['owner']=='player')
 check(bread['storage']=='fridge','installed cabinet touch stores the purchased food')
 close();hotspot('bed');click('Pull the blanket')
 check(next(x for x in state()['items'] if x['id']==bread['id'])['cold_minutes']==480,'sleep accrues only actual refrigerator preservation')
 interruption();adb('shell','input','tap','723','1560');time.sleep(.5);click('Wrapped black');shot('stored-food-inspection');click('Unwrap and eat')
 check(next(x for x in state()['items'] if x['id']==bread['id'])['owner']=='consumed','stored food can be eaten at home after interrupted play')
 (OUT/'fridge-evidence.json').write_text(json.dumps({'fixture':'Isolated QA citizen starts in shop with 200 CR; fixture used only to cover the 60 CR appliance without replaying many shifts. Purchases, installation, storage, sleep, interruption and consumption use real touch controls. This is not a balance or earned-progression claim.','steps':steps,'final_storage':next(x for x in state()['items'] if x['id']==bread['id'])},indent=2)+'\n')
 print('FRIDGE TOUCH FIXTURE PASSED',flush=True)
finally:
 adb('shell','am','force-stop',PACKAGE)
 with tempfile.TemporaryDirectory(prefix='schism-qa-restore-') as directory:
  for slot,data in enumerate(backups):
   destination=f'files/residency/slot{slot}.json'
   if data is None:adb('shell','run-as',PACKAGE,'rm','-f',destination);continue
   file=Path(directory)/f'slot{slot}.json';file.write_bytes(data)
   remote=f'/data/local/tmp/schism-qa-restore{slot}.json'
   adb('push',str(file),remote);adb('shell','run-as',PACKAGE,'cp',remote,destination);adb('shell','rm',remote)
 adb('shell','rm','/data/local/tmp/schism-qa-fridge-fixture.json')
 launch()
