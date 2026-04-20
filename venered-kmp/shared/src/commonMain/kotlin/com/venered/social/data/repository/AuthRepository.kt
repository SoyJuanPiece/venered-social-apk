package com.venered.social.data.repository

import com.venered.social.data.network.SupabaseClient
import com.venered.social.data.network.getSupabaseUrl
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Repositorio para manejar autenticación con Supabase
 * Supabase utiliza JWT tokens para autenticación
 */
class AuthRepository {
    private val client = SupabaseClient.httpClient
    private val baseUrl = getSupabaseUrl("/auth/v1")

    /**
     * Iniciar sesión con email y contraseña
     */
    suspend fun signInWithPassword(email: String, password: String): Result<AuthResponse> = runCatching {
        val credentials = buildJsonObject {
            put("email", email)
            put("password", password)
        }

        val response = client.post("$baseUrl/token?grant_type=password") {
            contentType(ContentType.Application.Json)
            setBody(credentials.toString())
        }

        response.body()
    }

    /**
     * Registrar nuevo usuario
     */
    suspend fun signUp(email: String, password: String, userData: Map<String, String>): Result<AuthResponse> = runCatching {
        val userData = buildJsonObject {
            put("email", email)
            put("password", password)
            put("user_metadata", buildJsonObject {
                userData.forEach { (key, value) -> put(key, value) }
            })
        }

        val response = client.post("$baseUrl/signup") {
            contentType(ContentType.Application.Json)
            setBody(userData.toString())
        }

        response.body()
    }

    /**
     * Cerrar sesión
     */
    suspend fun signOut(token: String): Result<Unit> = runCatching {
        client.post("$baseUrl/logout") {
            header("Authorization", "Bearer $token")
        }
    }

    /**
     * Obtener usuario actual
     */
    suspend fun getCurrentUser(token: String): Result<User> = runCatching {
        val response = client.get("$baseUrl/user") {
            header("Authorization", "Bearer $token")
        }
        response.body()
    }

    /**
     * Enviar enlace de recuperación de contraseña
     */
    suspend fun resetPassword(email: String): Result<Unit> = runCatching {
        val data = buildJsonObject {
            put("email", email)
        }

        client.post("$baseUrl/recovery") {
            contentType(ContentType.Application.Json)
            setBody(data.toString())
        }
    }

    /**
     * Verificar código MFA
     */
    suspend fun verifyMFA(token: String, code: String): Result<AuthResponse> = runCatching {
        val mfaData = buildJsonObject {
            put("token", token)
            put("code", code)
        }

        val response = client.post("$baseUrl/verify") {
            contentType(ContentType.Application.Json)
            setBody(mfaData.toString())
        }

        response.body()
    }
}

/**
 * Respuesta de autenticación de Supabase
 */
@kotlinx.serialization.Serializable
data class AuthResponse(
    val access_token: String,
    val token_type: String = "bearer",
    val expires_in: Int = 3600,
    val refresh_token: String? = null,
    val user: User? = null
)

@kotlinx.serialization.Serializable
data class User(
    val id: String,
    val email: String,
    val user_metadata: Map<String, String>? = null,
    val created_at: String? = null
)
