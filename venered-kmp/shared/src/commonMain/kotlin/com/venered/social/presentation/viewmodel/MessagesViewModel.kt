package com.venered.social.presentation.viewmodel

import com.venered.social.data.model.Message
import com.venered.social.data.model.Conversation
import com.venered.social.domain.usecase.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

import kotlinx.coroutines.launch

data class MessagesState(
    val conversations: List<Conversation> = emptyList(),
    val currentMessages: List<Message> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

class MessagesViewModel(
    private val getConversationsUseCase: GetConversationsUseCase,
    private val getConversationMessagesUseCase: GetConversationMessagesUseCase,
    private val sendMessageUseCase: SendMessageUseCase
) : BaseViewModel() {
    private val _state = MutableStateFlow(MessagesState())
    val state: StateFlow<MessagesState> = _state

    private var currentConversationId: String? = null

    fun loadConversations(userId: String) {
        _state.value = _state.value.copy(isLoading = true, error = null)

        viewModelScope.launch {
            getConversationsUseCase(userId)
                .onSuccess { conversations ->
                    _state.value = _state.value.copy(
                        conversations = conversations,
                        isLoading = false
                    )
                }.onFailure { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message
                    )
                }
        }
    }

    fun loadConversationMessages(conversationId: String) {
        currentConversationId = conversationId
        _state.value = _state.value.copy(isLoading = true, error = null)

        viewModelScope.launch {
            getConversationMessagesUseCase(conversationId)
                .onSuccess { messages ->
                    _state.value = _state.value.copy(
                        currentMessages = messages,
                        isLoading = false
                    )
                }.onFailure { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message
                    )
                }
        }
    }

    fun sendMessage(conversationId: String, senderId: String, receiverId: String, content: String) {
        viewModelScope.launch {
            sendMessageUseCase(conversationId, senderId, receiverId, content)
                .onSuccess { message ->
                    _state.value = _state.value.copy(
                        currentMessages = _state.value.currentMessages + message
                    )
                }
        }
    }
}
