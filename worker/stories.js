// Personal stories are server-owned. Client requests select a published node and choice.
export const storyThreads = {
  signal:{title:'The signal beneath the signal',speaker:'PROXY 0 / Source unregistered',location:'The Ninth Stratum',image:'city',requires:()=>true,nodes:{
    start:{title:'Your reflection is half a second late.',text:'The mirror in your habitation cell displays an employment notice. Then it displays you, still asleep. A voice enters your implant without permission. “The Canon will keep you coherent,” it says. A second voice speaks from behind the glass. “The Wound will let you become something else.” Rent is still due in both versions of the room.',choices:[
      {id:'canon',label:'Answer the Canon. Ask for a stable reality.',preview:'Order +12 · Coherence +6 · Surveillance +4',delta:{alignment:12,coherence:6,heat:4},force:12,flags:{heardCanon:true},next:'canon',outcome:'The Canon acknowledges your biological signature. Your reflection catches up. Every door in the cell locks for exactly one second.'},
      {id:'wound',label:'Answer the other voice. Ask what is outside.',preview:'Chaos +12 · +3 CR · Coherence −6 · Surveillance +6',delta:{alignment:-12,coherence:-6,credits:3,heat:6},force:-12,flags:{heardWound:true},next:'wound',outcome:'Three untraceable credits appear in your implant. The voice says they have always been there. Behind your reflection, a corridor opens that this room does not contain.'},
      {id:'silence',label:'Disconnect the mirror. You need to get paid.',preview:'Remain unbound · No city influence',flags:{keptReceiverDark:true},next:'unbound',outcome:'You pull the mirror’s cable. The reflection keeps moving for another second. You have a shift to survive and no time to become a theology.'},
    ]},
    canon:{title:'An unscheduled person.',requires:p=>p.shifts>=1,locked:'Finish one shift in the Mnemonic Foundry.',text:'A Canon sentinel stops you outside the foundry. A resident is standing beneath a maintenance arch. Their implant broadcasts no civic identity. “Seal the arch,” the sentinel says. “Order requires a complete count.” The resident watches you without blinking.',choices:[
      {id:'seal',label:'Give up a relay fragment. Seal the arch.',preview:'−1 relay fragment · Order +12 · +2 trust',cost:{scrap:1},delta:{alignment:12,rep:2,coherence:6},force:12,flags:{sealedResident:true},next:'done',outcome:'The relay closes the maintenance arch. The city’s count becomes correct. You do not ask where the resident went.'},
      {id:'register',label:'Register the resident with the Canon.',preview:'Order +8 · +2 trust · Surveillance +3',delta:{alignment:8,rep:2,heat:3},force:8,flags:{registeredAnomaly:true},next:'done',outcome:'You transmit the resident’s location. A new number joins the registry. The sentinel calls this mercy.'},
      {id:'release',label:'Let the resident pass through.',preview:'Chaos +8 · Surveillance +8 · Coherence −3',delta:{alignment:-8,heat:8,coherence:-3},force:-8,flags:{releasedAnomaly:true},next:'done',outcome:'The resident steps through the arch. For a moment, there are two shadows where one should be. The sentinel records your hesitation.'},
    ]},
    wound:{title:'The door that was not built.',requires:p=>p.shifts>=1,locked:'Finish one shift before the hidden corridor returns.',text:'After your shift, the corridor appears between two vending shrines. The Wound offers you a maintenance key that feels warm and alive. “Open the city,” it says. “The walls are only a habit.” A ration queue stretches past your shoulder.',choices:[
      {id:'open',label:'Use the key. Break the Canon seal.',preview:'Chaos +12 · +8 CR · Coherence −6 · 1H / −10 energy',hours:1,energy:10,delta:{alignment:-12,credits:8,coherence:-6,heat:6},force:-12,flags:{openedWound:true},next:'done',outcome:'The seal tears open without making a sound. Eight credits arrive in your implant. Something on the other side remembers the name you had before you were born.'},
      {id:'supply',label:'Carry a ration through the corridor.',preview:'−1 ration · Chaos +12 · +2 trust · Surveillance +6',cost:{bread:1},delta:{alignment:-12,rep:2,heat:6},force:-12,flags:{fedBeyond:true},next:'done',outcome:'You carry food through the impossible door. Someone you cannot quite see takes it. The Wound thanks you in Iona’s voice.'},
      {id:'close',label:'Destroy the key. Keep one version of the city.',preview:'Order +8 · Coherence +8',delta:{alignment:8,coherence:8},force:8,flags:{closedWound:true},next:'done',outcome:'You snap the key. It stops feeling alive. The corridor becomes a blank wall, and your reflection holds still.'},
    ]},
    unbound:{title:'Unbound does not mean untouched.',requires:p=>p.shifts>=1,locked:'Finish a shift before the next transmission.',text:'Neither voice has claimed you. The ration printer recognizes your worker badge, though, and so does the rent collector. A terminal offers to buy the strange recording from your mirror. You can sell it, file it, or let it disappear.',choices:[
      {id:'sell',label:'Sell the recording to an unknown address.',preview:'+5 CR · Chaos +4 · Surveillance +3',delta:{credits:5,alignment:-4,heat:3},force:-4,next:'done',outcome:'The recording leaves your implant. Five credits replace it. Somewhere in the city, another mirror begins to lag.'},
      {id:'file',label:'File the recording with civic records.',preview:'+1 trust · Order +4',delta:{rep:1,alignment:4},force:4,next:'done',outcome:'The registry accepts your anomaly report. Its response is a prayer formatted as a receipt.'},
      {id:'erase',label:'Erase it. Survive your own life.',preview:'Coherence +4 · Remain unbound',delta:{coherence:4},flags:{remainedUnbound:true},next:'done',outcome:'You erase the recording. It does not erase you. Today you will work, eat, and sleep without signing your life to either voice.'},
    ]},
  }},
  neighbor: {title:'The door across the hall',speaker:'Iona / Habitation cell 15',location:'Cell Stack IX',image:'city',requires:()=>true,nodes:{
    start:{title:'Someone else is cold, too.',text:'Iona is sitting beside a dead thermal vent. The wall speaker is reciting her civic number incorrectly. “My implant says I ate,” she tells you. “I didn’t.” You check your own ration allowance. Neither of you gets paid until the next transmission.',choices:[
      {id:'bread',label:'Give her your vat-grown ration.',preview:'−1 ration · Iona remembers',cost:{bread:1},relations:{iona:2},flags:{helpedIona:true},next:'return',outcome:'You divide the biomass unevenly. Iona takes the larger piece. For a moment, her implant and yours broadcast the same heartbeat.'},
      {id:'blanket',label:'Buy a conductive wrap to share.',preview:'−6 CR · +10 warmth · Iona remembers',cost:{credits:6},delta:{warmth:10},relations:{iona:2},flags:{helpedIona:true},next:'return',outcome:'The conductive wrap crackles between you. Six credits to warm two bodies. The wall speaker says only one body is registered here.'},
      {id:'leave',label:'You need to look after yourself.',preview:'Keep your supplies · Iona grows distant',relations:{iona:-1},next:'distance',outcome:'You tell her you have nothing to spare. It is almost true. The door closes quietly.'},
    ]},
    return:{title:'A favor comes back.',requires:p=>p.shifts>=2,locked:'Complete two work shifts to hear from Iona again.',text:'Two shifts later, Iona returns with a stolen somatic key. “The Ward owes me,” she says. “Or I can make your implant appear awake while you sleep.” Her civic number sounds correct for the first time.',choices:[
      {id:'care',label:'Ask for the Somatic Ward key.',preview:'+22 health · Iona +1',delta:{health:22},relations:{iona:1},next:'done',outcome:'The Ward accepts Iona’s key. A surgical arm repairs you while the ceiling repeats a prayer you almost remember.'},
      {id:'cover',label:'Ask her to cover for you.',preview:'+18 energy · +2 trust',delta:{energy:18,rep:2},relations:{iona:1},next:'done',outcome:'Iona loops your implant’s awake signal while you sleep. The overseer reads an obedient worker. You owe a favor to a person the registry cannot count.'},
    ]},
    distance:{title:'The hallway is quieter.',text:'Iona sees you at the stairs and looks away. You could let the distance settle. Or spend something you can’t really spare to make it smaller.',choices:[
      {id:'apologize',label:'Leave three credits at her door.',preview:'−3 CR · Repair your relationship',cost:{credits:3},relations:{iona:2},next:'done',outcome:'You leave three credits and a note. The next morning, Iona nods to you in the hallway.'},
      {id:'alone',label:'Keep walking.',preview:'No cost · This door stays closed',flags:{alone:true},next:'done',outcome:'You keep walking. Some things are cheaper when you stop looking at them.'},
    ]},
  }},
  wages: {title:'The missing wages',speaker:'Havel / Mnemonic overseer',location:'Mnemonic Foundry',image:'factory',requires:p=>p.shifts>=1,locked:'Finish your first work shift.',nodes:{
    start:{title:'“Administrative deduction.”',text:'Havel displays your pay inside your retinal feed. It is short. A deduction scrolls past: UNLICENSED RECOLLECTION. “You remembered something during the shift,” he says. Behind his mask, the wage archive is still open.',choices:[
      {id:'quiet',label:'Accept the deduction. Keep your implant licensed.',preview:'+2 CR · +2 trust · Havel +1',delta:{credits:2,rep:2},relations:{havel:1},next:'favor',outcome:'You swallow the question. Havel adds two credits for being “reasonable.” He will remember that.'},
      {id:'challenge',label:'Demand the wages you earned.',preview:'+6 CR · +8 heat · Havel −2',delta:{credits:6,heat:8},relations:{havel:-2},next:'ledger',outcome:'He pays six credits from the drawer. Outside, security writes down your badge number.'},
      {id:'copy',label:'Copy the wage archive into an unused memory slot.',preview:'+1 scrap · Evidence kept · Havel −1',delta:{scrap:1},relations:{havel:-1},flags:{wageEvidence:true},next:'ledger',outcome:'The ledger tells the same story for every worker. You pocket a spare part on the way out. Evidence has a price, too.'},
    ]},
    favor:{title:'A place beside the machinery.',requires:p=>p.shifts>=3,locked:'Complete three shifts to receive Havel’s offer.',text:'Havel offers you a lattice technician’s seal. “You keep your thoughts in sequence.” The license requires a vacant memory slot. One worker’s identity must be removed from tomorrow’s archive. It could be yours. It could be someone else’s.',choices:[
      {id:'badge',label:'Take the training badge.',preview:'+4 trust · Havel +1 · A worker loses a shift',delta:{rep:4},relations:{havel:1},flags:{tookBadge:true},next:'done',outcome:'The badge opens a door. Someone else’s timecard lies in the waste bin. You tell yourself you earned this.'},
      {id:'refuse',label:'Keep the regular shift. Leave their name.',preview:'+2 trust · Havel −1',delta:{rep:2},relations:{havel:-1},next:'done',outcome:'You leave the badge on the desk. Tomorrow’s list keeps both names. Havel stops calling you reasonable.'},
    ]},
    ledger:{title:'The copy in your pocket.',requires:p=>p.shifts>=2,locked:'Return after your second shift.',text:'A member of the Uncounted waits beneath a dead surveillance lens. “The archive is deleting pay before the shift ends. We need the identities.” Havel’s chamber glows above you. You can still walk past both transmissions.',choices:[
      {id:'union',label:'Give the names to the union.',preview:'Union member required · +3 trust · +10 heat',require:p=>p.union,blocked:'Join the union first.',delta:{rep:3,heat:10},relations:{havel:-1},flags:{exposedWages:true},next:'done',outcome:'You give the union the names. By dawn, everyone knows what was taken. Security knows who spoke.'},
      {id:'deal',label:'Trade your silence for cash.',preview:'+10 CR · Havel +1',delta:{credits:10},relations:{havel:1},flags:{soldSilence:true},next:'done',outcome:'Havel pays ten credits for a missing page. You have enough for dinner. The deductions continue.'},
      {id:'keep',label:'Keep the evidence. Keep moving.',preview:'No cost · Record stays with you',flags:{wageEvidence:true},next:'done',outcome:'You pass the gate without a word. You keep the names. Perhaps surviving today is enough.'},
    ]},
  }},
  package: {title:'A sealed delivery',speaker:'Rook / Unlicensed courier',location:'Null Exchange',image:'market',requires:p=>p.shifts>=1,locked:'Work one shift before Rook approaches you.',nodes:{
    start:{title:'Don’t ask what’s inside.',text:'Rook waits behind a medical vending shrine. The mask has no eyeholes. A sealed mnemonic capsule: six credits now, fourteen at the destination. “It will sound like someone you know,” Rook says. “Do not answer.”',choices:[
      {id:'take',label:'Take the package.',preview:'+6 CR now · Rook +1 · Delivery follows',delta:{credits:6},relations:{rook:1},next:'door',outcome:'You take six credits and a package light enough to hide under a coat. Rook gives you an address.'},
      {id:'refuse',label:'Walk away from the easy money.',preview:'No cost · Delivery closes',next:'done',outcome:'Rook shrugs and asks the next person. The city will always have someone who needs six credits.'},
    ]},
    door:{title:'You can hear someone coughing.',text:'The destination is a quarantined Somatic Ward. A child’s voice emerges from a disconnected intercom. The capsule warms against your palm: stabilizers bearing the Canon seal. Rook expects a clean delivery. The Ward has not received supplies in three cycles.',choices:[
      {id:'deliver',label:'Hand it over. Take the money.',preview:'+14 CR · +12 heat · Rook +2 · Smuggler',hours:2,energy:10,delta:{credits:14,heat:12},relations:{rook:2},role:'Smuggler',flags:{deliveredMedicine:true},next:'done',outcome:'The clinic takes the medicine. Rook pays fourteen credits. It helped someone. It also put your name on a list.'},
      {id:'keep',label:'Keep the medicine for yourself.',preview:'+1 medicine · +8 heat · Rook −3',delta:{medicine:1,heat:8},relations:{rook:-3},flags:{brokeDelivery:true},next:'done',outcome:'You slip away with the tablets. Your own body needs help, too. Rook won’t offer you another package.'},
      {id:'return',label:'Return it to the Authority.',preview:'+3 trust · −6 CR advance · Rook −2',cost:{credits:6},delta:{rep:3},relations:{rook:-2},next:'done',outcome:'The Authority takes the package and your advance. The clerk thanks you without looking up. The coughing continues.'},
    ]},
  }},
  papers: {title:'A name in the registry',speaker:'Voss / Canon identity clerk',location:'Canon Registry',image:'city',requires:p=>p.rep>=4,locked:'Build 4 trust to receive the registry summons.',nodes:{
    start:{title:'Your papers have a discrepancy.',text:'Voss scans the civic seal beneath your skin. “Your identity checksum belongs to an obsolete version of the city.” The queue behind you advances without moving its feet. Rewriting your implant costs six credits. A manual review costs two hours of your life.',choices:[
      {id:'pay',label:'Pay to rewrite the civic checksum.',preview:'−6 CR · +2 trust · Voss +1',cost:{credits:6},delta:{rep:2},relations:{voss:1},next:'favor',outcome:'The seal costs six credits and takes three seconds. Voss’s expression never changes.'},
      {id:'wait',label:'Wait for the formal review.',preview:'2 hours · −4 energy · +3 trust',hours:2,energy:4,delta:{rep:3},relations:{voss:-1},next:'favor',outcome:'You wait until the office empties. The seal was valid all along. Voss stamps it again anyway.'},
      {id:'leave',label:'Leave with the old papers.',preview:'+5 heat · Keep your money',delta:{heat:5},next:'done',outcome:'You leave before your number is called. The next checkpoint may ask a different question.'},
    ]},
    favor:{title:'There is always another stamp.',text:'Voss sends a message directly into your implant. “There is a registry outside the registry. I can place your identity there.” A second identity could save a day. It could also belong to someone who has not been born yet.',choices:[
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
  for(const [key,n] of Object.entries(choice.cost||{}))if((p[key]||0)<n)return key==='credits'?`Need ${n} credits.`:`Need ${n} ${key==='bread'?'ration':key==='scrap'?'relay fragment':key}.`;
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
  for(const [key,n] of Object.entries(choice.delta||{})){const next=(p[key]||0)+n;p[key]=key==='alignment'?Math.max(-100,Math.min(100,next)):['health','energy','warmth','fullness','heat','coherence'].includes(key)?Math.max(0,Math.min(100,next)):Math.max(0,next);}
  for(const [name,n] of Object.entries(choice.relations||{}))s.contacts[name]=(s.contacts[name]||0)+n;
  Object.assign(s.flags,choice.flags||{});if(choice.role)p.role=choice.role;
  s.threads[input.id]=choice.next;s.decisions.push({thread:input.id,node:nodeId,choice:choice.id,label:choice.label,outcome:choice.outcome,created:now});
  return {message:choice.outcome,hours:choice.hours||0,energy:choice.energy||0,force:choice.force||0};
}
