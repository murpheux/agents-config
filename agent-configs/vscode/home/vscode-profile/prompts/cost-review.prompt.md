---
description: Cloud cost optimisation review of IaC or an architecture
agent: Architect
argument-hint: '[target, default this repo''s infrastructure]'
---

Review for cost optimisation. Target (default: the infrastructure in this repository): ${input:target:target or focus}
Identify the main cost drivers, then recommend concrete savings (right-sizing, Graviton/ARM, Savings Plans/Reserved/Spot, storage tiers and lifecycle, NAT/egress reduction, idle resources, log retention, autoscaling floors). For each: estimated monthly impact in C$ (state assumptions), effort and risk. No file changes.
