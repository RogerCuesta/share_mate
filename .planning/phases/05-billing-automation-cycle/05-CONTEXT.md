# Phase 5: Billing Automation Cycle - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase implementa la rutina automatizada de cobro del MVP R1: recordatorios locales T-24h por suscripción activa, reprogramación automática al reabrir app/migrar dispositivo y reinicio de ciclo en backend con reconciliación consistente en cliente.

Incluye `BILL-01`, `BILL-02` y `BILL-03`. No incluye centro completo de notificaciones, nuevas capacidades colaborativas ni restyle global (Phase 6).

</domain>

<decisions>
## Implementation Decisions

### Recordatorios T-24h (BILL-01)
- Regla temporal: notificación exactamente 24 horas antes del vencimiento local de cada suscripción.
- Cobertura: aplica a suscripciones activas mensuales y anuales (cada una según su próximo vencimiento).
- Si hay varios cobros el mismo día: una notificación por suscripción (no digest agrupado).
- Contenido mínimo del aviso: servicio + monto + vencimiento.

### Reprogramación automática (BILL-02)
- Reprogramar al iniciar app, volver a foreground y tras cambios relevantes de suscripción.
- Si una suscripción pasa a cancelada/pausada/eliminada, se limpian sus notificaciones pendientes al instante.
- Si cambia la zona horaria del dispositivo, recalcular programación futura con la zona local actual.
- Política anti-duplicados: máximo un recordatorio enviado por ciclo y suscripción.

### Reinicio mensual por backend + reconciliación (BILL-03)
- Reset de estados a `pendiente` al iniciar el nuevo ciclo de cada suscripción (por `dueDate`/anchor de la suscripción), no por día global fijo.
- Regla por tipo de ciclo: mensual y anual se resetean en su propio ciclo natural.
- Se preserva historial del ciclo anterior; para el nuevo ciclo se resetea estado operativo de pago.
- En conflicto entre offline local y reset backend: backend canónico + reconciliación cliente con feedback breve no bloqueante.

### UX de automatización y feedback
- Superficies: señal discreta en Home + detalle operativo en Settings (Sync/automatización).
- Permisos denegados: banner no bloqueante con CTA a habilitar notificaciones.
- Tap en notificación: navegación directa al detalle de suscripción.
- Correcciones por reset/sync: snackbar breve (sin modal ni banner persistente).

### Claude's Discretion
- Microcopy exacto de notificaciones, banner de permisos y snackbar de reconciliación.
- Diseño final de densidad visual para bloques de estado en Home/Settings manteniendo lenguaje actual hasta Phase 6.
- Política exacta de retry interno del scheduler local cuando la API del SO falle temporalmente (sin romper anti-duplicados).

</decisions>

<specifics>
## Specific Ideas

- Mantener experiencia operativa y rápida: el usuario debe saber qué cobrar mañana sin abrir varios flujos.
- La automatización debe ser visible pero no invasiva: feedback claro, no bloqueante.
- Continuidad con fases 2 y 4: convergencia determinista y backend como fuente canónica en conflictos.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/features/settings/domain/entities/app_settings.dart`: ya define `paymentRemindersEnabled` para gobernar activación de recordatorios.
- `lib/features/settings/presentation/providers/settings_provider.dart`: punto actual para persistir toggles de notificaciones.
- `lib/main.dart`: ya tiene hooks de `app_start`/`app_resume` y timer foreground para orquestación periódica.
- `lib/core/sync/payment_sync_orchestrator.dart` + `lib/core/sync/payment_sync_queue.dart`: base de reconciliación determinista y manejo de conflictos.
- `lib/features/subscriptions/domain/entities/subscription.dart`: ya expone `billingCycle` y `dueDate` para cálculo de próximo aviso/ciclo.

### Established Patterns
- Offline-first con backend canónico en conflictos de ciclo (Phase 2).
- Feedback no bloqueante con badges/snackbars para eventos de sync y corrección (Phase 4).
- Riverpod + providers para estado reactivo; invalidaciones explícitas tras mutaciones.

### Integration Points
- `lib/features/settings/presentation/screens/settings_screen.dart`: sección de notificaciones está en placeholder, lista para conectar con comportamiento real.
- `lib/features/home/presentation/widgets/home_header.dart`: botón/badge de notificaciones con TODO para proveedor real.
- `supabase/migrations/`: aún no hay migración de cron para reset de ciclo; Phase 5 debe añadir contrato backend correspondiente.
- `lib/features/subscriptions/presentation/providers/sync_status_provider.dart` y reconciliación de pagos: punto de enlace para avisos de corrección tras reset.

</code_context>

<deferred>
## Deferred Ideas

- Centro de notificaciones completo con bandeja/historial y contador real de no leídas.
- Configuración avanzada por usuario de franja horaria personalizada para recordatorios.
- Acciones avanzadas en notificación (snooze masivo, marcar pagado desde push) más allá del deep-link a detalle.

</deferred>

---

*Phase: 05-billing-automation-cycle*
*Context gathered: 2026-03-11*
