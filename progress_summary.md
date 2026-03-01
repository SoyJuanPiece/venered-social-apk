# Progreso del Proyecto - Venered Social

## Estado Actual: v1.2 (Fase de Notificaciones y Pulido)

### Últimas Mejoras Implementadas
- **Sistema de Notificaciones OneSignal Pro:**
    - Automatización total mediante Triggers en Supabase.
    - Personalización de mensajes: `"Tienes un mensaje de [Usuario]"` (Privacidad).
    - Soporte para: Mensajes, Likes, Comentarios y Followers.
- **Control de SPAM (Relevancia):**
    - Implementado "Cool-down" de 15 minutos para Likes y Comentarios en el mismo post.
    - Los mensajes de chat siempre tienen prioridad y llegan al instante.
- **Arquitectura de Base de Datos:**
    - Consolidado script `MASTER_SETUP_VENERED.sql` para despliegue rápido.
    - Limpieza de archivos SQL en la raíz; organizados en `/supabase/scripts/`.
- **Identidad Visual:**
    - Configurado `flutter_launcher_icons` en `pubspec.yaml`.
    - Estructura de assets lista para el nuevo icono de mensajería.

### Pendientes / Próximos Pasos
1. **Generación de Iconos:** Colocar el archivo `app_icon.png` y ejecutar el generador.
2. **Pruebas de Carga:** Verificar que el control de spam funciona bajo ráfagas de likes.
3. **Optimización de UI:** Revisar si las notificaciones dentro de la app necesitan un diseño más moderno.

---
*Actualizado el 01 de Marzo, 2026*
