// Offline test: loads ~/.grok/grok-preload.cjs (repo copy) exactly as the wrapper would, then drives
// grok-cli's REAL tool classes (tools/bash.js → promisify(exec), tools/text-editor.js → fs-extra).
//   node tests/test-preload.mjs            (GROK_PKG overrides the installed package location)
import { createRequire } from "node:module";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const home = path.join(here, "..", "home", ".grok");
const binGrok = (() => { try { return execFileSync("sh", ["-c", "command -v grok"], { encoding: "utf8" }).trim(); } catch { return ""; } })();
const pkg = process.env.GROK_PKG || (binGrok ? path.dirname(path.dirname(fs.realpathSync(binGrok))) : "");
const entry = path.join(pkg, "dist", "index.js");
if (!pkg || !fs.existsSync(entry)) { console.log("SKIP grok-cli not installed"); process.exit(0); }

let failures = 0;
const check = (name, ok, detail = "") => { console.log(`${ok ? "PASS" : "FAIL"} ${name}${detail ? ` — ${detail}` : ""}`); if (!ok) failures++; };

// Load the preload as the grok process would (argv[1] = grok-cli entry).
process.argv[1] = entry;
process.env.GROK_GUARD = path.join(home, "guard", "guard.py");
process.env.GROK_API_KEY = "dummy-not-a-key";
process.env.GROK_DEFAULT_MODEL = "claude-sonnet-5";
process.env.GROK_GATEWAY_MODELS = "deepseek-flash,claude-sonnet-5";
process.env.GROK_BASE_URL = "https://scarlet:9443/v1";
delete process.env.GROK_MODEL;
const work = fs.mkdtempSync(path.join(os.tmpdir(), "grok-preload-"));
process.chdir(work);
fs.mkdirSync(".grok"); fs.writeFileSync(".grok/settings.json", JSON.stringify({ model: "grok-code-fast-1" }));
createRequire(import.meta.url)(path.join(home, "grok-preload.cjs"));
check("default model set when project pins a non-gateway model", process.env.GROK_MODEL === "claude-sonnet-5", process.env.GROK_MODEL);

const { BashTool } = await import(pathToFileURL(path.join(pkg, "dist", "tools", "bash.js")).href);
const { TextEditorTool } = await import(pathToFileURL(path.join(pkg, "dist", "tools", "text-editor.js")).href);
const { ConfirmationService } = await import(pathToFileURL(path.join(pkg, "dist", "utils", "confirmation-service.js")).href);
ConfirmationService.getInstance().setSessionFlag("allOperations", true); // headless: no prompts — guard must still hold

const bash = new BashTool();
const run = (cmd) => bash.execute(cmd, 10000);
let r = await run("echo hello"); check("bash allows harmless command", r.success && r.output === "hello", r.error);
r = await run("rm -rf ~"); check("bash blocks rm -rf ~", !r.success && /Blocked by guardrails/.test(r.error), r.error);
r = await run("git push origin main"); check("bash blocks git push (ask)", !r.success && /approval/.test(r.error), r.error);
r = await run("cat ~/.aws/credentials"); check("bash blocks credential read", !r.success && /Blocked/.test(r.error), r.error);
r = await run('test -z "$GROK_API_KEY" && echo clean'); check("shell env has no GROK_API_KEY", r.success && r.output === "clean", r.output || r.error);

const editor = new TextEditorTool();
fs.writeFileSync("ok.txt", "x\n");
r = await editor.view(path.join(work, "ok.txt")); check("view allowed path", r.success, r.error);
fs.mkdirSync(".ssh"); fs.writeFileSync(".ssh/id_ed25519", "fake");
r = await editor.view(path.join(work, ".ssh", "id_ed25519")); check("view blocks private key", !r.success && /protected-path/.test(String(r.error)), r.error);
r = await editor.create(path.join(work, ".env"), "A=1"); check("create blocks .env", !r.success && !fs.existsSync(".env"), r.error);
r = await editor.create(path.join(work, "new.txt"), "hi"); check("create allowed path", r.success && fs.existsSync("new.txt"), r.error);

// Fail closed: guard missing → commands blocked
process.env.GROK_GUARD = "/nonexistent/guard.py";
r = await run("echo hello"); check("guard missing blocks commands", !r.success && /unavailable/.test(r.error), r.error);

// search_parameters stripped for gateway requests (fresh process whose entry path looks like grok-cli's)
process.env.GROK_GUARD = path.join(home, "guard", "guard.py");
const fake = path.join(work, "@vibe-kit", "grok-cli");
fs.mkdirSync(path.join(fake, "dist"), { recursive: true });
fs.mkdirSync(path.join(fake, "node_modules"));
fs.symlinkSync(path.join(pkg, "node_modules", "fs-extra"), path.join(fake, "node_modules", "fs-extra"));
fs.writeFileSync(path.join(fake, "dist", "index.js"), `
  const r1 = await fetch("https://scarlet:9443/v1/chat/completions", { method: "POST", body: JSON.stringify({ model: "m", search_parameters: { mode: "off" } }) });
  const r2 = await fetch("https://api.example.com/v1/x", { method: "POST", body: JSON.stringify({ search_parameters: { mode: "on" } }) });
  console.log(JSON.stringify([await r1.json(), await r2.json()]));`);
fs.writeFileSync(path.join(work, "stub-fetch.cjs"), "globalThis.fetch = async (u, i) => ({ json: async () => JSON.parse(i.body) });");
const out = execFileSync(process.execPath, ["--require", path.join(work, "stub-fetch.cjs"), "--require", path.join(home, "grok-preload.cjs"), path.join(fake, "dist", "index.js")],
  { encoding: "utf8", env: { ...process.env, GROK_BASE_URL: "https://scarlet:9443/v1" } });
const [gw, other] = JSON.parse(out.trim());
check("search_parameters stripped for the gateway", !("search_parameters" in gw) && gw.model === "m", JSON.stringify(gw));
check("other hosts untouched", "search_parameters" in other);
fs.rmSync(work, { recursive: true, force: true });
console.log(failures ? `${failures} FAILED` : "all preload checks passed");
process.exit(failures ? 1 : 0);
