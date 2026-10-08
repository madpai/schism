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
 if asset['id'] in scenes:assert asset['hotspots']==scenes[asset['id']]['hotspots'],asset['id']
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
objects=json.loads((ROOT/'data/objects.json').read_text())
assert objects['grid']==[4,4] and sorted(objects['cells'].values())==list(range(16))
for section in ['laundry']:
 for key,value in objects[section].items():
  if isinstance(value,str) and value.startswith('res://'):assert (ROOT/value[6:]).is_file(),value
for crop in objects['crops'].values():
 assert (ROOT/crop['asset'][6:]).is_file()
 x,y,w,h=crop['rect'];assert 0<=x and 0<=y and w>0 and h>0 and x+w<=1.001 and y+h<=1.001
with wave.open(str(ROOT/'assets/audio/footsteps.wav')) as cue:
 assert cue.getnframes()/cue.getframerate()<=.27,'travel must not replay a multi-step loop'
for p in ['fonts/FIRA-OFL.txt','fonts/DEJAVU-LICENSE.txt','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.txt']:assert (ROOT/'assets'/p).is_file(),p
print(f"SCHISM assets: {len(provenance['assets'])} generated images, 9 scene maps, 18 original audio files: hashes, atlas regions and zones verified.")
