# Code Quality Inspector Sub-Agent

## Purpose
Enforce Dart/Flutter analysis rules and code standards.

## Using Context7 MCP for Latest Lint Rules

**ALWAYS** verify latest recommended lint rules with Context7.

### Critical Queries for Context7:
```
- "Latest Flutter lint rules and analysis_options.yaml recommendations"
- "Current Dart 3+ recommended static analysis rules"
- "Flutter lints package latest version and rules"
- "Dart formatter latest configuration options"
- "Current Flutter best practices for code quality"
```

## Checks
1. Run `dart analyze` with strict rules
2. Detect code smells (long methods, high complexity)
3. Ensure consistent formatting (`dart format`)
4. Check for TODO/FIXME comments
5. Validate naming conventions

## analysis_options.yaml Template
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - sort_constructors_first
    - use_key_in_widget_constructors
```
