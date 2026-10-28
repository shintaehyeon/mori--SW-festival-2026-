import { createServer } from "node:http";
import {
  randomUUID,
  randomBytes,
  scrypt as scryptCb,
  timingSafeEqual,
  createHash,
} from "node:crypto";
import { promisify } from "node:util";
import { readFileSync, statSync } from "node:fs";
import { resolve, sep, extname } from "node:path";
import { openDb } from "./db.js";
import * as V from "./validation.js";
import { translateSnapshot, aiConfigured } from "./ai.js";
const hospitalData = JSON.parse(readFileSync(new URL("../resources/hospitals.json", import.meta.url), "utf8"));
const scrypt = promisify(scryptCb);
const now = () => new Date().toISOString();
const hash = (value) => createHash("sha256").update(value).digest("hex");
const defaultProfile = () => ({
  allergies: { status: "unknown", detail: "" },
  medications: { status: "unknown", detail: "" },
});
function fail(status, message) {
  const e = new Error(message);
  e.status = status;
  throw e;
}
async function passwordHash(password, salt = randomBytes(16).toString("hex")) {
  return `${salt}:${(await scrypt(password, salt, 64)).toString("hex")}`;
}
async function verify(password, encoded) {
  const salt = encoded.split(":")[0];
  return timingSafeEqual(
    Buffer.from(encoded),
    Buffer.from(await passwordHash(password, salt)),
  );
}
async function body(req) {
  if (!req.headers["content-type"]?.startsWith("application/json"))
    fail(415, "Use application/json.");
  let size = 0,
    chunks = [];
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 32000) fail(413, "Request too large.");
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    fail(400, "Invalid JSON.");
  }
}
export function createApp({
  dbPath = ":memory:",
  translate = translateSnapshot,
  configured = aiConfigured,
  origins = ["http://localhost:8081", "http://127.0.0.1:8081"],
  exposeErrors = false,
  secureCookies = false,
  staticDir = null,
  presenceClock = Date.now,
} = {}) {
  const db = openDb(dbPath);
  const rates = new Map();
  const presence = new Map();
  function communitySettings(uid) {
    const row = db.prepare("SELECT data FROM profiles WHERE user_id=?").get(uid);
    const settings = row ? JSON.parse(row.data).presence : null;
    if (settings?.enabled !== undefined) return settings;
    return {enabled:settings?.handong === true,organizationType:"school",organization:settings?.handong ? "한동대학교":"",region:""};
  }
  const groupKey = v => (v || "").normalize("NFKC").replace(/\s+/g,"").toLowerCase();
  function rate(key, limit, ms) {
    const t = Date.now();
    let entry = rates.get(key);
    if (!entry || t > entry.until) {
      entry = { count: 0, until: t + ms };
      rates.set(key, entry);
    }
    if (++entry.count > limit)
      fail(429, "Too many requests. Please wait and try again.");
    if (rates.size > 10000)
      for (const [k, v] of rates) if (v.until < t) rates.delete(k);
  }
  function sessionToken(req) {
    if (req.headers.authorization?.startsWith("Bearer "))
      return req.headers.authorization.slice(7);
    return req.headers.cookie
      ?.split(";")
      .map((s) => s.trim())
      .find((s) => s.startsWith("puchipa_session="))
      ?.split("=")[1];
  }
  function user(req) {
    const token = sessionToken(req);
    if (!token) fail(401, "Please sign in.");
    const u = db
      .prepare(
        "SELECT u.id,u.nickname,u.email FROM users u JOIN sessions s ON u.id=s.user_id WHERE s.token_hash=? AND s.expires_at>?",
      )
      .get(hash(token), Date.now());
    if (!u) fail(401, "Your session has expired. Please sign in.");
    return u;
  }
  function mine(table, id, uid) {
    const row = db
      .prepare(`SELECT * FROM ${table} WHERE id=? AND user_id=?`)
      .get(id, uid);
    if (!row) fail(404, "Record not found.");
    return row;
  }
  function entity(row) {
    return { id: row.id, ...JSON.parse(row.data), createdAt: row.created_at };
  }
  function post(row) {
    return {
      ...entity(row),
      author: row.nickname,
      authorId: row.user_id,
      updatedAt: row.updated_at,
      commentCount: db
        .prepare("SELECT count(*) AS n FROM comments WHERE post_id=?")
        .get(row.id).n,
    };
  }
  const server = createServer(async (req, res) => {
    res.setHeader("Cache-Control", "no-store");
    res.setHeader("X-Content-Type-Options", "nosniff");
    res.setHeader("Referrer-Policy", "no-referrer");
    const origin = req.headers.origin;
    function send(status, data) {
      res.writeHead(status, {
        "Content-Type": "application/json; charset=utf-8",
      });
      res.end(JSON.stringify(data));
    }
    try {
      if (origin) {
        if (!origins.includes(origin)) fail(403, "Origin is not allowed.");
        res.setHeader("Access-Control-Allow-Origin", origin);
        res.setHeader("Vary", "Origin");
        res.setHeader("Access-Control-Allow-Credentials", "true");
      }
      if (req.method === "OPTIONS") {
        res.setHeader(
          "Access-Control-Allow-Headers",
          "Content-Type,Authorization",
        );
        res.setHeader(
          "Access-Control-Allow-Methods",
          "GET,POST,PUT,DELETE,OPTIONS",
        );
        res.writeHead(204);
        res.end();
        return;
      }
      const url = new URL(req.url, "http://localhost");
      const p = url.pathname;
      const method = req.method;
      if (
        staticDir &&
        !p.startsWith("/api/") &&
        ["GET", "HEAD"].includes(method)
      ) {
        const root = resolve(staticDir);
        let file = resolve(root, "." + decodeURIComponent(p));
        if (file !== root && !file.startsWith(root + sep))
          fail(403, "Invalid path.");
        try {
          if (!statSync(file).isFile()) file = resolve(root, "index.html");
        } catch {
          if (extname(file)) fail(404, "Asset not found.");
          file = resolve(root, "index.html");
        }
        const mime = {
          ".html": "text/html; charset=utf-8",
          ".js": "text/javascript; charset=utf-8",
          ".css": "text/css; charset=utf-8",
          ".json": "application/json",
          ".ttf": "font/ttf",
          ".png": "image/png",
          ".ico": "image/x-icon",
          ".svg": "image/svg+xml",
        };
        const content = readFileSync(file);
        res.writeHead(200, {
          "Content-Type": mime[extname(file)] || "application/octet-stream",
        });
        res.end(method === "HEAD" ? undefined : content);
        return;
      }
      if (method === "GET" && p === "/api/health")
        return send(200, {
          ok: true,
          aiConfigured: configured(),
          version: "0.1.0",
        });
      if (
        method === "POST" &&
        ["/api/auth/register", "/api/auth/login"].includes(p)
      ) {
        rate(`auth:${req.socket.remoteAddress}`, 20, 15 * 60 * 1000);
        const register = p.endsWith("register");
        const input = V.parse(
          register ? V.registerSchema : V.loginSchema,
          await body(req),
        );
        let u;
        if (register) {
          const id = randomUUID();
          const encoded = await passwordHash(input.password);
          try {
            db.prepare("INSERT INTO users VALUES(?,?,?,?,?)").run(
              id,
              input.email,
              input.nickname,
              encoded,
              now(),
            );
          } catch (e) {
            if (
              e.code?.includes("SQLITE") &&
              String(e.message).includes("UNIQUE")
            )
              fail(409, "This email is already registered.");
            throw e;
          }
          u = { id, email: input.email, nickname: input.nickname };
        } else {
          const found = db
            .prepare("SELECT * FROM users WHERE email=?")
            .get(input.email);
          if (!found || !(await verify(input.password, found.password)))
            fail(401, "Email or password is incorrect.");
          u = { id: found.id, email: found.email, nickname: found.nickname };
        }
        const token = randomBytes(32).toString("hex");
        const expires = Date.now() + 7 * 24 * 60 * 60 * 1000;
        db.prepare("DELETE FROM sessions WHERE expires_at<=?").run(Date.now());
        db.prepare("INSERT INTO sessions VALUES(?,?,?)").run(
          hash(token),
          u.id,
          expires,
        );
        res.setHeader(
          "Set-Cookie",
          `puchipa_session=${token}; HttpOnly; SameSite=Lax; Path=/; Max-Age=604800${secureCookies ? "; Secure" : ""}`,
        );
        // Browser sessions use HttpOnly cookies. Native apps request a bearer token explicitly.
        return send(register ? 201 : 200, {
          user: u,
          ...(req.headers["x-client-platform"] === "native" ? { token } : {}),
        });
      }
      if (method === "POST" && p === "/api/auth/logout") {
        const t = sessionToken(req);
        if (t)
          db.prepare("DELETE FROM sessions WHERE token_hash=?").run(hash(t));
        res.setHeader(
          "Set-Cookie",
          "puchipa_session=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0",
        );
        return send(200, { ok: true });
      }
      if (p === "/api/hospitals" && method === "GET") {
        const q = (new URL(req.url, "http://localhost").searchParams.get("q") || "").slice(0,120).toLowerCase();
        const hospitals = hospitalData.hospitals.filter(h => !q || [h.name,h.type,h.address,...h.departments.map(d=>d.name)].join(" ").toLowerCase().includes(q));
        return send(200, {...hospitalData, hospitals:hospitals.slice(0,100),total:hospitals.length});
      }
      const u = user(req);
      if (p === "/api/presence/settings") {
        const row = db.prepare("SELECT data FROM profiles WHERE user_id=?").get(u.id);
        const current = row ? JSON.parse(row.data) : defaultProfile();
        if (method === "GET") return send(200, communitySettings(u.id));
        if (method === "PUT") {
          const settings = V.parse(V.presenceSettingsSchema, await body(req));
          db.prepare("INSERT INTO profiles VALUES(?,?) ON CONFLICT(user_id) DO UPDATE SET data=excluded.data")
            .run(u.id, JSON.stringify({...current,presence:settings}));
          if (!settings.enabled) for (const [key,value] of presence) if (value.uid === u.id) presence.delete(key);
          return send(200, settings);
        }
      }
      if (p === "/api/presence") {
        const tokenHash = hash(sessionToken(req));
        if (method === "POST" || method === "DELETE") {
          const input = V.parse(V.presenceSchema, await body(req));
          const key = `${tokenHash}:${input.clientId}`;
          if (method === "DELETE") presence.delete(key);
          else {
            const row = db.prepare("SELECT data FROM profiles WHERE user_id=?").get(u.id);
            const optedIn = communitySettings(u.id).enabled;
            if (optedIn) presence.set(key,{uid:u.id,tokenHash,seen:presenceClock()});
            else presence.delete(key);
          }
        }
        const ids = new Set();
        for (const [key,value] of presence) {
          const live = presenceClock() - value.seen < 90000 && db.prepare("SELECT 1 FROM sessions WHERE token_hash=? AND expires_at>?").get(value.tokenHash,Date.now());
          if (!live) presence.delete(key); else ids.add(value.uid);
        }
        const mineSettings = communitySettings(u.id);
        const people = [...ids].map(id => communitySettings(id)).filter(s => s.enabled);
        const organizationCount = mineSettings.organization ? people.filter(s => s.organizationType === mineSettings.organizationType && groupKey(s.organization) === groupKey(mineSettings.organization)).length : null;
        const regionCount = mineSettings.region ? people.filter(s => groupKey(s.region) === groupKey(mineSettings.region)).length : null;
        return send(200,{count:people.length,organization:mineSettings.organization,organizationType:mineSettings.organizationType,region:mineSettings.region,organizationCount,regionCount,windowSeconds:90,includesMe:ids.has(u.id) && mineSettings.enabled,affiliationVerification:"self-declared",checkedAt:now()});
      }

      if (method === "GET" && p === "/api/auth/me")
        return send(200, { user: u });
      if (method === "DELETE" && p === "/api/auth/me") {
        db.prepare("DELETE FROM users WHERE id=?").run(u.id);
        res.setHeader(
          "Set-Cookie",
          "puchipa_session=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0",
        );
        return send(200, { ok: true });
      }
      if (p === "/api/avatar") {
        const row = db.prepare("SELECT data FROM profiles WHERE user_id=?").get(u.id);
        const current = row ? JSON.parse(row.data) : defaultProfile();
        if (method === "GET") return send(200, current.avatar || {name:"Mori", style:"sprout", color:"mint"});
        if (method === "PUT") {
          const avatar = V.parse(V.avatarSchema, await body(req));
          db.prepare("INSERT INTO profiles VALUES(?,?) ON CONFLICT(user_id) DO UPDATE SET data=excluded.data")
            .run(u.id, JSON.stringify({...current, avatar}));
          return send(200, avatar);
        }
      }
      if (p === "/api/emergency-profile") {
        const row = db.prepare("SELECT data FROM profiles WHERE user_id=?").get(u.id);
        const current = row ? JSON.parse(row.data) : defaultProfile();
        if (method === "GET") return send(200, current.emergency || {});
        if (method === "PUT") {
          const emergency = V.parse(V.emergencySchema, await body(req));
          db.prepare("INSERT INTO profiles VALUES(?,?) ON CONFLICT(user_id) DO UPDATE SET data=excluded.data")
            .run(u.id, JSON.stringify({...current, emergency}));
          return send(200, emergency);
        }
      }
      if (p === "/api/profile") {
        if (method === "GET")
          return send(
            200,
            db.prepare("SELECT data FROM profiles WHERE user_id=?").get(u.id)
              ? JSON.parse(
                  db
                    .prepare("SELECT data FROM profiles WHERE user_id=?")
                    .get(u.id).data,
                )
              : defaultProfile(),
          );
        if (method === "PUT") {
          const input = V.parse(V.profileSchema, await body(req));
          db.prepare(
            "INSERT INTO profiles VALUES(?,?) ON CONFLICT(user_id) DO UPDATE SET data=excluded.data",
          ).run(u.id, JSON.stringify({...JSON.parse(db.prepare("SELECT data FROM profiles WHERE user_id=?").get(u.id)?.data || "{}"), ...input}));
          return send(200, input);
        }
      }
      if (p === "/api/journals") {
        if (method === "GET")
          return send(
            200,
            db
              .prepare(
                "SELECT * FROM journals WHERE user_id=? ORDER BY created_at DESC",
              )
              .all(u.id)
              .map(entity),
          );
        if (method === "POST") {
          const input = V.parse(V.journalSchema, await body(req));
          const id = randomUUID(),
            t = now();
          db.prepare("INSERT INTO journals VALUES(?,?,?,?)").run(
            id,
            u.id,
            JSON.stringify(input),
            t,
          );
          return send(201, { id, ...input, createdAt: t });
        }
      }
      let match = p.match(/^\/api\/journals\/([a-z0-9-]+)$/);
      if (match) {
        mine("journals", match[1], u.id);
        if (method === "DELETE") {
          db.prepare("DELETE FROM journals WHERE id=? AND user_id=?").run(
            match[1],
            u.id,
          );
          return send(200, { ok: true });
        }
      }
      if (p === "/api/cards") {
        if (method === "GET")
          return send(
            200,
            db
              .prepare(
                "SELECT * FROM cards WHERE user_id=? ORDER BY created_at DESC",
              )
              .all(u.id)
              .map(entity),
          );
        if (method === "POST") {
          const input = V.parse(V.symptomSchema, await body(req));
          const profileRow = db
            .prepare("SELECT data FROM profiles WHERE user_id=?")
            .get(u.id);
          const snapshot = {
            symptoms: input.symptoms,
            onset: input.onset,
            profile: profileRow
              ? V.parse(V.profileSchema, JSON.parse(profileRow.data))
              : defaultProfile(),
            journals: [...new Set(input.journalIds)].map((id) =>
              entity(mine("journals", id, u.id)),
            ),
          };
          const id = randomUUID(),
            t = now();
          const data = {
            snapshot,
            translation: null,
            mode: "original",
            confirmedAt: null,
            translationError: null,
          };
          db.prepare("INSERT INTO cards VALUES(?,?,?,?)").run(
            id,
            u.id,
            JSON.stringify(data),
            t,
          );
          return send(201, { id, ...data, createdAt: t });
        }
      }
      match = p.match(/^\/api\/cards\/([a-z0-9-]+)(?:\/(translate|confirm))?$/);
      if (match) {
        const row = mine("cards", match[1], u.id);
        const card = entity(row);
        if (!match[2] && method === "GET") return send(200, card);
        if (!match[2] && method === "DELETE") {
          db.prepare("DELETE FROM cards WHERE id=? AND user_id=?").run(
            card.id,
            u.id,
          );
          return send(200, { ok: true });
        }
        if (match[2] === "translate" && method === "POST") {
          rate(`ai:${u.id}`, 10, 60 * 60 * 1000);
          try {
            card.translation = V.parse(
              V.translationSchema,
              await translate(card.snapshot),
            );
            card.mode = "ai";
            card.confirmedAt = null;
            card.translationError = null;
          } catch (e) {
            card.translationError =
              "Translation unavailable. Your original information is preserved.";
            db.prepare("UPDATE cards SET data=? WHERE id=? AND user_id=?").run(
              JSON.stringify(card),
              card.id,
              u.id,
            );
            fail(
              e.status || 502,
              e.status
                ? e.message
                : "Translation failed. Please use the original card or retry.",
            );
          }
          const result = db
            .prepare("UPDATE cards SET data=? WHERE id=? AND user_id=?")
            .run(JSON.stringify(card), card.id, u.id);
          if (!result.changes) fail(404, "Record was removed.");
          return send(200, card);
        }
        if (match[2] === "confirm" && method === "PUT") {
          const input = V.parse(V.cardConfirmSchema, await body(req));
          if (card.mode !== "ai" || !card.translation)
            fail(409, "Translate the card before confirming it.");
          if (
            input.journalKo.length !== card.snapshot.journals.length ||
            new Set(input.journalKo.map((j) => j.id)).size !==
              input.journalKo.length ||
            input.journalKo.some(
              (j) => !card.snapshot.journals.some((s) => s.id === j.id),
            )
          )
            fail(400, "Selected records do not match.");
          card.translation = { ...input };
          delete card.translation.reviewed;
          card.confirmedAt = now();
          db.prepare("UPDATE cards SET data=? WHERE id=? AND user_id=?").run(
            JSON.stringify(card),
            card.id,
            u.id,
          );
          return send(200, card);
        }
      }
      if (p === "/api/posts") {
        if (method === "GET") {
          const rows = db
            .prepare(
              "SELECT p.*,u.nickname FROM posts p JOIN users u ON u.id=p.user_id ORDER BY p.created_at DESC",
            )
            .all();
          const query = (url.searchParams.get("q") || "").toLowerCase();
          const lang = url.searchParams.get("language");
          return send(
            200,
            rows
              .map(post)
              .filter(
                (v) =>
                  (!lang || v.language === lang) &&
                  `${v.title} ${v.place} ${v.body}`
                    .toLowerCase()
                    .includes(query),
              ),
          );
        }
        if (method === "POST") {
          rate(`post:${u.id}`, 30, 60 * 60 * 1000);
          const input = V.parse(V.postSchema, await body(req));
          const id = randomUUID(),
            t = now();
          db.prepare("INSERT INTO posts VALUES(?,?,?,?,?)").run(
            id,
            u.id,
            JSON.stringify(input),
            t,
            t,
          );
          return send(
            201,
            post(
              db
                .prepare(
                  "SELECT p.*,u.nickname FROM posts p JOIN users u ON u.id=p.user_id WHERE p.id=?",
                )
                .get(id),
            ),
          );
        }
      }
      match = p.match(/^\/api\/posts\/([a-z0-9-]+)(?:\/(comments|reports))?$/);
      if (match) {
        const id = match[1];
        const row = db
          .prepare(
            "SELECT p.*,u.nickname FROM posts p JOIN users u ON u.id=p.user_id WHERE p.id=?",
          )
          .get(id);
        if (!row) fail(404, "Post not found.");
        if (!match[2]) {
          if (method === "GET") return send(200, post(row));
          if (["PUT", "DELETE"].includes(method)) {
            mine("posts", id, u.id);
            if (method === "DELETE") {
              db.prepare("DELETE FROM posts WHERE id=? AND user_id=?").run(
                id,
                u.id,
              );
              return send(200, { ok: true });
            }
            const input = V.parse(V.postSchema, await body(req));
            db.prepare(
              "UPDATE posts SET data=?,updated_at=? WHERE id=? AND user_id=?",
            ).run(JSON.stringify(input), now(), id, u.id);
            return send(
              200,
              post(
                db
                  .prepare(
                    "SELECT p.*,u.nickname FROM posts p JOIN users u ON u.id=p.user_id WHERE p.id=?",
                  )
                  .get(id),
              ),
            );
          }
        }
        if (match[2] === "comments") {
          if (method === "GET")
            return send(
              200,
              db
                .prepare(
                  "SELECT c.id,c.body,c.user_id AS authorId,c.created_at AS createdAt,u.nickname AS author FROM comments c JOIN users u ON u.id=c.user_id WHERE c.post_id=? ORDER BY c.created_at",
                )
                .all(id),
            );
          if (method === "POST") {
            rate(`comment:${u.id}`, 60, 60 * 60 * 1000);
            const input = V.parse(V.commentSchema, await body(req));
            const cid = randomUUID(),
              t = now();
            db.prepare("INSERT INTO comments VALUES(?,?,?,?,?)").run(
              cid,
              id,
              u.id,
              input.body,
              t,
            );
            return send(201, {
              id: cid,
              body: input.body,
              authorId: u.id,
              author: u.nickname,
              createdAt: t,
            });
          }
        }
        if (match[2] === "reports" && method === "POST") {
          const input = V.parse(V.reportSchema, await body(req));
          db.prepare(
            "INSERT INTO reports VALUES(?,?,?,?,?,?) ON CONFLICT(post_id,user_id) DO UPDATE SET reason=excluded.reason,detail=excluded.detail",
          ).run(randomUUID(), id, u.id, input.reason, input.detail, now());
          return send(201, {
            ok: true,
            message: "Report saved for operator review.",
          });
        }
      }
      match = p.match(/^\/api\/comments\/([a-z0-9-]+)$/);
      if (match && method === "DELETE") {
        mine("comments", match[1], u.id);
        db.prepare("DELETE FROM comments WHERE id=? AND user_id=?").run(
          match[1],
          u.id,
        );
        return send(200, { ok: true });
      }
      fail(404, "Not found.");
    } catch (e) {
      if (!res.headersSent)
        send(e.status || 500, {
          error: e.status ? e.message : "Server error.",
          ...(exposeErrors ? { debug: String(e) } : {}),
        });
      else res.end();
    }
  });
  return {
    server,
    db,
    close: () =>
      new Promise((resolve) =>
        server.close(() => {
          db.close();
          resolve();
        }),
      ),
  };
}
