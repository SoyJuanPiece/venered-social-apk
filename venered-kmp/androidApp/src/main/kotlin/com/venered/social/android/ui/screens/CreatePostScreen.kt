package com.venered.social.android.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.venered.social.presentation.theme.VeneredCornerRadius
import com.venered.social.presentation.theme.VeneredSpacing
import com.venered.social.presentation.viewmodel.PostViewModel
import com.venered.social.di.SharedComponent

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreatePostScreen(navController: NavController, userId: String) {
    val viewModel = remember { SharedComponent.providePostViewModel() }
    val state by viewModel.state.collectAsState()
    var content by remember { mutableStateOf("") }
    var selectedMediaUri by remember { mutableStateOf<Uri?>(null) }
    var isVideo by remember { mutableStateOf(false) }
    
    val context = LocalContext.current

    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            selectedMediaUri = it
            val mimeType = context.contentResolver.getType(it)
            isVideo = mimeType?.startsWith("video") == true
        }
    }

    LaunchedEffect(state.isSuccess) {
        if (state.isSuccess) {
            navController.popBackStack()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Crear Post", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.Close, contentDescription = "Cancelar")
                    }
                },
                actions = {
                    Button(
                        onClick = { 
                            if (selectedMediaUri != null) {
                                val bytes = context.contentResolver.openInputStream(selectedMediaUri!!)?.readBytes()
                                if (bytes != null) {
                                    val fileName = "upload_${System.currentTimeMillis()}.${if (isVideo) "mp4" else "jpg"}"
                                    viewModel.uploadMediaAndCreatePost(userId, content, bytes, fileName, isVideo)
                                }
                            } else {
                                viewModel.createPost(userId, content)
                            }
                        },
                        enabled = (content.isNotEmpty() || selectedMediaUri != null) && !state.isLoading,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary,
                            contentColor = MaterialTheme.colorScheme.onPrimary
                        ),
                        shape = RoundedCornerShape(VeneredCornerRadius.Medium.dp)
                    ) {
                        if (state.isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                color = MaterialTheme.colorScheme.onPrimary,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text("Publicar")
                        }
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(VeneredSpacing.Large.dp)
        ) {
            // Input de texto
            TextField(
                value = content,
                onValueChange = { content = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 100.dp),
                placeholder = { Text("¿Qué estás pensando?") },
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = Color.Transparent,
                    unfocusedContainerColor = Color.Transparent,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent
                )
            )
            
            // Preview de Multimedia
            selectedMediaUri?.let { uri ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(250.dp)
                        .padding(vertical = VeneredSpacing.Medium.dp)
                        .clip(RoundedCornerShape(VeneredCornerRadius.Large.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                ) {
                    if (isVideo) {
                        // Placeholder para video (usaríamos un player real o thumbnail en el futuro)
                        Column(
                            modifier = Modifier.fillMaxSize(),
                            verticalArrangement = Arrangement.Center,
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(Icons.Default.PlayCircle, contentDescription = null, size(48.dp))
                            Text("Video seleccionado", modifier = Modifier.padding(top = 8.dp))
                        }
                    } else {
                        AsyncImage(
                            model = uri,
                            contentDescription = "Preview",
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Crop
                        )
                    }
                    
                    IconButton(
                        onClick = { selectedMediaUri = null },
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(8.dp)
                            .background(Color.Black.copy(alpha = 0.5f), RoundedCornerShape(50))
                    ) {
                        Icon(Icons.Default.Close, contentDescription = "Quitar", tint = Color.White)
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Herramientas de multimedia
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = VeneredSpacing.Large.dp),
                tonalElevation = 2.dp,
                shape = RoundedCornerShape(VeneredCornerRadius.Medium.dp)
            ) {
                Row(
                    modifier = Modifier.padding(VeneredSpacing.Medium.dp),
                    horizontalArrangement = Arrangement.spacedBy(VeneredSpacing.Large.dp)
                ) {
                    IconButton(onClick = { launcher.launch("image/*") }) {
                        Icon(Icons.Default.PhotoLibrary, contentDescription = "Galería", tint = MaterialTheme.colorScheme.primary)
                    }
                    IconButton(onClick = { launcher.launch("video/*") }) {
                        Icon(Icons.Default.VideoLibrary, contentDescription = "Video", tint = MaterialTheme.colorScheme.primary)
                    }
                    IconButton(onClick = { /* Cámara - requiere más permisos */ }) {
                        Icon(Icons.Default.PhotoCamera, contentDescription = "Cámara")
                    }
                }
            }
            
            if (state.error != null) {
                Text(
                    text = state.error!!,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(top = 16.dp),
                    fontSize = 12.sp
                )
            }
        }
    }
}

private fun Modifier.size(size: androidx.compose.ui.unit.Dp) = this.size(size)
