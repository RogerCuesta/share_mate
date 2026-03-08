# Requirements: Share Mate

**Defined:** 2026-03-08
**Core Value:** Saber en segundos quién te debe dinero este mes por cada suscripción, sin invitar a nadie ni depender de que otros usen la app.

## v1 Requirements

### Data Safety

- [ ] **SAFE-01**: La app no elimina suscripciones/contactos locales existentes durante arranque o migración.
- [ ] **SAFE-02**: Las migraciones locales son idempotentes, versionadas y se ejecutan una sola vez por versión.

### Security & Privacy

- [ ] **SECU-01**: Los datos locales de suscripciones/pagos/contactos están cifrados en reposo.
- [ ] **SECU-02**: Las operaciones sensibles de cuenta (incluido borrado) se ejecutan vía backend autorizado y no desde API admin en cliente.
- [ ] **SECU-03**: RLS en Supabase garantiza aislamiento total por `user_id` en lecturas/escrituras de datos de negocio.

### Catalog

- [ ] **CATA-01**: El usuario puede buscar y seleccionar servicios desde `service_templates` en Supabase.
- [ ] **CATA-02**: Al seleccionar plantilla se autocompletan nombre/logo/color en el formulario de alta.
- [ ] **CATA-03**: El catálogo queda cacheado localmente y usable sin bloquear la UI.

### Local Contacts

- [ ] **CNTC-01**: El usuario puede crear un contacto local (nombre + avatar/color) sin email ni invitación.
- [ ] **CNTC-02**: El usuario puede seleccionar/editar/eliminar contactos locales dentro del flujo de creación/edición de suscripción.

### Split & Billing Rules

- [ ] **SPLT-01**: El coste se divide automáticamente a partes iguales entre contactos seleccionados.
- [ ] **SPLT-02**: El split se recalcula correctamente al cambiar precio total o miembros.
- [ ] **SPLT-03**: Si el día de cobro no existe en el mes (p. ej. 31 en febrero), se normaliza al último día válido.

### Payment Tracking

- [ ] **PAYM-01**: En detalle de suscripción, cada contacto puede pasar entre estado `pendiente` y `pagado`.
- [ ] **PAYM-02**: El cambio de estado actualiza inmediatamente la UI local (optimistic update) y la deuda agregada en Home.
- [ ] **PAYM-03**: Si no hay red, el cambio de pago se encola y se sincroniza luego sin perder consistencia.

### Debt Dashboard

- [ ] **DASH-01**: Home muestra deuda total a favor y próximo cobro de forma prioritaria.
- [ ] **DASH-02**: Los totales en Home permanecen consistentes tras toggles, sincronización y reseteos de ciclo.

### Notifications & Monthly Cycle

- [ ] **BILL-01**: El sistema programa notificación local T-24h para cada suscripción activa.
- [ ] **BILL-02**: Las notificaciones se reprograman automáticamente al reabrir app/migrar dispositivo.
- [ ] **BILL-03**: El ciclo mensual reinicia estados a pendiente mediante cron backend y reconciliación en cliente.

### Offline Sync Reliability

- [ ] **SYNC-01**: La cola offline procesa operaciones con retry/backoff y manejo de fallos terminales.
- [ ] **SYNC-02**: La resolución de conflictos entre estado local optimista y reset mensual backend es determinista.
- [ ] **SYNC-03**: La app expone estado de sincronización sin filtrar datos sensibles en logs.

### UX Consistency (Flutter)

- [ ] **UX-01**: Pantallas núcleo (Home, Catálogo, Crear, Split, Detalle) siguen el design system `ui-ux-pro-max` persistido.
- [ ] **UX-02**: Nuevos componentes usan theming/tokens compartidos y evitan estilos hardcoded ad-hoc.

## v2 Requirements

### Monetization

- **MON-01**: Definir paywall con límite de grupos y desbloqueo por pago (RevenueCat).
- **MON-02**: Añadir métricas históricas de morosidad por contacto.

### Collaboration

- **COL-01**: Enviar invitaciones o links de confirmación de pago a terceros.
- **COL-02**: Permitir actualización de estado por parte de deudores desde app/web.

### Banking & Currency

- **BANK-01**: Integrar Open Banking para lectura de cargos reales.
- **CURR-01**: Soportar multidivisa con conversión y reporting.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Invitaciones multiusuario en R1 | MVP enfocado en modo single-player sin fricción |
| Pasarelas de pago integradas en R1 | Añade complejidad legal/técnica fuera del valor núcleo inicial |
| Open Banking en R1 | Alto esfuerzo y dependencias externas no críticas para validar propuesta |
| Multidivisa en R1 | No necesaria para validar uso principal del producto |
| Analítica avanzada de largo plazo en R1 | Prioridad es ritual de cobro operativo, no reporting profundo |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SAFE-01 | Phase 1 | Pending |
| SAFE-02 | Phase 1 | Pending |
| SECU-01 | Phase 1 | Pending |
| SECU-02 | Phase 1 | Pending |
| SECU-03 | Phase 1 | Pending |
| CATA-01 | Phase 3 | Pending |
| CATA-02 | Phase 3 | Pending |
| CATA-03 | Phase 3 | Pending |
| CNTC-01 | Phase 3 | Pending |
| CNTC-02 | Phase 3 | Pending |
| SPLT-01 | Phase 3 | Pending |
| SPLT-02 | Phase 3 | Pending |
| SPLT-03 | Phase 3 | Pending |
| PAYM-01 | Phase 4 | Pending |
| PAYM-02 | Phase 4 | Pending |
| PAYM-03 | Phase 4 | Pending |
| DASH-01 | Phase 4 | Pending |
| DASH-02 | Phase 4 | Pending |
| BILL-01 | Phase 5 | Pending |
| BILL-02 | Phase 5 | Pending |
| BILL-03 | Phase 5 | Pending |
| SYNC-01 | Phase 2 | Pending |
| SYNC-02 | Phase 2 | Pending |
| SYNC-03 | Phase 2 | Pending |
| UX-01 | Phase 6 | Pending |
| UX-02 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 26 total
- Mapped to phases: 26
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-08*
*Last updated: 2026-03-08 after roadmap phase mapping*
