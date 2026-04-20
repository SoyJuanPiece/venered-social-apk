package com.venered.social.android.ui.screens

import androidx.compose.foundation.layout.*
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

@Composable
fun ProfileScreen(userId: String, navController: NavController) {
    var userName by remember { mutableStateOf("@usuario") }
    var displayName by remember { mutableStateOf("Nombre Usuario") }
    var bio by remember { mutableStateOf("Bio del usuario") }
    var postsCount by remember { mutableStateOf(42) }
    var followersCount by remember { mutableStateOf(1230) }
    var followingCount by remember { mutableStateOf(564) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(displayName) },
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(VeneredSpacing.Medium.dp)
        ) {
            // Avatar (placeholder)
            Surface(
                modifier = Modifier
                    .size(80.dp)
                    .align(Alignment.CenterHorizontally),
                shape = RoundedCornerShape(50),
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
            ) {}

            // User Info
            Text(
                text = displayName,
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .padding(top = VeneredSpacing.Medium.dp)
            )

            Text(
                text = userName,
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
                modifier = Modifier.align(Alignment.CenterHorizontally)
            )

            Text(
                text = bio,
                fontSize = 14.sp,
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .padding(top = VeneredSpacing.ExtraSmall.dp)
            )

            // Stats Row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = VeneredSpacing.Large.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                StatColumn("$postsCount", "Posts")
                StatColumn("$followersCount", "Seguidores")
                StatColumn("$followingCount", "Siguiendo")
            }

            // Edit Profile Button
            Button(
                onClick = { },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = VeneredSpacing.Large.dp),
                shape = RoundedCornerShape(VeneredCornerRadius.Medium.dp)
            ) {
                Text("Editar perfil")
            }

            Spacer(modifier = Modifier.height(VeneredSpacing.Large.dp))

            // Posts section title
            Text(
                text = "Posts",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = VeneredSpacing.Medium.dp)
            )

            // Posts placeholder
            repeat(3) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(VeneredSpacing.ExtraSmall.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    shape = RoundedCornerShape(VeneredCornerRadius.Medium.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(150.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("Post $it")
                    }
                }
            }
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
