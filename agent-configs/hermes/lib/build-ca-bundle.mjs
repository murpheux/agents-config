#!/usr/bin/env node
// Write the OS trust store (incl. the home-lab CA trusted in the macOS keychain) to a PEM bundle,
// then verify it against the gateway. For runtimes that ignore the keychain: Python/OpenSSL
// (Aider, via SSL_CERT_FILE) and Node (Copilot CLI, via NODE_EXTRA_CA_CERTS).
// Same mechanism as the Cline CLI launcher: tls.getCACertificates("system"), Node >= 22.15.
//
// usage: node build-ca-bundle.mjs <out.pem> [host:port]     (default host scarlet:9443)
import fs from "node:fs";
import tls from "node:tls";

const [out, target = "scarlet:9443"] = process.argv.slice(2);
if (!out) { console.error("usage: build-ca-bundle.mjs <out.pem> [host:port]"); process.exit(2); }
if (typeof tls.getCACertificates !== "function") {
  console.error(`node ${process.version} lacks tls.getCACertificates — need Node >= 22.15`); process.exit(1);
}
const certs = tls.getCACertificates("system");
if (!certs.length) { console.error("OS trust store returned no certificates"); process.exit(1); }
const pem = certs.map((c) => (c.endsWith("\n") ? c : `${c}\n`)).join("");
fs.writeFileSync(`${out}.tmp`, pem, { mode: 0o644 });
fs.renameSync(`${out}.tmp`, out);
console.log(`${certs.length} OS-trusted certificates → ${out}`);

const [host, port] = target.split(":");
const sock = tls.connect({ host, port: Number(port), servername: host, ca: pem, timeout: 8000 }, () => {
  console.log(`verified: ${target} chains to a certificate in the bundle`); sock.end();
});
sock.on("timeout", () => { console.warn(`warning: ${target} unreachable (timeout) — bundle written but not verified`); sock.destroy(); });
sock.on("error", (e) => {
  const tlsErr = /CERT|SELF_SIGNED|ISSUER|ALTNAME|SIGNATURE|VERIFY/i.test(e.code ?? e.message);
  if (tlsErr) { console.error(`FAILED: ${target} does not verify against the bundle (${e.code ?? e.message})`); process.exit(1); }
  console.warn(`warning: ${target} unreachable (${e.code ?? e.message}) — bundle written but not verified`);
});
