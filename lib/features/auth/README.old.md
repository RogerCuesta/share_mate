# Feature: Authentication (Auth)

## Descripción
Feature completo de autenticación offline con Clean Architecture que permite registro, login, persistencia de sesión y logout.

## Estado: ✅ COMPLETADO (Fase 1 - Offline)

## Arquitectura

### Capa de Dominio (Domain Layer)
Contiene la lógica de negocio pura, sin dependencias de frameworks.

#### Entidades
- **User** ([user.dart](domain/entities/user.dart))
  - Propiedades: `id`, `email`, `fullName`, `createdAt`
  - Lógica: validación de email, obtención de iniciales

- **AuthSession** ([auth_session.dart](domain/entities/auth_session.dart))
  - Propiedades: `userId`, `token`, `expiresAt`, `createdAt`
  - Lógica: verificación de expiración, validación de sesión

#### Repositorio (Interfaz)
- **AuthRepository** ([auth_repository.dart](domain/repositories/auth_repository.dart))
  - Define el contrato para operaciones de autenticación
  - Usa `Either<Failure, Success>` para manejo funcional de errores
  - Contiene todas las definiciones de `AuthFailure`

#### Use Cases
1. **RegisterUser** ([register_user.dart](domain/usecases/register_user.dart))
   - Valida email único
   - Valida formato de email y fortaleza de password
   - Registra nuevo usuario

2. **LoginUser** ([login_user.dart](domain/usecases/login_user.dart))
   - Valida credenciales
   - Crea sesión de autenticación

3. **LogoutUser** ([logout_user.dart](domain/usecases/logout_user.dart))
   - Limpia sesión actual

4. **GetCurrentUser** ([get_current_user.dart](domain/usecases/get_current_user.dart))
   - Recupera usuario autenticado actual

5. **CheckAuthStatus** ([check_auth_status.dart](domain/usecases/check_auth_status.dart))
   - Verifica si hay sesión activa válida

### Capa de Datos (Data Layer)
Implementa los repositorios y maneja persistencia.

#### Modelos
- **UserModel** ([user_model.dart](data/models/user_model.dart))
  - TypeId: 10 (Hive)
  - Conversión: Entity ↔ Model ↔ JSON

- **UserCredentialsModel** ([user_credentials_model.dart](data/models/user_credentials_model.dart))
  - TypeId: 12 (Hive)
  - Almacena password hasheado con SHA-256

- **AuthSessionModel** ([auth_session_model.dart](data/models/auth_session_model.dart))
  - Solo en memoria y secure storage (NO en Hive)
  - Conversión: Entity ↔ Model ↔ JSON

#### Data Sources

**UserLocalDataSource** ([user_local_datasource.dart](data/datasources/user_local_datasource.dart))
- Storage: **Hive**
- Boxes: `users`, `credentials`
- Funciones:
  - Guardar/obtener usuarios
  - Verificar credenciales
  - Hash de passwords (SHA-256)

**AuthLocalDataSource** ([auth_local_datasource.dart](data/datasources/auth_local_datasource.dart))
- Storage: **flutter_secure_storage**
- Funciones:
  - Guardar/obtener sesión
  - Generar tokens (UUID v4)
  - Validar sesión
  - Expiración: 30 días

#### Repositorio (Implementación)
- **AuthRepositoryImpl** ([auth_repository_impl.dart](data/repositories/auth_repository_impl.dart))
  - Coordina UserLocalDataSource y AuthLocalDataSource
  - Implementa lógica de registro y login
  - Maneja errores con Either<Failure, Success>

### Capa de Presentación (Presentation Layer)

#### Providers (Riverpod)

**Dependency Providers** ([auth_dependency_providers.dart](presentation/providers/auth_dependency_providers.dart))
- Provee data sources, repository y use cases
- Inyección de dependencias con Riverpod

**AuthProvider** ([auth_provider.dart](presentation/providers/auth_provider.dart))
- Estado global de autenticación
- Estados: `initial`, `loading`, `authenticated`, `unauthenticated`, `error`
- Funciones: `checkAuth()`, `setAuthenticated()`, `logout()`

**LoginFormProvider** ([login_form_provider.dart](presentation/providers/login_form_provider.dart))
- Maneja estado del formulario de login
- Validación de campos
- Submit con feedback de errores

**RegisterFormProvider** ([register_form_provider.dart](presentation/providers/register_form_provider.dart))
- Maneja estado del formulario de registro
- Validación de campos (incluye confirmación de password)
- Submit con feedback de errores

#### Screens

**LoginScreen** ([login_screen.dart](presentation/screens/login_screen.dart))
- Formulario de login con Material 3
- Campos: email, password
- Validación en tiempo real
- Navegación a RegisterScreen

**RegisterScreen** ([register_screen.dart](presentation/screens/register_screen.dart))
- Formulario de registro con Material 3
- Campos: fullName, email, password, confirmPassword
- Validación en tiempo real
- Auto-login después de registro exitoso

