# Dependency Injection con Riverpod Generator

Este directorio contiene la configuración de inyección de dependencias usando `riverpod_generator` con anotaciones `@riverpod`.

## 📁 Archivos

- **`injection.dart`**: Definición de providers con anotaciones `@riverpod`
- **`injection.g.dart`**: Código generado automáticamente por `riverpod_generator` (no editar)

## 🏗️ Arquitectura

### Providers Generados

Todos los providers se definen usando la anotación `@riverpod` y el código se genera automáticamente con `build_runner`.

**Ventajas:**
- ✅ Menos boilerplate
- ✅ Type-safe references entre providers
- ✅ Auto-dispose por defecto
- ✅ Mejor detección de errores en compilación
- ✅ Sintaxis moderna y declarativa

### Estructura de Providers

```dart
@riverpod
SupabaseClient supabaseClient(Ref ref) {
  return SupabaseService.client;
}
```

El generador crea automáticamente:
- `supabaseClientProvider` - El provider que se usa en la app
- Tipos de referencia para type-safety

## 🔧 Uso en Main.dart

Para providers que necesitan inicialización asíncrona (como los data sources), usamos **provider overrides**:

```dart
void main() async {
  // Initialize services
  await HiveService.init();
  await SupabaseService.init();

  // Initialize singleton data sources
  final userLocalDataSource = UserLocalDataSourceImpl();
  await userLocalDataSource.init();

  final authLocalDataSource = AuthLocalDataSourceImpl();

  // Run app with overrides
  runApp(
    ProviderScope(
      overrides: [
        userLocalDataSourceProvider.overrideWithValue(userLocalDataSource),
        authLocalDataSourceProvider.overrideWithValue(authLocalDataSource),
      ],
      child: const MyApp(),
    ),
  );
}
```

## 📦 Providers Disponibles

### Supabase
- `supabaseClientProvider` - Cliente de Supabase

### Auth Feature - Data Sources
- `userLocalDataSourceProvider` - Hive data source (singleton con override)
- `authLocalDataSourceProvider` - Secure storage data source (singleton con override)
- `authRemoteDataSourceProvider` - Supabase auth data source

### Auth Feature - Repository
- `authRepositoryProvider` - Repository de autenticación

### Auth Feature - Use Cases
- `registerUserProvider` - Caso de uso para registro
- `loginUserProvider` - Caso de uso para login
- `logoutUserProvider` - Caso de uso para logout
- `getCurrentUserProvider` - Caso de uso para obtener usuario actual
- `checkAuthStatusProvider` - Caso de uso para verificar autenticación

## 🔄 Regenerar Código

Cuando modificas `injection.dart`, regenera el código con:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 📚 Referencia

- [Riverpod Generator](https://riverpod.dev/docs/concepts/about_code_generation)
- [Migration Guide](https://riverpod.dev/docs/migration/from_state_notifier)
- [Best Practices](https://riverpod.dev/docs/essentials/first_request)

## 🎯 Próximos Pasos

Para agregar nuevas features:

1. Define providers en `injection.dart` con `@riverpod`
2. Ejecuta `build_runner build`
3. Usa los providers generados en tu código
4. Si necesitas singletons con inicialización, usa overrides en `main.dart`
