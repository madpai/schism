import { snapshot, act } from './game.js';
import { resetCharacters } from './reset.js';
import { page, assets } from './page.js';
const headers={ 'Cache-Control':'no-store', 'X-Content-Type-Options':'nosniff' };
export default {
  async fetch(request,env){
    const url=new URL(request.url);
    // Temporary one-time operation. Sites' confirmed owner-private access boundary
    // authenticates browser and service callers. Remove this route after execution.
    if(url.pathname==='/api/maintenance/character-reset'){
      if(request.method!=='POST')return Response.json({error:'Method not allowed.'},{status:405,headers});
      const origin=request.headers.get('Origin');if(origin&&origin!==url.origin)return Response.json({error:'Request origin does not match the city.'},{status:403,headers});
      if(!env.DB)return Response.json({error:'City registry unavailable.'},{status:503,headers});
      try{return Response.json(await resetCharacters(env.DB),{headers});}
      catch(error){console.error('Character reset:',error);return Response.json({error:'Character reset could not complete.'},{status:503,headers});}
    }
    if(url.pathname==='/')return new Response(page,{headers:{'Content-Type':'text/html;charset=utf-8','X-Content-Type-Options':'nosniff'}});
    if(url.pathname.startsWith('/art/')){
      const a=assets[url.pathname];if(!a)return new Response('Not found',{status:404});
      const bytes=Uint8Array.from(atob(a),c=>c.charCodeAt(0));return new Response(bytes,{headers:{'Content-Type':'image/webp','Cache-Control':'public,max-age=86400'}});
    }
    if(url.pathname==='/api/state'||url.pathname==='/api/action'){
      const owner=request.headers.get('oai-authenticated-user-id');
      if(!owner)return Response.json({error:'Sign in to keep your citizen and progress.',signin:'/signin-with-chatgpt?return_to=%2F'},{status:401,headers});
      if(!env.DB)return Response.json({error:'The city registry is unavailable. Please try again shortly.'},{status:503,headers});
      try{
        if(url.pathname==='/api/state'&&request.method==='GET')return Response.json(await snapshot(env.DB,owner),{headers});
        if(url.pathname==='/api/action'&&request.method==='POST'){
          const origin=request.headers.get('Origin');if(origin&&origin!==url.origin)return Response.json({error:'Request origin does not match the city.'},{status:403,headers});
          if(!request.headers.get('Content-Type')?.startsWith('application/json'))return Response.json({error:'Expected a JSON action.'},{status:415,headers});
          const raw=await request.text();if(raw.length>2000)return Response.json({error:'That notice is too long.'},{status:413,headers});
          let input;try{input=JSON.parse(raw);}catch{return Response.json({error:'Invalid action.'},{status:400,headers});}
          return Response.json(await act(env.DB,owner,input),{headers});
        }
        return Response.json({error:'Method not allowed.'},{status:405,headers});
      }catch(error){console.error('City registry:',error);return Response.json({error:error.status?error.message:'The city registry could not complete that request. Your last save is safe.'},{status:error.status||503,headers});}
    }
    return new Response('Not found',{status:404});
  }
};
