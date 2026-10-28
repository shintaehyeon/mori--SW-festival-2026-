import { randomBytes, randomUUID, createHash } from 'node:crypto';
import { z } from 'zod';
import { parse } from './validation.js';
const hash = code => createHash('sha256').update(code).digest('hex');
const graphemes = new Intl.Segmenter(undefined,{granularity:'grapheme'});
export const shortMessage = z.string().trim().min(1).max(400).refine(s=>[...graphemes.segment(s)].length<=20,'Messages must be 20 characters or fewer.').refine(s=>!/[\r\n\u0000-\u001f\u007f]/.test(s),'Use one short line.');
const settingsSchema=z.object({visibility:z.enum(['public','private']),shareStatus:z.boolean(),condition:z.enum(['unknown','good','okay','low']),note:z.string().trim().max(80)});
const inviteSchema=z.union([z.object({code:z.string().regex(/^[a-f0-9]{32}$/)}),z.object({requestId:z.string().uuid()})]);
const defaultSocial={visibility:'private',shareStatus:false,condition:'unknown',note:'',updatedAt:null};
export async function socialRoutes({p,method,u,db,send,body,fail,rate,online}) {
 const pair=id=>[u.id,id].sort();
 const blocked=id=>Boolean(db.prepare('SELECT 1 FROM friend_blocks WHERE (owner=? AND target=?) OR (owner=? AND target=?)').get(u.id,id,id,u.id));
 const friends=id=>Boolean(db.prepare('SELECT 1 FROM friendships WHERE a=? AND b=?').get(...pair(id)))&&!blocked(id);
 const profile=id=>{const r=db.prepare('SELECT * FROM social_profiles WHERE user_id=?').get(id);return r?{visibility:r.visibility,shareStatus:!!r.share_status,condition:r.condition,note:r.note,updatedAt:r.updated_at}:{...defaultSocial};};
 const publicPerson=(id,isFriend=false)=>{
  const user=db.prepare('SELECT nickname FROM users WHERE id=?').get(id);
  const row=db.prepare('SELECT data FROM profiles WHERE user_id=?').get(id);
  const avatar=row?JSON.parse(row.data).avatar:null;
  const s=profile(id),visible=s.visibility==='public';
  return {id,nickname:avatar?.name||user.nickname,avatar:avatar?{style:avatar.style,color:avatar.color}:null,visibility:s.visibility,online:visible?online(id):null,
   status:visible&&isFriend&&s.shareStatus?{condition:s.condition,note:s.note,updatedAt:s.updatedAt}:null};
 };
 if(p==='/api/social/settings') {
  if(method==='GET') return send(200,profile(u.id));
  if(method==='PUT') {const v=parse(settingsSchema,await body());db.prepare('INSERT INTO social_profiles VALUES(?,?,?,?,?,?) ON CONFLICT(user_id) DO UPDATE SET visibility=excluded.visibility,share_status=excluded.share_status,condition=excluded.condition,note=excluded.note,updated_at=excluded.updated_at').run(u.id,v.visibility,+v.shareStatus,v.condition,v.note,new Date().toISOString());return send(200,profile(u.id));}
 }
 if(p==='/api/social/invites'&&method==='POST') {
  rate(`invite:${u.id}`,10,3600000);
  db.prepare('DELETE FROM friend_invites WHERE user_id=? OR expires_at<?').run(u.id,Date.now());
  const code=randomBytes(16).toString('hex'),expiresAt=Date.now()+7*86400000;
  db.prepare('INSERT INTO friend_invites VALUES(?,?,?)').run(hash(code),u.id,expiresAt);
  return send(201,{code,expiresAt:new Date(expiresAt).toISOString()});
 }
 if(p==='/api/social/invites'&&method==='DELETE'){db.prepare('DELETE FROM friend_invites WHERE user_id=?').run(u.id);return send(200,{ok:true});}
 if(p==='/api/social/accept'&&method==='POST') {
  rate(`accept:${u.id}`,30,3600000);
  const input=parse(inviteSchema,await body());
  let inviter;
  if(input.requestId) {
    const request=db.prepare('SELECT * FROM friend_requests WHERE id=? AND recipient=?').get(input.requestId,u.id);
    if(!request || blocked(request.sender)) fail(400,'Invitation unavailable.');
    inviter=request.sender;
  } else {
    const invite=db.prepare('SELECT * FROM friend_invites WHERE code_hash=? AND expires_at>?').get(hash(input.code),Date.now());
    if(!invite || invite.user_id===u.id || blocked(invite.user_id)) fail(400,'Invitation is unavailable or expired.');
    inviter=invite.user_id;
  }
  const [a,b]=pair(inviter);
  db.prepare('INSERT OR IGNORE INTO friendships VALUES(?,?,?)').run(a,b,new Date().toISOString());
  if(input.code) db.prepare('DELETE FROM friend_invites WHERE code_hash=?').run(hash(input.code));
  db.prepare('DELETE FROM friend_requests WHERE (sender=? AND recipient=?) OR (sender=? AND recipient=?)').run(u.id,inviter,inviter,u.id);
  return send(200,{friend:publicPerson(inviter,true)});
 }
 if(p==='/api/social/requests' && method==='GET') {
  return send(200,db.prepare('SELECT * FROM friend_requests WHERE recipient=?').all(u.id).filter(r=>!blocked(r.sender)).map(r=>({id:r.id,from:publicPerson(r.sender),createdAt:r.created_at})));
 }
 if(p==='/api/social/requests' && method==='POST') {
  const v=parse(z.object({recipient:z.string().uuid()}),await body());
  if(v.recipient===u.id || blocked(v.recipient) || profile(v.recipient).visibility!=='public') fail(400,'This person is unavailable.');
  if(friends(v.recipient)) fail(400,'Already friends.');
  rate(`request:${u.id}`,20,3600000);
  db.prepare('INSERT OR IGNORE INTO friend_requests VALUES(?,?,?,?)').run(randomUUID(),u.id,v.recipient,new Date().toISOString());
  return send(201,{ok:true});
 }
 const rejection=p.match(/^\/api\/social\/requests\/([0-9a-f-]{36})$/);
 if(rejection&&method==='DELETE'){db.prepare('DELETE FROM friend_requests WHERE id=? AND recipient=?').run(rejection[1],u.id);return send(200,{ok:true});}
 if(p==='/api/social/friends'&&method==='GET') {
  const ids=db.prepare('SELECT a,b FROM friendships WHERE a=? OR b=?').all(u.id,u.id).map(r=>r.a===u.id?r.b:r.a);
  return send(200,ids.filter(id=>!blocked(id)).map(id=>publicPerson(id,true)));
 }
 if(p==='/api/social/online'&&method==='GET') {
  return send(200,db.prepare("SELECT user_id FROM social_profiles WHERE visibility='public' AND user_id<>?").all(u.id).filter(r=>!blocked(r.user_id)&&online(r.user_id)).slice(0,50).map(r=>publicPerson(r.user_id,false)));
 }
 const target=p.match(/^\/api\/social\/friends\/([0-9a-f-]{36})(\/block)?$/);
 if(target&&method==='DELETE') {
  if(target[1]===u.id) fail(400,'Invalid friend.');
  if(!db.prepare('SELECT 1 FROM users WHERE id=?').get(target[1])) fail(404,'Person unavailable.');
  db.prepare('DELETE FROM friend_requests WHERE (sender=? AND recipient=?) OR (sender=? AND recipient=?)').run(u.id,target[1],target[1],u.id);
  if(target[2]) db.prepare('INSERT OR IGNORE INTO friend_blocks VALUES(?,?)').run(u.id,target[1]);
  db.prepare('DELETE FROM friendships WHERE a=? AND b=?').run(...pair(target[1]));
  db.prepare('DELETE FROM friend_messages WHERE (sender=? AND recipient=?) OR (sender=? AND recipient=?)').run(u.id,target[1],target[1],u.id);
  return send(200,{ok:true});
 }
 if(p==='/api/social/messages'&&method==='GET') {
  const rows=db.prepare('SELECT * FROM friend_messages WHERE sender=? OR recipient=? ORDER BY created_at DESC,id DESC LIMIT 50').all(u.id,u.id);
  return send(200,rows.filter(r=>friends(r.sender===u.id?r.recipient:r.sender)).map(r=>({id:r.id,sender:r.sender,recipient:r.recipient,body:r.body,createdAt:r.created_at,fromMe:r.sender===u.id,peer:publicPerson(r.sender===u.id?r.recipient:r.sender,true).nickname})));
 }
 if(p==='/api/social/messages'&&method==='POST') {
  const v=parse(z.object({recipient:z.string().uuid(),body:shortMessage}),await body());
  if(!friends(v.recipient)) fail(403,'Accept an invitation before sending a message.');
  rate(`message:${u.id}`,30,3600000);
  const id=randomUUID(),createdAt=new Date().toISOString();
  db.prepare('INSERT INTO friend_messages VALUES(?,?,?,?,?)').run(id,u.id,v.recipient,v.body,createdAt);
  return send(201,{id,body:v.body,createdAt});
 }
 fail(404,'Not found.');
}
