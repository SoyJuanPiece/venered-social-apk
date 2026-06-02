package com.venered.social.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.venered.social.android.ui.theme.VeneredTheme
import com.venered.social.android.ui.screens.*

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            VeneredTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    VeneredNavigation()
                }
            }
        }
    }
}

@Composable
fun VeneredNavigation() {
    val rootNavController = rememberNavController()
    val isLoggedIn = remember { mutableStateOf(false) }
    val currentUserId = remember { mutableStateOf("") }

    NavHost(
        navController = rootNavController,
        startDestination = if (isLoggedIn.value) "main" else "login"
    ) {
        composable("login") {
            LoginScreen(
                navController = rootNavController,
                onLoginSuccess = { userId ->
                    currentUserId.value = userId
                    isLoggedIn.value = true
                    rootNavController.navigate("main") {
                        popUpTo("login") { inclusive = true }
                    }
                }
            )
        }

        composable("register") {
            RegisterScreen(
                navController = rootNavController,
                onRegisterSuccess = { userId ->
                    currentUserId.value = userId
                    isLoggedIn.value = true
                    rootNavController.navigate("main") {
                        popUpTo("login") { inclusive = true }
                    }
                }
            )
        }

        composable("main") {
            MainNavigationScreen(rootNavController, currentUserId.value)
        }

        composable("create_post") {
            CreatePostScreen(rootNavController, currentUserId.value)
        }

        composable("story_viewer/{storyId}") { backStackEntry ->
            val storyId = backStackEntry.arguments?.getString("storyId") ?: ""
            StoryViewerScreen(rootNavController, storyId)
        }

        composable("chat/{conversationId}/{otherUsername}/{otherUserId}") { backStackEntry ->
            val conversationId = backStackEntry.arguments?.getString("conversationId") ?: ""
            val otherUsername = backStackEntry.arguments?.getString("otherUsername") ?: ""
            val otherUserId = backStackEntry.arguments?.getString("otherUserId") ?: ""
            ChatScreen(conversationId, otherUsername, otherUserId, currentUserId.value, rootNavController)
        }

        composable("profile/{userId}") { backStackEntry ->
            val userId = backStackEntry.arguments?.getString("userId") ?: ""
            ProfileScreen(userId, rootNavController)
        }
    }
}
