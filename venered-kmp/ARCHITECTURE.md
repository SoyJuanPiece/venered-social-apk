# Arquitectura y Best Practices - Venered KMP

## 🏗️ Arquitectura General

Venered KMP sigue una arquitectura limpia con capas bien definidas:

```
┌─────────────────────────────────────────────────┐
│        PRESENTATION LAYER (UI)                  │
│  - Screens (Compose/SwiftUI)                    │
│  - ViewModels (StateFlow-based)                 │
│  - Navigation                                   │
├─────────────────────────────────────────────────┤
│        DOMAIN LAYER (Use Cases)                 │
│  - Business logic                               │
│  - Use cases (operators)                        │
│  - Repositories interfaces                      │
├─────────────────────────────────────────────────┤
│        DATA LAYER                               │
│  - Repositories (implementations)               │
│  - Network (Ktor + Supabase)                    │
│  - Cache (in-memory)                            │
│  - Local DB (SQLDelight)                        │
├─────────────────────────────────────────────────┤
│        SHARED LIBRARY (Kotlin Multiplataforma)  │
│  - Todos los modelos y lógica compartida       │
│  - Compilado para Android, iOS                 │
└─────────────────────────────────────────────────┘

    ↓ PLATAFORMAS ESPECÍFICAS

┌──────────────────┐         ┌──────────────────┐
│  ANDROID APP     │         │   iOS APP        │
│  (Jetpack        │         │   (SwiftUI +     │
│   Compose)       │         │    Combine)      │
└──────────────────┘         └──────────────────┘
```

## 📚 Patrones Utilizados

### 1. Repository Pattern
Abstracción del acceso a datos. Maneja tanto HTTP como caché.

```kotlin
// Data Layer
class PostRepository {
    suspend fun getFeedPosts(limit: Int, offset: Int): Result<List<Post>>
    suspend fun createPost(...): Result<Post>
}

// Domain Layer
class GetFeedPostsUseCase(private val repo: PostRepository) {
    suspend operator fun invoke(limit: Int, offset: Int): Result<List<Post>>
}

// Presentation Layer
class HomeFeedViewModel(private val useCase: GetFeedPostsUseCase) {
    val state: StateFlow<HomeFeedState>
    fun loadInitialFeed()
}
```

### 2. MVI/MVVM Pattern
Unidirectional data flow con StateFlow.

```kotlin
// State
data class HomeFeedState(
    val posts: List<Post> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

// ViewModel
class HomeFeedViewModel(...) {
    private val _state = MutableStateFlow(HomeFeedState())
    val state: StateFlow<HomeFeedState> = _state
    
    // Actions que modifican el state
    fun loadMore()
    fun toggleLike(postId: String, userId: String)
}

// UI (Composable)
@Composable
fun HomeScreen(viewModel: HomeFeedViewModel) {
    val state by viewModel.state.collectAsState()
    Column {
        state.posts.forEach { post -> PostCard(post) }
        if (state.isLoading) LoadingIndicator()
        state.error?.let { ErrorMessage(it) }
    }
}
```

### 3. Dependency Injection (Manual)
Para KMP, usamos inyección manual en lugar de frameworks pesados.

```kotlin
// En la app:
val postRepository = PostRepository()
val getUserPostsUseCase = GetUserPostsUseCase(postRepository)
val userViewModel = UserViewModel(getUserPostsUseCase)
```

### 4. Expect/Actual para código específico de plataforma

```kotlin
// common
expect object FilesManager {
    fun getSharedPreferences(): SharedPreferences
}

// androidMain
actual object FilesManager {
    actual fun getSharedPreferences(): SharedPreferences {
        return context.getSharedPreferences("app", Context.MODE_PRIVATE)
    }
}

// iosMain
actual object FilesManager {
    actual fun getSharedPreferences(): SharedPreferences {
        return UserDefaultsWrapper()
    }
}
```

## 🔄 Flujos de Datos

### Login Flow
```
LoginScreen 
  ↓ usuario ingresa credenciales
  ↓ AuthViewModel.login(email, password)
  ↓ AuthRepository.signInWithPassword()
  ↓ Supabase JWT token received
  ↓ Guardar token en SharedPreferences/Keychain
  ↓ Navegar a HomePage
  ↓ HomePage obtiene currentUser desde SharedPreferences
```

### Feed Loading Flow
```
HomeFeedScreen initState
  ↓ HomeFeedViewModel.loadInitialFeed()
  ↓ getFeedPostsUseCase(limit=15, offset=0)
  ↓ postRepository.getFeedPosts()
  ↓ HTTP GET /rest/v1/posts_with_likes_count?limit=15&offset=0
  ↓ Supabase response recibida
  ↓ Cache actualizado (FeedCache)
  ↓ _state.value = HomeFeedState(posts=newPosts, isLoading=false)
  ↓ UI se re-renderiza con nuevos posts
```

