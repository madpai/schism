#!/usr/bin/env python3
"""Living City touch/OCR QA; an explicitly selected isolated emulator, never save injection.

Run from the repository root after installing the new APK on a fresh AVD:
  python3 scripts/android-living-playtest.py --device emulator-5584 --adb /path/to/adb
--resume continues only this runner's marked QA citizen. No reset/clear command exists.
The checkpoint contains phase names and identity hashes, never a player save.
"""
import argparse
import csv
import hashlib
import io
import json
import os
from pathlib import Path
import re
import subprocess
import time
from PIL import Image, ImageChops, ImageStat

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--device', required=True)
parser.add_argument('--adb', default=os.environ.get('ADB', 'adb'))
parser.add_argument('--output', default='docs/playtests/android-living')
parser.add_argument('--resume', action='store_true')
parser.add_argument('--extended', action='store_true', help='Also validate a second shift, familiar controls and Day 2 inspection.')
args = parser.parse_args()
if not re.fullmatch(r'emulator-\d+', args.device):
    raise SystemExit('Select a fresh isolated emulator explicitly; physical devices are excluded.')
ADB = [args.adb, '-s', args.device]
PACKAGE = 'org.schism.districtix'
OUT = Path(args.output)
OUT.mkdir(parents=True, exist_ok=True)
SCENES = json.loads(Path('mobile/data/scenes.json').read_text())['scenes']
CHECKPOINT = OUT / 'qa-checkpoint.json'
STEPS = []
DONE = []
PRIOR_ATTEMPTS = []


def adb(*arguments, raw=False):
    result = subprocess.run(ADB + list(arguments), capture_output=True, check=True)
    return result.stdout if raw else result.stdout.decode().strip()


def state():
    candidates = []
    for slot in range(2):
        result = subprocess.run(ADB + ['exec-out', 'run-as', PACKAGE, 'cat',
                                      f'files/residency/slot{slot}.json'], capture_output=True)
        if result.returncode:
            continue
        try:
            envelope = json.loads(result.stdout)
            if hashlib.sha256(envelope['payload'].encode()).hexdigest() != envelope['sha256']:
                continue
            candidates.append(json.loads(envelope['payload']))
        except (ValueError, KeyError):
            continue
    return max(candidates, key=lambda value: value['revision']) if candidates else None


def dimensions():
    pairs = re.findall(r'(\d+)x(\d+)', adb('shell', 'wm', 'size'))
    return tuple(map(int, pairs[-1]))


def shot(name=None):
    path = OUT / (name + '.png') if name else OUT / '.ocr-frame.png'
    for _ in range(30):
        data = adb('exec-out', 'screencap', '-p', raw=True)
        if data.startswith(b'\x89PNG\r\n\x1a\n') and data[-8:-4] == b'IEND':
            frame = Image.open(io.BytesIO(data)).convert('L')
            if frame.getextrema()[1] > 16:
                path.write_bytes(data)
                return path
        time.sleep(.2)
    raise AssertionError('Android renderer stayed blank or returned incomplete PNGs.')


