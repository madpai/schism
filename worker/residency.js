import {livingState} from './living.js';
// City hours advance for everybody together. One city hour is fifteen real minutes.
export const CITY_HOUR_MS=900000, CITY_DAY_MS=21600000;
export const appearanceOptions={
  gender:['Woman','Man','Nonbinary'],
  skin:['Porcelain','Sand','Olive','Bronze','Umber','Ebony'],
  hair:['Black','Brown','Copper','Blonde','Silver','Violet'],
  style:['Cropped','Swept','Bob','Braids','Shaved'],
  frame:['Lean','Broad','Soft'],
};
export const defaultAppearance={gender:'Nonbinary',skin:'Olive',hair:'Black',style:'Cropped',frame:'Lean'};
export function validAppearance(value){
  return value&&typeof value==='object'&&!Array.isArray(value)&&Object.entries(appearanceOptions).every(([key,values])=>values.includes(value[key]));
}
export function residenceDays(p,now){return Math.max(0,Math.floor((now-p.joined)/86400000));}
export function residencyState(p,now){
  // Saves written before registration existed are established citizens, not new arrivals.
  p.registered??=true;p.appearance??={...defaultAppearance};p.residencyVersion??=1;
  p.nextRentAt??=now+Math.max(1,(p.nextRent||24)-(p.clock||0))*CITY_HOUR_MS;
  p.labor??={day:0,hours:0};p.criminal??={xp:0,attempts:0,successes:0,day:0,count:0};
  p.reliefDay??=0;p.security??=false;p.lastRestDay??=0;
  p.taxDebt??=0;p.taxRemainder??=0;p.taxEarned??=0;p.taxPaid??=0;p.taxDeadline??=now+CITY_DAY_MS;
  p.taxHold??=false;p.criminalHold??=false;
  p.daysInCity=residenceDays(p,now);livingState(p,now);return p;
}
export function institutionRequirements(p,now){
  const age=residenceDays(p,now),civic=p.careers?.civic?.xp||0;
  const administrative=[['2 days in the city',age>=2],['25 civic trust',p.rep>=25],['80 civic career XP',civic>=80],['Security heat below 20',p.heat<20]];
  const security=[['7 days in the city',age>=7],['60 civic trust',p.rep>=60],['180 civic career XP',civic>=180],['Order alignment +40',p.alignment>=40],['30 completed shifts',p.shifts>=30],['Security heat at most 10',p.heat<=10],['No active sentence',!p.detainedUntil||p.detainedUntil<=now]];
  const shop=[['1 day in the city',age>=1],['10 civic trust',p.rep>=10]];
  return {administrative,security,shop};
}
export const timedActions=new Set(['work','rest','crime','organize','clinic','official_work','business_work','security_work','event_work','clearance']);
export const onDutyActions=new Set(['buy','consume','rent','tax','post','rename','appearance','gear_buy','gear_equip','gear_remove','relief','list','trade','cancel','sell','collect','quick','craft','casino','network_job','network_post','use_craft']);
for(const action of ['stair_choice','stair_inspect','stair_repair','shift_choice','tenant_request','tenant_request_fill','tenant_request_cancel','report','feedback','moderate','tenant_create','tenant_join','tenant_leave','tenant_post','tenant_donate','tenant_take','tenant_repair','recovery_work','mend_clothes','tax_reserve','rent_prepay','rent_reclaim','district_choice','survey','case_review','order_create','order_fill','order_cancel','career_case','prepare_crime','crisis_response'])onDutyActions.add(action);
export function accrueTax(p,gross){
  p.taxEarned+=gross;const amount=p.taxRemainder+gross*12;
  const assessed=Math.floor(amount/100);p.taxDebt+=assessed;p.taxRemainder=amount%100;
  if(p.finance?.taxAuto){const held=Math.min(p.credits,assessed);p.credits-=held;p.finance.taxReserve+=held;}
}
export function identityFlags(p,now){
  const flags=[];
  if(p.taxHold)flags.push({id:'tax',label:'Tax delinquency',detail:`${p.taxDebt} CR owed. Pay Revenue, then request registry clearance. Public custodial work remains open if you need debt money.`});
  if(p.criminalHold)flags.push({id:'arrest',label:'Arrest record',detail:'Resolve your sentence, reduce heat to 20 or below, then request registry clearance.'});
  if(p.detainedUntil>now)flags.push({id:'detained',label:'Detained',detail:'Your sentence is still running.'});
  return flags;
}

// Rewards are deferred; expenses are reserved at the start. Deltas allow shopping and
// trading during a shift without a completion overwriting the player's newer balance.
export function scheduleActivity(before,after,{action,label,message,now,hours,energy,day}){
  const deltas={},sets={};
  for(const key of Object.keys(after)){
    if(['activity','lastTick','nextRent','nextRentAt','clock','daysInCity','energy','labor','criminal','district','neighborhood','aftermath','finance','clothingWear','fireDay','housingReform','housingVersion','rentTier','shopDay','shopSessions','lastRestDay'].includes(key))continue;
    if(typeof after[key]==='number'&&typeof before[key]==='number'){
      const delta=after[key]-before[key];if(delta>0)deltas[key]=delta;
    }else if(JSON.stringify(after[key])!==JSON.stringify(before[key]))sets[key]=after[key];
  }
  const p=structuredClone(after);
  for(const [key,value] of Object.entries(deltas))p[key]-=value;
  for(const key of Object.keys(sets))p[key]=structuredClone(before[key]??null);
  p.energy=Math.max(0,before.energy-energy);
  if(action==='rest')deltas.energy=({bunk:8,street:6,room:16,flat:20}[after.housing]??8);
  p.activity={action,label,started:now,endsAt:now+hours*CITY_HOUR_MS,hours,day,deltas,sets,message};
  return p;
}
export function completeActivity(p){
  const a=p.activity;if(!a)return;
  for(const [key,value] of Object.entries(a.deltas))p[key]=(p[key]||0)+value;
  Object.assign(p,a.sets);p.activity=null;
  if(a.taxGross)accrueTax(p,a.taxGross);
  for(const key of ['health','energy','fullness','warmth','heat','coherence'])p[key]=Math.max(0,Math.min(100,p[key]));
}
