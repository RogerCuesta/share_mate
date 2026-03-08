# Phase 2: Offline Sync Reliability Core - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase define una sincronizacion offline determinista entre estado local optimista y backend, asegurando convergencia confiable con retry/backoff, manejo de conflictos y visibilidad de estado para el usuario sin exponer datos sensibles.

</domain>

<decisions>
## Implementation Decisions

### Conflictos entre local optimista y backend
- La fuente de verdad es backend por ciclo cuando existe conflicto (no local-last-write).
- La frontera de ciclo se define por `due_date` local de la suscripcion (no mes UTC global).
- Si una operacion en cola llega a un ciclo ya cerrado: `no-op` de negocio + registro de auditoria de conflicto.
- La reconciliacion se ejecuta en `app resume`, despues de escrituras remotas exitosas y con intervalo corto en foreground.

### Retry, backoff y fallos terminales
- Politica base: 5 intentos con backoff exponencial + jitter.
- Clasificacion de errores:
- `4xx` no recuperables -> terminal (excepto casos explicitamente transitorios si se modelan).
- `5xx` y errores de red -> transitorios con retry.
- Al agotar reintentos, la operacion pasa a cola dead-letter y la cola principal continua.
- Feedback al usuario en terminales: badge no bloqueante + accion manual de recuperacion.

### Estado de sincronizacion y privacidad
- Modelo UX: `Sincronizado` / `Pendiente` / `Requiere accion` + timestamp de ultima sync exitosa.
- Superficies de UI: Home (badge global), detalle de suscripcion (estado contextual), Settings (vista completa y acciones).
- Politica de logs: sin PII ni importes; registrar solo metadata tecnica (id interno de operacion, tipo de accion, retries, clase de error).
- Acciones manuales: `Reintentar todo` y `Limpiar solo terminales` (no limpiar cola completa por defecto).

### Claude's Discretion
- Parametros exactos de backoff/jitter (ventanas de tiempo concretas) manteniendo 5 intentos.
- Copy final de estados y mensajes de error en UI.
- Estructura exacta de almacenamiento de auditoria/dead-letter mientras respete privacidad y trazabilidad.

</decisions>

<specifics>
## Specific Ideas

- Se prioriza convergencia cross-device por encima de preservar ciegamente la ultima intencion local cuando el ciclo mensual ya avanzo.
- La visibilidad de sync debe ser util operativamente, no tecnica: clara para el usuario y accionable sin bloquear el flujo.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/sync/payment_sync_queue.dart`: cola local ya implementada con `enqueue`, `getPending`, `markSynced`, `incrementRetry`.
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`: ya hace optimistic update y encola operaciones al fallar remoto (`markAsPaid`, `markAllAsPaid`, `unmark`).
- `lib/features/subscriptions/presentation/providers/payment_provider.dart`: punto existente para invalidacion de providers y potencial exposicion de estado de sync en UI.

### Established Patterns
- Offline-first en repositorios de suscripciones: local primero + fallback remoto.
- Uso de Riverpod para estado y refresh reactivo de pantallas.
- Manejo de fallos por tipos de `SubscriptionFailure` y `AsyncValue`/state unions en presentation.

### Integration Points
- Falta worker/orquestador de drenado de cola: hoy se inicializa en `lib/main.dart` pero no se procesa automaticamente.
- Integrar reconciliacion y drenado con ciclo de vida de app (resume/foreground) y operaciones remotas exitosas.
- Conectar estado agregado de cola/dead-letter a Home, detalle de suscripcion y Settings.
- Preparar ganchos para validacion de conflictos contra estado backend por ciclo antes de aplicar operaciones en cola.

</code_context>

<deferred>
## Deferred Ideas

None - discussion stayed within phase scope.

</deferred>

---

*Phase: 02-offline-sync-reliability-core*
*Context gathered: 2026-03-08*
