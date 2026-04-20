package com.venered.social.data.repository

import com.venered.social.data.model.SavedPost
import com.venered.social.data.network.SupabaseClient
import com.venered.social.data.network.getSupabaseUrl
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class SavedPostRepository {
    private val client = SupabaseClient.httpClient
    private val baseUrl = getSupabaseUrl("/rest/v1")

    suspend fun getSavedPosts(userId: String): Result<List<SavedPost>> = runCatching {
        val response = client.get("$baseUrl/saved_posts") {
            parameter("user_id", "eq.$userId")
        }
        response.body()
    }

    suspend fun savePost(userId: String, postId: String): Result<SavedPost> = runCatching {
        val saveData = buildJsonObject {
            put("user_id", userId)
            put("post_id", postId)
        }

        val response = client.post("$baseUrl/saved_posts") {
            contentType(ContentType.Application.Json)
            setBody(saveData.toString())
        }
        response.body()
    }

    suspend fun removeSavedPost(userId: String, postId: String): Result<Unit> = runCatching {
        client.delete("$baseUrl/saved_posts") {
            parameter("user_id", "eq.$userId")
            parameter("post_id", "eq.$postId")
        }
    }

    suspend fun isSaved(userId: String, postId: String): Result<Boolean> = runCatching {
        val response = client.get("$baseUrl/saved_posts") {
            parameter("user_id", "eq.$userId")
            parameter("post_id", "eq.$postId")
        }
        val saved: List<SavedPost> = response.body()
        saved.isNotEmpty()
    }
}
