package com.venered.social.presentation.viewmodel

import com.venered.social.domain.usecase.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class PostState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val isSuccess: Boolean = false
)

class PostViewModel(
    private val createPostUseCase: CreatePostUseCase,
    private val deletePostUseCase: DeletePostUseCase
) : BaseViewModel() {
    private val _state = MutableStateFlow(PostState())
    val state: StateFlow<PostState> = _state

    fun createPost(userId: String, content: String?, mediaUrl: String? = null) {
        _state.value = _state.value.copy(isLoading = true, error = null, isSuccess = false)
        viewModelScope.launch {
            createPostUseCase(userId, content, mediaUrl)
                .onSuccess {
                    _state.value = _state.value.copy(isLoading = false, isSuccess = true)
                }.onFailure { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message ?: "Error al crear post"
                    )
                }
        }
    }

    fun resetState() {
        _state.value = PostState()
    }
}
