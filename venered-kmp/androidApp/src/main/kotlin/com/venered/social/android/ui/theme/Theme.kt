package com.venered.social.android.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.venered.social.presentation.theme.VeneredColors
import com.venered.social.presentation.theme.VeneredCornerRadius
import android.os.Build

private val DarkColorScheme = darkColorScheme(
    primary = VeneredColors.DarkPrimary,
    onPrimary = VeneredColors.DarkTextPrimary,
    primaryContainer = VeneredColors.DarkPrimaryVariant,
    onPrimaryContainer = VeneredColors.DarkTextPrimary,
    secondary = VeneredColors.DarkSecondary,
    onSecondary = VeneredColors.DarkTextPrimary,
    secondaryContainer = VeneredColors.DarkSecondaryVariant,
    onSecondaryContainer = VeneredColors.DarkTextPrimary,
    tertiary = VeneredColors.DarkPrimary,
    onTertiary = VeneredColors.DarkTextPrimary,
    background = VeneredColors.DarkBackground,
    onBackground = VeneredColors.DarkTextPrimary,
    surface = VeneredColors.DarkSurface,
    onSurface = VeneredColors.DarkTextPrimary,
    surfaceVariant = VeneredColors.DarkSurfaceVariant,
    onSurfaceVariant = VeneredColors.DarkTextSecondary,
    error = VeneredColors.DarkError,
    onError = VeneredColors.DarkTextPrimary,
    outline = VeneredColors.DarkBorder
)

private val LightColorScheme = lightColorScheme(
    primary = VeneredColors.LightPrimary,
    onPrimary = VeneredColors.LightTextPrimary,
    primaryContainer = VeneredColors.LightPrimaryVariant,
    onPrimaryContainer = VeneredColors.LightTextPrimary,
    secondary = VeneredColors.LightSecondary,
    onSecondary = VeneredColors.LightTextPrimary,
    secondaryContainer = VeneredColors.LightSecondaryVariant,
    onSecondaryContainer = VeneredColors.LightTextPrimary,
    tertiary = VeneredColors.LightPrimary,
    onTertiary = VeneredColors.LightTextPrimary,
    background = VeneredColors.LightBackground,
    onBackground = VeneredColors.LightTextPrimary,
    surface = VeneredColors.LightSurface,
    onSurface = VeneredColors.LightTextPrimary,
    surfaceVariant = VeneredColors.LightSurfaceVariant,
    onSurfaceVariant = VeneredColors.LightTextSecondary,
    error = VeneredColors.LightError,
    onError = VeneredColors.LightTextPrimary,
    outline = VeneredColors.LightBorder
)

@Composable
fun VeneredTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = androidx.compose.ui.platform.LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
