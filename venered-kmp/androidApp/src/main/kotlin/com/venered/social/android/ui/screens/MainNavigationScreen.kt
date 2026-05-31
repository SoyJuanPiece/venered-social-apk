package com.venered.social.android.ui.screens

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController

@Composable
fun MainNavigationScreen(rootNavController: NavController, userId: String) {
    val bottomNavController = rememberNavController()
    val navBackStackEntry by bottomNavController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface,
                tonalElevation = 8.dp
            ) {
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
                    label = { Text("Inicio") },
                    selected = currentRoute == "home_inner",
                    onClick = {
                        if (currentRoute != "home_inner") {
                            bottomNavController.navigate("home_inner") {
                                popUpTo(bottomNavController.graph.startDestinationId)
                                launchSingleTop = true
                            }
                        }
                    }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Search, contentDescription = "Explore") },
                    label = { Text("Explorar") },
                    selected = currentRoute == "explore_inner",
                    onClick = {
                        if (currentRoute != "explore_inner") {
                            bottomNavController.navigate("explore_inner") {
                                popUpTo(bottomNavController.graph.startDestinationId)
                                launchSingleTop = true
                            }
                        }
                    }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Notifications, contentDescription = "Notifications") },
                    label = { Text("Notis") },
                    selected = currentRoute == "notifications_inner",
                    onClick = {
                        if (currentRoute != "notifications_inner") {
                            bottomNavController.navigate("notifications_inner") {
                                popUpTo(bottomNavController.graph.startDestinationId)
                                launchSingleTop = true
                            }
                        }
                    }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Email, contentDescription = "Messages") },
                    label = { Text("Mensajes") },
                    selected = currentRoute == "messages_inner",
                    onClick = {
                        if (currentRoute != "messages_inner") {
                            bottomNavController.navigate("messages_inner") {
                                popUpTo(bottomNavController.graph.startDestinationId)
                                launchSingleTop = true
                            }
                        }
                    }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Person, contentDescription = "Profile") },
                    label = { Text("Perfil") },
                    selected = currentRoute == "profile_inner",
                    onClick = {
                        if (currentRoute != "profile_inner") {
                            bottomNavController.navigate("profile_inner") {
                                popUpTo(bottomNavController.graph.startDestinationId)
                                launchSingleTop = true
                            }
                        }
                    }
                )
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = bottomNavController,
            startDestination = "home_inner",
            modifier = Modifier.padding(paddingValues)
        ) {
            composable("home_inner") {
                HomeScreen(rootNavController, userId)
            }
            composable("explore_inner") {
                ExploreScreen(rootNavController)
            }
            composable("notifications_inner") {
                NotificationsScreen(rootNavController, userId)
            }
            composable("messages_inner") {
                MessagesScreen(rootNavController, userId)
            }
            composable("profile_inner") {
                ProfileScreen(userId, rootNavController)
            }
        }
    }
}
