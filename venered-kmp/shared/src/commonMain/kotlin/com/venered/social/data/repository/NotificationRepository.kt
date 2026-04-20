package com.venered.social.data.repository

import com.venered.social.data.model.Notification
import com.venered.social.data.network.SupabaseClient
import com.venered.social.data.network.getSupabaseUrl
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class NotificationRepository {
    private val client = SupabaseClient.httpClient
    private val baseUrl = getSupabaseUrl("/rest/v1")

    suspend fun getNotifications(userId: String, limit: Int = 50, offset: Int = 0): Result<List<Notification>> = runCatching {
        val response = client.get("$baseUrl/notifications") {
            parameter("receiver_id", "eq.$userId")
            parameter("limit", limit)
            parameter("offset", offset)
            parameter("order", "created_at.desc")
        }
        response.body()
    }

    suspend fun markNotificationAsRead(notificationId: String): Result<Unit> = runCatching {
        val updateData = buildJsonObject {
            put("is_read", true)
        }

        client.patch("$baseUrl/notifications") {
            parameter("id", "eq.$notificationId")
            contentType(ContentType.Application.Json)
            setBody(updateData.toString())
        }
    }

    suspend fun createNotification(receiverId: String, senderId: String, type: String, relatedId: String? = null, content: String? = null): Result<Notification> = runCatching {
        val notifData = buildJsonObject {
            put("receiver_id", receiverId)
            put("sender_id", senderId)
            put("type", type)
            relatedId?.let { put("related_id", it) }
            content?.let { put("content", it) }
        }

        val response = client.post("$baseUrl/notifications") {
            contentType(ContentType.Application.Json)
            setBody(notifData.toString())
        }
        response.body()
    }

    suspend fun saveFCMToken(userId: String, fcmToken: String): Result<Unit> = runCatching {
        val tokenData = buildJsonObject {
            put("user_id", userId)
            put("fcm_token", fcmToken)
        }

        client.post("$baseUrl/user_fcm_tokens") {
            parameter("on_conflict", "user_id")
            contentType(ContentType.Application.Json)
            setBody(tokenData.toString())
        }
    }
}
