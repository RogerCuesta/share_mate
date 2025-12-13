# Data Layer Specialist Sub-Agent

## Purpose
Implement repositories, data sources, and DTOs with Hive for offline-first architecture.

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
