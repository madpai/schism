// Each row is an immutable commitment. Completed contributions affect the whole city,
// even if the citizen who started the shift has not come back to collect their pay.
export const cityResponses={
  output:{name:'Emergency printer shift',description:'Feed the ration printers. Two hours, 18 energy, 5 credits and 4 production.',hours:2,energy:18,pay:5,output:4},
  freight:{name:'Unload a relief train',description:'Haul sealed food crates off the rainline. Two hours, 22 energy, 6 credits and 3 freight.',hours:2,energy:22,pay:6,freight:3},
  relief:{name:'Run the communal boiler',description:'Burn one relay fragment to heat the cells. Two hours, 12 energy, 1 trust and 2 relief.',hours:2,energy:12,pay:0,relief:2,scrap:1},
};
export async function cityLife(db,w,now){
  const [metrics,population]=await Promise.all([
    db.prepare('SELECT COALESCE(sum(output),0) output, COALESCE(sum(freight),0) freight, COALESCE(sum(crime),0) crime, COALESCE(sum(unrest),0) unrest, COALESCE(sum(relief),0) relief, COALESCE(sum(patrols),0) patrols FROM city_activity WHERE day=? AND completes<=?').bind(w.day,now).first(),
    db.prepare("SELECT count(*) n FROM citizens WHERE json_extract(data,'$.registered') IS NOT 0 AND updated>?").bind(now-86400000).first(),
  ]);
  const target=Math.max(6,population.n*3),events=[];
  const add=(id,title,cause,effect,tone='danger')=>events.push({id,title,cause,effect,tone});
  let food=0,wages=0,security=0,cold=0;
  if(w.shortage){food+=2;cold++;add('front','Null front','A freezing pressure front has reached the district.','Food +2 CR. Exposure +1 warmth per city hour.');}
  if(w.inspection){add('inspection','Identity sweep','The Canon has ordered a district inspection.','Checkpoint capture risk +15 percentage points.');}
  if(w.hour>=12&&metrics.output<target){food++;wages--;add('shortfall','Production shortfall',`${metrics.output} / ${target} production. Citizens have not kept the foundry staffed.`,'Food +1 CR. Shift wages −1 CR. Emergency printer work is available.');}
  if(w.hour>=8&&metrics.freight<3){food++;add('freight','Relief train held at the border','Not enough citizens are unloading the rainline.','Food +1 CR until 3 freight is delivered.');}
  if(metrics.crime>=3&&metrics.patrols<metrics.crime){security+=.1;food++;add('raids','District lockdown',`${metrics.crime} criminal operations reported; ${metrics.patrols} security patrols completed.`,'Food +1 CR. Capture risk +10 percentage points. Patrols can lift the lockdown.');}
  if(metrics.unrest>=3){wages+=2;security+=.05;add('strike','The Uncounted win a contract',`${metrics.unrest} organizing shifts have forced the foundry to negotiate.`,'All shift wages +2 CR. Checkpoint capture risk +5 percentage points.','warning');}
  if(metrics.output>=target){food--;add('surplus','Printer lines restored',`Citizens delivered ${metrics.output} production against a target of ${target}.`,'Food −1 CR. Completed factory and emergency shifts add common food stock.','positive');}
  if(metrics.relief>=4){cold--;add('boiler','Communal boilers lit',`${metrics.relief} relief from citizen boiler crews.`,'Every citizen loses 1 less warmth per city hour.','positive');}
  if(metrics.freight>=3)add('arrival','Relief train unloaded',`${metrics.freight} freight delivered by citizens.`,'Border surcharge lifted. Completed freight adds common food stock.','positive');
  Object.assign(w,{foodModifier:food,wageModifier:wages,citySecurityModifier:security,coldModifier:cold});
  return {metrics,target,events,responses:cityResponses,nextCycleAt:(Math.floor(now/21600000)+1)*21600000,workLimit:8,crimeLimit:3};
}
export function contributionFor(action,input,job,hours){
  const m={output:0,freight:0,crime:0,unrest:0,relief:0,patrols:0};
  if(action==='work'){if(['mnemonic','recovery'].includes(job.career))m.output=hours;else if(job.career==='transit')m.freight=hours;else m.relief=1;}
  if(action==='crime')m.crime=1;
  if(action==='organize')m.unrest=1;
  if(action==='security_work')m.patrols=2;
  if(action==='event_work'){const r=cityResponses[input.id];for(const key of Object.keys(m))m[key]=r[key]||0;}
  return m;
}
