# 📝 Ejemplos de Prompts para Agentes

Este archivo contiene ejemplos prácticos de cómo interactuar con los agentes AI.

---

## 🏗️ FLUTTER FEATURE ARCHITECT

### Ejemplo 1: Feature Completo de Autenticación

```
@flutter-feature-architect

Crear un feature completo de autenticación con las siguientes especificaciones:

**Funcionalidades:**
1. Login con email y password
2. Registro de nuevos usuarios
3. Recuperación de contraseña
4. Persistencia de sesión (mantener login)
5. Logout

**Requisitos técnicos:**
- Clean Architecture estricta
- Validación de email y password en el dominio
- Tokens guardados en flutter_secure_storage (NO en Hive)
- User info básica en Hive (nombre, email, id)
- Estados de loading, error y success bien manejados
- Encriptación para datos sensibles

**UI:**
- LoginScreen con Material 3
- SignupScreen
- ForgotPasswordScreen
- Form validation con mensajes de error claros

Genera toda la estructura siguiendo los templates de los sub-agentes.
```

---

### Ejemplo 2: Feature de E-commerce

```
@flutter-feature-architect

Necesito un feature de catálogo de productos para e-commerce:

**Entidades:**
- Product (id, name, description, price, imageUrl, category, stock)
- Category (id, name, icon)

**Funcionalidades:**
1. Listar productos con filtro por categoría
2. Búsqueda de productos por nombre
3. Ver detalle de producto
4. Agregar a favoritos (persistente)
5. Cache de productos con Hive (offline-first)

**Casos de uso:**
- GetProductList (con filtros opcionales)
- GetProductDetail
- SearchProducts
- ToggleFavorite
- GetFavoriteProducts

**UI Requirements:**
- GridView para lista de productos
- SearchBar con debounce
- Filtros por categoría (chips)
- Producto card con imagen, nombre, precio
- Screen de detalle con galería

Importante: Manejar estados de empty, loading, error correctamente.
```

---

### Ejemplo 3: Feature de Chat en Tiempo Real

```
@flutter-feature-architect

Crear feature de chat 1-a-1 con las siguientes características:

**Funcionalidades:**
1. Listar conversaciones
2. Ver mensajes de una conversación
3. Enviar mensaje de texto
4. Enviar imagen (desde galería o cámara)
5. Indicador de "typing..."
6. Persistencia local de mensajes (Hive)
7. Sincronización con WebSocket

**Entidades:**
- Conversation (id, participants, lastMessage, unreadCount)
- Message (id, conversationId, senderId, text, imageUrl, timestamp, status)
- MessageStatus (sent, delivered, read)

**Casos especiales:**
- Mensajes offline: guardar en Hive y enviar cuando haya conexión
- Imágenes: usar LazyBox por tamaño
- Paginación de mensajes antiguos
- Optimistic updates para UX fluida

Coordina con @hive-database-auditor para asegurar que el manejo de imágenes y mensajes es óptimo.
```

---

## 🛡️ FLUTTER DEVOPS & QUALITY GUARDIAN

### Ejemplo 1: Pre-Production Checklist

```
@flutter-devops-quality-guardian

El feature de autenticación está listo para revisión pre-producción.

Por favor ejecuta el checklist completo:
1. Code quality inspection
2. Test coverage analysis (necesitamos ≥80%)
3. Hive database audit (verificar encryption de tokens si aplica)
4. Security audit (especialmente manejo de passwords y tokens)
5. Performance profiling (login flow debe ser <2s)
6. Dependency audit

Genera un reporte detallado con:
- Score general
- Blockers (si los hay)
- Warnings críticos
- Tiempo estimado para resolver issues
- Checklist de producción
```

---

### Ejemplo 2: Performance Investigation

```
@flutter-devops-quality-guardian

Los usuarios reportan lag al scrollear la lista de productos (300+ items).

Necesito que coordines:
1. @performance-auditor para identificar bottlenecks
2. @hive-database-auditor para verificar queries
3. @code-quality-inspector para detectar anti-patterns en widgets

Analiza específicamente:
- Uso de ListView.builder vs ListView
- Rebuilds innecesarios
- Queries de Hive en el build method
- Imágenes sin cache
- Widget trees sin const

Proporciona código específico para optimizar.
```

---

### Ejemplo 3: Security Audit Completo

```
@flutter-devops-quality-guardian

Necesito una auditoría de seguridad completa del proyecto antes del release a producción.

Enfócate en:
1. Secrets hardcodeados (API keys, tokens)
2. Datos sensibles sin encriptar en Hive
3. Validación de inputs (SQL injection, XSS si aplica)
4. Permisos de la app (Android/iOS)
5. Configuración de SSL pinning
6. Exposure de información en logs
7. Backups automáticos (pueden exponer datos)

Genera un security report con severidad (Critical, High, Medium, Low) y recomendaciones específicas de fix.
```

---

## 🎨 UI COMPONENT BUILDER

### Ejemplo 1: Componente Complejo Reutilizable

