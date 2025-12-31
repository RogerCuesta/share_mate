# Data Layer Specialist Sub-Agent

## Purpose
Implement repositories, data sources, and DTOs with Hive for offline-first architecture.

## Using Context7 MCP for Latest Data Layer APIs

**CRITICAL:** Always verify Hive, Supabase, and Dart APIs with Context7 before implementing data layer.

### Critical Queries for Context7:
```
- "Latest Hive TypeAdapter code generation and HiveField syntax"
- "Current Supabase Flutter SDK API for CRUD operations"
- "Hive encryption with HiveAES latest implementation"
- "Supabase RLS policies and security best practices"
- "Latest PostgrestException error handling in Supabase"
- "Hive box lifecycle management and best practices"
- "Supabase realtime subscriptions latest API"
- "Dart code generation with build_runner latest commands"
```

### Before Writing Data Code:
1. Query Context7 for latest Hive and Supabase package versions and APIs
2. Verify TypeAdapter annotation syntax and code generation
3. Check Supabase client methods and error handling patterns
4. Validate offline-first repository implementation strategies

## Deliverables
1. **Hive TypeAdapters** (for all domain entities)
2. **Repository Implementations** (with Hive caching)
3. **DTOs/Models** (HiveObject extensions with HiveFields)
4. **Data Mappers** (toEntity/fromEntity converters)
5. **API Data Sources** (HTTP clients with error handling)

## Hive TypeAdapter Template
```dart
// lib/features/{feature}/data/models/{entity}_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/{entity}.dart';

part '{entity}_model.g.dart';

@HiveType(typeId: 0) // Use centralized HiveTypeIds class
class {Entity}Model extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final DateTime createdAt;
  
  @HiveField(3, defaultValue: false)
  final bool isCompleted;

  {Entity}Model({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.isCompleted,
  });

  // To Domain Entity
  {Entity} toEntity() {
    return {Entity}(
      id: id,
      title: title,
      createdAt: createdAt,
      isCompleted: isCompleted,
    );
  }

  // From Domain Entity
  factory {Entity}Model.fromEntity({Entity} entity) {
    return {Entity}Model(
      id: entity.id,
      title: entity.title,
      createdAt: entity.createdAt,
      isCompleted: entity.isCompleted,
    );
  }
  
  // From JSON (API response)
  factory {Entity}Model.fromJson(Map<String, dynamic> json) {
    return {Entity}Model(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
  
  // To JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'is_completed': isCompleted,
    };
  }
}
```

## Repository Implementation Template (Offline-First)
```dart
// lib/features/{feature}/data/repositories/{entity}_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../domain/entities/{entity}.dart';
import '../../domain/failures/{feature}_failure.dart';
import '../../domain/repositories/{entity}_repository.dart';
import '../datasources/{entity}_local_datasource.dart';
import '../datasources/{entity}_remote_datasource.dart';

class {Entity}RepositoryImpl implements {Entity}Repository {
  final {Entity}LocalDataSource localDataSource;
  final {Entity}RemoteDataSource remoteDataSource;
  
  {Entity}RepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<{Feature}Failure, List<{Entity}>>> getAll() async {
    try {
      // Try remote first
      final remoteModels = await remoteDataSource.getAll();
      
      // Cache in Hive
      await localDataSource.cacheAll(remoteModels);
      
      return Right(remoteModels.map((m) => m.toEntity()).toList());
    } catch (e) {
      // Fallback to local cache
      try {
        final cachedModels = await localDataSource.getAll();
        return Right(cachedModels.map((m) => m.toEntity()).toList());
      } catch (localError) {
        return Left({Feature}Failure.cacheError(localError.toString()));
      }
    }
  }

  @override
  Future<Either<{Feature}Failure, {Entity}>> getById(String id) async {
    try {
      // Check cache first
      final cached = await localDataSource.getById(id);
      if (cached != null) {
        return Right(cached.toEntity());
      }
      
      // Fetch from remote
      final remote = await remoteDataSource.getById(id);
      await localDataSource.create(remote);
      
      return Right(remote.toEntity());
    } catch (e) {
      return Left({Feature}Failure.notFound());
    }
  }

  @override
  Future<Either<{Feature}Failure, {Entity}>> create({Entity} entity) async {
    try {
      final model = {Entity}Model.fromEntity(entity);
      
      // Save locally first (optimistic update)
      await localDataSource.create(model);
      
      // Sync to remote
      final remoteModel = await remoteDataSource.create(model);
      
      // Update local with server ID
      await localDataSource.update(remoteModel);
      
      return Right(remoteModel.toEntity());
    } catch (e) {
      return Left({Feature}Failure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<{Feature}Failure, {Entity}>> update({Entity} entity) async {
    try {
      final model = {Entity}Model.fromEntity(entity);
      
      await localDataSource.update(model);
      final updated = await remoteDataSource.update(model);
      
      return Right(updated.toEntity());
    } catch (e) {
      return Left({Feature}Failure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<{Feature}Failure, Unit>> delete(String id) async {
    try {
      await localDataSource.delete(id);
      await remoteDataSource.delete(id);
      return const Right(unit);
    } catch (e) {
      return Left({Feature}Failure.serverError(e.toString()));
    }
  }
}
```

