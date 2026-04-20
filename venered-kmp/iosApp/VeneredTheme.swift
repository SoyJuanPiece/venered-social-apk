import SwiftUI

// COLORS - Sincronizados con Kotlin
struct VeneredColors {
    // DARK THEME
    static let darkPrimary = Color(red: 0.38, green: 0.40, blue: 0.95)        // #6366F1
    static let darkSecondary = Color(red: 0.92, green: 0.28, blue: 0.60)      // #EC4899
    static let darkBackground = Color(red: 0.04, green: 0.04, blue: 0.04)     // #0A0A0A
    static let darkSurface = Color(red: 0.09, green: 0.09, blue: 0.09)        // #171717
    static let darkTextPrimary = Color(red: 1.0, green: 1.0, blue: 1.0)       // #FFFFFF
    static let darkTextSecondary = Color(red: 0.79, green: 0.79, blue: 0.80)  // #CACACA
    static let darkError = Color(red: 1.0, green: 0.42, blue: 0.42)           // #FF6B6B
    
    // LIGHT THEME
    static let lightPrimary = Color(red: 0.31, green: 0.27, blue: 0.90)       // #4F46E5
    static let lightSecondary = Color(red: 0.92, green: 0.34, blue: 0.05)     // #EA580C
    static let lightBackground = Color(red: 0.96, green: 0.97, blue: 1.0)     // #F5F8FF
    static let lightSurface = Color(red: 1.0, green: 1.0, blue: 1.0)          // #FFFFFF
    static let lightTextPrimary = Color(red: 0.06, green: 0.09, blue: 0.16)   // #0F172A
    static let lightTextSecondary = Color(red: 0.28, green: 0.33, blue: 0.41) // #475569
    static let lightError = Color(red: 0.94, green: 0.27, blue: 0.27)         // #EF4444
}

// SPACING - Sincronizado con Kotlin
struct VeneredSpacing {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
    static let huge: CGFloat = 32
    static let massive: CGFloat = 48
}

// TYPOGRAPHY - Sincronizado con Kotlin
struct VeneredTypography {
    static let displayLargeSize: CGFloat = 48
    static let displayMediumSize: CGFloat = 40
    static let displaySmallSize: CGFloat = 32
    
    static let headlineLargeSize: CGFloat = 28
    static let headlineMediumSize: CGFloat = 24
    static let headlineSmallSize: CGFloat = 20
    
    static let titleLargeSize: CGFloat = 20
    static let titleMediumSize: CGFloat = 16
    static let titleSmallSize: CGFloat = 14
    
    static let bodyLargeSize: CGFloat = 16
    static let bodyMediumSize: CGFloat = 14
    static let bodySmallSize: CGFloat = 12
    
    static let labelLargeSize: CGFloat = 14
    static let labelMediumSize: CGFloat = 12
    static let labelSmallSize: CGFloat = 11
}

// CORNER RADIUS - Sincronizado con Kotlin
struct VeneredCornerRadius {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
    static let circle: CGFloat = 50
}

// THEME MANAGER
struct VeneredTheme {
    @Environment(\.colorScheme) var colorScheme
    
    func getPrimaryColor() -> Color {
        colorScheme == .dark ? VeneredColors.darkPrimary : VeneredColors.lightPrimary
    }
    
    func getSecondaryColor() -> Color {
        colorScheme == .dark ? VeneredColors.darkSecondary : VeneredColors.lightSecondary
    }
    
    func getBackgroundColor() -> Color {
        colorScheme == .dark ? VeneredColors.darkBackground : VeneredColors.lightBackground
    }
    
    func getSurfaceColor() -> Color {
        colorScheme == .dark ? VeneredColors.darkSurface : VeneredColors.lightSurface
    }
    
    func getTextPrimaryColor() -> Color {
        colorScheme == .dark ? VeneredColors.darkTextPrimary : VeneredColors.lightTextPrimary
    }
    
    func getTextSecondaryColor() -> Color {
        colorScheme == .dark ? VeneredColors.darkTextSecondary : VeneredColors.lightTextSecondary
    }
    
    func getErrorColor() -> Color {
        colorScheme == .dark ? VeneredColors.darkError : VeneredColors.lightError
    }
}
