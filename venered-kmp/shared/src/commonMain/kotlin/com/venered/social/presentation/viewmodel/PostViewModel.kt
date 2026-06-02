package com.venered.social.presentation.viewmodel

import com.venered.social.domain.usecase.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class PostState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val isSuccess: Boolean = false,
    val uploadedMediaUrl: String? = null
)

class PostViewModel(
    private val createPostUseCase: CreatePostUseCase,
    private val deletePostUseCase: DeletePostUseCase,
    private val uploadImageUseCase: UploadImageUseCase,
    private val uploadVideoUseCase: UploadVideoUseCase
) : BaseViewModel() {
    private val _state = MutableStateFlow(PostState())
    val state: StateFlow<PostState> = _state

    fun createPost(userId: String, content: String?, mediaUrl: String? = null, type: String = "text") {
        _state.value = _state.value.copy(isLoading = true, error = null, isSuccess = false)
        viewModelScope.launch {
            createPostUseCase(userId, content, mediaUrl, type)
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

    fun uploadMediaAndCreatePost(userId: String, content: String?, bytes: ByteArray, fileName: String, isVideo: Boolean) {
        _state.value = _state.value.copy(isLoading = true, error = null)
        viewModelScope.launch {
            val uploadResult = if (isVideo) {
                uploadVideoUseCase(bytes, fileName)
            } else {
                uploadImageUseCase(bytes, fileName)
            }

            uploadResult.onSuccess { url ->
                createPost(userId, content, url, if (isVideo) "video" else "image")
            }.onFailure { exception ->
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = "Fallo al subir multimedia: ${exception.message}"
                )
            }
        }
    }

    fun resetState() {
        _state.value = PostState()
    }
}
