---
description: Cloud cost optimisation review of IaC or an architecture
argument-hint: "[target]"
---
Use the `role-architect` skill's judgement for this. Review for cost optimisation. Target (default: the infrastructure in this repository): ${@:-the infrastructure in this repository}

Identify the main cost drivers, then recommend concrete savings (right-sizing, Graviton/ARM, Savings Plans/Reserved/Spot, storage tiers and lifecycle, NAT/egress reduction, idle resources, log retention, autoscaling floors). For each: estimated monthly impact in C$ (state assumptions), effort, and risk. No changes to files.
