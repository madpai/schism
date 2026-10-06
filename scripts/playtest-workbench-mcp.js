async (page) => {
 const errors=[],failedAssets=[];page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.url().includes('/art/')&&r.status()>=400)failedAssets.push({url:r.url(),status:r.status()});});
 const visits=[];
 for(const width of [1440,390,360]){
  await page.setViewportSize({width,height:900});
  for(const dest of ['skills','workshop','hacking','camp','inventory','loadout','jobs','market']){
   await page.evaluate(dest=>go(dest),dest);
   if(dest==='workshop'){
    for(const section of ['repairs','supplies','comfort','exchange']){await page.locator(`[data-workbench-tab="${section}"]`).click();await page.waitForTimeout(50);visits.push(await measure(dest+'/'+section));}
   }else {await page.waitForTimeout(50);visits.push(await measure(dest));}
  }
 }
 await page.setViewportSize({width:1440,height:1000});await page.evaluate(()=>{workbenchTab='repairs';go('workshop')});
 await page.evaluate(async()=>{await Promise.all([...document.querySelectorAll('#main img')].map(i=>{i.loading='eager';return i.decode().catch(()=>{});}));});await page.waitForTimeout(350);await page.screenshot({path:'/home/commander/ashfall/.local-data/evidence/v010-workshop-desktop.png',fullPage:true});
 await page.setViewportSize({width:390,height:844});await page.evaluate(()=>go('hacking'));await page.evaluate(async()=>{await Promise.all([...document.querySelectorAll('#main img')].map(i=>{i.loading='eager';return i.decode().catch(()=>{});}));});await page.waitForTimeout(350);await page.screenshot({path:'/home/commander/ashfall/.local-data/evidence/v010-signals-mobile.png',fullPage:true});
 async function measure(dest){return page.evaluate(dest=>({dest,width:innerWidth,overflow:document.documentElement.scrollWidth>innerWidth,heading:document.querySelector('#main h1')?.textContent,brokenImages:[...document.querySelectorAll('#main img')].filter(i=>i.complete&&i.naturalWidth===0).map(i=>i.src),invalidButtons:[...document.querySelectorAll('#main button')].filter(b=>!b.textContent.trim()&&!b.getAttribute('aria-label')).length}),dest);}
 return {visits:visits.length,failures:visits.filter(v=>v.overflow||v.brokenImages.length||v.invalidButtons),errors,failedAssets,details:visits};
}
