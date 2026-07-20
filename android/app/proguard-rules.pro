# Flutter internal classes
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Prevent R8 from warning about internal GMS and Play Store classes
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**

# CameraX classes (used by flutter_zxing via camera package)
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**