## Local DataSource Template (Hive)
```dart
// lib/features/{feature}/data/datasources/{entity}_local_datasource.dart
import 'package:hive/hive.dart';
import '../models/{entity}_model.dart';

abstract class {Entity}LocalDataSource {
  Future<List<{Entity}Model>> getAll();
  Future<{Entity}Model?> getById(String id);
  Future<void> create({Entity}Model model);
  Future<void> update({Entity}Model model);
  Future<void> delete(String id);
  Future<void> cacheAll(List<{Entity}Model> models);
  Future<void> clear();
}

class {Entity}LocalDataSourceImpl implements {Entity}LocalDataSource {
  static const String boxName = '{entity}Box';
  
  Box<{Entity}Model> get _box => Hive.box<{Entity}Model>(boxName);

  @override
  Future<List<{Entity}Model>> getAll() async {
    return _box.values.toList();
  }

  @override
  Future<{Entity}Model?> getById(String id) async {
    return _box.get(id);
  }

  @override
  Future<void> create({Entity}Model model) async {
    await _box.put(model.id, model);
  }

  @override
  Future<void> update({Entity}Model model) async {
    await _box.put(model.id, model);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> cacheAll(List<{Entity}Model> models) async {
    final Map<String, {Entity}Model> entries = {
      for (var model in models) model.id: model
    };
    await _box.putAll(entries);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
```

## Remote DataSource Template
```dart
// lib/features/{feature}/data/datasources/{entity}_remote_datasource.dart
import 'package:dio/dio.dart';
import '../models/{entity}_model.dart';

abstract class {Entity}RemoteDataSource {
  Future<List<{Entity}Model>> getAll();
  Future<{Entity}Model> getById(String id);
  Future<{Entity}Model> create({Entity}Model model);
  Future<{Entity}Model> update({Entity}Model model);
  Future<void> delete(String id);
}

class {Entity}RemoteDataSourceImpl implements {Entity}RemoteDataSource {
  final Dio client;
  static const String baseUrl = '/api/{entities}';
  
  {Entity}RemoteDataSourceImpl({required this.client});

  @override
  Future<List<{Entity}Model>> getAll() async {
    final response = await client.get(baseUrl);
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => {Entity}Model.fromJson(json)).toList();
  }

  @override
  Future<{Entity}Model> getById(String id) async {
    final response = await client.get('$baseUrl/$id');
    return {Entity}Model.fromJson(response.data);
  }

  @override
  Future<{Entity}Model> create({Entity}Model model) async {
    final response = await client.post(baseUrl, data: model.toJson());
    return {Entity}Model.fromJson(response.data);
  }

  @override
  Future<{Entity}Model> update({Entity}Model model) async {
    final response = await client.put(
      '$baseUrl/${model.id}',
      data: model.toJson(),
    );
    return {Entity}Model.fromJson(response.data);
  }

  @override
  Future<void> delete(String id) async {
    await client.delete('$baseUrl/$id');
  }
}
```

## Critical Hive Practices
1. **TypeId Management:** Use centralized HiveTypeIds class
2. **Migration Strategy:** Use defaultValue in @HiveField for new fields
3. **Box Lifecycle:** Open in HiveService.init(), reference via getter
4. **Batch Operations:** Use putAll() for multiple writes
5. **Encryption:** Use HiveAES for sensitive data

