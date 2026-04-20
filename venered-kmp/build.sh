#!/bin/bash
# Script para compilar el proyecto Venered KMP

set -e

echo "🔨 Compilando Venered KMP..."

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
./gradlew clean

# Compilar módulo compartido
echo "📦 Compilando módulo compartido..."
./gradlew shared:build

# Compilar Android
echo "🤖 Compilando Android..."
./gradlew androidApp:build

# Compilar iOS (requiere macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Compilando iOS..."
    ./gradlew iosApp:build
else
    echo "⚠️ iOS solo se puede compilar en macOS"
fi

echo "✅ ¡Compilación exitosa!"
