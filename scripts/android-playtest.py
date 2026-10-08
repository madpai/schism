#!/usr/bin/env python3
"""Touch/OCR Android loop. Only an explicitly selected emulator; never clears existing saves."""
import argparse,csv,hashlib,io,json,os,re,subprocess,time
from pathlib import Path
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('--device',required=True);p.add_argument('--resume-arrival',action='store_true');p.add_argument('--verify-resume',action='store_true');p.add_argument('--adb',default=os.environ.get('ADB','adb'));p.add_argument('--output',default='docs/playtests/android');args=p.parse_args()
if not args.device.startswith('emulator-'):raise SystemExit('This automated QA script is restricted to an isolated emulator.')
ADB=[args.adb,'-s',args.device];PACKAGE='org.schism.districtix';OUT=Path(args.output);OUT.mkdir(parents=True,exist_ok=True)
scenes=json.loads(Path('mobile/data/scenes.json').read_text())['scenes'];steps=[]
def adb(*a,raw=False):
 r=subprocess.run(ADB+list(a),check=True,capture_output=True)
 return r.stdout if raw else r.stdout.decode().strip()
def state():
 candidates=[]
 for slot in range(2):
  r=subprocess.run(ADB+['exec-out','run-as',PACKAGE,'cat',f'files/residency/slot{slot}.json'],capture_output=True)
  if r.returncode:continue
  try:
   envelope=json.loads(r.stdout);assert hashlib.sha256(envelope['payload'].encode()).hexdigest()==envelope['sha256'];candidates.append(json.loads(envelope['payload']))
  except (ValueError,KeyError,AssertionError):pass
 if not candidates:return None
 return max(candidates,key=lambda x:x['revision'])
def shot(name=None):
 path=OUT/(name+'.png') if name else Path('/tmp/schism-touch.png')
 for attempt in range(40):
  data=adb('exec-out','screencap','-p',raw=True)
  if data.startswith(b'\x89PNG\r\n\x1a\n') and data[-8:-4]==b'IEND':
   frame=Image.open(io.BytesIO(data)).convert('L')
   if frame.getextrema()[1]>16:path.write_bytes(data);return path
  time.sleep(.2)
 raise AssertionError('Android frame stayed blank or incomplete; no image was overwritten')
