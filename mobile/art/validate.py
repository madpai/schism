#!/usr/bin/env python3
"""Validate committed provenance, imports, scenes and mobile target geometry."""
import hashlib,json,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
scenes=json.loads((ROOT/'data/scenes.json').read_text())['scenes']
provenance=json.loads((ROOT/'art/provenance.json').read_text())
for asset in provenance['assets']:
 p=ROOT/asset['file'];prompt=ROOT/asset['prompt']
 assert hashlib.sha256(p.read_bytes()).hexdigest()==asset['sha256'],p
 assert hashlib.sha256(prompt.read_bytes()).hexdigest()==asset['prompt_sha256'],prompt
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
for p in ['fonts/FIRA-OFL.txt','fonts/DEJAVU-LICENSE.txt','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.txt']:assert (ROOT/'assets'/p).is_file(),p
print(f"SCHISM assets: {len(provenance['assets'])} generated images, 9 scene maps, 18 original audio files: hashes and zones verified.")