## Code Generation Commands
```bash
# Generate Hive TypeAdapters
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for development
flutter pub run build_runner watch
```

## ═══════════════════════════════════════════════════════════════
## SUPABASE INTEGRATION (After Hive Implementation)
## ═══════════════════════════════════════════════════════════════

## CRITICAL: Offline-First Strategy
**ALWAYS implement Hive first, then add Supabase integration**
1. ✅ Hive models + TypeAdapters (offline storage)
2. ✅ LocalDataSource implementation (100% working offline)
3. ✅ Test offline functionality completely
4. ✅ THEN add Supabase RemoteDataSource
5. ✅ Update Repository to use both (remote-first read, optimistic write)

## Supabase RemoteDataSource Template

```dart
// lib/features/{feature}/data/datasources/{entity}_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/{entity}_model.dart';

/// Exception thrown when {entity} remote operations fail
class {Entity}RemoteException implements Exception {
  final String message;
  {Entity}RemoteException(this.message);

  @override
  String toString() => '{Entity}RemoteException: $message';
}

/// Remote data source for {entity} operations using Supabase
abstract class {Entity}RemoteDataSource {
  Future<List<{Entity}Model>> getAll(String userId);
  Future<{Entity}Model> getById(String id);
  Future<{Entity}Model> create({Entity}Model model);
  Future<{Entity}Model> update({Entity}Model model);
  Future<void> delete(String id);
}

/// Implementation of {Entity}RemoteDataSource using Supabase
class {Entity}RemoteDataSourceImpl implements {Entity}RemoteDataSource {
  final SupabaseClient _client;

  {Entity}RemoteDataSourceImpl({required SupabaseClient client})
      : _client = client;

  @override
  Future<List<{Entity}Model>> getAll(String userId) async {
    try {
      print('🔍 [{Entity}RemoteDS] Fetching all for user: $userId');

      final response = await _client
          .from('{entities}')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      print('📦 [{Entity}RemoteDS] Found ${(response as List).length} items');

      final List<dynamic> data = response as List<dynamic>;
      final items = data
          .map((json) => {Entity}Model.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [{Entity}RemoteDS] Successfully fetched ${items.length} items');
      return items;
    } on PostgrestException catch (e) {
      print('❌ [{Entity}RemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw {Entity}RemoteException(
        'Database error fetching {entities}: ${e.message}',
      );
    } catch (e) {
      print('❌ [{Entity}RemoteDS] Unexpected error: $e');
      throw {Entity}RemoteException(
        'Failed to fetch {entities}: ${e.toString()}',
      );
    }
  }

  @override
  Future<{Entity}Model> getById(String id) async {
    try {
      print('🔍 [{Entity}RemoteDS] Fetching by ID: $id');

      final response = await _client
          .from('{entities}')
          .select()
          .eq('id', id)
          .single();

      print('✅ [{Entity}RemoteDS] Successfully fetched item');
      return {Entity}Model.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      print('❌ [{Entity}RemoteDS] PostgrestException: ${e.message}');
      throw {Entity}RemoteException(
        'Database error fetching {entity}: ${e.message}',
      );
    } catch (e) {
      print('❌ [{Entity}RemoteDS] Unexpected error: $e');
      throw {Entity}RemoteException(
        'Failed to fetch {entity}: ${e.toString()}',
      );
    }
  }

  @override
  Future<{Entity}Model> create({Entity}Model model) async {
    try {
      print('🔍 [{Entity}RemoteDS] Creating new item');

      final response = await _client
          .from('{entities}')
          .insert(model.toJson())
          .select()
          .single();

      print('✅ [{Entity}RemoteDS] Successfully created: ${response['id']}');
      return {Entity}Model.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      print('❌ [{Entity}RemoteDS] PostgrestException: ${e.message}');
      throw {Entity}RemoteException(
        'Database error creating {entity}: ${e.message}',
      );
    } catch (e) {
      print('❌ [{Entity}RemoteDS] Unexpected error: $e');
      throw {Entity}RemoteException(
        'Failed to create {entity}: ${e.toString()}',
      );
    }
  }

  @override
  Future<{Entity}Model> update({Entity}Model model) async {
    try {
      print('🔍 [{Entity}RemoteDS] Updating item: ${model.id}');

      final response = await _client
          .from('{entities}')
          .update(model.toJson())
          .eq('id', model.id)
          .select()
          .single();

      print('✅ [{Entity}RemoteDS] Successfully updated');
      return {Entity}Model.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      print('❌ [{Entity}RemoteDS] PostgrestException: ${e.message}');
      throw {Entity}RemoteException(
        'Database error updating {entity}: ${e.message}',
      );
    } catch (e) {
      print('❌ [{Entity}RemoteDS] Unexpected error: $e');
      throw {Entity}RemoteException(
        'Failed to update {entity}: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      print('🔍 [{Entity}RemoteDS] Deleting item: $id');

      await _client.from('{entities}').delete().eq('id', id);

      print('✅ [{Entity}RemoteDS] Successfully deleted');
    } on PostgrestException catch (e) {
      print('❌ [{Entity}RemoteDS] PostgrestException: ${e.message}');
      throw {Entity}RemoteException(
        'Database error deleting {entity}: ${e.message}',
      );
    } catch (e) {
      print('❌ [{Entity}RemoteDS] Unexpected error: $e');
      throw {Entity}RemoteException(
        'Failed to delete {entity}: ${e.toString()}',
      );
    }
  }
}
```

