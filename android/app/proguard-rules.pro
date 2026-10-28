# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }

# Suppress Play Store deferred components missing class warnings in R8
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep WebRTC
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Keep MediaPipe & Hand Landmarker
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Keep DeepAR
-keep class ai.deepar.** { *; }
-dontwarn ai.deepar.**

# Keep Socket.IO & Jackson
-keep class io.socket.** { *; }
-keep class org.json.** { *; }

# Keep Flutter Secure Storage
-keep class javax.crypto.** { *; }

# Prevent obfuscation of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
