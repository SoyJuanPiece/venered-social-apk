package com.venered.social.presentation.theme

import androidx.compose.ui.graphics.Color

/**
 * Paleta de colores centralizada para toda la app
 * Se comparte entre Android e iOS
 */
object VeneredColors {
    // ============================================================
    // DARK THEME
    // ============================================================
    
    // Primario
    val DarkPrimary = Color(0xFF6366F1)              // Indigo vibrante
    val DarkPrimaryVariant = Color(0xFF4F46E5)      // Indigo oscuro
    
    // Secundario
    val DarkSecondary = Color(0xFFEC4899)            // Rosa vibrante
    val DarkSecondaryVariant = Color(0xFFDB2777)    // Rosa oscuro
    
    // Fondos
    val DarkBackground = Color(0xFF0A0A0A)           // Casi negro
    val DarkSurface = Color(0xFF171717)              // Gris muy oscuro
    val DarkSurfaceVariant = Color(0xFF1E1028)      // Gris con tinte morado
    
    // Textos
    val DarkTextPrimary = Color(0xFFFFFFFF)          // Blanco
    val DarkTextSecondary = Color(0xFFCACACB)        // Gris claro
    val DarkTextTertiary = Color(0xFF808080)        // Gris medio
    
    // Estados
    val DarkError = Color(0xFFFF6B6B)                // Rojo
    val DarkSuccess = Color(0xFF51CF66)              // Verde
    val DarkWarning = Color(0xFFFFA94D)              // Naranja
    
    // ============================================================
    // LIGHT THEME
    // ============================================================
    
    // Primario
    val LightPrimary = Color(0xFF4F46E5)             // Indigo
    val LightPrimaryVariant = Color(0xFF3730A3)     // Indigo oscuro
    
    // Secundario
    val LightSecondary = Color(0xFFEA580C)           // Naranja
    val LightSecondaryVariant = Color(0xFFD64A0A)   // Naranja oscuro
    
    // Fondos
    val LightBackground = Color(0xFFF5F8FF)          // Azul muy claro
    val LightSurface = Color(0xFFFFFFFF)             // Blanco
    val LightSurfaceVariant = Color(0xFFEEF2FF)     // Azul claro
    
    // Textos
    val LightTextPrimary = Color(0xFF0F172A)         // Casi negro
    val LightTextSecondary = Color(0xFF475569)       // Gris oscuro
    val LightTextTertiary = Color(0xFF94A3B8)       // Gris
    
    // Estados
    val LightError = Color(0xFFEF4444)               // Rojo
    val LightSuccess = Color(0xFF22C55E)             // Verde
    val LightWarning = Color(0xFFF59E0B)             // Naranja
    
    // ============================================================
    // NEUTRAL (Compartidos)
    // ============================================================
    
    val Transparent = Color(0x00000000)
    val Black = Color(0xFF000000)
    val White = Color(0xFFFFFFFF)
    
    // Bordes y divisores
    val DarkBorder = Color(0xFF2D2D2D)
    val LightBorder = Color(0xFFDCE5F6)
}

/**
 * Espaciado centralizado (dp values)
 */
object VeneredSpacing {
    const val ExtraSmall = 4          // 4.dp
    const val Small = 8               // 8.dp
    const val Medium = 12             // 12.dp
    const val Large = 16              // 16.dp
    const val ExtraLarge = 24         // 24.dp
    const val Huge = 32               // 32.dp
    const val Massive = 48            // 48.dp
}

/**
 * Tamaños de fuentes centralizados (sp)
 */
object VeneredTypography {
    // Display
    const val DisplayLargeSize = 48
    const val DisplayMediumSize = 40
    const val DisplaySmallSize = 32
    
    // Headline
    const val HeadlineLargeSize = 28
    const val HeadlineMediumSize = 24
    const val HeadlineSmallSize = 20
    
    // Title
    const val TitleLargeSize = 20
    const val TitleMediumSize = 16
    const val TitleSmallSize = 14
    
    // Body
    const val BodyLargeSize = 16
    const val BodyMediumSize = 14
    const val BodySmallSize = 12
    
    // Label
    const val LabelLargeSize = 14
    const val LabelMediumSize = 12
    const val LabelSmallSize = 11
}

/**
 * Radio de esquinas (border radius)
 */
object VeneredCornerRadius {
    const val ExtraSmall = 4
    const val Small = 8
    const val Medium = 12
    const val Large = 16
    const val ExtraLarge = 20
    const val Circle = 50  // Para elementos circulares
}

/**
 * Elevación (shadow depth)
 */
object VeneredElevation {
    const val None = 0
    const val Low = 2
    const val Medium = 4
    const val High = 8
    const val VeryHigh = 12
}

/**
 * Opacidades
 */
object VeneredOpacity {
    const val Disabled = 0.38f
    const val Hovered = 0.08f
    const val Focused = 0.12f
    const val Pressed = 0.12f
    const val DraggedAlpha = 0.16f
}

/**
 * Duraciones de animación (ms)
 */
object VeneredDuration {
    const val VeryShort = 100
    const val Short = 200
    const val Medium = 300
    const val Long = 500
    const val VeryLong = 1000
}
