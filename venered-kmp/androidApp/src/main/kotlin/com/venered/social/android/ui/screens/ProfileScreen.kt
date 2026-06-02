package com.venered.social.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.venered.social.presentation.theme.VeneredCornerRadius
import com.venered.social.presentation.theme.VeneredSpacing
import com.venered.social.presentation.viewmodel.ProfileViewModel
import com.venered.social.di.SharedComponent
import com.venered.social.data.model.User
import com.venered.social.data.model.Post

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(userId: String, navController: NavController) {
    val viewModel = remember { SharedComponent.provideProfileViewModel() }
    val state by viewModel.state.collectAsState()
    val userPosts by viewModel.userPosts.collectAsState()

    LaunchedEffect(userId) {
        viewModel.loadUserProfile(userId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(state.user?.displayName ?: "Perfil") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Atrás")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues)) {
            if (state.isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            } else if (state.error != null) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(text = "Error: ${state.error}", color = MaterialTheme.colorScheme.error)
                }
            } else {
                state.user?.let { user ->
                    ProfileContent(user, userPosts, navController)
                }
            }
        }
    }
}

@Composable
fun ProfileContent(user: User, posts: List<Post>, navController: NavController) {
    LazyColumn(
        modifier = Modifier.fillMaxSize()
    ) {
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(VeneredSpacing.Large.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Avatar
                Surface(
                    modifier = Modifier.size(100.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    if (user.avatarUrl != null) {
                        AsyncImage(
                            model = user.avatarUrl,
                            contentDescription = user.username,
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Icon(
                            Icons.Default.Person,
                            contentDescription = null,
                            modifier = Modifier.padding(24.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                        )
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(top = VeneredSpacing.Medium.dp)
                ) {
                    Text(
                        text = user.displayName ?: user.username,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold
                    )
                    if (user.isVerified) {
                        Icon(
                            Icons.Default.Verified,
                            contentDescription = "Verificado",
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(start = 6.dp).size(20.dp)
                        )
                    }
                }

                Text(
                    text = "@${user.username}",
                    fontSize = 16.sp,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )

                user.bio?.let {
                    Text(
                        text = it,
                        fontSize = 14.sp,
                        modifier = Modifier.padding(vertical = VeneredSpacing.Medium.dp),
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center
                    )
                }

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = VeneredSpacing.Medium.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    StatColumn("${posts.size}", "Posts")
                    StatColumn("0", "Seguidores")
                    StatColumn("0", "Siguiendo")
                }

                Button(
                    onClick = { },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = VeneredSpacing.Medium.dp),
                    shape = RoundedCornerShape(VeneredCornerRadius.Medium.dp)
                ) {
                    Text("Editar perfil")
                }
            }
        }

        item {
            Text(
                text = "Posts",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(horizontal = VeneredSpacing.Large.dp, vertical = VeneredSpacing.Medium.dp)
            )
        }

        items(posts) { post ->
            PostCard(post, navController)
        }
    }
}

@Composable
fun StatColumn(count: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = count,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = label,
            fontSize = 12.sp,
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
        )
    }
}
