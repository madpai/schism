#!/usr/bin/env python3
"""Real touch QA on one explicitly selected fresh isolated SCHISM emulator."""
import argparse, csv, hashlib, importlib.util, io, json, os, re, subprocess, sys, time
from pathlib import Path
from PIL import Image, ImageOps
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--device',required=True); p.add_argument('--adb',required=True)
p.add_argument('--output',default='docs/playtests/android-v050'); p.add_argument('--resume',action='store_true')
a=p.parse_args()
if not re.fullmatch(r'emulator-\d+',a.device): raise SystemExit('An isolated emulator must be selected explicitly.')
original_args=sys.argv
sys.argv=['android-living-playtest.py','--device',a.device,'--adb',a.adb,'--output',a.output]
spec=importlib.util.spec_from_file_location('living_helpers', 'scripts/android-living-playtest.py')
q=importlib.util.module_from_spec(spec); spec.loader.exec_module(q); sys.argv=original_args
OUT=Path(a.output); MARK=OUT/'qa-checkpoint.json'; APK=Path('builds/schism-android-debug.apk')
APK_HASH=hashlib.sha256(APK.read_bytes()).hexdigest()
if MARK.exists():
    if not a.resume: raise SystemExit('This QA citizen already exists; use --resume, never reset.')
    mark=json.loads(MARK.read_text()); q.DONE=mark['done']
    if mark['identity_sha256']!=q.identity_hash(): raise SystemExit('QA identity does not match marker.')
    previous=OUT/'touch-evidence.json'
    if previous.exists(): q.STEPS=json.loads(previous.read_text()).get('steps',[])
elif q.state() and q.state()['identity']['registered']:
    raise SystemExit('Refusing to reuse an unmarked citizen.')


def evidence(status, error=None):
    current=q.state()
    record={'status':status,'apk_sha256':APK_HASH,'package':q.PACKAGE,'version':'0.5.0','device':a.device,
      'build':q.adb('shell','getprop','ro.build.fingerprint'), 'gpu_backend':'isolated AVD / swangle ANGLE Compatibility',
      'coverage_limit':'Emulator only; no physical phone, no subjective ergonomics/audio validation.',
      'done':q.DONE,'steps':q.STEPS,'state_sha256':hashlib.sha256(json.dumps(current,sort_keys=True).encode()).hexdigest() if current else None,
      'summary':{key:current[key] for key in ('schema','revision','minute','credits','employment','tax_paid')} if current else {},
      'laundry_shifts':current['jobs']['laundry']['shifts'] if current else 0}
    if error: record['error']=error
    (OUT/'touch-evidence.json').write_text(json.dumps(record,indent=2)+'\n')


