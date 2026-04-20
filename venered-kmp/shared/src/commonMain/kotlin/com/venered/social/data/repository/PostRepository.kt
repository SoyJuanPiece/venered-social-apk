package com.venered.social.data.repository

import com.venered.social.data.model.*
import com.venered.social.data.network.SupabaseClient
import com.venered.social.data.network.getSupabaseUrl
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.coroutines.delay
import kotlinx.serialization.json.*

class PostRepository {
    private val client = SupabaseClient.httpClient
    private val baseUrl = getSupabaseUrl("/rest/v1")

    suspend fun getFeedPosts(limit: Int = 15, offset: Int = 0): Result<List<Post>> = runCatching {
        val response = client.get("$baseUrl/posts_with_likes_count") {
            parameter("limit", limit)
            parameter("offset", offset)
            parameter("order", "created_at.desc")
        }
        response.body()
    }

    suspend fun getPostsByUser(userId: String, limit: Int = 15, offset: Int = 0): Result<List<Post>> = runCatching {
        val response = client.get("$baseUrl/posts_with_likes_count") {
            parameter("user_id", "eq.$userId")
            parameter("limit", limit)
            parameter("offset", offset)
            parameter("order", "created_at.desc")
        }
        response.body()
    }

    suspend fun createPost(userId: String, content: String?, mediaUrl: String?, type: String = "text"): Result<Post> = runCatching {
        val postData = buildJsonObject {
            put("user_id", userId)
            put("content", content)
            put("media_url", mediaUrl)
            put("type", type)
        }

        val response = client.post("$baseUrl/posts") {
            contentType(ContentType.Application.Json)
            setBody(postData.toString())
        }
        response.body()
    }

    suspend fun deletePost(postId: String): Result<Unit> = runCatching {
        client.delete("$baseUrl/posts") {
            parameter("id", "eq.$postId")
        }
    }

    suspend fun likePost(userId: String, postId: String): Result<Unit> = runCatching {
        val likeData = buildJsonObject {
            put("user_id", userId)
            put("post_id", postId)
        }

        client.post("$baseUrl/likes") {
            contentType(ContentType.Application.Json)
            setBody(likeData.toString())
        }
    }

    suspend fun unlikePost(userId: String, postId: String): Result<Unit> = runCatching {
        client.delete("$baseUrl/likes") {
            parameter("user_id", "eq.$userId")
            parameter("post_id", "eq.$postId")
        }
    }

    suspend fun getComments(postId: String): Result<List<Comment>> = runCatching {
        val response = client.get("$baseUrl/comments") {
            parameter("post_id", "eq.$postId")
            parameter("order", "created_at.asc")
        }
        response.body()
    }

    suspend fun addComment(userId: String, postId: String, content: String): Result<Comment> = runCatching {
        val commentData = buildJsonObject {
            put("user_id", userId)
            put("post_id", postId)
            put("content", content)
        }

        val response = client.post("$baseUrl/comments") {
            contentType(ContentType.Application.Json)
            setBody(commentData.toString())
        }
        response.body()
    }
}
