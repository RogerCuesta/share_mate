# 🚀 Guía de Inicio Rápido

Esta guía te ayudará a comenzar a usar los agentes AI en tu proyecto Flutter.

## 📋 Pre-requisitos

- Flutter SDK 3.24+
- Dart 3.4+
- Editor de código (VS Code o Android Studio)
- Claude Desktop o acceso a Claude.ai

## 🔧 Configuración Inicial

### 1. Instalar Dependencias

```bash
cd flutter_project_agents
flutter pub get
```

### 2. Verificar Instalación

```bash
flutter doctor
dart --version
flutter --version
```

### 3. Ejecutar el Proyecto Base

```bash
flutter run
```

Deberías ver una pantalla simple con "Ready to start!".

## 🤖 Usando los Agentes

### Método 1: Usando Claude Desktop con Project

1. Abre Claude Desktop
2. Crea un nuevo Project llamado "Flutter App Development"
3. Agrega la carpeta del proyecto como Knowledge
4. Sube los archivos de agentes desde `.claude/agents/`

### Método 2: Usando Claude.ai

1. Ve a claude.ai
2. Inicia una nueva conversación
3. Sube los archivos de agentes que necesites
4. Referéncialos con `@` en tus mensajes

## 📝 Ejemplo Práctico: Crear Feature de Tareas

### Paso 1: Llamar al Agente Principal

```
@flutter-feature-architect

Necesito crear un feature completo de gestión de tareas (Task Manager) con las siguientes funcionalidades:

1. Crear nueva tarea con título y descripción
2. Marcar tarea como completada/pendiente
3. Eliminar tarea
4. Listar todas las tareas
5. Persistencia local con Hive
6. Offline-first

Aplica Clean Architecture estrictamente.
```

### Paso 2: El Agente Coordinará

El agente automáticamente llamará a los sub-agentes:

```
Coordinando sub-agentes para el feature:

✓ @domain-layer-specialist
  - Task entity (Freezed)
  - CreateTask, UpdateTask, DeleteTask, GetTaskList use cases
  - TaskRepository interface
  - TaskFailure sealed class

✓ @clean-architecture-validator
  - Validando estructura de capas
  - Sin violaciones detectadas

✓ @data-layer-specialist
  - TaskModel con HiveType (typeId: 0)
  - TaskLocalDataSource (Hive)
  - TaskRemoteDataSource (API mock)
  - TaskRepositoryImpl

✓ @riverpod-state-architect
  - taskListProvider
  - taskFormProvider
  - Providers de dependency injection

✓ @hive-database-auditor
  - TypeAdapter registrado correctamente
  - Box lifecycle validado
  - No conflictos de typeId

✓ @ui-component-builder
  - TaskListScreen
  - TaskFormDialog
  - TaskTile widget
  - EmptyState y ErrorState

✓ @patrol-test-engineer
  - Tests unitarios para use cases
  - Tests de widget para UI
  - Tests de integración con Patrol
```

### Paso 3: Generar Código

Después de recibir todos los archivos del agente:

```bash
# Generar TypeAdapters, Providers, Freezed
flutter pub run build_runner build --delete-conflicting-outputs

# O en modo watch
flutter pub run build_runner watch
```

### Paso 4: Ejecutar y Probar

```bash
# Ejecutar la app
flutter run

# Ejecutar tests
flutter test

# Ejecutar tests de integración
patrol test
```

## 🔍 Preparar para Producción

### Llamar al Agente de Quality

```
@flutter-devops-quality-guardian

Revisar el feature de Task Manager antes de producción. Necesito:
- Validación de código
- Coverage de tests
- Auditoría de Hive
- Security check
- Performance analysis
```

### El Agente Generará un Reporte

```
Production Readiness Report:

✅ Code Quality: 0 errors, 3 warnings
⚠️  Test Coverage: 76% (necesita 80%+)
✅ Hive Audit: Todo correcto
✅ Security: Sin vulnerabilidades
✅ Performance: 14ms avg rendering

Blockers:
1. Incrementar test coverage (+4%)

Estimated fix time: 1 hour
```

## 📂 Estructura de Archivos Generados

Después de crear el feature de tareas, tendrás:

```
lib/
├── core/
│   ├── di/
│   │   └── injection.dart              # DI providers
│   └── storage/
│       ├── hive_service.dart           # Ya existe
│       └── hive_type_ids.dart          # Actualizado con task = 0
├── features/
│   └── tasks/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── task_local_datasource.dart
│       │   │   └── task_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── task_model.dart
│       │   │   └── task_model.g.dart   # Generado
│       │   └── repositories/
│       │       └── task_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── task.dart
│       │   │   └── task.freezed.dart   # Generado
│       │   ├── failures/
│       │   │   ├── task_failure.dart
│       │   │   └── task_failure.freezed.dart
│       │   ├── repositories/
│       │   │   └── task_repository.dart
│       │   └── usecases/
│       │       ├── create_task.dart
│       │       ├── update_task.dart
│       │       ├── delete_task.dart
│       │       └── get_task_list.dart
│       └── presentation/
│           ├── providers/
│           │   ├── task_provider.dart
│           │   ├── task_provider.g.dart  # Generado
│           │   ├── task_form_provider.dart
│           │   └── task_form_provider.g.dart
│           ├── screens/
│           │   └── task_list_screen.dart
│           └── widgets/
│               ├── task_tile.dart
│               ├── task_form_dialog.dart
│               ├── empty_state.dart
│               └── error_state.dart
└── main.dart                           # Actualizado
```

## 🎯 Próximos Pasos

1. **Agregar más features**: Repite el proceso con otros features
2. **Configurar CI/CD**: Usar `@ci-cd-pipeline-engineer`
3. **Setup de flavors**: Usar `@build-configuration-expert`
4. **Optimización**: Usar `@performance-auditor` periódicamente

## 💡 Tips Importantes

### Code Generation

Siempre ejecuta después de crear nuevos archivos:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Registrar TypeAdapters

Actualiza `lib/core/storage/hive_service.dart`:

```dart
static Future<void> init() async {
  await Hive.initFlutter();
  
  // Registrar TODOS los TypeAdapters
  Hive.registerAdapter(TaskModelAdapter());
  // Hive.registerAdapter(UserModelAdapter());
  
  // Abrir TODAS las boxes
  await Hive.openBox<TaskModel>('taskBox');
  // await Hive.openBox<UserModel>('userBox');
}
```

### TypeIds Únicos

Actualiza `lib/core/storage/hive_type_ids.dart` ANTES de crear modelos:

```dart
class HiveTypeIds {
  static const int task = 0;      // Ya asignado
  static const int user = 10;     // Próximo feature
  static const int project = 20;  // Otro feature
}
```

## 🐛 Troubleshooting

### Error: "TypeAdapter not found"

```bash
# Regenerar código
flutter pub run build_runner build --delete-conflicting-outputs

# Verificar que el adapter está registrado en HiveService.init()
```

### Error: "Provider not found"

```bash
# Regenerar providers
flutter pub run build_runner build --delete-conflicting-outputs

# Verificar imports de .g.dart
```

### Tests fallan

```bash
# Limpiar y regenerar
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📚 Recursos Adicionales

- [README Principal](README.md)
- [Agentes Disponibles](.claude/agents/)
- [Documentación de Riverpod](https://riverpod.dev/)
- [Documentación de Hive](https://docs.hivedb.dev/)
- [Documentación de Patrol](https://patrol.leancode.co/)

---

**¡Listo para empezar! 🚀**
