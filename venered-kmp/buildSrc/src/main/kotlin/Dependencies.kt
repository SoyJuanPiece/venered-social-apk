// Configuración de composicion de módulos de Gradle

// Definición del repositorio de artefactos
repositories {
    google()
    mavenCentral()
    maven("https://oss.sonatype.org/content/repositories/snapshots/")
}

// Versiones centralizadas de dependencias
object Versions {
    const val kotlin = "1.9.20"
    const val gradle = "8.1.4"
    const val compose = "1.6.0"
    const val composeCompiler = "1.5.4"
    const val coroutines = "1.7.3"
    const val ktor = "2.3.6"
    const val sqldelight = "2.0.1"
    const val datetime = "0.5.0"
    const val serialization = "1.6.0"
    
    // Android
    const val compileSdk = 34
    const val targetSdk = 34
    const val minSdk = 24
    
    // AndroidX
    const val appcompat = "1.6.1"
    const val material = "1.10.0"
    const val lifecycle = "2.6.2"
    const val navigation = "2.7.5"
    const val activity = "1.8.1"
    
    // Firebase
    const val firebase = "32.7.0"
    const val firebaseMessaging = "23.4.0"
    
    // Coil
    const val coil = "2.5.0"
}

// Definición de dependencias comunes
object Dependencies {
    // Kotlin
    const val kotlinStdlib = "org.jetbrains.kotlin:kotlin-stdlib:${Versions.kotlin}"
    
    // Coroutines
    const val coroutinesCore = "org.jetbrains.kotlinx:kotlinx-coroutines-core:${Versions.coroutines}"
    const val coroutinesAndroid = "org.jetbrains.kotlinx:kotlinx-coroutines-android:${Versions.coroutines}"
    
    // Serialization
    const val serializationJson = "org.jetbrains.kotlinx:kotlinx-serialization-json:${Versions.serialization}"
    
    // DateTime
    const val datetime = "org.jetbrains.kotlinx:kotlinx-datetime:${Versions.datetime}"
    
    // Ktor
    const val ktorCore = "io.ktor:ktor-client-core:${Versions.ktor}"
    const val ktorAndroid = "io.ktor:ktor-client-android:${Versions.ktor}"
    const val ktorIos = "io.ktor:ktor-client-ios:${Versions.ktor}"
    const val ktorJson = "io.ktor:ktor-client-json:${Versions.ktor}"
    const val ktorSerialization = "io.ktor:ktor-client-serialization:${Versions.ktor}"
    
    // SQLDelight
    const val sqldelightRuntime = "app.cash.sqldelight:runtime:${Versions.sqldelight}"
    const val sqldelightAndroid = "app.cash.sqldelight:android-driver:${Versions.sqldelight}"
    const val sqldelightNative = "app.cash.sqldelight:native-driver:${Versions.sqldelight}"
    
    // UUID
    const val uuid = "com.benasher44:uuid:0.7.1"
}
