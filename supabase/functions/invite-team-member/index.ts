import {createClient} from 'npm:@supabase/supabase-js@2.81.1';
const origin='https://marchese-crm.lovely-haven-7526.chatgpt.site';
const allowedOrigins=[origin,'https://astarkmarkus.github.io','http://terminal.local:4173'];
const roles=['appointment_setter','sales','talent_broker','admin'];
Deno.serve(async req=>{
 const requestOrigin=req.headers.get('Origin')??'';
 const headers={'Content-Type':'application/json','Access-Control-Allow-Origin':allowedOrigins.includes(requestOrigin)?requestOrigin:origin,'Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Vary':'Origin'};
 const reply=(status:number,body:unknown)=>new Response(JSON.stringify(body),{status,headers});
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
 if(req.method!=='POST')return reply(405,{code:'method_not_allowed'});
 if(requestOrigin&&!allowedOrigins.includes(requestOrigin))return reply(403,{code:'forbidden'});
 const token=(req.headers.get('Authorization')??'').replace(/^Bearer\s+/i,'');
 if(!token)return reply(401,{code:'unauthorized'});
 const service=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
 const {data:auth,error:authError}=await service.auth.getUser(token);
 if(authError||!auth.user)return reply(401,{code:'unauthorized'});
 let body;try{body=await req.json()}catch{return reply(400,{code:'invalid_input'})}
 if(!body||typeof body!=='object'||Array.isArray(body))return reply(400,{code:'invalid_input'});
 if(body.action==='accept'){const done=await service.from('team_invitations').update({status:'accepted'}).eq('user_id',auth.user.id).eq('status','sent');return done.error?reply(500,{code:'service_error'}):reply(200,{status:'accepted'})}
 const {data:caller,error:profileError}=await service.from('profiles').select('role,active').eq('user_id',auth.user.id).single();
 if(profileError||!caller?.active||caller.role!=='admin')return reply(403,{code:'admin_required'});
 const email=String(body.email??'').trim().toLowerCase();
 const name=String(body.display_name??'').trim();const role=String(body.role??'appointment_setter');
 if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||email.length>254||!name||name.length>120||!roles.includes(role))return reply(400,{code:'invalid_input'});
 const {count,error:rateError}=await service.from('audit_log').select('id',{count:'exact',head:true}).eq('actor_id',auth.user.id).eq('entity','team_invitations').gte('created_at',new Date(Date.now()-3600000).toISOString());
 if(rateError)return reply(500,{code:'service_error'});
 if((count??0)>=40)return reply(429,{code:'rate_limit'});
 const {data:prior,error:priorError}=await service.from('team_invitations').select('*').eq('email',email).maybeSingle();
 if(priorError)return reply(500,{code:'service_error'});
 if(prior?.status==='accepted')return reply(409,{code:'already_member'});
 if(prior&&Date.now()-new Date(prior.last_attempt_at).getTime()<60000)return reply(429,{code:'rate_limit'});
 if(prior?.user_id){
  const {data:existing}=await service.auth.admin.getUserById(prior.user_id);
  if(existing?.user?.last_sign_in_at)return reply(409,{code:'already_member'});
 }
 const now=new Date().toISOString();
 const payload={email,display_name:name,role,invited_by:auth.user.id,status:'sending',last_attempt_at:now,delivery_error:null};
 const claim=prior?await service.from('team_invitations').update(payload).eq('id',prior.id).eq('last_attempt_at',prior.last_attempt_at).select('id').maybeSingle():await service.from('team_invitations').insert(payload).select('id').single();
 if(claim.error||!claim.data)return reply(409,{code:'invitation_busy'});
 const id=claim.data.id;
 // Never accept redirect targets from the client. The configured URL is the public CRM.
 const {data,error}=await service.auth.admin.inviteUserByEmail(email,{redirectTo:origin+'/?invite=1'});
 if(error||!data.user){
  const code=error?.code==='email_address_not_authorized'?'smtp_required':error?.status===429?'rate_limit':error?.code==='email_exists'||error?.code==='user_already_exists'?'already_member':'email_delivery_failed';
  await service.from('team_invitations').update({status:'failed',delivery_error:code}).eq('id',id);
  return reply(code==='rate_limit'?429:code==='already_member'?409:422,{code});
 }
 // Preserve any existing profile: invitation retries must never silently elevate an existing member.
 const {data:existingProfile,error:checkError}=await service.from('profiles').select('user_id').eq('user_id',data.user.id).maybeSingle();
 if(checkError){await service.from('team_invitations').update({status:'failed',delivery_error:'profile_error',user_id:data.user.id}).eq('id',id);return reply(500,{code:'profile_error'})}
 if(!existingProfile){const p=await service.from('profiles').insert({user_id:data.user.id,display_name:name,role,active:true});if(p.error){await service.from('team_invitations').update({status:'failed',delivery_error:'profile_error',user_id:data.user.id}).eq('id',id);return reply(500,{code:'profile_error'})}}
 const logged=await service.from('team_invitations').update({status:'sent',user_id:data.user.id,last_sent_at:now,delivery_error:null}).eq('id',id);
 if(logged.error)return reply(500,{code:'service_error'});
 return reply(200,{status:'sent',email});
});
