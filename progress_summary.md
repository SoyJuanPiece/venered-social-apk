# Progreso del Proyecto - Venered Social

## Estado Actual: v2.0 (Sincronización Total y Cache Agresivo)

### Últimas Mejoras Implementadas
- **Sistema de Historias (Stories) Pro:**
    - **Interfaz Refinada:** El icono "+" ahora es dinámico (desaparece si ya tienes una historia).
    - **Menú de Gestión:** Añadido menú de 3 puntos dentro del visor para borrar o añadir más historias.
    - **Soporte Multi-historia:** Las historias se agrupan por usuario y se reproducen en secuencia.
- **Rendimiento y Cache (SQLite):**
    - **Carga Instantánea:** Feed y lista de mensajes ahora se guardan localmente para mostrarse de inmediato al abrir la app.
    - **Cache de Video:** Las historias se descargan una sola vez y se guardan en el cel, ahorrando 100% de datos en la segunda reproducción.
- **Sincronización Inteligente:**
    - **Filtro Offline:** La app oculta automáticamente historias de más de 24h basándose en el reloj local si no hay internet.
    - **Limpieza de Disco:** Al iniciar la app, se borran físicamente los archivos de video y fotos caducados para liberar espacio.
- **Corrección de Notificaciones:**
    - **Push Fix:** Reparada la lógica de envío desde Supabase usando el estándar moderno de OneSignal.
    - **Limpieza de Conflictos:** Eliminado el choque entre Firebase Messaging y OneSignal que bloqueaba el registro.

### Pendientes / Próximos Pasos
1. **Venered Market:** Iniciar el desarrollo de la sección de compra/venta.
2. **Notificaciones In-App:** Añadir avisos visuales elegantes mientras el usuario navega.
3. **Optimización de Perfil:** Cachear también los posts del perfil propio.

---
*Actualizado el 02 de Marzo, 2026*