```
@ui-component-builder

Necesito un componente de ProductCard reutilizable con las siguientes características:

**Visual:**
- Imagen del producto (aspect ratio 1:1)
- Nombre del producto (máximo 2 líneas con ellipsis)
- Precio (formateado como moneda)
- Badge de "Nuevo" si fue creado en últimos 7 días
- Badge de "Descuento" si tiene precio reducido
- Botón de favoritos (corazón) en esquina superior derecha
- Rating con estrellas (1-5)

**Interactividad:**
- Tap en card: navega a detalle
- Tap en favorito: toggle favorito (optimistic update)
- Hero animation en imagen al navegar a detalle

**Props:**
- product: Product entity
- onFavoriteTap: VoidCallback
- isFavorite: bool

Material 3, responsive, accesible.
```

---

## 🧪 PATROL TEST ENGINEER

### Ejemplo 1: Test de Flujo Completo

```
@patrol-test-engineer

Necesito tests de Patrol para el flujo completo de compra:

**User Flow:**
1. Usuario abre app (no autenticado)
2. Navega a catálogo de productos
3. Busca "laptop"
4. Selecciona un producto
5. Agrega al carrito
6. Ve carrito (debe aparecer el producto)
7. Procede a checkout
8. Se le pide login
9. Hace signup con email/password
10. Vuelve a checkout
11. Llena datos de envío
12. Confirma orden
13. Ve confirmación con número de orden

**Assertions:**
- Cada pantalla se renderiza correctamente
- Los datos persisten entre navegaciones
- Validaciones de formulario funcionan
- Estados de loading aparecen
- Mensajes de error se muestran si hay fallos

**Casos edge:**
- Perder conexión durante checkout
- Cerrar app y volver (debe mantener carrito)
- Email duplicado en signup

Incluye mocks para API calls y Hive setup para tests aislados.
```

---

## 🔍 HIVE DATABASE AUDITOR

### Ejemplo 1: Auditoría de Esquema

```
@hive-database-auditor

Hemos agregado varios features y quiero auditar todo el esquema de Hive:

**Models actuales:**
- TaskModel (typeId: 0)
- UserModel (typeId: 10)
- ProductModel (typeId: 20)
- MessageModel (typeId: 30)
- ConversationModel (typeId: 31)

**Verifica:**
1. No hay conflictos de typeId
2. Todos los adapters están registrados en HiveService
3. Boxes se abren correctamente en init()
4. Fields tienen defaultValue donde corresponde
5. LazyBox se usa para MessageModel (contiene imágenes)
6. Encryption habilitada para UserModel
7. Auto-compaction configurado para Messages (se borran frecuentemente)
8. No hay .values.toList() en hot paths
9. Cascade deletion para relaciones (User -> Messages)

Genera reporte con score y recomendaciones de optimización.
```

---

## 🚀 CI/CD PIPELINE ENGINEER

### Ejemplo 1: Setup de Pipeline Completo

```
@ci-cd-pipeline-engineer

Necesito configurar CI/CD completo para GitHub Actions:

**Stages:**
1. **Lint & Analyze**
   - dart analyze
   - dart format --set-exit-if-changed

2. **Test**
   - flutter test --coverage
   - Minimum coverage: 80%
   - Upload coverage to Codecov

3. **Build**
   - Android APK (release)
   - iOS IPA (release)
   - Solo si tests pasan

4. **Deploy**
   - Dev flavor → Firebase App Distribution
   - Prod flavor → Manual approval → Play Store (internal testing) / TestFlight

**Triggers:**
- Push a `main`: Full pipeline
- Pull Request: Lint + Test only
- Tag `v*`: Build + Deploy a prod

**Secrets needed:**
- ANDROID_KEYSTORE
- IOS_CERTIFICATE
- FIREBASE_TOKEN
- PLAY_STORE_SERVICE_ACCOUNT

Genera el archivo .github/workflows/ci-cd.yml completo.
```

---

## 💡 Tips para Mejores Resultados

### 1. Sé Específico
❌ "Crear un feature de usuarios"
✅ "Crear feature de gestión de usuarios con CRUD, roles (admin/user), avatar, y persistencia en Hive"

### 2. Define Requisitos Técnicos
```
Siempre incluye:
- Entidades y sus campos
- Casos de uso específicos
- Requisitos de UI
- Manejo de errores esperado
- Estrategia de persistencia
```

### 3. Menciona Casos Edge
```
Considera:
- Estados vacíos
- Errores de red
- Validaciones de formulario
- Datos corruptos en Hive
- Migraciones de schema
```

### 4. Solicita Validaciones
```
Siempre pide:
- Validación de Clean Architecture
- Tests coverage
- Performance check
- Security audit
```

---

## 🔄 Workflow Recomendado

```
1. Diseño → @flutter-feature-architect
   ↓
2. Implementación → Agente genera código
   ↓
3. Code Generation → build_runner
   ↓
4. Testing → @patrol-test-engineer
   ↓
5. Quality Check → @flutter-devops-quality-guardian
   ↓
6. Optimización → @performance-auditor + @hive-database-auditor
   ↓
7. Pre-Production → @flutter-devops-quality-guardian (full audit)
   ↓
8. Deploy → @ci-cd-pipeline-engineer
```

---

**Usa estos ejemplos como base y adáptalos a tus necesidades específicas!** 🚀
