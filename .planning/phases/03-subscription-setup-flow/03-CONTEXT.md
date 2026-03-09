# Phase 3: Subscription Setup Flow - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase cubre el alta/edicion completa de suscripciones compartidas: seleccion de servicio desde catalogo, gestion de contactos locales dentro del flujo y reglas robustas de split/fecha para que el usuario configure correctamente una suscripcion desde el primer intento.

No incluye tracking de pago en detalle/Home ni automatizaciones mensuales (fases posteriores).

</domain>

<decisions>
## Implementation Decisions

### Catalogo de servicios (CATA-01/02/03)
- La seleccion de servicio se hara en un `sheet` buscable (no dropdown inline ni grid fija como flujo principal).
- Politica de datos: `cache-first` con refresco en segundo plano.
- Al seleccionar plantilla se autocompletan nombre/logo/color, pero el usuario puede editarlos antes de guardar.
- Frescura de cache: TTL de 24h + accion manual de refresh desde UI del catalogo.

### Contactos locales embebidos en alta/edicion (CNTC-01/02)
- El selector de miembros sera un `sheet` con tabs: `Seleccionar` contactos existentes y `Crear rapido`.
- Alta rapida de contacto en flujo: `nombre + color/avatar` (sin email obligatorio).
- Edicion/eliminacion en flujo aplican cambios en vivo sobre la seleccion actual.
- Si se intenta crear duplicado por nombre exacto, mostrar aviso y sugerir reutilizar contacto existente (con posibilidad de continuar bajo confirmacion).

### Reglas de split (SPLT-01/02)
- El owner siempre se incluye en el reparto (`totalMembers = owner + miembros seleccionados`).
- Regla de redondeo: los miembros reciben importe base redondeado y el residuo de centimos se asigna al owner.
- Recalculo en edicion: al cambiar precio o miembros.
- Cuando cambian miembros, se resetea estado de pago para mantener consistencia de ciclo.
- El preview de split debe mostrar desglose completo incluyendo la parte de `You`.

### Fecha de cobro mensual (SPLT-03)
- Si el dia objetivo no existe en un mes, se normaliza al ultimo dia valido de ese mes.
- Se mantiene el dia ancla original para meses siguientes (ej: 31 -> febrero 28/29 -> marzo vuelve a 31 si existe).
- Politica temporal de producto: manejo `date-only` en zona local del usuario (sin depender de hora UTC visible en UI).
- Mostrar hint contextual en el formulario: en meses cortos se usa el ultimo dia valido.

### Claude's Discretion
- Detalle final del componente de `sheet` (altura, animaciones, densidad de cards) respetando el design language vigente y el skill `ui-ux-pro-max`.
- Estrategia exacta de invalidacion/cache storage para catalogo mientras se mantenga TTL 24h + refresh manual.
- Microcopy final de mensajes de duplicado, normalizacion de fecha y estados vacios.

</decisions>

<specifics>
## Specific Ideas

- El flujo debe sentirse de baja friccion: crear suscripcion sin navegar fuera de la pantalla principal de alta/edicion.
- Se prioriza transparencia de calculo (preview y desglose visible) sobre ocultar detalles matematicos.
- Se mantiene la vision single-player: el owner controla todo el flujo y registra deuda a favor.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/features/subscriptions/presentation/widgets/service_icon_picker.dart`: picker visual ya existente (grid de `PredefinedServices`) reutilizable como fallback/local suggestions dentro del nuevo `sheet`.
- `lib/features/subscriptions/domain/entities/predefined_services.dart`: catalogo estatico actual (8 servicios) util como base offline inicial o fallback cuando no haya cache remota.
- `lib/features/subscriptions/presentation/widgets/members_list_section.dart` y `add_member_dialog.dart`: UI actual de miembros, util para migrar hacia selector de contactos embebido.
- `lib/features/contacts/presentation/providers/contacts_provider.dart`: CRUD existente para lista de contactos locales.

### Established Patterns
- Riverpod con `@riverpod` para estado/form providers y side effects de submit.
- Flujo de formulario centralizado en `create_group_subscription_form_provider.dart` con validacion, create/edit y recalc de miembros.
- UI actual usa componentes dark-theme custom con estilos hardcoded; fase 3 debe mantener coherencia funcional sin expandir scope de system-wide restyle (fase 6).

### Integration Points
- `lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart`: punto principal para incorporar `sheet` de catalogo y `sheet` de contactos.
- `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart`: punto de integracion para autocompletado desde plantilla, validacion de nuevos campos de contacto y reglas de split/fecha.
- `lib/features/contacts/domain/entities/add_contact_input.dart`: actualmente exige email; debe adaptarse al contrato de contact local sin email obligatorio para cumplir CNTC-01.
- Datasource/repositorio de catalogo desde Supabase (nuevo) debera conectarse a la capa `data/domain/presentation` del feature subscriptions sin romper flujo offline-first.

</code_context>

<deferred>
## Deferred Ideas

- Ninguna en esta discusion; el alcance se mantuvo dentro de la Phase 3.

</deferred>

---

*Phase: 03-subscription-setup-flow*
*Context gathered: 2026-03-08*
