# Venered Social - Kotlin Multiplataforma

Migración completa de la aplicación Venered Social de **Flutter** a **Kotlin Multiplataforma (KMP)**.

## 📱 Plataformas Soportadas

- **Android**: App nativa con Jetpack Compose
- **iOS**: App nativa con SwiftUI
- **Shared**: Lógica de negocio compartida en Kotlin

## 🏗️ Arquitectura

### Estructura de Carpetas

```
venered-kmp/
├── shared/                          # Módulo compartido (Kotlin Multiplataforma)
│   └── src/
│       └── commonMain/kotlin/
│           └── com/venered/social/
│               ├── data/
│               │   ├── model/           # Modelos de datos
│               │   ├── network/         # Cliente Supabase/HTTP
│               │   ├── repository/      # Repositorios
│               │   └── cache/           # Caché en memoria
│               ├── domain/
│               │   └── usecase/         # Casos de uso
│               ├── presentation/
│               │   └── viewmodel/       # ViewModels compartidos
│               └── utils/               # Utilidades
├── androidApp/                      # App Android
│   └── src/main/
│       ├── kotlin/
│       │   └── com/venered/social/android/
│       │       ├── ui/
│       │       │   ├── theme/           # Tema Material 3
│       │       │   ├── screens/         # Pantallas Compose
│       │       │   └── components/      # Componentes reutilizables
│       │       ├── services/            # Servicios (Firebase, etc)
│       │       └── MainActivity.kt
│       └── res/
├── iosApp/                          # App iOS
│   └── VeneredApp.swift             # SwiftUI + Combine
└── build.gradle.kts                 # Build principal
```

### Arquitectura MVVM + Clean Architecture

- **Data Layer**: Repositorios, modelos, cache
- **Domain Layer**: Casos de uso, lógica de negocio
- **Presentation Layer**: ViewModels, UI (Compose/SwiftUI)

## 🔌 Integración Supabase

La app utiliza **Supabase** (PostgreSQL en la nube) para:

- 🔐 Autenticación (Email/Password + MFA)
- 📝 Posts, comentarios, likes
- 💬 Mensajería directa
- 📬 Notificaciones
- 👤 Perfiles de usuario

### Credenciales

```
URL: https://ywbqkzvsqgyxgmguxwam.supabase.co
ANON_KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🚀 Características Principales

### Autenticación
- Login/Registro
- Verificación de 2 factores (TOTP MFA)
- Gestión de sesiones

### Feed Social
- Posts con imágenes/videos
- Sistema de likes
- Comentarios
- Historias (24 horas)
- Búsqueda de usuarios

### Mensajería
- Chats 1:1
- Notificaciones en tiempo real
- Soporte para multimedia

### Notificaciones
- Push notifications (Firebase)
- Notificaciones en tiempo real
- Sonidos y vibración

### Perfil de Usuario
- Editar información
- Avatar personalizado
- Estado de localización
- Verificación de identidad

## 🔧 Configuración

### Requisitos Previos

- **Android Studio** 2023.1+
- **Xcode** 14.3+
- **Kotlin** 1.9.20+
- **Gradle** 8.0+
- **JDK** 11+

### Instalación Android

```bash
# En venered-kmp/
./gradlew androidApp:build

# Ejecutar en emulador/dispositivo
./gradlew androidApp:installDebug
```

### Instalación iOS

```bash
# Generar código Swift desde KMP
./gradlew iosApp:build

# Abrir en Xcode
open iosApp/Venered.xcodeproj

# Compilar y ejecutar en Xcode
```

## 📦 Dependencias Principales

### Multiplataforma (compartido)
- `kotlinx-coroutines`: Concurrencia
- `ktor-client`: HTTP client
- `kotlinx-serialization`: JSON parsing
- `sqldelight`: Base de datos local
- `kotlinx-datetime`: Manejo de fechas

### Android
- `androidx-compose`: UI
- `androidx-navigation`: Navegación
- `coil-compose`: Carga de imágenes
- `firebase-messaging`: Push notifications
- `androidx-lifecycle`: Manejo de ciclo de vida

### iOS
- `SwiftUI`: UI Framework
- `Combine`: Reactive programming
- `URLSession`: Networking

## 🔄 Flujos Principales

### Login
```
LoginScreen 
  → Validar credenciales 
  → AuthRepository.login() 
  → Navegar a HomePage si éxito
  → Mostrar error si falla
