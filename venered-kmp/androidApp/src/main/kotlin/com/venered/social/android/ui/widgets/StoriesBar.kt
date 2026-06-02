package com.venered.social.android.ui.widgets

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.venered.social.data.model.Story
import com.venered.social.presentation.theme.VeneredSpacing

@Composable
fun StoriesBar(
    stories: List<Story>,
    onStoryClick: (Story) -> Unit,
    onAddStoryClick: () -> Unit
) {
    // Agrupar historias por usuario (simplificado)
    val groupedStories = stories.groupBy { it.userId }.values.toList()

    LazyRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = VeneredSpacing.Small.dp),
        contentPadding = PaddingValues(horizontal = VeneredSpacing.Medium.dp),
        horizontalArrangement = Arrangement.spacedBy(VeneredSpacing.Medium.dp)
    ) {
        // Botón para añadir historia
        item {
            StoryCircle(
                username = "Tú",
                isMe = true,
                onTap = onAddStoryClick
            )
        }

        items(groupedStories) { userStories ->
            val firstStory = userStories.first()
            StoryCircle(
                username = firstStory.username,
                imageUrl = firstStory.avatarUrl,
                hasActiveStory = true,
                onTap = { onStoryClick(firstStory) }
            )
        }
    }
}

@Composable
fun StoryCircle(
    username: String,
    imageUrl: String? = null,
    isMe: Boolean = false,
    hasActiveStory: Boolean = false,
    onTap: () -> Unit
) {
    val storyGradient = Brush.linearGradient(
        colors = listOf(Color(0xFF6366F1), Color(0xFFEC4899))
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(70.dp).clickable { onTap() }
    ) {
        Box(
            modifier = Modifier
                .size(64.dp)
                .then(
                    if (hasActiveStory) {
                        Modifier.border(2.dp, storyGradient, CircleShape)
                    } else {
                        Modifier
                    }
                )
                .padding(3.dp)
        ) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                shape = CircleShape,
                color = MaterialTheme.colorScheme.surfaceVariant
            ) {
                if (imageUrl != null) {
                    AsyncImage(
                        model = imageUrl,
                        contentDescription = username,
                        modifier = Modifier.fillMaxSize().clip(CircleShape),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier.fillMaxSize()
                    ) {
                        Icon(
                            Icons.Default.Person,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                        )
                    }
                }
            }

            if (isMe) {
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .size(20.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary)
                        .border(2.dp, MaterialTheme.colorScheme.background, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.Add,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(12.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = username,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.fillMaxWidth()
        )
    }
}
