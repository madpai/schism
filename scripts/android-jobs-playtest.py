#!/usr/bin/env python3
"""Tactile-job QA with real Android input and read-only verified-save assertions.

Use an explicitly selected fresh emulator. --resume reuses only this runner's
marked citizen; no reset, injected save or direct simulation command is used.
"""
import argparse
import csv
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from PIL import Image, ImageOps

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--device', required=True)
p.add_argument('--adb', required=True)
p.add_argument('--output', default='docs/playtests/android-v060')
p.add_argument('--resume', action='store_true')
a = p.parse_args()
if not re.fullmatch(r'emulator-\d+', a.device):
    raise SystemExit('Select an isolated emulator explicitly.')
original_args = sys.argv
sys.argv = ['android-living-playtest.py', '--device', a.device, '--adb', a.adb, '--output', a.output]
spec = importlib.util.spec_from_file_location('jobs_helpers', 'scripts/android-living-playtest.py')
q = importlib.util.module_from_spec(spec)
spec.loader.exec_module(q)
sys.argv = original_args
OUT = Path(a.output)
MARK = OUT/'qa-checkpoint.json'
APK_HASH = hashlib.sha256(Path('builds/schism-android-debug.apk').read_bytes()).hexdigest()
PRIOR_ATTEMPTS = []
if MARK.exists():
    if not a.resume:
        raise SystemExit('Marked citizen exists; use --resume, never reset.')
    mark = json.loads(MARK.read_text())
    if mark['identity_sha256'] != q.identity_hash():
        raise SystemExit('The QA citizen does not match this runner.')
    q.DONE = mark['done']
    if (OUT/'touch-evidence.json').exists():
        previous = json.loads((OUT/'touch-evidence.json').read_text())
        q.STEPS = previous['steps']
        PRIOR_ATTEMPTS = previous.get('prior_attempts', [])
        PRIOR_ATTEMPTS.append({'status': previous['status'], 'apk_sha256': previous['apk_sha256'],
                               'error': previous.get('error')})
elif q.state() and q.state()['identity']['registered']:
    raise SystemExit('Refusing to reuse an unmarked registered citizen.')


def evidence(status, error=None):
    s = q.state()
    receipt = {'status': status, 'version': '0.6.0', 'package': q.PACKAGE,
               'apk_sha256': APK_HASH, 'device': a.device, 'done': q.DONE, 'steps': q.STEPS,
               'prior_attempts': PRIOR_ATTEMPTS,
               'limits': 'Android14 swangle emulator only; no physical-phone comfort/audio/GPU claim.',
               'final': {key: s[key] for key in ('schema', 'revision', 'minute', 'credits', 'employment', 'tax_paid', 'last_receipt')} if s else {},
               'shifts': {key: s['jobs'][key]['shifts'] for key in ('laundry', 'cleaning', 'freight')} if s else {}}
    if error:
        receipt['error'] = str(error)
    (OUT/'touch-evidence.json').write_text(json.dumps(receipt, indent=2)+'\n')


