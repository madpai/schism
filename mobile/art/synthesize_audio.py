#!/usr/bin/env python3
"""Original SCHISM audio. No source samples. Deterministic seed; PCM mono/22050Hz."""
from pathlib import Path
import math, random, wave, struct, json, hashlib
OUT=Path(__file__).resolve().parents[1]/'assets/audio'
OUT.mkdir(parents=True,exist_ok=True)
RATE=22050
SCENES={'room':(50,.05,.09),'hall':(50,.08,.03),'street':(35,.04,.23),'bureau':(100,.1,.04),'laundry':(42,.16,.07),'cleaning':(100,.07,.025),'freight':(32,.15,.055),'shop':(50,.07,.09),'camp':(70,.12,.04)}
manifest=[]
def write(name,samples,description):
 path=OUT/(name+'.wav')
 with wave.open(str(path),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
  f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x))*32700)) for x in samples))
 manifest.append({'id':name,'file':str(path.relative_to(OUT.parent.parent)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'license':'Original project asset; repository owner controls distribution','source':'Original deterministic oscillator/noise synthesis; no third-party samples','description':description,'rate':RATE,'duration':len(samples)/RATE})
for n,(hz,volume,rain) in SCENES.items():
 rng=random.Random(48193+sum(map(ord,n)));low=0;s=[]
 for i in range(RATE*8):
  t=i/RATE; noise=rng.uniform(-1,1);low=low*.975+noise*.025
  hum=math.sin(math.tau*hz*t)*volume+math.sin(math.tau*hz*2*t)*volume*.21
  machine=math.sin(math.tau*3*t)*math.sin(math.tau*hz*t)*volume*.08
  s.append(hum+machine+noise*rain*.27+low*rain)
 write(n,s,'Fluorescent/motor harmonics and filtered industrial/rain noise; seamless eight-second loop')
for n in ['door','footsteps','cloth','mop','coin','beep','washer','buzzer','drain']:
 rng=random.Random(48200+sum(map(ord,n)));duration=1.2 if n in ['footsteps','washer','drain'] else .42;s=[];low=0
 for i in range(int(RATE*duration)):
  t=i/RATE;noise=rng.uniform(-1,1);low=low*.9+noise*.1
  if n=='door': x=(math.sin(math.tau*92*t)+noise*.2)*math.exp(-t*15)*.42
  elif n=='footsteps':
   pulse=t%0.36;x=(low*1.3+math.sin(math.tau*80*pulse)*.1)*math.exp(-pulse*38)
  elif n=='coin': x=(math.sin(math.tau*1730*t)+math.sin(math.tau*2620*t)*.5)*math.exp(-t*23)*.2
  elif n=='beep': x=math.sin(math.tau*680*t)*.12 if .015<t<.18 else 0
  elif n=='buzzer':x=(math.sin(math.tau*125*t)+math.sin(math.tau*250*t)*.6)*math.exp(-t*9)*.16
  elif n=='washer': x=(math.sin(math.tau*42*t)*(0.5+0.2*math.sin(math.tau*4*t))+low*.4)*.22*math.sin(math.pi*t/duration)
  elif n=='drain': x=(noise*.1+low*.9)*math.sin(math.pi*t/duration)*.4
  else:x=noise*math.sin(math.pi*t/duration)*(.10 if n=='cloth' else .14)
  s.append(x)
 write(n,s,'Original tactile '+n+' effect')
(Path(__file__).parent/'audio-provenance.json').write_text(json.dumps({'generator':'synthesize_audio.py','seed_family':48193,'assets':manifest},indent=2)+'\n')
