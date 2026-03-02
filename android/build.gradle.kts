buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Forzar versiones globales
    project.extra.set("flutter.compileSdkVersion", 35)
    project.extra.set("flutter.targetSdkVersion", 35)
    project.extra.set("flutter.minSdkVersion", 23)
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // PARCHE DE COMPATIBILIDAD KOTLIN DSL
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null && android is com.android.build.gradle.BaseExtension) {
            android.compileSdkVersion(35)
            
            // Inyectar la extensión 'flutter' que esperan algunos plugins antiguos
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

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
