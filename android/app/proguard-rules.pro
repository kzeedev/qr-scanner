# Flutter internal classes
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# CameraX classes (used by flutter_zxing via camera package)
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**