def lines(mode=3):
    result = subprocess.run(['tesseract', str(shot()), 'stdout', '--psm', str(mode), 'tsv'],
                            capture_output=True, text=True, check=True,
                            env={**os.environ, 'OMP_THREAD_LIMIT': '1'})
    groups = {}
    for row in csv.DictReader(io.StringIO(result.stdout), delimiter='\t'):
        if row.get('text', '').strip():
            groups.setdefault((row['block_num'], row['par_num'], row['line_num']), []).append(row)
    output = []
    for words in groups.values():
        left = min(int(word['left']) for word in words)
        top = min(int(word['top']) for word in words)
        right = max(int(word['left']) + int(word['width']) for word in words)
        bottom = max(int(word['top']) + int(word['height']) for word in words)
        output.append((' '.join(word['text'] for word in words), (left+right)//2,
                       (top+bottom)//2, words))
    return output


def tap(x, y):
    adb('shell', 'input', 'tap', str(int(x)), str(int(y)))
    time.sleep(.7)


def scroll_upward():
    width, height = dimensions()
    adb('shell', 'input', 'swipe', str(int(width*.87)), str(int(height*.86)),
        str(int(width*.87)), str(int(height*.43)), '250')
    time.sleep(.45)


def click(text, scroll=True, button_only=False):
    needle = text.lower()
    for _ in range(10 if scroll else 3):
        found = []
        for mode in (3, 6):
            found = [entry for entry in lines(mode) if needle in entry[0].lower()
                     and (not button_only or ':' not in entry[0])]
            if found:
                break
        if found:
            entry = found[-1]
            offset = 0
            start = entry[0].lower().rfind(needle)
            words = []
            for word in entry[3]:
                if offset < start+len(needle) and offset+len(word['text']) > start:
                    words.append(word)
                offset += len(word['text'])+1
            left = min(int(word['left']) for word in words)
            right = max(int(word['left'])+int(word['width']) for word in words)
            top = min(int(word['top']) for word in words)
            bottom = max(int(word['top'])+int(word['height']) for word in words)
            tap((left+right)//2, (top+bottom)//2)
            STEPS.append({'touch': text, 'point': [(left+right)//2, (top+bottom)//2]})
            print('TOUCH:', text, flush=True)
            return
        if scroll:
            scroll_upward()
    shot('FAILED-' + re.sub(r'\W+', '-', text))
    raise AssertionError(f'Cannot find {text!r}: {[entry[0] for entry in lines()]}')


def sheet_visible():
    frame = Image.open(shot()).convert('RGB')
    width, height = frame.size
    scale = width/480
    top = max(92*scale, height*.14)
    expected = (17, 25, 17)  # main.gd bounded sheet panel, untouched by analogue shader
    points = [(int(15*scale), int(top+10*scale)),
              (int(width-15*scale), int(top+10*scale)),
              (int(15*scale), int(top+80*scale))]
    return all(max(abs(a-b) for a, b in zip(frame.getpixel(point), expected)) <= 8 for point in points)


def close():
    # Android Back opens pause when no sheet exists; avoid creating that modal accidentally.
    if not sheet_visible():
        return
    adb('shell', 'input', 'keyevent', '4')
    time.sleep(.3)


def hotspot(name):
    current = state()
    rect = next(entry['rect'] for entry in SCENES[current['location']]['hotspots']
                if entry['id'] == name)
    width, height = dimensions()
    scale = width/480
    x = int((rect[0]+rect[2]/2)*width)
    y = int(100*scale+(rect[1]+rect[3]/2)*(height-222*scale))
    tap(x, y)
    STEPS.append({'hotspot': name, 'location': current['location'], 'point': [x, y]})
    print('OBJECT:', current['location'], name, flush=True)


def check(condition, label):
    if not condition:
        shot('FAILED-state')
        raise AssertionError(label)
    STEPS.append({'assertion': label, 'ok': True})
    print('PASS:', label, flush=True)


def launch():
    adb('shell', 'am', 'start', '-n', PACKAGE+'/com.godot.game.GodotAppLauncher')
    for _ in range(20):
        if any('schism' in entry[0].lower() or 'civic' in entry[0].lower() for entry in lines()):
            time.sleep(.5)
            return
        time.sleep(.3)
    raise AssertionError('Game interface did not appear.')


def interruption(label):
    before = state()
    adb('shell', 'input', 'keyevent', '3')
    time.sleep(.3)
    adb('shell', 'am', 'force-stop', PACKAGE)
    time.sleep(.3)
    launch()
    check(before == state(), label+': every saved field equals after background/force-stop/relaunch')
    STEPS.append({'interruption': label, 'revision': before['revision'],
                  'payload_sha256': hashlib.sha256(json.dumps(before, sort_keys=True).encode()).hexdigest()})
    shot(label+'-resumed')


def goto(target):
    # All movement is real scene hotspot input, never a reducer/state injection.
    close()
    while state()['location'] != target:
        location = state()['location']
        if location == 'room':
            hotspot('door')
        elif location == 'hall':
            hotspot('room' if target == 'room' else 'stairs')
        elif location == 'street':
            hotspot('hall' if target in ('hall', 'room') else target)
        else:
            hotspot('exit')
        check(not state()['shift'], 'navigation keeps no unfinished work order')


def identity_hash():
    return hashlib.sha256(json.dumps(state()['identity'], sort_keys=True).encode()).hexdigest()


def checkpoint(phase):
    if phase not in DONE:
        DONE.append(phase)
    CHECKPOINT.write_text(json.dumps({'device': args.device, 'package': PACKAGE,
                                     'identity_sha256': identity_hash(), 'done': DONE}, indent=2)+'\n')


def capture_sizes(prefix, object_name=None):
    before = state()
    for width, height in ((360, 640), (390, 844), (1080, 2400)):
        close()
        adb('shell', 'wm', 'size', f'{width}x{height}')
        adb('shell', 'wm', 'density', '160' if width < 600 else '420')
        time.sleep(2)
        if object_name:
            hotspot(object_name)
        shot(f'{prefix}-{width}x{height}')
        if object_name:
            scroll_upward()
            shot(f'{prefix}-lower-{width}x{height}')
        check(before == state(), f'{prefix} {width}x{height}: inspecting/scaling changes no saved field')
    close()
    adb('shell', 'wm', 'size', 'reset')
    adb('shell', 'wm', 'density', 'reset')
    time.sleep(2)


def registration():
    current = state()
    if not current or not current['identity']['registered']:
        shot('registration-top')
        click('Factory laborer')
        click('Technical apprentice', scroll=False)
        shot('registration-background')
        click('Sign the residency')
    check(state()['identity']['background'] == 'technical_apprentice', 'selected background persists')
    checkpoint('registered')
    if not state()['arrival_seen']:
        click('Fold the paper')
    check(state()['credits'] == 4, 'origin retains equal 4 CR starting wallet')
    check(any(item['kind'] == 'note' and item['metadata'].get('background') == 'technical_apprentice'
              for item in state()['items']), 'background memento is a real persisted possession')
    goto('room')
    hotspot('sink')
    click('Cup your hands')
    goto('bureau')
    hotspot('ticket')
    if 'put the paper' in ' '.join(entry[0].lower() for entry in lines()):
        click('Put the paper')
    hotspot('clerk')
    if not state()['id_shown']:
        click('Slide your civic')
    shot('bureau-authorizations')
    click('Sign Municipal Laundry')
    check(state()['employment'] == 'laundry', 'bureau ticket/ID/authorization path succeeds')
    checkpoint('employment')


def actual_drag_first_load():
    # OCR can read the narrow official type's 01 as O1, Ol or 0I. A merged
    # row may contain both tags, so derive the first card's x from its known
    # normalized layout rather than using the whole row's OCR center.
    entries = lines(3) + lines(6)
    category = state()['shift']['uniforms'][0]['type'].lower()
    sources = [entry for entry in entries if re.search(r"(?:^|\s)[0o][1il]\s*[/|]", entry[0], re.I)
               and category in entry[0].lower() and 'load' not in entry[0].lower()]
    if sources:
        width, _ = dimensions()
        scale = width/480
        source = min(sources, key=lambda entry: entry[2])
        start = (int(width*.27), int(source[2]-36*scale))
        # ClothActivity first card label baseline is 310; drum center is 110.
        # Relative y remains valid after bounded sheet scrolling.
        end = (width//2, int(source[2]-200*scale))
        shot('cloth-drag-before')
        adb('shell', 'input', 'swipe', str(start[0]), str(start[1]), str(end[0]), str(end[1]), '650')
        time.sleep(.8)
        success = state()['shift']['uniforms'][0]['loaded']
        STEPS.append({'gesture': 'garment-to-drum drag', 'from': start, 'to': end,
                      'source_ocr': source[0], 'saved_loaded': success})
        shot('cloth-drag-after')
        if success:
            check(True, 'actual Android drag saves first garment loading')
            return
    STEPS.append({'limitation': 'Drag could not be verified; continued with full-size tap alternative.',
                  'ocr_candidates': [entry[0] for entry in entries if category in entry[0].lower()]})
    close()
    hotspot('washer')
    click('Load uniform 01')


def laundry():
    if state()['jobs']['laundry']['shifts']:
        check(not state()['shift'], 'resumed first shift already settled')
        return
    goto('laundry') if not state()['shift'] else None
    if not state()['shift']:
        hotspot('cart')
        click('Pull the cart')
    if state()['shift']['stage'] == 'inspect':
        for index in range(4):
            garment = state()['shift']['uniforms'][index]
            if garment['sorted']:
                continue
            close(); hotspot('cart'); click(f'UNIFORM {index+1:02}')
            if not garment['inspected']:
                click('Unfold and read')
            if not garment['pocket_checked']:
                click('Turn out the')
            garment = state()['shift']['uniforms'][index]
            if garment['found'] and next(item for item in state()['items'] if item['id'] == garment['found'])['owner'] == 'found':
                shot('found-object'); click('Place in Lost Property')
                hotspot('cart'); click(f'UNIFORM {index+1:02}')
            click(garment['type'].upper(), button_only=True)
        close(); shot('cart-empty-scene'); hotspot('washer')
        if not state()['shift']['hatch_open']:
            click('Pull the hatch')
        if not state()['shift']['uniforms'][0]['loaded']:
            actual_drag_first_load()
        shot('cloth-partially-loaded')
        interruption('partial-load')
        hotspot('washer')
        for index in range(4):
            if not state()['shift']['uniforms'][index]['loaded']:
                click(f'Load uniform {index+1:02}')
    if state()['shift']['stage'] == 'prepare':
        close(); hotspot('washer')
        while state()['shift']['doses'] < 2:
            click('Tip one measured')
        click('STANDARD', button_only=True)
        if state()['shift']['hatch_open']:
            click('Push the hatch')
        click('Press the green')
        time.sleep(1.4)
        close()
        first = shot('washer-running-a'); time.sleep(.6); second = shot('washer-running-b')
        a = Image.open(first).convert('RGB'); b = Image.open(second).convert('RGB')
        width, height = a.size; scale = width/480; area = height-222*scale
        region = (int(width*.47), int(100*scale+area*.39), int(width*.70), int(100*scale+area*.55))
        rms = sum(ImageStat.Stat(ImageChops.difference(a.crop(region), b.crop(region))).rms)/3
        check(rms > 5, 'actual washer glass animation differs between two Android frames')
        STEPS.append({'measurement': 'washer-glass RGB RMS', 'value': rms, 'region': region})
    if state()['shift']['stage'] == 'washed':
        close(); hotspot('washer')
        if not state()['shift']['uniforms'][0]['unloaded']:
            click('Collect wet uniform 01')
        shot('cloth-partially-unloaded')
        interruption('partial-unload'); hotspot('washer')
        for index in range(4):
            if not state()['shift']['uniforms'][index]['unloaded']:
                click(f'Collect wet uniform {index+1:02}')
    if state()['shift']['stage'] == 'wet':
        close(); hotspot('washer'); click('Hang the bundle')
    if state()['shift']['stage'] == 'dry':
        close(); hotspot('washer')
        if state()['shift']['uniforms'][0]['folds'] == 0:
            shot('cloth-before-fold'); click('Fold the left sleeve')
        shot('cloth-one-fold'); interruption('partial-fold')
        capture_sizes('cloth-folding', 'washer')
        hotspot('washer')
        while state()['shift']['stage'] == 'dry':
            current = state()['shift']['uniforms']
            garment = next(item for item in current if item['folds'] < (2 if item['type'] == 'medical' else 3))
            folds = int(garment['folds'])
            click(('Bring both sleeves' if folds == 0 else 'Fold the hem') if garment['type'] == 'medical'
                  else ['Fold the left sleeve', 'Fold the right sleeve', 'Fold the hem'][folds])
    if state()['shift']['stage'] == 'folded':
        close(); hotspot('washer')
        click('Carry the stack'); click('Place folded')
    if state()['shift']['stage'] == 'receipt':
        close(); hotspot('outgoing'); click('Slide your timecard')
        shot('wage-slip')
        check(state()['last_receipt']['quality'] == 100, 'tactile first shift quality 100')
        click('Fold the wage')
    check(state()['credits'] == 11 and state()['jobs']['laundry']['shifts'] == 1 and not state()['shift'],
          'first laundry shift pays 7 CR exactly once; wallet 11 CR')
    interruption('settled-wage')
    check(state()['credits'] == 11, 'settled wage cannot duplicate after process death')
    checkpoint('laundry')


def event_phase(phase, location, hotspot_name, choice, flag):
    if not state()['city']['flags'].get(flag):
        goto(location); hotspot(hotspot_name); shot(phase+'-choice'); click(choice)
    check(state()['city']['flags'].get(flag), phase+' choice persists its consequence')
    check(state()['city']['encounters'][phase]['count'] == 1, phase+' encounter resolved once')
    shot(phase+'-after'); checkpoint(phase)


def open_bag_item(label):
    close()
    width, height = dimensions()
    tap(width*.54, height-38*width/480)
    # Label alternatives are intentional accessibility controls, including deeper pockets.
    carried = [item for item in state()['items'] if item['owner'] == 'player' and item['storage'] == 'bag']
    page = next(index//4 for index, item in enumerate(carried) if item['label'] == label)
    if len(carried) > 4:
        click('Previous pocket')  # disabled on page zero; safe reset of ephemeral page view
        for _ in range(page):
            click('Look deeper')
        shot('bag-deeper-pocket' if page else 'bag-first-pocket')
    shot('bag-before-'+re.sub(r'\W+', '-', label))
    click(label)
    check('serial' in ' '.join(entry[0].lower() for entry in lines()), 'bag item inspection displays a serial record')


def shopping():
    goto('shop')
    # Read affected goods without buying expensive possessions; actual rendered evidence.
    for object_name, name in [('stew', 'shop-stew-tea'), ('water', 'shop-water-soap'), ('goods', 'shop-shelf')]:
        close(); hotspot(object_name); shot(name+'-top'); scroll_upward(); shot(name+'-lower')
        if object_name == 'goods':
            for _ in range(5):
                if any('salvaged wall shelf' in entry[0].lower() for entry in lines()):
                    shot('shop-shelf-art'); break
                scroll_upward()
    for kind, object_name, buy, label, consume in [
        ('bread', 'food', 'Take Wrapped black', 'Wrapped black bread', 'Unwrap and eat'),
        ('water', 'water', 'Take Bottled water', 'Bottled water', 'Open and drink'),
        ('soap', 'water', 'Take Municipal soap', 'Municipal soap', None)]:
        purchased = [item for item in state()['items'] if item['kind'] == kind and item['origin'] == 'Food kiosk']
        if not purchased:
            close(); hotspot(object_name); click(buy)
            purchased = [item for item in state()['items'] if item['kind'] == kind and item['origin'] == 'Food kiosk']
        if consume and purchased[0]['owner'] == 'player':
            open_bag_item(label); shot(kind+'-inspection'); click(consume)
    check(state()['credits'] == 6, 'bread/water/soap purchases leave 6 CR without injected resources')
    checkpoint('shopping')


def home():
    goto('room')
    if 'washed-home' not in DONE:
        if state()['needs']['hygiene'] <= 70:
            hotspot('sink'); click('Wash face')
        checkpoint('washed-home')
    if 'slept-home' not in DONE:
        if state()['minute'] % 1440 // 60 < 19:
            hotspot('bed'); click('Pull the blanket')
        checkpoint('slept-home')
    shot('home-after-survival-loop')
    check(state()['needs']['energy'] >= 95 and state()['needs']['hygiene'] >= 65,
          'daily loop restores energy and maintains hygiene after exploration, food and paid work')
    check(state()['city']['flags'].get('service_repaired'), 'rest is optional for the repaired relay')
    interruption('survival-loop'); checkpoint('home')


def extended_flow():
    if 'extended-second-shift' not in DONE:
        if state()['jobs']['laundry']['shifts'] < 2:
            if not state()['shift']:
                goto('laundry'); hotspot('cart'); click('Pull the cart')
            if state()['shift']['stage'] == 'inspect':
                for index in range(4):
                    garment = state()['shift']['uniforms'][index]
                    if garment['sorted']:
                        continue
                    close(); hotspot('cart'); click(f'UNIFORM {index+1:02}')
                    if not garment['inspected']:
                        click('Unfold and read')
                    if not garment['pocket_checked']:
                        click('Turn out the')
                    garment = state()['shift']['uniforms'][index]
                    if garment['found'] and next(item for item in state()['items'] if item['id'] == garment['found'])['owner'] == 'found':
                        click('Place in Lost Property'); hotspot('cart'); click(f'UNIFORM {index+1:02}')
                    click(garment['type'].upper(), button_only=True)
                close(); hotspot('washer')
                if not state()['shift']['hatch_open']:
                    click('Pull the hatch')
                if not state()['shift']['uniforms'][0]['loaded']:
                    actual_drag_first_load()
                shot('second-shift-familiar-loading')
                click('lift the remaining')
            if state()['shift']['stage'] == 'prepare':
                close(); hotspot('washer')
                while state()['shift']['doses'] < 2:
                    click('Tip one measured')
                click('HOT', button_only=True)
                if state()['shift']['hatch_open']:
                    click('Push the hatch')
                click('Press the green'); time.sleep(1.4)
            if state()['shift']['stage'] == 'washed':
                close(); hotspot('washer'); click('collect the remaining')
            if state()['shift']['stage'] == 'wet':
                close(); hotspot('washer'); click('Hang the bundle')
            if state()['shift']['stage'] == 'dry':
                close(); hotspot('washer'); shot('second-shift-familiar-folding')
                click('fold the remaining')
            if state()['shift']['stage'] == 'folded':
                close(); hotspot('outgoing'); click('Place folded')
            if state()['shift']['stage'] == 'receipt':
                close(); hotspot('outgoing'); click('Slide your timecard'); shot('second-wage-slip')
                click('Fold the wage')
        check(state()['jobs']['laundry']['shifts'] == 2 and state()['last_receipt']['quality'] == 100,
              'second shift familiar controls retain quality and exact-once settlement')
        check(state()['credits'] == 13 and state()['taxes']['accrued'] == 1,
              'second wage pays full 7 CR; 1 CR assessment remains unpaid until office payment')
        interruption('second-shift-settlement'); checkpoint('extended-second-shift')
    if 'extended-rest' not in DONE:
        goto('room')
        paste = next((item for item in state()['items'] if item['kind'] == 'paste' and item['owner'] == 'player'), None)
        if paste:
            open_bag_item(paste['label']); click('Unwrap and eat')
        hotspot('sink'); click('Cup your hands')
        # Resume will not sleep a second time if the successful transaction outlived the checkpoint write.
        if int(state()['minute']) // 1440 == 0 or int(state()['minute']) % 1440 // 60 < 6:
            hotspot('bed'); click('Pull the blanket')
        check(int(state()['minute']) // 1440 >= 1 and 6 <= int(state()['minute']) % 1440 // 60 < 22,
              'second-shift ordinary sleep restores the citizen on Day 2')
        checkpoint('extended-rest')
    if 'extended-inspection' not in DONE:
        goto('service'); hotspot('guard'); shot('day-two-security-inspection')
        if 'street_inspection' not in state()['city']['encounters']:
            click('Present civic paper')
        check(state()['city']['encounters']['street_inspection']['count'] == 1,
              'physical guard inspection resolves once on Day 2')
        interruption('day-two-inspection'); checkpoint('extended-inspection')


def run():
    global DONE
    installed = adb('shell', 'pm', 'path', PACKAGE).removeprefix('package:')
    apk_hash = adb('shell', 'sha256sum', installed).split()[0]
    initial = state()
    if initial and initial['identity']['registered']:
        if not args.resume or not CHECKPOINT.exists():
            raise SystemExit('Existing registered citizen: use a fresh isolated AVD. No saves are reset.')
        marker = json.loads(CHECKPOINT.read_text())
        if marker['device'] != args.device or marker['identity_sha256'] != identity_hash():
            raise SystemExit('--resume marker does not identify this isolated QA citizen.')
        DONE = marker['done']
        candidates = [path for path in (OUT/'failure.json', OUT/'touch-evidence.json') if path.exists()]
        if candidates:
            previous_path = max(candidates, key=lambda path: path.stat().st_mtime_ns)
            previous = json.loads(previous_path.read_text())
            STEPS.extend(previous.get('steps', []))
            PRIOR_ATTEMPTS.extend(previous.get('prior_attempts', []))
            if previous.get('error'):
                PRIOR_ATTEMPTS.append({'error': previous['error'], 'source': previous_path.name,
                                       'note': 'Successful assertions and measurements before this failure remain in steps.'})
        STEPS.append({'resume': True, 'completed_phases': list(DONE), 'revision': state()['revision']})
    elif args.resume:
        raise SystemExit('--resume requires this runner\'s marked registered QA citizen.')
    adb('logcat', '-c'); launch()
    if 'employment' not in DONE:
        registration()
    if 'laundry' not in DONE:
        laundry()
    if 'coworker_cover' not in DONE:
        event_phase('coworker_cover', 'laundry', 'coworker', 'Help clear the station', 'coworker_known')
    if 'service_repair' not in DONE:
        goto('service'); shot('service-daytime'); capture_sizes('service-daytime')
        event_phase('service_repair', 'service', 'cabinet', 'Reseat the relay', 'service_repaired')
        check(state()['city'].get('security_favor', 0) >= 1, 'repair records a security favor')
        event_phase('relay_detail', 'service', 'relay', 'Listen beside the cabinet', 'relay_heard')
        check('relay_signal' in state()['discoveries'], 'repair immediately unlocks the recovered recording')
    if 'neighbor_help' not in DONE:
        event_phase('neighbor_help', 'hall', 'neighbor', 'Carry the basket', 'neighbor_known')
    if 'shopping' not in DONE:
        shopping()
    if 'home' not in DONE:
        home()
    if 'relay_detail' not in DONE:
        goto('service'); shot('service-evening')
        event_phase('relay_detail', 'service', 'relay', 'Listen beside the cabinet', 'relay_heard')
        check('relay_signal' in state()['discoveries'], 'repaired relay records its discovery without a time gate')
        check(any(item['label'] == 'Relay count transcription' for item in state()['items']),
              'relay discovery produces persistent physical transcription')
    if args.extended:
        extended_flow()
    interruption('living-city-complete')
    logs = adb('logcat', '-d', '-s', 'godot', 'AndroidRuntime')
    (OUT/'runtime.txt').write_text(logs)
    check(not any(error in logs for error in ('SCRIPT ERROR', 'FATAL EXCEPTION', 'Program linking failed')),
          'no native script, Java crash or GLES shader-link errors')
    current = state()
    evidence = {'package': PACKAGE, 'apk_sha256': apk_hash, 'device': args.device,
                'sdk': adb('shell', 'getprop', 'ro.build.version.sdk'),
                'device_model': adb('shell', 'getprop', 'ro.product.model'),
                'emulator_renderer': 'Read runtime/device configuration; no physical GPU coverage claimed.',
                'resume': args.resume, 'extended': args.extended, 'prior_attempts': PRIOR_ATTEMPTS, 'steps': STEPS,
                'final': {'revision': current['revision'], 'location': current['location'],
                          'minute': current['minute'], 'credits': current['credits'], 'needs': current['needs'],
                          'background': current['identity']['background'],
                          'shifts': current['jobs']['laundry']['shifts'], 'receipt': current['last_receipt'],
                          'city_flags': current['city']['flags'], 'discoveries': current['discoveries']},
                'limits': 'Emulator touch/render/interruption evidence only; no physical-phone audio, comfort, performance or retention claim.'}
    (OUT/'touch-evidence.json').write_text(json.dumps(evidence, indent=2)+'\n')
    (OUT/'failure.json').unlink(missing_ok=True)
    print('LIVING CITY ANDROID TOUCH LOOP PASSED', flush=True)


if __name__ == '__main__':
    try:
        run()
    except Exception as error:
        try:
            shot('FAILED-final')
            (OUT/'failure.json').write_text(json.dumps({'error': str(error), 'prior_attempts': PRIOR_ATTEMPTS, 'steps': STEPS}, indent=2)+'\n')
        except Exception:
            pass
        raise
    finally:
        # Restore only emulator viewport overrides. Citizen state is never replaced.
        subprocess.run(ADB+['shell', 'wm', 'size', 'reset'], capture_output=True)
        subprocess.run(ADB+['shell', 'wm', 'density', 'reset'], capture_output=True)
        (OUT/'.ocr-frame.png').unlink(missing_ok=True)
