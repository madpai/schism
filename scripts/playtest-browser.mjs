// Optional real-time browser playthrough against the running shared local city.
// Run npm run dev first. Each run creates a separate ordinary citizen.
import {chromium} from 'playwright-core';
import assert from 'node:assert/strict';
import {mkdir} from 'node:fs/promises';
const url=process.env.SCHISM_QA_URL||'http://127.0.0.1:4173';
const out=process.env.SCHISM_QA_OUTPUT||'.local-data/qa-screenshots';await mkdir(out,{recursive:true});
const browser=await chromium.launch({executablePath:process.env.SCHISM_BROWSER||'/opt/brave-bin/brave',headless:true,args:['--no-sandbox','--disable-gpu','--disable-dev-shm-usage']});
try{
 const context=await browser.newContext({viewport:{width:390,height:844},isMobile:true,hasTouch:true}),page=await context.newPage(),errors=[];
 page.on('pageerror',error=>errors.push(error.message));
 const name='QA '+crypto.randomUUID().slice(0,6),notice=name+' connected to the shared district wire.';
 const read=()=>page.evaluate(async()=>await (await fetch('/api/state')).json());
 const nav=async id=>{await page.evaluate(id=>go(id),id);await page.waitForTimeout(800);};
 const finish=async()=>{const s=await read();assert(s.citizen.errand);console.log(`Waiting ${Math.ceil((s.citizen.errand.endsAt-Date.now())/1000)} real seconds: ${s.citizen.errand.label}`);await page.waitForTimeout(Math.max(0,s.citizen.errand.endsAt-Date.now()+1300));await page.waitForFunction(()=>!c().errand);return read();};
 await page.goto(url);await page.locator('#register-form').waitFor();
 await page.locator('input[name="name"]').fill(name);await page.locator('select[name="gender"]').selectOption('Woman');await page.getByRole('button',{name:'Skin tone: Bronze',exact:true}).click();await page.getByRole('button',{name:'Hair color: Copper',exact:true}).click();await page.locator('select[name="style"]').selectOption('Braids');
 assert.equal(await page.locator('input[name="name"]').inputValue(),name);await page.screenshot({path:out+'/arrival-mobile.png'});
 await page.getByRole('button',{name:'Register and step off the train',exact:true}).click();await page.locator('.identity-strip').waitFor();await page.getByRole('button',{name:'Continue into the district',exact:true}).click();
 await nav('street');await page.locator('[data-action="quick"][data-id="bins"]').click();let s=await read();assert.equal(s.citizen.credits,0);assert(Object.values(s.citizen.materials).every(n=>n===0));s=await finish();assert.equal(Object.values(s.citizen.materials).reduce((a,b)=>a+b,0),2);
 await nav('network');await page.locator('#network-message').fill(notice);await page.getByRole('button',{name:'Transmit',exact:true}).click();await page.locator('.neural-message').getByText(notice,{exact:true}).waitFor();
 const second=await browser.newContext(),neighbor=await second.newPage();await neighbor.goto(url);await neighbor.locator('#register-form').waitFor();await neighbor.locator('input[name="name"]').fill(name+' Neighbor');await neighbor.getByRole('button',{name:'Register and step off the train',exact:true}).click();await neighbor.locator('.identity-strip').waitFor();await neighbor.evaluate(()=>go('network'));await neighbor.locator('.neural-message').getByText(notice,{exact:true}).waitFor();const n=await neighbor.evaluate(async()=>await (await fetch('/api/state')).json());assert.notEqual(n.citizen.id,s.citizen.id);assert.equal(n.world.day,s.world.day);await second.close();
 await nav('street');await page.locator('[data-action="quick"][data-id="salvage"]').click();s=await finish();assert.equal(s.citizen.materials.circuit,1);
 await nav('jobs');await page.locator('[data-action="work"][data-id="sorting"]').click();await page.getByRole('button',{name:'Confirm',exact:true}).click();await page.locator('.assignment-panel').waitFor();await page.reload();await page.locator('.assignment-panel').waitFor();
 await nav('workshop');s=await read();const recipe=s.citizen.materials.cloth>=2?'bandage':'scrap';await page.locator(`[data-action="craft"][data-id="${recipe}"]`).click();s=await finish();assert(s.citizen[recipe]>=1&&s.citizen.activity);
 await nav('street');assert(await page.locator('[data-action="quick"][data-id="bins"]').isDisabled());await page.locator('[data-action="quick"][data-id="decode"]').click();s=await finish();assert.equal(s.citizen.materials.data,1);assert.equal(s.citizen.credits,0);
 await nav('network');await page.locator('[data-action="network_job"][data-id="public"]').click();s=await finish();assert.equal(s.citizen.credits,2);assert(s.citizen.activity&&s.cityLife.metrics.freight>=1);
 await nav('profile');await page.getByRole('button',{name:'Hair color: Silver',exact:true}).click();await page.waitForTimeout(800);await page.getByRole('button',{name:'Save appearance',exact:true}).click();await page.waitForTimeout(1000);await page.reload();await page.locator('#appearance-form').waitFor();assert((await page.locator('.dossier-sheet svg').getAttribute('aria-label')).includes('silver'));
 for(const width of [360,390,1440]){await page.setViewportSize({width,height:width>760?1000:844});for(const id of ['overview','street','workshop','network','jobs','city','housing','inventory','loadout','careers','encounters','forces','underground','institutions','profile','citizens']){await nav(id);assert(!(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth)),`${id}/${width} overflow`);if(['profile','street','network','workshop','jobs'].includes(id)&&width!==360)await page.screenshot({path:out+`/${id}-${width}.png`});}}
 assert.deepEqual(errors,[]);console.log(JSON.stringify({passed:'real timers, two shared-city citizens, crafting during work, district contracts, appearance persistence, all desktop/mobile screens',name,errors}));
}finally{await browser.close();}
