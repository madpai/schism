#!/usr/bin/env python3
"""Validate committed provenance, imports, scenes and mobile target geometry."""
import hashlib,json,wave,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
scenes=json.loads((ROOT/'data/scenes.json').read_text())['scenes']
provenance=json.loads((ROOT/'art/provenance.json').read_text())
for asset in provenance['assets']:
 p=ROOT/asset['file'];prompt=ROOT/asset['prompt']
 assert hashlib.sha256(p.read_bytes()).hexdigest()==asset['sha256'],p
 assert hashlib.sha256(prompt.read_bytes()).hexdigest()==asset['prompt_sha256'],prompt
 assert list(struct.unpack('>II',p.read_bytes()[16:24]))==asset['dimensions'],p
 for reference in asset.get('references',[]):
  assert hashlib.sha256((ROOT/reference['file']).read_bytes()).hexdigest()==reference['sha256'],reference
 if asset['id'] in scenes:
  # Living City adds authored targets; original scene targets remain intact.
  for hotspot in asset['hotspots']:assert hotspot in scenes[asset['id']]['hotspots'],(asset['id'],hotspot)
for name,scene in scenes.items():
 assert (ROOT/'assets/scenes'/scene['asset']).exists(),name
 ids=set()
 for h in scene['hotspots']:
  assert h['id'] not in ids;ids.add(h['id'])
  x,y,w,height=h['rect'];assert 0<=x<1 and 0<=y<1 and w>0 and height>0 and x+w<=1.0001 and y+height<=1.0001,(name,h)
 assert (ROOT/'assets/audio'/(scene['audio']+'.wav')).exists(),name
for asset in json.loads((ROOT/'art/audio-provenance.json').read_text())['assets']:
 p=ROOT/asset['file'];assert hashlib.sha256(p.read_bytes()).hexdigest()==asset['sha256'],p
 with wave.open(str(p)) as w:assert w.getnchannels()==1 and w.getframerate()==22050 and w.getsampwidth()==2
living=json.loads((ROOT/'art/living-city-provenance.json').read_text())
for asset in living['assets']:
 for key in ['file','prompt']:
  assert hashlib.sha256((ROOT/asset[key]).read_bytes()).hexdigest()==asset['sha256' if key=='file' else 'prompt_sha256'],asset[key]
 for reference in asset['references']:
  assert hashlib.sha256((ROOT/reference['file']).read_bytes()).hexdigest()==reference['sha256'],reference
for path,digest in living['authored_maps'].items():
 assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,path
objects=json.loads((ROOT/'data/objects.json').read_text())
assert objects['grid']==[4,4] and sorted(objects['cells'].values())==list(range(16))
# Inspect actual alpha inside individually authored source regions, not inferred grid cells.
from PIL import Image
from collections import deque
atlas=Image.open(ROOT/objects['atlas'][6:]).convert('RGBA')
cutoff=objects['alpha_cutoff']
assert cutoff==16 and set(objects['regions'])==set(objects['cells'])
for kind,rect in objects['regions'].items():
 x,y,w,h=rect;assert all(isinstance(v,int) for v in rect)
 assert 0<=x and 0<=y and x+w<=atlas.width and y+h<=atlas.height,kind
 alpha=atlas.crop((x,y,x+w,y+h)).getchannel('A')
 visible=alpha.point(lambda value:255 if value>cutoff else 0)
 bounds=visible.getbbox();assert bounds is not None,kind
 left,top,right,bottom=bounds
 assert min(left,top,w-right,h-bottom)>=8,('missing alpha gutter',kind,bounds)
 pixels=visible.tobytes();seen=bytearray(w*h);components=[]
 for start,value in enumerate(pixels):
  if not value or seen[start]:continue
  queue=deque([start]);seen[start]=1;count=0
  while queue:
   index=queue.popleft();px=index%w;py=index//w;count+=1
   for near in (index-1 if px else -1,index+1 if px<w-1 else -1,index-w if py else -1,index+w if py<h-1 else -1):
    if near>=0 and not seen[near] and pixels[near]:seen[near]=1;queue.append(near)
  components.append(count)
 assert sum(components)-max(components)<100,('unrelated silhouette fragment',kind,components)
for section in ['laundry']:
 for key,value in objects[section].items():
  if isinstance(value,str) and value.startswith('res://'):assert (ROOT/value[6:]).is_file(),value
for crop in objects['crops'].values():
 assert (ROOT/crop['asset'][6:]).is_file()
 x,y,w,h=crop['rect'];assert 0<=x and 0<=y and w>0 and h>0 and x+w<=1.001 and y+h<=1.001
with wave.open(str(ROOT/'assets/audio/footsteps.wav')) as cue:
 assert cue.getnframes()/cue.getframerate()<=.27,'travel must not replay a multi-step loop'
for p in ['fonts/FIRA-OFL.txt','fonts/DEJAVU-LICENSE.txt','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.txt']:assert (ROOT/'assets'/p).is_file(),p
print(f"SCHISM assets: {len(provenance['assets'])+len(living['assets'])} generated images, 10 scene maps, 18 original audio files: hashes, atlas regions and zones verified.")
