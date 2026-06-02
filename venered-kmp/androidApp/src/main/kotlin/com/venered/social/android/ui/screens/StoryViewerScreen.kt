package com.venered.social.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.venered.social.presentation.viewmodel.HomeFeedViewModel
import com.venered.social.di.SharedComponent
import kotlinx.coroutines.delay
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.input.pointer.pointerInput

@Composable
fun StoryViewerScreen(navController: NavController, initialStoryId: String) {
    val viewModel = remember { SharedComponent.provideHomeFeedViewModel() }
    val state by viewModel.state.collectAsState()
    
    val stories = state.stories
    if (stories.isEmpty()) {
        LaunchedEffect(Unit) { navController.popBackStack() }
        return
    }

    var currentIndex by remember { 
        mutableStateOf(stories.indexOfFirst { it.id == initialStoryId }.coerceAtLeast(0)) 
    }
    
    val currentStory = stories.getOrNull(currentIndex) ?: stories.first()

    // Auto-advance logic
    LaunchedEffect(currentIndex) {
        delay(5000) // 5 seconds per story
        if (currentIndex < stories.size - 1) {
            currentIndex++
        } else {
            navController.popBackStack()
        }
    }

    Box(modifier = Modifier.fillMaxSize().background(Color.Black)) {
        // Story Content
        AsyncImage(
            model = currentStory.mediaUrl,
            contentDescription = null,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Fit
        )

        // Overlay Info
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .align(Alignment.TopStart)
        ) {
            // Progress Bar
            Row(
                modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                stories.forEachIndexed { index, _ ->
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(2.dp)
                            .background(
                                if (index <= currentIndex) Color.White else Color.Gray.copy(alpha = 0.5f)
                            )
                    )
                }
            }

            // User Info
            Row(verticalAlignment = Alignment.CenterVertically) {
                Surface(
                    modifier = Modifier.size(32.dp),
                    shape = CircleShape,
                    color = Color.Gray
                ) {
                    if (currentStory.avatarUrl != null) {
                        AsyncImage(
                            model = currentStory.avatarUrl,
                            contentDescription = null,
                            modifier = Modifier.fillMaxSize().clip(CircleShape),
                            contentScale = ContentScale.Crop
                        )
                    }
                }
                Text(
                    text = currentStory.username,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    modifier = Modifier.padding(start = 8.dp).weight(1f)
                )
                IconButton(onClick = { navController.popBackStack() }) {
                    Icon(Icons.Default.Close, contentDescription = "Cerrar", tint = Color.White)
                }
            }
        }
        
        // Navigation Areas
        Row(modifier = Modifier.fillMaxSize()) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .pointerInput(Unit) {
                        detectTapGestures(onTap = { 
                            if (currentIndex > 0) currentIndex--
                        })
                    }
            )
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .pointerInput(Unit) {
                        detectTapGestures(onTap = { 
                            if (currentIndex < stories.size - 1) currentIndex++
                            else navController.popBackStack()
                        })
                    }
            )
        }
    }
}
