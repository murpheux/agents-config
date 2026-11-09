---
name: ansible
description: "Writing or reviewing Ansible playbooks/roles for server-state config — layout, idempotency, vault/1Password secrets, check-mode workflow"
---

# Ansible

## Layout
```
ansible/
  inventory/hosts.yml          # groups: swarm_managers (scarlet), swarm_workers (gru, cass), dev (medusa)
  group_vars/ host_vars/
  roles/<role_name>/{tasks,handlers,templates,defaults,meta}/
  playbooks/<name>.yml         # snake_case
  ansible.cfg                  # remote_user=_ai_daemon, host_key_checking=True
```

## Rules
- FQCN modules (`ansible.builtin.copy`); no `shell`/`command` when a module exists; if unavoidable use `creates:`/`changed_when:`.
- Idempotent: second run reports `changed=0`.
- OS-aware packages: `community.general.pacman` (scarlet, cass), `ansible.builtin.apt` (gru), `community.general.homebrew` (medusa) — or `ansible.builtin.package` with per-OS vars.
- Secrets: `community.general.onepassword` lookup or ansible-vault; `no_log: true` on tasks handling secrets.
- Handlers for restarts; `become: true` only on tasks that need it.
- Templates end with `{{ ansible_managed | comment }}`.

## Workflow
1. `ansible-lint` · `ansible-playbook --syntax-check` — read-only (safe to auto-approve).
2. `ansible-playbook -i inventory playbooks/x.yml --check --diff --limit <host>` — requires approval.
3. Real runs against production/shared hosts are in the destructive gate — Murpheux approves.
