# Add any project-specific ProGuard rules here.
# Flutter's default rules already handle most cases, but
# this file can be used to keep classes/methods that would
# otherwise be removed if needed by reflection or plugins.

# Keep MainActivity
-keep class com.juanpiece.venered.MainActivity { *; }

# Keep Flutter and its classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }

# Fix for R8 Missing class errors related to Play Core
-dontwarn com.google.android.play.core.**

# Example:
# -keep class com.example.MyClass { *; }
