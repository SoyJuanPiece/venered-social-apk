package com.venered.social.presentation.viewmodel

import com.venered.social.data.model.User
import com.venered.social.domain.usecase.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

import kotlinx.coroutines.launch

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
) : BaseViewModel() {
    private val _state = MutableStateFlow(ProfileState())
    val state: StateFlow<ProfileState> = _state

    private val _userPosts = MutableStateFlow<List<com.venered.social.data.model.Post>>(emptyList())
    val userPosts: StateFlow<List<com.venered.social.data.model.Post>> = _userPosts

    fun loadUserProfile(userId: String) {
        _state.value = _state.value.copy(isLoading = true, error = null)

        viewModelScope.launch {
            getUserProfileUseCase(userId)
                .onSuccess { user ->
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
        }
    }

    private fun loadUserPosts(userId: String) {
        viewModelScope.launch {
            getUserPostsUseCase(userId)
                .onSuccess { posts ->
                    _userPosts.value = posts
                }
        }
    }

    fun updateProfile(userId: String, displayName: String?, bio: String?, estado: String?) {
        _state.value = _state.value.copy(isLoading = true)

        viewModelScope.launch {
            updateProfileUseCase(userId, displayName, bio, estado)
                .onSuccess { user ->
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
        viewModelScope.launch {
            updateAvatarUseCase(userId, avatarUrl)
                .onSuccess { user ->
                    _state.value = _state.value.copy(user = user)
                }
        }
    }
}
