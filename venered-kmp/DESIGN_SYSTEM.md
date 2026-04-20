# Venered Design System

## Overview

The Venered Design System provides a centralized, unified design language across all platforms (Android, iOS, Web) using **Kotlin Multiplatform** (KMP). All design tokens are defined in the shared module and referenced by platform-specific implementations.

## Architecture

```
venered-kmp/
├── shared/
│   └── src/commonMain/kotlin/
│       └── com/venered/social/
│           └── presentation/
│               └── theme/
│                   └── VeneredTheme.kt (Single Source of Truth)
├── androidApp/
│   └── src/main/kotlin/
│       └── com/venered/social/android/
│           ├── ui/theme/
│           │   └── Theme.kt (Uses VeneredColors)
│           └── ui/screens/ (Use VeneredSpacing, VeneredCornerRadius)
└── iosApp/
    └── VeneredTheme.swift (Mirrored values from Kotlin)
```

## Color System

### Dark Theme Colors
- **Primary**: `#6366F1` (Indigo)
- **Secondary**: `#EC4899` (Rose/Pink)
- **Background**: `#0F172A` (Almost Black)
- **Surface**: `#1E293B` (Dark Slate)
- **Text/OnBackground**: `#F1F5F9` (Off White)

### Light Theme Colors
- **Primary**: `#4F46E5` (Indigo - Darker)
- **Secondary**: `#EA580C` (Orange)
- **Background**: `#F8FAFC` (Light Gray)
- **Surface**: `#FFFFFF` (White)
- **Text/OnBackground**: `#0F172A` (Dark Gray/Black)

### Usage

**Android (Compose)**:
```kotlin
import com.venered.social.presentation.theme.VeneredColors

Card(
    colors = CardDefaults.cardColors(
        containerColor = VeneredColors.DarkSurface // Auto-adjusts based on theme
    )
) {
    // Content
}
```

**iOS (SwiftUI)**:
```swift
import SwiftUI

VStack {
    Text("Hello")
        .foregroundColor(VeneredColors.darkPrimary)
}
.background(VeneredColors.darkBackground)
```

## Spacing System

All spacing uses a consistent scale in **dp (density-independent pixels)**:

| Token | Value | Use Case |
|-------|-------|----------|
| `ExtraSmall` | 4 dp | Minimal gaps, icon spacing |
| `Small` | 8 dp | Item padding, small gaps |
| `Medium` | 12 dp | Standard padding, moderate gaps |
| `Large` | 16 dp | Card padding, section spacing |
| `ExtraLarge` | 20 dp | Major spacing, top sections |
| `XLarge` | 24 dp | Large sections, main padding |
| `Massive` | 32 dp | Page padding, large gaps |

### Usage

**Android (Compose)**:
```kotlin
import com.venered.social.presentation.theme.VeneredSpacing

Card(
    modifier = Modifier.padding(VeneredSpacing.Medium.dp)
) {
    Column(
        modifier = Modifier.padding(VeneredSpacing.Large.dp),
        verticalArrangement = Arrangement.spacedBy(VeneredSpacing.Small.dp)
    ) {
        // Content
    }
}
```

**iOS (SwiftUI)**:
```swift
VStack(spacing: CGFloat(VeneredSpacing.medium)) {
    Text("Item 1")
    Text("Item 2")
}
.padding(CGFloat(VeneredSpacing.large))
```

## Corner Radius System

Consistent border radius values for cards, buttons, and text fields:

| Token | Value | Use Case |
|-------|-------|----------|
| `Small` | 8 dp | Small components |
| `Medium` | 12 dp | Buttons, chips |
| `Large` | 16 dp | Cards, modals |
| `ExtraLarge` | 20 dp | Large containers |
| `Circle` | 50 dp | Avatars, circles |
| `None` | 0 dp | Sharp corners (rare) |

### Usage

**Android (Compose)**:
```kotlin
import com.venered.social.presentation.theme.VeneredCornerRadius

Card(
    shape = RoundedCornerShape(VeneredCornerRadius.Large.dp)
) {
    // Content
}
```

**iOS (SwiftUI)**:
```swift
VStack()
    .background(Color.white)
    .cornerRadius(CGFloat(VeneredCornerRadius.large))
```

## Typography System

Font sizes and styles for consistent hierarchy:

| Token | Size | Use Case |
|-------|------|----------|
| `Display` | 32 sp | App title, main headers |
| `Headline` | 24 sp | Section titles |
| `Title` | 20 sp | Card titles, subtitles |
| `Body` | 14 sp | Main content, paragraphs |
| `Label` | 12 sp | Captions, metadata |
| `Caption` | 11 sp | Timestamps, small text |

### Usage

**Android (Compose)**:
```kotlin
Text(
    text = "Welcome",
    style = MaterialTheme.typography.displayLarge // or custom size
)
```

