package com.venered.social.android.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
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
import com.venered.social.presentation.viewmodel.MessagesViewModel
import com.venered.social.di.SharedComponent
import com.venered.social.data.model.Conversation
import com.venered.social.utils.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MessagesScreen(navController: NavController, userId: String) {
    val viewModel = remember { SharedComponent.provideMessagesViewModel() }
    val state by viewModel.state.collectAsState()

    LaunchedEffect(userId) {
        viewModel.loadConversations(userId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Mensajes", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues)) {
            if (state.isLoading && state.conversations.isEmpty()) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (state.error != null && state.conversations.isEmpty()) {
                Text(
                    text = "Error: ${state.error}", 
                    color = MaterialTheme.colorScheme.error, 
                    modifier = Modifier.align(Alignment.Center).padding(16.dp)
                )
            } else if (!state.isLoading && state.conversations.isEmpty()) {
                Column(
                    modifier = Modifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text("No tienes mensajes todavía", fontWeight = FontWeight.Medium)
                }
            } else {
                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    items(state.conversations) { conversation ->
                        ConversationItem(conversation) {
                            val otherUserId = if (conversation.user1Id == userId) conversation.user2Id else conversation.user1Id
                            navController.navigate("chat/${conversation.id}/${conversation.otherUsername}/$otherUserId")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ConversationItem(conversation: Conversation, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = VeneredSpacing.Large.dp, vertical = VeneredSpacing.ExtraSmall.dp)
            .clickable { onClick() },
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(VeneredCornerRadius.Medium.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(VeneredSpacing.Medium.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(56.dp),
                shape = CircleShape,
                color = MaterialTheme.colorScheme.surfaceVariant
            ) {
                if (conversation.otherAvatarUrl != null) {
                    AsyncImage(
                        model = conversation.otherAvatarUrl,
                        contentDescription = conversation.otherUsername,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Icon(
                        Icons.Default.Person, 
                        contentDescription = null, 
                        modifier = Modifier.padding(12.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                    )
                }
            }

            Column(modifier = Modifier.weight(1f).padding(horizontal = VeneredSpacing.Medium.dp)) {
                Text(
                    text = conversation.otherUsername,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
                Text(
                    text = conversation.lastMessageContent ?: "Empezar chat",
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
                    maxLines = 1,
                    overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis
                )
            }

            Text(
                text = DateTimeFormatter.formatRelativeTime(conversation.lastMessageAt),
                fontSize = 11.sp,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
            )
        }
    }
}
