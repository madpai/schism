import {quickBlocked} from './street.js';
import {supplyCatalog,supplyCount,changeSupply} from './orders.js';
const tenantNeed=(ok,message)=>{if(!ok)throw Object.assign(new Error(message),{status:400});};
const tenantSql=(db,sql,...args)=>db.prepare(sql).bind(...args);
export function neighborState(p,day){p.neighborhood??={};const n=p.neighborhood;if(n.day!==day){n.day=day;n.withdrawals=0;}return n;}
export async function resolveTenant(db,id,now){
 let b=await tenantSql(db,'SELECT * FROM tenant_blocks WHERE id=?',id).first();if(!b)return null;
 if(b.heat_until>0&&b.heat_until<=now){await tenantSql(db,'UPDATE tenant_blocks SET heat_until=0,progress=0,round=round+1,version=version+1 WHERE id=? AND version=?',id,b.version).run();b=await tenantSql(db,'SELECT * FROM tenant_blocks WHERE id=?',id).first();}
 if(b.progress>=6&&!b.heat_until){const result=await tenantSql(db,'SELECT count(*) n,max(completes) last FROM tenant_repairs WHERE block=? AND round=? AND completes<=?',id,b.round,now).first();if(result.n>=6){await tenantSql(db,'UPDATE tenant_blocks SET heat_until=?,version=version+1 WHERE id=? AND version=? AND heat_until=0',result.last+86400000,id,b.version).run();b=await tenantSql(db,'SELECT * FROM tenant_blocks WHERE id=?',id).first();if(b.heat_until<=now)return resolveTenant(db,id,now);}}
 return b;
}
export async function tenantMembership(db,citizen,now){
 const m=await tenantSql(db,'SELECT block,joined FROM tenant_members WHERE citizen=?',citizen).first();if(!m)return null;
 const b=await resolveTenant(db,m.block,now);if(!b)return null;
 // Keep completed rounds authoritative even after their active UI state resets.
 // Offline residents receive only protection after joining and actual completion.
 const rounds=(await tenantSql(db,'SELECT round,max(completes) completed FROM tenant_repairs WHERE block=? AND completes<=? GROUP BY round HAVING count(*)>=6 ORDER BY round DESC LIMIT 10',m.block,now).all()).results;
 return {...b,heatWindows:rounds.map(r=>({from:Math.max(r.completed,m.joined),until:r.completed+86400000})).filter(r=>r.from<r.until)};
}
export async function tenantSnapshot(db,citizen,p,w){
 neighborState(p,w.day);const b=await tenantMembership(db,citizen,w.now);
 const directory=(await tenantSql(db,'SELECT b.id,b.name,b.heat_until,count(m.citizen) members FROM tenant_blocks b LEFT JOIN tenant_members m ON m.block=b.id GROUP BY b.id ORDER BY b.created DESC LIMIT 30').all()).results;
 if(!b)return {block:null,directory,capacity:12,catalog:supplyCatalog};
 const [members,messages,log,repair]=await Promise.all([
 tenantSql(db,'SELECT c.id,c.name FROM tenant_members m JOIN citizens c ON c.id=m.citizen WHERE m.block=? ORDER BY m.joined',b.id).all(),
 tenantSql(db,'SELECT m.body,m.created,c.name FROM tenant_messages m JOIN citizens c ON c.id=m.citizen WHERE m.block=? ORDER BY m.created DESC LIMIT 40',b.id).all(),
 tenantSql(db,'SELECT a.item,a.quantity,a.kind,a.created,c.name FROM tenant_transfers a JOIN citizens c ON c.id=a.citizen WHERE a.block=? ORDER BY a.created DESC LIMIT 20',b.id).all(),
 tenantSql(db,'SELECT count(*) n FROM tenant_repairs WHERE block=? AND round=? AND completes<=?',b.id,b.round,w.now).first(),
 ]);
 return {block:{id:b.id,name:b.name,founder:b.founder,stock:JSON.parse(b.stock),progress:repair.n,reserved:b.progress,target:6,heatUntil:b.heat_until,round:b.round},members:members.results,messages:messages.results,log:log.results,directory,capacity:12,catalog:supplyCatalog,withdrawUsed:!!p.neighborhood.withdrawals};
}
export async function tenantAction(db,p,c,input,w,op){
 neighborState(p,w.day);const extra=[],checks=[],q=(sql,...args)=>tenantSql(db,sql,...args),b=await tenantMembership(db,c.id,w.now);let message='';
 const checkBlock=()=>checks.push(q('INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM tenant_blocks WHERE id=? AND version=?),0))',op+'building',b.id,b.version));
 if(input.action==='tenant_create'){
  tenantNeed(!b,'Leave your current association before creating another.');tenantNeed(typeof input.name==='string'&&/^[\p{L}\p{N} ._-]{3,32}$/u.test(input.name.trim()),'Use a building name of 3–32 letters, numbers, or basic punctuation.');tenantNeed(!await q('SELECT id FROM tenant_blocks WHERE founder=?',c.id).first(),'You have already founded an association. Join an existing one.');
  const id=crypto.randomUUID();extra.push(q('INSERT INTO tenant_blocks (id,name,founder,stock,created) VALUES (?,?,?,\'{}\',?)',id,input.name.trim(),c.id,w.now),q('INSERT INTO tenant_members (citizen,block,joined) VALUES (?,?,?)',c.id,id,w.now));p.neighborhood.memberEver=true;message='A free tenant association is registered. Twelve neighbors can share a shelf, talk, and repair the building together.';
 }else if(input.action==='tenant_join'){
  tenantNeed(!b,'You already belong to a tenant association.');const target=await q('SELECT * FROM tenant_blocks WHERE id=?',input.id).first();tenantNeed(target,'This association is unavailable.');const count=await q('SELECT count(*) n FROM tenant_members WHERE block=?',input.id).first();tenantNeed(count.n<12,'This association has twelve residents.');
  checks.push(q('INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM tenant_blocks WHERE id=? AND version=?),0))',op+'building',target.id,target.version));extra.push(q('UPDATE tenant_blocks SET version=version+1 WHERE id=?',target.id),q('INSERT INTO tenant_members (citizen,block,joined) VALUES (?,?,?)',c.id,target.id,w.now));p.neighborhood.memberEver=true;message='You join the tenant association. Its supplies belong to the shared shelf; every transfer is visible to members.';
 }else{
  tenantNeed(b,'Join a tenant association first.');const stock=JSON.parse(b.stock);
  if(input.action==='tenant_post'){
   tenantNeed(typeof input.body==='string'&&input.body.trim().length>=1&&input.body.trim().length<=320,'Write 1–320 characters.');const last=await q('SELECT max(created) latest,count(*) n FROM tenant_messages WHERE citizen=? AND created>?',c.id,w.now-3600000).first();tenantNeed(!last.latest||w.now-last.latest>=15000,'Wait fifteen seconds between building messages.');tenantNeed(last.n<40,'Forty building messages per real hour.');extra.push(q('INSERT INTO tenant_messages (id,block,citizen,body,created) VALUES (?,?,?,?,?)',op,b.id,c.id,input.body.trim(),w.now));message='Your message reaches your building neighbors.';
  }else if(input.action==='tenant_leave'){
   tenantNeed(!p.errand||p.errand.action!=='tenant_repair','Finish your building repair before leaving.');checkBlock();extra.push(q('DELETE FROM tenant_members WHERE citizen=?',c.id),q('UPDATE tenant_blocks SET version=version+1 WHERE id=?',b.id));message='You leave the association. Donated supplies and completed work stay with the building.';
  }else if(input.action==='tenant_repair'){
   tenantNeed(!b.heat_until||b.heat_until<=w.now,'The building repair is holding. Save supplies for its next maintenance round.');tenantNeed(b.progress<6,'All six repair units are reserved; wait for completion.');const blocked=quickBlocked(p,{energy:4,break:true},w.now);tenantNeed(!blocked,blocked);tenantNeed((stock.wire||0)>=1&&(stock.cloth||0)>=1,'The shared shelf needs one wire and one fabric for this repair.');
   stock.wire--;stock.cloth--;p.energy-=4;p.street.count++;p.errand={action:'tenant_repair',id:b.id,label:'Seal the building’s draught line',art:'bunkhouse',started:w.now,endsAt:w.now+30000,reward:{},message:'One shared repair unit completed. Six units protect building members from 0.75 cold per city hour for twenty-four real hours.'};
   checkBlock();extra.push(q('UPDATE tenant_blocks SET stock=?,progress=progress+1,version=version+1 WHERE id=?',JSON.stringify(stock),b.id),q('INSERT INTO tenant_repairs (id,block,citizen,round,completes) VALUES (?,?,?,?,?)',op,b.id,c.id,b.round,p.errand.endsAt));message='Repairing the draught line: thirty seconds, four energy, one shared wire and fabric. Protection begins after the sixth unit actually finishes.';
  }else{
   tenantNeed(typeof input.item==='string'&&Object.hasOwn(supplyCatalog,input.item),'Choose a published supply.');const withdrawal=input.action==='tenant_take';tenantNeed(withdrawal||input.action==='tenant_donate','Choose a building action.');const amount=withdrawal?1:input.quantity;
   tenantNeed(Number.isInteger(amount)&&amount>=1&&amount<=5,'Donate 1–5 units.');checkBlock();
   if(withdrawal){tenantNeed(['bread','heatpack','bandage','medicine','neuralpatch'].includes(input.item),'The relief shelf releases consumables only. Materials stay for shared repairs.');tenantNeed(!p.neighborhood.withdrawals,'One relief-shelf item per citizen per cycle, across all buildings.');tenantNeed((stock[input.item]||0)>=1,'The shelf has no stock of that item.');stock[input.item]--;changeSupply(p,input.item,1);p.neighborhood.withdrawals=1;message='One shared consumable enters your bag. Your neighbors can see the withdrawal.';}
   else{tenantNeed(supplyCount(p,input.item)>=amount,'Donate supplies you actually own.');tenantNeed((stock[input.item]||0)+amount<=100,'The shelf holds at most one hundred of each supply.');changeSupply(p,input.item,-amount);stock[input.item]=(stock[input.item]||0)+amount;message='Your supplies enter the shared shelf. They remain with this building if you leave.';}
   extra.push(q('UPDATE tenant_blocks SET stock=?,version=version+1 WHERE id=?',JSON.stringify(stock),b.id),q('INSERT INTO tenant_transfers (id,block,citizen,item,quantity,kind,created) VALUES (?,?,?,?,?,?,?)',op,b.id,c.id,input.item,amount,withdrawal?'take':'donate',w.now));
  }
 }
 return {message,extra,checks};
}
