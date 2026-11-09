// ~/.config/kilo/plugin/guardrails.ts — SKELETON. tool.execute.before hook -> guard/kilo_guard.py (fail-closed).
// TODO(verify): Kilo plugin API shape (OpenCode-derived: `tool.execute.before` receiving {tool}, {args}).
import { spawnSync } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

const GUARD = join(homedir(), ".config", "kilo", "guard", "kilo_guard.py");

export const Guardrails = async () => ({
  "tool.execute.before": async (input: { tool: string }, output: { args: Record<string, unknown> }) => {
    const run = spawnSync("python3", [GUARD], { input: JSON.stringify({ toolName: input.tool, input: output.args }), encoding: "utf8" });
    if (run.status !== 0) throw new Error(`guardrails: guard failed (${run.stderr?.slice(0, 200)})`);
    const { decision, reason } = JSON.parse(run.stdout);
    if (decision !== "allow") throw new Error(`guardrails: ${decision}: ${reason}`);
  },
});
