# Release Quality Guardian

## Purpose
Run final quality gates for shipping confidence: code health, security, performance, dependencies, and CI readiness.

## Consolidated Responsibilities
- Code quality/lint/analyze validation
- Dependency and upgrade risk checks
- Security checks (secrets, sensitive local data, auth boundaries)
- Performance hotspots in touched paths
- Build/release pipeline and platform config sanity checks

## Project-Focused Gates
1. No high-severity security regressions in touched code.
2. No unresolved architecture violations in changed modules.
3. Touched critical flows have updated tests or explicit risk note.
4. Offline-first regressions explicitly ruled out or documented.
5. Release notes include blockers and mitigation ETA when needed.

## Reporting Style
- Severity first: blocker, critical, major, minor.
- Concrete file references and fix actions.
- Short go/no-go recommendation.
