package com.venered.social.domain.usecase

import com.venered.social.data.model.Message
import com.venered.social.data.model.Conversation
import com.venered.social.data.repository.MessageRepository

class GetConversationsUseCase(private val messageRepository: MessageRepository) {
    suspend operator fun invoke(userId: String): Result<List<Conversation>> {
        return messageRepository.getConversations(userId)
    }
}

class GetConversationMessagesUseCase(private val messageRepository: MessageRepository) {
    suspend operator fun invoke(conversationId: String, limit: Int = 50, offset: Int = 0): Result<List<Message>> {
        return messageRepository.getConversationMessages(conversationId, limit, offset)
    }
}

class SendMessageUseCase(private val messageRepository: MessageRepository) {
    suspend operator fun invoke(conversationId: String, senderId: String, receiverId: String, content: String?, mediaUrl: String? = null, type: String = "text"): Result<Message> {
        return messageRepository.sendMessage(conversationId, senderId, receiverId, content, mediaUrl, type)
    }
}

class MarkMessageAsReadUseCase(private val messageRepository: MessageRepository) {
    suspend operator fun invoke(messageId: String): Result<Unit> {
        return messageRepository.markAsRead(messageId)
    }
}

class CreateOrGetConversationUseCase(private val messageRepository: MessageRepository) {
    suspend operator fun invoke(user1Id: String, user2Id: String): Result<String> {
        return messageRepository.createOrGetConversation(user1Id, user2Id)
    }
}
