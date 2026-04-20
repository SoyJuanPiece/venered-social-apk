package com.venered.social.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Comment
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.venered.social.presentation.theme.VeneredCornerRadius
import com.venered.social.presentation.theme.VeneredSpacing

@Composable
fun HomeScreen(navController: NavController) {
    var posts by remember { mutableStateOf(emptyList<PostItemData>()) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        // TODO: Load posts from repository
        isLoading = false
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Venered") },
                modifier = Modifier.fillMaxWidth(),
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.primary
                )
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            items(posts) { post ->
                PostCard(post, navController)
            }

            if (isLoading) {
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

@Composable
fun PostCard(post: PostItemData, navController: NavController) {
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
                        text = post.authorName,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                    Text(
                        text = post.timestamp,
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                    )
                }
            }

            // Content
            Text(
                text = post.content,
                modifier = Modifier.padding(bottom = VeneredSpacing.Medium.dp),
                fontSize = 14.sp
            )

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
                        imageVector = Icons.Filled.Comment,
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

data class PostItemData(
    val id: String = "",
    val authorName: String = "Usuario",
    val content: String = "Este es un post de ejemplo",
    val timestamp: String = "hace 2 horas",
    val likesCount: Int = 0,
    val commentsCount: Int = 0,
    val mediaUrl: String? = null
)
