package com.venered.social.data.repository

import com.venered.social.data.model.Message
import com.venered.social.data.model.Conversation
import com.venered.social.data.network.SupabaseClient
import com.venered.social.data.network.getSupabaseUrl
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class MessageRepository {
    private val client = SupabaseClient.httpClient
    private val baseUrl = getSupabaseUrl("/rest/v1")

    suspend fun getConversations(userId: String): Result<List<Conversation>> = runCatching {
        val response = client.get("$baseUrl/view_conversations") {
            parameter("limit", "50")
            parameter("order", "last_message_at.desc")
        }
        response.body()
    }

    suspend fun getConversationMessages(conversationId: String, limit: Int = 50, offset: Int = 0): Result<List<Message>> = runCatching {
        val response = client.get("$baseUrl/messages") {
            parameter("conversation_id", "eq.$conversationId")
            parameter("limit", limit)
            parameter("offset", offset)
            parameter("order", "created_at.asc")
        }
        response.body()
    }

    suspend fun sendMessage(conversationId: String, senderId: String, receiverId: String, content: String?, mediaUrl: String? = null, type: String = "text"): Result<Message> = runCatching {
        val messageData = buildJsonObject {
            put("conversation_id", conversationId)
            put("sender_id", senderId)
            put("receiver_id", receiverId)
            put("content", content)
            put("media_url", mediaUrl)
            put("type", type)
        }

        val response = client.post("$baseUrl/messages") {
            contentType(ContentType.Application.Json)
            setBody(messageData.toString())
        }
        response.body()
    }

    suspend fun markAsRead(messageId: String): Result<Unit> = runCatching {
        val updateData = buildJsonObject {
            put("is_read", true)
        }

        client.patch("$baseUrl/messages") {
            parameter("id", "eq.$messageId")
            contentType(ContentType.Application.Json)
            setBody(updateData.toString())
        }
    }

    suspend fun createOrGetConversation(user1Id: String, user2Id: String): Result<String> = runCatching {
        // Intentar obtener conversación existente
        val response = client.get("$baseUrl/conversations") {
            parameter("or", "(and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id))")
        }
        
        val conversations: List<Conversation> = response.body()
        if (conversations.isNotEmpty()) {
            return@runCatching conversations.first().id
        }

        // Crear nueva conversación
        val newConvData = buildJsonObject {
            put("user1_id", user1Id)
            put("user2_id", user2Id)
        }

        val createResponse = client.post("$baseUrl/conversations") {
            contentType(ContentType.Application.Json)
            setBody(newConvData.toString())
        }

        val newConv: Conversation = createResponse.body()
        newConv.id
    }
}
