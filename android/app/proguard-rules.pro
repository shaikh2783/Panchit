# Add project-specific ProGuard rules here. Flutter automatically adds
# the necessary keep rules for most plugins, but you can extend this file
# whenever a plugin or your own code is incorrectly removed/obfuscated.

# Prevent Flutter framework classes from being stripped.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Keep any part of the app under your application ID from being stripped.
-keep class com.example.snginepro.** { *; }
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task