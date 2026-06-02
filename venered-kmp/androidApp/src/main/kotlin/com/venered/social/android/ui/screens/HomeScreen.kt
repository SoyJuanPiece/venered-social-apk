package com.venered.social.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.ModeComment
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.venered.social.presentation.theme.VeneredCornerRadius
import com.venered.social.presentation.theme.VeneredSpacing
import com.venered.social.presentation.viewmodel.HomeFeedViewModel
import com.venered.social.di.SharedComponent
import com.venered.social.data.model.Post
import com.venered.social.utils.DateTimeFormatter
import com.venered.social.android.ui.widgets.StoriesBar
import com.venered.social.android.ui.widgets.PostSkeleton

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(navController: NavController, userId: String) {
    val viewModel = remember { SharedComponent.provideHomeFeedViewModel() }
    val state by viewModel.state.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.setCurrentUser(userId)
        viewModel.loadInitialFeed()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Venered", fontWeight = FontWeight.Bold) },
                modifier = Modifier.fillMaxWidth(),
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.primary
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { navController.navigate("create_post") },
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            ) {
                Icon(Icons.Default.Add, contentDescription = "Crear Post")
            }
        }
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues)) {
            LazyColumn(
                modifier = Modifier.fillMaxSize()
            ) {
                // Barra de Historias
                item {
                    StoriesBar(
                        stories = state.stories,
                        onStoryClick = { /* Ver historia */ },
                        onAddStoryClick = { /* Añadir historia */ }
                    )
                    Divider(
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.05f),
                        thickness = 1.dp
                    )
                }

                if (state.isLoading && state.posts.isEmpty()) {
                    // Skeletons al cargar
                    items(5) {
                        PostSkeleton()
                    }
                } else if (state.error != null && state.posts.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillParentMaxSize()
                                .padding(32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "Error: ${state.error}",
                                color = MaterialTheme.colorScheme.error,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                } else if (!state.isLoading && state.posts.isEmpty()) {
                    // Estado vacío
                    item {
                        Box(
                            modifier = Modifier
                                .fillParentMaxSize()
                                .padding(32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    text = "La aplicación está vacía",
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Bold,
                                    textAlign = TextAlign.Center
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    text = "Haz una publicación para comenzar a conectar con otros.",
                                    fontSize = 14.sp,
                                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
                                    textAlign = TextAlign.Center
                                )
                            }
                        }
                    }
                } else {
                    // Posts del feed
                    items(state.posts) { post ->
                        PostCard(post, navController)
                    }

                    if (state.isLoading) {
                        item {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(32.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun PostCard(post: Post, navController: NavController) {
    var isLiked by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(VeneredSpacing.Medium.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(VeneredCornerRadius.Large.dp)
    ) {
        Column(modifier = Modifier.padding(VeneredSpacing.Medium.dp)) {
            // Author Info
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = VeneredSpacing.Medium.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Avatar (placeholder)
                Surface(
                    modifier = Modifier
                        .size(40.dp),
                    shape = RoundedCornerShape(50),
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
                ) {
                    // Avatar image would go here
                }

                Column(modifier = Modifier.padding(start = VeneredSpacing.Medium.dp)) {
                    Text(
                        text = if (post.username.isNotEmpty()) post.username else "Usuario",
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                    Text(
                        text = DateTimeFormatter.formatRelativeTime(post.createdAt),
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                    )
                }
            }

            // Content
            post.content?.let {
                Text(
                    text = it,
                    modifier = Modifier.padding(bottom = VeneredSpacing.Medium.dp),
                    fontSize = 14.sp
                )
            }

            // Engagement Stats
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = VeneredSpacing.Medium.dp),
                horizontalArrangement = Arrangement.spacedBy(VeneredSpacing.Large.dp)
            ) {
                Text("${post.likesCount} likes", fontSize = 12.sp)
                Text("${post.commentsCount} comments", fontSize = 12.sp)
            }

            // Actions
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(VeneredSpacing.ExtraSmall.dp)
            ) {
                IconButton(
                    onClick = { isLiked = !isLiked },
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(
                        imageVector = if (isLiked) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                        contentDescription = "Like",
                        tint = if (isLiked) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.onBackground
                    )
                }

                IconButton(
                    onClick = { },
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(
                        imageVector = Icons.Filled.ModeComment,
                        contentDescription = "Comment",
                        tint = MaterialTheme.colorScheme.onBackground
                    )
                }

                IconButton(
                    onClick = { },
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Share,
                        contentDescription = "Share",
                        tint = MaterialTheme.colorScheme.onBackground
                    )
                }
            }
        }
    }
}
