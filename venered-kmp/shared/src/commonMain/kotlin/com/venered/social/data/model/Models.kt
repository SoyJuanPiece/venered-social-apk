package com.venered.social.data.model

import kotlinx.serialization.Serializable
import kotlinx.datetime.Instant

@Serializable
data class User(
    val id: String,
    val username: String,
    val displayName: String? = null,
    val bio: String? = null,
    val avatarUrl: String? = null,
    val estado: String? = null,
    val isVerified: Boolean = false,
    val isAdmin: Boolean = false,
    val isOnline: Boolean = false,
    val lastSeen: Instant? = null,
    val updatedAt: Instant? = null
)

@Serializable
data class Post(
    val id: String,
    val userId: String,
    val content: String? = null,
    val mediaUrl: String? = null,
    val type: String = "text",
    val createdAt: Instant? = null,
    val likesCount: Int = 0,
    val commentsCount: Int = 0,
    val username: String = "",
    val avatarUrl: String? = null,
    val isVerified: Boolean = false
)

@Serializable
data class Like(
    val id: String,
    val userId: String,
    val postId: String,
    val createdAt: Instant? = null
)

@Serializable
data class Comment(
    val id: String,
    val userId: String,
    val postId: String,
    val content: String,
    val createdAt: Instant? = null,
    val username: String = "",
    val avatarUrl: String? = null
)

@Serializable
data class Message(
    val id: String,
    val conversationId: String,
    val senderId: String,
    val receiverId: String? = null,
    val content: String? = null,
    val mediaUrl: String? = null,
    val type: String = "text",
    val isRead: Boolean = false,
    val createdAt: Instant? = null
)

@Serializable
data class Conversation(
    val id: String,
    val user1Id: String,
    val user2Id: String,
    val lastMessageAt: Instant? = null,
    val createdAt: Instant? = null,
    val otherUsername: String = "",
    val otherAvatarUrl: String? = null,
    val lastMessageContent: String? = null
)

@Serializable
data class Story(
    val id: String,
    val userId: String,
    val mediaUrl: String,
    val type: String = "image",
    val expiresAt: Instant? = null,
    val createdAt: Instant? = null,
    val username: String = "",
    val avatarUrl: String? = null,
    val isVerified: Boolean = false
)

@Serializable
data class Notification(
    val id: String,
    val receiverId: String,
    val senderId: String,
    val type: String,
    val relatedId: String? = null,
    val content: String? = null,
    val isRead: Boolean = false,
    val createdAt: Instant? = null
)

@Serializable
data class SavedPost(
    val id: String,
    val userId: String,
    val postId: String,
    val createdAt: Instant? = null
)

@Serializable
data class VerificationRequest(
    val id: String,
    val userId: String,
    val category: String,
    val message: String? = null,
    val status: String = "pending",
    val createdAt: Instant? = null
)
