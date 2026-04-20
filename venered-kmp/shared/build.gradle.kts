plugins {
    kotlin("multiplatform")
    kotlin("plugin.serialization") version "1.9.20"
    id("com.android.library")
}

kotlin {
    androidTarget()
    
    iosX64()
    iosArm64()
    iosSimulatorArm64()

    sourceSets {
        val commonMain by getting {
            dependencies {
                // Coroutines
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
                
                // Serialization
                implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
                
                // HTTP Client
                implementation("io.ktor:ktor-client-core:2.3.6")
                implementation("io.ktor:ktor-client-serialization:2.3.6")
                implementation("io.ktor:ktor-client-json:2.3.6")
                
                // DateTime
                implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.5.0")
                
                // Database (SQLDelight)
                implementation("app.cash.sqldelight:runtime:2.0.1")
                
                // UUID
                implementation("com.benasher44:uuid:0.7.1")
            }
        }

        val androidMain by getting {
            dependencies {
                implementation("io.ktor:ktor-client-android:2.3.6")
                implementation("app.cash.sqldelight:android-driver:2.0.1")
                
                // Android specifics
                implementation("androidx.appcompat:appcompat:1.6.1")
                implementation("com.google.android.material:material:1.10.0")
                implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.2")
                
                // Firebase
                implementation("com.google.firebase:firebase-messaging-ktx:23.4.0")
                implementation("com.google.firebase:firebase-core:21.1.1")
            }
        }

        val iosMain by getting {
            dependencies {
                implementation("io.ktor:ktor-client-ios:2.3.6")
                implementation("app.cash.sqldelight:native-driver:2.0.1")
            }
        }

        val commonTest by getting {
            dependencies {
                implementation(kotlin("test"))
            }
        }
    }
}

android {
    namespace = "com.venered.social"
    compileSdk = 34

    defaultConfig {
        minSdk = 24
    }
}
