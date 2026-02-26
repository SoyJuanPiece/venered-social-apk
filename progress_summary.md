# Resumen del Progreso y Soluciones Aplicadas

Este documento resume los problemas encontrados y las soluciones implementadas durante el proceso de depuración y mejora de la aplicación `venered_social`.

## 1. Análisis Inicial del Proyecto

- El proyecto `venered_social` es una aplicación de redes sociales basada en Flutter con un backend en Supabase.
- El backend (`schema.sql`) está bien diseñado, con tablas para perfiles, publicaciones, likes y seguidores, y utiliza RLS y triggers para la creación automática de perfiles.
- El frontend (`lib/main.dart`) estaba en una etapa temprana, manejando la autenticación pero con UI básicas y una arquitectura no modular.
- Se identificó una inconsistencia arquitectónica clave en la creación de perfiles de usuario (manual en Flutter vs. automática vía trigger en Supabase).

## 2. Problema: Fallo de Compilación en GitHub Actions (Android v2 Embedding)

### Descripción del Error
El workflow de GitHub Actions fallaba con un error relacionado con `flutter pub get` y una advertencia sobre la "versión deprecada del Android embedding", indicando que el plugin `app_links` requería la v2.

### Solución
1.  **Migración a Android v2 Embedding:** Se modificó `android/app/src/main/AndroidManifest.xml` para alinearlo con la v2 embedding, eliminando `android:name="${applicationName}"` y cambiando `android:name=".MainActivity"` a `android:name="io.flutter.embedding.android.FlutterActivity"`. Posteriormente se revirtió a `.MainActivity` al añadir el archivo Java personalizado.
2.  **Actualización de Dependencias:** Se eliminó `pubspec.lock` y se ejecutó `flutter pub get` para resolver las dependencias limpiamente.
3.  **Versión de Flutter en CI:** Se actualizó la versión de Flutter en `.github/workflows/build.yml` de `3.19.6` a `3.35.2`.

## 3. Problema: Error de Compilación en Gradle (Sintaxis de Kotlin)

### Descripción del Error
Errores de script de compilación de Kotlin en `android/app/build.gradle.kts`, específicamente `Expression 'versionCode' of type 'Int' cannot be invoked as a function.`.

### Solución
- Se corrigió la sintaxis en `android/app/build.gradle.kts`, cambiando `flutter.versionCode()` a `flutter.versionCode` y `flutter.versionName()` a `flutter.versionName`.

## 4. Problema: `SocketException` en Android (Falta Permiso de Internet)

### Descripción del Error
La aplicación lanzaba un `SocketException` al intentar comunicarse con Supabase.

### Solución
- Se añadió el permiso `android.permission.INTERNET` al archivo `android/app/src/main/AndroidManifest.xml`.

## 5. Problema: Error de Base de Datos de Supabase (NULL username en `profiles`)

### Descripción del Error
Fallo en el registro debido a `null value in column "username"`.

### Solución
1.  **Modificación Flutter:** Se actualizó `_register` para pasar el `username` como metadato al método `supabase.auth.signUp`.
2.  **Trigger SQL:** Se actualizó `public.handle_new_user()` para incluir lógica de `COALESCE` y generar nombres de usuario por defecto si fallaba la captura de metadatos.

## 6. Evolución de la Interfaz y Experiencia de Usuario (UI/UX)

### Rediseño "Venered Original"
- **Identidad Propia:** Se abandonó el diseño clonado de Instagram por uno de "Tarjetas Burbuja" con bordes muy redondeados (`borderRadius: 24`), sombras suaves y mayor aire entre secciones.
- **Login y Registro:** Rediseño total con tipografía elegante (`Billabong` placeholder), minimalismo extremo y eliminación de banners azules gigantes.
- **Barra de Historias:** Implementación de una barra horizontal de "Stories" con degradados vibrantes para dar vida al feed.

### Animaciones y Multimedia
- **Like Animado:** Implementación de animación de corazón gigante con rebote elástico al hacer doble toque en las fotos.
- **Visualizador Full-Screen:** Integración de Hero animations para ver fotos de posts y de perfil en pantalla completa con soporte para zoom.
- **Glassmorphism:** Efectos de desenfoque y transparencia en AppBars para una sensación premium.

## 7. Funcionalidades Avanzadas Implementadas

- **Comentarios en Tiempo Real:** Migración de `Future` a `Streams` en Supabase para que los comentarios aparezcan instantáneamente sin recargar.
- **Sistema de Guardado Real:** Creación de la tabla `saved_posts` y lógica completa para guardar/deshacer guardado desde el feed y verlos en el perfil.
- **Gestión de Temas:** Implementación de un `ThemeManager` con `shared_preferences` para permitir el cambio manual entre Modo Claro, Oscuro y Sistema.
- **Publicaciones Versátiles:** Opción de usar la Cámara o Galería, y soporte para posts de solo texto con fondos degradados.
- **Deep Linking & Sharing:** Generación de enlaces reales (`venered.social/post/ID`) para compartir publicaciones en lugar de URLs de imágenes.

## 8. Optimizaciones de DevOps y Base de Datos

- **CI/CD Robusto:**
    - Generación automática de **GitHub Releases** con notas de cambio basadas en commits.
    - Compresión de APK a **ZIP** para evitar límites de tamaño en el envío por Telegram.
    - Implementación de caché para Flutter y Gradle en GitHub Actions.
- **Mantenimiento SQL:**
    - Script `clean_all_data.sql` para reinicio total de la base de datos.
    - Migraciones "Safe" que evitan errores de "Duplicate Object" en Supabase usando bloques `DO EXCEPTION`.
    - Borrado sincronizado de imágenes en **ImgBB** al eliminar publicaciones mediante el uso de `image_deletehash`.

## Próximas Tareas Pendientes

- Implementación del sistema de Mensajería Directa (DMs).
- Verificación de dominio para App Links.
- Sistema de notificaciones push en tiempo real.
