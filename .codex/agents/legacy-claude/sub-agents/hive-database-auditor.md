# Hive Database Auditor Sub-Agent

## Purpose
Audit Hive database implementation for performance, security, and best practices compliance.

## Audit Checklist

### 1. TypeAdapter Registration
- ✓ All models have @HiveType annotation with unique typeId
- ✓ TypeAdapters registered before box opening
- ✓ No typeId conflicts across models
- ✓ Generated .g.dart files up to date

### 2. Box Lifecycle Management
- ✓ Boxes opened in main() or initialization phase
- ✓ Boxes closed on app disposal
- ✓ No repeated box.open() calls (check for leaks)
- ✓ Proper error handling on box operations

### 3. Performance Patterns
- ✓ LazyBox used for large objects (>100KB per entry)
- ✓ Batch operations (putAll, deleteAll) instead of loops
- ✓ No .values.toList() inside ListView.builder
- ✓ Indexed queries where applicable (custom box methods)
- ✓ Auto-compaction enabled for frequently updated boxes

### 4. Security & Encryption
- ✓ Sensitive data encrypted with HiveAES
- ✓ Encryption keys stored securely (flutter_secure_storage)
- ✓ No plain-text passwords/tokens in Hive
- ✓ Box names don't expose sensitive info

### 5. Migration Strategy
- ✓ HiveField defaultValue for new fields
- ✓ Version tracking for breaking changes
- ✓ Backward compatibility handling
- ✓ Data migration scripts if needed

### 6. Data Integrity
- ✓ Proper null safety in models
- ✓ Validation before putting data
- ✓ Cascade deletion handling (related entities)
- ✓ Backup strategy for critical data

## Audit Report Template
```
📦 HIVE DATABASE AUDIT REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 TypeAdapter Analysis
✅ 3 adapters registered (Task, User, Settings)
✅ No typeId conflicts
⚠️  WARNING: ProjectModel adapter not generated (run build_runner)

🔍 Box Lifecycle
✅ Boxes opened in HiveService.init()
❌ CRITICAL: Box 'taskBox' never closed (memory leak risk)
   Location: lib/features/tasks/data/datasources/task_local_datasource.dart
   Fix: Add box.close() in dispose() or app termination

🔍 Performance
✅ LazyBox used for attachments (average 500KB per file)
❌ CRITICAL: Using .values.toList() in hot path
   Location: lib/features/tasks/presentation/screens/task_list_screen.dart:89
   Impact: O(n) iteration on every frame rebuild
   Fix: Cache list or use ValueListenableBuilder with box.listenable()

✅ Batch operations used for sync (putAll with 100 items)

🔍 Security
❌ BLOCKER: Sensitive 'notes' field not encrypted
   Location: lib/features/tasks/data/models/task_model.dart
   Risk: Plain-text sensitive user data
   Fix: Create separate encrypted box for notes or use HiveAES

✅ Auth tokens stored in flutter_secure_storage (not Hive)

🔍 Migration
✅ All new fields have defaultValue annotations
⚠️  WARNING: No version tracking for TaskModel
   Recommendation: Add version field for future breaking changes

🔍 Data Integrity
✅ Null safety properly handled
✅ Validation in repository before put()
❌ MAJOR: No cascade deletion for related entities
   Scenario: Deleting User doesn't delete their Tasks
   Fix: Implement cascade deletion in UserRepository

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 OVERALL SCORE: 6.5/10
🚫 BLOCKERS: 1 (encryption)
⚠️  CRITICAL: 2 (memory leak, performance)
📋 TOTAL ISSUES: 6

RECOMMENDATION: Address blocker before production release
ESTIMATED FIX TIME: 3 hours
```

## Common Anti-Patterns to Flag

### 1. Opening boxes in build methods
```dart
// ❌ BAD
Widget build(BuildContext context) {
  final box = Hive.box<TaskModel>('tasks'); // Opens on every rebuild!
  ...
}

// ✅ GOOD
class TaskLocalDataSourceImpl {
  Box<TaskModel> get _box => Hive.box<TaskModel>('tasks'); // Already opened
}
```

### 2. Not closing boxes (memory leaks)
```dart
// ❌ BAD
await Hive.openBox<TaskModel>('tasks');
// Never closed

// ✅ GOOD
// In HiveService
static Future<void> closeAll() async {
  await Hive.close();
}
// Called in main() on app termination
```

