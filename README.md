# Venered Social

Aplicacion social inspirada en Instagram/Threads, desarrollada en Flutter con backend en Supabase.
Incluye feed, historias, chat en tiempo real, notificaciones push y pipeline de compilacion automatica para Android.

## Funcionalidades
- Feed con publicaciones de texto e imagen.
- Likes y comentarios por publicacion.
- Historias con expiracion automatica.
- Mensajeria en tiempo real.
- Notificaciones push con Firebase Cloud Messaging.
- Perfil de usuario editable y flujo de verificacion.
- Compatibilidad con Android, iOS, Web y Desktop.

## Stack tecnico
- Flutter 3.24.5 y Dart 3.5.4.
- Supabase: Auth, PostgreSQL, Realtime y politicas RLS.
- Firebase Cloud Messaging para push.
- Backend Node/Express para soporte de media en historias.

## Estructura del proyecto
- lib: aplicacion Flutter (pantallas, widgets, servicios).
- supabase: esquema SQL, migraciones y configuracion.
- almacenamiento-temporal: servicio Node para flujo hibrido de historias.
- test: pruebas de widgets y flujo base.
- .github/workflows: CI/CD de build y release.

## Requisitos
- Flutter 3.24.5+
- Dart 3.5.4+
- Node.js 18+ (para almacenamiento-temporal)
- Proyecto Supabase configurado
- Firebase configurado para push en Android/iOS

## Ejecucion local

### 1) App Flutter
```bash
flutter pub get
flutter run
```

### 2) Backend de historias (opcional)
```bash
cd almacenamiento-temporal
npm install
npm run dev
```

## Base de datos y migraciones
- Script principal SQL: supabase/MASTER_SETUP_VENERED_FINAL.sql
- Migraciones versionadas: supabase/migrations
- Guia de aplicacion manual: MIGRATION_INSTRUCTIONS.md
- Script auxiliar: apply_migrations.sh

## CI/CD
El workflow de GitHub Actions compila APK por ABI, genera App Bundle y crea release al publicar tags.

Archivo de referencia: .github/workflows/build.yml

## Notas de despliegue
- En entorno Web bajo HTTPS, endpoints HTTP se bloquean por Mixed Content.
- Para habilitar video de historias en Web, el backend de historias debe publicarse con HTTPS.

## Testing
- Pruebas actuales en test/app_test.dart y test/user_search_dialog_test.dart.
- Se recomienda ampliar cobertura con pruebas unitarias de servicios y validaciones de negocio.

## Licencia
Este proyecto es Source Available para uso personal y no comercial.
Mas informacion en LICENSE.
