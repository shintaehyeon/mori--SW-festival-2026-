import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createApp } from "../src/app.js";
import { assertNumbersPreserved } from "../src/validation.js";

async function fixture(t, options = {}) {
  const app = createApp(options);
  await new Promise((r) => app.server.listen(0, "127.0.0.1", r));
  const base = `http://127.0.0.1:${app.server.address().port}`;
  t.after(() => app.close());
  const request = async (path, method = "GET", data, token, headers = {}) => {
    const res = await fetch(base + path, {
      method,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...headers,
      },
      body: data === undefined ? undefined : JSON.stringify(data),
    });
    return {
      status: res.status,
      data: res.status === 204 ? null : await res.json(),
      headers: res.headers,
    };
  };
  const register = async (name) => {
    const r = await request(
      "/api/auth/register",
      "POST",
      {
        email: `${name}@example.com`,
        password: "test-password-123",
        nickname: name,
      },
      null,
      { "X-Client-Platform": "native" },
    );
    assert.equal(r.status, 201);
    return r.data;
  };
  return { app, request, register };
}
const profile = {
  allergies: { status: "known", detail: "Penicillin" },
  medications: { status: "unknown", detail: "" },
};
const journal = {
  date: "2026-10-27",
  condition: "low",
  sleep: 6,
  note: "Slept 6 hours. Throat uncomfortable.",
};
const post = {
  title: "My clinic visit",
  body: "This is a clearly fictional test experience for automated verification.",
  place: "Test clinic",
  visitDate: "2026-10-25",
  language: "English",
  method: "translation",
  consent: true,
};

test("authentication: cookies are HttpOnly, passwords are hashed, revoked sessions fail", async (t) => {
  const { app, request, register } = await fixture(t);
  const a = await register("Alice");
  assert.equal((await request("/api/auth/me")).status, 401);
  assert.notEqual(
    app.db.prepare("SELECT password FROM users").get().password,
    "test-password-123",
  );
  assert.equal(
    (
      await request("/api/auth/login", "POST", {
        email: "Alice@example.com",
        password: "wrong",
      })
    ).status,
    401,
  );
  const login = await request("/api/auth/login", "POST", {
    email: "alice@example.com",
    password: "test-password-123",
  });
  assert.match(login.headers.get("set-cookie"), /HttpOnly/);
  assert.equal(login.data.token, undefined);
  assert.equal(
    (await request("/api/auth/me", "GET", undefined, a.token)).data.user
      .nickname,
    "Alice",
  );
  await request("/api/auth/logout", "POST", {}, a.token);
  assert.equal(
    (await request("/api/auth/me", "GET", undefined, a.token)).status,
    401,
  );
});

test("health records: ownership, selection, frozen snapshot, persistence and deletion", async (t) => {
  const { request, register } = await fixture(t);
  const a = await register("Alice"),
    b = await register("Bobby");
  assert.equal(
    (await request("/api/profile", "PUT", profile, a.token)).status,
    200,
  );
  const saved = (await request("/api/journals", "POST", journal, a.token)).data;
  assert.deepEqual(
    (await request("/api/journals", "GET", undefined, b.token)).data,
    [],
  );
  assert.equal(
    (await request(`/api/journals/${saved.id}`, "DELETE", undefined, b.token))
      .status,
    404,
  );
  assert.equal(
    (
      await request(
        "/api/cards",
        "POST",
        {
          symptoms: "Sore throat",
          onset: "Yesterday",
          journalIds: [saved.id],
          consent: true,
        },
        b.token,
      )
    ).status,
    404,
  );
  const card = (
    await request(
      "/api/cards",
      "POST",
      {
        symptoms: "Sore throat",
        onset: "Yesterday",
        journalIds: [saved.id],
        consent: true,
      },
      a.token,
    )
  ).data;
  assert.equal(card.snapshot.journals.length, 1);
  assert.equal(card.snapshot.profile.allergies.detail, "Penicillin");
  await request(
    "/api/profile",
    "PUT",
    { ...profile, allergies: { status: "none", detail: "" } },
    a.token,
  );
  assert.equal(
    (await request(`/api/cards/${card.id}`, "GET", undefined, a.token)).data
      .snapshot.profile.allergies.detail,
    "Penicillin",
  );
  assert.equal(
    (await request(`/api/cards/${card.id}`, "GET", undefined, b.token)).status,
    404,
  );
  assert.equal(
    (
      await request(
        "/api/cards",
        "POST",
        { symptoms: "x", onset: "", journalIds: [], consent: false },
        a.token,
      )
    ).status,
    400,
  );
  await request(`/api/journals/${saved.id}`, "DELETE", undefined, a.token);
  assert.deepEqual(
    (await request("/api/journals", "GET", undefined, a.token)).data,
    [],
  );
  await request(`/api/cards/${card.id}`, "DELETE", undefined, a.token);
  assert.equal(
    (await request(`/api/cards/${card.id}`, "GET", undefined, a.token)).status,
    404,
  );
});