def lines(mode=3):
 path=shot();r=subprocess.run(['tesseract',str(path),'stdout','--psm',str(mode),'tsv'],capture_output=True,text=True,check=True,env={**os.environ,'OMP_THREAD_LIMIT':'1'});groups={}
 for row in csv.DictReader(io.StringIO(r.stdout),delimiter='\t'):
  if not row.get('text','').strip():continue
  k=(row['block_num'],row['par_num'],row['line_num']);groups.setdefault(k,[]).append(row)
 result=[]
 for rows in groups.values():
  text=' '.join(x['text'] for x in rows);x=min(int(v['left']) for v in rows);y=min(int(v['top']) for v in rows);right=max(int(v['left'])+int(v['width']) for v in rows);bottom=max(int(v['top'])+int(v['height']) for v in rows)
  result.append((text,(x+right)//2,(y+bottom)//2,rows))
 return result
def click(text,scroll=True,button_only=False):
 needle=text.lower()
 for attempt in range(9 if scroll else 8):
  def matches(line):return needle in line[0].lower() and (not button_only or ':' not in line[0])
  found=[line for line in lines() if matches(line)]
  if not found:found=[line for line in lines(6) if matches(line)]
  if found:
   line,_,_,rows=found[-1];start=line.lower().rfind(needle);end=start+len(needle);offset=0;matched=[]
   for word in rows:
    length=len(word['text'])
    if offset<end and offset+length>start:matched.append(word)
    offset+=length+1
   left=min(int(v['left']) for v in matched);right=max(int(v['left'])+int(v['width']) for v in matched)
   top=min(int(v['top']) for v in matched);bottom=max(int(v['top'])+int(v['height']) for v in matched);x=(left+right)//2;y=(top+bottom)//2
   adb('shell','input','tap',str(x),str(y));time.sleep(.13);steps.append({'touch':text,'point':[x,y]});print('TOUCH:',text,flush=True);return
  if scroll:adb('shell','input','swipe','850','1900','850','750','220')
  time.sleep(.4)
 shot('FAILED-'+re.sub(r'\W+','-',text));raise AssertionError(f'Cannot find {text}: {lines()}')
def close():adb('shell','input','keyevent','4');time.sleep(.12)
def hotspot(name):
 s=state(); rect=next(h['rect'] for h in scenes[s['location']]['hotspots'] if h['id']==name)
 # Portrait canvas uses width scaling, expanding logical height.
 raw=adb('shell','wm','size');w,h=map(int,re.findall(r'(\d+)x(\d+)',raw)[-1]);scale=w/480
 x=int((rect[0]+rect[2]/2)*w);y=int(100*scale+(rect[1]+rect[3]/2)*(h-222*scale))
 adb('shell','input','tap',str(x),str(y));time.sleep(.45);steps.append({'hotspot':name,'point':[x,y]});print('OBJECT:',name,flush=True)
def check(ok,label):
 if not ok:shot('FAILED-state');raise AssertionError(label)
 steps.append({'assertion':label,'ok':True});print('PASS:',label,flush=True)
def launch():
 adb('shell','am','start','-n',PACKAGE+'/com.godot.game.GodotAppLauncher')
 for attempt in range(20):
  visible=' '.join(line[0].lower() for line in lines())
  if 'schism' in visible or 'civic' in visible:return
  time.sleep(.3)
 raise AssertionError('Game interface did not appear after Android launch')
def interruption():
 old=state();adb('shell','input','keyevent','3');time.sleep(.3);adb('shell','am','force-stop',PACKAGE);time.sleep(.2);launch();new=state()
 check(old==new,'home + force-stop/relaunch preserves every simulation field; no offline decay')
def laundry(interrupt=False):
 hotspot('cart');click('Pull the cart');shot('garment-cart')
 for n in range(4):
  click(f'UNIFORM {n+1:02}');click('Unfold and read');click('Turn out the')
  u=state()['shift']['uniforms'][n]
  if u['found']:
   shot('found-object');click('Place in Lost Property');hotspot('cart');click(f'UNIFORM {n+1:02}')
  click(u['type'].upper(),button_only=True)
 close();hotspot('washer');click('Pull the hatch');click('Lift the sorted');click('Tip one measured');click('Tip one measured')
 if interrupt:interruption();hotspot('washer');shot('resumed-washer')
 expected={'dirt':'STANDARD','oil':'HOT','blood':'SANITIZE'}[state()['shift']['uniforms'][0]['stain']]
 click(expected,button_only=True);click('Push the hatch');click('Press the green');time.sleep(1.3);click('Open the hatch and');click('Hang the bundle');click('Fold sleeves');click('Place folded');click('Slide your timecard');shot('wage-slip')
 check(state()['last_receipt']['quality']==100 and not state()['shift'],'touch-only laundry completes quality and settlement')
 click('Fold the wage')

installed_path=adb('shell','pm','path',PACKAGE).removeprefix('package:')
installed_sha256=adb('shell','sha256sum',installed_path).split()[0]
initial=state()
if not args.verify_resume and initial and initial['identity']['registered'] and not (args.resume_arrival and not initial['arrival_seen']):raise SystemExit('QA emulator already has a citizen. Use a new isolated AVD; this script never resets saves.')
if not args.verify_resume:
 adb('logcat','-c');launch();shot('arrival')
 if not initial or not initial['identity']['registered']:click('Sign the residency')
 click('Fold the paper')
 check(state()['identity']['registered'] and state()['credits']==4,'arrival identity and 4 CR persist')
 shot('room');hotspot('sink');click('Cup your hands');hotspot('door');hotspot('stairs');shot('street');hotspot('bureau');shot('bureau');hotspot('ticket');click('Put the paper');hotspot('clerk');click('Slide your civic');shot('vacancies');click('Sign Municipal Laundry')
 check(state()['employment']=='laundry','bureau ticket/ID/authorization touch path')
 hotspot('exit');hotspot('laundry');shot('laundry');laundry(True)
 check(state()['credits']==11 and state()['jobs']['laundry']['shifts']==1,'first shift 7 CR paid once')
 hotspot('exit');hotspot('shop');hotspot('food');click('Take Wrapped black');click('Wrapped black');click('Unwrap and eat');hotspot('water');click('Take Bottled water');click('Bottled water');click('Open and drink');hotspot('water');click('Take Municipal soap');close();hotspot('exit');hotspot('hall');hotspot('room');hotspot('sink');click('Wash face');hotspot('bed');click('Pull the blanket');shot('room-after-shift');hotspot('paper');shot('tenancy');close();
 check(state()['credits']==6 and state()['needs']['energy']>95 and state()['needs']['hygiene']>70,'work -> food/water/soap -> home -> sleep loop')
 interruption()
else:
 check(initial and initial['location']=='room' and initial['credits']==6 and initial['jobs']['laundry']['shifts']==1,'completed touch-flow save retained for resolution/resume follow-up')
 launch();interruption()
# Test native Status and retained bag at three phone sizes.
for w,h in [(360,640),(390,844),(1080,2400)]:
 adb('shell','wm','size',f'{w}x{h}');adb('shell','wm','density','160' if w<600 else '420');time.sleep(3);shot(f'room-{w}x{h}')
 # Fixed bottom dock geometry avoids OCR ambiguity at small text sizes. This is a real touch.
 adb('shell','input','tap',str(int(w*.22)),str(int(h-38*w/480)));time.sleep(.6);shot(f'status-{w}x{h}')
 visible=' '.join(line[0].lower() for line in lines())
 check(any(label in visible for label in ['health','energy','hygiene']),f'{w}x{h}: real status overlay displays needs')
 close()
 check(state()['location']=='room',f'{w}x{h}: scene and status usable; state retained')
adb('shell','wm','size','reset');adb('shell','wm','density','reset');time.sleep(2)
logs=adb('logcat','-d','-s','godot','AndroidRuntime');(OUT/'runtime.txt').write_text(logs)
check('SCRIPT ERROR' not in logs and 'FATAL EXCEPTION' not in logs and 'Program linking failed' not in logs,'no native script, Java crash or GLES shader errors')
s=state();(OUT/'touch-evidence.json').write_text(json.dumps({'package':PACKAGE,'apk_sha256':installed_sha256,'device':args.device,'follow_up':args.verify_resume,'platform':'Android API 34 emulator / ANGLE SwiftShader', 'sizes':[{'width':w,'height':h,'density':160 if w<600 else 420} for w,h in [(360,640),(390,844),(1080,2400)]],'steps':steps,'final':{'revision':s['revision'],'location':s['location'],'credits':s['credits'],'needs':s['needs'],'employment':s['employment'],'shifts':s['jobs']['laundry']['shifts'],'receipt':s['last_receipt'],'identity_registered':s['identity']['registered']},'limits':'Not a physical-phone audio, ergonomics or retention test.'},indent=2)+'\n')
print('ANDROID TOUCH LOOP PASSED',flush=True)
