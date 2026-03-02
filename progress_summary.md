# Progreso del Proyecto - Venered Social

## Estado Actual: v1.7 (Remodelación de Mensajería y Persistencia)

### Últimas Mejoras Implementadas
- **Remodelación Total del Chat:**
    - **Interfaz Unificada:** Se añadió el botón `+` para agrupar opciones de Cámara y Galería, limpiando la barra de escritura.
    - **Botón de Enviar Inteligente:** Corregida la lógica del botón derecho; ahora conmuta correctamente entre Micrófono (vacío) y Enviar (con texto).
- **Persistencia y Caché Local (WhatsApp Style):**
    - **SQLite Integrado:** Implementada base de datos local para rastrear archivos descargados.
    - **Almacenamiento Permanente:** Las fotos y audios se guardan en la memoria interna del teléfono para acceso offline.
    - **Independencia del Servidor:** Aunque los archivos se borren de la nube, el usuario mantiene su copia local.
- **Optimización de Recursos:**
    - **Compresión Global:** Aplicada compresión automática a fotos de chat, posts y perfil (máx 500KB).
    - **Almacenamiento en Nube:** Extendida la vida de los archivos en Supabase Storage a **7 días** antes del auto-borrado.
- **Chat Blindado:**
    - Reforzada la lógica de grabación de audio con gestos de cancelación (deslizar para borrar) y reseteo automático de estados en caso de error.

### Pendientes / Próximos Pasos
1. **Venered Market:** Iniciar el desarrollo de la sección de compra/venta.
2. **Historias (Stories):** Implementar el carrusel de estados temporales en el feed.
3. **Notificaciones In-App:** Añadir avisos visuales elegantes mientras el usuario navega dentro de la app.

---
*Actualizado el 01 de Marzo, 2026*
