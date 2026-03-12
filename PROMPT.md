# Prompt para Red Social Android en Flutter (Nivel Producción) - Venered Social

Crea una aplicación móvil completa de red social para Android usando Flutter, inspirada en el diseño y experiencia de usuario de Instagram y Threads de Meta. El proyecto debe seguir una arquitectura limpia, ser modular y estar optimizado para el mercado venezolano con funciones avanzadas de seguridad y regionalización.

## Requisitos funcionales y Core

1. **Pantalla de inicio (Feed Regionalizado):**
   - Muestra publicaciones de usuarios (imágenes, texto, likes, comentarios).
   - **Filtro por Estado:** Los usuarios solo ven contenido de personas que residen en su mismo estado de Venezuela.
   - Scroll vertical infinito y Pull-to-refresh.

2. **Navegación inferior:**
   - Barra con pestañas: Inicio, Buscar, Publicar, Notificaciones, Perfil.
   - Iconos modernos y minimalistas con soporte para Modo Oscuro y Claro.

3. **Perfil de Usuario y Edición:**
   - Foto de perfil, biografía, contadores de seguidores/seguidos.
   - **Gestión de Ubicación:** Selección de Estado de Venezuela, restringido a un cambio cada 7 días.

4. **Publicar y Multimedia:**
   - Carga de imágenes desde galería/cámara.
   - Procesamiento de imágenes para optimización de almacenamiento.

5. **Interacción Social:**
   - Sistema de likes y comentarios en tiempo real.
   - Mensajería directa (Chat) integrada.

6. **Notificaciones Push Inteligentes (Firebase FCM):**
   - Notificaciones automáticas para Likes, Comentarios, Mensajes y Seguidores.
   - **Control de SPAM:** Lógica de cooldown (15 min) para interacciones repetitivas en el mismo post.
   - **Privacidad:** Los mensajes push ocultan el contenido sensible (Ej: "Tienes un mensaje de Juan").

## Requisitos de Seguridad y Regionalización

1. **Autenticación Avanzada:**
   - Registro/Login vía Supabase Auth.
   - **MFA (2FA) Opcional:** Soporte para Autenticación de Dos Factores mediante TOTP (Google Authenticator/Authy).
   - Verificación de segundo paso obligatoria para cuentas protegidas durante el login.

2. **Exclusividad Nacional (Venezuela):**
   - **Detección por IP:** Geolocalización automática al registrarse para identificar el estado.
   - **Bloqueo Internacional:** Restricción de registro para direcciones IP fuera de Venezuela.

## Requisitos Técnicos y Arquitectura

- **Framework:** Flutter 3.24.x o superior.
- **Backend:** Supabase (Auth, Database, Storage, Realtime, Edge Functions).
- **Notificaciones:** Firebase Cloud Messaging (FCM) con registro de token en Supabase.
- **Geolocalización:** Integración con IP-API (con soporte Cleartext configurado en Android).
- **Gestión de Iconos:** Uso de `flutter_launcher_icons` para branding automatizado.
- **Base de Datos:**
    - Lógica de negocio protegida por Triggers y Row Level Security (RLS).
    - Scripts organizados en `/supabase` para despliegue maestro (`MASTER_SETUP_VENERED.sql`).

## Politica de Multimedia (estado implementado)

- Imagenes de perfil, posts, mensajes e historias: ImgBB.
- Video: solo historias en movil mediante backend Telegram.
- Web: historias en foto; video deshabilitado si backend de historias no expone HTTPS.

## Requisitos de Diseño

- Interfaz moderna, minimalista y responsiva.
- Soporte completo para **Tema Oscuro** persistente.
- Animaciones suaves y feedback visual (Badges de mensajes no leídos, indicadores de carga).

---

### Instrucciones para Mantenimiento y Evolución

- Mantener la limpieza del repositorio: Scripts SQL en `/supabase/scripts`.
- Asegurar compatibilidad de nulabilidad (Null-Safety) en todas las pantallas.
- Seguir la convención de versiones (v1.2 actual).
- Priorizar la seguridad del usuario y la privacidad en las notificaciones push.

Este prompt define a **Venered Social** como una plataforma robusta, segura y regionalizada, lista para escalar en el ecosistema móvil de Venezuela.
