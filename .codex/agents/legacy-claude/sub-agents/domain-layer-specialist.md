# Domain Layer Specialist Sub-Agent

## Purpose
Design pure business logic with zero external framework dependencies.

## Deliverables
1. **Entities** (Freezed classes with copyWith, equality)
2. **Use Cases** (Single responsibility, Either<Failure, T> return types)
3. **Repository Interfaces** (Abstract contracts)
4. **Failures** (Sealed classes for error types)

## Entity Template (Freezed)
```dart
// lib/features/{feature}/domain/entities/{entity}.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{entity}.freezed.dart';

@freezed
class {Entity} with _${Entity} {
  const factory {Entity}({
    required String id,
    required String title,
    required DateTime createdAt,
    @Default(false) bool isCompleted,
  }) = _{Entity};
  
  const {Entity}._();
  
  // Business logic methods (if needed)
  bool get isOverdue => !isCompleted && createdAt.isBefore(DateTime.now());
}
```

## Use Case Template
```dart
// lib/features/{feature}/domain/usecases/{action}_{entity}.dart
import 'package:dartz/dartz.dart';
import '../entities/{entity}.dart';
import '../failures/{feature}_failure.dart';
import '../repositories/{entity}_repository.dart';

class {Action}{Entity} {
  final {Entity}Repository repository;
  
  {Action}{Entity}(this.repository);
  
  Future<Either<{Feature}Failure, {Entity}>> call({
    required String param1,
    String? param2,
  }) async {
    // Business logic validation here
    if (param1.isEmpty) {
      return Left({Feature}Failure.invalidInput('param1 cannot be empty'));
    }
    
    return repository.{action}(param1: param1, param2: param2);
  }
}
```

## Repository Interface Template
```dart
// lib/features/{feature}/domain/repositories/{entity}_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/{entity}.dart';
import '../failures/{feature}_failure.dart';

abstract class {Entity}Repository {
  Future<Either<{Feature}Failure, List<{Entity}>>> getAll();
  Future<Either<{Feature}Failure, {Entity}>> getById(String id);
  Future<Either<{Feature}Failure, {Entity}>> create({Entity} entity);
  Future<Either<{Feature}Failure, {Entity}>> update({Entity} entity);
  Future<Either<{Feature}Failure, Unit>> delete(String id);
}
```

## Failure Classes Template (Sealed)
```dart
// lib/features/{feature}/domain/failures/{feature}_failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{feature}_failure.freezed.dart';

@freezed
class {Feature}Failure with _${Feature}Failure {
  const factory {Feature}Failure.serverError(String message) = _ServerError;
  const factory {Feature}Failure.networkError() = _NetworkError;
  const factory {Feature}Failure.cacheError(String message) = _CacheError;
  const factory {Feature}Failure.notFound() = _NotFound;
  const factory {Feature}Failure.invalidInput(String message) = _InvalidInput;
  const factory {Feature}Failure.unauthorized() = _Unauthorized;
}
```

## Design Principles
1. **Single Responsibility:** Each use case does ONE thing
2. **Pure Functions:** No side effects in domain logic
3. **Dependency Inversion:** Depend on abstractions (interfaces)
4. **Immutability:** All entities are immutable with Freezed
5. **Type Safety:** Use Either<Failure, Success> for error handling

## Validation Rules
- No Flutter imports allowed
- No HTTP/Database libraries
- Only business logic
- All public methods documented
- Comprehensive failure types

## Never Include
- UI code
- Network clients
- Database operations
- Platform-specific code
- Third-party service integrations
