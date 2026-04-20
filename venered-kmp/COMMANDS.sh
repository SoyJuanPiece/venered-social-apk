#!/bin/bash
# Comandos Útiles - Venered KMP Reference

# ============================================================================
# LIMPIAR Y RESETEAR
# ============================================================================

# Limpiar todo
./gradlew clean

# Limpiar y compilar desde cero
./gradlew clean build

# Resetear Android Studio cache
rm -rf .gradle
rm -rf .idea
rm -rf */build

# ============================================================================
# COMPILACIÓN
# ============================================================================

# Compilar module compartido
./gradlew shared:build

# Compilar Android
./gradlew androidApp:build

# Compilar iOS (macOS solo)
./gradlew iosApp:build

# Compilar APK debug
./gradlew androidApp:assembleDebug

# Compilar APK release (firmado)
./gradlew androidApp:assembleRelease

# ============================================================================
# INSTALACIÓN Y EJECUCIÓN
# ============================================================================

# Instalar en emulador/dispositivo Debug
./gradlew androidApp:installDebug

# Instalar en emulador/dispositivo Release
./gradlew androidApp:installRelease

# Instalar y ejecutar Debug
./gradlew androidApp:installDebug
adb shell am start -n com.venered.social/.MainActivity

# Crear archivos IDE para Android Studio
./gradlew androidApp:idea

# ============================================================================
# TESTING
# ============================================================================

# Tests unitarios (módulo compartido)
./gradlew shared:test

# Tests unitarios (Android)
./gradlew androidApp:test

# Tests instrumentados (Android, requiere emulador)
./gradlew androidApp:connectedAndroidTest

# Ejecutar tests y generar reporte
./gradlew test --info

# ============================================================================
# GESTIÓN DE EMULADORES Y DISPOSITIVOS
# ============================================================================

# Listar emuladores disponibles
emulator -list-avds

# Iniciar emulador específico
emulator -avd <nombre_emulador> &

# Listar dispositivos conectados
adb devices

# Conectar a dispositivo remoto
adb connect <ip:puerto>

# Desconectar dispositivo
adb disconnect <ip:puerto>

# ============================================================================
# LOGS Y DEBUG
# ============================================================================

# Ver logs en tiempo real
adb logcat | grep "Venered"

# Ver todos los logs
adb logcat

# Limpiar logs
adb logcat -c

# Ver logs de crash específicos
adb logcat | grep "FATAL"

# Capturar logs a archivo
adb logcat > logs.txt &

# ============================================================================
# PERFORMANCE Y PROFILING
# ============================================================================

# Medir tiempo de compilación
./gradlew androidApp:build --profile

# Ver tareas lentas
./gradlew androidApp:build --profile --warn

# Analisar dependencias
./gradlew dependencies

# Generar dependency tree
./gradlew androidApp:dependencies > dependencies.txt

# ============================================================================
# GRADLE TASKS
# ============================================================================

# Listar todas las tasks disponibles
./gradlew tasks

# Listar tasks de un módulo específico
./gradlew shared:tasks

# Ejecutar task con verbose
./gradlew androidApp:build --info

# Ejecutar task con debug
./gradlew androidApp:build --debug

# ============================================================================
# GIT COMMANDS (Si usas Git)
# ============================================================================

# Inicializar repositorio
git init

# Agregar archivos
git add .

# Commit
git commit -m "Tu mensaje"

# Push a repositorio remoto
git push origin main

# Pull cambios remotos
git pull origin main

# Ver cambios
git status

# Ver log de commits
git log

# ============================================================================
# ANDROID ESPECÍFICO
# ============================================================================

# Generar apk con gradle wrapper
./gradlew wrapper --gradle-version 8.1.4

# Forcejar compilación de Kotlin
./gradlew kotlinCompile

# Verificar build.gradle.kts
./gradlew :androidApp:projects

# ============================================================================
# IOS ESPECÍFICO (macOS)
# ============================================================================

# Abrir workspace de iOS en Xcode
open iosApp/Venered.xcworkspace

# Compilar desde línea de comandos
xcodebuild -workspace iosApp/Venered.xcworkspace -scheme VeneredApp -configuration Debug

# Listar simuladores disponibles
xcrun simctl list devices

# Instalar en simulador
xcrun simctl install booted iosApp/build/app.app

# ============================================================================
# FIRMAR APK (RELEASE)
# ============================================================================

# Generar keystore (primera vez)
keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000

# Ver información del keystore
keytool -list -v -keystore release.keystore

# ============================================================================
# UTILIDADES
# ============================================================================

# Formatear código Kotlin
./gradlew :shared:ktlintFormat
./gradlew :androidApp:ktlintFormat

# Verificar Lint
./gradlew :androidApp:lint

# Actualizar Gradle
./gradlew wrapper --gradle-version 8.1.4

# Mostrar versión de Gradle
./gradlew --version

# ============================================================================
# BUILD OPTIMIZATION
# ============================================================================

# Build paralelo
./gradlew androidApp:build -x test --parallel

# Habilitar caché de build
./gradlew androidApp:build --build-cache

# Ejecutar sin caché
./gradlew androidApp:build --no-build-cache

# Modo daemon (más rápido)
./gradlew --daemon androidApp:build

# Parar daemon
./gradlew --stop

# ============================================================================
# TROUBLESHOOTING
# ============================================================================

# Sincronizar Gradle (Android Studio)
./gradlew sync

# Limpiar cache de gradle
rm -rf ~/.gradle/caches/

# Resetear gradle daemon
./gradlew --stop && ./gradlew clean build

# Ver versión de JDK usado
./gradlew --version

# Cambiar asignación de memoria para gradle
export GRADLE_OPTS="-Xmx2048m -XX:MaxMetaspaceSize=512m"

# ============================================================================
# PUBLICACIÓN
# ============================================================================

# Build APK release
./gradlew androidApp:bundleRelease

# Build AAB (Android App Bundle) para Play Store
./gradlew android:bundle

# Firmar APK final
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
    -keystore release.keystore \
    app-release-unsigned.apk release_key

# Alinear APK (zipalign)
zipalign -v 4 app-release-unsigned.apk app-release.apk

# ============================================================================
# VARIABLES DE ENTORNO
# ============================================================================

# Establecer temporalmente (Linux/Mac)
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
export GRADLE_OPTS="-Xmx2g -XX:MaxMetaspaceSize=512m"

# En Windows (CMD)
set GRADLE_OPTS=-Xmx2g -XX:MaxMetaspaceSize=512m

# ============================================================================
# ATAJOS PRÁCTICOS
# ============================================================================

# Función para compilar rápido
quickbuild() {
    ./gradlew clean androidApp:installDebug
}

# Función para ejecutar tests
quicktest() {
    ./gradlew shared:test androidApp:test
}

# Alias útil (agregar a ~/.bashrc o ~/.zshrc)
alias kmpbuild="./gradlew build"
alias kmpdebug="./gradlew androidApp:installDebug"
alias kmptest="./gradlew test"
alias kmpclean="./gradlew clean"
