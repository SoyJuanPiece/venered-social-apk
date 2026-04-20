# Quick Start Guide - Venered KMP

## 🎯 En 5 Minutos

### 1. Clonar y Preparar
```bash
cd venered-kmp
chmod +x install.sh
./install.sh
```

### 2. Compilar Módulo Compartido
```bash
./gradlew shared:build
```

### 3. Ejecutar en Android
```bash
./gradlew androidApp:installDebug
```

### 4. En iOS (macOS)
```bash
./gradlew iosApp:build
open iosApp/Venered.xcodeproj
# Luego Cmd+R en Xcode
```

---

## 📋 Requisitos del Sistema

### Todos los Desarrolladores
- Git
- JDK 11+ (para Android/Kotlin)
- Gradle 8.1.4+

### Android
- Android Studio 2023.1+
- Android SDK 34
- Mínimo Android 7.0 (SDK 24)

### iOS (Solo macOS)
- Xcode 14.3+
- iOS 14.0+
- CocoaPods (opcional, para pods)

---

## 🚀 Estructura de Desarrollo

```
Tu trabajo diario estará en:

┌─ shared/
│  ├─ src/commonMain/           ← Lógica compartida
│  └─ build.gradle.kts
│
├─ androidApp/
│  └─ src/main/kotlin/          ← Pantallas Android
│
└─ iosApp/
   └─ VeneredApp.swift          ← Pantallas iOS
```

---

## 🔄 Flujo de Desarrollo Típico

### Agregar una Pantalla Nueva

#### 1. Modelo (si es necesario)
```kotlin
// shared/src/commonMain/kotlin/.../data/model/Models.kt
@Serializable
data class NewFeature(...)
```

#### 2. Repositorio
```kotlin
// shared/.../data/repository/NewRepository.kt
class NewRepository {
    suspend fun getData(): Result<List<NewFeature>>
}
```

#### 3. Casos de Uso
```kotlin
// shared/.../domain/usecase/NewUseCases.kt
class GetDataUseCase(private val repo: NewRepository) {
    suspend operator fun invoke(): Result<List<NewFeature>>
}
```

#### 4. ViewModel
```kotlin
// shared/.../presentation/viewmodel/NewViewModel.kt
class NewViewModel(private val useCase: GetDataUseCase) {
    val state: StateFlow<NewState> = ...
    fun loadData()
}
```

#### 5. Pantalla Android
```kotlin
// androidApp/.../ui/screens/NewScreen.kt
@Composable
fun NewScreen(navController: NavController) {
    val state by viewModel.state.collectAsState()
    // UI con Compose
}
```

#### 6. Pantalla iOS
```swift
// iosApp/NewScreen.swift
struct NewScreen: View {
    @ObservedObject var viewModel = NewViewModel()
    // UI con SwiftUI
}
```

---

## 🎨 Cambiar Colores/Tema

### Android Compose
```kotlin
// androidApp/ui/theme/Theme.kt
private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFF6366F1),      // Cambiar aquí
    secondary = Color(0xFFEC4899),    // Y aquí
    ...
)
```

### iOS SwiftUI
```swift
// iosApp/VeneredApp.swift
.foregroundColor(.indigo)  // Cambiar colores
```

---

## 🔐 Agregar Endpoints Nuevos

### 1. En el Repositorio
```kotlin
// shared/data/repository/YourRepository.kt
suspend fun getNewData(): Result<List<Item>> = runCatching {
    val response = client.get("$baseUrl/new_endpoint") {
        parameter("limit", 20)
    }
    response.body()
}
```

### 2. En el Caso de Uso
```kotlin
class GetNewDataUseCase(private val repo: YourRepository) {
    suspend operator fun invoke(): Result<List<Item>> {
        return repo.getNewData()
    }
}
```

### 3. En el ViewModel
```kotlin
class YourViewModel(private val useCase: GetNewDataUseCase) {
    fun loadData() {
        // Usar el use case
    }
}
```

---

## 🧪 Testing Rápido

### Test Unitario
```bash
./gradlew shared:test
```

### Test en Android
```bash
./gradlew androidApp:connectedAndroidTest
```

### Logs
```bash
adb logcat | grep "Venered"
```

---

## 🐛 Troubleshooting Rápido

### Error: "Gradle sync failed"
```bash
./gradlew clean
./gradlew build --refresh-dependencies
```

### Error: "Compiling iOS" en Linux
iOS solo se compila en macOS. En Linux solo puedes compilar Android.

### Error: "Firebase not initialized"
Agrega tu `google-services.json` en `androidApp/src`

### Error: "Port already in use"
```bash
lsof -i :8080
kill -9 <PID>
```

---

## 📱 Emuladores

### Android Emulator
```bash
# Listar emuladores disponibles
emulator -list-avds

# Iniciar
emulator -avd <nombre>
```

### iOS Simulator
```bash
# En Xcode: Product → Destination → Seleccionar Simulator
```

---

## 📚 Recursos Importantes

| Recurso | Enlace |
|---------|--------|
| Kotlin Multiplatform | https://kotlinlang.org/docs/multiplatform.html |
| Jetpack Compose | https://developer.android.com/jetpack/compose/documentation |
| SwiftUI | https://developer.apple.com/tutorials/SwiftUI |
| Supabase | https://supabase.com/docs |
| Ktor Client | https://ktor.io/docs/client.html |

---

## 🎓 Conceptos Clave

### StateFlow
Flujo reactivo compartible entre recomposiciones y plataformas.
```kotlin
val state: StateFlow<UiState> = _state.asStateFlow()
```

### Expect/Actual
Código específico de plataforma.
```kotlin
expect fun getPlatformName(): String
actual fun getPlatformName() = "Android"
```

### Coroutines
Operaciones asíncronas NO bloqueantes.
```kotlin
viewModelScope.launch {
    val data = repository.getData()  // suspend
}
```

### Result<T>
Manejo de éxito/error sin excepciones.
```kotlin
result.onSuccess { data ->
    // Procesar datos
}.onFailure { error ->
    // Manejar error
}
```

---

## 🔑 Atajos de Teclado Útiles

### Android Studio
- `Cmd+K` (Mac) / `Ctrl+K` (Win): Commit
- `Alt+Enter`: Quick fix/Suggestions
- `Cmd+Shift+O`: Optimizar imports
- `Cmd+Option+L`: Format code

### Xcode
- `Cmd+R`: Compile y ejecuta
- `Cmd+B`: Build
- `Cmd+E`: Edit scheme

---

## 📞 Pedir Ayuda

1. Revisar logs: `adb logcat` (Android) o Xcode console (iOS)
2. Verificar errores de compilación
3. Limpiar build: `./gradlew clean`
4. Revisar dependencias en `build.gradle.kts`

---

¡Listo para empezar! 🚀
