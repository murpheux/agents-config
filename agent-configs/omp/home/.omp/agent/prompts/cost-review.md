---
description: Cloud cost optimisation review of IaC or an architecture
argument-hint: "[target]"
---
Delegate this to the `architect` subagent with the task tool (self-contained brief), then summarise its result. Review for cost optimisation. Target (default: the infrastructure in this repository): $ARGUMENTS (if empty: the infrastructure in this repository)

Identify the main cost drivers, then recommend concrete savings (right-sizing, Graviton/ARM, Savings Plans/Reserved/Spot, storage tiers and lifecycle, NAT/egress reduction, idle resources, log retention, autoscaling floors). For each: estimated monthly impact in C$ (state assumptions), effort, and risk. No changes to files.
