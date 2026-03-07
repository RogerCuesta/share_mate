# Agents in .codex

## Structure
- `active/main/`: current main agent to use for this repo
- `active/sub-agents/`: reduced, optimized specialist set
- `legacy-claude/`: full copy of previous `.claude/agents` setup
  - `main/`
  - `sub-agents/`

## Recommended Usage Order
1. Start with `active/main/share-mate-principal-agent.md`
2. Delegate focused work to one or more `active/sub-agents/*`
3. Use `legacy-claude/*` only for historical reference or prompt back-compat

## Why this layout
- Preserves old behavior (no information loss)
- Gives a smaller active set with less overlap
- Keeps migration and maintenance simple