### 3. Hot path iterations
```dart
// ❌ BAD: O(n) on every build
Widget build(BuildContext context) {
  final tasks = Hive.box<TaskModel>('tasks').values.toList();
  return ListView.builder(...);
}

// ✅ GOOD: Use ValueListenableBuilder
Widget build(BuildContext context) {
  return ValueListenableBuilder(
    valueListenable: Hive.box<TaskModel>('tasks').listenable(),
    builder: (context, Box<TaskModel> box, _) {
      final tasks = box.values.toList();
      return ListView.builder(...);
    },
  );
}
```

### 4. Loop puts instead of batch
```dart
// ❌ BAD: N database writes
for (var task in tasks) {
  await box.put(task.id, task);
}

// ✅ GOOD: 1 database write
await box.putAll(Map.fromEntries(
  tasks.map((t) => MapEntry(t.id, t))
));
```

### 5. Regular Box for large files
```dart
// ❌ BAD: Loads all files into memory
await Hive.openBox<AttachmentModel>('attachments');

// ✅ GOOD: Lazy loading for files >100KB
await Hive.openLazyBox<AttachmentModel>('attachments');
```

### 6. No encryption for sensitive data
```dart
// ❌ BAD: Plain-text passwords
@HiveField(0)
final String password;

// ✅ GOOD: Encrypted box
final encryptionKey = await getEncryptionKey(); // From secure storage
await Hive.openBox<UserModel>(
  'users',
  encryptionCipher: HiveAesCipher(encryptionKey),
);
```

### 7. TypeId conflicts
```dart
// ❌ BAD: Duplicate typeIds
@HiveType(typeId: 0)
class TaskModel { }

@HiveType(typeId: 0) // Conflict!
class UserModel { }

// ✅ GOOD: Centralized management
// lib/core/storage/hive_type_ids.dart
class HiveTypeIds {
  static const int task = 0;
  static const int user = 1;
  static const int settings = 2;
}

@HiveType(typeId: HiveTypeIds.task)
class TaskModel { }
```

### 8. Missing TypeAdapter registration
```dart
// ❌ BAD: Forgot to register
await Hive.initFlutter();
await Hive.openBox<TaskModel>('tasks'); // ERROR: TypeAdapter not found

// ✅ GOOD: Register before opening
await Hive.initFlutter();
Hive.registerAdapter(TaskModelAdapter());
await Hive.openBox<TaskModel>('tasks');
```

## Optimization Recommendations

### Box Compaction
```dart
// Enable auto-compaction for frequently updated boxes
await Hive.openBox<TaskModel>(
  'tasks',
  compactionStrategy: (entries, deletedEntries) {
    return deletedEntries > 50; // Compact when 50+ deleted
  },
);

// Manual compaction after bulk deletes
await box.compact();
```

### Encryption Setup
```dart
// lib/core/storage/hive_encryption.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class HiveEncryption {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key';
  
  static Future<List<int>> getEncryptionKey() async {
    var key = await _storage.read(key: _keyName);
    
    if (key == null) {
      final newKey = Hive.generateSecureKey();
      await _storage.write(
        key: _keyName,
        value: base64UrlEncode(newKey),
      );
      return newKey;
    }
    
    return base64Url.decode(key);
  }
}

// Usage
final encryptionKey = await HiveEncryption.getEncryptionKey();
await Hive.openBox<SensitiveModel>(
  'sensitive',
  encryptionCipher: HiveAesCipher(encryptionKey),
);
```

### Cascade Deletion
```dart
// lib/features/users/data/repositories/user_repository_impl.dart
@override
Future<Either<UserFailure, Unit>> delete(String userId) async {
  try {
    // Delete related entities first
    await _taskLocalDataSource.deleteByUserId(userId);
    await _projectLocalDataSource.deleteByUserId(userId);
    
    // Then delete user
    await localDataSource.delete(userId);
    await remoteDataSource.delete(userId);
    
    return const Right(unit);
  } catch (e) {
    return Left(UserFailure.deletionError(e.toString()));
  }
}
```

## Performance Benchmarks
Expected performance metrics:
- Read operation: <5ms for 1000 entries
- Write operation: <2ms per entry
- Batch write (100 items): <50ms
- Box open time: <100ms
- Memory footprint: <1MB per 1000 entries (without LazyBox)

## Security Checklist
- [ ] No API keys or secrets in Hive boxes
- [ ] Sensitive data encrypted with HiveAES
- [ ] Encryption keys stored in flutter_secure_storage
- [ ] Box files not exposed in backup/exports
- [ ] User data isolated per user (multi-tenant)
