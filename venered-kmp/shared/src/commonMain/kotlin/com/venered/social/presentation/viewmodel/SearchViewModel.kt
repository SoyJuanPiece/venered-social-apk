package com.venered.social.presentation.viewmodel

import com.venered.social.data.model.User
import com.venered.social.domain.usecase.SearchUsersUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class SearchState(
    val results: List<User> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

class SearchViewModel(
    private val searchUsersUseCase: SearchUsersUseCase
) : BaseViewModel() {
    private val _state = MutableStateFlow(SearchState())
    val state: StateFlow<SearchState> = _state

    fun search(query: String) {
        if (query.isBlank()) {
            _state.value = SearchState()
            return
        }

        _state.value = _state.value.copy(isLoading = true, error = null)
        viewModelScope.launch {
            searchUsersUseCase(query)
                .onSuccess { users ->
                    _state.value = _state.value.copy(
                        results = users,
                        isLoading = false
                    )
                }.onFailure { exception ->
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = exception.message ?: "Error al buscar usuarios"
                    )
                }
        }
    }
}
