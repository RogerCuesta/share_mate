# Share Mate

## What This Is

Share Mate es una app Flutter para gestionar suscripciones compartidas donde una sola persona paga y controla quién le debe en cada ciclo. El producto prioriza un flujo "single-player" sin fricción: contactos locales, split automático, estado de pago por miembro y recordatorios antes del cobro. Esta etapa busca cerrar completamente el MVP R1 definido en el PRD, aprovechando base funcional ya existente en el código.

## Core Value

Saber en segundos quién te debe dinero este mes por cada suscripción, sin invitar a nadie ni depender de que otros usen la app.

## Requirements

### Validated

- ✓ Flujo de autenticación con sesión persistente (registro/login/logout + guard de rutas) — existente
- ✓ Gestión base de suscripciones compartidas con arquitectura clean (`data/domain/presentation`) — existente
- ✓ Seguimiento de pagos por miembros en detalle de suscripción (marcar pagado/no pagado) — existente
- ✓ Gestión de contactos y shell de app con navegación principal (Home/Contacts/Analytics/Settings) — existente
- ✓ Persistencia local con Hive y sincronización remota con Supabase en repositorios offline-first — existente

### Active

- [ ] Catálogo de servicios desde Supabase (`service_templates`) con selección rápida durante alta
- [ ] Flujo completo de contactos locales "shadow users" (alta/selección/edición mínima) integrado en creación de suscripción
- [ ] Split simple a partes iguales robusto para todos los miembros seleccionados
- [ ] Estado de cobro por contacto (pagado/pendiente) con actualización inmediata del resumen de deuda en Home
- [ ] Dashboard Home centrado en "deuda total a favor" y próximo cobro
- [ ] Notificaciones locales T-24h por suscripción usando programación mensual
- [ ] Regla de ciclo mensual para reinicio a pendiente mediante cron en Supabase
- [ ] Diseño UI consistente para Flutter guiado por `ui-ux-pro-max` (design system persistido)

### Out of Scope

- Invitaciones multiusuario y colaboración en tiempo real — fuera del MVP R1, planificado para R3
- Pasarelas de pago integradas (Bizum/Stripe/etc.) — fuera de MVP, planificado en fases posteriores
- Paywall/monetización (RevenueCat) — fuera del cierre de R1, planificado para R2
- Open Banking y lectura bancaria automática — explícitamente excluido del MVP
- Multidivisa y conversiones FX — MVP con moneda única por locale

## Context

Proyecto brownfield Flutter con base funcional en `lib/features/auth`, `lib/features/subscriptions`, `lib/features/contacts` y `lib/features/settings`. Usa Riverpod + generación de código, Supabase como backend, Hive para almacenamiento local y GoRouter para navegación. Existe un mapa de código actualizado en `.planning/codebase/` que confirma arquitectura limpia y riesgos prioritarios (migraciones de arranque, cifrado local incompleto y robustez de sincronización). El PRD de referencia está en `/Users/rogerpersonal/Downloads/Plan de Producto para App de Suscripciones.md` y define el objetivo de completar MVP R1 con enfoque de extrema facilidad de uso.

## Constraints

- **Tech stack**: Mantener Flutter + Riverpod + Supabase + Hive — ya es la base del código y minimiza retrabajo
- **Arquitectura**: Respetar boundaries de Clean Architecture por feature — evita fuga de lógica al UI y regressions
- **Offline-first**: La app debe seguir operativa sin red y sincronizar en background — es requisito RNF1 del PRD
- **Privacidad**: Mantener aislamiento por usuario con RLS en Supabase — requisito RNF3 y seguridad de datos
- **Scope**: Priorizar cierre de MVP R1 antes de R2/R3 — enfoque en activar y retener al pagador principal
- **Diseño**: Aplicar design system generado con `ui-ux-pro-max` para pantallas Flutter — coherencia visual y velocidad de implementación

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Cerrar primero MVP R1 (sin adelantar monetización) | Reducir riesgo y entregar valor central antes de expandir alcance | — Pending |
| Reinicio mensual de estados de pago vía cron en Supabase | Mayor fiabilidad cross-device que sólo lógica local | — Pending |
| Moneda única por locale en MVP | Simplifica producto y evita complejidad multidivisa temprana | — Pending |
| Usar `ui-ux-pro-max` como fuente de verdad de UI (MASTER + overrides) | Acelera decisiones de diseño y mantiene consistencia en Flutter | — Pending |

---
*Last updated: 2026-03-08 after initialization*
