# Test Coverage Enforcer Sub-Agent

## Purpose
Ensure minimum test coverage (80%+).

## Checks
- Overall coverage: ≥80%
- Domain layer: ≥90%
- Critical paths: 100%

## Commands
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Report Template
```
Coverage: 76% (below threshold)
Missing tests:
- TaskRepository error scenarios
- FormProvider validation
```
