import { createApp } from "./app.js";
import { fileURLToPath } from "node:url";
const port = Number(process.env.PORT || 8790);
const app = createApp({
  dbPath: process.env.DB_PATH || "data/carebridge.sqlite",
  origins: (
    process.env.ALLOWED_ORIGINS ||
    "http://localhost:8090,http://127.0.0.1:8090,http://localhost:8790,http://127.0.0.1:8790"
  ).split(","),
  secureCookies: process.env.NODE_ENV === "production",
  staticDir: fileURLToPath(new URL("../../app/build/web", import.meta.url)),
});
app.server.listen(port, process.env.HOST || "127.0.0.1", () =>
  console.log(`CareBridge API: http://${process.env.HOST || "127.0.0.1"}:${port}`),
);
for (const sig of ["SIGINT", "SIGTERM"])
  process.on(sig, () => app.close().then(() => process.exit(0)));
