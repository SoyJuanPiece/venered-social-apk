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
    
    // Forzar versiones globales para todos los plugins (incluyendo record_android)
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
    
    // PARCHE DEFINITIVO: Inyectar propiedad 'flutter' en la extensión 'android' de los subproyectos
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                android.compileSdkVersion(35)
                
                // Si el plugin busca 'android.flutter', se lo proporcionamos
                if (!android.hasProperty("flutter")) {
                    (android as ExtensionAware).extensions.add("flutter", mapOf(
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
