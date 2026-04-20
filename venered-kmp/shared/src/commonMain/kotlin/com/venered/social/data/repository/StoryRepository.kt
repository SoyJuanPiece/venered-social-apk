package com.venered.social.data.repository

import com.venered.social.data.model.Story
import com.venered.social.data.network.SupabaseClient
import com.venered.social.data.network.getSupabaseUrl
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class StoryRepository {
    private val client = SupabaseClient.httpClient
    private val baseUrl = getSupabaseUrl("/rest/v1")

    suspend fun getStoriesForFeed(): Result<List<Story>> = runCatching {
        val response = client.get("$baseUrl/stories_with_profiles") {
            parameter("order", "created_at.desc")
        }
        response.body()
    }

    suspend fun getUserStories(userId: String): Result<List<Story>> = runCatching {
        val response = client.get("$baseUrl/stories_with_profiles") {
            parameter("user_id", "eq.$userId")
            parameter("order", "created_at.desc")
        }
        response.body()
    }

    suspend fun createStory(userId: String, mediaUrl: String, type: String = "image"): Result<Story> = runCatching {
        val storyData = buildJsonObject {
            put("user_id", userId)
            put("media_url", mediaUrl)
            put("type", type)
            put("expires_at", (System.currentTimeMillis() + 86400000)) // +24h
        }

        val response = client.post("$baseUrl/stories") {
            contentType(ContentType.Application.Json)
            setBody(storyData.toString())
        }
        response.body()
    }

    suspend fun deleteStory(storyId: String): Result<Unit> = runCatching {
        client.delete("$baseUrl/stories") {
            parameter("id", "eq.$storyId")
        }
    }
}
