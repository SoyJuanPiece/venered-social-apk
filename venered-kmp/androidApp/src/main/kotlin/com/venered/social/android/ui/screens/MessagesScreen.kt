package com.venered.social.android.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
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
                title = { Text("Mensajes") },
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
                Text(state.error!!, color = MaterialTheme.colorScheme.error, modifier = Modifier.align(Alignment.Center))
            } else {
                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    items(state.conversations) { conversation ->
                        ConversationItem(conversation) {
                            navController.navigate("chat/${conversation.id}/${conversation.otherUsername}")
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
                shape = RoundedCornerShape(50),
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
            ) {}

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
                    maxLines = 1
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
