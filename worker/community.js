const communitySql=(db,sql,...args)=>db.prepare(sql).bind(...args);
const communityNeed=(ok,message,status=400)=>{if(!ok)throw Object.assign(new Error(message),{status});};
export function operatorContext(request,env){
 const email=request.headers.get('oai-authenticated-user-email')?.trim().toLowerCase();
 const owner=request.headers.get('oai-authenticated-user-id');
 const operator=!!owner&&!!email&&email===env.SCHISM_OPERATOR_EMAIL?.trim().toLowerCase();
 const moderators=(env.SCHISM_MODERATOR_EMAILS||'').toLowerCase().split(',').map(s=>s.trim()).filter(Boolean);
 return {operator,moderator:operator||!!owner&&!!email&&moderators.includes(email)};
}
export async function communitySnapshot(db,citizen,w,context={}){
 const mute=await communitySql(db,'SELECT until FROM community_mutes WHERE citizen=? AND until>?',citizen,w.now).first();
 const result={moderator:!!context.moderator,operator:!!context.operator,mutedUntil:mute?.until||0};
 if(context.moderator)result.reports=(await communitySql(db,'SELECT r.*,c.name reporterName,a.name authorName FROM community_reports r JOIN citizens c ON c.id=r.reporter LEFT JOIN citizens a ON a.id=r.author ORDER BY CASE WHEN r.status=\'open\' THEN 0 ELSE 1 END,r.created DESC LIMIT 80').all()).results;
 return result;
}
export async function communityAction(db,c,input,w,op,context={}){
 const q=(sql,...args)=>communitySql(db,sql,...args),extra=[],checks=[];
 if(input.action==='feedback'||input.action==='report'){
  const last=await q('SELECT count(*) n FROM community_reports WHERE reporter=? AND created>?',c.id,w.now-86400000).first();communityNeed(last.n<12,'Twelve reports or feedback notes per real day.');
  communityNeed(typeof input.reason==='string'&&input.reason.trim().length>=3&&input.reason.trim().length<=500,'Describe the problem in 3–500 characters.');
  let source='feedback',message=op,author=null,body='Player feedback';
  if(input.action==='report'){
   communityNeed(['network','board','tenant'].includes(input.source),'Choose a visible community message.');source=input.source;message=input.id;
   communityNeed(typeof message==='string','Choose a message.');
   const sql={network:'SELECT citizen,body FROM neural_messages WHERE id=?',board:'SELECT citizen,body FROM posts WHERE id=?',tenant:'SELECT m.citizen,m.body FROM tenant_messages m JOIN tenant_members t ON t.block=m.block AND t.citizen=? WHERE m.id=?'}[source];
   const row=await (source==='tenant'?q(sql,c.id,message):q(sql,message)).first();communityNeed(row,'This message is not available to you.');author=row.citizen;body=row.body;
   communityNeed(!await q('SELECT id FROM community_reports WHERE reporter=? AND source=? AND message=?',c.id,source,message).first(),'You have already reported this message.');
   checks.push(q('INSERT INTO action_guards (id,valid) VALUES (?,CASE WHEN EXISTS(SELECT 1 FROM community_reports WHERE reporter=? AND source=? AND message=?) THEN 0 ELSE 1 END)',op+'report',c.id,source,message));
  }
  extra.push(q('INSERT INTO community_reports (id,reporter,source,message,author,body,reason,created) VALUES (?,?,?,?,?,?,?,?)',op,c.id,source,message,author,body,input.reason.trim(),w.now));
  return {message:source==='feedback'?'Your feedback is saved for the game’s operator. Thank you for helping shape the district.':'Your report is saved for a moderator. It is private.',extra,checks};
 }
 communityNeed(context.moderator,'Moderator access required.',403);
 const report=await q('SELECT * FROM community_reports WHERE id=?',input.id).first();communityNeed(report&&report.status==='open','This report is already resolved or unavailable.');
 communityNeed(['dismiss','hide','mute'].includes(input.resolution),'Choose a published moderation action.');
 communityNeed(input.resolution==='dismiss'||report.source!=='feedback','Feedback can be acknowledged without hiding a message.');
 checks.push(q('INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM community_reports WHERE id=? AND status=\'open\'),0))',op+'moderation',report.id));
 if(input.resolution!=='dismiss')extra.push(q('INSERT OR IGNORE INTO community_hidden (source,message,moderator,created) VALUES (?,?,?,?)',report.source,report.message,c.id,w.now));
 if(input.resolution==='mute')extra.push(q('INSERT INTO community_mutes (citizen,until,moderator,created) VALUES (?,?,?,?) ON CONFLICT(citizen) DO UPDATE SET until=max(until,excluded.until),moderator=excluded.moderator,created=excluded.created',report.author,w.now+86400000,c.id,w.now));
 extra.push(q('UPDATE community_reports SET status=\'resolved\',resolution=?,moderator=?,resolved=? WHERE id=?',input.resolution,c.id,w.now,report.id));
 return {message:input.resolution==='mute'?'Message hidden; its author cannot post community messages for twenty-four hours.':input.resolution==='hide'?'The message is hidden from community feeds.':'The report is acknowledged and closed.',extra,checks};
}
export async function postingAllowed(db,citizen,now){
 const mute=await communitySql(db,'SELECT until FROM community_mutes WHERE citizen=? AND until>?',citizen,now).first();communityNeed(!mute,'Community posting is paused until your moderation timeout ends.',403);
}
export async function requestBudget(db,owner,kind,now=Date.now()){
 const minute=Math.floor(now/60000),limit=kind==='state'?90:kind==='action'?60:4;
 const row=await communitySql(db,'INSERT INTO request_windows (owner,kind,window,count) VALUES (?,?,?,1) ON CONFLICT(owner,kind) DO UPDATE SET count=CASE WHEN request_windows.window=excluded.window THEN request_windows.count+1 ELSE 1 END,window=excluded.window RETURNING count',owner,kind,minute).first();
 communityNeed(row.count<=limit,'Too many requests. Try again in one minute.',429);
}
export const backupTables=['device_offers','device_demand','camp_production','citizens','market','journal','posts','listings','projects','forces','city_activity','maintenance_runs','neural_messages','supply_orders','district_crises','crisis_actions','tenant_blocks','tenant_members','tenant_messages','tenant_transfers','tenant_repairs','recovery_actions','district_news','stair_events','tenant_requests','community_reports','community_hidden','community_mutes'];
export async function exportCity(db){
 const rows=await db.batch(backupTables.map(name=>db.prepare('SELECT * FROM '+name+' LIMIT 10001')));
 communityNeed(rows.every(r=>r.results&&r.results.length<=10000),'City export exceeds the alpha backup limit. Use a database export before proceeding.',409);
 return {format:'schism-city-backup-v1',version:'0.10.0',exportedAt:new Date().toISOString(),tables:Object.fromEntries(backupTables.map((name,i)=>[name,rows[i].results]))};
}
