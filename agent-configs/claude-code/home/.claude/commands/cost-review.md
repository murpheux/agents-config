---
description: Cloud cost optimisation review of IaC or an architecture
argument-hint: '[target, default this repo''s infrastructure]'
---

Review for cost optimisation. Target (default: the infrastructure in this repository): $ARGUMENTS
Identify the main cost drivers, then recommend concrete savings (right-sizing, Graviton/ARM, Savings Plans/Reserved/Spot, storage tiers and lifecycle, NAT/egress reduction, idle resources, log retention, autoscaling floors). For each: estimated monthly impact in C$ (state assumptions), effort and risk. No file changes.

Delegate this to the `architect` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
