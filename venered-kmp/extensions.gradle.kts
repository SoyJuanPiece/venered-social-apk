// Archivo de extensiones para el proyecto
// Usar con: apply(from = "extensions.gradle.kts")

fun String.quote(): String = "\"$this\""

ext["versionName"] = "1.0.0"
ext["versionCode"] = 1

// Dependencias comunes
ext["kotlin_version"] = "1.9.20"
ext["compose_version"] = "1.6.0"
ext["androidx_version"] = "2023.12.00"
ext["coroutines_version"] = "1.7.3"
ext["ktor_version"] = "2.3.6"
ext["sqldelight_version"] = "2.0.1"
ext["firebase_version"] = "32.7.0"

// Funciones auxiliares
fun getLocalProperties(): Map<String, String> {
    val properties = mutableMapOf<String, String>()
    val localPropertiesFile = rootProject.file("local.properties")
    
    if (localPropertiesFile.exists()) {
        localPropertiesFile.bufferedReader().use { reader ->
            reader.forEachLine { line ->
                if (line.isNotEmpty() && !line.startsWith("#")) {
                    val (key, value) = line.split("=", limit = 2).let { 
                        if (it.size == 2) it[0] to it[1] else return@forEachLine 
                    }
                    properties[key] = value
                }
            }
        }
    }
    return properties
}
