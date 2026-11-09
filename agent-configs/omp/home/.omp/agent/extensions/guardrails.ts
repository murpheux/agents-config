/**
 * omp guardrails extension — runs the repo's shared guard on every tool call.
 *
 * omp 18.x emits `tool_call` ({ type, toolName, toolCallId, input }) before each tool runs; a handler
 * returning { block: true, reason } stops it, and omp itself blocks when a handler throws or times out
 * (verified in the installed binary's ExtensionRunner.emitToolCall). Rather than re-porting the rules,
 * this calls ~/.omp/agent/guard/omp_guard.py (the shared guard.py + guardrails.json, plus omp's edit-mode
 * shapes), so every tool in this repo enforces the identical rule set.
 *
 * deny → block · ask → ctx.ui.confirm when there is a UI, otherwise block · any guard failure → throw
 * (omp then blocks the call: fail closed).
 */
import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";

const AGENT_DIR = process.env.PI_CODING_AGENT_DIR || path.join(os.homedir(), ".omp", "agent");
const GUARD = path.join(AGENT_DIR, "guard", "omp_guard.py");

type Verdict = { decision: "allow" | "ask" | "deny"; reason: string };

function check(toolName: string, input: unknown): Verdict {
  const run = spawnSync("python3", [GUARD], {
    input: JSON.stringify({ toolName, input }),
    encoding: "utf8",
    timeout: 10_000,
  });
  if (run.error || run.status !== 0) {
    throw new Error(`guardrails unavailable (${run.error?.message ?? `exit ${run.status}`}); reinstall the omp config`);
  }
  const verdict = JSON.parse(run.stdout) as Verdict;
  if (!["allow", "ask", "deny"].includes(verdict.decision)) {
    throw new Error(`guardrails returned an invalid decision: ${run.stdout.slice(0, 200)}`);
  }
  return verdict;
}

export default function (pi) {
  pi.on("tool_call", async (event, ctx) => {
    const verdict = check(event.toolName, event.input);
    if (verdict.decision === "allow") return undefined;
    if (verdict.decision === "ask") {
      if (ctx?.hasUI === true) {
        const ok = await ctx.ui.confirm("Guardrails", `${verdict.reason}\n\nAllow this ${event.toolName} call?`);
        if (ok) return undefined;
      }
      return { block: true, reason: `Needs Murpheux's approval ${verdict.reason} — present the exact command and let him run it` };
    }
    return { block: true, reason: `Blocked by guardrails ${verdict.reason}` };
  });
}
