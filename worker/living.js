import {quickBlocked} from './street.js';
const livingNeed=(ok,message)=>{if(!ok)throw Object.assign(new Error(message),{status:400});};
const LIVING_CYCLE_MS=21600000;
export const housingTypes={
 bunk:{name:'Municipal bunkhouse',rent:0,cold:1.5,sleepRate:5,sleepBonus:8,warmth:0,health:8,art:'bunkhouse',description:'A free steel bunk, a thin blanket, and a broken radiator. Sleep restores energy; the building provides no warmth.'},
 street:{name:'Cardboard under the rainline',rent:0,cold:3,sleepRate:4,sleepBonus:6,warmth:0,health:4,art:'barrel-fire',description:'No rent, no privacy, and no insulation. The barrel fire offers a little warmth once per cycle. The free bunkhouse is always open.'},
 room:{name:'Private room',rent:20,cold:.5,sleepRate:6,sleepBonus:16,warmth:32,health:8,art:'housing',description:'A locked door and a working radiator. Twenty credits per cycle; unused prepaid funds can be reclaimed.'},
 flat:{name:'Heated apartment',rent:32,cold:.25,sleepRate:7,sleepBonus:20,warmth:40,health:10,art:'housing',description:'Reliable heat and better rest above the rainline. Thirty-two credits per cycle; absence never adds more than four unpaid bills.'},
};
export function livingState(p,now){
 p.finance??={};p.finance.taxAuto??=false;p.finance.taxReserve??=0;p.finance.rentReserve??=0;p.finance.rentPaid??=0;
 p.clothingWear??=0;p.fireDay??=0;
 if(!p.housingVersion){
  const oldFree=p.housing==='bunk'||p.housing==='street'&&(p.rentDebt||0)<=48;
  if(oldFree){p.housingReform={at:now,waived:p.rentDebt||0};p.rentDebt=0;p.rentCycles=0;p.evicted=false;p.housing='bunk';}
  p.rentTier=p.housing==='flat'?'flat':p.housing==='room'?'room':p.housing==='street'?(p.rentDebt>80?'flat':'room'):'bunk';
  p.housingVersion=1;
 }
 return p;
}
export function livingCold(p){return housingTypes[p.housing]?.cold??housingTypes.bunk.cold;}
export function livingSleep(p){return housingTypes[p.housing]||housingTypes.bunk;}
export function settleBills(p,now){
 if(now>=p.nextRentAt){
  const bills=Math.floor((now-p.nextRentAt)/LIVING_CYCLE_MS)+1,cost=housingTypes[p.housing]?.rent||0;
  if(cost){
   const paid=Math.min(bills,Math.floor(p.finance.rentReserve/cost));p.finance.rentReserve-=paid*cost;p.finance.rentPaid+=paid*cost;
   const charged=Math.min(bills-paid,Math.max(0,4-p.rentCycles));p.rentDebt+=charged*cost;p.rentCycles+=charged;
   if(p.rentCycles>=4){p.rentTier=p.housing;p.housing='street';p.evicted=true;}
  }
  p.nextRentAt+=bills*LIVING_CYCLE_MS;
 }
 if(now>=p.taxDeadline){
  if(p.finance.taxAuto){const paid=Math.min(p.taxDebt,p.finance.taxReserve);p.finance.taxReserve-=paid;p.taxDebt-=paid;p.taxPaid+=paid;}
  if(p.taxDebt>0)p.taxHold=true;
  else p.taxDeadline+=(Math.floor((now-p.taxDeadline)/LIVING_CYCLE_MS)+1)*LIVING_CYCLE_MS;
 }
}
export function livingAction(p,input,w){
 if(input.action==='tax_reserve'){
  livingNeed(typeof input.enabled==='boolean','Choose whether Revenue should reserve tax.');p.finance.taxAuto=input.enabled;
  if(input.enabled){const held=Math.min(p.credits,Math.max(0,p.taxDebt-p.finance.taxReserve));p.credits-=held;p.finance.taxReserve+=held;return 'Tax reserve enabled. Reported earnings reserve assessed tax; Revenue pays it at the deadline. Existing ID holds still need clearance.';}
  const refund=p.finance.taxReserve;p.credits+=refund;p.finance.taxReserve=0;return `Tax reserve disabled. ${refund} reserved credits returned. You must pay future tax yourself.`;
 }
 if(input.action==='rent_prepay'){
  const cost=housingTypes[p.housing].rent;livingNeed(cost>0,'The municipal bunkhouse and street have no rent.');livingNeed(!p.rentDebt,'Settle existing rent arrears before prepaying.');livingNeed(Number.isInteger(input.cycles)&&input.cycles>=1&&input.cycles<=8,'Prepay 1–8 six-hour cycles.');const amount=cost*input.cycles;
  livingNeed(p.finance.rentReserve+amount<=cost*8,'Keep at most eight rent cycles prepaid.');livingNeed(p.credits>=amount,`Need ${amount} credits to prepay these cycles.`);p.credits-=amount;p.finance.rentReserve+=amount;return `${amount} credits reserved for future rent. Bills consume prepaid funds at the normal deadline, without requiring you to return.`;
 }
 if(input.action==='rent_reclaim'){livingNeed(p.finance.rentReserve>0,'There are no unused prepaid funds.');const amount=p.finance.rentReserve;p.finance.rentReserve=0;p.credits+=amount;return `${amount} unused rent credits returned. Future paid-housing bills still apply.`;}
 if(input.action==='return_bunk'||input.action==='sleep_street'){
  livingNeed(!p.activity&&!p.errand,'Finish your assignment before changing where you sleep.');const next=input.action==='return_bunk'?'bunk':'street';livingNeed(p.housing!==next,'You already sleep here.');
  const refund=p.finance.rentReserve;p.credits+=refund;p.finance.rentReserve=0;p.housing=next;p.evicted=false;p.nextRentAt=w.now+LIVING_CYCLE_MS;
  return `${next==='bunk'?'You return to the free municipal bunkhouse. No heat, no rent.':'You lay cardboard beneath the rainline. The free bunkhouse remains available.'}${refund?` ${refund} unused prepaid credits returned.`:''}${p.rentDebt?' Previous private-housing arrears remain, but they do not block the free bunk.':''}`;
 }
 livingNeed(false,'Unknown housing or reserve action.');
}
export function startLivingTask(p,input,w){
 if(input.action==='warm_fire'){
  livingNeed(!p.activity&&!p.errand,'Leave the barrel fire until your assignment is over.');livingNeed(p.fireDay!==w.day,'One warm-up at the barrel fire per cycle.');p.fireDay=w.day;
  p.errand={action:'warm_fire',id:'fire',label:'Warm your hands at the barrel fire',art:'barrel-fire',started:w.now,endsAt:w.now+45000,reward:{warmth:12},message:'A little fire under the viaduct. Twelve warmth; no food, credits, or restored housing.'};
  return {message:'Warming up for 45 seconds. No energy cost; once per cycle.',metrics:{},endsAt:p.errand.endsAt};
 }
 const effort=p.district?.flags.mendingLesson?2:3,blocked=quickBlocked(p,{energy:effort,cost:{cloth:1},break:true},w.now);livingNeed(!blocked,blocked);livingNeed(p.clothingWear>0,'Your clothing has no recorded wear.');p.materials.cloth--;p.energy-=effort;p.street.count++;
 p.errand={action:'mend_clothes',id:'mend',label:'Mend your worn jacket',art:'workshop',started:w.now,endsAt:w.now+30000,reward:{},message:'You mend the seams and clean the worst stains. Clothing wear reduced by 40; appearance only.'};return {message:`Mending for 30 seconds; ${effort} energy and one fabric. Cosmetic wear only.`,metrics:{},endsAt:p.errand.endsAt};
}
export function livingSnapshot(p,w){const spec=housingTypes[p.housing]||housingTypes.bunk;return {types:housingTypes,current:spec,prepaidCycles:spec.rent?Math.floor(p.finance.rentReserve/spec.rent):0,fireUsed:p.fireDay===w.day,freeRecovery:true};}

// Listing proceeds can reach a seller who is offline or in a shift. Reserve tax in
// the same SQL payment, without replacing their finance or inventory object.
export function reportedPaymentStatement(db,citizen,gross){
 const earned="CAST((coalesce(json_extract(data,'$.taxRemainder'),0)+gross*12)/100 AS INTEGER)",held=`CASE WHEN json_extract(data,'$.finance.taxAuto')=1 THEN ${earned} ELSE 0 END`;
 return db.prepare(`WITH pay(gross) AS (VALUES (?)) UPDATE citizens SET data=(SELECT json_set(data,'$.credits',coalesce(json_extract(data,'$.credits'),0)+gross-(${held}),'$.taxEarned',coalesce(json_extract(data,'$.taxEarned'),0)+gross,'$.taxDebt',coalesce(json_extract(data,'$.taxDebt'),0)+${earned},'$.taxRemainder',(coalesce(json_extract(data,'$.taxRemainder'),0)+gross*12)%100,'$.finance.taxReserve',coalesce(json_extract(data,'$.finance.taxReserve'),0)+(${held})) FROM pay),version=version+1 WHERE id=?`).bind(gross,citizen);
}
