package com.venered.social.domain.usecase

import com.venered.social.data.repository.AuthRepository
import com.venered.social.data.repository.AuthResponse

class LoginUseCase(private val authRepository: AuthRepository) {
    suspend operator fun invoke(email: String, password: String): Result<AuthResponse> {
        return authRepository.signInWithPassword(email, password)
    }
}

class RegisterUseCase(private val authRepository: AuthRepository) {
    suspend operator fun invoke(email: String, password: String, metadata: Map<String, String>): Result<AuthResponse> {
        return authRepository.signUp(email, password, metadata)
    }
}

class LogoutUseCase(private val authRepository: AuthRepository) {
    suspend operator fun invoke(token: String): Result<Unit> {
        return authRepository.signOut(token)
    }
}

class ResetPasswordUseCase(private val authRepository: AuthRepository) {
    suspend operator fun invoke(email: String): Result<Unit> {
        return authRepository.resetPassword(email)
    }
}
