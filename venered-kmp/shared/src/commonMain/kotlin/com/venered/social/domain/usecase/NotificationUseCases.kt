package com.venered.social.domain.usecase

import com.venered.social.data.model.Notification
import com.venered.social.data.repository.NotificationRepository

class GetNotificationsUseCase(private val notificationRepository: NotificationRepository) {
    suspend operator fun invoke(userId: String, limit: Int = 50, offset: Int = 0): Result<List<Notification>> {
        return notificationRepository.getNotifications(userId, limit, offset)
    }
}

class MarkNotificationAsReadUseCase(private val notificationRepository: NotificationRepository) {
    suspend operator fun invoke(notificationId: String): Result<Unit> {
        return notificationRepository.markNotificationAsRead(notificationId)
    }
}

class CreateNotificationUseCase(private val notificationRepository: NotificationRepository) {
    suspend operator fun invoke(receiverId: String, senderId: String, type: String, relatedId: String? = null, content: String? = null): Result<Notification> {
        return notificationRepository.createNotification(receiverId, senderId, type, relatedId, content)
    }
}

class SaveFCMTokenUseCase(private val notificationRepository: NotificationRepository) {
    suspend operator fun invoke(userId: String, fcmToken: String): Result<Unit> {
        return notificationRepository.saveFCMToken(userId, fcmToken)
    }
}
