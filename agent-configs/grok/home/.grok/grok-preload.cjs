// ~/.grok/grok-preload.cjs — loaded by the `grok` wrapper via NODE_OPTIONS="--require …".
// grok-cli (@vibe-kit/grok-cli) has no hook API, so this preload is its enforcement layer:
//   1. Guard: wraps child_process.exec (the `bash` tool's only path: tools/bash.js → promisify(exec)),
//      fs/promises writeFile/appendFile (tools/text-editor.js writes) and fs-extra readFile & co. (its
//      reads) with the shared guard (~/.grok/guard/guard.py). deny AND ask block; any guard failure blocks.
//   2. Secrets: shell commands get an environment without gateway/API keys.
//   3. Model: grok-cli auto-creates .grok/settings.json {model: "grok-code-fast-1"} in every cwd and that
//      wins over the user default (utils/settings-manager.js getCurrentModel), so unless -m/--model or a
//      gateway model is pinned, GROK_MODEL is set to the gateway default.
//   4. Requests: grok/client.js always sends xAI's `search_parameters`; it's stripped for the gateway.
// Inert in any other Node process (children inherit NODE_OPTIONS, which is removed below).
"use strict";

const fs = require("fs");
const path = require("path");

const entry = (() => { try { return fs.realpathSync(process.argv[1] || ""); } catch { return ""; } })();
if (!entry.endsWith(path.join("@vibe-kit", "grok-cli", "dist", "index.js"))) return;

// Children (shell commands, MCP servers) must not load this preload.
if (process.env.NODE_OPTIONS) {
  process.env.NODE_OPTIONS = process.env.NODE_OPTIONS.replace(/--require[= ]\S*grok-preload\.cjs/g, "").trim();
}

const cp = require("child_process");
const util = require("util");
const { syncBuiltinESMExports } = require("module");

const guardPath = () => process.env.GROK_GUARD || path.join(require("os").homedir(), ".grok", "guard", "guard.py");
const PY = process.env.GROK_GUARD_PYTHON || "python3";
const SECRET_ENV = /^(GROK_API_KEY|AGENTGATEWAY_API_KEY|OPENAI_API_KEY|OPENROUTER_API_KEY|ANTHROPIC_(API_KEY|AUTH_TOKEN)|GEMINI_API_KEY|MORPH_API_KEY|LITELLM_API_KEY|COPILOT_PROVIDER_API_KEY|GITHUB_PAT|GH_TOKEN|GITHUB_TOKEN|OP_SERVICE_ACCOUNT_TOKEN|OP_SESSION_.*|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)$/;

const origExecFileSync = cp.execFileSync;
function verdict(args) {
  try {
    const out = origExecFileSync(PY, [guardPath(), ...args], { encoding: "utf8", timeout: 15000, stdio: ["ignore", "pipe", "pipe"] }).trim();
    const [decision, ...reason] = out.split(" ");
    if (decision === "allow") return null;
    if (decision === "deny") return `Blocked by guardrails ${reason.join(" ")}`;
    if (decision === "ask") return `Needs Murpheux's approval ${reason.join(" ")} — present the exact command and let him run it`;
    return `guardrails returned an unexpected answer (${out.slice(0, 80)})`;
  } catch (err) {
    return `guardrails unavailable (${err.code || err.message}) — blocked; reinstall the grok config`;
  }
}

