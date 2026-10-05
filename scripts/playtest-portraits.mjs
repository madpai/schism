// Bounded visual review using an existing local citizen; no action POSTs or grants.
import {chromium} from 'playwright-core';
import assert from 'node:assert/strict';
import {mkdir} from 'node:fs/promises';

const url=process.env.SCHISM_QA_URL||'http://100.89.1.14:4173';
const storageState=process.env.SCHISM_QA_SESSION||'.local-data/qa-browser.json';
const out=process.env.SCHISM_QA_OUTPUT||'.local-data/portrait-review';
await mkdir(out,{recursive:true});
const browser=await chromium.launch({executablePath:process.env.SCHISM_BROWSER||'/opt/brave-bin/brave',headless:true,args:['--no-sandbox','--disable-gpu','--disable-dev-shm-usage']});
try {
 const context=await browser.newContext({storageState,viewport:{width:1300,height:1000}});
 const page=await context.newPage(),errors=[];
 page.on('pageerror',error=>errors.push(error.message));
 page.on('response',response=>{if(response.status()>=400&&new URL(response.url()).pathname.startsWith('/art/'))errors.push(`${response.status()} ${new URL(response.url()).pathname}`);});
 page.on('requestfailed',request=>{if(new URL(request.url()).pathname.startsWith('/art/'))errors.push(`Art request failed: ${new URL(request.url()).pathname}`);});
 await page.goto(url+'/#overview');await page.locator('.identity-strip').waitFor();
 const citizen=await page.evaluate(()=>({id:c().id,appearance:structuredClone(c().appearance),body:c().loadout.body}));
 for(const outfit of ['weathercoat','adminuniform','securityuniform']) {
  await page.evaluate(item=>{
   const p=c(),body=p.loadout.body;p.loadout.body=item;
   document.querySelector('#main').innerHTML=['Lean','Broad','Soft'].map(frame=>`<h2>${item} / ${frame}</h2><div style="display:grid;grid-template-columns:repeat(5,180px);gap:12px">${['Woman','Man','Nonbinary'].map((gender,i)=>['Shaved','Cropped','Swept','Bob','Braids'].map(style=>`<figure style="margin:0;min-width:0">${citizenArt({...p.appearance,gender,frame,style,skin:['Porcelain','Bronze','Ebony'][i],hair:['Silver','Copper','Violet'][i]})}<figcaption>${gender} ${style}</figcaption></figure>`).join('')).join('')}</div>`).join('');
   p.loadout.body=body;
  },outfit);
  await page.addStyleTag({content:'#main figure .citizen-art{display:block;width:180px;height:270px} #main figure figcaption{font-size:12px;line-height:1.5;padding-top:6px}'});
  await page.waitForTimeout(300);
  assert.equal(await page.locator('#main .citizen-art').count(),45);
  await page.locator('#main').screenshot({path:`${out}/${outfit}.png`});
 }
 await page.evaluate(()=>{
  const p=c();document.querySelector('#main').innerHTML=`<div style="display:grid;grid-template-columns:repeat(6,150px);gap:12px">${Object.keys(skinColors).map((skin,i)=>`<figure style="margin:0">${citizenArt({...p.appearance,skin,hair:Object.keys(hairColors)[i],style:'Braids'})}<figcaption>${skin} / ${Object.keys(hairColors)[i]}</figcaption></figure>`).join('')}</div>`;
 });
 await page.addStyleTag({content:'#main figure .citizen-art{width:150px;height:225px}'});
 await page.waitForTimeout(300);await page.locator('#main').screenshot({path:`${out}/colors.png`});
 for(const width of [360,390,1440]) {
  await page.setViewportSize({width,height:900});
  await page.goto(url+'/#overview');await page.locator('.identity-strip').waitFor();
  await page.locator('.identity-links [data-nav="profile"]').click();await page.locator('.dossier-sheet').waitFor();
  await page.waitForTimeout(250);
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`${width}px profile overflow`);
  await page.screenshot({path:`${out}/profile-${width}.png`,fullPage:true});
 }
 // A fresh intake preview exercises customization without registering a citizen.
 const intake=await browser.newPage({viewport:{width:390,height:844},isMobile:true,hasTouch:true});
 intake.on('pageerror',error=>errors.push(error.message));
 await intake.goto(url);await intake.locator('#register-form').waitFor();
 for(const style of ['Shaved','Braids']) {
  await intake.locator('select[name="gender"]').selectOption('Man');
  await intake.locator('select[name="style"]').selectOption(style);
  await intake.waitForTimeout(250);await intake.screenshot({path:`${out}/intake-${style.toLowerCase()}.png`,fullPage:true});
 }
 const retained=await page.evaluate(async()=>{const s=await(await fetch('/api/state')).json();return {id:s.citizen.id,appearance:s.citizen.appearance,body:s.citizen.loadout.body};});
 assert.deepEqual(retained,citizen);assert.deepEqual(errors,[]);
 console.log(`Portrait review passed: 135 face/build/hair/outfit combinations, six color pairs, 360/390/1440px profiles, mobile intake. Existing identity and wardrobe retained. Inspect screenshots in ${out}.`);
} finally {await browser.close();}
