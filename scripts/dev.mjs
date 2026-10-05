// Local gameplay QA only. Production identity is supplied exclusively by Sites.
import { createServer } from 'node:http';
import worker from '../dist/server/index.js';
import { localDB } from './local-db.mjs';
const db=localDB();
createServer(async(req,res)=>{
  try{
    const body=[];for await(const chunk of req)body.push(chunk);
    const headers=new Headers(req.headers);headers.set('oai-authenticated-user-id','local-qa-citizen');
    const request=new Request('http://127.0.0.1:4173'+req.url,{method:req.method,headers,...(req.method==='POST'?{body:Buffer.concat(body)}:{})});
    const response=await worker.fetch(request,{DB:db});res.writeHead(response.status,Object.fromEntries(response.headers));res.end(Buffer.from(await response.arrayBuffer()));
  }catch(err){console.error(err);res.writeHead(500);res.end('Local QA server error');}
}).listen(4173,'127.0.0.1',()=>console.log('Local gameplay QA: http://127.0.0.1:4173'));
