package com.venered.social.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
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
import com.venered.social.presentation.viewmodel.NotificationsViewModel
import com.venered.social.di.SharedComponent
import com.venered.social.data.model.Notification
import com.venered.social.utils.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationsScreen(navController: NavController, userId: String) {
    val viewModel = remember { SharedComponent.provideNotificationsViewModel() }
    val state by viewModel.state.collectAsState()

    LaunchedEffect(userId) {
        viewModel.loadNotifications(userId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Notificaciones") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Atrás")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues)) {
            if (state.isLoading && state.notifications.isEmpty()) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (state.error != null && state.notifications.isEmpty()) {
                Text(state.error!!, color = MaterialTheme.colorScheme.error, modifier = Modifier.align(Alignment.Center))
            } else {
                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    items(state.notifications) { notification ->
                        NotificationItemCard(notification) {
                            viewModel.markAsRead(notification.id)
                        }
                    }

                    if (state.notifications.isEmpty()) {
                        item {
                            Box(
                                modifier = Modifier.fillMaxWidth().padding(32.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Text("No hay notificaciones", color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun NotificationItemCard(notification: Notification, onRead: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = VeneredSpacing.Large.dp, vertical = VeneredSpacing.ExtraSmall.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (notification.isRead) MaterialTheme.colorScheme.surface else MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
        ),
        shape = RoundedCornerShape(VeneredCornerRadius.Medium.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(VeneredSpacing.Medium.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(40.dp),
                shape = RoundedCornerShape(50),
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
            ) {}

            Column(modifier = Modifier.weight(1f).padding(horizontal = VeneredSpacing.Medium.dp)) {
                Text(
                    text = "Alguien ${notification.type}", // TODO: Better mapping
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )
                notification.content?.let {
                    Text(text = it, fontSize = 12.sp, color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f))
                }
            }

            Text(
                text = DateTimeFormatter.formatRelativeTime(notification.createdAt),
                fontSize = 11.sp,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
            )
        }
    }
}
