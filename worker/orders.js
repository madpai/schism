const orderNeed=(ok,message)=>{if(!ok)throw Object.assign(new Error(message),{status:400});};
export const supplyCatalog={
 cloth:{name:'Salvaged fabric',material:true,icon:'coat'},wire:{name:'Copper wire',material:true,icon:'energy'},circuit:{name:'Circuit parts',material:true,icon:'box'},data:{name:'Signal traces',material:true,icon:'energy'},
 heatpack:{name:'Improvised warming pack',icon:'temp'},bandage:{name:'Clean field dressing',icon:'health'},neuralpatch:{name:'Neural grounding patch',icon:'energy'},
 bread:{name:'Vat-grown ration',icon:'bread'},medicine:{name:'Somatic stabilizer',icon:'health'},scrap:{name:'Relay fragment',icon:'box'},
};
export function supplyCount(p,id){return supplyCatalog[id]?.material?p.materials?.[id]||0:p[id]||0;}
export function changeSupply(p,id,n){if(supplyCatalog[id].material){p.materials??={};p.materials[id]=(p.materials[id]||0)+n;}else p[id]=(p[id]||0)+n;}
const supplyPath=id=>supplyCatalog[id].material?'$.materials.'+id:'$.'+id;
export async function ensureSupplyOrders(db,w){
 const row=await db.prepare('SELECT count(DISTINCT citizen) n FROM city_activity WHERE completes>? AND completes<=?').bind(w.now-21600000,w.now).first();
 const quantity=Math.max(3,Math.min(8,row.n||0));
 const items=w.day%2?[['wire',2],['bandage',3]]:[['heatpack',4],['wire',2]];
 await db.batch([
  db.prepare('UPDATE supply_orders SET status=2 WHERE buyer IS NULL AND day<? AND status=0').bind(w.day),
  ...items.map(([item,price])=>db.prepare('INSERT OR IGNORE INTO supply_orders (id,buyer,item,price,remaining,quantity,status,day,created) VALUES (?,NULL,?,?,?,?,0,?,?)').bind(`municipal-${w.day}-${item}`,item,price,quantity,quantity,w.day,w.now)),
 ]);
}
export async function supplyOrdersSnapshot(db,p,w){
 await ensureSupplyOrders(db,w);
 const orders=(await db.prepare("SELECT o.*,coalesce(c.name,'Municipal Relief') name FROM supply_orders o LEFT JOIN citizens c ON c.id=o.buyer WHERE o.status=0 AND (o.buyer IS NOT NULL OR o.day=?) ORDER BY CASE WHEN o.buyer=? THEN 0 ELSE 1 END,o.created DESC LIMIT 48").bind(w.day,p.id).all()).results;
 return {catalog:supplyCatalog,orders,municipalUsed:p.district?.municipalSales||0,slots:p.business?8:3};
}
export async function supplyOrderAction(db,p,c,input,w,op){
 const extra=[],checks=[],make=(sql,...args)=>db.prepare(sql).bind(...args);let message='',taxGross=0,metrics={};
 if(input.action==='order_create'){
  orderNeed(typeof input.item==='string'&&Object.hasOwn(supplyCatalog,input.item),'Choose a published supply.');
  orderNeed(Number.isInteger(input.quantity)&&input.quantity>=1&&input.quantity<=10,'Request 1–10 units.');orderNeed(Number.isInteger(input.price)&&input.price>=1&&input.price<=50,'Offer 1–50 credits per unit.');
  const total=input.quantity*input.price;orderNeed(p.credits>=total,`Reserve ${total} credits to post this order.`);
  const count=await make('SELECT count(*) n FROM supply_orders WHERE buyer=? AND status=0',c.id).first();orderNeed(count.n<(p.business?8:3),'Your supply-order slots are full. Fill or cancel an order first.');
  p.credits-=total;extra.push(make('INSERT INTO supply_orders (id,buyer,item,price,remaining,quantity,status,day,created) VALUES (?,?,?,?,?,?,0,?,?)',crypto.randomUUID(),c.id,input.item,input.price,input.quantity,input.quantity,w.day,w.now));
  message=`Requested ${input.quantity} ${supplyCatalog[input.item].name.toLowerCase()} at ${input.price} CR each. ${total} credits are held until delivery or cancellation.`;
 }else{
  orderNeed(typeof input.id==='string','Choose an order.');
  const offer=await make('SELECT * FROM supply_orders WHERE id=? AND status=0',input.id).first();orderNeed(offer,'This order has already closed.');
  orderNeed(offer.buyer!==null||offer.day===w.day,'That municipal order belongs to an earlier cycle.');
  checks.push(make('INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM supply_orders WHERE id=? AND status=0 AND remaining=?),0))',op+'request',offer.id,offer.remaining));
  if(input.action==='order_cancel'){
   orderNeed(offer.buyer===c.id,'Only the buyer can cancel this order.');const refund=offer.remaining*offer.price;p.credits+=refund;
   extra.push(make('UPDATE supply_orders SET status=2 WHERE id=?',offer.id));message=`Order cancelled. ${refund} held credits returned; earlier deliveries remain yours.`;
  }else{
   orderNeed(offer.buyer!==c.id,'You cannot fill your own order.');orderNeed(Number.isInteger(input.quantity)&&input.quantity>=1&&input.quantity<=10&&input.quantity<=offer.remaining,'Choose an available quantity of 1–10 units.');
   if(offer.buyer===null){orderNeed(!p.district.municipalSales,'One municipal delivery per citizen per cycle. Other citizens need the work too.');orderNeed(input.quantity===1,'Municipal Relief buys one unit per citizen per cycle.');}
   orderNeed(supplyCount(p,offer.item)>=input.quantity,`You need ${input.quantity} ${supplyCatalog[offer.item].name.toLowerCase()}.`);
   changeSupply(p,offer.item,-input.quantity);const gross=input.quantity*offer.price;p.credits+=gross;taxGross=gross;
   extra.push(make('UPDATE supply_orders SET remaining=remaining-?,status=CASE WHEN remaining=? THEN 1 ELSE 0 END WHERE id=?',input.quantity,input.quantity,offer.id));
   if(offer.buyer!==null){
    checks.push(make("INSERT INTO action_guards (id,valid) VALUES (?,COALESCE((SELECT 1 FROM citizens WHERE id=? AND json_extract(data,'$.registered') IS NOT 0),0))",op+'recipient',offer.buyer));
    const path=supplyPath(offer.item);extra.push(make('UPDATE citizens SET data=json_set(data,?,coalesce(json_extract(data,?),0)+?),version=version+1 WHERE id=?',path,path,input.quantity,offer.buyer),make('INSERT INTO journal (id,citizen,body,created) VALUES (?,?,?,?)',crypto.randomUUID(),offer.buyer,`${input.quantity} ${supplyCatalog[offer.item].name.toLowerCase()} delivered to your supply order. ${gross} held credits released to the supplier.`,w.now));
   }else{p.district.municipalSales=1;if(offer.item==='heatpack'||offer.item==='bandage')metrics.relief=1;}
   message=`Delivered ${input.quantity} ${supplyCatalog[offer.item].name.toLowerCase()}. ${gross} taxable credits received from ${offer.buyer===null?'Municipal Relief':'the buyer’s held payment'}.`;
  }
 }
 return {extra,checks,message,taxGross,metrics};
}
