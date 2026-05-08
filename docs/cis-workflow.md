# CIS Linux Workflow (PoC)

## Architecture

This PoC uses a GitOps model where configuration and automation logic are versioned in Git.

- GitHub Actions orchestrates linting and execution.
- A self-hosted runner executes Ansible inside the infrastructure boundary.
- Ansible-Lockdown upstream roles provide CIS audit/remediation logic.
- Inventory group selection controls target hosts (`debian12`, `oracle_linux`, `linux_cis`).
- CIS inventory file is stored at `ansible/inventory/ssh/hosts.yml`.
- CIS group vars live under `ansible/inventory/ssh/group_vars/`.

Execution flow:
1. `lint` job validates playbooks and syntax.
2. `cis` job installs pinned roles, runs preflight, then runs audit or remediation.
3. Report artifacts are collected into `ansible/reports/<run_id>/` and uploaded.

## Wrapper Approach

The playbooks in `ansible/playbooks/cis/` are intentionally thin wrappers:

- `preflight.yml` validates `target_group`, inventory membership, supported OS, and sudo access.
- `audit.yml` dynamically loads `cis_audit_role` from group vars and runs audit-only mode (`run_audit: true`, `audit_only: true`).
- `remediate.yml` dynamically loads `cis_remediation_role`, forces `serial: 1`, requires `confirm_remediation=YES`, and enables audit capture around remediation (`run_audit: true`) for evidence.

This keeps logic readable and thesis-explainable while still reusing upstream CIS content.

## Why Roles Are Pinned

Roles are installed via `ansible-galaxy` from git sources in `ansible/requirements/cis-lockdown.yml`.

- No vendored upstream code is copied into this repository.
- No `latest` versions are used.
- Each role must be pinned to an explicit commit SHA.

This ensures deterministic and reproducible automation runs.

## How To Run

Use the `CIS Linux PoC` workflow (`workflow_dispatch`) with inputs:

- `target_group`: inventory group to target
- `mode`: `audit` or `remediate`
- `cis_profile`: one of:
  - `level1-server` (default)
  - `level1-workstation`
  - `level2-server`
  - `level2-workstation`
- `confirm_remediation`: must be `YES` for remediation mode

Examples:

- Audit run:
  - `mode=audit`
  - `target_group=linux_cis`
  - `cis_profile=level1-server`
- Remediation:
  - `mode=remediate`
  - `target_group=debian12` (or `oracle_linux`)
  - `cis_profile=level1-server`
  - `confirm_remediation=YES`

## Report Output Contract

- Role fetch destination is forced to `${GITHUB_WORKSPACE}/ansible/reports/<run_id>/raw/`.
- Artifact upload path is `ansible/reports/<run_id>/`.
- Expected primary files are JSON scan outputs under `raw/`.
  - Audit mode: typically pre-scan output.
  - Remediation mode: pre-scan and post-scan outputs for before/after evidence.
- `scripts/cis/collect-results.sh` acts as validator/fallback. If no reports are found, it writes `TODO-REPORT-SOURCE.txt`.

## Risks And Limitations

- Upstream role updates may change behavior or variables.
- Remediation may break SSH, sudo, or firewall access if controls are misapplied.
- Oracle Linux uses RHEL roles (binary-compatible assumption, not perfect equivalence).
- RHEL10-CIS upstream role is community-maintained and may require Oracle-specific variable tuning.
- Audit and remediation role versions may drift if pins are not managed together.
- Self-hosted runner security is critical (runner hardening and network boundaries required).
- Secrets leakage risk exists if workflows are modified unsafely.
- Authentication scope is intentionally simplified for PoC:
  - SSH key from `ANSIBLE_SSH_PRIVATE_KEY`
  - single automation user
  - no Vault, PAM, or OIDC integration
