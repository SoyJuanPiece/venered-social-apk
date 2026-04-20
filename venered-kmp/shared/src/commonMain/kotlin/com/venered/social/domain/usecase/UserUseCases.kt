package com.venered.social.domain.usecase

import com.venered.social.data.model.User
import com.venered.social.data.repository.UserRepository

class GetUserProfileUseCase(private val userRepository: UserRepository) {
    suspend operator fun invoke(userId: String): Result<User> {
        return userRepository.getUserProfile(userId)
    }
}

class GetUserByUsernameUseCase(private val userRepository: UserRepository) {
    suspend operator fun invoke(username: String): Result<User> {
        return userRepository.getUserByUsername(username)
    }
}

class SearchUsersUseCase(private val userRepository: UserRepository) {
    suspend operator fun invoke(query: String): Result<List<User>> {
        return userRepository.searchUsers(query)
    }
}

class UpdateProfileUseCase(private val userRepository: UserRepository) {
    suspend operator fun invoke(userId: String, displayName: String?, bio: String?, estado: String?): Result<User> {
        return userRepository.updateProfile(userId, displayName, bio, estado)
    }
}

class UpdateAvatarUseCase(private val userRepository: UserRepository) {
    suspend operator fun invoke(userId: String, avatarUrl: String): Result<User> {
        return userRepository.updateAvatar(userId, avatarUrl)
    }
}

class SetOnlineStatusUseCase(private val userRepository: UserRepository) {
    suspend operator fun invoke(userId: String, isOnline: Boolean): Result<Unit> {
        return userRepository.setOnlineStatus(userId, isOnline)
    }
}
