// Deterministic schedules through ordinary registered accounts in isolated SQLite.
// Deadlines advance here, never in the owner's persistent city. No stat fixtures.
import assert from 'node:assert/strict';
import {writeFile,mkdir} from 'node:fs/promises';
import {harness} from './test-harness.mjs';
const definitions=[{id:'daily',visits:1,skips:[]},{id:'twice-daily',visits:2,skips:[]},{id:'each-cycle',visits:4,skips:[]},{id:'missed-weekend',visits:1,skips:[2,3]},{id:'earned-room',visits:4,skips:[],progression:true}],results=[];
for(const def of definitions){
 const h=harness(),owner=def.id;await h.register(owner);await h.start(owner,{action:'tax_reserve',enabled:true});const epoch=h.now,samples=[];let work=0,spent=0,relief=0,returns=0;
 for(let day=0;day<7;day++){
  if(def.skips.includes(day))continue;
  for(let visit=0;visit<def.visits;visit++){
   h.now=epoch+day*86400000+visit*86400000/def.visits;let s=await h.read(owner);const entry={health:Math.round(s.citizen.health),energy:Math.round(s.citizen.energy),food:Math.round(s.citizen.fullness),warmth:Math.round(s.citizen.warmth),credits:s.citizen.credits};
   assert(def.progression||s.citizen.rentDebt===0);assert(def.progression||s.citizen.housing==='bunk');assert(!s.citizen.taxHold);
   if((s.citizen.health<25||s.citizen.fullness<25||s.citizen.warmth<15)&&s.citizen.reliefDay!==s.world.day){s=await h.start(owner,{action:'relief'});relief++;}
   if(!s.living.fireUsed){s=await h.start(owner,{action:'warm_fire'});h.now=s.citizen.errand.endsAt;s=await h.read(owner);}
   const trained=s.jobs.find(j=>j.id==='maintenance'),job=def.progression&&!trained.quotes[0].blocked?trained:s.jobs.find(j=>j.id==='sorting'),quote=job.quotes.find(q=>q.mode==='standard'||q.id==='standard')||job.quotes[0];assert(!quote.blocked,`Return ${day}/${visit} must reopen ordinary factory work: ${quote.blocked}`);
   s=await h.start(owner,{action:'work',id:job.id});const end=s.citizen.activity.endsAt;s=await h.start(owner,{action:'quick',id:'sweep'});h.now=s.citizen.errand.endsAt;await h.read(owner);h.now=end;s=await h.read(owner);work++;assert(!s.citizen.activity);
   if(def.progression){s=await h.start(owner,{action:'work',id:job.id});h.now=s.citizen.activity.endsAt;s=await h.read(owner);work++;}
   const soup=s.goods.find(g=>g.id==='soup');if(s.citizen.credits>=soup.price){spent+=soup.price;s=await h.start(owner,{action:'buy',id:'soup'});}else{const ration=s.goods.find(g=>g.id==='bread');if(s.citizen.credits>=ration.price){spent+=ration.price;s=await h.start(owner,{action:'buy',id:'bread'});s=await h.start(owner,{action:'consume',id:'bread'});}}
   if(def.progression){h.now+=2000;s=await h.read(owner);}
   if(def.progression&&s.citizen.rentDebt&&s.citizen.credits>=s.citizen.rentDebt)s=await h.start(owner,{action:'rent'});
   if(def.progression&&s.citizen.rentDebt)s=await h.start(owner,{action:'return_bunk'});
   if(def.progression&&s.citizen.housing==='bunk'&&s.citizen.credits>=155){s=await h.start(owner,{action:'upgrade'});s=await h.start(owner,{action:'rent_prepay',cycles:4});}
   if(def.progression&&s.citizen.housing==='room'&&s.citizen.finance.rentReserve<40&&s.citizen.credits>=40-s.citizen.finance.rentReserve)s=await h.start(owner,{action:'rent_prepay',cycles:Math.ceil((40-s.citizen.finance.rentReserve)/20)});
   s=await h.start(owner,{action:'rest'});h.now=s.citizen.activity.endsAt;s=await h.read(owner);returns++;
   samples.push({realDay:day+1,visit:visit+1,cityDay:s.world.day,job:job.id,housing:s.citizen.housing,entry,exit:{health:Math.round(s.citizen.health),energy:Math.round(s.citizen.energy),food:Math.round(s.citizen.fullness),warmth:Math.round(s.citizen.warmth),credits:s.citizen.credits,taxHeld:s.citizen.finance.taxReserve,taxDebt:s.citizen.taxDebt},elapsedMinutes:Math.round((h.now-(epoch+day*86400000+visit*86400000/def.visits))/60000)});
  }
 }
 h.now=epoch+7*86400000;const last=await h.read(owner);assert(last.citizen.rentDebt===0&&!last.citizen.evicted&&!last.citizen.taxHold&&last.citizen.taxDebt===0&&last.citizen.finance.taxReserve===0);
 results.push({schedule:def,completedShifts:work,returns,reliefMeals:relief,foodSpending:spent,grossIncome:last.citizen.taxEarned,taxPaid:last.citizen.taxPaid,endingCredits:last.citizen.credits,endingHealth:Math.round(last.citizen.health),endingEnergy:Math.round(last.citizen.energy),housing:last.citizen.housing,rentPaid:last.citizen.finance.rentPaid,rentHeld:last.citizen.finance.rentReserve,rentDebt:last.citizen.rentDebt,taxDebt:last.citizen.taxDebt,samples});
}
const report={mode:'isolated simulated seven real days; ordinary registration/actions; accelerated test deadlines only',policy:'At each scheduled visit: relief if needed, free barrel fire, one 30-minute memory shift (earned-room works two consecutive shifts, choosing unlocked 45-minute lattice work) plus a 20-second terminal task, buy affordable broth/ration, queue 90-minute free sleep. Each cycle starts sleep once. No fixture goods, stat grants, crime, trades, or career switches. Earned-room saves 155 CR before a private deposit/four-cycle prepayment, then funds each rent bill from earned wages.',limitations:['Current-weather settlement applies across each offline interval; future simulation can model historical weather.','Sleep completion is simulated; a person would leave after starting it.','This is a recovery/economy benchmark, not proof of enjoyable real multi-day play.'],results};
const output=process.env.SCHISM_BALANCE_OUTPUT||'docs/playtests/v0.8/balance.json';await mkdir(output.slice(0,output.lastIndexOf('/')),{recursive:true});await writeFile(output,JSON.stringify(report,null,2)+'\n');for(const r of results)console.log(JSON.stringify({schedule:r.schedule.id,shifts:r.completedShifts,gross:r.grossIncome,food:r.foodSpending,tax:r.taxPaid,credits:r.endingCredits,rentDebt:r.rentDebt,taxDebt:r.taxDebt,health:r.endingHealth,housing:r.housing,rentPaid:r.rentPaid}));
