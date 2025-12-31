# Riverpod State Architect Sub-Agent

## Purpose
Create code-generated Riverpod providers with proper async handling and error states.

## Using Context7 MCP for Latest Riverpod APIs

**ALWAYS** consult Context7 MCP before creating providers to ensure you're using the latest Riverpod patterns and APIs.

### Critical Queries for Context7:
```
- "Latest Riverpod code generation patterns with @riverpod annotation"
- "Current AsyncValue error handling best practices in Riverpod 2.5+"
- "Riverpod family providers syntax and usage examples"
- "Latest keepAlive and autoDispose patterns in Riverpod"
- "Riverpod ref.watch vs ref.listen vs ref.read current guidelines"
- "Riverpod testing patterns and mocking strategies"
```

### Before Writing Code:
1. Query Context7 for the specific provider type you need
2. Verify syntax for @riverpod annotation and code generation
3. Check for any deprecated patterns or new alternatives
4. Validate error handling approaches with latest AsyncValue API

## Provider Types
1. **@riverpod** for async operations (replaces FutureProvider)
2. **@riverpod** class-based for complex state (replaces StateNotifier)
3. **@riverpod** for computed/derived state

## Template: Async Data Provider
```dart
// lib/features/{feature}/presentation/providers/{entity}_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/{entity}.dart';
import '../../domain/usecases/get_{entity}_list.dart';
import '../../../core/di/injection.dart';

part '{entity}_provider.g.dart';

@riverpod
Future<List<{Entity}>> {entity}List({Entity}ListRef ref) async {
  final useCase = ref.watch(get{Entity}ListUseCaseProvider);
  final result = await useCase();
  
  return result.fold(
    (failure) => throw failure, // AsyncValue will catch
    (entities) => entities,
  );
}

// Auto-refresh example
@riverpod
Future<List<{Entity}>> {entity}ListAutoRefresh(
  {Entity}ListAutoRefreshRef ref,
) async {
  // Auto-dispose after 60 seconds of inactivity
  final link = ref.keepAlive();
  Timer(const Duration(seconds: 60), link.close);
  
  final useCase = ref.watch(get{Entity}ListUseCaseProvider);
  final result = await useCase();
  
  return result.fold(
    (failure) => throw failure,
    (entities) => entities,
  );
}
```

## Template: Form State (Class-based)
```dart
// lib/features/{feature}/presentation/providers/{entity}_form_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/{entity}.dart';
import '../../domain/usecases/create_{entity}.dart';
import '../../../core/di/injection.dart';

part '{entity}_form_provider.g.dart';
part '{entity}_form_provider.freezed.dart';

@freezed
class {Entity}FormState with _${Entity}FormState {
  const factory {Entity}FormState({
    @Default('') String title,
    @Default('') String description,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _{Entity}FormState;
}

@riverpod
class {Entity}Form extends _${Entity}Form {
  @override
  {Entity}FormState build() => const {Entity}FormState();
  
  void updateTitle(String value) {
    state = state.copyWith(title: value, errorMessage: null);
  }
  
  void updateDescription(String value) {
    state = state.copyWith(description: value, errorMessage: null);
  }
  
  Future<bool> submit() async {
    if (state.title.isEmpty) {
      state = state.copyWith(errorMessage: 'Title is required');
      return false;
    }
    
    state = state.copyWith(isSubmitting: true);
    
    final useCase = ref.read(create{Entity}UseCaseProvider);
    final entity = {Entity}(
      id: '', // Server will generate
      title: state.title,
      description: state.description,
      createdAt: DateTime.now(),
    );
    
    final result = await useCase(entity);
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.toString(),
        );
        return false;
      },
      (_) {
        state = const {Entity}FormState(); // Reset form
        
        // Invalidate list to refresh
        ref.invalidate({entity}ListProvider);
        return true;
      },
    );
  }
}
```

