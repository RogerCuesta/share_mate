# Flutter Project with AI Agents - Vibe Coding

Este proyecto utiliza una arquitectura de agentes para desarrollo Flutter siguiendo Clean Architecture y principios de "vibe coding".

## 🤖 Arquitectura de Agentes

### Agentes Principales

#### 1. **Flutter Feature Architect** (`.claude/agents/flutter-feature-architect.md`)
Coordina el desarrollo de features completas llamando a sub-agentes especializados.

**Uso:**
```
@flutter-feature-architect 
Necesito crear un feature de gestión de tareas con sync offline
```

#### 2. **Flutter DevOps & Quality Guardian** (`.claude/agents/flutter-devops-quality-guardian.md`)
Asegura calidad de código, testing y preparación para producción.

**Uso:**
```
@flutter-devops-quality-guardian
Revisar el feature de tareas antes de release a producción
```

### Sub-Agentes Especializados

Los agentes principales coordinan estos sub-agentes automáticamente:

#### Arquitectura & Dominio
- `@clean-architecture-validator` - Valida separación de capas
- `@domain-layer-specialist` - Crea entidades y use cases
- `@data-layer-specialist` - Implementa repositorios y Hive

#### Estado & UI
- `@riverpod-state-architect` - Providers con code generation
- `@ui-component-builder` - Widgets Material 3

#### Base de Datos
- `@hive-database-auditor` - Audita implementación de Hive

#### Testing & Calidad
- `@patrol-test-engineer` - Tests unitarios y widget
- `@patrol-integration-specialist` - Tests E2E con Patrol
- `@test-coverage-enforcer` - Asegura cobertura 80%+
- `@performance-auditor` - Identifica bottlenecks
- `@code-quality-inspector` - Lints y code smells

#### DevOps
- `@build-configuration-expert` - Flavors y build configs
- `@ci-cd-pipeline-engineer` - GitHub Actions / GitLab CI
- `@dependency-guardian` - Gestión de paquetes
- `@security-auditor` - Vulnerabilidades de seguridad
- `@crash-analytics-investigator` - Firebase Crashlytics

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── di/                    # Riverpod providers de DI
│   ├── errors/                # Base failure classes
│   ├── network/              # HTTP client (Dio)
│   ├── storage/
│   │   ├── hive_service.dart     # Inicialización de Hive
│   │   └── hive_type_ids.dart    # TypeIds centralizados
│   └── utils/                # Extensions, constants
├── features/
│   ├── auth/                 # ✅ Authentication feature (COMPLETED)
│   │   ├── README.md         # Auth documentation
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_local_datasource.dart    # Session storage
│   │   │   │   └── user_local_datasource.dart    # User CRUD
│   │   │   ├── models/       # UserModel, SessionModel, etc.
│   │   │   └── repositories/ # AuthRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/     # User, AuthSession
│   │   │   ├── repositories/ # AuthRepository interface
│   │   │   └── usecases/     # Register, Login, Logout, etc.
│   │   └── presentation/
│   │       ├── providers/    # AuthProvider, FormProviders
│   │       ├── screens/      # Login, Register
│   │       └── widgets/      # AuthTextField, AuthButton, etc.
│   └── {feature_name}/       # Future features follow same structure
│       ├── data/
│       │   ├── datasources/  # Local (Hive) y Remote (API)
│       │   ├── models/       # DTOs con TypeAdapters
│       │   └── repositories/ # Implementaciones
│       ├── domain/
│       │   ├── entities/     # Freezed models
│       │   ├── failures/     # Sealed error classes
│       │   ├── repositories/ # Interfaces abstractas
│       │   └── usecases/     # Business logic
│       └── presentation/
│           ├── providers/    # Riverpod state
│           ├── screens/      # Pantallas completas
│           └── widgets/      # Componentes reusables
├── routing/
│   └── app_router.dart       # GoRouter config with auth guards
└── main.dart
```

## 🚀 Workflow de Desarrollo

### Crear un Nuevo Feature

```
Usuario: @flutter-feature-architect
Crear feature de autenticación con email/password y persistencia local

