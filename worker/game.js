import { CITY_HOUR_MS, CITY_DAY_MS, appearanceOptions, defaultAppearance, validAppearance, residencyState, institutionRequirements, timedActions, onDutyActions, scheduleActivity, completeActivity, accrueTax, identityFlags } from './residency.js';
import { cityLife, cityResponses, contributionFor } from './citylife.js';
import { encountersFor, personalState, resolveEncounter } from './stories.js';
import { forceProfile, citizenForces } from './forces.js';
import { gearCatalog, careerPaths, shiftTypes, specialistJobs, careerState, gearEffects, coldRate, jobQuote, recordShift, careerSnapshot, equipmentSnapshot, removeEquipment } from './progression.js';
const EPOCH = Date.UTC(2026,9,5);
const clamp = (n, min=0, max=100) => Math.max(min,Math.min(max,n));
export const goods = {
  bread:{name:'Vat-grown ration',price:3,stock:36,description:'Your daily biomass allowance. It has no previous owner.',effect:'+24 fullness',icon:'bread'},
  soup:{name:'Heated nutrient broth',price:5,stock:24,description:'Warm enough to silence the tremor in your hands.',effect:'+35 fullness · +18 warmth',icon:'soup'},
  coat:{name:'Insulated shroud',price:18,stock:8,description:'Conductive lining. Previous occupant unknown.',effect:'Slows cold exposure',icon:'coat'},
  medicine:{name:'Somatic stabilizer',price:10,stock:12,description:'The seal bears a clinic sigil. The ingredients are classified.',effect:'+30 health',icon:'health'},
  scrap:{name:'Relay fragments',price:4,stock:25,description:'Dead neural hardware. Some fragments still retain an echo.',effect:'Trade, repair, or seal a breach',icon:'box'},
};
export const jobs = {
  sorting:{career:'mnemonic',name:'Memory sorter',employer:'Canon Mnemonic Works',pay:8,energy:18,hours:2,rep:1,description:'Separate intact memory wafers from the ones still speaking. Do not listen.',risk:'Routine exposure',requires:0},
  hauling:{career:'transit',physical:true,name:'Reliquary carrier',employer:'Vestibule Transit Office',pay:13,energy:28,hours:3,rep:2,description:'Move sealed reliquaries between the transit pylons. Their weight changes after midnight.',risk:'Heavy load',requires:0},
  cleaning:{career:'civic',name:'Residue custodian',employer:'Canon Order Maintenance',pay:5,energy:10,hours:1,rep:1,description:'Scrape the black residue from public prayer terminals. It grows back when the speakers go silent.',risk:'Routine exposure',requires:0},
  maintenance:{career:'mnemonic',name:'Lattice technician',employer:'Canon Mnemonic Works',pay:22,energy:20,hours:3,rep:3,description:'Repair the neural lattice from inside its maintenance coffin. Your badge permits you to leave.',risk:'Trusted operative',requires:8},
};
Object.assign(jobs,specialistJobs);
export function world(now=Date.now()) {
  const day=Math.max(1,Math.floor((now-EPOCH)/21600000)+1);
  const hour=Math.floor(((now-EPOCH)%21600000+21600000)%21600000/900000);
  const phase=day%4;
  return {day,hour,now,temperature:phase===1?-4:phase===2?-7:phase===3?-2:1,weather:phase===0?'Static rain':phase===1?'Signal fog':phase===2?'Null front':'Ash fall',shortage:phase===2,inspection:phase===3,event:phase===2?'Null front. The ration printers are producing empty wrappers.':phase===3?'The Canon is reading citizen implants at every checkpoint.':phase===0?'A transit reliquary has arrived. The Exchange reports new biomass.':'The thermal lattice is offline. The walls are reciting numbers again.'};
}
export function initial(now=Date.now()) {
  return {credits:0,health:78,energy:58,fullness:42,warmth:35,rep:0,heat:0,scrap:0,bread:0,medicine:0,coat:false,housing:'bunk',role:'Unassigned resident',union:false,shifts:0,clock:0,nextRent:24,nextRentAt:now+CITY_DAY_MS,rentDebt:0,rentCycles:0,registered:false,appearance:{...defaultAppearance},residencyVersion:2,joined:now,lastTick:now,evicted:false,business:false,property:false};
}
export function settle(data, now=Date.now(),w=world(now)) {
  const p=residencyState(careerState(citizenForces(structuredClone(data))),now);
  if(!p.registered){p.lastTick=now;return p;}
  // Resolve at a precise boundary: completion rewards cannot be used before the shift ends.
  const start=Math.max(p.lastTick,now-168*3600000);
  const advance=until=>{
    const hours=Math.max(0,(until-p.lastTick)/CITY_HOUR_MS);
    if(!hours)return;
    const sleeping=p.activity?.action==='rest',working=!!p.activity&&!sleeping;
    const rate=working?Math.max(.2,coldRate(p,w)+(w.coldModifier||0)):Math.max(.2,(p.evicted?3:p.housing==='flat'?.25:p.housing==='room'?.5:1)+(w.coldModifier||0)-(w.heating?1:0)-(p.coat?.6:0));
    const hunger=sleeping?1.5:2;
    const hungerDamage=Math.max(0,hours-Math.max(0,p.fullness-15)/hunger);
    const coldDamage=Math.max(0,hours-Math.max(0,p.warmth-15)/rate);
    p.fullness=clamp(p.fullness-hours*hunger);p.warmth=clamp(p.warmth-hours*rate);
    p.health=clamp(p.health-hungerDamage-coldDamage*.5,10,100);
    p.energy=clamp(p.energy+hours*(sleeping?6:working?0:1));p.heat=clamp(p.heat-hours*.25);
    p.lastTick=until;
  };
  p.lastTick=start;
  if(p.activity&&p.activity.endsAt<=now){advance(p.activity.endsAt);completeActivity(p);}
  advance(now);
  if(now>=p.nextRentAt){
    const bills=Math.floor((now-p.nextRentAt)/CITY_DAY_MS)+1;
    const charged=Math.min(bills,Math.max(0,4-p.rentCycles));
    p.rentDebt+=charged*(p.housing==='flat'?32:p.housing==='room'?20:12);p.rentCycles+=charged;p.nextRentAt+=bills*CITY_DAY_MS;
  }
  if(p.rentCycles>=4){p.evicted=true;p.housing='street';}
  if(now>=p.taxDeadline){if(p.taxDebt>0)p.taxHold=true;else p.taxDeadline+= (Math.floor((now-p.taxDeadline)/CITY_DAY_MS)+1)*CITY_DAY_MS;}
  // These fields survive for old saves and UI compatibility, but follow shared time.
  p.clock=Math.max(0,Math.floor((now-EPOCH)/CITY_HOUR_MS));p.nextRent=p.clock+Math.ceil((p.nextRentAt-now)/CITY_HOUR_MS);
  return p;
}
function need(condition,message){if(!condition)throw Object.assign(new Error(message),{status:400});}
const uid=()=>crypto.randomUUID();
function stmt(db,sql,...args){return db.prepare(sql).bind(...args);}
async function all(db,sql,...args){return (await stmt(db,sql,...args).all()).results;}
function price(item,w){return Math.max(1,goods[item].price+(['bread','soup'].includes(item)?(w.foodModifier||0)+(w.rationModifier||0):item==='coat'&&w.shortage?2:0));}
export async function ensureCitizen(db,owner,now=Date.now()){
  const id=uid();
  await stmt(db,'INSERT OR IGNORE INTO citizens (id,owner,name,data,updated) VALUES (?,?,?,?,?)',id,owner,'Citizen '+id.slice(0,4).toUpperCase(),JSON.stringify(initial(now)),now).run();
  return stmt(db,'SELECT * FROM citizens WHERE owner=?',owner).first();
}
async function ensureMarket(db,w,life){
  const supply=life?Math.floor(life.metrics.output/2)+life.metrics.freight:0;
  await db.batch(Object.entries({...goods,...Object.fromEntries(Object.entries(gearCatalog).filter(([id,g])=>g.price&&!Object.hasOwn(goods,id)))}).map(([id,g])=>{
    const delivered=['bread','soup'].includes(id)?supply:0;
    return stmt(db,'INSERT INTO market (id,stock,day,delivered) VALUES (?,?,?,?) ON CONFLICT(id) DO UPDATE SET stock=min(?,market.stock+max(0,excluded.day-market.day)*?+CASE WHEN excluded.day>market.day THEN excluded.delivered WHEN excluded.day=market.day THEN max(0,excluded.delivered-market.delivered) ELSE 0 END), delivered=CASE WHEN excluded.day>=market.day THEN max(CASE WHEN excluded.day=market.day THEN market.delivered ELSE 0 END,excluded.delivered) ELSE market.delivered END, day=max(market.day,excluded.day)',id,g.stock+delivered,w.day,delivered,g.stock*2,g.stock);
  }));
}
async function settledCitizen(db,owner,now,w){
  for(let retry=0;retry<4;retry++){
    const c=await ensureCitizen(db,owner,now),raw=JSON.parse(c.data),p=settle(raw,now,w);
    if(JSON.stringify(raw)===JSON.stringify(p))return {...c,data:JSON.stringify(p)};
    if(raw.activity&&!p.activity){
      const guard=uid();
      try{
        await db.batch([
          stmt(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM citizens WHERE id=? AND version=?),0))',guard,c.id,c.version),
          stmt(db,'UPDATE citizens SET data=?,version=version+1 WHERE id=?',JSON.stringify(p),c.id),
          stmt(db,'INSERT INTO journal (id,citizen,body,created) VALUES (?,?,?,?)',uid(),c.id,raw.activity.message,raw.activity.endsAt),
          stmt(db,'DELETE FROM action_guards WHERE id=?',guard),
        ]);
        return {...c,version:c.version+1,data:JSON.stringify(p)};
      }catch(error){if(String(error).includes('guard_valid'))continue;throw error;}
    }else{
      const result=await stmt(db,'UPDATE citizens SET data=?,version=version+1 WHERE id=? AND version=?',JSON.stringify(p),c.id,c.version).run();
      if(result.meta.changes)return {...c,version:c.version+1,data:JSON.stringify(p)};
    }
  }
  throw Object.assign(new Error('Your registry record changed. Refresh and try again.'),{status:409});
}
async function cityProject(db,w){
  const id='heating-'+w.day;
  await stmt(db,'INSERT OR IGNORE INTO projects (id,day,progress) VALUES (?,?,0)',id,w.day).run();
  const row=await stmt(db,'SELECT * FROM projects WHERE id=?',id).first();
  w.heating=row.progress>=12;
  return {...row,target:12,complete:w.heating};
}
async function cityForces(db,w){
  const id='signal-'+w.day;
  await stmt(db,'INSERT OR IGNORE INTO forces (id,day,balance,interventions) VALUES (?,?,0,0)',id,w.day).run();
  const row=await stmt(db,'SELECT * FROM forces WHERE id=?',id).first();
  const force={...row,...forceProfile(row)};Object.assign(w,forceProfile(row));return force;
}
export async function snapshot(db,owner,now=Date.now()){
  const w=world(now),life=await cityLife(db,w,now);
  await ensureMarket(db,w,life);
  const force=await cityForces(db,w);w.securityModifier=(w.securityModifier||0)+w.citySecurityModifier;
  const project=await cityProject(db,w),c=await settledCitizen(db,owner,now,w),citizen=JSON.parse(c.data);personalState(citizen);
  const [stock,log,board,people,offers,totals]=await Promise.all([
    all(db,'SELECT * FROM market'),all(db,'SELECT body,created FROM journal WHERE citizen=? ORDER BY created DESC LIMIT 12',c.id),
    all(db,'SELECT p.id,p.body,p.created,c.name,c.data FROM posts p JOIN citizens c ON c.id=p.citizen ORDER BY p.created DESC LIMIT 20'),
    all(db,'SELECT id,name,data,updated FROM citizens ORDER BY updated DESC LIMIT 30'),
    all(db,'SELECT l.*,c.name FROM listings l JOIN citizens c ON c.id=l.seller WHERE l.sold=0 ORDER BY l.created DESC LIMIT 30'),
    stmt(db,"SELECT count(*) AS citizens, sum(CASE WHEN json_extract(data,'$.union')=1 THEN 1 ELSE 0 END) AS members FROM citizens WHERE json_extract(data,'$.registered') IS NOT 0").first(),
  ]);
  return {citizen:{id:c.id,name:c.name,...citizen},world:{...w,now},cityLife:life,appearanceOptions,requirements:institutionRequirements(citizen,now),idFlags:identityFlags(citizen,now),project,forces:force,encounters:encountersFor(citizen),
    goods:stock.filter(s=>Object.hasOwn(goods,s.id)).map(s=>({...goods[s.id],id:s.id,stock:s.stock,price:price(s.id,w)})),jobs:Object.entries(jobs).map(([id,j])=>({id,...j,quotes:Object.keys(shiftTypes).map(mode=>jobQuote(citizen,j,mode,w))})),
    equipment:equipmentSnapshot(citizen,stock,w),careers:careerSnapshot(citizen,w),shiftTypes,loadoutEffects:gearEffects(citizen),
    log,board:board.map(p=>({id:p.id,name:p.name,body:p.body,created:p.created,role:JSON.parse(p.data).role})),
    citizens:people.filter(p=>JSON.parse(p.data).registered!==false).map(p=>{const d=JSON.parse(p.data);return {id:p.id,name:p.name,role:d.role,rep:d.rep,shifts:d.shifts,union:d.union,appearance:d.appearance||defaultAppearance,daysInCity:Math.max(0,Math.floor((now-d.joined)/86400000)),online:now-p.updated<120000};}),listings:offers,totals};
}
export async function act(db,owner,input,now=Date.now()){
  need(input&&typeof input==='object'&&!Array.isArray(input),'Invalid action.');
  need(typeof input.action==='string','Choose an action.');
  const w=world(now),life=await cityLife(db,w,now);
  const force=await cityForces(db,w);w.securityModifier=(w.securityModifier||0)+w.citySecurityModifier;
  const project=await cityProject(db,w),c=await settledCitizen(db,owner,now,w),p=JSON.parse(c.data);
  need(p.registered||input.action==='register','Register your character at the arrival platform first.');
  need(!p.activity||onDutyActions.has(input.action),`You are busy: ${p.activity?.label}. Wait until it finishes.`);
  need(!p.detainedUntil||p.detainedUntil<=now||['tax','rent','post','consume','relief'].includes(input.action),'Your sentence is still running. Check your release time.');
  need(now-c.last_action>=650,'Give the city a moment before your next action.');
  await ensureMarket(db,w,life);personalState(p);
  const before=structuredClone(p);
  if(p.labor.day!==w.day)p.labor={day:w.day,hours:0};
  if(p.criminal.day!==w.day){p.criminal.day=w.day;p.criminal.count=0;}
  const requirement=kind=>{const requirements=institutionRequirements(p,now)[kind];need(requirements.every(([,met])=>met),'Requirements: '+requirements.filter(([,met])=>!met).map(([label])=>label).join(', '));};
  const extra=[],checks=[],op=uid();let message='',hours=0,energy=0;
  const credit=n=>need(p.credits>=n,`You need ${n} credits. You have ${p.credits}.`);
  const job=typeof input.id==='string'&&Object.hasOwn(jobs,input.id)?jobs[input.id]:null;
  switch(input.action){
    case 'register':{
      need(!p.registered,'You already have a character.');
      need(typeof input.name==='string'&&/^[\p{L}\p{N} ._-]{2,24}$/u.test(input.name.trim()),'Use a name of 2–24 letters, numbers, spaces, or basic punctuation.');
      need(validAppearance(input.appearance),'Choose a valid appearance for every field.');
      p.registered=true;p.appearance={...input.appearance};p.joined=now;p.lastTick=now;p.nextRentAt=now+CITY_DAY_MS;p.taxDeadline=now+CITY_DAY_MS;p.arrivalDay=w.day;
      extra.push(stmt(db,'UPDATE citizens SET name=? WHERE id=?',input.name.trim(),c.id));
      message=`The import train brakes at Platform IX. City day ${w.day}. Your papers read ${input.name.trim()}. No credits. No allegiance. A bunk for one cycle. The city will bill you for the next.`;break;
    }
    case 'appearance':need(validAppearance(input.appearance),'Choose a valid appearance.');p.appearance={...input.appearance};message='The registry replaces your identity scan. Your face is still yours.';break;
    case 'relief':need(p.reliefDay!==w.day,'One emergency meal per citizen each city day.');p.reliefDay=w.day;p.fullness=clamp(p.fullness+24);p.warmth=clamp(p.warmth+10);p.health=Math.max(25,p.health);p.energy=Math.max(20,p.energy);message='A queue, a stamped wrist, and one emergency meal. Enough to work again. Relief is consumed here and cannot be sold.';break;
    case 'tax':credit(p.taxDebt);need(p.taxDebt>0,'You have no unpaid income tax.');p.credits-=p.taxDebt;p.taxPaid+=p.taxDebt;message=`Revenue receives ${p.taxDebt} credits. ${p.taxHold?'Your ID remains flagged until the Registry completes a clearance review.':'Your tax record is current.'}`;p.taxDebt=0;p.taxDeadline=now+CITY_DAY_MS;break;
    case 'clearance':need(p.taxHold||p.criminalHold,'Your ID has no clearance hold.');need(p.taxDebt===0,'Pay your income tax debt before requesting clearance.');need(p.heat<=20,'Reduce security heat to 20 or below before requesting clearance.');need(!p.detainedUntil||p.detainedUntil<=now,'Serve your sentence first.');hours=p.credits>=2?1:2;energy=p.credits>=2?6:14;if(p.credits>=2)p.credits-=2;p.taxHold=false;p.criminalHold=false;message='Your number is finally called. The Registry clears your ID. Factory gates will accept your papers again.';break;
    case 'security':requirement('security');need(!p.taxHold&&!p.criminalHold,'Security recruitment requires a cleared ID.');need(!p.security,'You already serve in the security forces.');p.security=true;p.role='Canon security recruit';message='Thirty shifts and a week in the district. The Canon issues you a badge. You now protect the laws you struggled to survive.';break;
    case 'security_work':need(p.security,'Join the security forces first.');need(!p.taxHold&&!p.criminalHold,'Clear your identity holds before reporting for duty.');hours=3;energy=24;p.credits+=20;p.rep++;p.alignment=clamp(p.alignment+2,-100,100);message='You patrol the rainline. Two incidents closed, twenty credits earned. The district lockdown weakens.';break;
    case 'event_work':{const response=typeof input.id==='string'&&Object.hasOwn(cityResponses,input.id)?cityResponses[input.id]:null;need(response,'Choose a published district response.');need(!p.taxHold&&!p.criminalHold||input.id==='relief','Factory and freight gates require a cleared ID.');need(p.scrap>=(response.scrap||0),'The boiler requires one relay fragment.');p.scrap-=response.scrap||0;hours=response.hours;energy=response.energy;p.credits+=response.pay;p.rep++;message=`Completed ${response.name.toLowerCase()}. Your work changes the district for everyone.`;break;}

    case 'encounter':{const resolved=resolveEncounter(p,input,now);message=resolved.message;hours=resolved.hours;energy=resolved.energy;if(resolved.force)extra.push(stmt(db,'UPDATE forces SET balance=max(-100,min(100,balance+?)),interventions=interventions+1 WHERE id=?',resolved.force,force.id));break;}
    case 'rite':{
      need(['order','chaos'].includes(input.id),'Choose Order or Chaos.');need(p.lastRiteDay!==w.day,'You have already performed a rite this city day.');
      hours=1;energy=6;const direction=input.id==='order'?12:-12;
      if(input.id==='order'){need(p.scrap>=1,'The Canon requires one relay fragment to seal a breach.');p.scrap--;p.rep++;p.coherence=clamp(p.coherence+8);message='You seal a breach with a relay fragment. The Canon broadcasts your compliance. Another doorway stops whispering.';}
      else {p.credits+=4;p.heat=clamp(p.heat+8);p.coherence=clamp(p.coherence-8);message='You interrupt the Canon signal. Four untraceable credits arrive in your implant. The Wound speaks in your own voice.';}
      p.alignment=clamp(p.alignment+direction,-100,100);p.lastRiteDay=w.day;
      extra.push(stmt(db,'UPDATE forces SET balance=max(-100,min(100,balance+?)),interventions=interventions+1 WHERE id=?',direction,force.id));break;
    }
    case 'contribute':{
      need(p.scrap>0,'You need one relay fragment to repair the thermal lattice.');need(!project.complete,'The thermal lattice is already repaired for this city day.');
      checks.push(stmt(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM projects WHERE id=? AND progress<12),0))',op+'project',project.id));
      extra.push(stmt(db,'UPDATE projects SET progress=progress+1 WHERE id=?',project.id));p.scrap--;p.rep++;p.story.flags.helpedDistrict=true;
      message='You add a relay fragment to the thermal lattice. One less freezing habitation cell, if enough citizens join you.';break;
    }
    case 'work':{
      need(job,'That job is no longer available.');need(!['mnemonic','recovery'].includes(job.career)||!p.taxHold&&!p.criminalHold,'Factory gate denied: your ID is flagged. Visit Revenue and Registry clearance.');const mode=input.shift||'standard';need(Object.hasOwn(shiftTypes,mode),'Choose a published shift type.');
      const quote=jobQuote(p,job,mode,w);need(!quote.blocked,quote.blocked);
      hours=quote.hours;energy=quote.energy;p.credits+=quote.pay;p.rep+=job.rep;p.shifts++;recordShift(p,job,quote,world(now+quote.hours*CITY_HOUR_MS).day);
      p.health=clamp(p.health-quote.healthLoss);p.coherence=clamp(p.coherence-quote.coherenceLoss);p.heat=clamp(p.heat+quote.heat);p.scrap+=quote.scrap;
      if(p.rep>=8&&['Worker','Unassigned resident'].includes(p.role))p.role='Trusted worker';
      const moments={mnemonic:'You leave with a memory of rain falling in a city you have never visited.',transit:'Rain gathers in your collar. A scanner follows you until the next intersection.',civic:'The last applicant has your face. You close the terminal before it can speak.',recovery:'Your tools smell of ozone. Something beneath the tunnel floor is still breathing.'};
      message=`Completed ${shiftTypes[mode].name.toLowerCase()} as ${job.name.toLowerCase()}. Earned ${quote.pay} credits and ${quote.xp} career XP. ${moments[job.career]}`;break;
    }
    case 'career':need(typeof input.id==='string'&&Object.hasOwn(careerPaths,input.id),'Choose a career path.');need(p.career!==input.id,'That career is already active.');p.career=input.id;message=`Your employment record now follows ${careerPaths[input.id].name.toLowerCase()}. Experience on every path is retained.`;break;
    case 'career_claim':need(typeof input.id==='string'&&Object.hasOwn(careerPaths,input.id),'Choose a career path.');need(p.dailyWork.day===w.day&&(p.dailyWork.counts[input.id]||0)>=3,'Finish three shifts on this path in one city day.');need(!p.dailyWork.claimed[input.id],'You already claimed this work quota.');p.dailyWork.claimed[input.id]=true;p.credits+=3;p.rep++;message='Three shifts recorded. Three quota credits enter your implant. One more trust in your employment file.';break;
    case 'gear_buy':{
      const g=typeof input.id==='string'&&Object.hasOwn(gearCatalog,input.id)?gearCatalog[input.id]:null;need(g&&!g.starter,'That equipment is not for sale.');need(!p.ownedGear.includes(input.id),'You already own that equipment.');const cost=input.id==='coat'?price('coat',w):g.price;credit(cost);
      checks.push(stmt(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM market WHERE id=? AND stock>0),0))',op+'stock',input.id));extra.push(stmt(db,'UPDATE market SET stock=stock-1 WHERE id=?',input.id));p.credits-=cost;p.ownedGear.push(input.id);message=`Bought ${g.name.toLowerCase()} for ${cost} credits. Equip it from your loadout.`;break;
    }
    case 'gear_equip':{
      const g=typeof input.id==='string'&&Object.hasOwn(gearCatalog,input.id)?gearCatalog[input.id]:null;need(g&&p.ownedGear.includes(input.id),'You do not own that equipment.');need(p.loadout[g.slot]!==input.id,'That equipment is already equipped.');p.loadout[g.slot]=input.id;p.coat=p.loadout.body==='coat';message=`Equipped ${g.name.toLowerCase()}. ${g.effect}.`;break;
    }
    case 'gear_remove':need(typeof input.id==='string'&&['head','body','hands','feet','neural'].includes(input.id),'Unknown equipment slot.');need(p.loadout[input.id]&&!gearCatalog[p.loadout[input.id]].starter,'That slot has no removable equipment.');removeEquipment(p,input.id);message='Equipment returned to your inventory. The city feels a little less forgiving.';break;
    case 'buy':{
      const g=typeof input.id==='string'&&Object.hasOwn(goods,input.id)?goods[input.id]:null;need(g,'Unknown item.');const cost=price(input.id,w);credit(cost);
      if(input.id==='coat')need(!p.ownedGear.includes('coat'),'You already have an insulated shroud.');
      checks.push(stmt(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM market WHERE id=? AND stock>0),0))',op+'stock',input.id));
      extra.push(stmt(db,'UPDATE market SET stock=stock-1 WHERE id=?',input.id));p.credits-=cost;
      if(input.id==='soup'){p.fullness=clamp(p.fullness+35);p.warmth=clamp(p.warmth+18);message='Heated nutrient broth. Your implant marks the body as fed. For a moment, it is correct.';}
      else if(input.id==='coat'){p.coat=true;p.ownedGear.push('coat');p.loadout.body='coat';p.warmth=clamp(p.warmth+12);message='The shroud carries three erased civic signatures. Your implant adds a fourth.';}
      else {p[input.id]=(p[input.id]||0)+1;message=`Bought ${g.name.toLowerCase()} for ${cost} credits. It’s in your bag.`;}break;
    }
    case 'consume':{
      need(['bread','medicine'].includes(input.id),'That item cannot be used.');need(p[input.id]>0,'You don’t have that item.');p[input.id]--;
      if(input.id==='bread'){p.fullness=clamp(p.fullness+24);message='You consume the vat-grown ration. The printer thanks you for returning its biomass.';}else {p.health=clamp(p.health+30);message='The stabilizer silences an unfamiliar voice in your pulse. You can breathe a little easier.';}break;
    }
    case 'rest':hours=6;need(p.lastRestDay!==w.day,'One full sleep per city day. Idle time also recovers energy.');p.lastRestDay=w.day;p.warmth=clamp(p.warmth+(p.evicted?0:p.housing==='flat'?40:p.housing==='room'?32:20));p.health=clamp(p.health+8);message=p.evicted?'You sleep beneath the transit lattice. The masked commuters step around you.':'Six hours in your habitation cell. The wall terminal repeats a prayer in a voice you used to know.';break;
    case 'rent':credit(p.rentDebt);need(p.rentDebt>0,'Your rent is already paid.');p.credits-=p.rentDebt;message=`Paid ${p.rentDebt} credits in rent. You can stay another day.`;p.rentDebt=0;p.rentCycles=0;p.evicted=false;if(p.housing==='street')p.housing='bunk';break;
    case 'upgrade':credit(45);need(!p.evicted,'Settle your rent debt first.');need(!['room','flat'].includes(p.housing),'You already have private housing.');p.credits-=45;p.housing='room';p.warmth=clamp(p.warmth+25);message='A room with a lock. Forty-five credits never bought so little freedom.';break;
    case 'flat':credit(180);need(p.housing==='room'&&!p.evicted,'Rent a private room and settle any eviction first.');need(p.daysInCity>=2&&p.rep>=20,'A heated apartment requires 2 days of residency and 20 trust.');p.credits-=180;p.housing='flat';p.warmth=clamp(p.warmth+30);message='A heated apartment above the rainline. Thirty-two credits each city cycle. For once, the window closes.';break;
    case 'crime':{
      need(['steal','smuggle'].includes(input.id),'Unknown opportunity.');need(p.criminal.count<3,'Three criminal operations per city day. Checkpoints are watching you.');p.criminal.count++;p.criminal.attempts++;hours=input.id==='steal'?1:3;energy=input.id==='steal'?12:22;
      const risk=clamp((input.id==='steal'?.3:.4)+(p.heat/200)+(w.inspection?.15:0)+(w.securityModifier||0)+gearEffects(p).captureRisk,0,1);
      const random=crypto.getRandomValues(new Uint32Array(1))[0]/4294967296;
      if(random<risk){const fine=Math.min(p.credits,input.id==='steal'?7:15);p.credits-=fine;p.rep=Math.max(0,p.rep-2);p.heat=clamp(p.heat+20);p.health=clamp(p.health-8);p.criminalHold=true;p.detainedUntil=now+(hours+2)*CITY_HOUR_MS;message=`Security caught you. Your ID is flagged and you must serve two city hours after this operation. ${fine} credits confiscated. They remember your face.`;}
      else {p.criminal.successes++;p.criminal.xp+=input.id==='steal'?3:6;p.alignment=clamp(p.alignment-3,-100,100);p.heat=clamp(p.heat+12);if(input.id==='steal'){p.scrap+=3;message='Three relay fragments slip into your shroud. The mnemonic sentinel keeps reciting its prayer.';}else {p.credits+=w.contrabandPay||24;p.role='Smuggler';message=`The sealed mnemonic package reaches the other side. ${w.contrabandPay||24} credits enter your implant.`;}}break;
    }
    case 'sell':need(p.scrap>0,'You don’t have any relay fragments.');p.scrap--;p.credits+=3;message='Sold a relay fragment to the broker for 3 credits. It is still broadcasting when you leave.';break;
    case 'union':credit(4);need(!p.union,'You’re already a union member.');p.credits-=4;p.union=true;message='You pay 4 credits into the mutual-aid fund. You’re no longer alone.';break;
    case 'organize':need(p.union,'Join the union first.');hours=2;energy=12;p.rep+=2;p.role='Union organizer';p.heat=clamp(p.heat+5);message='You organize the Uncounted for the next shift. Trust grows. So does the Canon’s interest.';break;
    case 'clinic':credit(8);p.credits-=8;p.health=clamp(p.health+40);p.coherence=clamp(p.coherence+15);hours=1;message='The Somatic Ward resets your implant and treats the body attached to it. Eight credits.';break;
    case 'bribe':credit(12);need(p.heat>0,'You don’t have a security record to clear.');p.credits-=12;p.heat=Math.max(0,p.heat-35);message='The clerk misfiles your record. Twelve credits disappear with it.';break;
    case 'official':requirement('administrative');need(!p.taxHold&&!p.criminalHold,'The Bureau requires a cleared ID.');credit(60);need(!p.official,'You already hold a municipal post.');p.credits-=60;p.official=true;p.role='Municipal official';message='Your application is approved. The processing fee was non-refundable.';break;
    case 'official_work':need(p.official,'You don’t hold a municipal post.');need(!p.taxHold&&!p.criminalHold,'The Bureau requires a cleared ID.');hours=2;energy=8;p.credits+=17;p.rep++;message='You process a stack of work permits. Seventeen credits for deciding who gets to wait.';break;
    case 'business':requirement('shop');need(!p.taxHold&&!p.criminalHold,'A trading license requires a cleared ID.');credit(90);need(!p.business,'You already own a stall.');p.credits-=90;p.business=true;p.role='Shop owner';message='The exchange terminal accepts your signature. No guarantee of customers.';break;
    case 'business_work':need(p.business,'You don’t own a market stall.');need(!p.taxHold&&!p.criminalHold,'Clear your ID to reopen the licensed stall.');if(p.shopDay!==w.day){p.shopDay=w.day;p.shopSessions=0;}need(p.shopSessions<2,'Two shop sessions per city day. Foot traffic has dried up.');p.shopSessions++;need(p.bread>0||p.scrap>0,'Stock your terminal with rations or relay fragments first.');hours=2;energy=8;{const item=p.bread?'bread':'scrap';p[item]--;p.credits+=item==='bread'?7:8;message=`You sell ${goods[item].name.toLowerCase()} at your stall. ${item==='bread'?7:8} credits from the morning foot traffic.`;}break;
    case 'property':credit(180);need(!p.property,'You already hold a lease.');need(p.rep>=15,'You need 15 trust to acquire a property lease.');p.credits-=180;p.property=true;p.role='Landlord';message='You acquire a district lease. The city takes its cut first.';break;
    case 'collect':need(p.property,'You don’t have a property lease.');need(p.lastCollect!==w.day,'You already collected this city day.');p.credits+=9;p.lastCollect=w.day;message='Nine credits from your lease. Somewhere, someone works another shift.';break;
    case 'post':{
      need(typeof input.body==='string'&&input.body.trim().length>=3&&input.body.trim().length<=240,'Write between 3 and 240 characters.');
      extra.push(stmt(db,'INSERT INTO posts (id,citizen,body,created) VALUES (?,?,?,?)',uid(),c.id,input.body.trim(),now));message='Your notice enters the neighborhood signal.';break;
    }
    case 'rename':{
      need(typeof input.name==='string'&&/^[\p{L}\p{N} ._-]{2,24}$/u.test(input.name.trim()),'Use 2–24 letters, numbers, spaces, or basic punctuation.');
      extra.push(stmt(db,'UPDATE citizens SET name=? WHERE id=?',input.name.trim(),c.id));message='Your citizen papers have been updated.';break;
    }
    case 'list':{
      need(['bread','medicine','scrap'].includes(input.id),'That item cannot be traded.');need(p[input.id]>0,'You don’t have that item.');need(Number.isInteger(input.price)&&input.price>=1&&input.price<=50,'Choose a price between 1 and 50 credits.');
      const count=await stmt(db,'SELECT count(*) AS n FROM listings WHERE seller=? AND sold=0',c.id).first();need(count.n<(p.business?12:6),'Your listing slots are full.');p[input.id]--;
      extra.push(stmt(db,'INSERT INTO listings (id,seller,item,price,created) VALUES (?,?,?,?,?)',uid(),c.id,input.id,input.price,now));message=`Listed ${goods[input.id].name.toLowerCase()} for ${input.price} credits.`;break;
    }
    case 'trade':{
      need(typeof input.id==='string','Choose a listing.');const offer=await stmt(db,'SELECT * FROM listings WHERE id=? AND sold=0',input.id).first();need(offer,'Someone already bought that listing.');need(offer.seller!==c.id,'You cannot buy your own listing.');credit(offer.price);
      checks.push(stmt(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM listings WHERE id=? AND sold=0),0))',op+'offer',input.id));
      extra.push(stmt(db,'UPDATE listings SET sold=1 WHERE id=?',input.id),stmt(db,"UPDATE citizens SET data=json_set(data,'$.credits',json_extract(data,'$.credits')+?,'$.taxEarned',coalesce(json_extract(data,'$.taxEarned'),0)+?,'$.taxDebt',coalesce(json_extract(data,'$.taxDebt'),0)+CAST((coalesce(json_extract(data,'$.taxRemainder'),0)+?*12)/100 AS INTEGER),'$.taxRemainder',(coalesce(json_extract(data,'$.taxRemainder'),0)+?*12)%100),version=version+1 WHERE id=?",offer.price,offer.price,offer.price,offer.price,offer.seller),stmt(db,'INSERT INTO journal (id,citizen,body,created) VALUES (?,?,?,?)',uid(),offer.seller,`Your ${goods[offer.item].name.toLowerCase()} sold for ${offer.price} credits.`,now));
      p.credits-=offer.price;p[offer.item]++;message=`Bought ${goods[offer.item].name.toLowerCase()} from another citizen for ${offer.price} credits.`;break;
    }
    case 'cancel':{
      const offer=await stmt(db,'SELECT * FROM listings WHERE id=? AND seller=? AND sold=0',String(input.id),c.id).first();need(offer,'Listing is no longer available.');
      checks.push(stmt(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM listings WHERE id=? AND sold=0),0))',op+'offer',offer.id));extra.push(stmt(db,'UPDATE listings SET sold=2 WHERE id=?',offer.id));p[offer.item]++;message='You take your goods back from the market.';break;
    }
    default:throw Object.assign(new Error('Unknown action.'),{status:400});
  }
  need(p.energy>=energy,`You need ${energy} energy. Rest before taking this job.`);
  const taxable=['work','official_work','business_work','security_work','event_work','career_claim','collect','sell'].includes(input.action)||(input.action==='encounter'&&input.id==='wages'&&['quiet','challenge'].includes(input.choice));
  const gross=Math.max(0,p.credits-before.credits);
  if(taxable&&gross&&!timedActions.has(input.action))accrueTax(p,gross);
  let final;
  if(timedActions.has(input.action)){
    if(['work','official_work','event_work','security_work'].includes(input.action)){
      need(p.labor.hours+hours<=8,'Eight working hours per city day. Your permit has no hours left.');p.labor.hours+=hours;
    }
    final=scheduleActivity(before,p,{action:input.action,label:input.action==='work'?job.name:input.action==='event_work'?cityResponses[input.id].name:input.action.replaceAll('_',' '),message,now,hours,energy,day:w.day});
    if(taxable)final.activity.taxGross=gross;
    const metrics=contributionFor(input.action,input,job,hours),values=Object.values(metrics);
    if(values.some(Boolean))extra.push(stmt(db,'INSERT INTO city_activity (id,citizen,day,completes,output,freight,crime,unrest,relief,patrols) VALUES (?,?,?,?,?,?,?,?,?,?)',op,c.id,world(final.activity.endsAt).day,final.activity.endsAt,...values));
    message=`Started ${final.activity.label.toLowerCase()}. Finishes in ${hours*15} real minutes. Pay and benefits arrive at completion.`;
  }else{
    p.energy=clamp(p.energy-energy);
    // Finite narrative decisions and daily rites spend energy; they never change city time.
    final=settle(p,now,w);
  }
  const statements=[stmt(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM citizens WHERE id=? AND version=?),0))',op,c.id,c.version),...checks,
    stmt(db,'UPDATE citizens SET data=?,version=version+1,last_action=?,updated=? WHERE id=?',JSON.stringify(final),now,now,c.id),...extra,
    stmt(db,'INSERT INTO journal (id,citizen,body,created) VALUES (?,?,?,?)',uid(),c.id,message,now),
    stmt(db,'DELETE FROM action_guards WHERE id=? OR id=? OR id=? OR id=?',op,op+'stock',op+'offer',op+'project')];
  try{await db.batch(statements);}catch(e){if(String(e).includes('guard_valid'))throw Object.assign(new Error('That offer or your balance just changed. Refresh and try again.'),{status:409});throw e;}
  return {message,...await snapshot(db,owner,now)};
}