test("AI unavailable: original survives and cannot be confirmed as a translation", async (t) => {
  const { request, register } = await fixture(t, {
    translate: async () => {
      const e = new Error("AI is not configured.");
      e.status = 503;
      throw e;
    },
    configured: () => false,
  });
  const a = await register("Alice");
  const card = (
    await request(
      "/api/cards",
      "POST",
      {
        symptoms: "Pain 3 days",
        onset: "3 days ago",
        journalIds: [],
        consent: true,
      },
      a.token,
    )
  ).data;
  assert.equal(
    (await request(`/api/cards/${card.id}/translate`, "POST", {}, a.token))
      .status,
    503,
  );
  const read = (
    await request(`/api/cards/${card.id}`, "GET", undefined, a.token)
  ).data;
  assert.equal(read.mode, "original");
  assert.equal(read.snapshot.symptoms, "Pain 3 days");
  assert.equal(read.translation, null);
  assert.equal(
    (
      await request(
        `/api/cards/${card.id}/confirm`,
        "PUT",
        {
          symptomsKo: "",
          onsetKo: "",
          allergiesKo: "",
          medicationsKo: "",
          journalKo: [],
          reviewed: true,
        },
        a.token,
      )
    ).status,
    409,
  );
});

test("translation draft requires explicit review and preserves original snapshot", async (t) => {
  const draft = {
    symptomsKo: "목 통증",
    onsetKo: "어제",
    allergiesKo: "미확인",
    medicationsKo: "미확인",
    journalKo: [],
  };
  const { request, register } = await fixture(t, {
    translate: async () => draft,
    configured: () => true,
  });
  const a = await register("Alice");
  const card = (
    await request(
      "/api/cards",
      "POST",
      {
        symptoms: "Sore throat",
        onset: "Yesterday",
        journalIds: [],
        consent: true,
      },
      a.token,
    )
  ).data;
  const translated = await request(
    `/api/cards/${card.id}/translate`,
    "POST",
    {},
    a.token,
  );
  assert.equal(translated.status, 200);
  assert.equal(translated.data.confirmedAt, null);
  assert.equal(
    (
      await request(
        `/api/cards/${card.id}/confirm`,
        "PUT",
        { ...draft, reviewed: false },
        a.token,
      )
    ).status,
    400,
  );
  const confirmed = await request(
    `/api/cards/${card.id}/confirm`,
    "PUT",
    { ...draft, symptomsKo: "목이 아픕니다.", reviewed: true },
    a.token,
  );
  assert.ok(confirmed.data.confirmedAt);
  assert.equal(confirmed.data.snapshot.symptoms, "Sore throat");
});