# Dark native controls need an inverted enlarged OCR pass at the smallest size.
# Coordinates are mapped back to actual Android pixels; taps remain real input.
original_lines = q.lines
def readable_lines(mode=3):
    entries = original_lines(mode)
    source = q.shot(); target = OUT/'.ocr-readable.png'
    frame = Image.open(source).convert('L')
    ImageOps.invert(frame).resize((frame.width*2,frame.height*2)).save(target)
    result = subprocess.run(['tesseract',str(target),'stdout','--psm',str(mode),'tsv'],capture_output=True,text=True,check=True,env={**os.environ,'OMP_THREAD_LIMIT':'1'})
    groups = {}
    for row in csv.DictReader(io.StringIO(result.stdout),delimiter='\t',quoting=csv.QUOTE_NONE):
        if row.get('text','').strip():
            for key in ('left','top','width','height'): row[key]=str(int(row[key])//2)
            groups.setdefault((row['block_num'],row['par_num'],row['line_num']),[]).append(row)
    for words in groups.values():
        left=min(int(w['left']) for w in words); right=max(int(w['left'])+int(w['width']) for w in words)
        top=min(int(w['top']) for w in words); bottom=max(int(w['top'])+int(w['height']) for w in words)
        entries.append((' '.join(w['text'] for w in words),(left+right)//2,(top+bottom)//2,words))
    return entries
q.lines = readable_lines


def resize(width,height):
    q.adb('shell','wm','size',f'{width}x{height}')
    q.adb('shell','wm','density','160' if width<600 else '420'); time.sleep(1.2)


def current_sizes(prefix):
    before=q.state()
    for width,height in ((360,640),(390,844),(1080,2400)):
        resize(width,height); q.shot(f'{prefix}-{width}x{height}')
        q.scroll_upward(); q.shot(f'{prefix}-lower-{width}x{height}')
        q.check(q.state()==before,f'{prefix} {width}x{height} inspection and resize are transaction free')
    resize(360,640)


def register_and_job():
    if not q.state() or not q.state()['identity']['registered']:
        q.shot('registration-360x640'); q.click('Sign the residency')
    if not q.state()['arrival_seen']: q.click('Fold the paper')
    q.check(q.state()['credits']==4,'paperwork preserves starting wallet')
    q.check(q.state()['identity']['background']=='factory_laborer','factory origin is persisted')
    q.checkpoint('registered'); evidence('running')
    q.goto('bureau')
    if not q.state()['ticket']: q.hotspot('ticket'); q.click('Put the paper')
    q.hotspot('clerk')
    if not q.state()['id_shown']: q.click('Slide your civic')
    else:
        q.close(); q.hotspot('vacancies')
    before=q.state(); q.shot('vacancy-360x640')
    print('VISUAL_QA:',str(OUT/'vacancy-360x640.png'),flush=True)
    q.click('Municipal Laundry Attendant'); q.shot('vacancy-laundry-marked')
    q.check(before==q.state(),'checking vacancy changes a draft only')
    q.click('Civic Sanitation Worker'); q.shot('vacancy-cleaning-marked')
    q.check(before==q.state(),'switching checkbox leaves all authority fields unchanged')
    q.interruption('unsigned-draft')
    q.check(q.state()['employment']=='','unsigned draft cannot grant a job after process death')
    q.hotspot('vacancies')
    current_sizes('vacancy-clipboard')
    q.close(); q.hotspot('vacancies'); q.click('Municipal Laundry Attendant')
    q.click('Sign here'); q.shot('signed-authorization')
    q.check(q.state()['employment']=='laundry' and q.state()['revision']==before['revision']+1,'signature assigns selected job exactly once')
    q.click('Fold the authorization'); q.checkpoint('employment'); evidence('running')


def ocr_image(path):
    source=Image.open(path).convert('L'); target=OUT/'.ocr-measured.png'
    ImageOps.invert(source).resize((source.width*2,source.height*2)).save(target)
    result=subprocess.run(['tesseract',str(target),'stdout','--psm','6','tsv'],capture_output=True,text=True,check=True,env={**os.environ,'OMP_THREAD_LIMIT':'1'})
    groups={}
    for row in csv.DictReader(io.StringIO(result.stdout),delimiter='\t',quoting=csv.QUOTE_NONE):
        if row.get('text','').strip(): groups.setdefault((row['block_num'],row['par_num'],row['line_num']),[]).append(row)
    return [(' '.join(w['text'] for w in words),sum(int(w['top'])+int(w['height'])/2 for w in words)/len(words)/2) for words in groups.values()]


def garment_line(entries, category):
    return next((entry for entry in entries if re.search(r'(?:^|\s)[0o][1il]\s*[/|]',entry[0],re.I) and category in entry[0].lower() and 'load' not in entry[0].lower()),None)


def measured_drag(mode):
    category=q.state()['shift']['uniforms'][0]['type'].lower()
    width,height=q.dimensions(); scale=width/480
    for attempt in range(18):
        entries=q.lines(6); source=garment_line(entries,category)
        if mode=='unload':
            basket=next((e for e in entries if 'collect wet uniform 01' in e[0].lower()),None)
            if basket:
                start=(int(width*.27),int(basket[2]-392*scale))
                end=(width//2,int(basket[2]-126*scale))
                if 160*scale<start[1]<height-70*scale and 130*scale<end[1]<height-70*scale: break
            q.adb('shell','input','swipe',str(int(width*.92)),str(int(height*.75)),str(int(width*.92)),str(int(height*.75-40*scale)),'250'); time.sleep(.35)
            continue
        if source:
            start=(int(width*.27),int(source[2]-36*scale))
            end=(width//2,int(source[2]+(232.5 if mode=='unload' else -200)*scale))
            if 130*scale<start[1]<height-70*scale and 130*scale<end[1]<height-70*scale: break
        q.scroll_upward()
    else: raise AssertionError(f'Could not expose both {mode} garment and physical target: {[e[0] for e in entries]}')
    before=q.shot(f'{mode}-drag-before'); anchor=garment_line(ocr_image(before),category) if mode=='load' else next((e for e in ocr_image(before) if 'collect wet uniform 01' in e[0].lower()),None)
    q.check(anchor is not None,f'{mode} baseline garment label is readable')
    process=subprocess.Popen(q.ADB+['shell','input','swipe',str(start[0]),str(start[1]),str(end[0]),str(end[1]),'1800'],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    time.sleep(.45); mid1=q.shot(f'{mode}-drag-mid-a')
    time.sleep(.35); mid2=q.shot(f'{mode}-drag-mid-b')
    stdout,stderr=process.communicate(timeout=10)
    if process.returncode: raise AssertionError(stderr.decode())
    time.sleep(.5)
    mid_anchors=[garment_line(ocr_image(path),category) if mode=='load' else next((e for e in ocr_image(path) if 'collect wet uniform 01' in e[0].lower()),None) for path in (mid1,mid2)]
    deltas=[abs(entry[1]-anchor[1]) if entry else None for entry in mid_anchors]
    q.STEPS.append({'measurement':f'{mode} garment drag / parent label vertical drift','pixels':deltas,'duration_ms':1800,'from':start,'to':end})
    q.check(all(delta is not None and delta<=2 for delta in deltas),f'{mode} actual Android drag keeps menu label fixed within 2 pixels')
    field='unloaded' if mode=='unload' else 'loaded'
    q.check(q.state()['shift']['uniforms'][0][field],f'{mode} actual drag commits one garment')
    q.shot(f'{mode}-drag-after')
    # A blank-space swipe directly after release must still move the sheet.
    before_blank=q.shot(f'{mode}-blank-before')
    q.scroll_upward(); after_blank=q.shot(f'{mode}-blank-after')
    a0=ocr_image(before_blank); a1=ocr_image(after_blank)
    displacements=[]
    for text,y in a0:
        matches=[yy for tt,yy in a1 if tt==text and len(text)>8]
        if matches: displacements.append(abs(matches[0]-y))
    if max(displacements,default=0)<=12:
        # Labels can be clipped in one frame. Measure the same painted patch instead.
        before_frame=Image.open(before_blank).convert('RGB'); after_frame=Image.open(after_blank).convert('RGB')
        px=int(width*.66); py=int(height*.66); edge=max(16,int(32*scale))
        patch=before_frame.crop((px,py,px+edge,py+edge))
        matches=[]
        for yy in range(int(150*scale),height-edge-30,2):
            candidate=after_frame.crop((px,yy,px+edge,yy+edge))
            error=sum(q.ImageStat.Stat(q.ImageChops.difference(patch,candidate)).mean)/3
            matches.append((error,yy))
        error,yy=min(matches)
        q.STEPS.append({'measurement':f'{mode} blank-scroll painted patch','vertical_drift_pixels':abs(yy-py),'mean_RGB_error':error})
        if error<15: displacements.append(abs(yy-py))
    q.STEPS.append({'measurement':f'{mode} immediate blank-space scrolling','max_label_drift_pixels':max(displacements,default=0)})
    q.check(max(displacements,default=0)>12,f'{mode} blank-space scroll resumes immediately after garment release')
    q.close(); q.hotspot('washer'); evidence('running')


def manual_shift():
    original_click=q.click; original_shot=q.shot
    q.actual_drag_first_load=lambda:measured_drag('load')
    def click(text,**kwargs):
        if text=='Collect wet uniform 01' and not q.state()['shift']['uniforms'][0]['unloaded']:
            measured_drag('unload'); return
        return original_click(text,**kwargs)
    def shot(name=None):
        path=original_shot(name)
        if name=='wage-slip': current_sizes('wage-clipboard')
        return path
    q.click=click; q.shot=shot
    q.laundry()
    q.click=original_click; q.shot=original_shot
    q.checkpoint('laundry'); evidence('running')


def finish_survival_and_known():
    if 'survival' not in q.DONE:
        q.goto('bureau'); q.hotspot('tax'); current_sizes('tax-clipboard'); q.close()
        q.goto('shop'); q.hotspot('food'); q.click('Take Wrapped black')
        q.open_bag_item('Wrapped black bread'); q.click('Unwrap and eat')
        q.goto('room'); q.hotspot('sink'); q.click('Cup your hands')
        q.hotspot('bed'); q.click('Pull the blanket'); q.shot('home-survival-loop')
        q.interruption('survival-loop'); q.checkpoint('survival'); evidence('running')
    if not q.state()['shift']:
        q.goto('laundry'); q.hotspot('cart'); q.click('Pull the cart')
    for index in range(4):
        garment=q.state()['shift']['uniforms'][index]
        if garment['sorted']: continue
        q.close(); q.hotspot('cart'); q.click(f'UNIFORM {index+1:02}')
        if not garment['inspected']: q.click('Unfold and read')
        if not garment['pocket_checked']: q.click('Turn out the')
        garment=q.state()['shift']['uniforms'][index]
        if garment['found'] and next(item for item in q.state()['items'] if item['id']==garment['found'])['owner']=='found':
            q.click('Place in Lost Property'); q.hotspot('cart'); q.click(f'UNIFORM {index+1:02}')
        q.click(garment['type'].upper(),button_only=True)
    q.close(); q.hotspot('washer')
    if not q.state()['shift']['hatch_open']: q.click('Pull the hatch')
    all_text=[]
    for n in range(4):
        all_text.extend(entry[0].lower() for entry in q.lines(6)); q.shot(f'known-work-manual-{n}'); q.scroll_upward()
    q.check(not any('familiar' in text or 'remaining bundle' in text or 'fold the remaining' in text for text in all_text),'known work offers no automatic bundle shortcut')
    q.check(all(not item['loaded'] for item in q.state()['shift']['uniforms']),'experienced worker must still load individual garments')
    q.click('Load uniform 01'); q.interruption('known-partial-load')
    q.check(sum(bool(item['loaded']) for item in q.state()['shift']['uniforms'])==1,'known worker first load is individual and process safe')
    q.checkpoint('known-manual'); evidence('passed')


def run():
    q.adb('shell','settings','put','secure','immersive_mode_confirmations','confirmed')
    resize(360,640); q.launch()
    if 'employment' not in q.DONE: register_and_job()
    if 'laundry' not in q.DONE: manual_shift()
    if 'known-manual' not in q.DONE: finish_survival_and_known()
    logs=q.adb('logcat','-d','-t','2500')
    q.check('SCRIPT ERROR' not in logs and 'Parse Error' not in logs,'Android logs contain no GDScript errors')
    evidence('passed'); print('PASS complete:',OUT/'touch-evidence.json',flush=True)

try: run()
except Exception as error:
    evidence('failed',str(error)); q.shot('FAILED-final'); raise