original_lines = q.lines
def lines(mode=3):
    entries = original_lines(mode)
    frame = Image.open(q.shot()).convert('L')
    target = OUT/'.ocr-readable.png'
    ImageOps.invert(frame).resize((frame.width*2, frame.height*2)).save(target)
    result = subprocess.run(['tesseract', str(target), 'stdout', '--psm', str(mode), 'tsv'],
                            capture_output=True, text=True, check=True,
                            env={**os.environ, 'OMP_THREAD_LIMIT': '1'})
    groups = {}
    for row in csv.DictReader(io.StringIO(result.stdout), delimiter='\t', quoting=csv.QUOTE_NONE):
        if row.get('text', '').strip():
            for key in ('left', 'top', 'width', 'height'):
                row[key] = str(int(row[key])//2)
            groups.setdefault((row['block_num'], row['par_num'], row['line_num']), []).append(row)
    for words in groups.values():
        left = min(int(w['left']) for w in words); right = max(int(w['left'])+int(w['width']) for w in words)
        top = min(int(w['top']) for w in words); bottom = max(int(w['top'])+int(w['height']) for w in words)
        entries.append((' '.join(w['text'] for w in words), (left+right)//2, (top+bottom)//2, words))
    return entries
q.lines = lines


def goto(target):
    q.close()
    for attempt in range(10):
        location = q.state()['location']
        if location == target:
            return
        if location == 'room':
            q.hotspot('door')
        elif location == 'hall':
            q.hotspot('room' if target == 'room' else 'stairs')
        elif location == 'street':
            q.hotspot('hall' if target in ('room', 'hall') else target)
        else:
            q.hotspot('exit')
    raise AssertionError('Navigation did not reach '+target)
q.goto = goto


def phase(name):
    q.checkpoint(name)
    evidence('running')


def work_button(text, instruction, lane=None):
    # Project the layout verified by tactile_ui.gd into Android pixels. Tall
    # and short phones use different expand scales; short serif labels can
    # disappear from OCR even when the native control is visibly present.
    width, height = q.dimensions()
    scale = min(width/480, height/900)
    panel_top = max(92*scale, height*.14)
    point = (int(width*(.20, .50, .80)[lane]) if lane is not None else width//2,
             int(panel_top+(12+64+10+284+12+32)*scale))
    before = q.state()
    q.tap(*point)
    q.STEPS.append({'touch': text, 'point': list(point), 'instruction': instruction,
                    'located_by': 'native alternative layout verified at three sizes'})
    q.check(q.state()['revision'] == before['revision']+1, text+' alternative saves exactly one action')


def open_parcel(index):
    q.close()
    width, height = q.dimensions(); scale = min(width/480, height/900)
    point = (int(width*(.30+.175*index)), int(100*scale+.515*(height-222*scale)))
    before = q.state()
    q.tap(*point)
    q.STEPS.append({'parcel': before['shift']['crates'][index]['serial'], 'point': list(point),
                    'located_by': 'individual scene crate target'})
    q.check(q.state() == before, 'opening physical parcel is transaction free')


def apply(job):
    q.goto('bureau')
    if not q.state()['ticket']:
        q.hotspot('ticket'); q.click('Put the paper')
    if not q.state()['id_shown']:
        q.hotspot('clerk'); q.click('Slide your civic')
    else:
        q.hotspot('vacancies')
    q.click({'cleaning': 'Civic Sanitation Worker', 'freight': 'Freight Sorter'}[job])
    q.click('Sign here'); q.click('Fold the authorization')
    q.check(q.state()['employment'] == job, job+' authorization signed through physical paperwork')
    q.goto(job)


def measure_drag(label, gesture, before_field, after_field):
    width, height = q.dimensions(); scale = min(width/480, height/900)
    top = max(92*scale, height*.14)+(12+64+10)*scale
    if label == 'floor':
        band = q.state()['shift']['work_steps']['floor']
        start = (int(width*.30), int(top+(49+75*band)*scale)); end = (int(width*.66), start[1])
    elif label == 'crate-lift':
        start = (width//2, int(top+152*scale)); end = (width//2, int(top+66*scale))
    else:
        start = (width//2, int(top+90*scale)); end = (int(width*.20), int(top+202*scale))
    before = q.state()
    q.shot(label+'-drag-before')
    child = subprocess.Popen(q.ADB+['shell', 'input', 'swipe', *map(str, (*start, *end)), '1800'],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(.55); q.shot(label+'-drag-mid')
    _, stderr = child.communicate(timeout=10)
    if child.returncode:
        raise AssertionError(stderr.decode())
    time.sleep(.8)
    after = q.state()
    q.check(before_field(before) and after_field(after) and after['revision'] == before['revision']+1,
            label+' real drag commits exactly one saved step')
    q.STEPS.append({'measurement': label+' actual1800ms Android swipe', 'instruction': gesture,
                    'from': start, 'to': end})
    q.shot(label+'-drag-after')
    evidence('running')


def cleaning():
    if not q.state()['shift']:
        apply('cleaning'); q.hotspot('supplies'); q.click('Take the sanitation order')
    if not q.state()['shift']['supplies']:
        q.hotspot('supplies'); q.click('Take the workplace supplies')
    q.close(); q.hotspot('floor')
    if q.state()['shift']['work_steps']['floor'] < 3 and 'floor-final-drag' not in q.DONE:
        band = q.state()['shift']['work_steps']['floor']
        measure_drag('floor', 'SWIPE ACROSS',
                     lambda s: s['shift']['work_steps']['floor'] == band,
                     lambda s: s['shift']['work_steps']['floor'] == band+1)
        phase('floor-final-drag')
    if 'cleaning-partial' not in q.DONE:
        q.interruption('cleaning-partial'); phase('cleaning-partial')
    if 'cleaning-sizes' not in q.DONE:
        q.capture_sizes('cleaning-floor', 'floor'); phase('cleaning-sizes')
    for surface in ('floor', 'desk', 'bin'):
        q.close(); q.hotspot(surface)
        if surface == 'desk' and not q.state()['shift']['desk_checked']:
            q.click('Inspect the forgotten paper'); q.shot('desk-memorandum')
            q.click('Place in Lost Property'); q.close(); q.hotspot(surface)
        while q.state()['shift']['work_steps'][surface] < 3:
            progress = int(q.state()['shift']['work_steps'][surface])
            text = (f'Mop muddy band {progress+1}' if surface == 'floor' else
                    f'Wipe dirty patch {progress+1}' if surface == 'desk' else
                    ('Tie the bag closed', 'Lift the heavy bag out', 'Fit a fresh bag')[progress])
            if surface == 'bin':
                work_button(text, ('OUTLINED AREA', 'PULL UPWARD', 'PUSH DOWNWARD')[progress])
            else:
                q.click(text)
        q.shot(surface+'-finished')
    q.close(); q.hotspot('receipt')
    before = q.state()
    q.check(before['shift']['stage'] == 'receipt' and before['shift']['minutes'] == 240,
            'nine cleaning actions retain original240-minute work duration')
    q.click('Stamp the sanitation timecard'); q.shot('cleaning-wage')
    after = q.state()
    q.check(after['credits'] == before['credits']+8 and after['jobs']['cleaning']['shifts'] == 1,
            'cleaning pays8CR exactly once')
    q.interruption('cleaning-paid'); phase('cleaning')


def freight():
    if not q.state()['shift']:
        apply('freight'); q.hotspot('manifest'); q.click('Pull the freight manifest')
    if not q.state()['shift']['manifest_read']:
        q.hotspot('manifest'); q.click('Compare and mark')
    for index in range(4):
        if q.state()['shift']['crates'][index]['routed']:
            continue
        open_parcel(index)
        if not q.state()['shift']['crates'][index]['inspected']:
            work_button('Turn the crate', 'OUTLINED AREA')
        if index == 3 and not q.state()['shift']['crates'][index]['opened']:
            q.click('Lift the damaged lid'); q.shot('damaged-parcel')
            q.click('Place in Lost Property'); open_parcel(index)
        if not q.state()['shift']['crates'][index]['lifted']:
            if index == 0:
                measure_drag('crate-lift', 'PULL UPWARD',
                             lambda s: not s['shift']['crates'][0]['lifted'],
                             lambda s: s['shift']['crates'][0]['lifted'])
            else:
                work_button('Lift the crate onto the trolley', 'PULL UPWARD')
        if index == 0 and 'freight-partial' not in q.DONE:
            q.interruption('freight-partial'); phase('freight-partial')
            open_parcel(index)
        if not q.state()['shift']['crates'][index]['stamped']:
            work_button('Press the checked-seal stamp', 'PUSH DOWNWARD')
        if index == 0:
            measure_drag('crate-route', 'DRAG CRATE TO A LANE',
                         lambda s: not s['shift']['crates'][0]['routed'],
                         lambda s: s['shift']['crates'][0]['routed'])
        else:
            destination = q.state()['shift']['crates'][index]['destination']
            work_button('Route into '+destination, 'DRAG CRATE TO A LANE',
                        ('BLOCK C', 'CLINIC', 'TEXTILES').index(destination))
        q.close()
    q.hotspot('receipt'); before = q.state()
    q.check(before['shift']['minutes'] == 240 and before['shift']['quality'] == 100,
            'four hand-prepared parcels retain original duration and perfect quality')
    q.click('Stamp the freight timecard'); q.shot('freight-wage')
    after = q.state()
    q.check(after['credits'] == before['credits']+9 and after['jobs']['freight']['shifts'] == 1,
            'freight pays9CR exactly once')
    q.interruption('freight-paid'); phase('freight')


try:
    q.adb('shell', 'wm', 'size', '360x640'); q.adb('shell', 'wm', 'density', '160')
    q.adb('logcat', '-c'); q.launch()
    if any('got it' in entry[0].lower() for entry in q.lines(6)):
        q.click('Got it', scroll=False)
    if not q.state()['identity']['registered']:
        q.click('Sign the residency')
    if not q.state()['arrival_seen']:
        q.click('Fold the paper')
    if 'registered' not in q.DONE:
        phase('registered')
    if 'cleaning' not in q.DONE:
        cleaning()
    if 'freight' not in q.DONE:
        freight()
    logs = q.adb('logcat', '-d', '-s', 'godot', 'AndroidRuntime')
    (OUT/'runtime.txt').write_text('\n'.join(line.rstrip() for line in logs.splitlines())+'\n')
    q.check(not any(text in logs for text in ('SCRIPT ERROR', 'FATAL EXCEPTION', 'Program linking failed')),
            'no native script/crash/shader errors')
    evidence('passed')
    print('TACTILE JOBS ANDROID PASSED', flush=True)
except Exception as error:
    evidence('failed', error)
    try:
        q.shot('FAILED-final')
    except subprocess.CalledProcessError:
        pass  # Preserve the original failure when the emulator itself is gone.
    raise
finally:
    for setting in ('size', 'density'):
        subprocess.run(q.ADB+['shell', 'wm', setting, 'reset'], capture_output=True)
    for file in ('.ocr-frame.png', '.ocr-readable.png'):
        (OUT/file).unlink(missing_ok=True)
