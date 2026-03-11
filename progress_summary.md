# Progreso de Venered Social - v3.0 (Final Setup)

## 🚀 Logros Recientes

### 0. Estabilización de Build y CI (Marzo 2026)
- **Build Flutter corregido:** Se solucionó el error de compilación por parámetro faltante en `ProfileScreen` (`userId` requerido desde navegación principal).
- **GitHub Actions robustecido:** Se corrigió la restauración de `google-services.json` desde secrets y se añadió validación del JSON antes de compilar.
- **Permisos de release arreglados:** Se agregó `permissions: contents: write` en el workflow para permitir crear releases sin error `403`.
- **Disparo por tags validado:** Se confirmaron ejecuciones con tags semánticos (`v1.2.x`) y funcionamiento del pipeline de build.
- **Conexión Supabase verificada:** La app y el entorno responden correctamente contra Auth y REST del proyecto (`HTTP 200`).

### 1. Migración y Limpieza de Base de Datos (Supabase)
- **Nuevo Proyecto:** Migración total a la instancia `ywbqkzvsqgyxgmguxwam`.
- **Master Setup v3.0:** Se implementó un script maestro robusto que crea todo el ecosistema:
    - **Módulos Core:** Perfiles (auto-creación), Posts, Likes, Comentarios, Seguidores.
    - **Mensajería:** Tabla de mensajes y vista de conversaciones para chats en tiempo real.
    - **Historias (Stories):** Sistema completo con vistas y expiración de 24 horas.
    - **Moderación:** Sistema de reportes y solicitudes de verificación.
- **Vistas SQL:** Creadas vistas críticas como `stories_with_profiles` y `posts_with_likes_count` para optimizar la carga de la App.

### 2. Notificaciones Push Definitivas (Firebase FCM)
- **Migración OneSignal -> Firebase:** Se eliminó OneSignal para usar el sistema nativo y gratuito de Google (FCM).
- **Registro de Tokens:** La App ahora registra automáticamente el FCM Token de cada dispositivo en Supabase al iniciar sesión.
- **Trigger SQL:** Se implementó el disparador `send_fcm_push` que envía notificaciones automáticas al móvil cuando hay mensajes, nuevos seguidores o interacciones.

### 3. Correcciones de la Aplicación (Flutter)
- **Buscador Arreglado:** Se sincronizaron los nombres de columnas entre la App y la DB (`avatar_url`).
- **Compatibilidad Android:** Actualización de `desugar_jdk_libs` a la versión 2.1.4 para permitir compilaciones exitosas con las nuevas librerías de Firebase.
- **Realtime:** Activación de Supabase Realtime en todas las tablas clave para una experiencia fluida.

### 4. Repositorio y CI/CD
- **Unificación:** Se fusionó la carpeta `almacenamiento-temporal` eliminando dependencias externas.
- **Automatización:** Tag `1.0` configurado para disparar la compilación automática del APK en GitHub Actions con cada cambio importante.

## 🛠️ Estado Actual
- **Base de Datos:** 100% Configurada y Segura (RLS Activo).
- **Notificaciones:** Funcionando vía Firebase (Priority High).
- **APK:** Pipeline de compilación y release operativo en GitHub Actions.

---
*Actualizado el 11 de Marzo de 2026*
