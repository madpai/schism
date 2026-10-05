// Run with Playwright MCP browser_run_code_unsafe(filename), in a signed-in local QA tab.
// Uses visible navigation and read-only refreshes. It never grants supplies or changes clocks.
async (page) => {
 const assert=(ok,message)=>{if(!ok)throw new Error(message);};
 assert(/^http:\/\/(100\.89\.1\.14|127\.0\.0\.1):4173\//.test(page.url()),'Use the shared local QA city.');
 const errors=[],onError=error=>errors.push(error.message);
 page.on('pageerror',onError);
 const navigate=async id=>{
  if(page.viewportSize().width<=760)await page.getByRole('button',{name:'Toggle navigation',exact:true}).click();
  await page.locator(`.sidebar [data-nav="${id}"]`).click();
  await page.waitForFunction(id=>tab===id,id);
 };
 const result={started:new Date().toISOString(),screens:[],checks:[]};
 try{
  await page.reload();
  await page.waitForFunction(()=>ready&&c().registered);
  const before=await page.evaluate(()=>({name:c().name,housing:c().housing,activityEnd:c().activity?.endsAt,stock:state.tenants.block?.stock}));
  result.citizen=before.name;
  result.renderCases=await page.evaluate(()=>{
   const original=state,checks=[];
   try{
    state=structuredClone(state);
    const parse=html=>new DOMParser().parseFromString(html,'text/html');
    c().taxDebt=2;
    if(!parse(taxPanel(true)).querySelector('details').open)throw Error('Assessed tax should expand by default.');
    c().taxDebt=0;c().taxHold=true;
    if(!parse(taxPanel(true)).querySelector('details').open)throw Error('An ID hold should expand tax details.');
    checks.push('Assessed tax and held IDs expand housing tax details by default.');
    for(const [action,destination] of [['rest','housing'],['clearance','institutions'],['crime','underground'],['work','jobs']]){
     c().activity={action,label:'Client-only render check',endsAt:Date.now()+60000};
     if(parse(overview()).querySelector('.feed-row [data-nav]').dataset.nav!==destination)throw Error(`Wrong ${action} Details destination.`);
    }
    checks.push('Rest, clearance, crime and work details link to the relevant screen.');
    return checks;
   }finally{state=original;}
  });
  for(const width of [360,390,1440]){
   await page.setViewportSize({width,height:width>760?1000:844});
   for(const id of ['overview','street','workshop','network','city','jobs','market','housing','neighbors','loadout','inventory','careers','encounters','forces','underground','institutions','citizens','profile']){
    await navigate(id);
    const measure=await page.evaluate(()=>({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,height:document.documentElement.scrollHeight}));
    assert(measure.scrollWidth<=width,`${id}/${width} has horizontal overflow`);
    result.screens.push({page:id,...measure});
   }
  }
  result.checks.push('All 17 navigation screens and character papers fit 360/390/1440px.');
  await page.setViewportSize({width:390,height:844});
  await navigate('housing');
  const options=page.locator('[data-view-key="housing-options"]');
  const tax=page.locator('.tax-disclosure');
  assert(!await options.evaluate(el=>el.open),'Secondary housing starts folded.');
  await options.locator('summary').click();
  if(!await tax.evaluate(el=>el.open))await tax.locator('summary').click();
  await page.evaluate(()=>load(true));
  assert(await options.evaluate(el=>el.open)&&await tax.evaluate(el=>el.open),'Refresh collapsed an opened housing section.');
  await navigate('overview');await navigate('housing');
  assert(await options.evaluate(el=>el.open),'Navigation forgot the housing section.');
  await options.locator('summary').click();await tax.locator('summary').click();
  await page.evaluate(()=>load(true));
  assert(!await options.evaluate(el=>el.open)&&!await tax.evaluate(el=>el.open),'Refresh reopened a deliberately folded section.');
  result.checks.push('Open and closed housing sections survive refresh and navigation.');
  result.housing=await page.evaluate(()=>({height:document.documentElement.scrollHeight,sleepButtonTop:Math.round(document.querySelector('[data-action="rest"]').getBoundingClientRect().top+scrollY)}));
  await navigate('institutions');
  assert(await page.locator('.tax-panel').isVisible(),'Registry tax controls should stay visible.');
  assert(await page.locator('.tax-disclosure').count()===0,'Registry inherited the housing fold.');
  result.checks.push('Registry keeps its full tax controls.');
  await navigate('neighbors');
  if(await page.locator('.tenant-header').count()){
   const empty=page.locator('[data-view-key="empty-supplies"]');
   if(await empty.count()){
    assert(!await empty.evaluate(el=>el.open),'Empty stock starts folded.');
    await empty.locator('summary').click();await page.evaluate(()=>load(true));
    assert(await empty.evaluate(el=>el.open),'Refresh collapsed empty stock.');
    await empty.locator('summary').click();
   }
   const draft='Unsent QA draft: check the radiator before the next visit.';
   const field=page.locator('#tenant-message-form textarea');
   await field.fill(draft);await page.evaluate(()=>load(true));
   assert(await field.inputValue()===draft,'Refresh lost the unsent building draft.');
   await field.fill('');await field.blur();
   result.neighbors=await page.evaluate(()=>({height:document.documentElement.scrollHeight,channelTop:Math.round(document.querySelector('.tenant-channel').getBoundingClientRect().top+scrollY),stockedRows:document.querySelectorAll('.tenant-stock').item(0).children.length}));
   result.checks.push('Empty-stock sections and unsent building drafts survive refresh.');
  }
  const after=await page.evaluate(()=>({housing:c().housing,activityEnd:c().activity?.endsAt,stock:state.tenants.block?.stock}));
  assert(before.housing===after.housing,'The UI sweep changed housing.');
  assert(before.activityEnd===after.activityEnd||(before.activityEnd<=Date.now()&&!after.activityEnd),'The UI sweep changed a live assignment deadline.');
  assert(JSON.stringify(before.stock)===JSON.stringify(after.stock),'The UI sweep changed shelf stock.');
  assert(errors.length===0,errors.join('\n'));
  result.errors=errors;result.ended=new Date().toISOString();
  await navigate('overview');
  return result;
 }finally{page.off('pageerror',onError);}
}
