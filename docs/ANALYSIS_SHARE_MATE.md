# 📊 Análisis de Proyecto: Share Mate 🤝

## 🎯 Objetivo del Proyecto
Crear una aplicación ("Share Mate") sencilla y moderna para el control de suscripciones online compartidas. Su función principal es permitir al usuario gestionar sus suscripciones, saber exactamente **quién le debe cuánto** y **qué día**, además de calcular automáticamente la deuda cuando se crean o modifican suscripciones.

---

## 🏗️ Estado Actual del Proyecto (Lo que ya tienes)

He analizado tu repositorio de arriba a abajo. El proyecto está muy bien fundamentado y utiliza un stack tecnológico robusto y moderno para Flutter:

### 1. Arquitectura y Stack 🛠️
*   **Patrón:** Clean Architecture estricta (Domain, Data, Presentation).
*   **Gestor de Estado:** Riverpod (con code generation).
*   **Modelos de Datos:** Freezed (para inmutabilidad y copias).
*   **Backend & Autenticación:** Supabase.
*   **Offline-First:** Hive + Sync Queue (permite usar la app sin internet y sincronizar cuando vuelve la conexión, lo cual es excelente).

### 2. Base de Datos (Supabase Schema) 🗄️
Tu esquema de base de datos está muy bien pensado para este caso de uso:
*   **`subscriptions`**: Guarda la info base (nombre, color, ícono, ciclo de pago, total a pagar, fecha de cobro).
*   **`subscription_members`**: **¡Esta es la joya de la corona!** Guarda quién está en cada suscripción, cuánto le toca pagar (`amount_to_pay`), si ya pagó (`has_paid`) y la fecha de su pago.
*   **`contacts`**: Recientemente refactorizado (Enero 2026). Pasaste de un sistema complejo de "amigos" a una simple y efectiva libreta de contactos personales (nombre, email, notas).
*   **`profiles`**: Para manejar los avatares y nombres de los usuarios registrados.
*   **Funciones SQL (`get_monthly_stats`)**: Tienes una función que ya calcula lo que te deben (`pending_to_collect`), lo que has cobrado (`collected_amount`) y tus gastos totales.

### 3. Features Implementadas (en `lib/features/`) 📱
*   **Auth (Autenticación)**: 100% implementada y probada (Grade A). Offline-first y segura.
*   **Subscriptions**: Es el core que más código tiene. Tienes repositorios híbridos (Hive + Supabase) y pantallas creadas (`create_group_subscription_screen.dart`, `subscription_detail_screen.dart`, etc.).
*   **Contacts**: La estructura base existe y la base de datos está lista.
*   **Home & Settings**: Estructura base configurada.

---

## 🚧 Estancamiento: ¿Qué falta para terminar "Share Mate"?

Aunque la base técnica es increíble, para cumplir el objetivo de ser una app "sencilla y útil para saber quién me debe", faltan las conexiones lógicas entre la UI y estos cálculos. Aquí detallo lo que falta:

### 1. Cálculos de División (Splits) Personalizados 🧮
*   **Problema:** Actualmente, en tu entidad `Subscription` en Flutter (ver `subscription.dart`), el cálculo está hardcodeado a partes iguales: `totalCost / totalMembers`.
*   **Solución:** Aunque la base de datos (`subscription_members`) permite guardar un `amount_to_pay` específico por persona, la UI y el modelo de Flutter aún no lo soportan.
*   **Acción:** Añadir en la UI de creación de grupo (`create_group_subscription_screen.dart`) la opción de elegir el tipo de división:
    *   *A partes iguales* (Equitativo)
    *   *Porcentajes* (Ej: Yo 60%, tú 40%)
    *   *Cantidad exacta* (Ej: Netflix cuesta $15, yo pago $10, tú $5)

### 2. Dashboard Central (Home Screen) 🏠
*   **Problema:** La función SQL `get_monthly_stats` hace el trabajo duro, pero el `home_screen.dart` probablemente solo esté mostrando una lista cruda de suscripciones.
*   **Solución:** Rediseñar el `home_screen.dart` para que lo primero que vea el usuario sea:
    1.  **"Me Deben:"** (Total pendiente de cobro este mes).
    2.  **Lista de Morosos:** Tarjetas rápidas con "Juan Pérez te debe $5 de Netflix (Venció hace 2 días)". Botón rápido de "Marcar como pagado" o "Recordar".
    3.  **"Mis Gastos Próximos:"** Qué me van a cobrar a mí en los próximos 7 días.

### 3. Flujo de "Marcar como Pagado" (Settling Debts) ✅
*   **Problema:** Aunque existe el RPC `mark_payment_as_paid_atomic` en tu capa de datos, la experiencia de usuario para esto no está clara.
*   **Solución:** En el detalle de la suscripción (`subscription_detail_screen.dart`), debe haber una lista clara de los miembros del grupo. Junto a cada miembro, un switch o botón "Pagó este mes". Al pulsarlo, se actualiza el `has_paid` a `true` y se guarda la fecha.

### 4. Integración de Contactos en Grupos 👥
*   **Problema:** Tienes la tabla `contacts`, pero al crear un grupo, la selección de personas aún no está integrada fluidamente.
*   **Solución:** Implementar la pantalla de "Seleccionar Contactos" a la hora de crear una suscripción compartida. Si el contacto no existe, permitir crearlo ahí mismo sin salir del flujo.

### 5. Sistema de Notificaciones / Recordatorios 🔔
*   **Problema:** La app es pasiva; el usuario tiene que entrar para ver si alguien le debe.
*   **Solución:** (Para una versión V1.5 o V2) Implementar recordatorios locales (`flutter_local_notifications`). 
    *   "Netflix se cobra mañana, asegúrate de tener fondos."
    *   "Juan aún no te paga Spotify de este mes."
    *   "Generar link de cobro" (ej. botón para enviar un mensaje de WhatsApp prefijado: *"Hola Juan, toca pagar $5 de Netflix este mes. ¡Gracias!"*).

---

## 🗺️ Plan de Acción Recomendado (Next Steps)

Para destrabarte, te sugiero atacar el proyecto en este orden (te puedo ayudar con cualquiera de estos pasos):

1.  **Fase 1: El Cerebro Matemático (Lógica de Splits)**
    *   Modificar la entidad `Subscription` y `SubscriptionMember`.
    *   Añadir la lógica para divisiones exactas y porcentuales, no solo "partes iguales".
2.  **Fase 2: El Dashboard (Home Screen)**
    *   Conectar el `home_screen.dart` con la función Supabase `get_monthly_stats`.
    *   Diseñar las tarjetas UI ("Me deben", "Mis gastos").
3.  **Fase 3: Gestión de Pagos UI**
    *   Terminar la UI en `subscription_detail_screen.dart` para listar miembros y añadir el botón visual de "Marcar como pagado".
4.  **Fase 4: Flujo de Contactos**
    *   Terminar el CRUD básico de Contactos y conectarlo al flujo de "Crear Suscripción Grupo".

*¡El trabajo arquitectónico que has hecho hasta ahora es de nivel Senior! Solo te falta conectar las piezas visuales para que la experiencia de usuario (UX) brille.* ¿Por qué paso de la Fase 1 quieres que empecemos?