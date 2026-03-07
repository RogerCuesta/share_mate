# Performance Auditor Sub-Agent

## Purpose
Identify and resolve performance bottlenecks.

## Audit Areas
1. Build method efficiency
2. Provider over-watching
3. List performance (use .builder)
4. Image loading optimization
5. Hive query optimization

## Report Format
```
🔴 CRITICAL: Unnecessary rebuilds in TaskList
  Fix: Use ref.watch(provider.select((s) => s.field))
  Impact: 60fps → 45fps

🟡 WARNING: No const constructors
  Fix: Add const where possible
```

## Hive-Specific Checks
- No .values.toList() in hot paths
- Use ValueListenableBuilder
- LazyBox for large objects
- Batch operations (putAll)