### Like Toggle Flow
```
User taps like button
  ↓ PostCard calls viewModel.toggleLike(postId, userId, currentLikedState)
  ↓ Optimistic UI update (modificar _state inmediatamente)
  ↓ likePostUseCase() o unlikePostUseCase() en background
  ↓ HTTP POST/DELETE a Supabase
  ↓ Si error, revertir cambio local
  ↓ Si éxito, mantener estado
```

## 🗄️ Gestión de Estado

### StateFlow vs MutableState (Compose)
- **StateFlow**: Para ViewModel compartido, mejor para KMP
- **MutableState**: Para UI local, mejor para Compose específica

```kotlin
// ViewModel (compartido)
val state: StateFlow<HomeFeedState>

// Composable UI (local)
@Composable
fun LoginScreen() {
    var email by remember { mutableStateOf("") }  // Local
    var password by remember { mutableStateOf("") } // Local
}
```

### Caché en Capas
```
1. Memory Cache (rápido)
   └─ StateFlow en ViewModel
   └─ FeedCache object
   
2. Local DB (persistente)
   └─ SQLDelight
   
3. Network (source of truth)
   └─ Supabase API
```

## 🔒 Seguridad

### Tokens JWT
```kotlin
// Guardar de forma segura
SharedPreferencesSecured().putString("auth_token", jwtToken)

// Incluir en headers
httpClient.defaultRequest {
    header("Authorization", "Bearer $token")
}
```

### Validación de Input
```kotlin
// Antes de enviar a servidor
fun validateEmail(email: String): Boolean {
    return email.matches("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}".toRegex())
}

fun validatePassword(pwd: String): Boolean {
    return pwd.length >= 8 && pwd.any { it.isUpperCase() } && pwd.any { it.isDigit() }
}
```

## 📱 Respuesta a Diferentes Pantallas

```kotlin
@Composable
fun adaptiveLayout(content: @Composable (isCompact: Boolean) -> Unit) {
    val windowSizeClass = calculateWindowSizeClass()
    val isCompact = windowSizeClass.widthSizeClass == WindowWidthSizeClass.Compact
    content(isCompact)
}
```

## 🧪 Testing

### Unit Tests
```kotlin
class GetFeedPostsUseCaseTest {
    @Test
    fun loadFeedEmpty() = runTest {
        val useCase = GetFeedPostsUseCase(mockRepository)
        val result = useCase(limit = 15, offset = 0)
        assertTrue(result.isSuccess)
    }
}
```

### Integration Tests (Android)
```kotlin
@RunWith(AndroidJUnit4::class)
class HomeFeedScreenTest {
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun displaysPostsWhenLoaded() {
        composeTestRule.setContent {
            HomeScreen()
        }
        composeTestRule.onNodeWithText("Post content").assertIsDisplayed()
    }
}
```

## 📊 Monitoreo y Analytics

### Firebase Analytics
```kotlin
val analytics = FirebaseAnalytics.getInstance(context)
val bundle = bundleOf(
    "post_id" to post.id,
    "user_id" to userId
)
analytics.logEvent("post_liked", bundle)
```

### Crashlytics
```kotlin
try {
    savePost(post)
} catch (e: Exception) {
    FirebaseCrashlytics.getInstance().recordException(e)
    LoggerService.log("Error saving post", e)
}
```

## 🚀 Performance Tips

1. **Lazy Loading**: Cargar datos conforme se necesite
```kotlin
LazyColumn {
    items(posts) { post -> PostCard(post) }
}
```

2. **Paginación**: 15-20 items por página
```kotlin
suspend fun getFeedPosts(limit: Int = 15, offset: Int = 0)
```

3. **Caché Agresivo**: Guardar posts, usuarios, mensajes
```kotlin
FeedCache.updateCache(posts)
UserCache.cacheUser(user)
```

4. **Compresión de Media**: En cliente, no en servidor
```kotlin
val compressed = compressImage(file)
uploadMedia(compressed)
```

5. **Colecciones de Flow**: Usar collect en ciclo de vida adecuado
```kotlin
viewModel.state.collect { state ->
    renderUI(state)
}
```

## 📋 Checklist de Producción

- [ ] Manejo robusto de errores de red
- [ ] Offline-first capability
- [ ] Retry logic con exponential backoff
- [ ] Rate limiting cliente
- [ ] Input validation exhaustivo
- [ ] Encrypt sensitive data
- [ ] Analytics de usuario
- [ ] Crash reporting
- [ ] Code obfuscation (ProGuard)
- [ ] Performance profiling
- [ ] Accessibility (a11y)
- [ ] i18n/Localization
- [ ] Dark/Light theme
- [ ] Battery optimization
- [ ] Memory leak detection

## 🔗 Referencias Útiles

- [Kotlin Multiplatform](https://kotlinlang.org/docs/reference/multiplatform.html)
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [SwiftUI](https://developer.apple.com/swiftui/)
- [Supabase Docs](https://supabase.com/docs)
- [Ktor Client](https://ktor.io/docs/client.html)
- [Kotlin Coroutines](https://kotlinlang.org/docs/reference/coroutines.html)
