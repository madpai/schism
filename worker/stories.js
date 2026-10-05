// Personal stories are server-owned. Client requests select a published node and choice.
export const storyThreads = {
  neighbor: {title:'The door across the hall',speaker:'Iona / Bunk 15',location:'Block 6',image:'city',requires:()=>true,nodes:{
    start:{title:'Someone else is cold, too.',text:'Iona is sitting beside the broken radiator. She has stopped pretending to read. “Do you have anything to eat?” she asks. You look at your own bag. Neither of you gets paid until tomorrow.',choices:[
      {id:'bread',label:'Give her your ration bread.',preview:'−1 bread · Iona remembers',cost:{bread:1},relations:{iona:2},flags:{helpedIona:true},next:'return',outcome:'You split the bread unevenly and give Iona the larger half. She doesn’t say thank you. She says your name.'},
      {id:'blanket',label:'Buy a blanket to share.',preview:'−6 CR · +10 warmth · Iona remembers',cost:{credits:6},delta:{warmth:10},relations:{iona:2},flags:{helpedIona:true},next:'return',outcome:'A six-credit blanket is thin, but sitting together makes the cold smaller. You both keep it.'},
      {id:'leave',label:'You need to look after yourself.',preview:'Keep your supplies · Iona grows distant',relations:{iona:-1},next:'distance',outcome:'You tell her you have nothing to spare. It is almost true. The door closes quietly.'},
    ]},
    return:{title:'A favor comes back.',requires:p=>p.shifts>=2,locked:'Complete two work shifts to hear from Iona again.',text:'Two shifts later, Iona knocks. “I know someone at the clinic,” she says. “Or I can cover for you when the supervisor comes around.” She hasn’t forgotten the radiator.',choices:[
      {id:'care',label:'Ask for the clinic introduction.',preview:'+22 health · Iona +1',delta:{health:22},relations:{iona:1},next:'done',outcome:'Iona’s friend cleans the wound without asking for payment. Your name means something to someone now.'},
      {id:'cover',label:'Ask her to cover for you.',preview:'+18 energy · +2 trust',delta:{energy:18,rep:2},relations:{iona:1},next:'done',outcome:'Iona signs your timecard while you sleep. The foreman never notices. You owe her another favor.'},
    ]},
    distance:{title:'The hallway is quieter.',text:'Iona sees you at the stairs and looks away. You could let the distance settle. Or spend something you can’t really spare to make it smaller.',choices:[
      {id:'apologize',label:'Leave three credits at her door.',preview:'−3 CR · Repair your relationship',cost:{credits:3},relations:{iona:2},next:'done',outcome:'You leave three credits and a note. The next morning, Iona nods to you in the hallway.'},
      {id:'alone',label:'Keep walking.',preview:'No cost · This door stays closed',flags:{alone:true},next:'done',outcome:'You keep walking. Some things are cheaper when you stop looking at them.'},
    ]},
  }},
  wages: {title:'The missing wages',speaker:'Havel / Factory foreman',location:'Kessler works',image:'factory',requires:p=>p.shifts>=1,locked:'Finish your first work shift.',nodes:{
    start:{title:'“Administrative deduction.”',text:'Havel slides a pay envelope across the desk. It is short. He points at a line you never signed: EQUIPMENT WEAR. “Everyone pays their part.” Behind him, the wage ledger is still open.',choices:[
      {id:'quiet',label:'Take the envelope. Keep the job.',preview:'+2 CR · +2 trust · Havel +1',delta:{credits:2,rep:2},relations:{havel:1},next:'favor',outcome:'You swallow the question. Havel adds two credits for being “reasonable.” He will remember that.'},
      {id:'challenge',label:'Demand the wages you earned.',preview:'+6 CR · +8 heat · Havel −2',delta:{credits:6,heat:8},relations:{havel:-2},next:'ledger',outcome:'He pays six credits from the drawer. Outside, security writes down your badge number.'},
      {id:'copy',label:'Memorize the ledger. Say nothing.',preview:'+1 scrap · Evidence kept · Havel −1',delta:{scrap:1},relations:{havel:-1},flags:{wageEvidence:true},next:'ledger',outcome:'The ledger tells the same story for every worker. You pocket a spare part on the way out. Evidence has a price, too.'},
    ]},
    favor:{title:'A place beside the machinery.',requires:p=>p.shifts>=3,locked:'Complete three shifts to receive Havel’s offer.',text:'“You don’t make trouble,” Havel says. He offers you a training badge. One name must come off tomorrow’s shift list to make room. It could be yours. It could be someone else’s.',choices:[
      {id:'badge',label:'Take the training badge.',preview:'+4 trust · Havel +1 · A worker loses a shift',delta:{rep:4},relations:{havel:1},flags:{tookBadge:true},next:'done',outcome:'The badge opens a door. Someone else’s timecard lies in the waste bin. You tell yourself you earned this.'},
      {id:'refuse',label:'Keep the regular shift. Leave their name.',preview:'+2 trust · Havel −1',delta:{rep:2},relations:{havel:-1},next:'done',outcome:'You leave the badge on the desk. Tomorrow’s list keeps both names. Havel stops calling you reasonable.'},
    ]},
    ledger:{title:'The copy in your pocket.',requires:p=>p.shifts>=2,locked:'Return after your second shift.',text:'The union representative is waiting at the gate. “If the deductions are real, we need names.” Havel’s office light is on upstairs. You can still walk past them both.',choices:[
      {id:'union',label:'Give the names to the union.',preview:'Union member required · +3 trust · +10 heat',require:p=>p.union,blocked:'Join the union first.',delta:{rep:3,heat:10},relations:{havel:-1},flags:{exposedWages:true},next:'done',outcome:'You give the union the names. By dawn, everyone knows what was taken. Security knows who spoke.'},
      {id:'deal',label:'Trade your silence for cash.',preview:'+10 CR · Havel +1',delta:{credits:10},relations:{havel:1},flags:{soldSilence:true},next:'done',outcome:'Havel pays ten credits for a missing page. You have enough for dinner. The deductions continue.'},
      {id:'keep',label:'Keep the evidence. Keep moving.',preview:'No cost · Record stays with you',flags:{wageEvidence:true},next:'done',outcome:'You pass the gate without a word. You keep the names. Perhaps surviving today is enough.'},
    ]},
  }},
  package: {title:'A sealed delivery',speaker:'Rook / Market runner',location:'Night market',image:'market',requires:p=>p.shifts>=1,locked:'Work one shift before Rook approaches you.',nodes:{
    start:{title:'Don’t ask what’s inside.',text:'A runner called Rook meets you behind the soup stall. A sealed package. Six credits now, fourteen at the door. “One rule,” Rook says. “You don’t open it.”',choices:[
      {id:'take',label:'Take the package.',preview:'+6 CR now · Rook +1 · Delivery follows',delta:{credits:6},relations:{rook:1},next:'door',outcome:'You take six credits and a package light enough to hide under a coat. Rook gives you an address.'},
      {id:'refuse',label:'Walk away from the easy money.',preview:'No cost · Delivery closes',next:'done',outcome:'Rook shrugs and asks the next person. The city will always have someone who needs six credits.'},
    ]},
    door:{title:'You can hear someone coughing.',text:'The delivery address is a shuttered clinic. Through the vent you hear a child coughing. A torn corner reveals what you’re carrying: medicine marked MUNICIPAL PROPERTY. Rook is expecting a clean delivery.',choices:[
      {id:'deliver',label:'Hand it over. Take the money.',preview:'+14 CR · +12 heat · Rook +2 · Smuggler',hours:2,energy:10,delta:{credits:14,heat:12},relations:{rook:2},role:'Smuggler',flags:{deliveredMedicine:true},next:'done',outcome:'The clinic takes the medicine. Rook pays fourteen credits. It helped someone. It also put your name on a list.'},
      {id:'keep',label:'Keep the medicine for yourself.',preview:'+1 medicine · +8 heat · Rook −3',delta:{medicine:1,heat:8},relations:{rook:-3},flags:{brokeDelivery:true},next:'done',outcome:'You slip away with the tablets. Your own body needs help, too. Rook won’t offer you another package.'},
      {id:'return',label:'Return it to the Authority.',preview:'+3 trust · −6 CR advance · Rook −2',cost:{credits:6},delta:{rep:3},relations:{rook:-2},next:'done',outcome:'The Authority takes the package and your advance. The clerk thanks you without looking up. The coughing continues.'},
    ]},
  }},
  papers: {title:'A name in the registry',speaker:'Clerk Voss / Civic records',location:'Municipal offices',image:'city',requires:p=>p.rep>=4,locked:'Build 4 trust to receive the registry summons.',nodes:{
    start:{title:'Your papers have a discrepancy.',text:'Clerk Voss circles a stamp on your work permit. “The old district seal. Invalid now.” The queue behind you shifts closer. A new permit costs six credits. Waiting for a review costs an afternoon.',choices:[
      {id:'pay',label:'Pay for the replacement seal.',preview:'−6 CR · +2 trust · Voss +1',cost:{credits:6},delta:{rep:2},relations:{voss:1},next:'favor',outcome:'The seal costs six credits and takes three seconds. Voss’s expression never changes.'},
      {id:'wait',label:'Wait for the formal review.',preview:'2 hours · −4 energy · +3 trust',hours:2,energy:4,delta:{rep:3},relations:{voss:-1},next:'favor',outcome:'You wait until the office empties. The seal was valid all along. Voss stamps it again anyway.'},
      {id:'leave',label:'Leave with the old papers.',preview:'+5 heat · Keep your money',delta:{heat:5},next:'done',outcome:'You leave before your number is called. The next checkpoint may ask a different question.'},
    ]},
    favor:{title:'There is always another stamp.',text:'Voss finds you on your way out. “I can put your name ahead of the queue next time.” A favor from a clerk can save a day. It can also make you available when the clerk needs something.',choices:[
      {id:'agree',label:'Accept the favor.',preview:'+2 trust · Voss +1 · Connected',delta:{rep:2},relations:{voss:1},flags:{clerkConnection:true},next:'done',outcome:'Your name goes into a smaller book. The city’s doors don’t open freely. Someone holds the key.'},
      {id:'decline',label:'Keep your own place in line.',preview:'+1 trust · Independent',delta:{rep:1},flags:{independent:true},next:'done',outcome:'You thank Voss and leave. Next time, you will wait with everyone else.'},
    ]},
  }},
};
export function personalState(p){
  p.story??={};p.story.threads??={};p.story.contacts??={iona:0,havel:0,rook:0,voss:0};p.story.flags??={};p.story.decisions??=[];return p.story;
}
function unavailable(p,choice){
  if(choice.require&&!choice.require(p))return choice.blocked;
  for(const [key,n] of Object.entries(choice.cost||{}))if((p[key]||0)<n)return key==='credits'?`Need ${n} credits.`:`Need ${n} ${key}.`;
  if(p.energy<(choice.energy||0))return `Need ${choice.energy} energy.`;
  return null;
}
export function encountersFor(p){
  const s=personalState(p);
  return Object.entries(storyThreads).map(([id,thread])=>{
    const nodeId=s.threads[id]||'start';const done=nodeId==='done';const node=done?null:thread.nodes[nodeId];
    const locked=!thread.requires(p)?thread.locked:node?.requires&&!node.requires(p)?node.locked:null;
    return {id,threadTitle:thread.title,speaker:thread.speaker,location:thread.location,image:thread.image,node:nodeId,done,locked,title:node?.title||thread.title,text:locked?'This encounter will continue when you meet its requirement.':node?.text||'This chapter is part of your history.',choices:done||locked?[]:node.choices.map(choice=>({id:choice.id,label:choice.label,preview:choice.preview,blocked:unavailable(p,choice)}))};
  });
}
export function resolveEncounter(p,input,now){
  const err=message=>{throw Object.assign(new Error(message),{status:400});};
  if(typeof input.id!=='string'||!Object.hasOwn(storyThreads,input.id))err('Unknown encounter.');
  const s=personalState(p),thread=storyThreads[input.id],nodeId=s.threads[input.id]||'start';
  if(nodeId==='done'||input.node!==nodeId)err('That moment has already passed. Read your current encounter.');
  const node=thread.nodes[nodeId];if(!thread.requires(p)||(node.requires&&!node.requires(p)))err('That encounter is not available yet.');
  const choice=node.choices.find(c=>c.id===input.choice);if(!choice)err('Choose one of the available responses.');
  const blocked=unavailable(p,choice);if(blocked)err(blocked);
  for(const [key,n] of Object.entries(choice.cost||{}))p[key]-=n;
  for(const [key,n] of Object.entries(choice.delta||{})){const next=(p[key]||0)+n;p[key]=['health','energy','warmth','fullness','heat'].includes(key)?Math.max(0,Math.min(100,next)):Math.max(0,next);}
  for(const [name,n] of Object.entries(choice.relations||{}))s.contacts[name]=(s.contacts[name]||0)+n;
  Object.assign(s.flags,choice.flags||{});if(choice.role)p.role=choice.role;
  s.threads[input.id]=choice.next;s.decisions.push({thread:input.id,node:nodeId,choice:choice.id,label:choice.label,outcome:choice.outcome,created:now});
  return {message:choice.outcome,hours:choice.hours||0,energy:choice.energy||0};
}
