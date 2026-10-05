import {contactThreads,recurringContacts} from './contacts.js';
import {quickBlocked} from './street.js';

const lifeNeed=(ok,message)=>{if(!ok)throw Object.assign(new Error(message),{status:400});};
const lifeClamp=(n,min=0,max=100)=>Math.max(min,Math.min(max,n));
export const districtThreads={
 ...contactThreads,...recurringContacts,
 ration:{name:'The name on the ration card',contact:'neri',speaker:'Neri / Cell Stack IX',art:'scavenge',trigger:'bins',nodes:{
  found:{title:'Someone threw away a name.',text:'Under wet municipal wrappers you find Neri’s ration card. Her address is two doors from yours. The printer will accept it once before the missing-card notice arrives.',choices:[
   {id:'return',label:'Return the card to Neri.',preview:'Neri +2 · Trust +1 · Order +2',relations:2,delta:{rep:1,alignment:2},next:'neighbor',wait:60000,outcome:'Neri has been waiting beside an empty printer. You return her card. She gives you a place to knock when the district gets colder.'},
   {id:'sell',label:'Sell the card to an alley broker.',preview:'+2 taxable CR · Neri −1',relations:-1,delta:{credits:2},taxGross:2,next:'done',outcome:'Two credits for a stranger’s next meal. Revenue records the sale; the broker does not record the stranger.'},
   {id:'forge',label:'Copy its access seal. Leave the card.',preview:'−2 energy · Heat +3 · Chaos +2 · One prepared route',energy:2,delta:{heat:3,alignment:-2},plan:'quiet',next:'checkpoint',wait:60000,outcome:'You copy the seal before putting the card back. It can conceal one operation this cycle. The original owner still cannot eat.'},
  ]},
  neighbor:{title:'Neri’s door is open.',text:'Neri sends a quiet message: the worker in the next cell has a burned hand. A clean dressing would help. She offers an introduction to the boiler crew, not payment.',choices:[
   {id:'dress',label:'Bring one clean field dressing.',preview:'−1 dressing · Neri +2 · Trust +1 · Boiler contact',cost:{bandage:1},relations:2,delta:{rep:1},flag:'boilerContact',next:'done',outcome:'Neri wraps the worker’s hand. The boiler crew now knows your name. You have turned a found card into people who will answer a message.'},
   {id:'visit',label:'Sit with them. Listen to the district news.',preview:'No energy or credits · Neri +1 · Boiler contact',relations:1,flag:'boilerContact',next:'done',outcome:'You cannot spare a dressing, but you can spare attention. The crew explains where the heating line is failing.'},
  ]},
  checkpoint:{title:'A borrowed identity has an owner.',text:'A checkpoint bulletin carries Neri’s civic number. You can erase your copy or pass it to Rook. Keeping it will not make it safer.',choices:[
   {id:'erase',label:'Erase the copied seal.',preview:'Prepared route removed · Heat −2 · Trust +1',clearPlan:true,delta:{heat:-2,rep:1},next:'done',outcome:'You erase the seal. One less borrowed name between you and a scanner.'},
   {id:'rook',label:'Warn Rook about the bulletin.',preview:'Rook contact · Heat +2 · Keep the prepared route',flag:'rookContact',delta:{heat:2},next:'done',outcome:'Rook updates his routes and keeps your name. The seal remains usable once this cycle; it remains stolen.'},
  ]},
 }},
 sabotage:{name:'Copper with a cut in it',contact:'esra',speaker:'Esra / Boiler crew',art:'workshop',trigger:'salvage',nodes:{
  found:{title:'This relay did not fail by itself.',text:'The terminal’s copper was cut cleanly before it was discarded. Esra recognizes the maintenance stamp. Someone is selling repairs and causing the damage that makes them necessary.',choices:[
   {id:'report',label:'Give Esra the maintenance stamp.',preview:'Esra +2 · Trust +1 · Boiler contact',relations:2,flag:'boilerContact',delta:{rep:1},next:'follow',wait:60000,outcome:'Esra takes the stamp. She will bring it to the crew before the next heating failure.'},
   {id:'strip',label:'Strip the stamped assembly for parts.',preview:'−2 energy · +1 wire · +1 circuit · Esra −1',energy:2,materials:{wire:1,circuit:1},relations:-1,next:'done',outcome:'The stamp disappears beneath your cutters. The pieces will buy warmth; the source of the failures stays hidden.'},
   {id:'copy',label:'Keep a copy for the underground.',preview:'Rook contact · Chaos +2 · Heat +3',flag:'rookContact',delta:{alignment:-2,heat:3},next:'follow',wait:60000,outcome:'Rook wants the supplier’s name. Evidence can repair a district or give someone control over its next failure.'},
  ]},
  follow:{title:'The crew needs a decision.',text:'Esra asks whether to publish the stamp or quietly repair the affected line. The first draws inspectors; the second buys time for everyone who lives below it.',choices:[
   {id:'publish',label:'Publish the evidence.',preview:'Trust +1 · Order +2 · Heat +2',delta:{rep:1,alignment:2,heat:2},next:'done',outcome:'The maintenance stamp enters the civic archive. Inspectors will know which contractor to question.'},
   {id:'protect',label:'Help the crew identify the affected cells.',preview:'No energy · Esra +1 · Boiler contact',relations:1,flag:'boilerContact',next:'done',outcome:'You mark the affected cells on Esra’s map. At least the next warning will reach the people who need it.'},
  ]},
 }},
 permit:{name:'A permit that remembers you',contact:'voss',speaker:'Clerk Voss / Registry relay',art:'registry',trigger:'decode',nodes:{
  found:{title:'The wrong citizen was refused.',text:'Your decoded signal contains a denied work permit. The applicant’s name and civic number belong to different people. Voss can correct the file, but someone has to point out the error.',choices:[
   {id:'correct',label:'Send the mismatch to Voss.',preview:'Voss +1 · Trust +1 · Order +2',relations:1,delta:{rep:1,alignment:2},next:'review',wait:60000,outcome:'Voss puts the mismatch into a review queue. A record is a person’s access to wages; today you have treated it that way.'},
   {id:'route',label:'Ask Rook how to use the rejected permit.',preview:'−1 signal trace · Rook contact · Heat +2',cost:{data:1},flag:'rookContact',delta:{heat:2},next:'review',wait:60000,outcome:'Rook recognizes the obsolete gate code. It is useful information, and it comes with a name attached.'},
   {id:'delete',label:'Delete the private record.',preview:'No energy or reward',next:'done',outcome:'You erase the denied permit. You have enough records of your own to worry about.'},
  ]},
  review:{title:'A human entry in the ledger.',text:'Voss asks you to compare two addresses. One is a demolished building. Correcting it will help the applicant; keeping the obsolete address could conceal an underground delivery.',choices:[
   {id:'address',label:'Give Voss the current address.',preview:'Voss +1 · Trust +1',relations:1,delta:{rep:1},next:'done',outcome:'Voss corrects the address. The applicant can enter the factory once their own obligations are paid.'},
   {id:'quiet',label:'Keep the obsolete address for one route.',preview:'Chaos +2 · One prepared route · Heat +2',delta:{alignment:-2,heat:2},plan:'quiet',next:'done',outcome:'The dead building stays in your private map. One operation this cycle can use its scanner gap.'},
  ]},
 }},
 shift:{name:'The worker beside you',contact:'esra',speaker:'Esra / Late shift',art:'factory',trigger:'work',nodes:{
  found:{title:'The machine counted two people as one.',text:'At the end of your shift, Esra points to a second worker’s hours under your badge. Reporting it will restore their record. Havel would prefer a quiet correction.',choices:[
   {id:'restore',label:'Help Esra document the missing hours.',preview:'Esra +1 · Trust +1 · Order +2',relations:1,delta:{rep:1,alignment:2},next:'follow',wait:60000,outcome:'You record the second worker’s hours. They will still wait for payment, but they will not have to prove they existed.'},
   {id:'quiet',label:'Let Havel quietly amend the file.',preview:'No reward · Keep your own shift record',next:'done',outcome:'Havel closes the wage terminal. Your own wages remain exactly what you earned.'},
   {id:'leak',label:'Send the duplicated badge log to Rook.',preview:'Rook contact · Heat +3 · Chaos +2',flag:'rookContact',delta:{heat:3,alignment:-2},next:'follow',wait:60000,outcome:'Rook receives the log. A duplicate badge is evidence and a possible way through a gate.'},
  ]},
  follow:{title:'Esra has not forgotten.',text:'The worker’s corrected hours have been accepted. Esra offers to introduce you to the boiler crew or show you how to read a scanner schedule.',choices:[
   {id:'crew',label:'Meet the boiler crew.',preview:'Boiler contact · Esra +1',relations:1,flag:'boilerContact',next:'done',outcome:'Esra introduces you by name. The crew shows you the public repair board.'},
   {id:'scanner',label:'Learn the checkpoint schedule.',preview:'One prepared route this cycle',plan:'quiet',next:'done',outcome:'You learn the scanner’s blind interval. Knowledge can keep one future operation quieter; it does not make it lawful.'},
  ]},
 }},
};
export function districtState(p,day){
 p.district??={};const d=p.district;d.threads??={};d.contacts??={};d.flags??={};d.decisions??=[];d.completed??=0;d.cases??={};
 if(d.day!==day){d.day=day;d.surveys=[];d.caseCount={};d.responses=0;d.municipalSales=0;d.plan=null;}
 return d;
}
export function discoverDistrict(p,trigger,now,day){
 const d=districtState(p,day);d.completed++;
 for(const [id,t] of Object.entries(districtThreads))if(t.trigger===trigger&&!d.threads[id])d.threads[id]={node:'found',readyAt:now,discoveredAt:now};
}
function districtChoiceBlocked(p,choice,now,thread){
 if(thread.readyAt>now)return 'A reply is still on its way.';
 if(p.detainedUntil>now)return 'Decide after your release.';
 if(p.activity&&p.activity.action!=='work')return 'This assignment needs your attention.';
 if(p.energy<(choice.energy||0))return `Need ${choice.energy} energy.`;
 for(const [id,n] of Object.entries(choice.cost||{})){const count=['cloth','wire','circuit','data'].includes(id)?p.materials?.[id]:p[id];if((count||0)<n)return `Need ${n} ${id}.`;}
 return null;
}
export function districtEncounters(p,w){
 const d=districtState(p,w.day);
 return Object.entries(d.threads).filter(([id,s])=>districtThreads[s.template||id]&&s.node!=='done').map(([id,s])=>{
  const t=districtThreads[s.template||id],n=t.nodes[s.node];return {id,contact:t.contact,node:s.node,name:t.name,speaker:t.speaker,art:t.art,title:n.title,text:n.text,readyAt:s.readyAt,choices:n.choices.map(choice=>({id:choice.id,label:choice.label,preview:choice.preview,blocked:districtChoiceBlocked(p,choice,w.now,s)}))};
 });
}
export function chooseDistrict(p,input,w){
 const d=districtState(p,w.day),s=typeof input.id==='string'&&Object.hasOwn(d.threads,input.id)?d.threads[input.id]:null,key=s?.template||input.id,t=typeof key==='string'&&Object.hasOwn(districtThreads,key)?districtThreads[key]:null;
 lifeNeed(t&&s&&s.node!=='done'&&s.node===input.node,'That encounter has moved on. Read its current message.');
 const choice=t.nodes[s.node].choices.find(x=>x.id===input.choice);lifeNeed(choice,'Choose a published response.');const blocked=districtChoiceBlocked(p,choice,w.now,s);lifeNeed(!blocked,blocked);
 for(const [id,n] of Object.entries(choice.cost||{})){if(['cloth','wire','circuit','data'].includes(id))p.materials[id]-=n;else p[id]-=n;}
 for(const [key,n] of Object.entries(choice.delta||{}))p[key]=['rep','credits'].includes(key)?Math.max(0,(p[key]||0)+n):lifeClamp((p[key]||0)+n,key==='alignment'?-100:0);
 for(const [key,n] of Object.entries(choice.materials||{}))p.materials[key]+=n;
 p.energy-=choice.energy||0;d.contacts[t.contact]=(d.contacts[t.contact]||0)+(choice.relations||0);
 if(choice.flag)d.flags[choice.flag]=true;if(choice.plan)d.plan={mode:choice.plan,day:w.day};if(choice.clearPlan)d.plan=null;
 d.decisions.push({thread:input.id,node:s.node,choice:choice.id,label:choice.label,outcome:choice.outcome,created:w.now});d.decisions=d.decisions.slice(-40);
 s.choices??=[];s.choices.push(choice.id);s.node=choice.next;s.readyAt=w.now+(choice.wait||0);
 return {message:choice.outcome,taxGross:choice.taxGross||0};
}
export const districtSurveys={
 checkpoint:{name:'Read the checkpoint bulletin',art:'transit',text:'The public bulletin exposes a scanner gap. One operation this cycle can use a quieter route: capture risk −10 percentage points. The plan is consumed when an operation starts.',plan:'quiet'},
 boiler:{name:'Read the repair crew’s board',art:'workshop',text:'The crew needs warming packs and live copper. Municipal orders pay for supplies; district emergency responses need them too. Compare the reward with the district benefit before you sell.',flag:'boilerContact'},
 registry:{name:'Compare your civic obligations',art:'registry',text:'Wages are reported at 12%. Hold tax money aside. Paying debt and clearing an ID are separate steps. Public custodial work stays open; an indigence appeal substitutes time and energy for the review fee.'},
};
export function surveyDistrict(p,id,w){
 const d=districtState(p,w.day),s=typeof id==='string'&&Object.hasOwn(districtSurveys,id)?districtSurveys[id]:null;lifeNeed(s,'Choose a district bulletin.');lifeNeed(!d.surveys.includes(id),'You have already read this bulletin this cycle.');lifeNeed(!p.activity||p.activity.action==='work','Read the bulletin after this assignment.');
 d.surveys.push(id);if(s.plan)d.plan={mode:s.plan,day:w.day};if(s.flag)d.flags[s.flag]=true;return s.text;
}
export const careerCases={
 administration:{name:'The disputed freight permit',role:'Municipal administration',art:'registry',brief:'A relief consignment carries a valid address and an expired duplicate identity. The clerk can verify the real applicant or sell a quiet stamp. Your choice affects freight and your civic record.',choices:[
  {id:'verify',label:'Verify the applicant and release the freight.',seconds:45,energy:5,reward:{credits:3,taxGross:3,rep:1,alignment:1},metrics:{freight:1},outcome:'You verify the applicant. Three taxable credits, one trust, and the relief freight moves.'},
  {id:'hold',label:'Document the discrepancy for inspectors.',seconds:35,energy:4,reward:{credits:2,taxGross:2,rep:1,alignment:2},metrics:{patrols:1},outcome:'You record the discrepancy. Two taxable credits and one trust; inspectors receive usable evidence.'},
  {id:'stamp',label:'Sell an unrecorded stamp.',seconds:40,energy:5,reward:{credits:5,heat:5,alignment:-3},metrics:{crime:1},outcome:'Five unreported credits for an unrecorded stamp. Your uniform cannot hide the missing audit trail.'},
 ]},
 security:{name:'The worker at the rainline',role:'Canon security',art:'transit',brief:'A scanner flags a worker carrying repair copper. Their shift receipt is valid, but the contractor’s seal matches a theft report. Check the evidence, confiscate the cargo, or accept a payment.',choices:[
  {id:'evidence',label:'Check the receipt. Escort the repair copper.',seconds:60,energy:6,reward:{credits:4,taxGross:4,rep:1,alignment:1},metrics:{patrols:2,relief:1},outcome:'The worker’s receipt checks out. You escort the copper to the crew. Four taxable credits, one trust, and two patrol contributions.'},
  {id:'seize',label:'Hold the cargo and file an incident.',seconds:45,energy:5,reward:{credits:3,taxGross:3,alignment:2},metrics:{patrols:2},outcome:'The cargo enters evidence. Three taxable credits and two patrol contributions; the crew will wait for replacement copper.'},
  {id:'bribe',label:'Accept a payment and close the scanner log.',seconds:45,energy:5,reward:{credits:6,heat:7,alignment:-4},metrics:{crime:2},outcome:'Six unreported credits. The scanner log is closed, and the unregistered cargo enters the district.'},
 ]},
 shop:{name:'Who gets the last warming pack?',role:'Licensed exchange',art:'market',brief:'A boiler crew and a private buyer want the same stock. The private buyer pays more. The crew’s order helps the cell stacks stay warm.',choices:[
  {id:'crew',label:'Sell one warming pack to the boiler crew.',seconds:35,energy:3,cost:{heatpack:1},reward:{credits:4,taxGross:4,rep:1},metrics:{relief:2},outcome:'The crew receives your warming pack. Four taxable credits, one trust, and two relief contributions.'},
  {id:'private',label:'Sell the pack to the private buyer.',seconds:30,energy:3,cost:{heatpack:1},reward:{credits:6,taxGross:6},metrics:{},outcome:'Six taxable credits from a private buyer. The crew stays in the queue.'},
 ]},
 underground:{name:'The seal on the relief crate',role:'Rook’s routes',art:'neural',brief:'Rook has a crate number and no way through the scanner. One signal trace can restore its public manifest or erase its contents from the count.',choices:[
  {id:'restore',label:'Restore the public manifest.',seconds:40,energy:4,cost:{data:1},reward:{credits:2,taxGross:2,rep:1},metrics:{freight:1},outcome:'The crate joins the public manifest. Two taxable credits, one trust, and one freight contribution.'},
  {id:'divert',label:'Erase the crate and run Rook’s delivery.',seconds:50,energy:6,cost:{data:1},reward:{credits:5,heat:5,alignment:-2},metrics:{crime:1},outcome:'Five unreported credits and a missing relief crate. Rook remembers the delivery; the Canon remembers the gap.'},
 ]},
};
function caseEligible(p,role){return role==='administration'?p.official&&!p.taxHold&&!p.criminalHold:role==='security'?p.security&&!p.taxHold&&!p.criminalHold:role==='shop'?p.business&&!p.taxHold&&!p.criminalHold:role==='underground'&&(p.criminal.xp>=3||p.district.flags.rookContact);}
function careerChoiceBlocked(p,choice,w){
 const blocked=quickBlocked(p,{...choice,cost:{},break:false},w.now);if(blocked)return blocked;
 for(const [id,n] of Object.entries(choice.cost||{}))if((['data','wire','circuit','cloth'].includes(id)?p.materials[id]:p[id])<n)return `Need ${n} ${id}.`;
 return null;
}
export function reviewCareerCase(p,role,w){
 const d=districtState(p,w.day);lifeNeed(Object.hasOwn(careerCases,role)&&caseEligible(p,role),'Earn access to this career desk first.');lifeNeed(!p.activity||p.activity.action==='work','This assignment needs your full attention.');lifeNeed(!d.caseCount[role],'One case on each desk per cycle.');d.cases[role]={day:w.day,status:'reviewed',reviewedAt:w.now};return careerCases[role].brief;
}
export function startCareerCase(p,input,w){
 const d=districtState(p,w.day),desk=typeof input.id==='string'&&Object.hasOwn(careerCases,input.id)?careerCases[input.id]:null;
 lifeNeed(desk&&caseEligible(p,input.id),'Earn access to this career desk first.');lifeNeed(d.cases[input.id]?.day===w.day&&d.cases[input.id].status==='reviewed','Review the case file before choosing an assignment.');lifeNeed(!d.caseCount[input.id],'This case has already been assigned this cycle.');
 const choice=desk.choices.find(x=>x.id===input.choice);lifeNeed(choice,'Choose a published case response.');
 const blocked=quickBlocked(p,{...choice,cost:{},break:false},w.now);lifeNeed(!blocked,blocked);
 for(const [id,n] of Object.entries(choice.cost||{})){const count=['data','wire','circuit','cloth'].includes(id)?p.materials[id]:p[id];lifeNeed((count||0)>=n,`Need ${n} ${id}.`);}
 for(const [id,n] of Object.entries(choice.cost||{})){if(['data','wire','circuit','cloth'].includes(id))p.materials[id]-=n;else p[id]-=n;}
 p.energy-=choice.energy;p.street.count++;d.caseCount[input.id]=1;d.cases[input.id].status='assigned';
 p.errand={action:'career_case',id:input.id,label:desk.name,art:desk.art,started:w.now,endsAt:w.now+choice.seconds*1000,reward:choice.reward,message:choice.outcome,caseChoice:choice.id,crimeXP:input.id==='underground'&&choice.id==='divert'?1:0};
 return {message:`Started ${desk.name.toLowerCase()}. ${choice.seconds} seconds; ${choice.energy} energy.`,metrics:choice.metrics,endsAt:p.errand.endsAt};
}
export function completeDistrictTask(p,a,day){
 const d=districtState(p,day),completionDay=Math.max(1,Math.floor((a.endsAt-Date.UTC(2026,9,5))/21600000)+1);if(a.action==='career_case'){d.cases[a.id]={day:completionDay,status:'closed',choice:a.caseChoice,closedAt:a.endsAt,message:a.message};if(a.crimeXP){p.criminal.xp+=a.crimeXP;d.contacts.rook=(d.contacts.rook||0)+1;}}
 if(a.action==='prepare_crime'&&completionDay===day)d.plan={mode:'quiet',day};
 if(a.action==='quick')discoverDistrict(p,a.id,a.endsAt,day);
}
export function crimePreparation(p,w){const d=districtState(p,w.day);return d.plan?.day===w.day&&d.plan.mode==='quiet'?-.1:0;}
export function startCrimePreparation(p,w){
 const d=districtState(p,w.day);lifeNeed(!d.plan,'You already have a prepared route.');const item={energy:4,cost:{data:1},break:false},blocked=quickBlocked(p,item,w.now);lifeNeed(!blocked,blocked);
 p.energy-=4;p.materials.data--;p.street.count++;p.errand={action:'prepare_crime',id:'quiet',label:'Reconnoiter a checkpoint route',art:'transit',started:w.now,endsAt:w.now+30000,reward:{},message:'You map a quiet checkpoint route. Capture risk −10 percentage points on one operation this cycle.'};
 return {message:'Reconnoitering the checkpoint. 30 seconds; 4 energy; one signal trace.',metrics:{},endsAt:p.errand.endsAt};
}
export function districtSnapshot(p,w){
 const d=districtState(p,w.day);
 return {encounters:districtEncounters(p,w),contacts:d.contacts,decisions:d.decisions,plan:crimePreparation(p,w),surveys:Object.entries(districtSurveys).map(([id,s])=>({id,...s,read:d.surveys.includes(id)})),desks:Object.entries(careerCases).map(([id,s])=>({id,...s,eligible:!!caseEligible(p,id),file:d.cases[id]?.day===w.day?d.cases[id]:null,used:!!d.caseCount[id],choices:s.choices.map(choice=>({...choice,blocked:careerChoiceBlocked(p,choice,w)}))}))};
}
