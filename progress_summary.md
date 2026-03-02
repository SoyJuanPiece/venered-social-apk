# Progreso del Proyecto - Venered Social

## Estado Actual: v1.9.1 (Corrección de Compilación R8)

### Últimas Mejoras Implementadas
- **Corrección de Build Release:**
    - **ProGuard/R8 Fix:** Añadidas reglas `-dontwarn` para las clases de `google.android.play.core`. Esto resuelve el error de compilación en GitHub Actions causado por referencias internas de Flutter a librerías de la Play Store que no están presentes en el proyecto.
- **Estabilidad Android:**
    - **Migración a Kotlin:** Convertido `MainActivity` a Kotlin y reubicado en la estructura estándar para evitar errores de clase no encontrada (`ClassNotFoundException`).
    - **Refuerzo de ProGuard:** Añadidas reglas específicas para proteger las clases críticas de Flutter y la actividad principal durante la minificación de release.
- **Optimización de Audio:**
    - **Fix Notas de Voz:** Ajustada la configuración de grabación a `44100Hz` y `64kbps` para resolver errores de reproducción y longitud de archivo inválida en Android.
- **Sistema de Diagnóstico:**
    - **Logs de Subida:** Implementado logging detallado en el servidor Node.js y en la app para rastrear fallos en el sistema de historias.
    - **Timeouts de Red:** Añadido tiempo de espera de 30s en peticiones de subida para evitar bloqueos silenciosos en la UI.

### Pendientes / Próximos Pasos
1. **Venered Market:** Iniciar el desarrollo de la sección de compra/venta.
2. **Notificaciones In-App:** Añadir avisos visuales elegantes mientras el usuario navega dentro de la app.
3. **Depuración de Historias:** Validar la conexión con el servidor externo tras los nuevos logs implementados.

---
*Actualizado el 02 de Marzo, 2026*
