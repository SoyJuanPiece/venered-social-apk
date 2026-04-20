package com.venered.social.data.cache

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Cache en memoria para posts del feed
 * En producción, esto se reemplazaría con una base de datos local (SQLite/Realm)
 */
object FeedCache {
    private val _cachedPosts = MutableStateFlow<List<com.venered.social.data.model.Post>>(emptyList())
    val cachedPosts: StateFlow<List<com.venered.social.data.model.Post>> = _cachedPosts

    fun updateCache(posts: List<com.venered.social.data.model.Post>) {
        _cachedPosts.value = posts
    }

    fun getCachedPosts(): List<com.venered.social.data.model.Post> = _cachedPosts.value

    fun clear() {
        _cachedPosts.value = emptyList()
    }
}

/**
 * Cache para perfiles de usuarios
 */
object UserCache {
    private val cache = mutableMapOf<String, com.venered.social.data.model.User>()

    fun cacheUser(user: com.venered.social.data.model.User) {
        cache[user.id] = user
    }

    fun getUser(userId: String): com.venered.social.data.model.User? = cache[userId]

    fun getCachedUsers(): List<com.venered.social.data.model.User> = cache.values.toList()

    fun clear() {
        cache.clear()
    }
}

/**
 * Cache para mensajes
 */
object MessageCache {
    private val conversationMessages = mutableMapOf<String, List<com.venered.social.data.model.Message>>()

    fun cacheMessages(conversationId: String, messages: List<com.venered.social.data.model.Message>) {
        conversationMessages[conversationId] = messages
    }

    fun getMessages(conversationId: String): List<com.venered.social.data.model.Message> {
        return conversationMessages[conversationId] ?: emptyList()
    }

    fun addMessage(conversationId: String, message: com.venered.social.data.model.Message) {
        val existing = conversationMessages[conversationId] ?: emptyList()
        conversationMessages[conversationId] = existing + message
    }

    fun clear() {
        conversationMessages.clear()
    }
}
