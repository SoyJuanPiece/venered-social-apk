# Progreso del Proyecto - Venered Social

## Estado Actual: v1.1 (Fase Regional y Identidad)

### Últimas Mejoras Implementadas
- **Regionalización (Venezuela):**
    - Implementado sistema de **Estados de Venezuela** en perfiles.
    - **Filtro de Contenido:** El feed principal ahora solo muestra publicaciones de personas del mismo estado que el usuario.
    - **Restricción de Cambio:** Se añadió un trigger en Supabase que permite cambiar de estado solo una vez cada 7 días.
- **Geolocalización Automática:**
    - Integración con **IP-API** para detectar automáticamente el estado del usuario al registrarse.
    - **Bloqueo Internacional:** La aplicación ahora restringe el registro a direcciones IP fuera de Venezuela para mantener la exclusividad local.
- **Seguridad de Red:**
    - Configurado `usesCleartextTraffic` en Android y `NSAppTransportSecurity` en iOS para permitir la detección de ubicación.
- **Identidad Visual Actualizada:**
    - Nuevo icono oficial aplicado desde el paquete de diseño final.
    - Regeneración completa de assets para Android, iOS y Web.

### Pendientes / Próximos Pasos
1. **Editar Perfil:** Añadir el selector de estado en la pantalla de edición respetando la regla de los 7 días.
2. **Explorar:** Añadir una opción para "cambiar de estado" temporalmente en la sección de explorar para ver qué pasa en otras regiones.

---
*Actualizado el 01 de Marzo, 2026*
