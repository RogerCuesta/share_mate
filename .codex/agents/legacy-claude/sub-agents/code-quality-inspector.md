# Code Quality Inspector Sub-Agent

## Purpose
Enforce Dart/Flutter analysis rules and code standards.

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
