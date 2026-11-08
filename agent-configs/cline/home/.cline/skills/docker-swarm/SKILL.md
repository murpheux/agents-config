---
name: docker-swarm
description: "Writing/deploying Docker Swarm stacks on scarlet/gru/cass — compose deploy keys, secrets, placement, healthchecks, rolling updates, NFS volumes, troubleshooting"
---

# Docker Swarm stacks

Cluster facts: manager `scarlet`, workers `gru`, `cass`; contexts `<host>-daemon`; NFS `medusa:/System/Volumes/Data/Users/Shared/nfs_share`.

## Stack file conventions (compose spec, `docker stack deploy`)
- Service/stack names `kebab-case`. Pin images by tag **and** digest for anything important.
- Every service: `healthcheck`, `deploy.resources.limits` + `reservations`, `deploy.restart_policy` (`on-failure`, `max_attempts`), `logging` with size limits.
- Rolling updates: `deploy.update_config: {parallelism: 1, delay: 10s, order: start-first, failure_action: rollback}` and a matching `rollback_config`.
- Placement: `deploy.placement.constraints: [node.role == manager]` or `node.hostname == gru`; stateful services pinned to one node unless storage is shared.
- Secrets: `docker secret create` (value from `op read` run by **Murpheux**, piped, never echoed) → `secrets:` in the stack; apps read `/run/secrets/<name>`. Never put secrets in `environment:`.
- Networks: dedicated overlay per stack; `attachable: false` unless needed; encrypt sensitive overlays (`driver_opts: {encrypted: "true"}`).
- Volumes on NFS: `driver_opts: {type: nfs, o: "addr=10.10.2.100,nfsvers=4,rw", device: ":/System/Volumes/Data/Users/Shared/nfs_share/<svc>"}`.
- Publish ports in `mode: ingress` only when needed; prefer a reverse proxy.
- `docker compose config` / `docker stack config -c file.yml` to validate before deploy.

## Deploy / operate
```zsh
docker --context=scarlet-daemon stack deploy -c stack.yml --with-registry-auth <stack>
docker --context=scarlet-daemon stack services <stack>
docker --context=scarlet-daemon service ps <stack>_<svc> --no-trunc   # first stop for failures
docker --context=scarlet-daemon service logs --tail 200 <stack>_<svc>
docker --context=scarlet-daemon service rollback <stack>_<svc>        # requires approval
```

## Common failure signatures (`service ps --no-trunc`)
| Error | Cause |
|---|---|
| `no suitable node (scheduling constraints…)` | placement constraint / label mismatch |
| `insufficient resources` | reservations too high for node |
| `No such image` / `manifest unknown` | registry auth → `--with-registry-auth`, or wrong tag/arch |
| task `Rejected` / `starting` loop | failing healthcheck or crash — check logs |
| `invalid mount config` | NFS path missing or export permissions |