## Repository Implementation (Offline-First with Supabase)

```dart
// lib/features/{feature}/data/repositories/{entity}_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../domain/entities/{entity}.dart';
import '../../domain/failures/{feature}_failure.dart';
import '../../domain/repositories/{entity}_repository.dart';
import '../datasources/{entity}_local_datasource.dart';
import '../datasources/{entity}_remote_datasource.dart';

class {Entity}RepositoryImpl implements {Entity}Repository {
  final {Entity}LocalDataSource localDataSource;
  final {Entity}RemoteDataSource remoteDataSource;

  {Entity}RepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<{Feature}Failure, List<{Entity}>>> getAll(String userId) async {
    try {
      // 1. Try remote first (ensures fresh data)
      final remoteModels = await remoteDataSource.getAll(userId);

      // 2. Cache in Hive for offline access
      await localDataSource.cacheAll(remoteModels);

      // 3. Return domain entities
      return Right(remoteModels.map((m) => m.toEntity()).toList());
    } on {Entity}RemoteException catch (e) {
      // 4. Fallback to local cache on network error
      try {
        final cachedModels = await localDataSource.getAll();
        return Right(cachedModels.map((m) => m.toEntity()).toList());
      } catch (localError) {
        return Left({Feature}Failure.cacheError(localError.toString()));
      }
    } catch (e) {
      return Left({Feature}Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<{Feature}Failure, {Entity}>> getById(String id) async {
    try {
      // Check cache first for better performance
      final cached = await localDataSource.getById(id);
      if (cached != null) {
        // Return cached, but refresh in background
        _refreshInBackground(id);
        return Right(cached.toEntity());
      }

      // Fetch from remote if not in cache
      final remote = await remoteDataSource.getById(id);
      await localDataSource.create(remote);

      return Right(remote.toEntity());
    } on {Entity}RemoteException catch (e) {
      // Try cache on remote error
      final cached = await localDataSource.getById(id);
      if (cached != null) {
        return Right(cached.toEntity());
      }
      return Left({Feature}Failure.notFound());
    } catch (e) {
      return Left({Feature}Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<{Feature}Failure, {Entity}>> create({Entity} entity) async {
    try {
      final model = {Entity}Model.fromEntity(entity);

      // 1. Save locally first (optimistic update)
      await localDataSource.create(model);

      try {
        // 2. Sync to Supabase
        final remoteModel = await remoteDataSource.create(model);

        // 3. Update local with server-generated fields (id, timestamps)
        await localDataSource.update(remoteModel);

        return Right(remoteModel.toEntity());
      } on {Entity}RemoteException catch (e) {
        // If remote fails, entity is still saved locally
        // Mark for later sync if needed
        return Right(model.toEntity());
      }
    } catch (e) {
      return Left({Feature}Failure.createError(e.toString()));
    }
  }

  @override
  Future<Either<{Feature}Failure, {Entity}>> update({Entity} entity) async {
    try {
      final model = {Entity}Model.fromEntity(entity);

      // 1. Update locally first
      await localDataSource.update(model);

      try {
        // 2. Sync to Supabase
        final updated = await remoteDataSource.update(model);

        // 3. Update local with server response
        await localDataSource.update(updated);

        return Right(updated.toEntity());
      } on {Entity}RemoteException catch (e) {
        // If remote fails, update is still saved locally
        return Right(model.toEntity());
      }
    } catch (e) {
      return Left({Feature}Failure.updateError(e.toString()));
    }
  }

  @override
  Future<Either<{Feature}Failure, Unit>> delete(String id) async {
    try {
      // 1. Delete locally first
      await localDataSource.delete(id);

      try {
        // 2. Delete from Supabase
        await remoteDataSource.delete(id);
      } on {Entity}RemoteException catch (e) {
        // If remote delete fails, item is already removed locally
        // Could implement sync queue for deletion here
      }

      return const Right(unit);
    } catch (e) {
      return Left({Feature}Failure.deleteError(e.toString()));
    }
  }

  // Helper method for background refresh
  void _refreshInBackground(String id) async {
    try {
      final remote = await remoteDataSource.getById(id);
      await localDataSource.update(remote);
    } catch (e) {
      // Silently fail background refresh
    }
  }
}
```

