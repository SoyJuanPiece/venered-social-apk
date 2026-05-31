package com.venered.social.presentation.theme

import androidx.compose.ui.graphics.Color

/**
 * Paleta de colores centralizada para toda la app (Android)
 */
object VeneredColors {
    // DARK THEME
    val DarkPrimary = Color(0xFF6366F1)
    val DarkPrimaryVariant = Color(0xFF4F46E5)
    val DarkSecondary = Color(0xFFEC4899)
    val DarkSecondaryVariant = Color(0xFFDB2777)
    val DarkBackground = Color(0xFF0A0A0A)
    val DarkSurface = Color(0xFF171717)
    val DarkSurfaceVariant = Color(0xFF1E1028)
    val DarkTextPrimary = Color(0xFFFFFFFF)
    val DarkTextSecondary = Color(0xFFCACACB)
    val DarkTextTertiary = Color(0xFF808080)
    val DarkError = Color(0xFFFF6B6B)
    val DarkSuccess = Color(0xFF51CF66)
    val DarkWarning = Color(0xFFFFA94D)

    // LIGHT THEME
    val LightPrimary = Color(0xFF4F46E5)
    val LightPrimaryVariant = Color(0xFF3730A3)
    val LightSecondary = Color(0xFFEA580C)
    val LightSecondaryVariant = Color(0xFFD64A0A)
    val LightBackground = Color(0xFFF5F8FF)
    val LightSurface = Color(0xFFFFFFFF)
    val LightSurfaceVariant = Color(0xFFEEF2FF)
    val LightTextPrimary = Color(0xFF0F172A)
    val LightTextSecondary = Color(0xFF475569)
    val LightTextTertiary = Color(0xFF94A3B8)
    val LightError = Color(0xFFEF4444)
    val LightSuccess = Color(0xFF22C55E)
    val LightWarning = Color(0xFFF59E0B)

    // NEUTRAL
    val Transparent = Color(0x00000000)
    val Black = Color(0xFF000000)
    val White = Color(0xFFFFFFFF)
    val DarkBorder = Color(0xFF2D2D2D)
    val LightBorder = Color(0xFFDCE5F6)
}

object VeneredSpacing {
    const val ExtraSmall = 4
    const val Small = 8
    const val Medium = 12
    const val Large = 16
    const val ExtraLarge = 24
    const val Huge = 32
    const val Massive = 48
}

object VeneredCornerRadius {
    const val ExtraSmall = 4
    const val Small = 8
    const val Medium = 12
    const val Large = 16
    const val ExtraLarge = 20
    const val Circle = 50
}