test("community: other users can comment, cannot edit; report and cascade delete", async (t) => {
  const { app, request, register } = await fixture(t);
  const a = await register("Alice"),
    b = await register("Bobby");
  const created = await request("/api/posts", "POST", post, a.token);
  assert.equal(created.status, 201);
  const p = created.data;
  assert.equal(
    (
      await request(
        "/api/posts?q=clinic&language=English",
        "GET",
        undefined,
        b.token,
      )
    ).data.length,
    1,
  );
  assert.equal(
    (await request("/api/posts?q=nomatch", "GET", undefined, b.token)).data
      .length,
    0,
  );
  assert.equal(
    (await request(`/api/posts/${p.id}`, "PUT", post, b.token)).status,
    404,
  );
  assert.equal(
    (await request(`/api/posts/${p.id}`, "DELETE", undefined, b.token)).status,
    404,
  );
  const comment = (
    await request(
      `/api/posts/${p.id}/comments`,
      "POST",
      { body: "Did you book first?" },
      b.token,
    )
  ).data;
  assert.equal(
    (await request(`/api/comments/${comment.id}`, "DELETE", undefined, a.token))
      .status,
    404,
  );
  assert.equal(
    (await request(`/api/posts/${p.id}/comments`, "GET", undefined, a.token))
      .data.length,
    1,
  );
  assert.equal(
    (
      await request(
        `/api/posts/${p.id}/reports`,
        "POST",
        { reason: "privacy", detail: "Please review." },
        b.token,
      )
    ).status,
    201,
  );
  assert.equal(app.db.prepare("SELECT count(*) AS n FROM reports").get().n, 1);
  assert.equal(
    (
      await request(
        `/api/posts/${p.id}`,
        "PUT",
        { ...post, title: "Updated title" },
        a.token,
      )
    ).data.title,
    "Updated title",
  );
  await request(`/api/posts/${p.id}`, "DELETE", undefined, a.token);
  assert.equal(app.db.prepare("SELECT count(*) AS n FROM comments").get().n, 0);
  assert.equal(app.db.prepare("SELECT count(*) AS n FROM reports").get().n, 0);
});

test("disk restart retains health records; account deletion removes private and public data", async (t) => {
  const dir = mkdtempSync(join(tmpdir(), "puchipa-test-"));
  const path = join(dir, "test.sqlite");
  let app = createApp({ dbPath: path });
  await new Promise((r) => app.server.listen(0, "127.0.0.1", r));
  async function request(p, method, data, token) {
    const r = await fetch(`http://127.0.0.1:${app.server.address().port}` + p, {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-Client-Platform": "native",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: data ? JSON.stringify(data) : undefined,
    });
    return { status: r.status, data: await r.json() };
  }
  try {
    const a = (
      await request("/api/auth/register", "POST", {
        email: "restart@example.com",
        password: "test-password-123",
        nickname: "Restart",
      })
    ).data;
    await request("/api/profile", "PUT", profile, a.token);
    await request("/api/journals", "POST", journal, a.token);
    await request("/api/posts", "POST", post, a.token);
    await app.close();
    app = createApp({ dbPath: path });
    await new Promise((r) => app.server.listen(0, "127.0.0.1", r));
    assert.equal(
      (await request("/api/profile", "GET", undefined, a.token)).data.allergies
        .detail,
      "Penicillin",
    );
    assert.equal(
      (await request("/api/journals", "GET", undefined, a.token)).data.length,
      1,
    );
    await request("/api/auth/me", "DELETE", undefined, a.token);
    for (const table of [
      "users",
      "profiles",
      "journals",
      "cards",
      "posts",
      "sessions",
    ])
      assert.equal(
        app.db.prepare(`SELECT count(*) AS n FROM ${table}`).get().n,
        0,
      );
    assert.equal(
      (await request("/api/profile", "GET", undefined, a.token)).status,
      401,
    );
  } finally {
    await app.close();
    rmSync(dir, { recursive: true, force: true });
  }
});

test("input validation: dates, ownership and origin boundaries", async (t) => {
  const { request, register } = await fixture(t);
  const a = await register("Alice");
  assert.equal(
    (
      await request("/api/health", "GET", undefined, undefined, {
        Origin: "https://evil.example",
      })
    ).status,
    403,
  );
  assert.equal(
    (
      await request(
        "/api/profile",
        "PUT",
        { ...profile, allergies: { status: "known", detail: "" } },
        a.token,
      )
    ).status,
    400,
  );
  assert.equal(
    (
      await request(
        "/api/journals",
        "POST",
        { ...journal, date: "2026-02-30" },
        a.token,
      )
    ).status,
    400,
  );
  assert.equal(
    (await request("/api/journals", "POST", { ...journal, sleep: 25 }, a.token))
      .status,
    400,
  );
  assert.equal(
    (await request("/api/posts", "POST", { ...post, consent: false }, a.token))
      .status,
    400,
  );
});

