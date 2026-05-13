# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dio / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Keep model classes for JSON serialization
-keep class com.hisobnoma.admin.** { *; }

# Prevent R8 from stripping interfaces
-keep,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Play Core (required for R8 with Flutter deferred components)
-dontwarn com.google.android.play.core.**
