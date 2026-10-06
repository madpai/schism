// Short activities use their own server-timed slot. No client outcomes or clocks.
export const materials={cloth:{name:'Salvaged fabric',icon:'coat',description:'Clean strips cut from discarded civic textiles.'},wire:{name:'Copper wire',icon:'energy',description:'Enough live copper for one more improvised repair.'},circuit:{name:'Circuit parts',icon:'box',description:'Small components recovered from dead terminals.'},data:{name:'Signal traces',icon:'energy',description:'Fragments of the district network waiting to be decoded.'}};
export const streetTasks={
 bins:{name:'Search collection bins',area:'Reclamation alley',art:'scavenge',seconds:25,energy:4,break:false,description:'Recover fabric or copper from municipal waste. No credits guaranteed.'},
 textiles:{name:'Unpick discarded textiles',area:'Bunkhouse laundry',art:'bunkhouse',seconds:30,energy:4,break:false,description:'Recover two fabric strips from abandoned uniforms. A reliable source for mending and repairs.'},
 salvage:{name:'Strip dead electronics',area:'Service tunnels',art:'scavenge',seconds:45,energy:5,break:false,description:'Recover two wire and one circuit part. Exposed contacts can cost 2 health.'},
 sweep:{name:'Clean a public terminal',area:'Civic concourse',art:'registry',seconds:20,energy:3,break:true,description:'Earn 1 taxable credit. Small work with no career or trust shortcut.'},
 decode:{name:'Decode a stray signal',area:'Neural relay',art:'neural',seconds:35,energy:4,break:true,description:'Recover one signal trace for network contracts or neural patching.'},
 repair:{name:'Patch a heating relay',area:'Cell Stack IX',art:'workshop',seconds:60,energy:6,break:true,cost:{wire:1},description:'Spend one wire. Earn 2 taxable credits and add one district relief.'},
};
export const recipes={
 heatpack:{name:'Improvised warming pack',seconds:45,energy:3,cost:{cloth:2,wire:1},effect:'+14 warmth',description:'An exothermic pouch stitched from salvaged lining.'},
 bandage:{name:'Clean field dressing',seconds:35,energy:3,cost:{cloth:2},effect:'+10 health',description:'A stopgap until you can afford the Somatic Ward.'},
 scrap:{name:'Rebuilt relay fragment',seconds:75,energy:6,cost:{wire:3,circuit:1},effect:'One relay fragment',description:'Rebuild a small part for district repairs or sale.'},
 neuralpatch:{name:'Neural grounding patch',seconds:60,energy:5,cost:{circuit:2,data:2},effect:'+12 coherence',description:'Anchor your implant against the voices behind the signal.'},
};
export const quickSupplies={heatpack:{name:'Improvised warming pack',effect:'+14 warmth',icon:'temp'},bandage:{name:'Clean field dressing',effect:'+10 health',icon:'health'},neuralpatch:{name:'Neural grounding patch',effect:'+12 coherence',icon:'energy'}};
export const neuralChannels={district:{name:'District IX',description:'Citizen conversation, questions, and warnings.'},exchange:{name:'Exchange wire',description:'Trade offers and wanted supplies.'},uncounted:{name:'The Uncounted',description:'Workers, mutual aid, and organizing.'}};
const bound=(n,min=0,max=100)=>Math.max(min,Math.min(max,n));
const reject=(ok,message)=>{if(!ok)throw Object.assign(new Error(message),{status:400});};
export function streetState(p,day){
 p.materials??={};for(const id of Object.keys(materials))p.materials[id]??=0;
 for(const id of Object.keys(quickSupplies))p[id]??=0;
 p.workshopXP??=0;p.street??={day,count:0,games:0,leads:[]};
 if(p.street.day!==day)p.street={day,count:0,games:0,leads:[]};return p;
}
export function networkLeads(w){return [
 {id:'public',name:'Reconcile a freight manifest',seconds:50,energy:5,art:'transit',cost:{data:1},description:'Send one signal trace to the public relay. Earn 2 taxable credits, 1 trust, and one freight contribution.'},
 {id:'wound',name:'Deliver an unregistered echo',seconds:50,energy:6,art:'neural',cost:{data:1},description:'Send one signal trace through a hidden route. Earn 3 unreported credits, +4 heat, −1 alignment, and one criminal contribution.'},
 ];}
