import {quickBlocked} from './street.js';
import {supplyCount,changeSupply} from './orders.js';
const recoveryNeed=(ok,message)=>{if(!ok)throw Object.assign(new Error(message),{status:400});};
export async function districtAftermath(db,w){
 const rows=(await db.prepare('SELECT c.*,n.id news FROM district_crises c LEFT JOIN district_news n ON n.id=c.id WHERE c.outcome IS NOT NULL ORDER BY c.day DESC LIMIT 12').all()).results;
 for(const row of rows){
  if(row.news)continue;
  const headline=row.type==='boiler'?(row.outcome==='secured'?'The cold line holds':'The cold line fails'):(row.outcome==='secured'?'Relief convoy enters District IX':'The relief convoy turns back');
  const crew=(await db.prepare('SELECT c.name,sum(a.repair) units FROM crisis_actions a JOIN citizens c ON c.id=a.citizen WHERE a.crisis=? AND a.completes<=? AND a.repair>0 GROUP BY a.citizen ORDER BY units DESC,c.name LIMIT 4').bind(row.id,row.deadline).all()).results;
  const body=`City day ${row.day}: ${row.repair} repair units and ${row.diversion} diversions against a target of ${row.target}. ${row.outcome==='secured'?'Completed civic work secured the response.':'The district opens recovery contracts; unresolved damage can affect the next four cycles.'}`;
  await db.prepare('INSERT OR IGNORE INTO district_news (id,day,headline,body,data,published) VALUES (?,?,?,?,?,?)').bind(row.id,row.day,headline,body,JSON.stringify({type:row.type,outcome:row.outcome,crew}),row.deadline).run();
 }
 const incidents=[];
 for(const row of rows.filter(r=>r.outcome==='failed'&&r.day<w.day&&r.day>=w.day-4)){
  const target=Math.max(3,Math.min(6,Math.ceil(row.target/2))),totals=await db.prepare('SELECT count(*) reserved,sum(CASE WHEN completes<=? THEN 1 ELSE 0 END) completed FROM recovery_actions WHERE crisis=?').bind(w.now,row.id).first();
  const completed=totals.completed||0,expiresAt=row.started+5*21600000;
  incidents.push({id:row.id,day:row.day,type:row.type,name:row.type==='boiler'?'Repair the damaged cold line':'Recover the turned-back convoy',art:row.type==='boiler'?'workshop':'transit',target,completed,reserved:totals.reserved,expiresAt,recovered:completed>=target,item:row.type==='boiler'?'wire':'data',seconds:40,energy:4,effect:row.type==='boiler'?'Unresolved boiler damage adds 0.5 cold per city hour.':'Unrecovered freight adds 1 CR to food prices.'});
 }
 if(incidents.some(r=>!r.recovered&&r.type==='boiler'))w.coldModifier+=.5;
 if(incidents.some(r=>!r.recovered&&r.type==='freight'))w.foodModifier++;
 const paper=(await db.prepare('SELECT * FROM district_news WHERE published<=? ORDER BY published DESC LIMIT 6').bind(w.now).all()).results.map(r=>({...r,record:JSON.parse(r.data)}));
 w.aftermath=incidents;return {incidents,paper};
}
export function recoveryBlocked(p,r,w){
 if(r.recovered||r.reserved>=r.target)return 'All recovery units are complete or assigned.';
 if(w.now+r.seconds*1000>r.expiresAt)return 'This recovery contract cannot meet its deadline.';
 if(p.aftermath?.day===w.day&&p.aftermath.count>=2)return 'Two recovery assignments per citizen per cycle.';
 return quickBlocked(p,{energy:r.energy,cost:{[r.item]:1},break:true},w.now);
}
export async function startRecovery(db,p,c,input,w,life,op){
 const r=life.aftermath.incidents.find(x=>x.id===input.id);recoveryNeed(r,'This recovery contract is no longer available.');const blocked=recoveryBlocked(p,r,w);recoveryNeed(!blocked,blocked);recoveryNeed(supplyCount(p,r.item)>=1,'Bring the declared recovery supply.');changeSupply(p,r.item,-1);p.energy-=r.energy;p.street.count++;if(p.aftermath?.day!==w.day)p.aftermath={day:w.day,count:0};p.aftermath.count++;
 p.errand={action:'recovery_work',id:r.id,label:r.name,art:r.art,started:w.now,endsAt:w.now+40000,reward:{credits:2,taxGross:2,rep:1},message:'One recovery unit completed. Two taxable credits and one trust; repaired damage stops affecting the district once the shared target is met.'};
 return {message:'Recovery assignment started. Forty seconds, four energy, and one supply reserved.',checks:[db.prepare('INSERT INTO action_guards (id,valid) VALUES (?,CASE WHEN (SELECT count(*) FROM recovery_actions WHERE crisis=?)<? THEN 1 ELSE 0 END)').bind(op+'recovery',r.id,r.target)],extra:[db.prepare('INSERT INTO recovery_actions (id,crisis,citizen,completes) VALUES (?,?,?,?)').bind(op,r.id,c.id,p.errand.endsAt)]};
}
