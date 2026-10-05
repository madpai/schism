import {snapshot,act,initial} from '../worker/game.js';
import {defaultAppearance} from '../worker/residency.js';
import {localDB} from './local-db.mjs';
export function harness(){
 const db=localDB();let now=Date.UTC(2026,9,5,1);const fixtures=new Set();
 const read=owner=>snapshot(db,owner,now);
 const fixture=async(owner,values={})=>{
   await read(owner);
   if(!fixtures.has(owner)){db.sqlite.prepare('UPDATE citizens SET data=? WHERE owner=?').run(JSON.stringify({...initial(now),registered:true,credits:9,rentDebt:12,rentCycles:1,...values}),owner);fixtures.add(owner);}
   else await patch(owner,values);
   return read(owner);
 };
 const patch=async(owner,values)=>{const s=await read(owner);db.sqlite.prepare('UPDATE citizens SET data=? WHERE owner=?').run(JSON.stringify({...s.citizen,...values}),owner);return read(owner);};
 const start=async(owner,input)=>{now+=1000;return act(db,owner,input,now);};
 const finish=async owner=>{const s=await read(owner);if(s.citizen.activity)now=Math.max(now,s.citizen.activity.endsAt);return read(owner);};
 const action=async(owner,input)=>{const s=await start(owner,input);return s.citizen.activity?finish(owner):s;};
 const register=async(owner,name=owner)=>start(owner,{action:'register',name,appearance:defaultAppearance});
 return {db,read,fixture,patch,start,finish,action,register,get now(){return now;},set now(t){now=t;}};
}
