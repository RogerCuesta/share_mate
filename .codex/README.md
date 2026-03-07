# Local Codex Workspace Assets

This `.codex` directory is organized for predictable local usage:

- `agents/`
  - `active/`: current agents for this repository
  - `legacy-claude/`: full migrated copy from `.claude/agents`
  - `ANALYSIS.md`: keep/remove rationale and optimization notes
- `skills/`
  - local skills that are fully available in this repository
- `get-shit-done/`
  - workflow assets used by the GSD toolkit

If a skill is not present locally in `skills/`, use the globally installed skill from `$CODEX_HOME/skills`.
