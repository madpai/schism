import assert from 'node:assert/strict';
import {harness} from './test-harness.mjs';
import {act,world} from '../worker/game.js';
import {crimePreparation} from '../worker/life.js';
let checks=0;const check=(ok,label)=>{assert.ok(ok,label);checks++;};
const reject=async(fn,pattern)=>{await assert.rejects(fn,pattern);checks++;};
const quickFinish=async(h,owner)=>{const s=await h.read(owner);h.now=s.citizen.errand.endsAt;return h.read(owner);};
{
 const h=harness();await h.register('nera');let s=await h.read('nera');
 check(s.districtLife.encounters.length===0,'New citizens discover neighborhood stories through their actions');
 await reject(()=>h.start('nera',{action:'district_choice',id:'ration',node:'found',choice:'sell'}),/moved on/);
 s=await h.start('nera',{action:'quick',id:'bins'});check(!s.citizen.district.threads.ration,'Starting a task cannot unlock its encounter early');s=await quickFinish(h,'nera');
 check(s.districtLife.encounters.some(x=>x.id==='ration'&&x.node==='found'),'Completed scavenging uncovers a persisted ration-card encounter');
 const energy=s.citizen.energy;s=await h.start('nera',{action:'district_choice',id:'ration',node:'found',choice:'return'});check(s.citizen.rep===1&&s.citizen.district.contacts.neri===2&&s.citizen.energy>=energy,'Returning the card develops a relationship without an energy charge');
 await reject(()=>h.start('nera',{action:'district_choice',id:'ration',node:'found',choice:'sell'}),/moved on/);
 await reject(()=>h.start('nera',{action:'district_choice',id:'ration',node:'neighbor',choice:'visit'}),/reply/);
 h.now+=60000;await h.patch('nera',{energy:0});s=await h.start('nera',{action:'district_choice',id:'ration',node:'neighbor',choice:'visit'});check(s.citizen.district.flags.boilerContact&&s.citizen.district.threads.ration.node==='done','An exhausted citizen can complete a contact follow-up');
 s=await h.start('nera',{action:'survey',id:'checkpoint'});check(s.districtLife.plan===-.1&&s.citizen.energy<.1,'A free bulletin enables one strategic route without wages or energy');
 await reject(()=>h.start('nera',{action:'survey',id:'checkpoint'}),/already read/);await reject(()=>h.start('nera',{action:'survey',id:'__proto__'}),/bulletin/);
 await reject(()=>h.start('nera',{action:'quick',id:'bins'}),/Need 4 energy/);
 await h.patch('nera',{energy:100,fullness:100,warmth:100,health:100});s=await h.start('nera',{action:'work',id:'cleaning'});await h.start('nera',{action:'survey',id:'boiler'});s=await h.finish('nera');check(s.citizen.district.flags.boilerContact&&s.districtLife.encounters.some(x=>x.id==='shift'),'Work completion preserves contact changes made during the shift and reveals a new encounter');
 const original=crypto.getRandomValues;try{crypto.getRandomValues=a=>{a.fill(Math.floor(.25*4294967296));return a;};s=await h.start('nera',{action:'crime',id:'steal'});check(!s.citizen.district.plan&&s.citizen.activity,'A prepared route is reserved at operation start');s=await h.finish('nera');check(!s.citizen.criminalHold&&s.citizen.scrap===3,'The server applies the reduced capture risk, not a client outcome');}finally{crypto.getRandomValues=original;}
 h.now+=21600000;s=await h.read('nera');check(s.districtLife.plan===0&&s.citizen.district.surveys.length===0&&s.citizen.district.threads.ration.node==='done','Cycle reset refreshes planning without resetting personal stories');
}
{
 const h=harness();await h.fixture('choice',{energy:100,materials:{wire:2,cloth:2,circuit:0,data:0}});await h.start('choice',{action:'quick',id:'bins'});await quickFinish(h,'choice');h.now+=1000;
 const race=await Promise.allSettled([act(h.db,'choice',{action:'district_choice',id:'ration',node:'found',choice:'sell'},h.now),act(h.db,'choice',{action:'district_choice',id:'ration',node:'found',choice:'return'},h.now)]);
 check(race.filter(x=>x.status==='fulfilled').length===1,'Competing encounter choices resolve once');check((await h.read('choice')).citizen.district.decisions.length===1,'A resolved encounter has one durable decision');
}
{
 const h=harness();await h.fixture('buyer',{credits:100,energy:100,fullness:100,warmth:100});await h.fixture('supplier',{credits:9,materials:{wire:4,cloth:0,circuit:0,data:0}});
 let s=await h.start('buyer',{action:'order_create',item:'wire',quantity:3,price:5}),order=s.supplyExchange.orders.find(x=>x.buyer===s.citizen.id);check(s.citizen.credits===85&&order.remaining===3,'A buy order escrows the complete payment upfront');
 await reject(()=>h.start('buyer',{action:'order_fill',id:order.id,quantity:1}),/own order/);await reject(()=>h.start('supplier',{action:'order_cancel',id:order.id}),/Only the buyer/);
 s=await h.start('supplier',{action:'order_fill',id:order.id,quantity:2});check(s.citizen.credits===19&&s.citizen.materials.wire===2&&s.citizen.taxDebt===1,'Delivery removes exact stock and credits taxable payment');
 s=await h.read('buyer');check(s.citizen.materials.wire===2&&s.supplyExchange.orders.find(x=>x.id===order.id).remaining===1,'Partial delivery reaches the buyer and reduces the remaining request');s=await h.start('buyer',{action:'order_cancel',id:order.id});check(s.citizen.credits===90&&s.citizen.materials.wire===2,'Cancellation refunds only undelivered payment');
 await reject(()=>h.start('supplier',{action:'order_fill',id:order.id,quantity:1}),/closed/);
 for(const [key,value] of [['quantity',0],['quantity',11],['quantity',1.5],['price',0],['price',51],['price',1.5],['item','constructor']])await reject(()=>h.start('buyer',{action:'order_create',item:'wire',quantity:1,price:2,[key]:value}));
 await reject(()=>h.start('buyer',{action:'order_create',item:'wire',quantity:10,price:50}),/Reserve/);
 s=await h.start('buyer',{action:'work',id:'cleaning'});const pay=s.citizen.activity.deltas.credits;s=await h.start('buyer',{action:'order_create',item:'wire',quantity:1,price:2});order=s.supplyExchange.orders.find(x=>x.buyer===s.citizen.id);const balance=s.citizen.credits;
 await h.start('supplier',{action:'order_fill',id:order.id,quantity:1});s=await h.finish('buyer');check(s.citizen.credits===balance+pay&&s.citizen.materials.wire===3,'Incoming supply delivery and escrow survive deferred wage settlement');
 s=await h.start('buyer',{action:'order_create',item:'heatpack',quantity:1,price:1});const own=s.supplyExchange.orders.find(x=>x.buyer===s.citizen.id);
 const insert=h.db.sqlite.prepare('INSERT INTO supply_orders (id,buyer,item,price,remaining,quantity,status,day,created) VALUES (?,?,?,1,1,1,0,?,?)');for(let i=0;i<55;i++)insert.run('other-'+i,(await h.read('supplier')).citizen.id,'cloth',s.world.day,h.now+i+10000);
 check((await h.read('buyer')).supplyExchange.orders.some(x=>x.id===own.id),'A buyer can still cancel old own orders in a busy exchange');
 check(h.db.sqlite.prepare('SELECT count(*) n FROM action_guards').get().n===0,'Order guards are cleaned up');
}
{
 const h=harness();await h.fixture('buyer',{credits:30});await h.fixture('a',{credits:5,materials:{wire:1}});await h.fixture('b',{credits:5,materials:{wire:1}});let s=await h.start('buyer',{action:'order_create',item:'wire',quantity:1,price:10}),offer=s.supplyExchange.orders.find(o=>o.buyer===s.citizen.id);h.now+=1000;
 const race=await Promise.allSettled(['a','b'].map(owner=>act(h.db,owner,{action:'order_fill',id:offer.id,quantity:1},h.now)));check(race.filter(x=>x.status==='fulfilled').length===1,'Only one supplier can take the last escrowed unit');
 check((await h.read('buyer')).citizen.materials.wire===1,'A contested request delivers once');const actors=await Promise.all(['a','b'].map(o=>h.read(o)));check(actors.reduce((n,s)=>n+s.citizen.credits,0)===20&&actors.reduce((n,s)=>n+s.citizen.materials.wire,0)===1,'Losing delivery rolls back inventory and payment');
}
{
 const h=harness();await h.fixture('buyer',{credits:30});await h.fixture('seller',{credits:5,materials:{wire:1}});let s=await h.start('buyer',{action:'order_create',item:'wire',quantity:1,price:10}),offer=s.supplyExchange.orders.find(o=>o.buyer===s.citizen.id);h.now+=1000;
 const race=await Promise.allSettled([act(h.db,'buyer',{action:'order_cancel',id:offer.id},h.now),act(h.db,'seller',{action:'order_fill',id:offer.id,quantity:1},h.now)]);check(race.filter(x=>x.status==='fulfilled').length===1,'Cancellation and delivery cannot both claim held money');const buyer=await h.read('buyer'),seller=await h.read('seller');check(buyer.citizen.credits+seller.citizen.credits===35,'Cancellation/delivery race conserves credits');check(buyer.citizen.materials.wire+seller.citizen.materials.wire===1,'Cancellation/delivery race conserves goods');
}
{
 const h=harness();await h.fixture('maker',{credits:0,energy:0,materials:{wire:3},bandage:1});let s=await h.read('maker'),offer=s.supplyExchange.orders.find(x=>x.buyer===null&&x.item==='wire');const remaining=offer.remaining;await reject(()=>h.start('maker',{action:'order_fill',id:offer.id,quantity:2}),/one unit/);
 s=await h.start('maker',{action:'order_fill',id:offer.id,quantity:1});check(s.citizen.credits===2&&s.citizen.energy<.1,'An exhausted maker can fulfill existing demand without energy');await reject(()=>h.start('maker',{action:'order_fill',id:offer.id,quantity:1}),/One municipal/);
 for(let i=0;i<4;i++)await h.read('maker');check((await h.read('maker')).supplyExchange.orders.find(x=>x.id===offer.id).remaining===remaining-1,'State reads never refill municipal demand');h.now+=21600000;
 await reject(()=>h.start('maker',{action:'order_fill',id:offer.id,quantity:1}),/earlier cycle|closed/);s=await h.read('maker');check(s.supplyExchange.municipalUsed===0,'Municipal delivery quota refreshes on the shared cycle');
}
{
 const h=harness();h.now=Date.UTC(2026,9,5,0,20);await h.fixture('crew',{credits:0,energy:100,fullness:100,warmth:100,materials:{wire:3,data:2},heatpack:2});await h.fixture('observer');let s=await h.read('crew'),crisis=s.cityLife.crisis.current;
 check(crisis.phase==='warning'&&crisis.target===3,'An emergency opens with a readable warning and a quiet-city target');
 s=await h.start('crew',{action:'crisis_response',id:'crew',crisis:crisis.id});check(s.citizen.materials.wire===2&&s.citizen.credits===0&&s.cityLife.crisis.current.progress===0,'Emergency response reserves materials and defers public and personal effects');
 h.now=s.citizen.errand.endsAt;s=await h.read('observer');check(s.cityLife.crisis.current.progress===2,'The district sees completed commitments without the worker returning');s=await h.read('crew');check(s.citizen.credits===2&&s.citizen.rep===1,'Worker receives the reserved response payout once');
 s=await h.start('crew',{action:'crisis_response',id:'donate',crisis:crisis.id});s=await quickFinish(h,'crew');check(s.cityLife.crisis.current.progress===3&&s.citizen.heatpack===1,'A supplied warming pack reaches the repair target');await reject(()=>h.start('crew',{action:'crisis_response',id:'donate',crisis:crisis.id}),/Two direct/);
 h.now=crisis.warningUntil;s=await h.read('observer');check(s.cityLife.crisis.current.phase==='stabilizing','A repaired warning becomes a protected stabilization phase');
 await h.fixture('diverter',{credits:0,energy:100,materials:{data:2}});s=await h.start('diverter',{action:'crisis_response',id:'divert',crisis:crisis.id});s=await quickFinish(h,'diverter');check(s.cityLife.crisis.current.progress===1&&s.cityLife.crisis.current.phase==='active'&&s.citizen.taxEarned===0&&s.citizen.heat>5,'A criminal diversion lowers the same emergency progress and pays unreported income');
 await h.fixture('guard',{security:true,energy:100,fullness:100,warmth:100});await h.start('guard',{action:'case_review',id:'security'});s=await h.start('guard',{action:'career_case',id:'security',choice:'evidence'});s=await quickFinish(h,'guard');check(s.cityLife.crisis.current.progress>=crisis.target,'Security’s evidence escort directly supports the district response');
 h.now=crisis.deadline;s=await h.read('observer');check(s.cityLife.crisis.current.outcome==='secured','The authoritative deadline seals a successful outcome');const finalProgress=s.cityLife.crisis.current.progress;await reject(()=>h.start('crew',{action:'crisis_response',id:'crew',crisis:crisis.id}),/deadline/);
 h.now+=21600000;s=await h.read('observer');check(s.cityLife.crisis.history.some(x=>x.id===crisis.id&&x.outcome==='secured'&&x.repair-x.diversion===finalProgress),'Later arrivals see the completed emergency record');
}
{
 const h=harness();h.now=Date.UTC(2026,9,5,0,20);await h.fixture('idle');let s=await h.read('idle'),x=s.cityLife.crisis.current;h.now=x.deadline-30000;
 await h.patch('idle',{energy:100,materials:{wire:2}});await reject(()=>h.start('idle',{action:'crisis_response',id:'crew',crisis:x.id}),/deadline/);h.now=x.deadline;s=await h.read('idle');check(s.cityLife.crisis.current.outcome==='failed'&&s.world.coldModifier===1,'Neglect produces a recorded failure and shared cold penalty');
 h.now=x.deadline+1000;check((await h.read('idle')).cityLife.crisis.current.progress===0,'Outcome reads do not create repair units');
}
{
 const h=harness();await h.fixture('novice',{energy:100,materials:{data:2}});await reject(()=>h.start('novice',{action:'case_review',id:'administration'}),/Earn access/);await reject(()=>h.start('novice',{action:'career_case',id:'security',choice:'evidence'}),/Earn access/);
 await h.fixture('clerk',{credits:0,official:true,energy:100,fullness:100,warmth:100});await reject(()=>h.start('clerk',{action:'career_case',id:'administration',choice:'verify'}),/Review/);let s=await h.start('clerk',{action:'case_review',id:'administration'});check(s.citizen.energy===100&&s.citizen.district.cases.administration.status==='reviewed','Reviewing an earned desk file is useful without energy');s=await h.start('clerk',{action:'career_case',id:'administration',choice:'verify'});check(s.citizen.credits===0&&s.citizen.errand,'Career choices reserve a real short assignment');s=await quickFinish(h,'clerk');check(s.citizen.credits===3&&s.citizen.taxEarned===3&&s.citizen.district.cases.administration.status==='closed','Verified permit pays taxable wages and records the chosen outcome');await reject(()=>h.start('clerk',{action:'case_review',id:'administration'}),/One case/);
 await h.fixture('corrupt',{credits:0,official:true,energy:100});await h.start('corrupt',{action:'case_review',id:'administration'});await h.start('corrupt',{action:'career_case',id:'administration',choice:'stamp'});s=await quickFinish(h,'corrupt');check(s.citizen.credits===5&&s.citizen.taxEarned===0&&s.citizen.heat>4&&s.citizen.alignment<0,'An illicit desk choice trades a larger immediate reward for heat and Chaos');
 await h.fixture('held',{official:true,taxHold:true,taxDebt:1,energy:100});await reject(()=>h.start('held',{action:'case_review',id:'administration'}),/Earn access/);
 await h.fixture('shop',{business:true,credits:0,heatpack:2,energy:100,fullness:100,warmth:100});await h.start('shop',{action:'case_review',id:'shop'});await h.start('shop',{action:'career_case',id:'shop',choice:'crew'});s=await quickFinish(h,'shop');check(s.citizen.heatpack===1&&s.citizen.credits===4,'A licensed shop can direct crafted stock to a civic customer');s=await h.start('shop',{action:'business_work',id:'heatpack'});check(s.citizen.heatpack===0&&s.citizen.credits===4,'Selected shop stock is held at opening');s=await h.finish('shop');check(s.citizen.credits===10,'Chosen crafted stock pays on the long shop deadline');
 await h.fixture('rook',{energy:100,credits:0,criminal:{xp:3,attempts:0,successes:0,day:world(h.now).day,count:0},materials:{data:2}});await h.start('rook',{action:'case_review',id:'underground'});await h.start('rook',{action:'career_case',id:'underground',choice:'divert'});s=await quickFinish(h,'rook');check(s.citizen.criminal.xp===4&&s.citizen.credits===5,'A prepared underground delivery develops its own reputation');const credits=s.citizen.credits;await h.read('rook');check((await h.read('rook')).citizen.credits===credits,'A completed case cannot pay twice');
 check(h.db.sqlite.prepare('SELECT count(*) n FROM action_guards').get().n===0,'New assignment guards leave no residue');
}
{
 const h=harness();await h.register('returning');const joined=(await h.read('returning')).citizen.joined;
 let s=await h.start('returning',{action:'work',id:'cleaning'});s=await h.finish('returning');const bank=s.citizen.credits;
 h.now=joined+24*3600000;s=await h.read('returning');check(s.citizen.credits===bank&&!s.citizen.evicted&&s.citizen.rentDebt===0,'A real-day return preserves earned money and the rent-free basic bunk');
 check(s.districtLife.encounters.some(x=>x.id==='shift'),'Completed work leaves a message for the returning citizen');
 s=await h.start('returning',{action:'relief'});check(s.citizen.health>=25&&s.citizen.fullness>=24&&s.citizen.energy>=20,'A broke return has a real recovery path through existing relief');
 const quote=s.jobs.find(j=>j.id==='cleaning').quotes[0];check(!quote.blocked,'Public custodial wages remain available after an absence');s=await h.start('returning',{action:'work',id:'cleaning'});s=await h.finish('returning');check(s.citizen.credits===bank+quote.pay,'A returning citizen can complete another paid shift without a reset or grant');
}
console.log(`Passed ${checks} district checks: action encounters, zero-energy planning, prepared crime, escrow/partial/cancel races, municipal demand, phased emergencies, deferred career cases, shop stock, legacy survival, and cycle boundaries.`);
