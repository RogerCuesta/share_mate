# Phase 6: UX System Consistency - Context

**Gathered:** 2026-03-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Esta fase alinea las pantallas núcleo del MVP (`Home`, `Catalog`, `Create`, `Split`, `Detail`) y los componentes más repetidos al design system persistido del proyecto. El objetivo no es añadir nuevas capacidades, sino convertir un UI hoy consistente a nivel de producto pero irregular en ejecución en un sistema visual compartido, reusable y sin estilos hardcoded ad-hoc.

Incluye `UX-01` y `UX-02`. No incluye nuevos flujos funcionales, nuevas features de automatización ni expansión de alcance fuera de las superficies ya definidas en roadmap.

</domain>

<decisions>
## Implementation Decisions

### Dirección visual del sistema
- Se mantiene la base `dark` existente; Phase 6 no hace un rebranding completo ni cambia la personalidad del producto.
- La dirección deseada es `fintech claro`: moderna, precisa y confiable, con energía controlada en lugar de un look neón agresivo.
- El contraste objetivo es medio-alto: separación clara entre fondo, cards y acciones, pero sin exceso de glow o saturación.
- Gradientes, glow y recursos decorativos siguen existiendo, pero solo como acentos puntuales para hero surfaces, KPIs y CTAs clave.
- El sistema debe evolucionar el lenguaje actual, no reemplazarlo por uno sobrio-plano ni por un restyle radical de marca.

### Jerarquía y densidad en pantallas núcleo
- `Home` debe priorizar KPIs y deuda próxima como primer bloque visual; actividad y accesos secundarios quedan en segundo nivel.
- `Create` y `Split` deben sentirse compactos y guiados: menos bloques simultáneos, mejor agrupación y progresión directa.
- `Subscription Detail` debe abrir con un summary fuerte y dejar información secundaria en secciones claramente agrupadas debajo.
- Los bloques secundarios, helpers y texto explicativo deben reducirse de forma agresiva; la ayuda visible solo aparece cuando aporta contexto real.
- La app debe compartir una misma escala de densidad entre superficies: operativa, enfocada y sin que cada pantalla parezca de un sistema distinto.

### Componentes y patrones compartidos
- Cards y secciones deben converger a un único lenguaje base con variantes por énfasis, no a familias visuales aisladas por pantalla.
- La jerarquía de CTA debe ser estricta y reutilizable (`primary`, `secondary`, `ghost/tertiary`), evitando botones locales inventados.
- Banners, snackbars, empty states y avisos operativos deben formar un sistema discreto, consistente y poco decorativo.
- Bottom sheets, selectors buscables, chips y badges entran dentro del esfuerzo de normalización de Phase 6; no se dejan como detalle posterior.
- Los componentes nuevos o refactorizados deben consumir tokens/theme compartidos antes que colores, gradients o spacing inline.

### Claude's Discretion
- Microcopy exacto de headers, helper text, estados vacíos y CTAs mientras respete la jerarquía definida.
- Nivel exacto de compactación por pantalla, siempre que `Create` y `Split` sigan siendo guiados y `Detail` mantenga summary dominante.
- Orden concreto de extracción de primitives/theme tokens durante la implementación, según el mejor corte técnico para minimizar regresiones.

</decisions>

<specifics>
## Specific Ideas

- La app debe sentirse como un solo producto visual, no como una suma de pantallas bien resueltas por separado.
- El resultado buscado no es “más bonito” en abstracto, sino más coherente, más disciplinado y más reusable.
- Se mantiene continuidad con el lenguaje oscuro actual, pero con menos ruido visual, menos estilos sueltos y mejor jerarquía operativa.
- El design system persistido y la referencia de `ui-ux-pro-max` deben guiar la unificación de tokens, spacing, surfaces y patrones, sin abrir una fase extra de exploración estética.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/theme/app_theme.dart`: ya centraliza `ThemeData` para light/dark y es la base natural para endurecer el sistema visual.
- `lib/core/theme/theme_extensions.dart`: ya expone gradients, shadows, radius y spacing; puede convertirse en el punto único para eliminar estilos inline repetidos.
- `lib/features/subscriptions/presentation/widgets/billing_cycle_selector.dart`: patrón reusable de selector/chip que hoy existe pero necesita alinearse a tokens compartidos.
- `lib/features/subscriptions/presentation/widgets/split_bill_preview_card.dart`: ejemplo claro de card reusable con valor funcional alto, candidato directo a converger al lenguaje común.

### Established Patterns
- El repo ya usa un tema global y `ThemeExtension`, pero múltiples pantallas clave siguen pintándose con colores literales y gradientes ad-hoc.
- `Home`, `Create` y `Detail` muestran lenguaje visual parecido en intención, pero resuelto con implementaciones locales y densidades distintas.
- Fases 3, 4 y 5 ya fijaron prioridades de producto: setup de baja fricción, deuda/KPI prominente en Home y feedback operativo no bloqueante.
- Phase 6 debe respetar esas decisiones funcionales y unificarlas visualmente; no reabrirlas.

### Integration Points
- `lib/features/home/presentation/screens/home_screen.dart`: superficie clave para aplicar jerarquía operativa y reducir estilos hardcoded.
- `lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart`: punto principal para compactar formularios y estandarizar inputs/CTAs.
- `lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart`: pantalla con mayor densidad visual actual y mejor oportunidad para imponer summary + secciones.
- `lib/features/subscriptions/presentation/` en general: concentra selectors, preview cards, split UI y patrones que deben salir de Phase 6 con sistema consistente.

</code_context>

<deferred>
## Deferred Ideas

- Rebranding completo del producto o cambio fuerte de identidad visual.
- Nuevas capacidades funcionales en Home, Create, Split o Detail fuera de lo ya aprobado en fases anteriores.
- Sistema de design tokens multiplataforma más amplio o expansión a superficies no núcleo que no formen parte de `UX-01`/`UX-02`.

</deferred>

---

*Phase: 06-ux-system-consistency*
*Context gathered: 2026-03-12*
