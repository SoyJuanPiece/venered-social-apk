# Venered Social

Red social tipo Instagram/Threads construida en Flutter con Supabase, mensajeria en tiempo real, historias y pipeline de APK automatizado.

## Caracteristicas principales
- Feed con posts, likes y comentarios.
- Historias con expiracion y viewer interactivo.
- Chat en tiempo real.
- Notificaciones push con Firebase FCM.
- Perfil editable, seguidores/seguidos y paneles auxiliares (moderacion/verificacion).
- Soporte multiplataforma (Android, iOS, Web, Desktop).

## Politica multimedia actual
- Imagenes:
   - Perfil, posts, mensajes e historias usan ImgBB.
   - Nombres de archivos estandarizados por categoria/usuario.
- Video:
   - Solo historias en movil mediante backend Telegram.
   - En web, video de historias esta deshabilitado mientras el backend siga sin HTTPS.

## Stack
- Flutter `3.24.5` (Dart `3.5.4`).
- Supabase (Auth, Postgres, Realtime, Storage).
- Firebase Cloud Messaging para push.
- Backend Node/Express en `almacenamiento-temporal` para flujo hibrido de historias.

## Estructura relevante
- `lib/`: app Flutter.
- `supabase/`: SQL y configuracion backend.
- `almacenamiento-temporal/`: servicio Node para historias/media.
- `test/`: pruebas de widgets y flujo base.

## Ejecucion local

### Flutter
```bash
flutter pub get
flutter run
```

### Backend de historias (Node)
```bash
cd almacenamiento-temporal
npm install
npm run dev
```

## Notas de entorno
- Si pruebas la app web desde HTTPS (por ejemplo Codespaces), cualquier endpoint HTTP sera bloqueado por el navegador (Mixed Content).
- Para habilitar video de historias en web se requiere exponer el backend de historias con HTTPS.

## Licencia
Este proyecto es Source Available con uso personal y no comercial.
Consulta [LICENSE](LICENSE).

## Creditos
Desarrollado por JuanPiece.
