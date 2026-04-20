package com.venered.social.data.repository

import com.venered.social.data.model.User
import com.venered.social.data.network.SupabaseClient
import com.venered.social.data.network.getSupabaseUrl
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class UserRepository {
    private val client = SupabaseClient.httpClient
    private val baseUrl = getSupabaseUrl("/rest/v1")

    suspend fun getUserProfile(userId: String): Result<User> = runCatching {
        val response = client.get("$baseUrl/profiles") {
            parameter("id", "eq.$userId")
        }
        val users: List<User> = response.body()
        users.firstOrNull() ?: throw Exception("Usuario no encontrado")
    }

    suspend fun getUserByUsername(username: String): Result<User> = runCatching {
        val response = client.get("$baseUrl/profiles") {
            parameter("username", "eq.$username")
        }
        val users: List<User> = response.body()
        users.firstOrNull() ?: throw Exception("Usuario no encontrado")
    }

    suspend fun searchUsers(query: String): Result<List<User>> = runCatching {
        val response = client.get("$baseUrl/profiles") {
            parameter("or", "(username.ilike.%$query%,display_name.ilike.%$query%)")
        }
        response.body()
    }

    suspend fun updateProfile(userId: String, displayName: String?, bio: String?, estado: String?): Result<User> = runCatching {
        val updateData = buildJsonObject {
            displayName?.let { put("display_name", it) }
            bio?.let { put("bio", it) }
            estado?.let { put("estado", it) }
        }

        val response = client.patch("$baseUrl/profiles") {
            parameter("id", "eq.$userId")
            contentType(ContentType.Application.Json)
            setBody(updateData.toString())
        }

        val users: List<User> = response.body()
        users.firstOrNull() ?: throw Exception("Error actualizando perfil")
    }

    suspend fun updateAvatar(userId: String, avatarUrl: String): Result<User> = runCatching {
        val updateData = buildJsonObject {
            put("avatar_url", avatarUrl)
        }

        val response = client.patch("$baseUrl/profiles") {
            parameter("id", "eq.$userId")
            contentType(ContentType.Application.Json)
            setBody(updateData.toString())
        }

        val users: List<User> = response.body()
        users.firstOrNull() ?: throw Exception("Error actualizando avatar")
    }

    suspend fun setOnlineStatus(userId: String, isOnline: Boolean): Result<Unit> = runCatching {
        val updateData = buildJsonObject {
            put("is_online", isOnline)
            put("last_seen", System.currentTimeMillis())
        }

        client.patch("$baseUrl/profiles") {
            parameter("id", "eq.$userId")
            contentType(ContentType.Application.Json)
            setBody(updateData.toString())
        }
    }
}
