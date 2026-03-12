# Progreso de Venered Social - Estado Actual

## Resumen Ejecutivo
- App Flutter con backend Supabase + backend hibrido para historias en `almacenamiento-temporal`.
- CI/CD de APK activo por tags en GitHub Actions.
- Historias estabilizadas: refresco correcto, navegacion por tap derecha/izquierda y correcciones de reproduccion.
- Politica multimedia unificada:
    - Imagenes (perfil, post, mensaje, historia): ImgBB.
    - Video: solo historias via backend Telegram (en movil).

## Logros Recientes (Marzo 2026)

### 1) UI y navegacion
- Barra de navegacion inferior en movil reconstruida para evitar desplazamientos y solapamientos.
- Feed vacio con estado visual mejorado y acciones rapidas.
- Corregido overflow menor en el estado vacio del feed.

### 2) Historias
- Carga y refresco de historias ajustados para que nuevas historias aparezcan sin inconsistencias.
- Viewer mejorado:
    - Avance al tocar zona derecha/izquierda.
    - Manejo de URLs de Telegram expiradas con reintento de URL fresca por `file_id`.
    - Flujo de agregar/eliminar historia manteniendo estado local del viewer.
- Banner de estado de almacenamiento oculto para usuarios finales (solo debug).

### 3) Politica de medios implementada
- Publicaciones: solo imagen (video removido).
- ImgBB con nombre estandarizado por categoria y usuario.
- Backend Telegram forzado para videos de historias en movil.

### 4) Web vs movil
- Web:
    - Historias configuradas para fotos (HTTPS compatible).
    - Video en historias deshabilitado mientras el endpoint de Telegram siga en HTTP.
- Movil (APK):
    - Mantiene flujo completo de historias con video via backend Telegram.

### 5) CI/CD y build
- Ajustes de Gradle para evitar fallas de descarga.
- Builds por tags validadas en varias iteraciones `v1.2.x` y `v1.3.x`.

## Estado Actual
- Base de datos Supabase operativa con RLS.
- Realtime activo en modulos principales.
- Notificaciones push via Firebase FCM.
- Rama `main` limpia y sincronizada con `origin/main`.

## Pendientes Tecnicos Recomendados
- Exponer backend de historias por HTTPS para habilitar video tambien en web.
- Mantener variables de entorno del backend centralizadas para despliegues.

---
Actualizado el 12 de Marzo de 2026
