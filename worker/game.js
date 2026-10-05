import { encountersFor, personalState, resolveEncounter } from './stories.js';
import { forceProfile, citizenForces } from './forces.js';
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
  sorting:{name:'Memory sorter',employer:'Canon Mnemonic Works',pay:8,energy:18,hours:2,rep:1,description:'Separate intact memory wafers from the ones still speaking. Do not listen.',risk:'Routine exposure',requires:0},
  hauling:{name:'Reliquary carrier',employer:'Vestibule Transit Office',pay:13,energy:28,hours:3,rep:2,description:'Move sealed reliquaries between the transit pylons. Their weight changes after midnight.',risk:'Heavy load',requires:0},
  cleaning:{name:'Residue custodian',employer:'Canon Order Maintenance',pay:5,energy:10,hours:1,rep:1,description:'Scrape the black residue from public prayer terminals. It grows back when the speakers go silent.',risk:'Routine exposure',requires:0},
  maintenance:{name:'Lattice technician',employer:'Canon Mnemonic Works',pay:22,energy:20,hours:3,rep:3,description:'Repair the neural lattice from inside its maintenance coffin. Your badge permits you to leave.',risk:'Trusted operative',requires:8},
};
export function world(now=Date.now()) {
  const day=Math.max(1,Math.floor((now-EPOCH)/21600000)+1);
  const hour=Math.floor(((now-EPOCH)%21600000+21600000)%21600000/900000);
  const phase=day%4;
  return {day,hour,temperature:phase===1?-4:phase===2?-7:phase===3?-2:1,weather:phase===0?'Static rain':phase===1?'Signal fog':phase===2?'Null front':'Ash fall',shortage:phase===2,inspection:phase===3,event:phase===2?'Null front. The ration printers are producing empty wrappers.':phase===3?'The Canon is reading citizen implants at every checkpoint.':phase===0?'A transit reliquary has arrived. The Exchange reports new biomass.':'The thermal lattice is offline. The walls are reciting numbers again.'};
}
export function initial(now=Date.now()) {
  return {credits:9,health:78,energy:58,fullness:32,warmth:24,rep:0,heat:0,scrap:0,bread:0,medicine:0,coat:false,housing:'bunk',role:'Worker',union:false,shifts:0,clock:7,nextRent:24,rentDebt:12,rentCycles:1,joined:now,lastTick:now,evicted:false,business:false,property:false};
}
export function settle(data, now=Date.now()) {
  const p=citizenForces({...data});
  const hours=Math.min(168,Math.floor((now-p.lastTick)/3600000));
  if(hours>0){p.fullness=clamp(p.fullness-hours*2);p.warmth=clamp(p.warmth-hours*(p.coat?.3:1));p.energy=clamp(p.energy+hours*3);p.heat=clamp(p.heat-hours);p.clock+=hours;p.lastTick=now-((now-p.lastTick)%3600000);}
  while(p.clock>=p.nextRent){p.rentDebt+=(p.housing==='room'?20:12);p.rentCycles++;p.nextRent+=24;}
  if(p.rentCycles>=4){p.evicted=true;p.housing='street';}
  return p;
}
function need(condition,message){if(!condition)throw Object.assign(new Error(message),{status:400});}
const uid=()=>crypto.randomUUID();
function stmt(db,sql,...args){return db.prepare(sql).bind(...args);}
async function all(db,sql,...args){return (await stmt(db,sql,...args).all()).results;}
function price(item,w){return goods[item].price+(w.shortage&&['bread','soup','coat'].includes(item)?2:0)+(['bread','soup'].includes(item)?w.rationModifier||0:0);}
export async function ensureCitizen(db,owner,now=Date.now()){
  const id=uid();
  await stmt(db,'INSERT OR IGNORE INTO citizens (id,owner,name,data,updated) VALUES (?,?,?,?,?)',id,owner,'Citizen '+id.slice(0,4).toUpperCase(),JSON.stringify(initial(now)),now).run();
  return stmt(db,'SELECT * FROM citizens WHERE owner=?',owner).first();
}
async function ensureMarket(db,w){
  await db.batch(Object.entries(goods).map(([id,g])=>stmt(db,'INSERT INTO market (id,stock,day) VALUES (?,?,?) ON CONFLICT(id) DO UPDATE SET stock=min(?,market.stock+max(0,excluded.day-market.day)*?), day=max(market.day,excluded.day)',id,g.stock,w.day,g.stock,g.stock)));
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
  const c=await ensureCitizen(db,owner,now),w=world(now);
  await ensureMarket(db,w);
  const force=await cityForces(db,w);
  const project=await cityProject(db,w),citizen=settle(JSON.parse(c.data),now);personalState(citizen);
  const [stock,log,board,people,offers,totals]=await Promise.all([
    all(db,'SELECT * FROM market'),all(db,'SELECT body,created FROM journal WHERE citizen=? ORDER BY created DESC LIMIT 12',c.id),
    all(db,'SELECT p.id,p.body,p.created,c.name,c.data FROM posts p JOIN citizens c ON c.id=p.citizen ORDER BY p.created DESC LIMIT 20'),
    all(db,'SELECT id,name,data,updated FROM citizens ORDER BY updated DESC LIMIT 30'),
    all(db,'SELECT l.*,c.name FROM listings l JOIN citizens c ON c.id=l.seller WHERE l.sold=0 ORDER BY l.created DESC LIMIT 30'),
    stmt(db,"SELECT count(*) AS citizens, sum(CASE WHEN json_extract(data,'$.union')=1 THEN 1 ELSE 0 END) AS members FROM citizens").first(),
  ]);
  return {citizen:{id:c.id,name:c.name,...citizen},world:w,project,forces:force,encounters:encountersFor(citizen),
    goods:stock.map(s=>({...goods[s.id],id:s.id,stock:s.stock,price:price(s.id,w)})),jobs:Object.entries(jobs).map(([id,j])=>({id,...j})),
    log,board:board.map(p=>({id:p.id,name:p.name,body:p.body,created:p.created,role:JSON.parse(p.data).role})),
    citizens:people.map(p=>{const d=JSON.parse(p.data);return {id:p.id,name:p.name,role:d.role,rep:d.rep,shifts:d.shifts,union:d.union,online:now-p.updated<120000};}),listings:offers,totals};
}
export async function act(db,owner,input,now=Date.now()){
  need(input&&typeof input==='object'&&!Array.isArray(input),'Invalid action.');
  need(typeof input.action==='string','Choose an action.');
  const c=await ensureCitizen(db,owner,now),p=settle(JSON.parse(c.data),now),w=world(now);
  need(now-c.last_action>=650,'Give the city a moment before your next action.');
  await ensureMarket(db,w);
  const force=await cityForces(db,w);
  const project=await cityProject(db,w);personalState(p);
  const extra=[],checks=[],op=uid();let message='',hours=0,energy=0;
  const credit=n=>need(p.credits>=n,`You need ${n} credits. You have ${p.credits}.`);
  const job=typeof input.id==='string'&&Object.hasOwn(jobs,input.id)?jobs[input.id]:null;
  switch(input.action){
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
      need(job,'That job is no longer available.');need(p.rep>=job.requires,`You need ${job.requires} trust for this job.`);need(p.health>=15,'Visit the clinic or find medicine before another shift.');
      hours=job.hours;energy=job.energy;p.credits+=job.pay+(p.union?1:0);p.rep+=job.rep;p.shifts++;
      if(p.rep>=8&&p.role==='Worker')p.role='Trusted worker';
      message=`Completed a shift as ${job.name.toLowerCase()}. Earned ${job.pay+(p.union?1:0)} credits.`;break;
    }
    case 'buy':{
      const g=typeof input.id==='string'&&Object.hasOwn(goods,input.id)?goods[input.id]:null;need(g,'Unknown item.');const cost=price(input.id,w);credit(cost);
      if(input.id==='coat')need(!p.coat,'You already have an insulated shroud.');
      checks.push(stmt(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM market WHERE id=? AND stock>0),0))',op+'stock',input.id));
      extra.push(stmt(db,'UPDATE market SET stock=stock-1 WHERE id=?',input.id));p.credits-=cost;
      if(input.id==='soup'){p.fullness=clamp(p.fullness+35);p.warmth=clamp(p.warmth+18);message='Heated nutrient broth. Your implant marks the body as fed. For a moment, it is correct.';}
      else if(input.id==='coat'){p.coat=true;p.warmth=clamp(p.warmth+12);message='The shroud carries three erased civic signatures. Your implant adds a fourth.';}
      else {p[input.id]=(p[input.id]||0)+1;message=`Bought ${g.name.toLowerCase()} for ${cost} credits. It’s in your bag.`;}break;
    }
    case 'consume':{
      need(['bread','medicine'].includes(input.id),'That item cannot be used.');need(p[input.id]>0,'You don’t have that item.');p[input.id]--;
      if(input.id==='bread'){p.fullness=clamp(p.fullness+24);message='You consume the vat-grown ration. The printer thanks you for returning its biomass.';}else {p.health=clamp(p.health+30);message='The stabilizer silences an unfamiliar voice in your pulse. You can breathe a little easier.';}break;
    }
    case 'rest':hours=6;p.energy=clamp(p.energy+48);p.warmth=clamp(p.warmth+(p.evicted?0:28));p.health=clamp(p.health+8);message=p.evicted?'You sleep beneath the transit lattice. The masked commuters step around you.':'Six hours in your habitation cell. The wall terminal repeats a prayer in a voice you used to know.';break;
    case 'rent':credit(p.rentDebt);need(p.rentDebt>0,'Your rent is already paid.');p.credits-=p.rentDebt;message=`Paid ${p.rentDebt} credits in rent. You can stay another day.`;p.rentDebt=0;p.rentCycles=0;p.evicted=false;if(p.housing==='street')p.housing='bunk';break;
    case 'upgrade':credit(45);need(!p.evicted,'Settle your rent debt first.');need(p.housing!=='room','You already have a room.');p.credits-=45;p.housing='room';p.warmth=clamp(p.warmth+25);message='A room with a lock. Forty-five credits never bought so little freedom.';break;
    case 'crime':{
      need(['steal','smuggle'].includes(input.id),'Unknown opportunity.');hours=input.id==='steal'?1:3;energy=input.id==='steal'?12:22;
      const risk=clamp((input.id==='steal'?.3:.4)+(p.heat/200)+(w.inspection?.15:0)+(w.securityModifier||0),0,1);
      const random=crypto.getRandomValues(new Uint32Array(1))[0]/4294967296;
      if(random<risk){const fine=Math.min(p.credits,input.id==='steal'?7:15);p.credits-=fine;p.rep=Math.max(0,p.rep-2);p.heat=clamp(p.heat+20);p.health=clamp(p.health-8);message=`Security caught you. ${fine} credits confiscated. They remember your face.`;}
      else {p.heat=clamp(p.heat+12);if(input.id==='steal'){p.scrap+=3;message='Three relay fragments slip into your shroud. The mnemonic sentinel keeps reciting its prayer.';}else {p.credits+=w.contrabandPay||24;p.role='Smuggler';message=`The sealed mnemonic package reaches the other side. ${w.contrabandPay||24} credits enter your implant.`;}}break;
    }
    case 'sell':need(p.scrap>0,'You don’t have any relay fragments.');p.scrap--;p.credits+=3;message='Sold a relay fragment to the broker for 3 credits. It is still broadcasting when you leave.';break;
    case 'union':credit(4);need(!p.union,'You’re already a union member.');p.credits-=4;p.union=true;message='You pay 4 credits into the mutual-aid fund. You’re no longer alone.';break;
    case 'organize':need(p.union,'Join the union first.');hours=2;energy=12;p.rep+=2;p.role='Union organizer';p.heat=clamp(p.heat+5);message='You organize the Uncounted for the next shift. Trust grows. So does the Canon’s interest.';break;
    case 'clinic':credit(8);p.credits-=8;p.health=clamp(p.health+40);p.coherence=clamp(p.coherence+15);hours=1;message='The Somatic Ward resets your implant and treats the body attached to it. Eight credits.';break;
    case 'bribe':credit(12);need(p.heat>0,'You don’t have a security record to clear.');p.credits-=12;p.heat=Math.max(0,p.heat-35);message='The clerk misfiles your record. Twelve credits disappear with it.';break;
    case 'official':credit(60);need(p.rep>=20,'You need 20 trust to apply for a municipal post.');need(!p.official,'You already hold a municipal post.');p.credits-=60;p.official=true;p.role='Municipal official';message='Your application is approved. The processing fee was non-refundable.';break;
    case 'official_work':need(p.official,'You don’t hold a municipal post.');hours=2;energy=8;p.credits+=17;p.rep++;message='You process a stack of work permits. Seventeen credits for deciding who gets to wait.';break;
    case 'business':credit(90);need(p.rep>=10,'You need 10 trust for a trading license.');need(!p.business,'You already own a stall.');p.credits-=90;p.business=true;p.role='Shop owner';message='The exchange terminal accepts your signature. No guarantee of customers.';break;
    case 'business_work':need(p.business,'You don’t own a market stall.');need(p.bread>0||p.scrap>0,'Stock your terminal with rations or relay fragments first.');hours=2;energy=8;{const item=p.bread?'bread':'scrap';p[item]--;p.credits+=item==='bread'?7:8;message=`You sell ${goods[item].name.toLowerCase()} at your stall. ${item==='bread'?7:8} credits from the morning foot traffic.`;}break;
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
      extra.push(stmt(db,'UPDATE listings SET sold=1 WHERE id=?',input.id),stmt(db,"UPDATE citizens SET data=json_set(data,'$.credits',json_extract(data,'$.credits')+?),version=version+1 WHERE id=?",offer.price,offer.seller),stmt(db,'INSERT INTO journal (id,citizen,body,created) VALUES (?,?,?,?)',uid(),offer.seller,`Your ${goods[offer.item].name.toLowerCase()} sold for ${offer.price} credits.`,now));
      p.credits-=offer.price;p[offer.item]++;message=`Bought ${goods[offer.item].name.toLowerCase()} from another citizen for ${offer.price} credits.`;break;
    }
    case 'cancel':{
      const offer=await stmt(db,'SELECT * FROM listings WHERE id=? AND seller=? AND sold=0',String(input.id),c.id).first();need(offer,'Listing is no longer available.');
      checks.push(stmt(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM listings WHERE id=? AND sold=0),0))',op+'offer',offer.id));extra.push(stmt(db,'UPDATE listings SET sold=2 WHERE id=?',offer.id));p[offer.item]++;message='You take your goods back from the market.';break;
    }
    default:throw Object.assign(new Error('Unknown action.'),{status:400});
  }
  need(p.energy>=energy,`You need ${energy} energy. Rest before taking this job.`);p.energy=clamp(p.energy-energy);p.clock+=hours;
  p.fullness=clamp(p.fullness-hours*3);p.warmth=clamp(p.warmth-hours*Math.max(0,(p.coat?1:3)-(w.heating?1:0)));
  if(hours&&p.fullness<15)p.health=clamp(p.health-hours*2);if(hours&&p.warmth<15)p.health=clamp(p.health-hours);
  if(p.health===0){p.health=20;p.energy=20;p.credits=Math.max(0,p.credits-5);message+=' You collapse. The emergency ward patches you up and takes 5 credits.';}
  const final=settle(p,now);
  const statements=[stmt(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM citizens WHERE id=? AND version=?),0))',op,c.id,c.version),...checks,
    stmt(db,'UPDATE citizens SET data=?,version=version+1,last_action=?,updated=? WHERE id=?',JSON.stringify(final),now,now,c.id),...extra,
    stmt(db,'INSERT INTO journal (id,citizen,body,created) VALUES (?,?,?,?)',uid(),c.id,message,now),
    stmt(db,'DELETE FROM action_guards WHERE id=? OR id=? OR id=? OR id=?',op,op+'stock',op+'offer',op+'project')];
  try{await db.batch(statements);}catch(e){if(String(e).includes('guard_valid'))throw Object.assign(new Error('That offer or your balance just changed. Refresh and try again.'),{status:409});throw e;}
  return {message,...await snapshot(db,owner,now)};
}
