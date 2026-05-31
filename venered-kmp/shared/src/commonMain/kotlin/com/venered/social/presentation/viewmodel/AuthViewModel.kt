package com.venered.social.presentation.viewmodel

import com.venered.social.data.repository.AuthResponse
import com.venered.social.domain.usecase.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class AuthState(
    val authResponse: AuthResponse? = null,
    val isLoading: Boolean = false,
    val error: String? = null,
    val isRegistered: Boolean = false
)

class AuthViewModel(
    private val loginUseCase: LoginUseCase,
    private val registerUseCase: RegisterUseCase,
    private val logoutUseCase: LogoutUseCase,
    private val resetPasswordUseCase: ResetPasswordUseCase
) : BaseViewModel() {
    private val _state = MutableStateFlow(AuthState())
    val state: StateFlow<AuthState> = _state

    fun login(email: String, password: String) {
        _state.value = _state.value.copy(isLoading = true, error = null)
        viewModelScope.launch {
            loginUseCase(email, password)
                .onSuccess { response ->
                    _state.value = _state.value.copy(
                        authResponse = response,
                        isLoading = false
                    )
                }.onFailure { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message ?: "Error al iniciar sesión"
                    )
                }
        }
    }

    fun register(email: String, password: String, username: String) {
        _state.value = _state.value.copy(isLoading = true, error = null)
        val metadata = mapOf("username" to username)
        viewModelScope.launch {
            registerUseCase(email, password, metadata)
                .onSuccess { response ->
                    _state.value = _state.value.copy(
                        authResponse = response,
                        isLoading = false,
                        isRegistered = true
                    )
                }.onFailure { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message ?: "Error al registrarse"
                    )
                }
        }
    }

    fun logout(token: String) {
        viewModelScope.launch {
            logoutUseCase(token)
            _state.value = AuthState()
        }
    }

    fun resetPassword(email: String) {
        _state.value = _state.value.copy(isLoading = true, error = null)
        viewModelScope.launch {
            resetPasswordUseCase(email)
                .onSuccess {
                    _state.value = _state.value.copy(isLoading = false)
                }.onFailure { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message
                    )
                }
        }
    }
}