// 1+2. Shell commands (exec and its promisify.custom, which promisify(exec) actually calls)
const origExec = cp.exec;
const origExecCustom = origExec[util.promisify.custom];
function scrubbedOptions(options) {
  const opts = options && typeof options === "object" ? { ...options } : {};
  const env = { ...(opts.env || process.env) };
  for (const k of Object.keys(env)) if (SECRET_ENV.test(k)) delete env[k];
  opts.env = env;
  return opts;
}
function guardedExec(command, options, callback) {
  if (typeof options === "function") { callback = options; options = undefined; }
  const blocked = verdict(["--check-command", String(command)]);
  if (blocked) {
    const err = Object.assign(new Error(blocked), { code: 126, stdout: "", stderr: blocked });
    if (callback) process.nextTick(callback, err, "", blocked);
    const fake = new (require("events").EventEmitter)();
    fake.kill = () => false;
    return fake;
  }
  return origExec.call(this, command, scrubbedOptions(options), callback);
}
guardedExec[util.promisify.custom] = (command, options) => {
  const blocked = verdict(["--check-command", String(command)]);
  if (blocked) return Promise.reject(Object.assign(new Error(blocked), { code: 126, stdout: "", stderr: blocked }));
  return origExecCustom.call(cp, command, scrubbedOptions(options));
};
cp.exec = guardedExec;

// 1. File writes: tools/text-editor.js writes via the builtin `import { writeFile } from "fs/promises"`.
const fsp = fs.promises;
for (const name of ["writeFile", "appendFile"]) {
  const orig = fsp[name];
  fsp[name] = function guardedFsPromises(file, ...rest) {
    const blocked = typeof file === "string" || file instanceof URL ? verdict(["--check-path", String(file), "--write"]) : null;
    if (blocked) return Promise.reject(Object.assign(new Error(blocked), { code: "EACCES" }));
    return orig.call(this, file, ...rest);
  };
}
syncBuiltinESMExports(); // make ESM named imports of child_process / fs/promises see the wrappers

// 1. File tools (fs-extra, resolved from the grok-cli package so the ESM default import sees the wrapper)
const pkgDir = path.dirname(path.dirname(entry));
let fse;
try {
  fse = require(require.resolve("fs-extra", { paths: [pkgDir] }));
} catch (err) {
  console.error(`grok guard: cannot load fs-extra from ${pkgDir} (${err.message}) — refusing to start unguarded`);
  process.exit(126);
}
for (const [name, write] of [["readFile", false], ["writeFile", true], ["outputFile", true], ["appendFile", true]]) {
  const orig = fse[name];
  if (typeof orig !== "function") continue;
  fse[name] = function guardedFsExtra(file, ...rest) {
    const blocked = verdict(["--check-path", String(file), ...(write ? ["--write"] : [])]);
    if (blocked) {
      const err = Object.assign(new Error(blocked), { code: "EACCES" });
      const cb = rest[rest.length - 1];
      if (typeof cb === "function") { process.nextTick(cb, err); return undefined; }
      return Promise.reject(err);
    }
    return orig.call(this, file, ...rest);
  };
}

// 3. Default model unless the user picked one (-m/--model, GROK_MODEL, or a gateway model pinned for the project)
const argv = process.argv.slice(2);
const explicit = argv.some((a) => a === "-m" || a === "--model" || a.startsWith("--model="));
const gatewayModels = (process.env.GROK_GATEWAY_MODELS || "").split(",").filter(Boolean);
if (!explicit && !process.env.GROK_MODEL && process.env.GROK_DEFAULT_MODEL) {
  let pinned = null;
  try { pinned = JSON.parse(fs.readFileSync(path.join(process.cwd(), ".grok", "settings.json"), "utf8")).model; } catch { /* none */ }
  if (!gatewayModels.includes(pinned)) process.env.GROK_MODEL = process.env.GROK_DEFAULT_MODEL;
}

// 4. Strip xAI-only request fields on calls to the gateway
const base = (process.env.GROK_BASE_URL || "").replace(/\/+$/, "");
if (base && typeof globalThis.fetch === "function") {
  const origFetch = globalThis.fetch;
  globalThis.fetch = function patchedFetch(input, init) {
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input?.url;
    if (url && url.startsWith(base) && init && typeof init.body === "string" && init.body.includes("search_parameters")) {
      try {
        const body = JSON.parse(init.body);
        delete body.search_parameters;
        init = { ...init, body: JSON.stringify(body) };
      } catch { /* leave non-JSON bodies alone */ }
    }
    return origFetch.call(this, input, init);
  };
}