test("20 numeric fidelity fixtures reject omitted or changed numbers", () => {
  for (let i = 1; i <= 20; i++) {
    assert.doesNotThrow(() =>
      assertNumbersPreserved(`Dose ${i} mg for 2 days`, `${i} mg, 2일`),
    );
    assert.throws(() =>
      assertNumbersPreserved(`Dose ${i + 100} mg`, `${i} mg`),
    );
  }
});

test("exported client and API run from one origin; missing assets return 404", async (t) => {
  const { writeFileSync } = await import("node:fs");
  const dir = mkdtempSync(join(tmpdir(), "puchipa-static-"));
  writeFileSync(
    join(dir, "index.html"),
    "<html><title>Puchipa static test</title></html>",
  );
  writeFileSync(join(dir, "app.js"), 'console.log("test");');
  const { app } = await fixture(t, { staticDir: dir });
  const base = `http://127.0.0.1:${app.server.address().port}`;
  const page = await fetch(base + "/");
  assert.equal(page.status, 200);
  assert.match(await page.text(), /Puchipa static test/);
  const asset = await fetch(base + "/app.js");
  assert.equal(asset.status, 200);
  assert.match(asset.headers.get("content-type"), /javascript/);
  assert.equal((await fetch(base + "/missing.js")).status, 404);
  assert.equal((await fetch(base + "/api/health")).status, 200);
  t.after(() => rmSync(dir, { recursive: true, force: true }));
});

test('emergency profile is private and survives health profile updates', async (t) => {
  const {request, register} = await fixture(t);
  const a = await register('EmergencyA'), b = await register('EmergencyB');
  const data = {name:'Test Person', nationality:'France', organization:'Test school', address:'Test address', location:'Library', activity:'Studying', symptoms:'Headache', message:'Please call me', updatedAt:new Date().toISOString(), contacts:[{name:'Family',phone:'+33 612345678'}]};
  assert.equal((await request('/api/emergency-profile','PUT',data)).status,401);
  assert.equal((await request('/api/emergency-profile','PUT',data,a.token)).status,200);
  await request('/api/profile','PUT',profile,a.token);
  assert.deepEqual((await request('/api/emergency-profile','GET',undefined,a.token)).data,data);
  assert.deepEqual((await request('/api/emergency-profile','GET',undefined,b.token)).data,{});
  assert.equal((await request('/api/emergency-profile','PUT',{...data,contacts:[{name:'Bad',phone:'tel:119?x=y'}]},a.token)).status,400);
});

test('avatar customization persists privately alongside emergency and health data', async(t)=>{
 const {request,register}=await fixture(t);const a=await register('MoriA'),b=await register('MoriB');
 const avatar={name:'Little Me',style:'bunny',color:'lavender'};
 assert.equal((await request('/api/avatar','PUT',avatar,a.token)).status,200);
 await request('/api/profile','PUT',profile,a.token);
 assert.deepEqual((await request('/api/avatar','GET',undefined,a.token)).data,avatar);
 assert.equal((await request('/api/avatar','GET',undefined,b.token)).data.name,'Mori');
 assert.equal((await request('/api/avatar','PUT',{...avatar,style:'invalid'},a.token)).status,400);
 assert.equal((await request('/api/avatar')).status,401);
});

test('official hospital dataset searches real institutions without requiring login',async(t)=>{
 const {request}=await fixture(t);
 const all=await request('/api/hospitals');assert.equal(all.status,200);assert.equal(all.data.total,669);assert.equal(all.data.hospitals.length,100);
 const found=await request('/api/hospitals?q='+encodeURIComponent('내과'));
 assert.ok(found.data.total>0);assert.ok(found.data.hospitals.every(h=>h.departments.some(d=>d.name.includes('내과'))||JSON.stringify([h.name,h.type,h.address]).includes('내과')));
 assert.equal(all.data.snapshot,'2026-09-30');assert.ok(all.data.hospitals.every(h=>h.languageSupport==='unverified'));
});

