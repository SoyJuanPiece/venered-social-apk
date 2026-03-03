# Progreso del Proyecto - Venered Social

## Estado Actual: v2.1 (Depuración Crítica de Notificaciones)

### Últimas Mejoras Implementadas
- **Sistema de Historias (Stories) Pro:**
    - **Interfaz Refinada:** Icono "+" dinámico y menú de gestión de historias (borrado/añadido).
    - **Soporte Multi-historia:** Agrupación y reproducción secuencial optimizada.
- **Rendimiento y Cache (SQLite):**
    - **Carga Instantánea:** Feed y mensajes con persistencia local inmediata.
    - **Cache de Video:** Descarga única y ahorro de datos total en reproducciones recurrentes.
- **Sincronización Inteligente:**
    - **Filtro Offline:** Ocultación automática de contenido caducado (>24h).
    - **Limpieza de Disco:** Purga automática de archivos temporales al iniciar la app.
- **Depuración de Notificaciones (Completado):**
    - **Unificación SQL:** Se ha aplicado el parche de compatibilidad OneSignal v5 (`include_aliases`) en todos los scripts de Supabase (`MASTER_SETUP_VENERED.sql`, `FIX_ONESIGNAL_FINAL.sql`, etc.).
    - **Lógica Optimizada:** Integración de control de spam (1 cada 15 min para likes/comentarios) y privacidad (ocultar contenido de mensajes en push).
    - **Verificación de Triggers:** Confirmada la cadena de triggers desde mensajes/likes/comentarios hasta el envío HTTP.

### Pendientes / Próximos Pasos
1. **Prueba de Fuego:** Verificar la inserción en `public.notifications` y la cola `net.http_request_queue` tras enviar un mensaje real o simulado.
2. **Venered Market:** Iniciar el desarrollo de la sección de compra/venta (Próximamente).

---
*Actualizado el 03 de Marzo, 2026 - Fase de Depuración Push*
