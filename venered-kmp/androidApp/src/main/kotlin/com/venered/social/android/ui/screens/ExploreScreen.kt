package com.venered.social.android.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
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
import com.venered.social.presentation.viewmodel.SearchViewModel
import com.venered.social.di.SharedComponent
import com.venered.social.data.model.User

@Composable
fun ExploreScreen(navController: NavController) {
    val viewModel = remember { SharedComponent.provideSearchViewModel() }
    val state by viewModel.state.collectAsState()
    var searchQuery by remember { mutableStateOf("") }

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Search Bar
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { 
                searchQuery = it
                viewModel.search(it)
            },
            placeholder = { Text("Buscar usuarios...") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(VeneredSpacing.Large.dp),
            shape = RoundedCornerShape(VeneredCornerRadius.Large.dp),
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
            singleLine = true
        )

        Box(modifier = Modifier.fillMaxSize()) {
            if (state.isLoading) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (state.error != null) {
                Text(
                    text = state.error!!,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.align(Alignment.Center)
                )
            } else if (searchQuery.isEmpty()) {
                // Empty state or suggestions
                Column(
                    modifier = Modifier.fillMaxSize().padding(VeneredSpacing.Large.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = "Descubre personas nuevas",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                    )
                    Text(
                        text = "Busca por nombre de usuario",
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.4f)
                    )
                }
            } else {
                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    items(state.results) { user ->
                        SearchResultCard(user) {
                            navController.navigate("profile/${user.id}")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun SearchResultCard(user: User, onClick: () -> Unit) {
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
                modifier = Modifier.size(48.dp),
                shape = RoundedCornerShape(50),
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
            ) {
                // Image placeholder
            }

            Column(modifier = Modifier.weight(1f).padding(start = VeneredSpacing.Medium.dp)) {
                Text(
                    text = user.displayName ?: user.username,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
                Text(
                    text = "@${user.username}",
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )
            }

            if (user.isVerified) {
                Text("✅", fontSize = 12.sp)
            }
        }
    }
}