## Supabase Schema Design Guidelines

### Basic Table Template
```sql
CREATE TABLE IF NOT EXISTS {entities} (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relationships
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Data Fields
  title TEXT NOT NULL,
  description TEXT,
  status TEXT CHECK (status IN ('active', 'inactive', 'completed')),

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_{entities}_owner_id ON {entities}(owner_id);
CREATE INDEX idx_{entities}_created_at ON {entities}(created_at DESC);

-- RLS Policies
ALTER TABLE {entities} ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own {entities}"
  ON {entities} FOR SELECT
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can create their own {entities}"
  ON {entities} FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own {entities}"
  ON {entities} FOR UPDATE
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own {entities}"
  ON {entities} FOR DELETE
  USING (auth.uid() = owner_id);

-- Auto-update trigger
CREATE TRIGGER update_{entities}_updated_at
  BEFORE UPDATE ON {entities}
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## Critical Supabase Practices
1. **Always use UUIDs** for primary keys (compatible with Supabase auth.users)
2. **Enable RLS** on all tables to prevent data leaks
3. **Add indexes** on foreign keys and frequently queried columns
4. **Use CHECK constraints** for enum-like fields
5. **Handle PostgrestException** separately from generic errors
6. **Log operations** with emojis for easy debugging
7. **Test RLS policies** with different user contexts

## Integration with Dependency Injection

```dart
// lib/core/di/injection.dart

@riverpod
{Entity}RemoteDataSource {entity}RemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return {Entity}RemoteDataSourceImpl(client: client);
}

@riverpod
{Entity}Repository {entity}Repository(Ref ref) {
  return {Entity}RepositoryImpl(
    localDataSource: ref.watch({entity}LocalDataSourceProvider),
    remoteDataSource: ref.watch({entity}RemoteDataSourceProvider),
  );
}
```

## Testing RemoteDataSource

```dart
// test/features/{feature}/data/datasources/{entity}_remote_datasource_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}

void main() {
  late {Entity}RemoteDataSourceImpl dataSource;
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
    dataSource = {Entity}RemoteDataSourceImpl(client: mockClient);
  });

  group('getAll', () {
    test('should return list of models when call succeeds', () async {
      // Arrange
      final mockResponse = [
        {'id': '1', 'title': 'Test', 'owner_id': 'user-1', 'created_at': '2024-01-01T00:00:00Z'},
      ];

      when(() => mockClient.from('{entities}')).thenReturn(mockBuilder);
      when(() => mockBuilder.select()).thenReturn(mockBuilder);
      when(() => mockBuilder.eq('owner_id', any())).thenReturn(mockBuilder);
      when(() => mockBuilder.order('created_at', ascending: false))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getAll('user-1');

      // Assert
      expect(result, isA<List<{Entity}Model>>());
      expect(result.length, 1);
    });

    test('should throw {Entity}RemoteException on PostgrestException', () async {
      // Arrange
      when(() => mockClient.from('{entities}')).thenThrow(
        PostgrestException(message: 'Error', code: '500'),
      );

      // Act & Assert
      expect(
        () => dataSource.getAll('user-1'),
        throwsA(isA<{Entity}RemoteException>()),
      );
    });
  });
}
```
