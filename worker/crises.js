import {quickBlocked} from './street.js';
import {supplyCount,changeSupply} from './orders.js';
const crisisNeed=(ok,message)=>{if(!ok)throw Object.assign(new Error(message),{status:400});};
export const crisisTypes={
 boiler:{name:'The cold line',art:'housing',cause:'A neglected boiler line is losing pressure. Ordinary heating repairs, relief deliveries, and patrol escorts help. Criminal diversions remove repair stock.',activeEffect:'Cold exposure +0.5 per city hour while the repair response is below target.',need:'Repair units',success:'Boiler pressure holds. Cold exposure −0.5 per city hour until the cycle ends.',failure:'The cold line fails. Cold exposure +1 per city hour until the cycle ends.',supply:'heatpack'},
 freight:{name:'The relief convoy',art:'transit',cause:'The relief train is held behind a disputed manifest. Freight work and verified permits help. Criminal diversions send crates out of the public count.',activeEffect:'Food prices +1 CR while the freight response is below target.',need:'Freight units',success:'The convoy clears. Food prices −1 CR until the cycle ends.',failure:'The convoy turns back. Food prices +1 CR until the cycle ends.',supply:'wire'},
};
async function crisisTotals(db,id,until){return db.prepare('SELECT coalesce(sum(repair),0) repair,coalesce(sum(diversion),0) diversion,count(DISTINCT citizen) contributors FROM crisis_actions WHERE crisis=? AND completes<=?').bind(id,until).first();}
export async function districtCrisis(db,w,population){
 const begin=Math.floor(w.now/21600000)*21600000,type=w.day%2?'boiler':'freight',id='district-'+w.day;
 // Freeze the requirement at creation, bounded for quiet and populated cities.
 const workers=await db.prepare('SELECT count(DISTINCT citizen) n FROM city_activity WHERE completes>? AND completes<=?').bind(w.now-21600000,w.now).first();
 const target=Math.max(3,Math.min(12,Math.ceil((workers.n||0)*1.5)));
 await db.prepare('INSERT OR IGNORE INTO district_crises (id,day,type,started,deadline,target,outcome,repair,diversion) VALUES (?,?,?,?,?,?,NULL,0,0)').bind(id,w.day,type,begin,begin+18000000,target).run();
 const overdue=(await db.prepare('SELECT * FROM district_crises WHERE outcome IS NULL AND deadline<=? ORDER BY deadline LIMIT 32').bind(w.now).all()).results;
 for(const row of overdue){const sum=await crisisTotals(db,row.id,row.deadline);await db.prepare('UPDATE district_crises SET outcome=?,repair=?,diversion=? WHERE id=? AND outcome IS NULL').bind(sum.repair-sum.diversion>=row.target?'secured':'failed',sum.repair,sum.diversion,row.id).run();}
 const row=await db.prepare('SELECT * FROM district_crises WHERE id=?').bind(id).first(),sum=row.outcome?{repair:row.repair,diversion:row.diversion}:await crisisTotals(db,id,w.now);
 const progress=Math.max(0,sum.repair-sum.diversion),phase=row.outcome?'resolved':w.now<begin+3600000?'warning':progress>=row.target?'stabilizing':'active';
 const spec=crisisTypes[row.type];
 const current={...row,...spec,...sum,progress,phase,warningUntil:begin+3600000};
 if(row.outcome){if(row.type==='boiler')w.coldModifier+=(row.outcome==='secured'?-.5:1);else w.foodModifier+=(row.outcome==='secured'?-1:1);}
 else if(phase==='active'){if(row.type==='boiler')w.coldModifier+=.5;else w.foodModifier++;}
 const history=(await db.prepare('SELECT * FROM district_crises WHERE outcome IS NOT NULL AND day<? ORDER BY day DESC LIMIT 5').bind(w.day).all()).results.map(x=>({...x,name:crisisTypes[x.type].name}));
 return {current,history};
}
export function crisisCommitment(db,op,citizen,current,metrics,endsAt,override){
 if(!current||current.outcome||endsAt>current.deadline)return null;
 const repair=override?.repair??(current.type==='boiler'?(metrics.relief||0)+(metrics.patrols||0):(metrics.freight||0)),diversion=override?.diversion??(metrics.crime||0);
 if(!repair&&!diversion)return null;
 return db.prepare('INSERT INTO crisis_actions (id,crisis,citizen,completes,repair,diversion) VALUES (?,?,?,?,?,?)').bind(op,current.id,citizen,endsAt,repair,diversion);
}
export function crisisOptions(current){
 if(!current)return [];
 return [
  {id:'donate',name:`Deliver one ${current.supply==='heatpack'?'warming pack':'wire'}`,seconds:25,energy:2,cost:{[current.supply]:1},repair:1,reward:{credits:1,taxGross:1,rep:1},description:'One repair unit; 1 taxable CR and 1 trust.'},
  {id:'crew',name:current.type==='boiler'?'Join the repair crew':'Verify a freight seal',seconds:60,energy:6,cost:{[current.type==='boiler'?'wire':'data']:1},repair:2,reward:{credits:2,taxGross:2,rep:1},description:'Two repair units; 2 taxable CR and 1 trust.'},
  {id:'divert',name:'Divert the emergency stock',seconds:45,energy:7,cost:{data:1},diversion:2,reward:{credits:4,heat:6,alignment:-2},description:'Two diversion units; 4 unreported CR, +6 heat, Chaos +2.'},
 ];
}
export function crisisResponseBlocked(p,item,w,current){
 if(current?.outcome||!current||w.now+item.seconds*1000>current.deadline)return 'The response cannot reach this deadline.';
 if(p.district.responses>=2)return 'Two direct emergency responses per cycle.';
 const blocked=quickBlocked(p,{...item,cost:{},break:true},w.now);if(blocked)return blocked;
 for(const [id,n] of Object.entries(item.cost))if(supplyCount(p,id)<n)return `Need ${n} ${id}.`;
 return null;
}
export function startCrisisResponse(p,input,w,current){
 crisisNeed(input.crisis===current?.id,'The district emergency has changed. Refresh its briefing.');const item=crisisOptions(current).find(x=>x.id===input.id);crisisNeed(item,'Choose a published emergency response.');const blocked=crisisResponseBlocked(p,item,w,current);crisisNeed(!blocked,blocked);
 for(const [id,n] of Object.entries(item.cost))changeSupply(p,id,-n);p.energy-=item.energy;p.street.count++;p.district.responses++;
 p.errand={action:'crisis_response',id:input.id,label:item.name,art:current.art,started:w.now,endsAt:w.now+item.seconds*1000,reward:item.reward,message:`${item.name}. ${item.description} Your district commitment is recorded at completion.`};
 return {message:`Started ${item.name.toLowerCase()}. ${item.seconds} seconds; ${item.energy} energy.`,endsAt:p.errand.endsAt,metrics:input.id==='divert'?{crime:1}:current.type==='boiler'?{relief:item.repair}:{freight:item.repair},crisisUnits:{repair:item.repair||0,diversion:item.diversion||0}};
}
