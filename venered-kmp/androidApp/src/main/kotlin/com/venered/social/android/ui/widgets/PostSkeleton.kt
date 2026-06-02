package com.venered.social.android.ui.widgets

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.venered.social.presentation.theme.VeneredCornerRadius
import com.venered.social.presentation.theme.VeneredSpacing

@Composable
fun ShimmerBrush(): Brush {
    val shimmerColors = listOf(
        Color.LightGray.copy(alpha = 0.6f),
        Color.LightGray.copy(alpha = 0.2f),
        Color.LightGray.copy(alpha = 0.6f),
    )

    val transition = rememberInfiniteTransition(label = "shimmer")
    val translateAnim = transition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmer"
    )

    return Brush.linearGradient(
        colors = shimmerColors,
        start = Offset.Zero,
        end = Offset(x = translateAnim.value, y = translateAnim.value)
    )
}

@Composable
fun PostSkeleton() {
    val brush = ShimmerBrush()
    
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(VeneredSpacing.Medium.dp)
            .clip(RoundedCornerShape(VeneredCornerRadius.Large.dp))
            .background(Color.White.copy(alpha = 0.05f))
            .padding(VeneredSpacing.Medium.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Spacer(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(brush)
            )
            Column(modifier = Modifier.padding(start = VeneredSpacing.Medium.dp)) {
                Spacer(
                    modifier = Modifier
                        .width(100.dp)
                        .height(14.dp)
                        .background(brush)
                )
                Spacer(modifier = Modifier.height(6.dp))
                Spacer(
                    modifier = Modifier
                        .width(60.dp)
                        .height(10.dp)
                        .background(brush)
                )
            }
        }
        
        Spacer(modifier = Modifier.height(VeneredSpacing.Medium.dp))
        
        Spacer(
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp)
                .clip(RoundedCornerShape(VeneredCornerRadius.Medium.dp))
                .background(brush)
        )
        
        Spacer(modifier = Modifier.height(VeneredSpacing.Medium.dp))
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(VeneredSpacing.Large.dp)
        ) {
            Spacer(modifier = Modifier.size(24.dp).background(brush))
            Spacer(modifier = Modifier.size(24.dp).background(brush))
            Spacer(modifier = Modifier.size(24.dp).background(brush))
        }
    }
}
