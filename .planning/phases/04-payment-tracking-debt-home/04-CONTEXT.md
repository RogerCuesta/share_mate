# Phase 4: Payment Tracking & Debt Home - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase cubre el seguimiento operativo de cobro en ciclo actual: cambiar estado `pendiente/pagado` por miembro desde detalle de suscripcion y reflejar en Home una lectura inmediata y consistente de deuda total a favor + proximo cobro.

No incluye automatizaciones mensuales/notificaciones (Phase 5) ni restyle global del design system (Phase 6).

</domain>

<decisions>
## Implementation Decisions

### Regla de deuda en Home (DASH-01/DASH-02)
- La metrica principal `Deuda total a favor` representa solo pendiente del ciclo actual (lo que terceros deben al owner en el mes/ciclo en curso).
- Los casos overdue se incluyen en esa cifra total y se marcan visualmente como vencidos (no formula separada).
- Al togglear pago en detalle, Home actualiza de forma optimista e inmediata (sin refresh manual).
- Si hay correccion por conflicto/sync, Home se ajusta al estado canonico y muestra aviso breve explicativo.

### Interaccion de pagos en detalle (PAYM-01/PAYM-02/PAYM-03)
- Interaccion principal: tap/checkbox con cambio inmediato + ventana de undo.
- El undo aplica tanto a accion individual como a accion masiva (`Mark all as paid`).
- Tras cambios de estado, los miembros pendientes deben priorizarse arriba de pagados para foco operativo.
- Ante fallo/reversion, se revierte estado visual y se comunica con snackbar breve (sin modal bloqueante).

### Bloque de "proximo cobro" en Home (DASH-01)
- Seleccion principal: el caso mas urgente (primero overdue con pendiente; si no, la `dueDate` mas cercana con deuda pendiente).
- Contenido minimo: servicio, monto pendiente y referencia temporal (overdue/hoy/en X dias).
- Si no hay deuda pendiente del ciclo actual: mostrar estado positivo `Todo al dia` con pendiente a favor en cero.
- Desempate entre candidatos de misma urgencia: mayor importe pendiente primero.

### Claude's Discretion
- Layout final del bloque KPI Home (jerarquia visual entre deuda total y proximo cobro) manteniendo consistencia con patrones actuales hasta Phase 6.
- Microcopy exacto de avisos/snackbars para correcciones de sync y estados vacios.
- Detalle final de animaciones/transiciones al reordenar pendientes/pagados sin sacrificar claridad.

</decisions>

<specifics>
## Specific Ideas

- El Home debe priorizar lectura financiera accionable en segundos: "cuanto me deben ahora" y "que cobro primero".
- La experiencia debe sentirse inmediata tras toggles, pero sin ocultar reconciliaciones de sync cuando ocurran.
- Se mantiene enfoque single-player: el owner controla el estado de cobro y necesita feedback claro, no colaborativo.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart`: toggle individual ya implementado con snackbar + undo.
- `lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart`: accion masiva `Mark All as Paid` existente.
- `lib/features/subscriptions/presentation/providers/payment_provider.dart`: invalida providers clave (`subscriptionMembers`, `subscriptionStats`, `monthlyStats`, `pendingPayments`) para refresh reactivo.
- `lib/features/home/presentation/screens/home_screen.dart` + `widgets/stats_cards.dart` + `widgets/action_required_section.dart`: base actual de deuda/pendientes en Home.
- `lib/features/subscriptions/presentation/providers/sync_status_provider.dart`: etiquetas canónicas de sync (`Synced`, `Pending`, `Requires action`) heredadas de Phase 2.

### Established Patterns
- Repositorio de suscripciones con estrategia optimistic local-first + cola offline (`PaymentSyncQueue`) + reconciliacion orquestada.
- Riverpod con providers async para Home (`monthlyStatsProvider`, `pendingPaymentsProvider`, `activeSubscriptionsProvider`).
- UX actual en detalle usa feedback con SnackBar y evita friccion de modales para acciones frecuentes.

### Integration Points
- `lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart`: punto para reordenado pendiente/pagado y feedback de errores/reversion.
- `lib/features/home/presentation/widgets/stats_cards.dart` y `active_subscriptions_section.dart`: punto para priorizar "deuda total" y construir bloque de "proximo cobro".
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`: ya contiene comportamiento PAYM-03 (optimistic + queue + sync) sobre el que se debe montar UX consistente.
- `lib/features/home/presentation/widgets/home_header.dart`: superficie existente para señal global de estado de sincronizacion sin duplicar reglas.

</code_context>

<deferred>
## Deferred Ideas

- Ninguna fuera de alcance en esta discusion.

</deferred>

---

*Phase: 04-payment-tracking-debt-home*
*Context gathered: 2026-03-10*