Agente Principal:
├─ Llamando @domain-layer-specialist
│  └─ Crear User entity, LoginUseCase, AuthRepository interface
├─ Llamando @clean-architecture-validator
│  └─ Validar estructura de capas
├─ Llamando @data-layer-specialist
│  └─ Implementar Hive TypeAdapter, AuthRepositoryImpl
├─ Llamando @riverpod-state-architect
│  └─ Crear AuthProvider, LoginFormProvider
├─ Llamando @hive-database-auditor
│  └─ Validar TypeAdapter registration, encryption
├─ Llamando @ui-component-builder
│  └─ Crear LoginScreen, SignupScreen
└─ Llamando @patrol-test-engineer
   └─ Tests de login flow completo
```

### Preparar para Producción

```
Usuario: @flutter-devops-quality-guardian
Preparar feature de autenticación para release

Agente Principal:
├─ Llamando @code-quality-inspector (dart analyze)
├─ Llamando @test-coverage-enforcer (coverage ≥80%)
├─ Llamando @hive-database-auditor (encryption, performance)
├─ Llamando @security-auditor (vulnerabilidades)
├─ Llamando @performance-profiler (bottlenecks)
├─ Llamando @patrol-integration-specialist (E2E tests)
└─ Llamando @ci-cd-pipeline-engineer (pipeline status)

Resultado: Production Readiness Score + Blockers
```

## ✨ Features Implementados

### 🔐 Authentication (v1.0.0 - COMPLETED)

Sistema completo de autenticación con persistencia local.

**Funcionalidades:**
- ✅ Registro de usuarios con validación
- ✅ Login con email/password
- ✅ Gestión de sesiones (30 días)
- ✅ Persistencia segura (FlutterSecureStorage + Hive)
- ✅ Material 3 UI con animaciones Hero
- ✅ Auto-redirect basado en estado de auth
- ✅ Validación de formularios en tiempo real
- ✅ Indicador de fortaleza de contraseña

**Tech Stack:**
- Clean Architecture (3 capas)
- Riverpod para state management
- Hive para almacenamiento de usuarios
- SecureStorage para tokens de sesión
- SHA-256 para hashing de contraseñas
- GoRouter para navegación con guards

**Documentación:** [lib/features/auth/README.md](lib/features/auth/README.md)

**Estado:** ✅ Listo para desarrollo (⚠️ Pendiente: tests completos y encriptación de Hive)

---

## 🛠️ Tech Stack

- **Framework:** Flutter 3.24+
- **State Management:** Riverpod 2.5+ (Code Generation)
- **Local DB:** Hive 2.2+
- **Immutability:** Freezed
- **Navigation:** GoRouter 13.2+
- **Secure Storage:** flutter_secure_storage 9.2+
- **HTTP Client:** Dio
- **Testing:** Patrol
- **UI:** Material 3

## 📝 Comandos Importantes

### Code Generation
```bash
# Generar providers, Freezed, Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode para desarrollo
flutter pub run build_runner watch
```

### Testing
```bash
# Unit tests
flutter test

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Patrol integration tests
patrol test
```

### Build
```bash
# Debug
flutter run

# Release (Android)
flutter build apk --release --flavor prod

# Release (iOS)
flutter build ios --release --flavor prod
```

## 🎯 Principios de Vibe Coding

1. **Especialización de Agentes:** Cada agente tiene una responsabilidad única
2. **Coordinación Clara:** Los agentes principales orquestan, no implementan
3. **Reducción de Alucinaciones:** Contexto limitado por agente especializado
4. **Trazabilidad:** Claro quién hizo qué cambio
5. **Quality Gates:** DevOps Guardian como gate keeper

## 📊 Quality Gates

Antes de producción, todos estos deben pasar:

- ✅ Code Quality: 0 errors, <5 warnings
- ✅ Test Coverage: ≥80% overall, ≥90% domain
- ✅ Security: No critical vulnerabilities
- ✅ Performance: <16ms frame rendering
- ✅ Hive: Proper TypeAdapters, encryption, lifecycle
- ✅ CI/CD: All pipeline stages green

## 🔐 Security Checklist

- [ ] No hardcoded API keys
- [ ] Sensitive data encrypted (Hive with HiveAES)
- [ ] Tokens in flutter_secure_storage
- [ ] SSL pinning enabled
- [ ] Input validation on all forms

## 📚 Recursos

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Riverpod Docs](https://riverpod.dev/)
- [Hive Docs](https://docs.hivedb.dev/)
- [Patrol Docs](https://patrol.leancode.co/)
- [Material 3](https://m3.material.io/)

---

**Desarrollado con Vibe Coding usando AI Agents** 🤖✨
