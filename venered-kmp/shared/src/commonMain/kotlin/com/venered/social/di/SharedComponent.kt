package com.venered.social.di

import com.venered.social.data.repository.*
import com.venered.social.domain.usecase.*
import com.venered.social.presentation.viewmodel.*

object SharedComponent {
    // Repositories
    private val postRepository by lazy { PostRepository() }
    private val userRepository by lazy { UserRepository() }
    private val authRepository by lazy { AuthRepository() }
    private val messageRepository by lazy { MessageRepository() }
    private val notificationRepository by lazy { NotificationRepository() }
    private val storyRepository by lazy { StoryRepository() }

    // Use Cases - Posts
    private val getFeedPostsUseCase by lazy { GetFeedPostsUseCase(postRepository) }
    private val getUserPostsUseCase by lazy { GetUserPostsUseCase(postRepository) }
    private val createPostUseCase by lazy { CreatePostUseCase(postRepository) }
    private val deletePostUseCase by lazy { DeletePostUseCase(postRepository) }
    private val likePostUseCase by lazy { LikePostUseCase(postRepository) }
    private val unlikePostUseCase by lazy { UnlikePostUseCase(postRepository) }
    
    // Use Cases - User
    private val getUserProfileUseCase by lazy { GetUserProfileUseCase(userRepository) }
    private val searchUsersUseCase by lazy { SearchUsersUseCase(userRepository) }
    private val updateProfileUseCase by lazy { UpdateProfileUseCase(userRepository) }
    private val updateAvatarUseCase by lazy { UpdateAvatarUseCase(userRepository) }
    
    // Use Cases - Auth
    private val loginUseCase by lazy { LoginUseCase(authRepository) }
    private val registerUseCase by lazy { RegisterUseCase(authRepository) }
    private val logoutUseCase by lazy { LogoutUseCase(authRepository) }
    private val resetPasswordUseCase by lazy { ResetPasswordUseCase(authRepository) }
    
    // Use Cases - Messages
    private val getConversationsUseCase by lazy { GetConversationsUseCase(messageRepository) }
    private val getConversationMessagesUseCase by lazy { GetConversationMessagesUseCase(messageRepository) }
    private val sendMessageUseCase by lazy { SendMessageUseCase(messageRepository) }
    
    // Use Cases - Notifications
    private val getNotificationsUseCase by lazy { GetNotificationsUseCase(notificationRepository) }
    private val markNotificationAsReadUseCase by lazy { MarkNotificationAsReadUseCase(notificationRepository) }

    // Use Cases - Stories
    private val getFeedStoriesUseCase by lazy { GetFeedStoriesUseCase(storyRepository) }
    private val createStoryUseCase by lazy { CreateStoryUseCase(storyRepository) }
    private val deleteStoryUseCase by lazy { DeleteStoryUseCase(storyRepository) }

    // ViewModels
    fun provideAuthViewModel() = AuthViewModel(
        loginUseCase,
        registerUseCase,
        logoutUseCase,
        resetPasswordUseCase
    )

    fun provideHomeFeedViewModel() = HomeFeedViewModel(
        getFeedPostsUseCase,
        getFeedStoriesUseCase,
        likePostUseCase,
        unlikePostUseCase
    )

    fun providePostViewModel() = PostViewModel(
        createPostUseCase,
        deletePostUseCase
    )

    fun provideSearchViewModel() = SearchViewModel(
        searchUsersUseCase
    )

    fun provideProfileViewModel() = ProfileViewModel(
        getUserProfileUseCase,
        updateProfileUseCase,
        updateAvatarUseCase,
        getUserPostsUseCase
    )

    fun provideMessagesViewModel() = MessagesViewModel(
        getConversationsUseCase,
        getConversationMessagesUseCase,
        sendMessageUseCase
    )

    fun provideNotificationsViewModel() = NotificationsViewModel(
        getNotificationsUseCase,
        markNotificationAsReadUseCase
    )
}
