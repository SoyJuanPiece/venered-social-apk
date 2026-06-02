package com.venered.social.domain.usecase

import com.venered.social.data.model.Story
import com.venered.social.data.repository.StoryRepository

class GetFeedStoriesUseCase(private val repository: StoryRepository) {
    suspend operator fun invoke(): Result<List<Story>> = repository.getStoriesForFeed()
}

class CreateStoryUseCase(private val repository: StoryRepository) {
    suspend operator fun invoke(userId: String, mediaUrl: String, type: String = "image"): Result<Story> =
        repository.createStory(userId, mediaUrl, type)
}

class DeleteStoryUseCase(private val repository: StoryRepository) {
    suspend operator fun invoke(storyId: String): Result<Unit> = repository.deleteStory(storyId)
}
