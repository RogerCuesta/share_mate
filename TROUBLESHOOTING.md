# Troubleshooting Guide

## HiveError: The same instance of an HiveObject cannot be stored with two different keys

### Síntoma
Al intentar registrar o hacer login, aparece el error:
```
HiveError: The same instance of an HiveObject cannot be stored with two different keys
```

### Causa
Este error ocurría porque el `UserModel` se guardaba dos veces en el mismo box de Hive con diferentes claves:
1. Con `user.id` como clave
2. Con `'current_user_id'` como clave (guardando el mismo objeto)

### Solución Implementada
Se modificó `UserLocalDataSource` para guardar solo el ID del usuario actual en lugar del objeto completo:
- Ahora usa un box separado `Box<String>` para almacenar solo el ID
- El método `getCurrentUser()` obtiene el ID y luego busca el usuario en el box principal

### Cómo Limpiar Datos Corruptos

Si ya tienes datos corruptos en tu dispositivo/emulador, necesitas limpiarlos:

#### Opción 1: Limpiar desde código (Recomendado para desarrollo)

Agrega esta línea temporal en tu `main.dart` ANTES de inicializar la app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await EnvConfig.load();

  // Initialize services
  await SupabaseService.init();
  await HiveService.init();

  // 🔧 DESARROLLO: Limpia datos corruptos (comentar después de ejecutar una vez)
  await DevUtils.clearAllAuthData();

  // ... resto del código
}
```

**Importante**: Ejecuta la app UNA VEZ con esta línea, luego COMÉNTALA o ELIMÍNALA.

#### Opción 2: Limpiar desde Flutter DevTools

1. Abre Flutter DevTools
2. Ve a la pestaña "Storage"
3. Elimina todos los datos de la app

#### Opción 3: Desinstalar y reinstalar la app

```bash
# Para Android
flutter clean
flutter run

# Para iOS (si usas iOS)
flutter clean
cd ios && pod install && cd ..
flutter run
```

### Verificar que el Problema está Resuelto

Después de limpiar los datos:

1. Hot restart la app (no solo hot reload)
2. Intenta registrar un nuevo usuario
3. El registro debería funcionar sin errores
4. El usuario debería aparecer en Supabase
5. Deberías poder hacer login con ese usuario

### Utilidades de Desarrollo Disponibles

En `lib/core/utils/dev_utils.dart` tienes varios métodos útiles:

```dart
// Limpia todo (Hive + Secure Storage) - Recomendado
await DevUtils.clearAllAuthData();

// Solo limpia Hive
await DevUtils.clearHiveAuthData();

// Solo limpia Secure Storage
await DevUtils.clearSecureStorage();

// Borra TODO (¡cuidado!)
await DevUtils.nukeAllData();
```

## Problema: Usuario existe en Supabase pero no puede hacer login

### Síntoma
- El usuario se creó en Supabase
- Aparece en el panel de Supabase Auth
- Pero al intentar login aparece error de Hive

### Causa
Los datos locales de Hive están corruptos o desincronizados con Supabase.

### Solución

1. Limpia los datos locales usando `DevUtils.clearAllAuthData()`
2. Haz login (no registro) con las credenciales de Supabase
3. El sistema sincronizará automáticamente los datos de Supabase a Hive

## Debug Tips

### Ver contenido de Hive en desarrollo

Puedes añadir print statements temporales en `UserLocalDataSourceImpl`:

```dart
@override
Future<void> saveUser(UserModel user, String hashedPassword) async {
  print('💾 Saving user: ${user.id}');
  print('📧 Email: ${user.email}');
  print('🔑 Current users in box: ${_usersBox.keys.toList()}');

  // ... código existente
}
```

### Ver estado de autenticación

```dart
final currentUser = await userLocalDataSource.getCurrentUser();
print('👤 Current user: ${currentUser?.email ?? "none"}');
```

## Tests Pasando

Todos los tests deberían pasar después de los cambios:

```bash
flutter test
```

Resultado esperado: **80/80 tests passing** ✅
