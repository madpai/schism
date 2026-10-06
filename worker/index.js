import { snapshot, act } from './game.js';
import { page, assets } from './page.js';
import {operatorContext,requestBudget,exportCity} from './community.js';
const headers={ 'Cache-Control':'no-store', 'X-Content-Type-Options':'nosniff' };
export default {
  async fetch(request,env){
    const url=new URL(request.url);
    if(url.pathname==='/')return new Response(page,{headers:{...headers,'Content-Type':'text/html;charset=utf-8','Referrer-Policy':'same-origin'}});
    if(url.pathname.startsWith('/art/')){
      const a=assets[url.pathname];if(!a)return new Response('Not found',{status:404});
      const bytes=Uint8Array.from(atob(a),c=>c.charCodeAt(0));return new Response(bytes,{headers:{'Content-Type':'image/webp','Cache-Control':'public,max-age=86400'}});
    }
    if(['/api/state','/api/action','/api/health','/api/backup'].includes(url.pathname)){
      const owner=request.headers.get('oai-authenticated-user-id');
      if(!owner)return Response.json({error:'Sign in to keep your citizen and progress.',signin:'/signin-with-chatgpt?return_to=%2F'},{status:401,headers});
      if(!env.DB)return Response.json({error:'The city registry is unavailable. Please try again shortly.'},{status:503,headers});
      const context=operatorContext(request,env),requestId=crypto.randomUUID();
      try{
        if(['/api/health','/api/backup'].includes(url.pathname)){
          if(!context.operator)return Response.json({error:'Operator access required.'},{status:403,headers});
          if(request.method!=='GET')return Response.json({error:'Method not allowed.'},{status:405,headers});
          await requestBudget(env.DB,owner,'operator');
          if(url.pathname==='/api/backup')return Response.json(await exportCity(env.DB),{headers:{...headers,'Content-Disposition':'attachment; filename="schism-city-backup.json"'}});
          const health=await env.DB.prepare("SELECT count(*) citizens FROM citizens").first();return Response.json({ok:true,version:'0.9.0',time:new Date().toISOString(),citizens:health.citizens,requestId},{headers});
        }
        if(url.pathname==='/api/state'&&request.method==='GET'){await requestBudget(env.DB,owner,'state');return Response.json(await snapshot(env.DB,owner,Date.now(),context),{headers});}
        if(url.pathname==='/api/action'&&request.method==='POST'){
          const origin=request.headers.get('Origin');if(origin&&origin!==url.origin)return Response.json({error:'Request origin does not match the city.'},{status:403,headers});
          if(!request.headers.get('Content-Type')?.startsWith('application/json'))return Response.json({error:'Expected a JSON action.'},{status:415,headers});
          const raw=await request.text();if(raw.length>2000)return Response.json({error:'That notice is too long.'},{status:413,headers});
          let input;try{input=JSON.parse(raw);}catch{return Response.json({error:'Invalid action.'},{status:400,headers});}
          await requestBudget(env.DB,owner,'action');return Response.json(await act(env.DB,owner,input,Date.now(),context),{headers});
        }
        return Response.json({error:'Method not allowed.'},{status:405,headers});
      }catch(error){if(!error.status||error.status>=500)console.error(JSON.stringify({event:'city_request_failed',requestId,path:url.pathname,status:error.status||503,errorType:error.name||'Error'}));return Response.json({error:error.status?error.message:'The city registry could not complete that request. Retry before taking another action.',requestId},{status:error.status||503,headers:{...headers,...(error.status===429?{'Retry-After':'60'}:{})}});}
    }
    return new Response('Not found',{status:404});
  }
};
