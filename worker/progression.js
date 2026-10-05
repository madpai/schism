// Persistent character equipment and career progression; all effects are server-owned.
export const gearCatalog={
  weathercoat:{name:'Threadbare weathercoat',slot:'body',price:0,icon:'coat',description:'City-issue synthetic leather. Rain gets in at the seams.',effect:'No protection bonus',starter:true},
  boots:{name:'Worn work boots',slot:'feet',price:0,icon:'jobs',description:'The soles remember every shift you have forgotten.',effect:'No fatigue bonus',starter:true},
  civicimplant:{name:'Civic identity implant',slot:'neural',price:0,icon:'shield',description:'Your name, your debt, and the city’s right to locate you.',effect:'Standard civic connection',starter:true},
  coat:{name:'Insulated shroud',slot:'body',price:18,stock:8,icon:'coat',description:'Conductive lining turns waste implant heat into shelter.',effect:'Cold loss: 1 / hour instead of 3',cold:1},
  respirator:{name:'Particulate respirator',slot:'head',price:14,stock:10,icon:'shield',description:'A refurbished filter for the recovery tunnels.',effect:'Hazardous shifts cause 2 less health damage',protection:2},
  gloves:{name:'Servo work gloves',slot:'hands',price:12,stock:12,icon:'union',description:'Second-hand tendon motors. An extra pair of hands inside yours.',effect:'Work costs 2 less energy',energy:2},
  gripboots:{name:'Magnetic transit boots',slot:'feet',price:16,stock:10,icon:'jobs',description:'Hold the walkway when a transit pylon changes direction.',effect:'Physical shifts cost 3 less energy',physicalEnergy:3},
  bufferchip:{name:'Mnemonic buffer',slot:'neural',price:28,stock:6,icon:'energy',description:'Keeps an empty memory slot between you and the archive.',effect:'Work loses 3 less coherence',coherence:3},
  ghostchip:{name:'Ghost identity chip',slot:'neural',price:36,stock:4,icon:'underground',description:'A civic signature belonging to someone the Canon has never met.',effect:'Capture risk −5 percentage points',captureRisk:-.05},
  scanner:{name:'Retinal field scanner',slot:'hands',price:24,stock:8,icon:'pin',description:'Finds signals, faults, and bodies hidden behind rain.',effect:'Field shifts pay 2 extra credits',fieldPay:2},
};
export const careerPaths={
  mnemonic:{name:'Mnemonic engineering',employer:'Canon Mnemonic Works',description:'Sort memories. Diagnose the lattice. Become trusted with things you were never meant to remember.',ranks:['Memory apprentice','Lattice technician','Memory specialist','Lattice keeper'],icon:'energy'},
  transit:{name:'Transit & courier work',employer:'Vestibule Transit Office',description:'Move freight and messages through a city that keeps changing its own streets.',ranks:['Transit runner','Licensed courier','Route specialist','Transit controller'],icon:'pin'},
  civic:{name:'Civic service',employer:'Canon Civic Bureau',description:'Clean the public terminals. Process identities. Become the person who decides who counts.',ranks:['Civic attendant','Registry clerk','Civic inspector','Canon administrator'],icon:'institutions'},
  recovery:{name:'Industrial recovery',employer:'Stratum Reclamation Office',description:'Strip dead infrastructure for parts. Learn which noises mean it is still alive.',ranks:['Recovery hand','Salvage operative','Reclamation specialist','Recovery supervisor'],icon:'box'},
};
export const shiftTypes={
  standard:{name:'Regular shift',pay:1,hours:0,energy:0,requires:0,description:'Ordinary pay. Ordinary exhaustion.'},
  overtime:{name:'Overtime',pay:1.6,hours:1,energy:8,requires:2,description:'60% more base pay; +1 hour and +8 energy.'},
  graveyard:{name:'Graveyard',pay:1.35,hours:1,energy:4,requires:2,description:'35% more base pay; +1 hour, +4 energy, +3 heat, −4 coherence.'},
};
export const specialistJobs={
  diagnostics:{name:'Grid diagnostic survey',employer:'Canon Mnemonic Works',pay:16,energy:17,hours:2,rep:2,description:'Follow a faulty memory signal into the rain. The scanner says it has a heartbeat.',risk:'Field diagnostics',requires:4,career:'mnemonic',xp:12,field:true,coherence:2},
  extraction:{name:'Memory extraction',employer:'Canon Mnemonic Works',pay:28,energy:29,hours:4,rep:3,description:'Enter a live archive and separate a citizen from their recorded past.',risk:'Neural exposure',requires:8,career:'mnemonic',xp:32,coherence:5},
  delivery:{name:'Rainline delivery',employer:'Vestibule Transit Office',pay:10,energy:14,hours:2,rep:1,description:'Carry sealed correspondence across the elevated rainline. Do not read the return address.',risk:'Street exposure',requires:0,career:'transit',physical:true,field:true},
  nightcourier:{name:'Black-route courier',employer:'Vestibule Transit Office',pay:24,energy:28,hours:4,rep:2,description:'Deliver to unregistered addresses between two civic scanner passes.',risk:'Unregistered route',requires:4,career:'transit',xp:12,physical:true,field:true,heat:4},
  records:{name:'Identity processing',employer:'Canon Civic Bureau',pay:9,energy:12,hours:2,rep:1,description:'Approve six identities an hour. The same face appears in every seventh application.',risk:'Archive duty',requires:0,career:'civic'},
  patrol:{name:'Anomaly field inspection',employer:'Canon Civic Bureau',pay:19,energy:23,hours:3,rep:2,description:'Investigate a housing stack that is reporting one more resident than it contains.',risk:'Field inspection',requires:4,career:'civic',xp:12,physical:true,field:true,heat:3},
  salvage:{name:'Tunnel salvage',employer:'Stratum Reclamation Office',pay:11,energy:20,hours:2,rep:1,description:'Strip a dead transit relay in the lower tunnels. Bring back one usable fragment.',risk:'Hazardous air',requires:0,career:'recovery',physical:true,field:true,hazard:2,scrap:1},
  reclamation:{name:'Deep-core reclamation',employer:'Stratum Reclamation Office',pay:25,energy:30,hours:4,rep:3,description:'Recover two relay fragments from a server core marked biologically active.',risk:'Biological exposure',requires:8,career:'recovery',xp:32,physical:true,field:true,hazard:5,scrap:2,coherence:2},
};
const baseLoadout={head:null,body:'weathercoat',hands:null,feet:'boots',neural:'civicimplant'};
export function careerState(p){
  p.ownedGear??=['weathercoat','boots','civicimplant',...(p.coat?['coat']:[])];
  p.loadout??={...baseLoadout,body:p.coat?'coat':'weathercoat'};
  p.career??='mnemonic';p.careers??={};
  for(const id of Object.keys(careerPaths))p.careers[id]??={xp:id==='mnemonic'?p.shifts*2:0,shifts:0};
  p.dailyWork??={day:0,counts:{},claimed:{}};
  return p;
}
export function rankFor(xp){return xp>=64?3:xp>=32?2:xp>=12?1:0;}
export function gearEffects(p){
  const effects={cold:3,energy:0,physicalEnergy:0,protection:0,coherence:0,captureRisk:0,fieldPay:0};
  for(const id of Object.values(p.loadout||{})){const g=gearCatalog[id];if(!g)continue;for(const key of Object.keys(effects))if(g[key]!==undefined)effects[key]=key==='cold'?g[key]:effects[key]+g[key];}
  return effects;
}
export function coldRate(p,w={}){return Math.max(0,gearEffects(p).cold-(w.heating?1:0));}
export function jobQuote(p,job,mode='standard',w={}){
  const shift=shiftTypes[mode],effects=gearEffects(p),track=p.careers[job.career],rank=rankFor(track.xp);
  const pay=Math.ceil(job.pay*shift.pay)+(p.union?1:0)+(p.career===job.career?rank:0)+(job.field?effects.fieldPay:0);
  const hours=job.hours+shift.hours,energy=Math.max(2,job.energy+shift.energy-effects.energy-(job.physical?effects.physicalEnergy:0));
  const blocked=p.rep<job.requires?`Requires ${job.requires} trust.`:track.xp<(job.xp||0)?`Requires ${job.xp} ${careerPaths[job.career].name} XP.`:p.shifts<shift.requires?`Complete ${shift.requires} shifts first.`:p.health<15?'Treatment needed.':p.energy<energy?`Need ${energy} energy.`:null;
  return {mode,name:shift.name,pay,hours,energy,fullness:hours*3,warmth:hours*coldRate(p,w),xp:hours*2,healthLoss:Math.max(0,(job.hazard||0)-effects.protection),coherenceLoss:Math.max(0,(job.coherence||0)+(mode==='graveyard'?4:0)-effects.coherence),heat:(job.heat||0)+(mode==='graveyard'?3:0),scrap:job.scrap||0,blocked};
}
export function recordShift(p,job,quote,day){
  p.careers[job.career].xp+=quote.xp;p.careers[job.career].shifts++;
  if(p.dailyWork.day!==day)p.dailyWork={day,counts:{},claimed:{}};
  p.dailyWork.counts[job.career]=(p.dailyWork.counts[job.career]||0)+1;
}
export function careerSnapshot(p,w){
  return Object.entries(careerPaths).map(([id,path])=>{const record=p.careers[id],rank=rankFor(record.xp),next=[12,32,64][rank]||null;return {id,...path,...record,rank,title:path.ranks[rank],next,active:p.career===id,bonus:rank,quota:p.dailyWork.day===w.day?p.dailyWork.counts[id]||0:0,claimed:p.dailyWork.day===w.day&&!!p.dailyWork.claimed[id]};});
}
export function equipmentSnapshot(p,stock,w={}){return Object.entries(gearCatalog).map(([id,g])=>({id,...g,price:g.price+(id==='coat'&&w.shortage?2:0),stock:stock.find(s=>s.id===id)?.stock||0,owned:p.ownedGear.includes(id),equipped:p.loadout[g.slot]===id}));}
export function removeEquipment(p,slot){p.loadout[slot]=baseLoadout[slot];p.coat=p.loadout.body==='coat';}
