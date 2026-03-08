# Phase 1: Data Safety & Access Security - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase asegura que los datos del usuario sobreviven arranques y migraciones sin pérdida, quedan protegidos en reposo con cifrado local y se respetan los límites de acceso por cuenta. El foco es fiabilidad y seguridad de base, no nuevas capacidades de producto.

</domain>

<decisions>
## Implementation Decisions

### Migración de datos
- Las migraciones se ejecutarán por `schema_version` (no por cada arranque y no solo por versión de app), con control idempotente.
- Ante fallo de migración se aplica estrategia **fail-safe sin borrado**: no destruir datos, registrar estado de error y permitir reintento controlado.
- Antes de migrar boxes sensibles se crea **snapshot temporal** para recuperación.
- Primera ola de migración se limita a datos críticos R1: suscripciones, miembros, historial de pagos y cola de sincronización.

### Cifrado local
- Se cifrarán todas las boxes sensibles R1 en esta fase: suscripciones, miembros, historial de pagos, cola de sync y contactos locales.
- Se mantiene modelo de **clave maestra única por instalación** almacenada en secure storage, reforzando validación y manejo de errores.
- La migración de datos no cifrados a cifrados será **atómica con swap** (copiar-validar-reemplazar).
- Si falla la lectura/generación de clave se activa modo seguro: bloquear escritura, mostrar recuperación guiada y evitar fallback en claro.

### Claude's Discretion
- Estructura exacta de metadatos de migración (`schema_version`, flags de estado, checksum/validación).
- Diseño específico del flujo UX de recuperación guiada ante fallo de clave, manteniendo la política de no escritura en claro.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/storage/hive_service.dart`: ya soporta apertura de boxes con `encrypted: true` y gestión de clave maestra en `FlutterSecureStorage`.
- `lib/main.dart`: punto central de bootstrap para sustituir la migración destructiva actual (`_migrateSubscriptionBoxes`) por runner versionado.
- `lib/core/supabase/supabase_service.dart`: punto estable para operaciones autenticadas backend y validación de sesión.

### Established Patterns
- Arquitectura por features + Clean Architecture (`data/domain/presentation`) bajo `lib/features/*`.
- Inicialización ordenada de infraestructura en `main.dart` + overrides Riverpod para datasources singleton.
- Repositorios offline-first ya existentes en suscripciones; se puede extender sin romper contratos de dominio.

### Integration Points
- Reemplazar lógica de migración en `lib/main.dart` por un migrator versionado no destructivo.
- Activar cifrado al abrir boxes de suscripciones/contactos/sync usando `HiveService.openBox(..., encrypted: true)`.
- Corregir operación sensible de borrado de cuenta en `lib/features/settings/data/datasources/account_remote_datasource.dart` para backend autorizado.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-data-safety-access-security*
*Context gathered: 2026-03-08*
