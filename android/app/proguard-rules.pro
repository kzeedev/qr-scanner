# Keep ML Kit Barcode Scanning classes
-keep class com.google.mlkit.vision.barcode.** { *; }

# Keep common ML Kit and GMS internal classes
-keep class com.google.mlkit.common.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }

# Keep GMS (Google Play Services) internals used by ML Kit
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }

# Prevent R8 from warning about internal GMS and Play Store classes
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**

# Keep Mobile Scanner and CameraX internal classes
-keep class class.juliansteenbakker.mobile_scanner.** { *; }
-dontwarn class.juliansteenbakker.mobile_scanner.**
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**

# Flutter internal classes
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