test('presence counts opted-in unique accounts, expires, and excludes revoked sessions',async(t)=>{
 let time=100000;const {request,register}=await fixture(t,{presenceClock:()=>time});
 const a=await register('OnlineA'),b=await register('OnlineB');
 const beat=(token,clientId='test-client-1')=>request('/api/presence','POST',{clientId},token);
 assert.equal((await beat(a.token)).data.count,0);
 await request('/api/presence/settings','PUT',{handong:true},a.token);
 assert.equal((await beat(a.token)).data.count,1);
 assert.equal((await beat(a.token,'test-client-2')).data.count,1);
 await request('/api/presence/settings','PUT',{handong:true},b.token);
 assert.equal((await beat(b.token)).data.count,2);
 let status=(await request('/api/presence','GET',undefined,a.token)).data;
 assert.equal(status.includesMe,true);assert.equal(status.affiliationVerification,'self-declared');assert.equal(status.members,undefined);
 await request('/api/presence/settings','PUT',{handong:false},b.token);
 assert.equal((await beat(a.token)).data.count,1);
 time+=90001;assert.equal((await request('/api/presence','GET',undefined,a.token)).data.count,0);
 await beat(a.token);await request('/api/auth/logout','POST',{},a.token);
 assert.equal((await request('/api/presence','GET',undefined,b.token)).data.count,0);
 assert.equal((await beat(undefined)).status,401);
});

test('presence groups by organization type/name and registered area without exposing other groups',async(t)=>{
 const {request,register}=await fixture(t);const a=await register('SchoolA'),b=await register('SchoolB'),c=await register('WorkC');
 const setup=(token,value)=>request('/api/presence/settings','PUT',value,token);
 const beat=token=>request('/api/presence','POST',{clientId:'group-client'},token);
 await setup(a.token,{enabled:true,organizationType:'school',organization:'테스트 대학교',region:'포항시 북구'});
 await setup(b.token,{enabled:true,organizationType:'school',organization:'테스트대학교',region:'서울시'});
 await setup(c.token,{enabled:true,organizationType:'work',organization:'테스트대학교',region:'포항시북구'});
 await beat(b.token);await beat(c.token);const r=(await beat(a.token)).data;
 assert.equal(r.count,3);assert.equal(r.organizationCount,2);assert.equal(r.regionCount,2);assert.equal(r.organization,'테스트 대학교');assert.equal(r.members,undefined);
 await setup(b.token,{enabled:true,organizationType:'school',organization:'다른대학교',region:'서울시'});
 assert.equal((await beat(a.token)).data.organizationCount,1);
 assert.equal((await setup(a.token,{enabled:true,organizationType:'school',organization:'',region:''})).status,400);
});

test('daily intake selections persist in records and card snapshots without unsupported values',async(t)=>{
 const {request,register}=await fixture(t);const a=await register('IntakeUser');
 const note='섭취 기록 / Intake: 비타민 C / Vitamin C 500mg';
 const saved=await request('/api/journals','POST',{...journal,note,intakes:['vitamin_c','alcohol']},a.token);
 assert.equal(saved.status,201);assert.deepEqual(saved.data.intakes,['vitamin_c','alcohol']);
 const card=await request('/api/cards','POST',{symptoms:'Test symptoms',onset:'Today',journalIds:[saved.data.id],consent:true},a.token);
 assert.deepEqual(card.data.snapshot.journals[0].intakes,['vitamin_c','alcohol']);assert.equal(card.data.snapshot.journals[0].note,note);
 assert.equal((await request('/api/journals','POST',{...journal,intakes:['unapproved']},a.token)).status,400);
 assert.equal((await request('/api/journals','POST',{...journal,intakes:['alcohol','alcohol']},a.token)).status,400);
});