export function quickBlocked(p,item,now){
 return !p.registered?'Register your character first.':p.errand?'Finish your current short task.':p.detainedUntil>now?'Your sentence is still running.':p.activity&&p.activity.action!=='work'?'This assignment needs your full attention.':p.activity&&item.break===false?'Leave the street until your shift is over.':p.street.count>=10?'Ten short tasks per city cycle. The district has no more work for you.':p.health<15?'Treatment needed.':p.energy<item.energy?`Need ${item.energy} energy.`:Object.entries(item.cost||{}).some(([id,n])=>(p.materials[id]||0)<n)?'Missing materials.':null;
}
export function streetSnapshot(p,w){streetState(p,w.day);return {limit:10,used:p.street.count,materials,recipes:Object.entries(recipes).map(([id,r])=>({id,...r,break:true,blocked:quickBlocked(p,{...r,break:true},w.now)})),tasks:Object.entries(streetTasks).map(([id,t])=>({id,...t,blocked:quickBlocked(p,t,w.now)})),supplies:quickSupplies,channels:neuralChannels,leads:networkLeads(w).map(l=>({...l,break:true,blocked:p.street.leads.includes(l.id)?'Contract completed or accepted this cycle.':quickBlocked(p,{...l,break:true},w.now)})),casino:{seconds:20,energy:6,limit:4,used:p.street.games,blocked:quickBlocked(p,{energy:6,break:false},w.now)|| (p.street.games>=4?'Four hands per cycle. The dealer closes your tab.':p.credits<1?'Bring at least 1 credit.':null)}};}
export function startQuick(p,input,w,random){
 streetState(p,w.day);let item,reward={},message='',metrics={};
 if(input.action==='quick'){
  item=typeof input.id==='string'&&Object.hasOwn(streetTasks,input.id)?streetTasks[input.id]:null;reject(item,'Choose a published short task.');
  if(input.id==='bins'){const id=random<.5?'cloth':'wire';reward.materials={[id]:2};message=`The bins yield two ${id==='cloth'?'strips of fabric':'lengths of copper wire'}. Someone has already taken everything valuable.`;}
  if(input.id==='textiles'){reward.materials={cloth:2};message='Two clean fabric strips recovered from discarded uniforms. Their old names are cut away.';}
  if(input.id==='salvage'){reward.materials={wire:2,circuit:1};if(random<.2)reward.health=-2;message=`Recovered two wire and one circuit part.${random<.2?' A live contact burns your hand. −2 health.':''}`;}
  if(input.id==='sweep'){reward.credits=1;reward.taxGross=1;message='The terminal accepts your cleaning log. One credit, reported to Revenue.';}
  if(input.id==='decode'){reward.materials={data:1};message='One signal trace recovered. It carries a freight number and a voice that should not be there.';}
  if(input.id==='repair'){reward.credits=2;reward.taxGross=2;metrics.relief=1;message='The relay comes back online. Two credits and a little district heat. Revenue receives the log.';}
 }else if(input.action==='craft'){
  item=typeof input.id==='string'&&Object.hasOwn(recipes,input.id)?{...recipes[input.id],break:true}:null;reject(item,'Choose a published recipe.');reward[input.id]=1;reward.workshopXP=1;message=`Made one ${item.name.toLowerCase()}. It is in your inventory.`;
 }else if(input.action==='network_job'){
  item=networkLeads(w).find(l=>l.id===input.id);reject(item,'Choose a current network contract.');item={...item,break:true};reject(!p.street.leads.includes(input.id),'That contract was already accepted this cycle.');
  if(input.id==='public'){reward={credits:2,taxGross:2,rep:1};metrics.freight=1;message='Manifest reconciled. Two credits, one trust, and freight cleared for the whole district.';}
  else {reward={credits:3,heat:4,alignment:-1};metrics.crime=1;message='The hidden relay pays three unreported credits. The Canon notices an echo where no citizen should be.';}
 }else if(input.action==='casino'){
  reject(Number.isInteger(input.bet)&&input.bet>=1&&input.bet<=3,'Stake 1, 2, or 3 credits.');reject(p.street.games<4,'Four hands per cycle. The dealer closes your tab.');reject(p.credits>=input.bet,'You cannot stake credits you do not have.');
  item={name:'Null House / red or black',seconds:20,energy:6,break:false};const won=random<.45;reward.credits=won?input.bet*2:0;message=won?`The dealer turns a winning card. ${input.bet*2} credits returned, including your stake.`:'The card is wrong. Your stake belongs to the house. The dealer waits for your next bad decision.';
 }else reject(false,'Unknown short activity.');
 const blocked=quickBlocked(p,item,w.now);reject(!blocked,blocked);
 for(const [id,n] of Object.entries(item.cost||{}))p.materials[id]-=n;
 if(input.action==='network_job')p.street.leads.push(input.id);
 if(input.action==='casino'){p.credits-=input.bet;p.street.games++;}
 p.street.count++;p.energy-=item.energy;
 p.errand={action:input.action,id:input.id||'cards',label:item.name,art:item.art||(input.action==='casino'?'casino':'workshop'),started:w.now,endsAt:w.now+item.seconds*1000,reward,message};
 return {message:`Started ${item.name.toLowerCase()}. ${item.seconds} seconds, ${item.energy} energy.`,metrics,endsAt:p.errand.endsAt};
}
export function finishQuick(p,now,accrueTax){
 const a=p.errand;if(!a||a.endsAt>now)return;
 for(const [id,n] of Object.entries(a.reward.materials||{}))p.materials[id]=(p.materials[id]||0)+n;
 for(const [key,n] of Object.entries(a.reward)){if(['materials','taxGross'].includes(key))continue;p[key]=(p[key]||0)+n;}
 if(a.reward.taxGross)accrueTax(p,a.reward.taxGross);
 for(const key of ['health','energy','fullness','warmth','heat','coherence'])p[key]=bound(p[key]);p.alignment=bound(p.alignment,-100,100);p.errand=null;
}