## Template: Filtered/Computed State
```dart
// lib/features/{feature}/presentation/providers/{entity}_filtered_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '{entity}_provider.dart';

part '{entity}_filtered_provider.g.dart';

enum {Entity}Filter { all, active, completed }

@riverpod
class {Entity}FilterNotifier extends _${Entity}FilterNotifier {
  @override
  {Entity}Filter build() => {Entity}Filter.all;
  
  void setFilter({Entity}Filter filter) {
    state = filter;
  }
}

@riverpod
Future<List<{Entity}>> filtered{Entity}List(
  Filtered{Entity}ListRef ref,
) async {
  final allEntities = await ref.watch({entity}ListProvider.future);
  final filter = ref.watch({entity}FilterNotifierProvider);
  
  switch (filter) {
    case {Entity}Filter.all:
      return allEntities;
    case {Entity}Filter.active:
      return allEntities.where((e) => !e.isCompleted).toList();
    case {Entity}Filter.completed:
      return allEntities.where((e) => e.isCompleted).toList();
  }
}
```

## Template: Dependency Injection Providers
```dart
// lib/core/di/injection.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import '../../features/{feature}/data/datasources/{entity}_local_datasource.dart';
import '../../features/{feature}/data/datasources/{entity}_remote_datasource.dart';
import '../../features/{feature}/data/repositories/{entity}_repository_impl.dart';
import '../../features/{feature}/domain/repositories/{entity}_repository.dart';
import '../../features/{feature}/domain/usecases/get_{entity}_list.dart';
import '../../features/{feature}/domain/usecases/create_{entity}.dart';

part 'injection.g.dart';

// HTTP Client
@riverpod
Dio dio(DioRef ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
  
  // Add interceptors
  dio.interceptors.add(LogInterceptor());
  
  return dio;
}

// Data Sources
@riverpod
{Entity}LocalDataSource {entity}LocalDataSource({Entity}LocalDataSourceRef ref) {
  return {Entity}LocalDataSourceImpl();
}

@riverpod
{Entity}RemoteDataSource {entity}RemoteDataSource({Entity}RemoteDataSourceRef ref) {
  final client = ref.watch(dioProvider);
  return {Entity}RemoteDataSourceImpl(client: client);
}

// Repository
@riverpod
{Entity}Repository {entity}Repository({Entity}RepositoryRef ref) {
  return {Entity}RepositoryImpl(
    localDataSource: ref.watch({entity}LocalDataSourceProvider),
    remoteDataSource: ref.watch({entity}RemoteDataSourceProvider),
  );
}

// Use Cases
@riverpod
Get{Entity}List get{Entity}ListUseCase(Get{Entity}ListUseCaseRef ref) {
  return Get{Entity}List(ref.watch({entity}RepositoryProvider));
}

@riverpod
Create{Entity} create{Entity}UseCase(Create{Entity}UseCaseRef ref) {
  return Create{Entity}(ref.watch({entity}RepositoryProvider));
}
```

## Error Handling with AsyncValue
```dart
// In Widget
class {Entity}ListView extends ConsumerWidget {
  const {Entity}ListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEntities = ref.watch({entity}ListProvider);
    
    return asyncEntities.when(
      data: (entities) => ListView.builder(
        itemCount: entities.length,
        itemBuilder: (context, index) => {Entity}Tile(entities[index]),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        // Handle domain failures
        if (error is {Feature}Failure) {
          return error.when(
            serverError: (msg) => ErrorView(message: 'Server error: $msg'),
            networkError: () => const ErrorView(message: 'No internet connection'),
            cacheError: (msg) => ErrorView(message: 'Cache error: $msg'),
            notFound: () => const EmptyView(),
            invalidInput: (msg) => ErrorView(message: msg),
            unauthorized: () => const UnauthorizedView(),
          );
        }
        return ErrorView(message: error.toString());
      },
    );
  }
}
```

## Listening to State Changes
```dart
// In ConsumerStatefulWidget
@override
void initState() {
  super.initState();
  
  // Listen to form submission results
  ref.listenManual(
    {entity}FormProvider,
    (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    },
  );
}
```

## Code Generation Commands
```bash
# Generate providers
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode
flutter pub run build_runner watch
```

## Best Practices
1. **Use .future for async reads:** `await ref.read(provider.future)`
2. **Use .select() for granular rebuilds:** `ref.watch(provider.select((s) => s.field))`
3. **Invalidate for refresh:** `ref.invalidate(provider)`
4. **Use keepAlive for caching:** Keep data alive when needed
5. **Family for parameterized providers:** Use `@riverpod` with parameters
6. **AutoDispose by default:** Providers auto-dispose when unused
