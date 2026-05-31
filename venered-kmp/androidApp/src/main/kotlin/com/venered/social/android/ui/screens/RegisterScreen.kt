package com.venered.social.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.venered.social.presentation.theme.VeneredCornerRadius
import com.venered.social.presentation.theme.VeneredSpacing
import com.venered.social.presentation.viewmodel.AuthViewModel
import com.venered.social.di.SharedComponent

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff

@Composable
fun RegisterScreen(navController: NavController, onRegisterSuccess: (String) -> Unit) {
    val viewModel = remember { SharedComponent.provideAuthViewModel() }
    val state by viewModel.state.collectAsState()

    var email by remember { mutableStateOf("") }
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }

    LaunchedEffect(state.authResponse) {
        state.authResponse?.let { response ->
            response.user?.id?.let { userId ->
                onRegisterSuccess(userId)
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(VeneredSpacing.Large.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Título
        Text(
            text = "Crear Cuenta",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(bottom = VeneredSpacing.ExtraLarge.dp)
        )

        // Username Input
        OutlinedTextField(
            value = username,
            onValueChange = { username = it },
            label = { Text("Nombre de usuario") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = VeneredSpacing.ExtraSmall.dp),
            singleLine = true,
            shape = RoundedCornerShape(VeneredCornerRadius.Large.dp)
        )

        // Email Input
        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Email") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = VeneredSpacing.ExtraSmall.dp),
            singleLine = true,
            shape = RoundedCornerShape(VeneredCornerRadius.Large.dp)
        )

        // Password Input
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Contraseña") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = VeneredSpacing.ExtraSmall.dp),
            singleLine = true,
            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            shape = RoundedCornerShape(VeneredCornerRadius.Large.dp),
            trailingIcon = {
                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                    Icon(
                        imageVector = if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                        contentDescription = if (passwordVisible) "Ocultar" else "Ver"
                    )
                }
            }
        )

        // Error Message
        state.error?.let {
            Text(
                text = it,
                color = MaterialTheme.colorScheme.error,
                fontSize = 12.sp,
                modifier = Modifier
                    .padding(vertical = VeneredSpacing.ExtraSmall.dp)
                    .align(Alignment.Start)
            )
        }

        // Register Button
        Button(
            onClick = {
                if (email.isNotEmpty() && password.isNotEmpty() && username.isNotEmpty()) {
                    viewModel.register(email, password, username)
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = VeneredSpacing.Medium.dp)
                .height(50.dp),
            enabled = !state.isLoading
        ) {
            if (state.isLoading) {
                CircularProgressIndicator(modifier = Modifier.size(20.dp), color = MaterialTheme.colorScheme.onPrimary)
            } else {
                Text("Registrarse")
            }
        }

        // Login link
        Row(modifier = Modifier.padding(top = VeneredSpacing.Medium.dp)) {
            Text("¿Ya tienes cuenta? ")
            TextButton(
                onClick = { navController.popBackStack() },
                modifier = Modifier.padding(start = 0.dp),
                contentPadding = PaddingValues(0.dp)
            ) {
                Text(
                    text = "Inicia sesión",
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
