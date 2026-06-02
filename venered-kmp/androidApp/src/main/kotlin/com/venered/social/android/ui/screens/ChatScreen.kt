package com.venered.social.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.venered.social.presentation.theme.VeneredCornerRadius
import com.venered.social.presentation.theme.VeneredSpacing
import com.venered.social.presentation.viewmodel.MessagesViewModel
import com.venered.social.di.SharedComponent
import com.venered.social.data.model.Message
import com.venered.social.utils.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(conversationId: String, otherUsername: String, otherUserId: String, currentUserId: String, navController: NavController) {
    val viewModel = remember { SharedComponent.provideMessagesViewModel() }
    val state by viewModel.state.collectAsState()
    var messageText by remember { mutableStateOf("") }

    LaunchedEffect(conversationId) {
        viewModel.loadConversationMessages(conversationId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(otherUsername, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Volver")
                    }
                }
            )
        },
        bottomBar = {
            BottomAppBar(
                containerColor = MaterialTheme.colorScheme.surface,
                contentPadding = PaddingValues(horizontal = VeneredSpacing.Medium.dp)
            ) {
                OutlinedTextField(
                    value = messageText,
                    onValueChange = { messageText = it },
                    modifier = Modifier.weight(1f).padding(vertical = 4.dp),
                    placeholder = { Text("Mensaje...") },
                    shape = RoundedCornerShape(VeneredCornerRadius.ExtraLarge.dp)
                )
                IconButton(
                    onClick = {
                        if (messageText.isNotEmpty()) {
                            viewModel.sendMessage(conversationId, currentUserId, otherUserId, messageText)
                            messageText = ""
                        }
                    },
                    modifier = Modifier.padding(start = 8.dp)
                ) {
                    Icon(Icons.Default.Send, contentDescription = "Enviar", tint = MaterialTheme.colorScheme.primary)
                }
            }
        }
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues)) {
            if (state.isLoading && state.currentMessages.isEmpty()) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize().padding(horizontal = VeneredSpacing.Medium.dp),
                    reverseLayout = false
                ) {
                    items(state.currentMessages) { message ->
                        MessageBubble(message, message.senderId == currentUserId)
                    }
                }
            }
        }
    }
}

@Composable
fun MessageBubble(message: Message, isFromMe: Boolean) {
    val alignment = if (isFromMe) Alignment.CenterEnd else Alignment.CenterStart
    val color = if (isFromMe) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant
    val textColor = if (isFromMe) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant

    Box(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp), contentAlignment = alignment) {
        Card(
            shape = RoundedCornerShape(
                topStart = 16.dp,
                topEnd = 16.dp,
                bottomStart = if (isFromMe) 16.dp else 0.dp,
                bottomEnd = if (isFromMe) 0.dp else 16.dp
            ),
            colors = CardDefaults.cardColors(containerColor = color)
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                message.content?.let {
                    Text(text = it, color = textColor, fontSize = 14.sp)
                }
                Text(
                    text = DateTimeFormatter.formatRelativeTime(message.createdAt),
                    color = textColor.copy(alpha = 0.6f),
                    fontSize = 10.sp,
                    modifier = Modifier.align(Alignment.End).padding(top = 4.dp)
                )
            }
        }
    }
}
