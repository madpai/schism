#!/usr/bin/env python3
"""Continue a marked Living City emulator citizen through manual tax and detention.
Only actual taps advance the citizen; no save injection, clearing or clock edits.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import sys
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--device', required=True)
parser.add_argument('--repeat-only', action='store_true', help='Verify familiar bundle controls on a marked, experienced citizen.')
parser.add_argument('--resume', action='store_true', help='Continue only this runner’s failed marked-citizen flow.')
parser.add_argument('--adb', default='adb')
parser.add_argument('--citizen-evidence', required=True)
parser.add_argument('--output', default='docs/playtests/android-tax-v040')
args = parser.parse_args()
output = Path(args.output)
if output.exists() and any(output.iterdir()) and not args.resume:
    raise SystemExit('Use a new evidence directory.')
prior_steps = []
if args.resume:
    failed = output/'failure.json'
    if not failed.exists(): raise SystemExit('Resume requires this flow’s failure receipt.')
    prior_steps = json.loads(failed.read_text()).get('steps', [])
original = sys.argv
sys.argv = [original[0], '--device', args.device, '--adb', args.adb, '--output', args.output]
spec = importlib.util.spec_from_file_location('touch_qa', 'scripts/android-living-playtest.py')
qa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qa)
sys.argv = original
qa.STEPS.extend(prior_steps)
marker = json.loads((Path(args.citizen_evidence)/'qa-checkpoint.json').read_text())
qa.check(marker['device'] == args.device and marker['identity_sha256'] == qa.identity_hash(),
         'selected citizen belongs to the explicitly marked isolated Living City run')


def another_shift():
    before = qa.state()
    if not before['shift']:
        qa.goto('laundry'); qa.hotspot('cart'); qa.click('Pull the cart')
    if qa.state()['shift']['stage'] == 'inspect':
        for index in range(4):
            garment = qa.state()['shift']['uniforms'][index]
            if garment['sorted']: continue
            qa.close(); qa.hotspot('cart'); qa.click(f'UNIFORM {index+1:02}')
            if not garment['inspected']: qa.click('Unfold and read')
            if not garment['pocket_checked']: qa.click('Turn out the')
            garment = qa.state()['shift']['uniforms'][index]
            if garment['found'] and next(item for item in qa.state()['items'] if item['id'] == garment['found'])['owner'] == 'found':
                qa.click('Place in Lost Property'); qa.hotspot('cart'); qa.click(f'UNIFORM {index+1:02}')
            qa.click(garment['type'].upper(), button_only=True)
        qa.close(); qa.hotspot('washer')
        if not qa.state()['shift']['hatch_open']: qa.click('Pull the hatch')
        for index in range(4):
            if not qa.state()['shift']['uniforms'][index]['loaded']: qa.click(f'Load uniform {index+1:02}')
    if qa.state()['shift']['stage'] == 'prepare':
        qa.close(); qa.hotspot('washer')
        while qa.state()['shift']['doses'] < 2: qa.click('Tip one measured')
        cycle = 'SANITIZE' if any(g['stain'] == 'blood' for g in qa.state()['shift']['uniforms']) else 'HOT' if any(g['stain'] == 'oil' for g in qa.state()['shift']['uniforms']) else 'STANDARD'
        qa.click(cycle, button_only=True)
        if qa.state()['shift']['hatch_open']: qa.click('Push the hatch')
        qa.click('Press the green')
    if qa.state()['shift']['stage'] == 'washed':
        qa.close(); qa.hotspot('washer')
        for index in range(4):
            if not qa.state()['shift']['uniforms'][index]['unloaded']: qa.click(f'Collect wet uniform {index+1:02}')
    if qa.state()['shift']['stage'] == 'wet':
        qa.close(); qa.hotspot('washer'); qa.click('Hang the bundle')
    if qa.state()['shift']['stage'] == 'dry':
        qa.close(); qa.hotspot('washer'); qa.click('fold the remaining')
    if qa.state()['shift']['stage'] == 'folded':
        qa.close(); qa.hotspot('outgoing'); qa.click('Place folded')
    if qa.state()['shift']['stage'] == 'receipt':
        qa.close(); qa.hotspot('outgoing'); qa.click('Slide your timecard')
        qa.shot('full-gross-new-tax-assessment'); qa.click('Fold the wage')
    now = qa.state()
    qa.check(now['credits'] == before['credits'] + now['last_receipt']['gross']
             and now['last_receipt']['withholding'] == 0 and now['taxes']['accrued'] > 0,
             'new shift pays full gross and records unpaid assessment instead of withholding')


def feed_if_needed():
    if qa.state()['needs']['hunger'] >= 35:
        return
    qa.goto('shop'); qa.hotspot('food'); qa.click('Take Wrapped black')
    qa.open_bag_item('Wrapped black bread'); qa.click('Unwrap and eat'); qa.goto('room')


def repeat_work():
    before = qa.state()
    qa.check(not before['shift'] and before['jobs']['laundry']['shifts'] >= 1, 'marked citizen is eligible for familiar work')
    qa.goto('laundry'); qa.hotspot('cart'); qa.click('Pull the cart')
    for index in range(4):
        qa.close(); qa.hotspot('cart'); qa.click(f'UNIFORM {index+1:02}')
        qa.click('Unfold and read'); qa.click('Turn out the')
        garment = qa.state()['shift']['uniforms'][index]
        if garment['found']:
            qa.click('Place in Lost Property'); qa.hotspot('cart'); qa.click(f'UNIFORM {index+1:02}')
        qa.click(garment['type'].upper(), button_only=True)
    qa.close(); qa.hotspot('washer'); qa.click('Pull the hatch')
    qa.shot('familiar-load-before-cloth'); qa.click('lift the remaining', scroll=False)
    qa.check(all(g['loaded'] for g in qa.state()['shift']['uniforms']), 'familiar loading visible without scrolling loads every garment')
    while qa.state()['shift']['doses'] < 2: qa.click('Tip one measured')
    cycle = 'SANITIZE' if any(g['stain'] == 'blood' for g in qa.state()['shift']['uniforms']) else 'HOT' if any(g['stain'] == 'oil' for g in qa.state()['shift']['uniforms']) else 'STANDARD'
    qa.click(cycle, button_only=True); qa.click('Push the hatch'); qa.click('Press the green')
    qa.close(); qa.hotspot('washer'); qa.shot('familiar-collection-before-cloth')
    qa.click('collect the remaining', scroll=False)
    qa.check(all(g['unloaded'] for g in qa.state()['shift']['uniforms']), 'familiar collection is visible before the cloth surface')
    qa.close(); qa.hotspot('washer'); qa.click('Hang the bundle')
    qa.close(); qa.hotspot('washer'); qa.shot('familiar-folding-before-cloth')
    qa.click('fold the remaining', scroll=False)
    qa.close(); qa.hotspot('outgoing'); qa.click('Place folded'); qa.click('Slide your timecard'); qa.click('Fold the wage')
    qa.check(qa.state()['last_receipt']['quality'] == 100 and qa.state()['jobs']['laundry']['shifts'] == before['jobs']['laundry']['shifts']+1, 'familiar controls complete one quality-100 daily work loop')
    qa.interruption('familiar-work-settlement')
    apk = qa.adb('shell', 'pm', 'path', qa.PACKAGE).removeprefix('package:')
    (output/'touch-evidence.json').write_text(json.dumps({'apk_sha256': qa.adb('shell', 'sha256sum', apk).split()[0], 'device': args.device, 'steps': qa.STEPS, 'receipt': qa.state()['last_receipt']}, indent=2)+'\n')
    print('FAMILIAR WORK ANDROID FLOW PASSED', flush=True)


def run():
    qa.adb('logcat', '-c'); qa.launch()
    if args.repeat_only:
        repeat_work(); return
    if not any(step.get('assertion', '').startswith('physical office payment retires') for step in prior_steps):
        before = qa.state()
        qa.check(before['schema'] == 6 and before['taxes']['accrued'] > 0,
                 'new full-gross wage has a payable tax assessment')
        qa.goto('bureau'); qa.hotspot('tax'); qa.shot('tax-payment-slip-unpaid')
        qa.capture_sizes('tax-payment-counter', 'tax')
        qa.hotspot('tax'); qa.click('across the counter')
        now = qa.state(); paid = before['taxes']['accrued'] + before['taxes']['due']
        qa.check(now['taxes']['accrued'] == 0 and now['taxes']['due'] == 0
                 and now['tax_paid'] == before['tax_paid'] + paid
                 and now['credits'] == before['credits'] - paid,
                 'physical office payment retires exactly the displayed debt and wallet amount')
        qa.shot('tax-payment-stamped'); qa.interruption('manual-tax-payment')
    if not any(step.get('assertion', '').startswith('new shift pays full gross') for step in prior_steps):
        another_shift()
    if not qa.state()['taxes']['flagged']: qa.goto('room')
    debt = qa.state()['taxes']['accrued'] + qa.state()['taxes']['due']
    deadline = next((entry['minute'] for entry in reversed(qa.state()['taxes']['ledger']) if entry['type'] == 'bill' and entry['amount'] > 0), qa.state()['taxes']['next_due'])
    for _ in range(20):
        current = qa.state()
        if current['taxes']['flagged']:
            break
        feed_if_needed(); qa.hotspot('sink'); qa.click('Cup your hands')
        qa.hotspot('bed'); qa.click('Pull the blanket')
        current = qa.state()
        if current['taxes']['due'] > 0 and not current['taxes']['flagged']:
            qa.shot('tax-invoice-one-day-grace')
    current = qa.state()
    qa.check(current['taxes']['flagged'] and current['minute'] >= deadline + 1440,
             'unpaid invoice flags only after three played days and one-day grace')
    qa.check(current['location'] in ['room', 'street'] and not current['legal']['camp'].get('active', False),
             'deadline flags safely without teleporting the sleeping citizen into detention')
    qa.interruption('overdue-tax-flag')
    held = [item['id'] for item in qa.state()['items'] if item['owner'] == 'player' and item['storage'] == 'bag']
    qa.close()
    if qa.state()['location'] == 'room':
        qa.hotspot('door'); qa.hotspot('stairs')
    qa.check(qa.state()['location'] == 'street', 'inspection warning permits direct bureau payment before enforcement')
    qa.shot('overdue-street-payment-warning'); qa.close(); qa.hotspot('laundry')
    qa.check(qa.state()['location'] == 'camp' and qa.state()['legal']['camp']['reason'] == 'tax',
             'street inspection admits the flagged citizen to debt-repayment work')
    qa.shot('tax-camp-intake'); qa.interruption('tax-detention-intake')
    tax_paid = qa.state()['tax_paid']; wallet = qa.state()['credits']
    for order in range(max(3, int(debt))):
        qa.close(); qa.hotspot('meal'); qa.click('Eat the camp ration')
        qa.close(); qa.hotspot('scrap')
        for bin_name in ['METAL', 'FABRIC', 'METAL']:
            qa.click(bin_name, button_only=True)
        qa.click('Push the sorted tray')
        qa.check(qa.state()['legal']['camp']['orders'] == order+1, 'city supply order counts exactly once')
        qa.shot(f'city-supply-order-{order+1}')
        if order == 0:
            qa.interruption('first-debt-work-order')
    current = qa.state()
    qa.check(current['city']['supplies']['metal'] == 2*max(3, int(debt))
             and current['city']['supplies']['fabric'] == max(3, int(debt))
             and current['taxes']['worked_off'] == debt
             and current['taxes']['accrued'] + current['taxes']['due'] == 0
             and current['tax_paid'] == tax_paid and current['credits'] == wallet,
             'labor supplies city and retires tax without wages or fictitious cash payment')
    qa.close(); qa.hotspot('clerk'); qa.shot('tax-debt-cleared-release'); qa.click('Present the completed')
    qa.check(qa.state()['location'] == 'room' and not qa.state()['legal']['camp']['active'],
             'cleared debt and minimum production permit release to the citizen room')
    qa.check(all(any(item['id'] == item_id and item['owner'] == 'player' for item in qa.state()['items'])
                 for item_id in held), 'held belongings return with conserved identity on release')
    qa.interruption('tax-camp-release')
    logs = qa.adb('logcat', '-d', '-s', 'godot', 'AndroidRuntime')
    (output/'runtime.txt').write_text(logs)
    qa.check(not any(word in logs for word in ['SCRIPT ERROR', 'FATAL EXCEPTION']), 'tax flow has no native script or Java errors')
    apk = qa.adb('shell', 'pm', 'path', qa.PACKAGE).removeprefix('package:')
    result = {'apk_sha256': qa.adb('shell', 'sha256sum', apk).split()[0], 'device': args.device,
              'steps': qa.STEPS, 'taxes': qa.state()['taxes'], 'supplies': qa.state()['city']['supplies'],
              'limits': 'Isolated emulator touch evidence; no physical-phone test.'}
    (output/'touch-evidence.json').write_text(json.dumps(result, indent=2)+'\n')
    (output/'failure.json').unlink(missing_ok=True)
    print('MANUAL TAX AND CITY SUPPLY DETENTION ANDROID FLOW PASSED', flush=True)


if __name__ == '__main__':
    try:
        run()
    except Exception as error:
        qa.shot('FAILED-final')
        (output/'failure.json').write_text(json.dumps({'error': str(error), 'steps': qa.STEPS}, indent=2)+'\n')
        raise
