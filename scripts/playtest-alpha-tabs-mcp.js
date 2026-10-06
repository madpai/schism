// Read-only subpage checks. Run through Playwright MCP in an ordinary local QA tab.
async(page)=>{
 const assert=(ok,label)=>{if(!ok)throw Error(label);},errors=[],onError=e=>errors.push(e.message),result=[];
 page.on('pageerror',onError);
 try{
  await page.reload();await page.waitForFunction(()=>ready&&c().registered);
  for(const width of [360,390,1440]){
   await page.setViewportSize({width,height:844});
   for(const [screen,attr,sections] of [['street','street-tab',['materials','breaks','planning']],['city','city-tab',['conditions','recovery','paper','explore']],['encounters','story-tab',['neighborhood','encounters','contacts','history']]]){
    if(width<760)await page.getByRole('button',{name:'Toggle navigation',exact:true}).click();
    await page.locator('.sidebar [data-nav="'+screen+'"]').click();
    for(const section of sections){
     await page.locator('[data-'+attr+'="'+section+'"]').click();
     const m=await page.evaluate(()=>({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,height:document.documentElement.scrollHeight}));
     assert(m.scrollWidth<=width,screen+'/'+section+' overflow');assert(await page.locator('[data-'+attr+'="'+section+'"]').getAttribute('aria-pressed')==='true','Section selection did not render.');
     result.push({screen,section,...m});
    }
   }
  }
  await page.setViewportSize({width:390,height:844});
  await page.getByRole('button',{name:'Send game feedback',exact:true}).click();
  assert(await page.locator('#dialog-content #feedback-form').count()===1,'Feedback retains the shared dialog container.');
  await page.locator('#dialog [data-close]').first().click();
  await page.getByRole('button',{name:'Toggle navigation',exact:true}).click();await page.locator('.sidebar [data-nav="jobs"]').click();
  const available=page.locator('[data-action="work"]:not([disabled])');
  if(await available.count()){
   await available.first().click();assert(await page.locator('#dialog [data-confirm]').count()===1,'An action dialog still works after opening feedback.');await page.locator('#dialog [data-close]').first().click();
  }
  assert(!errors.length,errors.join('\n'));return {at:new Date().toISOString(),views:result,errors,feedbackContainer:true};
 }finally{page.off('pageerror',onError);}
}
