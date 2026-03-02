# Progreso del Proyecto - Venered Social

## Estado Actual: v1.8 (Historias y Almacenamiento Telegram)

### Últimas Mejoras Implementadas
- **Sistema de Historias (Stories):**
    - **Interfaz Estilo Instagram:** Implementado carrusel horizontal en el feed principal con círculos de perfil y gradientes dinámicos.
    - **Visor de Historias Pro:** Creado visor a pantalla completa con barras de progreso segmentadas, soporte para gestos (tocar lados para navegar, deslizar abajo para cerrar).
    - **Interacción:** Añadida capacidad de dar "Like" y enviar respuestas directas desde la historia.
- **Almacenamiento Ilimitado vía Telegram:**
    - **Integración de Video:** La app ahora permite publicar videos pesados usando Telegram como CDN gratuito.
    - **Servidor Node.js:** Implementado microservicio para gestionar subidas, file_ids y generación de URLs frescas (bypass de expiración de 1h de Telegram).
    - **Persistencia Híbrida:** Los metadatos se guardan en Supabase, mientras que el binario vive en la nube de Telegram.
- **Infraestructura de Red:**
    - **Hosting Externo:** Configurada la app para conectar con el servidor en `toby.hidencloud.com:24652`.
    - **Seguridad Android:** Habilitado `usesCleartextTraffic` para compatibilidad con el hosting HTTP.

### Pendientes / Próximos Pasos
1. **Venered Market:** Iniciar el desarrollo de la sección de compra/venta.
2. **Notificaciones In-App:** Añadir avisos visuales elegantes mientras el usuario navega dentro de la app.
3. **Optimización de Visor:** Añadir pre-carga (pre-fetching) de la siguiente historia para transiciones instantáneas.

---
*Actualizado el 02 de Marzo, 2026*