## Seguridad

### ✅ Implementado
- Password hasheado con SHA-256 (crypto package)
- Passwords NUNCA guardados en plain-text
- Session token en flutter_secure_storage (NO en Hive)
- Validación de email único
- Validación de formato de email
- Password mínimo 8 caracteres
- Token generado con UUID v4

### 🔄 Para Mejorar en Futuro
- Usar bcrypt o argon2 en lugar de SHA-256
- Añadir salt al hash
- Validar complejidad de password (mayúsculas, números, símbolos)
- Implementar rate limiting para intentos de login
- 2FA (Two-Factor Authentication)

## Integración con Hive

### TypeIds Usados
Definidos en [hive_type_ids.dart](../../core/storage/hive_type_ids.dart):
- `10`: UserModel
- `12`: UserCredentialsModel (usando `authToken` typeId)

### Boxes Creados
- `users`: Almacena UserModel
- `credentials`: Almacena UserCredentialsModel con passwords hasheados

### Inicialización
```dart
// En HiveService.init()
Hive.registerAdapter(UserModelAdapter());
Hive.registerAdapter(UserCredentialsModelAdapter());

final userDataSource = UserLocalDataSourceImpl();
await userDataSource.init();
```

## Flujo de Autenticación

### Registro
1. Usuario llena formulario → RegisterFormProvider
2. Validación de campos en provider
3. Submit → RegisterUser use case
4. Validación en dominio (email, password)
5. Repository verifica email único
6. Hash de password con SHA-256
7. Guardar UserModel en Hive
8. Guardar UserCredentialsModel en Hive
9. Auto-login → LoginUser use case
10. Crear AuthSession (token UUID, expira en 30 días)
11. Guardar sesión en secure storage
12. Actualizar AuthProvider con usuario autenticado

### Login
1. Usuario llena formulario → LoginFormProvider
2. Validación de campos en provider
3. Submit → LoginUser use case
4. Repository verifica credenciales (email + password hasheado)
5. Si válido, crear AuthSession
6. Guardar sesión en secure storage
7. Actualizar AuthProvider con usuario autenticado

### Check Auth (al iniciar app)
1. App inicia → main.dart → AuthProvider.checkAuth()
2. CheckAuthStatus verifica si existe sesión en secure storage
3. Verifica que sesión no esté expirada
4. Verifica que usuario aún exista en Hive
5. Si todo válido, cargar usuario → AuthProvider (authenticated)
6. Si no, → AuthProvider (unauthenticated) → LoginScreen

### Logout
1. Usuario presiona botón logout
2. AuthProvider.logout() → LogoutUser use case
3. Eliminar sesión de secure storage
4. AuthProvider → unauthenticated
5. Navegar a LoginScreen

## Preparación para Supabase (Fase 2)

### Estructura Lista para API
- Modelos tienen `fromJson` y `toJson`
- Repositorio usa interfaz (fácil swap de implementación)
- Data sources separados (local vs remote)

### Próximos Pasos para Supabase
1. Crear `AuthRemoteDataSource` con Supabase client
2. Crear `AuthRepositoryImpl` híbrido (local + remote)
3. Implementar sincronización offline/online
4. Migrar passwords a Supabase Auth
5. Usar Supabase tokens en lugar de UUID local

## Testing

### Para Implementar
- Unit tests para use cases
- Unit tests para repository
- Widget tests para screens
- Integration tests para flujo completo

## Uso

### Registro
```dart
Navigator.of(context).pushNamed('/register');
```

### Login
```dart
Navigator.of(context).pushNamed('/login');
```

### Obtener Usuario Actual
```dart
final authState = ref.watch(authProvider);
authState.when(
  authenticated: (user) => Text(user.fullName),
  unauthenticated: () => LoginScreen(),
  // ...
);
```

### Logout
```dart
await ref.read(authProvider.notifier).logout();
```

## Dependencias Usadas

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  freezed_annotation: ^2.4.4
  dartz: ^0.10.1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.2.2
  crypto: ^3.0.3
  uuid: ^4.3.3

dev_dependencies:
  build_runner: ^2.4.8
  freezed: ^2.5.2
  hive_generator: ^2.0.1
```

## Comandos Útiles

```bash
# Generar código (freezed, hive)
flutter pub run build_runner build --delete-conflicting-outputs

# Limpiar y regenerar
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## Notas Importantes

1. **Passwords**: Actualmente usando SHA-256. En producción usar bcrypt o argon2
2. **Tokens**: UUID local. Cambiar a Supabase JWT cuando integres API
3. **Sesión**: Expira en 30 días. Configurable en `AuthLocalDataSourceImpl._sessionDurationDays`
4. **Email**: Convertido a lowercase antes de guardar
5. **Un usuario a la vez**: Implementación actual soporta un solo usuario logueado

## Archivo Creado
📅 **Fecha**: 2025-12-13
👤 **Creado por**: Claude Sonnet 4.5 con AI Agents + Vibe Coding
