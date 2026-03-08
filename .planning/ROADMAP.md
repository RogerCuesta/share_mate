# Roadmap: Share Mate

## Overview

Este roadmap cierra MVP R1 priorizando confianza operativa antes de automatización: primero seguridad de datos y sincronización confiable, después el flujo principal de creación y cobro (catálogo + contactos + split + estado de pago + Home), y por último automatizaciones mensuales y consistencia visual para entregar una experiencia rápida, estable y coherente.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Data Safety & Access Security** - Los datos del usuario sobreviven migraciones y quedan aislados/protegidos por diseño. (completed 2026-03-08)
- [ ] **Phase 2: Offline Sync Reliability Core** - La app converge de forma determinista entre estado local y backend.
- [ ] **Phase 3: Subscription Setup Flow** - Alta de suscripción completa con catálogo, contactos locales y split robusto.
- [ ] **Phase 4: Payment Tracking & Debt Home** - Seguimiento de cobro por contacto con impacto inmediato y consistente en Home.
- [ ] **Phase 5: Billing Automation Cycle** - Recordatorios T-24h y reseteo mensual reconciliado de estados.
- [ ] **Phase 6: UX System Consistency** - Pantallas núcleo y componentes quedan alineados al design system persistido.

## Phase Details

### Phase 1: Data Safety & Access Security
**Goal**: El usuario puede confiar en que sus datos no se pierden en arranque/migraciones y solo son accesibles por su cuenta.
**Depends on**: Nothing (first phase)
**Requirements**: SAFE-01, SAFE-02, SECU-01, SECU-02, SECU-03
**Success Criteria** (what must be TRUE):
  1. Tras actualizar o reiniciar la app, el usuario mantiene intactas sus suscripciones/contactos/pagos locales.
  2. Reabrir la app múltiples veces en la misma versión no duplica ni corrompe datos por migraciones repetidas.
  3. El usuario conserva su información local tras activar cifrado en reposo, sin perder acceso funcional a sus datos.
  4. Con dos cuentas distintas, cada usuario solo puede leer/escribir sus propios datos de negocio y las acciones sensibles de cuenta funcionan por backend autorizado.
**Plans**: TBD

### Phase 2: Offline Sync Reliability Core
**Goal**: Los cambios hechos sin red se aplican localmente y terminan sincronizando de forma predecible con el backend.
**Depends on**: Phase 1
**Requirements**: SYNC-01, SYNC-02, SYNC-03
**Success Criteria** (what must be TRUE):
  1. Si el usuario opera offline, sus cambios se encolan y se sincronizan automáticamente al volver la conexión.
  2. Ante fallos transitorios, la app reintenta sin intervención del usuario y evita pérdida silenciosa de operaciones.
  3. Cuando hay conflicto entre estado local optimista y reset mensual backend, el resultado final es estable y consistente en todos los dispositivos del usuario.
  4. El usuario puede ver el estado de sincronización de forma clara sin exposición de datos sensibles en logs.
**Plans**: TBD

### Phase 3: Subscription Setup Flow
**Goal**: El usuario completa de extremo a extremo la creación/edición de suscripciones compartidas con datos correctos desde el primer intento.
**Depends on**: Phase 1
**Requirements**: CATA-01, CATA-02, CATA-03, CNTC-01, CNTC-02, SPLT-01, SPLT-02, SPLT-03
**Success Criteria** (what must be TRUE):
  1. El usuario puede buscar un servicio en catálogo y al seleccionarlo se autocompletan nombre/logo/color en el formulario.
  2. El usuario puede crear, seleccionar, editar y eliminar contactos locales sin email/invitación durante la creación/edición de suscripción.
  3. El split se calcula automáticamente a partes iguales para todos los miembros seleccionados y se recalcula al cambiar importe o miembros.
  4. Si el día de cobro no existe en un mes concreto, el sistema lo normaliza al último día válido sin bloquear el flujo.
  5. El catálogo se puede usar desde caché local sin congelar la UI cuando hay mala conexión.
**Plans**: TBD

### Phase 4: Payment Tracking & Debt Home
**Goal**: El usuario controla quién pagó cada suscripción y ve de inmediato su deuda total agregada y próximo cobro.
**Depends on**: Phase 2, Phase 3
**Requirements**: PAYM-01, PAYM-02, PAYM-03, DASH-01, DASH-02
**Success Criteria** (what must be TRUE):
  1. En el detalle de suscripción, el usuario puede alternar cada contacto entre `pendiente` y `pagado`.
  2. Al cambiar estado de pago, la UI local responde al instante y Home actualiza la deuda agregada sin refresco manual.
  3. Si no hay red, el cambio de pago persiste localmente y, tras sincronizar, no aparecen divergencias en deuda ni estados.
  4. Home prioriza visualmente deuda total a favor y próximo cobro, manteniendo consistencia tras toggles, sync y resets.
**Plans**: TBD

### Phase 5: Billing Automation Cycle
**Goal**: La app automatiza la rutina mensual de cobro con recordatorios y reinicio de ciclo confiables.
**Depends on**: Phase 2, Phase 4
**Requirements**: BILL-01, BILL-02, BILL-03
**Success Criteria** (what must be TRUE):
  1. El usuario recibe una notificación local T-24h para cada suscripción activa.
  2. Al reabrir la app o migrar de dispositivo, las notificaciones se reprograman correctamente sin duplicados críticos.
  3. Al iniciar un nuevo ciclo mensual, los estados vuelven a `pendiente` por cron backend y el cliente refleja ese estado tras reconciliación.
**Plans**: TBD

### Phase 6: UX System Consistency
**Goal**: Las pantallas críticas del flujo de cobro presentan una experiencia visual uniforme basada en el design system acordado.
**Depends on**: Phase 3, Phase 4, Phase 5
**Requirements**: UX-01, UX-02
**Success Criteria** (what must be TRUE):
  1. Home, Catálogo, Crear, Split y Detalle se perciben como parte de un mismo sistema visual (tokens, tipografías, espaciado, componentes).
  2. Nuevos componentes reutilizan theming/tokens compartidos y los cambios de tema impactan de forma coherente en todas las pantallas núcleo.
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 1.1 → 1.2 → 2 → 2.1 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Data Safety & Access Security | 3/3 | Complete   | 2026-03-08 |
| 2. Offline Sync Reliability Core | 1/4 | In Progress | - |
| 3. Subscription Setup Flow | 0/TBD | Not started | - |
| 4. Payment Tracking & Debt Home | 0/TBD | Not started | - |
| 5. Billing Automation Cycle | 0/TBD | Not started | - |
| 6. UX System Consistency | 0/TBD | Not started | - |
