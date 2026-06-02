package com.venered.social.domain.usecase

import com.venered.social.data.repository.MediaRepository

class UploadImageUseCase(private val repository: MediaRepository) {
    suspend operator fun invoke(bytes: ByteArray, fileName: String): Result<String> =
        repository.uploadImage(bytes, fileName)
}

class UploadVideoUseCase(private val repository: MediaRepository) {
    suspend operator fun invoke(bytes: ByteArray, fileName: String, isStory: Boolean = false): Result<String> =
        repository.uploadToTelegram(bytes, fileName, isStory)
}