test('friends require accepted invitations; public discovery never exposes health records; privacy hides shared status',async(t)=>{
 const {request,register}=await fixture(t);const a=await register('FriendAlice'),b=await register('FriendBobby'),c=await register('StrangerC');
 const settings={visibility:'public',shareStatus:true,condition:'low',note:'오늘 힘들어요'};
 assert.equal((await request('/api/social/settings','GET',undefined,a.token)).data.visibility,'private');
 await request('/api/social/settings','PUT',settings,a.token);
 await request('/api/presence','POST',{clientId:'friend-client'},a.token);
 let list=(await request('/api/social/online','GET',undefined,b.token)).data;
 assert.equal(list.length,1);assert.equal(list[0].status,null);assert.equal(list[0].online,true);assert.equal(list[0].email,undefined);
 assert.equal((await request('/api/social/messages','POST',{recipient:a.user.id,body:'힘내!'},b.token)).status,403);
 await request('/api/social/requests','POST',{recipient:a.user.id},b.token);
 const pending=(await request('/api/social/requests','GET',undefined,a.token)).data;
 assert.equal(pending.length,1);
 assert.equal((await request('/api/social/accept','POST',{requestId:pending[0].id},c.token)).status,400);
 await request('/api/social/accept','POST',{requestId:pending[0].id},a.token);
 list=(await request('/api/social/friends','GET',undefined,b.token)).data;
 assert.equal(list[0].status.condition,'low');assert.equal(list[0].status.note,'오늘 힘들어요');
 await request('/api/social/settings','PUT',{...settings,visibility:'private'},a.token);
 list=(await request('/api/social/friends','GET',undefined,b.token)).data;assert.equal(list[0].online,null);assert.equal(list[0].status,null);
 assert.equal((await request('/api/social/online','GET',undefined,b.token)).data.length,0);
});

test('friend codes are one-use and revocable; cheers enforce 20 graphemes; blocking cuts access',async(t)=>{
 const {request,register}=await fixture(t);const a=await register('CodeAlice'),b=await register('CodeBobby'),c=await register('CodeOther');
 const invite=(await request('/api/social/invites','POST',{},a.token)).data;
 assert.equal((await request('/api/social/accept','POST',{code:invite.code},a.token)).status,400);
 assert.equal((await request('/api/social/accept','POST',{code:invite.code},b.token)).status,200);
 assert.equal((await request('/api/social/accept','POST',{code:invite.code},c.token)).status,400);
 let sent=await request('/api/social/messages','POST',{recipient:b.user.id,body:'가'.repeat(20)},a.token);assert.equal(sent.status,201);
 assert.equal((await request('/api/social/messages','POST',{recipient:b.user.id,body:'가'.repeat(21)},a.token)).status,400);
 assert.equal((await request('/api/social/messages','POST',{recipient:b.user.id,body:'👨‍👩‍👧‍👦'.repeat(20)},a.token)).status,201);
 assert.equal((await request('/api/social/messages','POST',{recipient:b.user.id,body:'\n'},a.token)).status,400);
 assert.equal((await request('/api/social/messages','GET',undefined,b.token)).data.length,2);
 assert.equal((await request('/api/social/messages','GET',undefined,c.token)).data.length,0);
 await request(`/api/social/friends/${a.user.id}/block`,'DELETE',{},b.token);
 assert.equal((await request('/api/social/friends','GET',undefined,a.token)).data.length,0);
 assert.equal((await request('/api/social/messages','GET',undefined,a.token)).data.length,0);
 assert.equal((await request('/api/social/messages','POST',{recipient:b.user.id,body:'안녕'},a.token)).status,403);
 const next=(await request('/api/social/invites','POST',{},a.token)).data;
 assert.equal((await request('/api/social/accept','POST',{code:next.code},b.token)).status,400);
 await request('/api/social/invites','DELETE',{},a.token);
 assert.equal((await request('/api/social/accept','POST',{code:next.code},c.token)).status,400);
});

test('structured visit measurements validate ranges and preserve original snapshot',async(t)=>{
 const {request,register}=await fixture(t);const a=await register('VisitChart');
 const payload={symptoms:'Test symptom',onset:'Today',journalIds:[],consent:true,intake:{patientName:'Test only',bodySite:'Throat',painScore:0,temperatureC:37.2,measuredAt:'09:00 KST'}};
 const c=await request('/api/cards','POST',payload,a.token);assert.equal(c.status,201);assert.equal(c.data.snapshot.intake.painScore,0);assert.equal(c.data.snapshot.intake.temperatureC,37.2);
 assert.equal((await request('/api/cards','POST',{...payload,intake:{...payload.intake,painScore:11}},a.token)).status,400);
 assert.equal((await request('/api/cards','POST',{...payload,intake:{...payload.intake,temperatureC:90}},a.token)).status,400);
});
