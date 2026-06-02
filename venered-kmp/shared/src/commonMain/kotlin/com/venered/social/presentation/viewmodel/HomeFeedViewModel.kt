package com.venered.social.presentation.viewmodel

import com.venered.social.data.model.Post
import com.venered.social.data.model.Story
import com.venered.social.domain.usecase.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class HomeFeedState(
    val posts: List<Post> = emptyList(),
    val stories: List<Story> = emptyList(),
    val isLoading: Boolean = false,
    val isLoadingStories: Boolean = false,
    val error: String? = null,
    val hasMore: Boolean = true
)

class HomeFeedViewModel(
    private val getFeedPostsUseCase: GetFeedPostsUseCase,
    private val getFeedStoriesUseCase: GetFeedStoriesUseCase,
    private val likePostUseCase: LikePostUseCase,
    private val unlikePostUseCase: UnlikePostUseCase
) : BaseViewModel() {
    private val _state = MutableStateFlow(HomeFeedState())
    val state: StateFlow<HomeFeedState> = _state

    private var currentOffset = 0
    private val pageSize = 15
    private var currentUserId: String? = null

    fun setCurrentUser(userId: String) {
        currentUserId = userId
    }

    fun loadInitialFeed() {
        loadStories()
        loadFeed(reset = true)
    }

    private fun loadStories() {
        _state.value = _state.value.copy(isLoadingStories = true)
        viewModelScope.launch {
            getFeedStoriesUseCase()
                .onSuccess { stories ->
                    _state.value = _state.value.copy(
                        stories = stories,
                        isLoadingStories = false
                    )
                }.onFailure {
                    _state.value = _state.value.copy(isLoadingStories = false)
                }
        }
    }

    fun loadMorePosts() {
        if (_state.value.isLoading || !_state.value.hasMore) return
        loadFeed(reset = false)
    }

    private fun loadFeed(reset: Boolean) {
        _state.value = _state.value.copy(isLoading = true, error = null)
        if (reset) {
            currentOffset = 0
        }

        viewModelScope.launch {
            getFeedPostsUseCase(limit = pageSize, offset = currentOffset)
                .onSuccess { newPosts ->
                    val updatedPosts = if (reset) newPosts else _state.value.posts + newPosts
                    currentOffset += pageSize

                    _state.value = _state.value.copy(
                        posts = updatedPosts,
                        isLoading = false,
                        hasMore = newPosts.size == pageSize
                    )
                }.onFailure { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message ?: "Error cargando feed"
                    )
                }
        }
    }

    fun toggleLike(postId: String, userId: String, isLiked: Boolean) {
        viewModelScope.launch {
            if (isLiked) {
                unlikePostUseCase(userId, postId)
            } else {
                likePostUseCase(userId, postId)
            }
        }
    }
}
