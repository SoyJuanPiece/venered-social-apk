# Prompt para Red Social Android en Flutter (Nivel Producción)

Crea una aplicación móvil completa de red social para Android usando Flutter, inspirada en el diseño y experiencia de usuario de Instagram y Threads de Meta. El resultado debe ser un proyecto funcional, sin errores, con una interfaz moderna y minimalista, siguiendo buenas prácticas de Flutter y arquitectura limpia. La aplicación principal debe estar lista para producción, con todas las funciones necesarias para operar a nivel profesional.

## Requisitos funcionales

1. **Pantalla de inicio (Feed):**
   - Muestra publicaciones de usuarios (imágenes, texto, likes, comentarios).
   - Scroll vertical infinito.
   - Cada publicación debe mostrar: foto de perfil, nombre de usuario, imagen, descripción, número de likes y comentarios.

2. **Navegación inferior:**
   - Barra con pestañas: Inicio, Buscar, Publicar, Notificaciones, Perfil.
   - Iconos modernos y minimalistas.

3. **Perfil de usuario:**
   - Foto de perfil, biografía, número de seguidores/seguidos, publicaciones.
   - Botón para editar perfil.
   - Visualización de publicaciones propias en cuadrícula.

4. **Publicar:**
   - Permite subir fotos desde galería o cámara.
   - Escribir descripción.
   - Previsualización antes de publicar.

5. **Likes y comentarios:**
   - Sistema de likes en publicaciones.
   - Sección de comentarios con scroll.
   - Notificaciones por likes y comentarios.

6. **Buscar:**
   - Búsqueda de usuarios y publicaciones por nombre o hashtag.
   - Resultados en lista o cuadrícula.

7. **Notificaciones:**
   - Muestra notificaciones de likes, comentarios y nuevos seguidores.

8. **Autenticación:**
   - Registro y login de usuario (email y contraseña).
   - Recuperación de contraseña.

9. **Arquitectura y buenas prácticas:**
   - Usa arquitectura limpia (por ejemplo, MVVM o BLoC).
   - Código modular, reutilizable y bien documentado.
   - Manejo adecuado de estados y errores.

10. **Backend:**
   - Permite simular funcionalidades para pruebas, pero está preparado para integrar un backend real (Firebase, Supabase, AWS, etc.) cuando se decida.
   - Arquitectura desacoplada para facilitar la migración a backend real.
   - Manejo seguro de datos, autenticación, almacenamiento y notificaciones.

## Requisitos de diseño

- Interfaz moderna, minimalista y responsiva.
- Colores claros, tipografía limpia, iconografía simple.
- Animaciones suaves (transiciones, likes, carga de imágenes).
- Adaptación a diferentes tamaños de pantalla.

## Requisitos técnicos

- Flutter 3.x o superior.
- Compatible con Android 8.0+.
- Uso de paquetes recomendados: `provider` o `bloc`, `cached_network_image`, etc. (notificaciones y deep links eliminados; soporte de imágenes vuelve con ImgBB vía image_picker + http)
- Código sin errores, siguiendo buenas prácticas de Dart y Flutter.
- README con instrucciones de instalación y ejecución.
- Preparada para integración de backend real.
- Seguridad: manejo seguro de datos, validación de entradas, protección contra ataques comunes.
- Escalabilidad: arquitectura modular, desacoplada y preparada para crecimiento.
- Optimización: rendimiento eficiente, uso de caché, lazy loading, optimización de imágenes.
- Pruebas: incluye pruebas unitarias y de integración para las funciones principales.
- Accesibilidad: interfaz accesible, soporte para lectores de pantalla y navegación por teclado.
- Soporte multiplataforma: preparada para Android y posible extensión a iOS/web.

## Extras opcionales

- Soporte para modo oscuro.
- Mensajería directa entre usuarios.
- Stories (publicaciones temporales).
- Verificación de cuentas.

---

### Instrucciones para IA generadora

- Genera el proyecto Flutter completo, con todos los archivos necesarios.
- Implementa todas las funcionalidades descritas, listas para producción.
- Asegúrate de que el código compile y funcione sin errores.
- Usa nombres de clases, widgets y archivos claros y descriptivos.
- Documenta el código y agrega comentarios donde sea necesario.
- Incluye instrucciones detalladas en el README para instalar y ejecutar la app.
- Prepara la arquitectura para integración de backend real y escalabilidad.
- Implementa pruebas unitarias y de integración.
- Garantiza seguridad, accesibilidad y optimización.

---

Este prompt está diseñado para obtener una aplicación de red social en Flutter, moderna, funcional y sin errores, similar a Instagram/Threads, lista para usar y personalizar.