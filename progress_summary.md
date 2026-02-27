# Resumen de Progreso - Venered Social

Este documento resume las mejoras y cambios más recientes implementados en la aplicación Venered Social.

## Mejoras Recientes (Julio 2024)

### 1. Funcionalidad de Búsqueda y Navegación de Perfiles
- **Problema:** Los usuarios no podían navegar a los perfiles de otros usuarios desde los resultados de búsqueda.
- **Solución:** Se ha implementado la funcionalidad que permite a los usuarios tocar el nombre de un usuario en los resultados de búsqueda para ser redirigidos a su perfil.

### 2. Mejora en la Sección de Comentarios
- **Problema:**
    - No se mostraban los nombres de los usuarios que habían comentado.
    - No era posible acceder a los perfiles de los usuarios desde la sección de comentarios.
- **Solución:**
    - Se ha modificado la consulta a la base de datos para incluir la información del perfil del usuario (nombre y foto de perfil) junto con cada comentario.
    - Se ha rediseñado la interfaz de la sección de comentarios para mostrar la foto de perfil y el nombre de usuario.
    - Se ha añadido la funcionalidad de que al tocar en un comentario, el usuario es redirigido al perfil del autor del comentario.

### 3. Pantalla de Perfil Dinámica
- **Problema:** La pantalla de perfil solo mostraba la información del usuario que había iniciado sesión.
- **Solución:** Se ha modificado la pantalla de perfil para que muestre la información de cualquier usuario de la aplicación.
    - Cuando se visita el perfil de otro usuario, se muestran los botones "Seguir" (o "Dejar de seguir") y "Mensaje".

### 4. Configuración de GitHub Actions
- **Problema:** La compilación automática no se iniciaba al hacer `push` a la rama `main`.
- **Solución:** Se ha creado un nuevo tag (`v1.52.35`) para activar el workflow de GitHub Actions y compilar la aplicación. Adicionalmente se ha identificado que el workflow solo se activa con tags y no con push a main.

### 5. Corrección de Errores de Compilación
- **Problema:** La aplicación no compilaba debido a errores relacionados con la actualización de la librería de Supabase.
- **Solución:**
    - Se ha corregido la llamada a la `ChatScreen` para pasar los parámetros correctos.
    - Se ha actualizado el método `stream` a `asStream` en las consultas de Supabase.
    - Se ha corregido el orden de los métodos en las consultas de Supabase para asegurar que los filtros se aplican antes de crear el stream.

## Próximos Pasos
- [ ] Implementar la funcionalidad de "Seguir" y "Dejar de seguir".
- [ ] Implementar la funcionalidad de "Mensaje".
- [ ] Mejorar la interfaz de la pantalla de perfil.