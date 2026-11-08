---
name: cost-review
description: "Cloud cost optimisation review of IaC or an architecture"
---

# cost-review

Workflow skill (invoke explicitly, e.g. `$cost-review`). Treat the user's words after the skill name as the target.

Review for cost optimisation. Target (default: the infrastructure in this repository): the user's target
Identify the main cost drivers, then recommend concrete savings (right-sizing, Graviton/ARM, Savings Plans/Reserved/Spot, storage tiers and lifecycle, NAT/egress reduction, idle resources, log retention, autoscaling floors). For each: estimated monthly impact in C$ (state assumptions), effort and risk. No file changes.

Delegate the work to the `architect` subagent with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
