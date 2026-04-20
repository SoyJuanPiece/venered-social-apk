package com.venered.social.presentation.viewmodel

import com.venered.social.data.model.User
import com.venered.social.domain.usecase.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

data class ProfileState(
    val user: User? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)

class ProfileViewModel(
    private val getUserProfileUseCase: GetUserProfileUseCase,
    private val updateProfileUseCase: UpdateProfileUseCase,
    private val updateAvatarUseCase: UpdateAvatarUseCase,
    private val getUserPostsUseCase: GetUserPostsUseCase
) {
    private val _state = MutableStateFlow(ProfileState())
    val state: StateFlow<ProfileState> = _state

    private val _userPosts = MutableStateFlow<List<com.venered.social.data.model.Post>>(emptyList())
    val userPosts: StateFlow<List<com.venered.social.data.model.Post>> = _userPosts

    fun loadUserProfile(userId: String) {
        _state.value = _state.value.copy(isLoading = true, error = null)

        kotlin.runCatching {
            kotlinx.coroutines.runBlocking {
                getUserProfileUseCase(userId)
            }
        }.onSuccess { result ->
            result.onSuccess { user ->
                _state.value = _state.value.copy(
                    user = user,
                    isLoading = false
                )
                loadUserPosts(userId)
            }.onFailure { exception ->
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = exception.message
                )
            }
        }.onFailure { exception ->
            _state.value = _state.value.copy(
                isLoading = false,
                error = exception.message
            )
        }
    }

    private fun loadUserPosts(userId: String) {
        kotlin.runCatching {
            kotlinx.coroutines.runBlocking {
                getUserPostsUseCase(userId)
            }
        }.onSuccess { result ->
            result.onSuccess { posts ->
                _userPosts.value = posts
            }
        }
    }

    fun updateProfile(userId: String, displayName: String?, bio: String?, estado: String?) {
        _state.value = _state.value.copy(isLoading = true)

        kotlin.runCatching {
            kotlinx.coroutines.runBlocking {
                updateProfileUseCase(userId, displayName, bio, estado)
            }
        }.onSuccess { result ->
            result.onSuccess { user ->
                _state.value = _state.value.copy(
                    user = user,
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

    fun updateAvatar(userId: String, avatarUrl: String) {
        kotlin.runCatching {
            kotlinx.coroutines.runBlocking {
                updateAvatarUseCase(userId, avatarUrl)
            }
        }.onSuccess { result ->
            result.onSuccess { user ->
                _state.value = _state.value.copy(user = user)
            }
        }
    }
}
