# /cost-review.md — Cloud cost optimisation review of IaC or an architecture

Review for cost optimisation. Target (default: the infrastructure in this repository): the target Murpheux gave with the command
Identify the main cost drivers, then recommend concrete savings (right-sizing, Graviton/ARM, Savings Plans/Reserved/Spot, storage tiers and lifecycle, NAT/egress reduction, idle resources, log retention, autoscaling floors). For each: estimated monthly impact in C$ (state assumptions), effort and risk. No file changes.

## Steps

1. Use `subagent_architect` for the analysis if available; write any files in Act mode.
