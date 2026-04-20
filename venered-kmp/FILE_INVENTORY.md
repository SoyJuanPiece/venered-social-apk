# Inventario de Archivos - Venered KMP

## 📦 Módulo Compartido (shared/)

### Modelos de Datos
- `data/model/Models.kt` - Todos los data classes (Post, User, Message, etc)

### Network & HTTP
- `data/network/SupabaseClient.kt` - Cliente HTTP Ktor + credenciales Supabase

### Repositorios (Data Access Layer)
- `data/repository/AuthRepository.kt` - Autenticación, login, signup, MFA
- `data/repository/PostRepository.kt` - Crear, obtener, likes, comentarios
- `data/repository/UserRepository.kt` - Perfiles, búsqueda, actualizar
- `data/repository/MessageRepository.kt` - Chats, mensajes, conversaciones
- `data/repository/NotificationRepository.kt` - Notificaciones, FCM tokens
- `data/repository/StoryRepository.kt` - Historias (24h)
- `data/repository/SavedPostRepository.kt` - Posts guardados

### Casos de Uso (Domain Layer)
- `domain/usecase/PostUseCases.kt` - GetFeedPosts, CreatePost, etc
- `domain/usecase/UserUseCases.kt` - GetProfile, SearchUsers, UpdateProfile
- `domain/usecase/MessageUseCases.kt` - GetConversations, SendMessage
- `domain/usecase/NotificationUseCases.kt` - GetNotifications, MarkAsRead

### ViewModels (Presentation Logic)
- `presentation/viewmodel/HomeFeedViewModel.kt` - Feed principal  
- `presentation/viewmodel/ProfileViewModel.kt` - Perfil usuario
- `presentation/viewmodel/MessagesViewModel.kt` - Chat y mensajes
- `presentation/viewmodel/NotificationsViewModel.kt` - Notificaciones

### Caché
- `data/cache/Cache.kt` - FeedCache, UserCache, MessageCache

### Utilidades
- `utils/Utils.kt` - Formatters, validadores, helpers
- `utils/DateTimeFormatter.kt` - Formato de fechas relativo
- `utils/ImageUtils.kt` - URL web-safe para imágenes

### Configuración
- `build.gradle.kts` - Dependencias Kotlin Multiplataforma
- `settings.gradle.kts` - Configuración de módulos

## 🤖 App Android (androidApp/)

### Actividades
- `MainActivity.kt` - Activity principal + Navigation

### Tema UI
- `ui/theme/Theme.kt` - Material 3, colores (indigo/rosa)

### Pantallas (Composables)
- `ui/screens/LoginScreen.kt` - Login/registro
- `ui/screens/HomeScreen.kt` - Feed de posts principal
- `ui/screens/ProfileScreen.kt` - Perfil del usuario
- `ui/screens/MessagesScreen.kt` - Lista de conversaciones
- `ui/screens/ExploreScreen.kt` - Búsqueda y descubrimiento
- `ui/screens/ChatScreen.kt` - Chat individual
- `ui/screens/NotificationsScreen.kt` - Centro de notificaciones

### Servicios
- `services/VeneredFirebaseMessagingService.kt` - Push notifications

### Recursos
- `res/values/strings.xml` - Textos de la app
- `AndroidManifest.xml` - Permisos y configuración

### Build
- `build.gradle.kts` - Dependencias Android
- `.gitignore` - Archivos ignorados

## 🍎 App iOS (iosApp/)

### Swift
- `VeneredApp.swift` - App principal + SwiftUI views
- `Info.plist` - Configuración iOS

## 📄 Archivos de Configuración

### Root Build Files
- `build.gradle.kts` - Build principal (plugins)
- `settings.gradle.kts` - Inclusión de módulos
- `gradle.properties` - Propiedades de build
- `extensions.gradle.kts` - Extensiones y versiones

### Gradle Build Source
- `buildSrc/src/main/kotlin/Dependencies.kt` - Centralización de versiones

### Scripts
- `build.sh` - Script de compilación (Linux/Mac)
- `install.sh` - Script de instalación

### Documentación
- `README.md` - Documentación principal
- `ARCHITECTURE.md` - Patrones y arquitectura
- `MIGRATION_GUIDE.md` - Comparativa Flutter vs KMP

### Configuración de Proyecto
- `.gitignore` - Archivos git ignorados
- `.env.example` - Variables de entorno (ejemplo)

## 🔗 Estructura de Carpetas Completa

```
venered-kmp/
├── shared/
│   ├── src/
│   │   ├── androidMain/
│   │   ├── iosMain/
│   │   └── commonMain/
│   │       └── kotlin/com/venered/social/
│   │           ├── data/
│   │           │   ├── model/
│   │           │   ├── network/
│   │           │   ├── repository/
│   │           │   └── cache/
│   │           ├── domain/
│   │           │   └── usecase/
│   │           ├── presentation/
│   │           │   └── viewmodel/
│   │           └── utils/
│   └── build.gradle.kts
│
├── androidApp/
│   ├── src/
│   │   └── main/
│   │       ├── kotlin/com/venered/social/android/
│   │       │   ├── ui/
│   │       │   │   ├── theme/
│   │       │   │   ├── screens/
│   │       │   │   └── components/
│   │       │   ├── services/
│   │       │   └── MainActivity.kt
│   │       ├── res/values/
│   │       └── AndroidManifest.xml
│   └── build.gradle.kts
│
├── iosApp/
│   ├── VeneredApp.swift
│   └── Info.plist
│
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
├── buildSrc/
├── README.md
├── ARCHITECTURE.md
├── MIGRATION_GUIDE.md
├── build.sh
├── install.sh
└── .gitignore

Total de Archivos: 50+
Total de Líneas de Código: ~5000+
```

## 📊 Estadísticas del Proyecto

| Categoría | Cantidad |
|-----------|----------|
| Modelos de datos | 9 |
| Repositorios | 7 |
| Casos de uso | 17 |
| ViewModels | 4 |
| Pantallas Android | 7 |
| Servicios | 1 |
| Archivos de configuración | 8 |
| Documentación | 4 |
| **Total** | **~50 archivos** |

## 🔧 Cómo se Conectan los Archivos

```
UI (Composables)
  ↓ viewModel.loadFeed()
ViewModel (StateFlow)
  ↓ useCase(params)
Use Case (operator invoke)
  ↓ repository.getFeedPosts()
Repository (Network + Cache)
  ↓ httpClient.get("/api/posts")
SupabaseClient (Ktor HTTP)
  ↓ Response
Models.kt (Data classes)
  ↓ JSON → Kotlin Objects
Back to UI with state.collectAsState()
```

## 🚀 Próximos Pasos para Completar

- [ ] Agregar testing (androidTest, commonTest)
- [ ] Implementar SQLDelight para DB local
- [ ] Configurar Firebase google-services.json
- [ ] Agregar más validaciones y error handling
- [ ] Implementar imagen caching con Coil  
- [ ] Agregar social features (share, deep links)
- [ ] Optimizar performance (Baseline Profiles)
- [ ] Agregar dark theme completo
- [ ] Configurar analytics eventos
- [ ] Preparar para App Store/Play Store
