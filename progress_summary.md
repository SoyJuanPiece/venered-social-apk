# Progreso del Proyecto - Venered Social

## Estado Actual: v1.4 (Fase de Multimedia y Chat Inteligente)

### Últimas Mejoras Implementadas
- **Notas de Voz Inteligentes:**
    - **Grabación y Compresión:** Audios limitados a 1 minuto con compresión AAC a 32kbps para ahorro de datos.
    - **Almacenamiento Efímero (24h):** Los audios se eliminan automáticamente de Supabase Storage cada día para optimizar costos.
    - **Caché Local:** La app guarda permanentemente los audios enviados y recibidos en la memoria del teléfono.
    - **Sistema de Rescate (Re-upload):** Si un audio expira en el servidor, la app solicita automáticamente al emisor que lo resuba desde su copia local.
- **Sistema de Moderación y Verificación:**
    - **Gestión de Roles Pro:** Nueva pestaña en el panel de administración para buscar usuarios y cambiar su rango (Usuario, Moderador, Admin).
    - **Verificación Dinámica:** Flujo completo de solicitud de check azul y aprobación manual.
    - **Seguridad 2FA:** Fix aplicado para el parámetro `issuer` en el enrolamiento de Supabase.
- **Mantenimiento Técnico:**
    - Consolidado script maestro `MASTER_SETUP_VENERED.sql` (v1.3) y limpieza de scripts SQL.
    - Permisos SQL actualizados para permitir a administradores gestionar perfiles.

### Pendientes / Próximos Pasos
1. **Venered Market:** Implementar sección de compra/venta regionalizada por estado.
2. **Historias (Stories):** Sistema de publicaciones que desaparecen en 24 horas.
3. **Optimización de UI:** Pulir el diseño de las burbujas de audio en el chat.

---
*Actualizado el 01 de Marzo, 2026*