**iOS (SwiftUI)**:
```swift
Text("Welcome")
    .font(.system(size: CGFloat(VeneredTypography.display)))
```

## Elevation System

Shadow/elevation values for depth:

| Token | Elevation Value | Use Case |
|-------|-----------------|----------|
| `Level1` | 2 dp | Subtle shadows |
| `Level2` | 4 dp | Standard cards |
| `Level3` | 6 dp | Prominent cards |
| `Level4` | 8 dp | Modals, dialogs |
| `Level5` | 12 dp | Top-level overlays |

### Usage

**Android (Compose)**:
```kotlin
Card(
    elevation = CardDefaults.cardElevation(
        defaultElevation = VeneredElevation.Level2.dp
    )
) {
    // Content
}
```

## Opacity and Animation

### Opacity Constants
- **Full**: 1.0 (100% opaque)
- **High**: 0.87 (87% opaque - primary content)
- **Medium**: 0.60 (60% opaque - secondary content)
- **Low**: 0.38 (38% opaque - disabled/hint text)
- **Minimum**: 0.12 (12% opaque - scrim/very faded)

### Animation Durations
- **Short**: 150 ms (quick interactions)
- **Medium**: 300 ms (standard transitions)
- **Long**: 500 ms (complex animations)
- **VeryLong**: 1000 ms (special effects)

## Implementation Guidelines

### Mandatory Rules
1. **NEVER hardcode** spacing, colors, or corner radius values
2. **Always import** from centralized theme modules
3. **Use constants** from `VeneredSpacing`, `VeneredColors`, `VeneredCornerRadius`
4. **Test both themes**: Dark and Light mode must look identical in structure

### Best Practices
1. **Consistency**: Use spacing increments in multiples (8, 12, 16, 20, etc.)
2. **Hierarchy**: Use different spacing to show content importance
3. **Density**: Mobile (tight spacing) vs Tablet (generous spacing) - adjust at that layer
4. **Accessibility**: Ensure minimum touch targets of 48 dp
5. **Responsive**: Use weights and flexibility, not fixed sizes

## Migration from Flutter

### Before (Flutter - Local Colors)
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.indigo,
    borderRadius: BorderRadius.circular(12)
  ),
  child: Text('Button')
)
```

### After (KMP - Centralized Theme)

**Android**:
```kotlin
Card(
    modifier = Modifier.padding(VeneredSpacing.Large.dp),
    shape = RoundedCornerShape(VeneredCornerRadius.Medium.dp),
    colors = CardDefaults.cardColors(
        containerColor = MaterialTheme.colorScheme.primary // From VeneredColors
    )
) {
    Text("Button")
}
```

**iOS**:
```swift
VStack {
    Text("Button")
}
.padding(CGFloat(VeneredSpacing.large))
.background(VeneredColors.darkPrimary)
.cornerRadius(CGFloat(VeneredCornerRadius.medium))
```

## Platform-Specific Overrides

### When to Override
- **Never** override base design tokens
- Platform-specific **implementations** are OK (e.g., `Material3` semantics on Android)
- **Density adjustments** are OK (e.g., extra spacing on tablet)

### Incorrect Override
```kotlin
// ❌ DON'T do this
Card(
    modifier = Modifier.padding(15.dp), // Custom value!
    shape = RoundedCornerShape(13.dp)   // Custom value!
)
```

### Correct Usage
```kotlin
// ✅ DO this
Card(
    modifier = Modifier.padding(VeneredSpacing.Large.dp),
    shape = RoundedCornerShape(VeneredCornerRadius.Medium.dp)
)
```

## Checking Consistency

### Code Review Checklist
- [ ] All colors from `VeneredColors`?
- [ ] All spacing from `VeneredSpacing`?
- [ ] All corner radius from `VeneredCornerRadius`?
- [ ] Respects theme (dark/light)?
- [ ] No hardcoded dp/sp values in UI?
- [ ] Accessibility (48 dp min touch target)?

## File Locations

- **Shared Theme**: `shared/src/commonMain/kotlin/.../presentation/theme/VeneredTheme.kt`
- **Android Theme**: `androidApp/src/main/kotlin/.../android/ui/theme/Theme.kt`
- **iOS Theme**: `iosApp/VeneredTheme.swift`
- **Documentation**: This file (`DESIGN_SYSTEM.md`)

## Future Enhancements

- [ ] Create Figma components library
- [ ] Add animation guidelines document
- [ ] Implement dark/light mode switcher
- [ ] Create design tokens JSON export for web
- [ ] Add accessibility contrast validation
- [ ] Create component showcase app

---

**Last Updated**: 2024
**Version**: 1.0.0
**Maintained By**: Venered Design Team
