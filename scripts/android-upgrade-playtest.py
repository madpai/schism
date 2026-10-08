#!/usr/bin/env python3
"""Verify a real 0.3 (schema 4) to 0.4 (schema 6) Android upgrade.

Use an explicitly selected fresh emulator with no SCHISM installation or save.
The runner creates its own citizen through touch, installs over the old APK,
and never clears, injects, or exports a residency payload.
"""

import argparse
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time


ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--device', required=True, help='Fresh isolated emulator serial, such as emulator-5582')
parser.add_argument('--adb', default=os.environ.get('ADB', 'adb'))
parser.add_argument('--output', default='docs/playtests/android-upgrade-v040')
parser.add_argument('--previous-apk', default='builds/sideload/schism-0.3.0.apk')
parser.add_argument('--latest-apk', default='builds/schism-android-debug.apk')
args = parser.parse_args()
if not re.fullmatch(r'emulator-\d+', args.device):
    raise SystemExit('Use an explicitly selected fresh isolated emulator; physical devices are excluded.')

os.chdir(ROOT)  # The shared touch runner loads authored scene maps relative to the repository.
output = Path(args.output).resolve()
previous_apk = Path(args.previous_apk).resolve()
latest_apk = Path(args.latest_apk).resolve()
for path in (previous_apk, latest_apk):
    if not path.is_file() or not path.stat().st_size:
        raise SystemExit(f'APK missing or empty: {path}')
if previous_apk == latest_apk:
    raise SystemExit('Previous and latest APKs must be distinct artifacts.')
if output.exists() and any(output.iterdir()):
    raise SystemExit('Evidence directory already contains files. Select a new output directory.')

# The living-city runner exposes checked touch/OCR/state helpers behind its main guard.
# Supply this runner's arguments before import so the helper configures one device and
# writes only to this run's selected evidence directory.
helper_path = ROOT / 'scripts/android-living-playtest.py'
saved_argv = sys.argv
try:
    sys.argv = [str(helper_path), '--device', args.device, '--adb', args.adb,
                '--output', str(output)]
    spec = importlib.util.spec_from_file_location('schism_android_living_helpers', helper_path)
    qa = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(qa)
finally:
    sys.argv = saved_argv

PACKAGE = qa.PACKAGE
ADB = [args.adb, '-s', args.device]
assertions = []


def require(ok, label):
    qa.check(bool(ok), label)
    assertions.append(label)


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True,
                                     separators=(',', ':')).encode()).hexdigest()


def apk_digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def installed_apk_digest():
    package_path = qa.adb('shell', 'pm', 'path', PACKAGE)
    require(package_path.startswith('package:'), 'SCHISM package is installed')
    return qa.adb('shell', 'sha256sum', package_path.removeprefix('package:')).split()[0]


def verified_records():
    """Read verified private slot envelopes without writing their payload to evidence."""
    records = []
    for slot in range(2):
        result = subprocess.run(ADB + ['exec-out', 'run-as', PACKAGE, 'cat',
                                       f'files/residency/slot{slot}.json'], capture_output=True)
        if result.returncode:
            continue
        try:
            envelope = json.loads(result.stdout)
            payload = envelope['payload']
            if hashlib.sha256(payload.encode()).hexdigest() != envelope['sha256']:
                continue
            state = json.loads(payload)
            if state['revision'] != envelope['revision']:
                continue
            records.append({'slot': slot, 'payload_sha256': envelope['sha256'], 'state': state})
        except (KeyError, ValueError, TypeError):
            continue
    return records


def summary(record):
    state = record['state']
    return {'schema': state['schema'], 'revision': state['revision'],
            'sequence': state['sequence'], 'minute': state['minute'],
            'location': state['location'], 'credits': state['credits'],
            'needs_sha256': digest(state['needs']), 'items_count': len(state['items']),
            'items_sha256': digest(state['items']), 'shift_stage': state['shift'].get('stage'),
            'shift_sha256': digest(state['shift']),
            'payload_sha256': record['payload_sha256']}


def old_flow():
    qa.launch()
    require(qa.state()['schema'] == 4 and not qa.state()['identity']['registered'],
            '0.3 APK starts an unregistered schema 4 citizen')
    qa.shot('old-registration')
    qa.click('Sign the residency')
    qa.click('Fold the paper')
    qa.goto('shop')
    qa.hotspot('food')
    qa.click('Take Wrapped black')
    old_bread = next(item for item in qa.state()['items'] if item['kind'] == 'bread')
    require(old_bread['owner'] == 'player' and old_bread['storage'] == 'bag',
            'purchased bread remains a carried item')
    qa.goto('bureau')
    qa.hotspot('ticket')
    if any('put the paper' in line[0].lower() for line in qa.lines()):
        qa.click('Put the paper')
    qa.hotspot('clerk')
    qa.click('Slide your civic')
    qa.click('Sign Municipal Laundry')
    qa.goto('laundry')
    qa.hotspot('cart')
    qa.click('Pull the cart')
    qa.click('UNIFORM 01')
    qa.click('Unfold and read')
    state = qa.state()
    require(state['schema'] == 4 and state['shift']['stage'] == 'inspect'
            and state['shift']['uniforms'][0]['inspected']
            and not state['shift']['uniforms'][0]['pocket_checked']
            and all(not garment['inspected'] for garment in state['shift']['uniforms'][1:]),
            'old APK saves only the first uniform inspection in an active work order')
    qa.shot('old-partial-shift')
    return state, old_bread


