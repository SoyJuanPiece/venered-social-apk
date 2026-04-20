package com.venered.social.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun ExploreScreen() {
    var searchQuery by remember { mutableStateOf("") }
    var searchResults by remember { mutableStateOf(emptyList<UserSearchResult>()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
    ) {
        // Search Bar
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { 
                searchQuery = it
                // TODO: Filtrar resultados en tiempo real
            },
            label = { Text("Buscar usuarios") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp),
            trailingIcon = { }
        )

        // Suggested Users
        if (searchQuery.isEmpty()) {
            Text(
                text = "Sugerencias",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(16.dp)
            )

            repeat(6) { index ->
                SuggestedUserCard(
                    userName = "Usuario $index",
                    userHandle = "@usuario$index",
                    mutualFriends = (5..20).random()
                )
            }
        } else {
            // Search Results
            searchResults.forEach { user ->
                SearchResultCard(user)
            }
        }
    }
}

@Composable
fun SuggestedUserCard(userName: String, userHandle: String, mutualFriends: Int) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar
            Surface(
                modifier = Modifier.size(48.dp),
                shape = RoundedCornerShape(50),
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
            ) {}

            Column(modifier = Modifier.weight(1f).padding(start = 12.dp)) {
                Text(userName, fontWeight = FontWeight.Bold)
                Text("$mutualFriends amigos en común", fontSize = 12.sp, color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f))
            }

            Button(
                onClick = { },
                modifier = Modifier.height(32.dp),
                contentPadding = PaddingValues(horizontal = 16.dp)
            ) {
                Text("Seguir", fontSize = 12.sp)
            }
        }
    }
}

@Composable
fun SearchResultCard(user: UserSearchResult) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(40.dp),
                shape = RoundedCornerShape(50),
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
            ) {}

            Column(modifier = Modifier.weight(1f).padding(start = 12.dp)) {
                Text(user.name, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                Text(user.handle, fontSize = 12.sp, color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f))
            }
        }
    }
}

data class UserSearchResult(
    val id: String = "",
    val name: String = "",
    val handle: String = "",
    val avatarUrl: String? = null
)
