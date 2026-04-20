#!/usr/bin/env bash
# Guía de instalación para Venered KMP

echo "🚀 Instalando Venered KMP..."

# Validar requisitos
echo "✅ Verificando requisitos..."

# Verificar gradle
if ! command -v gradle &> /dev/null; then
    echo "⚠️ Gradle no encontrado. Por favor instálalo."
    exit 1
fi

# Verificar Java
if ! command -v java &> /dev/null; then
    echo "⚠️ Java no encontrado. Por favor instala JDK 11+"
    exit 1
fi

echo "✅ Todos los requisitos están instalados"

# Crear gradle.properties si no existe
if [ ! -f "gradle.properties" ]; then
    echo "📝 Creando gradle.properties..."
    touch gradle.properties
fi

# Crear local.properties si no existe
if [ ! -f "local.properties" ]; then
    echo "📝 Creando local.properties..."
    touch local.properties
fi

echo ""
echo "🔧 Instalación de dependencias..."
./gradlew wrapper --gradle-version 8.1.4

echo ""
echo "✅ ¡Instalación completada!"
echo ""
echo "Próximos pasos:"
echo "1. Android:    ./gradlew androidApp:installDebug"
echo "2. iOS:        ./gradlew iosApp:build (en macOS)"
echo "3. Tests:      ./gradlew test"
