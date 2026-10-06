import {quickBlocked} from './street.js';
import {tenantMembership} from './tenants.js';
const alphaNeed=(ok,message)=>{if(!ok)throw Object.assign(new Error(message),{status:400});};
const alphaSql=(db,sql,...args)=>db.prepare(sql).bind(...args);
export function stairState(p){
 p.district??={};p.district.contacts??={};p.district.flags??={};p.district.stair??={node:'invitation',readyAt:0,choices:[]};
 return p.district.stair;
}
const stairScenes={
 invitation:{contact:'neri',title:'A light on the stair',text:'Neri catches you beside the free bunks. The stair lamp went out three nights ago. Someone fell carrying a ration. The Canon marked the lamp repaired. Esra, who works the maintenance line, has never seen the replacement.',choices:[{id:'listen',label:'Ask Neri what happened.',preview:'No energy or credits · Meet Neri and Esra'}]},
 inspection:{contact:'esra',title:'A repair on paper',text:'Esra opens the lamp housing. The old coil is still inside. Her crew signed for a replacement that never arrived. She asks you to check the socket while she finds the allocation sheet.',task:'stair_inspect',choices:[]},
 inspecting:{contact:'esra',title:'Checking the socket',text:'Esra holds the housing steady while you trace the socket. The inspection will finish in thirty seconds. Its energy is already spent.',choices:[]},
 allocation:{contact:'esra',title:'Someone has already been paid',text:'The socket works. The allocation sheet carries the contractor’s stamp and a payment. Esra wants that discrepancy recorded. Neri wants a safe stair tonight, without inspectors searching the bunks.',choices:[{id:'record',label:'Record the missing allocation with Esra.',preview:'Esra +2 · Order +1 · Heat +1 · The public record names the repair'},{id:'quiet',label:'Promise Neri a repair without the report.',preview:'Neri +2 · Chaos +1 · Keep the crew out of the public record'}]},
 materials:{contact:'neri',title:'Copper and a strip of fabric',text:'Esra can rebuild the lamp with one copper wire and one fabric strip to insulate the grip. Bring supplies you own, or use your association’s shared shelf. A quiet district can still repair its own stair.',task:'stair_repair',choices:[]},
 repairing:{contact:'esra',title:'Hands inside the housing',text:'The repair is underway. Its supplies and energy have already been spent. The lamp will light when the work finishes.',choices:[]},
 account:{contact:'neri',title:'The first person down the stair',text:'Neri carries a bowl down the lit steps. Nobody has to feel for the broken rail tonight. Esra asks whose name should stay in the crew’s private account of the work.',choices:[{id:'crew',label:'Remember the people who made it possible.',preview:'Esra +1 · The crew remembers your choice'},{id:'neighbor',label:'Ask them to remember who needed the light.',preview:'Neri +1 · Neri remembers your choice'}]},
 return:{contact:'esra',title:'The next maintenance sheet',text:'The lamp is working. Esra will check the next cycle’s allocation and send you the result. Your repair is complete; you can leave and return for her message.',choices:[{id:'answer',label:'Read Esra’s follow-up.',preview:'No energy or credits · A lasting neighborhood history'}]},
 done:{contact:'neri',title:'A familiar stair',text:'Neri leaves room beside her at the fire. The stair has a history now, and both women know your part in it. Your choice will remain after the lamp needs maintenance again.',choices:[]},
};
function stairGate(p,w){return p.detainedUntil>w.now?'Wait until your release.':p.activity&&p.activity.action!=='work'?'This assignment needs your attention.':null;}
export async function stairSnapshot(db,p,citizen,w){
 const s=stairState(p),scene=stairScenes[s.node]||stairScenes.invitation,b=await tenantMembership(db,citizen,w.now),stock=b?JSON.parse(b.stock):{};
 const blocked=stairGate(p,w)||(s.readyAt>w.now?'A reply is still on its way.':null);
 const taskBlocked=quickBlocked(p,{energy:s.node==='inspection'?2:3,break:true},w.now);
 const canOwn=(p.materials?.wire||0)>=1&&(p.materials?.cloth||0)>=1,canShared=(stock.wire||0)>=1&&(stock.cloth||0)>=1;
 return {...scene,text:s.node==='done'?s.epilogue||scene.text:scene.text,id:'stair',node:s.node,readyAt:s.readyAt,route:s.route,completedAt:s.completedAt||0,credit:s.credit,blocked,choices:scene.choices.map(ch=>({...ch,blocked})),inspectBlocked:blocked||taskBlocked,ownBlocked:blocked||taskBlocked||(!canOwn?'Need one owned wire and fabric.':null),sharedBlocked:blocked||taskBlocked||(!b?'Join an association to use its shelf.':!canShared?'The shared shelf needs one wire and fabric.':null),building:b&&{id:b.id,name:b.name},owned:{wire:p.materials?.wire||0,cloth:p.materials?.cloth||0},shared:{wire:stock.wire||0,cloth:stock.cloth||0},history:s.choices};
}
export async function stairAction(db,p,c,input,w,op){
 const s=stairState(p),extra=[],checks=[];
 alphaNeed(!stairGate(p,w),stairGate(p,w));alphaNeed(s.readyAt<=w.now,'A reply is still on its way.');
 if(input.action==='stair_choice'){
  alphaNeed(input.node===s.node,'This part of the story has already changed.');
  const ch=(stairScenes[s.node]?.choices||[]).find(x=>x.id===input.choice);alphaNeed(ch,'Choose a published response.');
  s.choices.push({node:s.node,choice:ch.id,created:w.now});
  if(s.node==='invitation'){p.district.contacts.neri=(p.district.contacts.neri||0)+1;s.node='inspection';s.readyAt=w.now;}
  else if(s.node==='allocation'){
   s.route=ch.id;s.node='materials';s.readyAt=w.now+60000;
   const contact=ch.id==='record'?'esra':'neri';p.district.contacts[contact]=(p.district.contacts[contact]||0)+2;
   p.alignment=Math.max(-100,Math.min(100,p.alignment+(ch.id==='record'?1:-1)));if(ch.id==='record')p.heat=Math.min(100,p.heat+1);
  }else if(s.node==='account'){
   s.credit=ch.id;s.node='return';s.readyAt=Math.max(w.now+60000,w.now+(24-w.hour)*900000-(w.now%900000));
   const contact=ch.id==='crew'?'esra':'neri';p.district.contacts[contact]=(p.district.contacts[contact]||0)+1;
  }else if(s.node==='return'){
   s.node='done';s.readyAt=w.now;p.district.flags.stairNeighbor=true;s.epilogue=s.route==='record'?'Esra lays out the next allocation sheet. The missing coil is named, and the contractor must answer for it. Neri is wary of the inspectors, but the lamp still lights the stair. The crew remembers your account of the work.':'Esra brings a spare coil without a contractor’s stamp. Neri’s neighbors stay off the inspection list. The lamp holds; the original missing payment is still absent from the public record. The crew remembers your account of the work.';
  }
  return {message:s.node==='materials'?(s.route==='record'?'Esra files the missing allocation. Neri sends a supply list in one minute.':'Neri keeps the crew out of the report. Esra sends a supply list in one minute.'):s.node==='return'?'The lamp is repaired. Esra’s follow-up arrives next cycle; no need to wait here.':s.node==='done'?(s.route==='record'?'The next allocation names the missing coil. Esra has a record the contractor cannot quietly erase.':'Esra quietly redirects a spare coil to the stair. Neri’s neighbors stay out of the inspection list.'):'Esra is waiting beside the lamp. Check its socket.',extra,checks};
 }
 if(input.action==='stair_inspect'){
  alphaNeed(s.node==='inspection','The socket inspection is already handled.');
  const blocked=quickBlocked(p,{energy:2,break:true},w.now);alphaNeed(!blocked,blocked);
  p.energy-=2;p.street.count++;s.node='inspecting';
  p.errand={action:'stair_inspect',label:'Inspect the bunkhouse stair lamp',art:'bunkhouse',started:w.now,endsAt:w.now+30000,reward:{},message:'The socket still works. Esra finds a paid allocation for a replacement that never arrived.'};
  return {message:'Checking the socket: thirty seconds, two energy. This fits a work break.',extra,checks};
 }
 alphaNeed(input.action==='stair_repair'&&s.node==='materials','Choose the current stair repair.');
 alphaNeed(input.method==='owned'||input.method==='shared','Choose owned supplies or the shared shelf.');
 const blocked=quickBlocked(p,{energy:3,break:true},w.now);alphaNeed(!blocked,blocked);
 const b=await tenantMembership(db,c.id,w.now);
 if(input.method==='owned'){
  alphaNeed(p.materials.wire>=1&&p.materials.cloth>=1,'Bring one owned wire and fabric.');p.materials.wire--;p.materials.cloth--;
 }else{
  alphaNeed(b,'Join an association first.');const stock=JSON.parse(b.stock);
  alphaNeed((stock.wire||0)>=1&&(stock.cloth||0)>=1,'The shelf needs one wire and fabric.');stock.wire--;stock.cloth--;
  checks.push(alphaSql(db,'INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM tenant_blocks WHERE id=? AND version=?),0))',op+'stair',b.id,b.version));
  extra.push(alphaSql(db,'UPDATE tenant_blocks SET stock=?,version=version+1 WHERE id=?',JSON.stringify(stock),b.id),...['wire','cloth'].map(item=>alphaSql(db,'INSERT INTO tenant_transfers (id,block,citizen,item,quantity,kind,created) VALUES (?,?,?,?,1,?,?)',op+item,b.id,c.id,item,'stair',w.now)));
 }
 p.energy-=3;p.street.count++;s.node='repairing';s.method=input.method;s.block=b?.id||null;
 p.errand={action:'stair_repair',label:'Restore the light on the stair',art:'workshop',started:w.now,endsAt:w.now+45000,reward:{rep:2},message:'The stair lamp lights. Neri and Esra remember the work. Two trust earned; your account of the repair arrives in one minute.'};
 extra.push(alphaSql(db,'INSERT INTO stair_events (id,citizen,block,route,method,completes) VALUES (?,?,?,?,?,?)',op,c.id,s.block,s.route,input.method,p.errand.endsAt));
 return {message:'Repairing the lamp: forty-five seconds, three energy, one wire and fabric. The light begins at completion.',extra,checks};
}
export function completeStair(p,task){
 const s=stairState(p);
 if(task.action==='stair_inspect'){s.node='allocation';s.readyAt=task.endsAt;}
 if(task.action==='stair_repair'){
  s.node='account';s.completedAt=task.endsAt;s.readyAt=task.endsAt+60000;
  for(const id of ['neri','esra'])p.district.contacts[id]=(p.district.contacts[id]||0)+1;
 }
}
export function shiftMoment(p,w){
 const a=p.activity;
 if(!a||a.action!=='work'||a.started+30000>w.now||p.district.shiftChoiceDay===w.day)return null;
 const name={sorting:'A memory with a name',hauling:'A crate outside the manifest',cleaning:'The stain below the wage terminal',maintenance:'A repair without a receipt'}[a.job]||'The worker beside the terminal';
 return {title:name,started:a.started,text:'Esra spots work missing from the machine’s count. You can spend a moment preserving its record, or accept a small shortcut payment. The choice settles with this shift.',choices:[{id:'record',label:'Keep the missing work in the record.',preview:'−1 energy now · Esra +1 and +1 trust at shift completion',blocked:p.energy<1?'Need one energy.':null},{id:'shortcut',label:'Accept the shortcut payment.',preview:'+1 taxable CR at shift completion · +2 heat now',blocked:null}]};
}
export function chooseShiftMoment(p,input,w){
 const m=shiftMoment(p,w);alphaNeed(m&&input.started===m.started,'This shift’s decision is no longer available.');
 const ch=m.choices.find(x=>x.id===input.choice);alphaNeed(ch,'Choose a published response.');alphaNeed(!ch.blocked,ch.blocked);
 const a=p.activity;p.district.shiftChoiceDay=w.day;p.district.shiftDecision={choice:ch.id,job:a.job,created:w.now};
 if(ch.id==='record'){
  p.energy--;a.deltas.rep=(a.deltas.rep||0)+1;a.stairContact='esra';a.message+=' Your preserved work record earns one additional trust. Esra remembers your help.';
 }else{
  p.heat=Math.min(100,p.heat+2);a.deltas.credits=(a.deltas.credits||0)+1;a.taxGross=(a.taxGross||0)+1;a.message+=' Your shortcut payment adds one taxable credit.';
 }
 return ch.id==='record'?'You preserve the record. The extra trust and Esra’s acknowledgement arrive with this shift.':'You accept the shortcut. One additional taxable credit arrives with this shift; two heat is recorded now.';
}
export async function stairNews(db,w){
 return (await alphaSql(db,'SELECT s.route,s.method,s.completes,c.name,b.name building FROM stair_events s JOIN citizens c ON c.id=s.citizen LEFT JOIN tenant_blocks b ON b.id=s.block WHERE s.completes<=? ORDER BY s.completes DESC LIMIT 8',w.now).all()).results.map(s=>({...s,name:s.route==='record'?s.name:null,headline:s.route==='record'?'A missing allocation enters the record':'A stair lamp returns without a contractor notice'}));
}
export function alphaProgress(p){
 stairState(p);p.district.depositSaved||=p.credits>=45||['room','flat'].includes(p.housing);
 return {goals:[{id:'first_shift',name:'Earn your first wages',done:p.shifts>=1,progress:Math.min(1,p.shifts),target:1,where:'jobs'},{id:'stair',name:'Leave a light for the next arrival',done:!!p.district.stair?.completedAt,progress:p.district.stair?.completedAt?1:0,target:1,where:'encounters'},{id:'rank',name:'Earn your first career rank',done:Object.values(p.careers||{}).some(c=>c.xp>=24),progress:Math.min(24,Math.max(0,...Object.values(p.careers||{}).map(c=>c.xp||0))),target:24,where:'careers'},{id:'room',name:'Save a private-room deposit',done:!!p.district.depositSaved,progress:Math.min(45,p.credits),target:45,where:'housing'}]};
}
