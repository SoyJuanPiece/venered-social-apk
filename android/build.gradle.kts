buildscript {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1")
        classpath("com.onesignal:onesignal-gradle-plugin:[0.12.10, 0.99.99]")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // INYECCIÓN TEMPRANA DE PROPIEDADES (Para record_android y otros)
    project.plugins.configureEach {
        if (this is com.android.build.gradle.LibraryPlugin || this is com.android.build.gradle.AppPlugin) {
            val android = project.extensions.getByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                android.compileSdkVersion(35)
                
                // Creamos el objeto 'flutter' que el plugin busca en Groovy
                val extensionAware = android as org.gradle.api.plugins.ExtensionAware
                if (extensionAware.extensions.findByName("flutter") == null) {
                    extensionAware.extensions.add("flutter", mapOf(
                        "compileSdkVersion" to 35,
                        "targetSdkVersion" to 35,
                        "minSdkVersion" to 23
                    ))
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
