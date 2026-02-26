# Venered Social

Una red social moderna tipo Instagram/Threads, hecha en Flutter, lista para producción y web.

## Características principales
- Feed con animaciones y stories
- Perfil editable, seguidores/seguidos, publicaciones editables/eliminables
- Mensajería directa
- Búsqueda avanzada de usuarios y posts
- Notificaciones en tiempo real (simuladas)
- Verificación de cuentas
- Accesibilidad y adaptabilidad (a11y, dark/light)
- Pruebas automáticas incluidas

## Instalación y ejecución

1. Instala Flutter 3.x+
2. Ejecuta:
   ```
   flutter pub get
   flutter run -d chrome
   ```
3. Para web, también puedes compilar y servir:
   ```
   flutter build web
   python3 -m http.server 8090 --directory build/web
   ```

## Pruebas

El repositorio incluye tests básicos (contador y UI del diálogo de búsqueda).
Ejecuta:

```
flutter test
```

## Versionado

Cada conjunto de cambios se publica con un tag de Git para facilitar la
compilación en CI/CD. El último tag disponible es `v1.1.0`, que incluye
mejoras de diseño en mensajería, optimizaciones de RPC y configuración
de App Links.

## Estructura

## Deep Linking / App Links
La aplicación soporta enlaces universales (`https://venered.social/...`) y un esquema
personalizado `venered://`. Para que los links funcionen automáticamente en Android
será necesario:

1. Hospedar el archivo `assetlinks.json` en `https://venered.social/.well-known/assetlinks.json`.
   - El repositorio contiene un ejemplo en `web/.well-known/assetlinks.json`.
   - Reemplaza `<REPLACE_WITH_REAL_SHA256_FINGERPRINT>` con el fingerprint SHA-256 del
     certificado usado para firmar la APK/Bundle (`keytool -list -v -keystore ...`).
2. Asegurarse de que el `AndroidManifest.xml` tenga `android:autoVerify="true"` (ya está).

En iOS, agrega el dominio a la key `com.apple.developer.associated-domains` en el
`Info.plist` (ya incluido) y sube el archivo `apple-app-site-association` al servidor.

Con esto, al abrir enlaces como `https://venered.social/post/<id>` el sistema ofrecerá
abrir la aplicación directamente. También se usa `venered://post/<id>` como esquema
alternativo para correos de confirmación de Supabase.

## Créditos
Desarrollado por SoyJuanPiece y GitHub Copilot.