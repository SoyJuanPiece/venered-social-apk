# Progreso del Proyecto - Venered Social

## Estado Actual: v1.3 (Fase de Moderación, Regionalización y Seguridad)

### Últimas Mejoras Implementadas
- **Sistema de Moderación Integral:**
    - **Panel de Moderación:** Nueva interfaz para moderadores y administradores para gestionar la comunidad.
    - **Reportes de Contenido:** Los usuarios pueden reportar publicaciones por spam, acoso o contenido inapropiado.
    - **Sistema de Baneo:** Lógica en el servidor que impide a usuarios suspendidos publicar contenido nuevo.
    - **Verificación de Cuentas (Check Azul):** Flujo completo de solicitud desde ajustes y aprobación manual por moderadores.
- **Regionalización Avanzada (Venezuela):**
    - **Selector de Estados en Perfil:** Ahora los usuarios pueden actualizar su estado desde la edición de perfil.
    - **Regla de 7 Días:** Restricción automatizada en base de datos para cambios de ubicación regional.
    - **Detección por IP:** Bloqueo de registros fuera de Venezuela y pre-selección automática de estado.
- **Seguridad y Notificaciones:**
    - **Autenticación 2FA:** Soporte opcional para Google Authenticator y Authy (Fix de nulabilidad aplicado).
    - **Notificaciones Pro:** Control de spam (1 push cada 15 min por post) y privacidad en el contenido del mensaje.
- **Mantenimiento Técnico:**
    - Consolidación del script maestro `MASTER_SETUP_VENERED.sql` (v1.3).
    - Limpieza y organización de scripts en la carpeta `/supabase`.

### Pendientes / Próximos Pasos
1. **Notas de Voz:** Integración de grabación y reproducción de audios en el chat.
2. **Explorar por Hashtags:** Implementar la búsqueda y filtrado por etiquetas.
3. **Mejoras de UI en Moderación:** Añadir más detalles sobre los usuarios reportados en el panel.

---
*Actualizado el 01 de Marzo, 2026*
