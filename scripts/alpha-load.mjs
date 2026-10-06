// Lab evidence only: built Worker + SQLite adapter, isolated from every real city.
import assert from 'node:assert/strict';
import {performance} from 'node:perf_hooks';
import {writeFile,mkdir} from 'node:fs/promises';
import worker from '../dist/server/index.js';
import {localDB} from './local-db.mjs';
import {defaultAppearance} from '../worker/residency.js';
const db=localDB(),owners=Array.from({length:20},(_,i)=>'isolated-alpha-'+i),latencies=[],statuses=[];
const request=async(owner,path='/api/state',input)=>{
 const started=performance.now(),response=await worker.fetch(new Request('https://city.test'+path,{method:input?'POST':'GET',headers:{'oai-authenticated-user-id':owner,...(input?{'Content-Type':'application/json','Origin':'https://city.test'}:{})},...(input?{body:JSON.stringify(input)}:{})}),{DB:db});
 const data=await response.json();latencies.push(performance.now()-started);statuses.push(response.status);assert.equal(response.status,200,JSON.stringify(data));return data;
};
const began=performance.now();await Promise.all(owners.map(owner=>request(owner)));await Promise.all(owners.map((owner,i)=>request(owner,'/api/action',{action:'register',name:'Lab citizen '+i,appearance:defaultAppearance})));
await new Promise(resolve=>setTimeout(resolve,750));const working=await Promise.all(owners.map(owner=>request(owner,'/api/action',{action:'work',id:'cleaning'})));assert.ok(working.every(s=>s.citizen.activity&&s.citizen.credits===0));
for(let round=0;round<20;round++)await Promise.all(owners.map(owner=>request(owner)));
const sorted=latencies.slice().sort((a,b)=>a-b),percentile=p=>Math.round(sorted[Math.floor((sorted.length-1)*p)]*100)/100;
assert.equal(db.sqlite.prepare('SELECT count(*) n FROM citizens').get().n,20);assert.equal(db.sqlite.prepare('SELECT count(*) n FROM action_guards').get().n,0);
const result={release:'0.10.0',at:new Date().toISOString(),environment:'Node built Worker / in-memory SQLite; not production D1 or internet latency',concurrentCitizens:20,requests:statuses.length,failedRequests:statuses.filter(s=>s!==200).length,elapsedMs:Math.round(performance.now()-began),p50Ms:percentile(.5),p95Ms:percentile(.95),p99Ms:percentile(.99),maxMs:Math.round(sorted.at(-1)*100)/100,deferredWages:true};
await mkdir('.local-data/evidence',{recursive:true,mode:0o700});await writeFile('.local-data/evidence/v010-load.json',JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result,null,2));db.sqlite.close();
