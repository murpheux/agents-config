---
name: wf-cost-review
description: "Cloud cost optimisation review of IaC or an architecture"
---

# wf-cost-review

Workflow skill (invoke explicitly, e.g. `/wf-cost-review`). Treat the user's words after the skill name as the target.

Review for cost optimisation. Target (default: the infrastructure in this repository): the user's target
Identify the main cost drivers, then recommend concrete savings (right-sizing, Graviton/ARM, Savings Plans/Reserved/Spot, storage tiers and lifecycle, NAT/egress reduction, idle resources, log retention, autoscaling floors). For each: estimated monthly impact in C$ (state assumptions), effort and risk. No file changes.

Follow the `role-architect` skill (load it with `/role-architect` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-architect` first, then summarise its result.