def neutral_projection(new_state):
    projected = copy.deepcopy(new_state)
    projected.pop('schema')
    projected.pop('city')
    projected.pop('taxes')
    projected['identity'].pop('background')
    for garment in projected['shift']['uniforms']:
        for key in ('loaded', 'unloaded', 'folds'):
            garment.pop(key)
    return projected


def verify_upgrade(old, new, old_bread):
    require(old['schema'] == 4 and new['schema'] == 6,
            'actual persisted slot advances from schema 4 to schema 6')
    require(new['identity']['background'] == 'resident'
            and new['city'] == {'encounters': {}, 'flags': {}, 'security_favor': 0, 'supplies': {'metal': 0, 'fabric': 0}},
            'migration adds only neutral civilian background and empty city record')
    require(new['taxes']['accrued'] == 0 and new['taxes']['due'] == 0
            and new['taxes']['next_due'] == old['minute'] + 4320,
            'historical wages are not reassessed; first tax cycle starts at saved played time')
    require(all(garment['loaded'] is False and garment['unloaded'] is False
                and garment['folds'] == 0 for garment in new['shift']['uniforms']),
            'active inspection gains false/false/zero garment progress')
    prior = copy.deepcopy(old)
    prior.pop('schema')
    require(neutral_projection(new) == prior,
            'every prior payload field equals after removing only schema 6 defaults')
    bread = next(item for item in new['items'] if item['id'] == old_bread['id'])
    require(bread == old_bread and bread['owner'] == 'player' and bread['storage'] == 'bag',
            'bread identity, custody and all item metadata survive upgrade')
    require(all(new[key] == old[key] for key in ('minute', 'needs', 'credits',
                                               'revision', 'sequence')),
            'upgrade changes no played time, needs, money or command counters')


def run():
    # Require a truly fresh AVD. An existing installation could contain an
    # unreadable save, so checking only qa.state() would be unsafe.
    require(qa.adb('shell', 'pm', 'list', 'packages', PACKAGE) == '',
            'selected emulator has no SCHISM installation or prior residency files')
    require(qa.adb('shell', 'getprop', 'ro.kernel.qemu') == '1',
            'selected Android target identifies as an emulator')
    qa.adb('install', str(previous_apk))
    require(installed_apk_digest() == apk_digest(previous_apk),
            'installed 0.3 APK matches the selected old artifact byte for byte')
    old, old_bread = old_flow()
    old_records = verified_records()
    require(bool(old_records), 'old APK wrote a verified private save envelope')
    old_record = max(old_records, key=lambda record: record['state']['revision'])
    require(old_record['state'] == old, 'old saved payload equals visible active-shift state')

    qa.adb('shell', 'am', 'force-stop', PACKAGE)
    qa.adb('install', '-r', str(latest_apk))
    require(installed_apk_digest() == apk_digest(latest_apk),
            'installed 0.4 APK matches the selected latest artifact byte for byte')
    qa.launch()
    qa.adb('shell', 'input', 'keyevent', '3')  # Android Home triggers Session.flush.
    migrated = None
    for _ in range(20):
        matches = [record for record in verified_records()
                   if record['state'].get('schema') == 6
                   and record['state'].get('revision') == old['revision']]
        if matches:
            migrated = matches[0]
            break
        time.sleep(.25)
    require(migrated is not None, 'background pause wrote an actual verified schema 6 slot')
    verify_upgrade(old, migrated['state'], old_bread)
    qa.adb('shell', 'am', 'force-stop', PACKAGE)
    qa.launch()
    require(qa.state()['shift']['stage'] == 'inspect',
            'process death relaunch resumes the partially inspected work order')
    qa.hotspot('cart')
    qa.click('UNIFORM 01')
    qa.click('Turn out the')
    after = qa.state()
    require(after['shift']['uniforms'][0]['pocket_checked']
            and after['revision'] == old['revision'] + 1,
            'real pocket interaction commits once after migration')
    qa.shot('upgraded-first-uniform-pocket')
    require(next(item for item in after['items'] if item['id'] == old_bread['id']) == old_bread,
            'post-upgrade work does not alter the carried bread record')

    logs = qa.adb('logcat', '-d', '-s', 'godot', 'AndroidRuntime')
    require(not any(error in logs for error in ('SCRIPT ERROR', 'FATAL EXCEPTION',
                                                'Program linking failed')),
            'upgrade flow has no native script, Java or shader-link error')
    after_records = verified_records()
    after_record = max(after_records, key=lambda record: record['state']['revision'])
    evidence = {'device': args.device, 'package': PACKAGE,
                'previous_apk': os.path.relpath(previous_apk, ROOT),
                'previous_apk_sha256': apk_digest(previous_apk),
                'latest_apk': os.path.relpath(latest_apk, ROOT),
                'latest_apk_sha256': apk_digest(latest_apk),
                'old': summary(old_record), 'migrated': summary(migrated),
                'after_first_pocket': summary(after_record),
                'assertions': assertions, 'touches': qa.STEPS,
                'runtime_log_sha256': hashlib.sha256(logs.encode()).hexdigest(),
                'limits': 'Fresh emulator upgrade and touch evidence; no physical phone claim. No residency payload is written to evidence.'}
    (output / 'upgrade-evidence.json').write_text(json.dumps(evidence, indent=2)+'\n')
    print('ANDROID 0.3 TO 0.4 IN-PLACE UPGRADE PASSED', flush=True)


if __name__ == '__main__':
    try:
        run()
    except Exception as error:
        (output / 'failure.json').write_text(json.dumps(
            {'error': str(error), 'assertions': assertions, 'touches': qa.STEPS}, indent=2)+'\n')
        raise
    finally:
        (output / '.ocr-frame.png').unlink(missing_ok=True)
