package com.venered.social.presentation.viewmodel

import com.venered.social.data.model.Notification
import com.venered.social.domain.usecase.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

data class NotificationsState(
    val notifications: List<Notification> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val unreadCount: Int = 0
)

class NotificationsViewModel(
    private val getNotificationsUseCase: GetNotificationsUseCase,
    private val markNotificationAsReadUseCase: MarkNotificationAsReadUseCase
) {
    private val _state = MutableStateFlow(NotificationsState())
    val state: StateFlow<NotificationsState> = _state

    fun loadNotifications(userId: String, limit: Int = 50) {
        _state.value = _state.value.copy(isLoading = true, error = null)

        kotlin.runCatching {
            kotlinx.coroutines.runBlocking {
                getNotificationsUseCase(userId, limit = limit)
            }
        }.onSuccess { result ->
            result.onSuccess { notifications ->
                val unreadCount = notifications.count { !it.isRead }
                _state.value = _state.value.copy(
                    notifications = notifications,
                    isLoading = false,
                    unreadCount = unreadCount
                )
            }.onFailure { exception ->
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = exception.message
                )
            }
        }
    }

    fun markAsRead(notificationId: String) {
        kotlin.runCatching {
            kotlinx.coroutines.runBlocking {
                markNotificationAsReadUseCase(notificationId)
            }
        }.onSuccess { result ->
            result.onSuccess {
                // Actualizar estado local
                _state.value = _state.value.copy(
                    notifications = _state.value.notifications.map { notif ->
                        if (notif.id == notificationId) {
                            notif.copy(isRead = true)
                        } else {
                            notif
                        }
                    },
                    unreadCount = maxOf(0, _state.value.unreadCount - 1)
                )
            }
        }
    }

    fun markAllAsRead() {
        _state.value.notifications.forEach { notification ->
            if (!notification.isRead) {
                markAsRead(notification.id)
            }
        }
    }
}
