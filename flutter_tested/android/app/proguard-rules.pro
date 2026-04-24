# Flutter-specific rules — keep all Flutter/Dart runtime classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Keep model classes used via JSON serialization
-keep class com.learno.** { *; }
