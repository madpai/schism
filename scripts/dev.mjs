// Local shared-city host. This identity adapter is never bundled into production.
import { createServer } from 'node:http';
import { randomBytes,randomUUID,createHmac,timingSafeEqual } from 'node:crypto';
import { mkdir,readFile,writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import worker from '../dist/server/index.js';
import { localDB } from './local-db.mjs';
const dataDir=resolve(process.env.SCHISM_DATA_DIR||'.local-data');await mkdir(dataDir,{recursive:true,mode:0o700});
const keyPath=resolve(dataDir,'session.key');let key;
try{key=await readFile(keyPath);}catch(error){if(error.code!=='ENOENT')throw error;key=randomBytes(32);await writeFile(keyPath,key,{mode:0o600,flag:'wx'});}
const db=localDB(resolve(dataDir,'city.sqlite'));
let localOperator=null;try{localOperator=JSON.parse(await readFile(resolve(dataDir,'operator.json'),'utf8')).owner;}catch(error){if(error.code!=='ENOENT')throw error;}
const port=Number(process.env.SCHISM_PORT||4173),hosts=[...new Set(['127.0.0.1',...(process.env.SCHISM_TAILSCALE_IP?[process.env.SCHISM_TAILSCALE_IP]:[])])];
const sign=id=>createHmac('sha256',key).update(id).digest('hex');
function session(cookie=''){
 const value=cookie.split(';').map(s=>s.trim()).find(s=>s.startsWith('schism_local_session='))?.slice('schism_local_session='.length)||'';
 const [id,signature]=value.split('.');
 if(/^[0-9a-f-]{36}$/.test(id||'')&&/^[0-9a-f]{64}$/.test(signature||'')&&timingSafeEqual(Buffer.from(signature),Buffer.from(sign(id))))return {id};
 const fresh=randomUUID();return {id:fresh,cookie:`schism_local_session=${fresh}.${sign(fresh)}; Path=/; HttpOnly; SameSite=Strict; Max-Age=31536000`};
}
const handler=async(req,res)=>{
 try{
  const path=req.url.split('?')[0];
  if(path==='/signout-with-chatgpt'){res.writeHead(302,{'Location':'/','Set-Cookie':'schism_local_session=; Path=/; HttpOnly; SameSite=Strict; Max-Age=0'});res.end();return;}
  if(path==='/signin-with-chatgpt'){res.writeHead(302,{'Location':'/'});res.end();return;}
  const current=session(req.headers.cookie),headers=new Headers(req.headers);headers.delete('oai-authenticated-user-email');headers.set('oai-authenticated-user-id','local-'+current.id);
  if(localOperator==='local-'+current.id)headers.set('oai-authenticated-user-email','local.operator@schism.invalid');
  const body=[];let length=0;for await(const chunk of req){length+=chunk.length;if(length>4096){res.writeHead(413);res.end('Request too large');return;}body.push(chunk);}
  const request=new Request('http://'+req.headers.host+req.url,{method:req.method,headers,...(['POST','PUT','PATCH'].includes(req.method)?{body:Buffer.concat(body)}:{})});
  const response=await worker.fetch(request,{DB:db,SCHISM_OPERATOR_EMAIL:'local.operator@schism.invalid'}),outHeaders=Object.fromEntries(response.headers);if(current.cookie)outHeaders['set-cookie']=current.cookie;
  res.writeHead(response.status,outHeaders);res.end(Buffer.from(await response.arrayBuffer()));
 }catch(error){console.error('Local city:',error);res.writeHead(500);res.end('Local city request failed');}
};
for(const host of hosts)createServer(handler).listen(port,host,()=>console.log(`SCHISM shared local city: http://${host}:${port} / persistent SQLite / separate browser sessions`));