```

### Crear Post
```
CreatePostScreen 
  → Validar contenido 
  → Comprimir media 
  → PostRepository.createPost() 
  → Actualizar feed
```

### Cargar Feed
```
HomeFeedScreen 
  → Mostrar posts cacheados 
  → PostRepository.getFeedPosts(offset=0, limit=15) 
  → Actualizar caché 
  → Renderizar con datos frescos
```

## 🎨 Diseño Visual

### Colores
- **Primario**: `#6366F1` (Indigo - Dark) / `#4F46E5` (Light)
- **Secundario**: `#EC4899` (Rosa - Dark) / `#EA580C` (Orange - Light)
- **Fondo**: `#0A0A0A` (Dark) / `#F5F8FF` (Light)

### Tipografía
- **Font**: Poppins (Android) / System (iOS)
- **Estilos**: Bold, SemiBold, Regular

### Componentes Comunes
- `PostCard`: Tarjeta de post con interacciones
- `AvatarImage`: Avatar circular del usuario
- `ActionButton`: Botónes estándar
- `LoadingIndicator`: Spinner de carga

## 📡 Integración Firebase

### Setup
1. Crear proyecto en Firebase Console
2. Agregarcredenciales a `google-services.json` (Android)
3. Agregar credenciales a `GoogleService-Info.plist` (iOS)

### Push Notifications
```kotlin
// Guardar token FCM
NotificationRepository.saveFCMToken(userId, fcmToken)

// Recibir notificaciones
VeneredFirebaseMessagingService.onMessageReceived()
```

## 🧪 Testing

```bash
# Tests unitarios compartidos
./gradlew shared:test

# Tests en Android
./gradlew androidApp:test

# Instrumented tests
./gradlew androidApp:connectedAndroidTest
```

## 🚢 Build & Deploy

### Android APK
```bash
./gradlew androidApp:bundleRelease
```

### iOS Archive
```bash
# En Xcode, productos → Archive
```

## 🐛 Debugging

### Android
```bash
# Logs en logcat
adb logcat | grep "Venered"

# Debugger en Android Studio
```

### iOS
```bash
# Console en Xcode
# Breakpoints en Xcode
```

## 📊 Base de Datos Supabase

### Tablas Principales
- `profiles`: Perfiles de usuario
- `posts`: Posts/publicaciones
- `comments`: Comentarios
- `likes`: Sistema de likes
- `messages`: Mensajes directos
- `conversations`: Conversaciones
- `stories`: Historias
- `notifications`: Notificaciones

### Vistas SQL
- `posts_with_likes_count`: Posts con conteos
- `stories_with_profiles`: Stories con info del usuario
- `view_conversations`: Conversaciones del usuario

## ⚡ Performance

- **Caché en memoria** para posts, usuarios, mensajes
- **Paginación** (15 items por página)
- **Compresión de imágenes** en cliente
- **Lazy loading** de datos

## 🔒 Seguridad

- **HTTPS** obligatorio
- **Tokens JWT** para autenticación
- **RLS (Row Level Security)** en Supabase
- **Input validation** en cliente y servidor
- **Encriptación** de datos sensibles (SharedPreferences seguro en Android)

## 📝 Licencia

Este proyecto está bajo licencia MIT.

## 👨‍💻 Desarrollador

Migración de Flutter a Kotlin Multiplataforma realizada con arquitectura moderna y best practices.

---

**Nota**: Esta es la estructura base para una migración completa. Para producción, se deben agregar:
- Manejo avanzado de errores
- Analytics con Firebase
- Crashlytics
- A/B testing
- Rate limiting
- Offline-first sync
