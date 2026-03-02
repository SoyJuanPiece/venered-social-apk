# Progreso del Proyecto - Venered Social

## Estado Actual: v1.5 (Optimización Extrema y Resiliencia)

### Últimas Mejoras Implementadas
- **Notas de Voz de Ahorro Extremo:**
    - **Compresión Máxima:** Audios configurados a 16kbps y 11kHz (Mono). Un minuto de audio pesa ahora ~120KB (98% menos que antes).
    - **Límite de Tiempo:** Grabaciones restringidas a 60 segundos con contador visual en tiempo real.
- **Arquitectura de Almacenamiento Efímero:**
    - **Borrado en 24h:** Los audios se eliminan de Supabase Storage diariamente para mantener el servidor ligero.
    - **Caché Permanente:** La app guarda localmente todos los audios en la memoria del teléfono al enviarlos o recibirlos.
    - **Sistema de Rescate:** Si un audio ya no está en el servidor, la app solicita automáticamente al emisor que lo resuba desde su copia local de forma transparente.
- **Seguridad y Roles:**
    - Panel de administración con gestión de roles (Admin, Mod, User) operativo desde la app.
    - Solicitudes de verificación (Check Azul) con flujo de aprobación integrado.

### Pendientes / Próximos Pasos
1. **Venered Market:** Iniciar el desarrollo de la sección de compra/venta regionalizada.
2. **Historias (Stories):** Implementar el carrusel de estados temporales en el feed.

---
*Actualizado el 01 de Marzo, 2026*
