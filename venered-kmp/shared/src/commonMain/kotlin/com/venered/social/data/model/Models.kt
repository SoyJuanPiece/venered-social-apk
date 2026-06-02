package com.venered.social.data.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName
import kotlinx.datetime.Instant

@Serializable
data class User(
    val id: String,
    val username: String,
    @SerialName("display_name")
    val displayName: String? = null,
    val bio: String? = null,
    @SerialName("avatar_url")
    val avatarUrl: String? = null,
    val estado: String? = null,
    @SerialName("is_verified")
    val isVerified: Boolean = false,
    @SerialName("is_admin")
    val isAdmin: Boolean = false,
    @SerialName("is_online")
    val isOnline: Boolean = false,
    @SerialName("last_seen")
    val lastSeen: Instant? = null,
    @SerialName("updated_at")
    val updatedAt: Instant? = null
)

@Serializable
data class Post(
    val id: String,
    @SerialName("user_id")
    val userId: String,
    val content: String? = null,
    @SerialName("media_url")
    val mediaUrl: String? = null,
    val type: String = "text",
    @SerialName("created_at")
    val createdAt: Instant? = null,
    @SerialName("likes_count")
    val likesCount: Int = 0,
    @SerialName("comments_count")
    val commentsCount: Int = 0,
    val username: String = "",
    @SerialName("avatar_url")
    val avatarUrl: String? = null,
    @SerialName("is_verified")
    val isVerified: Boolean = false
)

@Serializable
data class Like(
    val id: String,
    @SerialName("user_id")
    val userId: String,
    @SerialName("post_id")
    val postId: String,
    @SerialName("created_at")
    val createdAt: Instant? = null
)

@Serializable
data class Comment(
    val id: String,
    @SerialName("user_id")
    val userId: String,
    @SerialName("post_id")
    val postId: String,
    val content: String,
    @SerialName("created_at")
    val createdAt: Instant? = null,
    val username: String = "",
    @SerialName("avatar_url")
    val avatarUrl: String? = null
)

@Serializable
data class Message(
    val id: String,
    @SerialName("conversation_id")
    val conversationId: String,
    @SerialName("sender_id")
    val senderId: String,
    @SerialName("receiver_id")
    val receiverId: String? = null,
    val content: String? = null,
    @SerialName("media_url")
    val mediaUrl: String? = null,
    val type: String = "text",
    @SerialName("is_read")
    val isRead: Boolean = false,
    @SerialName("created_at")
    val createdAt: Instant? = null
)

@Serializable
data class Conversation(
    val id: String,
    @SerialName("user1_id")
    val user1Id: String,
    @SerialName("user2_id")
    val user2Id: String,
    @SerialName("last_message_at")
    val lastMessageAt: Instant? = null,
    @SerialName("created_at")
    val createdAt: Instant? = null,
    @SerialName("other_username")
    val otherUsername: String = "",
    @SerialName("other_avatar_url")
    val otherAvatarUrl: String? = null,
    @SerialName("last_message_content")
    val lastMessageContent: String? = null
)

@Serializable
data class Story(
    val id: String,
    @SerialName("user_id")
    val userId: String,
    @SerialName("media_url")
    val mediaUrl: String,
    val type: String = "image",
    @SerialName("expires_at")
    val expiresAt: Instant? = null,
    @SerialName("created_at")
    val createdAt: Instant? = null,
    val username: String = "",
    @SerialName("avatar_url")
    val avatarUrl: String? = null,
    @SerialName("is_verified")
    val isVerified: Boolean = false
)

@Serializable
data class Notification(
    val id: String,
    @SerialName("receiver_id")
    val receiverId: String,
    @SerialName("sender_id")
    val senderId: String,
    val type: String,
    @SerialName("related_id")
    val relatedId: String? = null,
    val content: String? = null,
    @SerialName("is_read")
    val isRead: Boolean = false,
    @SerialName("created_at")
    val createdAt: Instant? = null
)

@Serializable
data class SavedPost(
    val id: String,
    @SerialName("user_id")
    val userId: String,
    @SerialName("post_id")
    val postId: String,
    @SerialName("created_at")
    val createdAt: Instant? = null
)

@Serializable
data class VerificationRequest(
    val id: String,
    @SerialName("user_id")
    val userId: String,
    val category: String,
    val message: String? = null,
    val status: String = "pending",
    @SerialName("created_at")
    val createdAt: Instant? = null
)
