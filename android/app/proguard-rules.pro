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

# Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keepattributes *Annotation*
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepclasseswithmembers class * {
    public void onPayment*(...);
}
-optimizations !method/inlining/*
# FFmpegKit — native code invokes Java callbacks via JNI by exact name.
# The ffmpeg_kit_flutter_new fork ships under com.antonkarpenko, not the
# original com.arthenica package; keep both.
-keep class com.arthenica.** { *; }
-dontwarn com.arthenica.**
-keep class com.antonkarpenko.** { *; }
-dontwarn com.antonkarpenko.**

# Agora RTC — JNI callbacks and reflection-instantiated handlers.
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# OneSignal — reflection-based initialization and notification handlers.
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**
