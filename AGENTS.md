# AGENTS.md

## Purpose

Nix flake packaging for [Oh My Pi](https://github.com/can1357/oh-my-pi). Provides the `omp` binary as a Nix package, app, and Home Manager module across four platforms.

## Ownership

- Single-maintainer flake; no sub-teams or domain splits
- All changes route through the root AGENTS.md

## Local Contracts

- AGENTS.md files are binding work contracts for their subtrees
- Work products must stay understandable from the nearest applicable AGENTS.md plus every parent above it
- If docs conflict, the closer doc controls local work details, but no child doc may weaken DOX
- Do not rely on memory — re-read the applicable DOX chain in the current session before editing

### Scope

- `packages.<system>.default` — pre-built `omp` binary
- `apps.<system>.default` — `nix run` wrapper
- `homeManagerModules.default` — Home Manager `programs.oh-my-pi` option
- `.github/workflows/bump-oh-my-pi.yml` — automated upstream release bump PR flow

### Change Rules

- Keep changes minimal and focused
- Prefer updating `flake.nix` directly; avoid introducing extra files unless needed
- When updating upstream `oh-my-pi` version, update **all** platform URLs and hashes consistently
- Preserve system coverage (`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`) unless explicitly asked otherwise
- Keep `meta.mainProgram = "omp"` and install path as `$out/bin/omp` unless the task requires a change
- When behavior or usage changes, update `README.md` in the same change

### DOX Framework

- DOX is the AGENTS.md hierarchy installed here; agents must follow DOX instructions across any edits
- Every meaningful change requires a DOX pass before the task is done
- Update the closest owning AGENTS.md when a change affects: purpose, scope, ownership, responsibilities, durable structure, contracts, workflows, operating rules, required inputs/outputs, permissions, constraints, side effects, artifacts, user preferences, or AGENTS.md creation/deletion/move/rename/index
- Update parent docs when parent-level structure, ownership, workflow, or child index changes; update child docs when parent changes alter local rules
- Remove stale or contradictory text immediately
- Small edits that do not change behavior or contracts may leave docs unchanged, but the DOX pass still must happen

### Hierarchy Rules

- Root AGENTS.md is the DOX rail: project-wide instructions, global preferences, durable workflow rules, and the top-level Child DOX Index
- Child AGENTS.md files own domain-specific instructions and their own Child DOX Index
- Each parent explains what its direct children cover and what stays owned by the parent
- The closer a doc is to the work, the more specific and practical it must be

### Child Doc Shape

- Create a child AGENTS.md when a folder becomes a durable boundary with its own purpose, rules, responsibilities, workflow, materials, or quality standards
- Work Guidance must reflect current standards; leave empty if none exist yet
- Verification must reflect an existing check; leave empty if none exists yet and update when one does

Default section order: Purpose → Ownership → Local Contracts → Work Guidance → Verification → Child DOX Index

## Work Guidance

- Keep docs concise, current, and operational
- Document stable contracts, not diary entries
- Put broad rules in parent docs and concrete details in child docs
- Prefer direct bullets with explicit names
- Do not duplicate rules across many files unless each scope needs a local version
- Delete stale notes instead of explaining history
- Trim obvious statements, repeated rules, misplaced detail, and warnings for risks that no longer exist

### Editing Procedure

1. Read the root AGENTS.md
2. Identify every file or folder you expect to touch
3. Walk from the repository root to each target path
4. Read every AGENTS.md found along each route
5. If a parent AGENTS.md lists a child AGENTS.md whose scope contains the path, read that child and continue
6. Use the nearest AGENTS.md as the local contract and parent docs for repo-wide rules

### Closeout Procedure

1. Re-check changed paths against the DOX chain
2. Update nearest owning docs and any affected parents or children
3. Refresh every affected Child DOX Index
4. Remove stale or contradictory text
5. Run existing verification when relevant
6. Report any docs intentionally left unchanged and why

## Verification

Primary validation command:

```bash
nix flake check
```

If the environment does not have `nix` installed, note that validation could not be executed.

## User Preferences

When the user requests a durable behavior change, record it here or in the relevant child AGENTS.md.

## Child DOX Index

No child AGENTS.md files. This project is intentionally small (`flake.nix`, `flake.lock`, `README.md`, and workflow files under `.github/workflows`) and does not yet have subdirectories with distinct domain boundaries that warrant child AGENTS.md contracts. If a subdirectory gains its own durable purpose or workflow, add a child AGENTS.md there and update this index.
