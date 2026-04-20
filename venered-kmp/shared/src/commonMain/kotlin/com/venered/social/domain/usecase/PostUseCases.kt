package com.venered.social.domain.usecase

import com.venered.social.data.model.Post
import com.venered.social.data.repository.PostRepository

class GetFeedPostsUseCase(private val postRepository: PostRepository) {
    suspend operator fun invoke(limit: Int = 15, offset: Int = 0): Result<List<Post>> {
        return postRepository.getFeedPosts(limit, offset)
    }
}

class GetUserPostsUseCase(private val postRepository: PostRepository) {
    suspend operator fun invoke(userId: String, limit: Int = 15, offset: Int = 0): Result<List<Post>> {
        return postRepository.getPostsByUser(userId, limit, offset)
    }
}

class CreatePostUseCase(private val postRepository: PostRepository) {
    suspend operator fun invoke(userId: String, content: String?, mediaUrl: String?, type: String = "text"): Result<Post> {
        return postRepository.createPost(userId, content, mediaUrl, type)
    }
}

class DeletePostUseCase(private val postRepository: PostRepository) {
    suspend operator fun invoke(postId: String): Result<Unit> {
        return postRepository.deletePost(postId)
    }
}

class LikePostUseCase(private val postRepository: PostRepository) {
    suspend operator fun invoke(userId: String, postId: String): Result<Unit> {
        return postRepository.likePost(userId, postId)
    }
}

class UnlikePostUseCase(private val postRepository: PostRepository) {
    suspend operator fun invoke(userId: String, postId: String): Result<Unit> {
        return postRepository.unlikePost(userId, postId)
    }
}

class GetCommentsUseCase(private val postRepository: PostRepository) {
    suspend operator fun invoke(postId: String): Result<List<com.venered.social.data.model.Comment>> {
        return postRepository.getComments(postId)
    }
}

class AddCommentUseCase(private val postRepository: PostRepository) {
    suspend operator fun invoke(userId: String, postId: String, content: String): Result<com.venered.social.data.model.Comment> {
        return postRepository.addComment(userId, postId, content)
    }
}
