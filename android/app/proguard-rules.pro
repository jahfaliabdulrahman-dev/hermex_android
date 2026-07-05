# Hermex Android ProGuard/R8 Rules

# ─── Flutter ───
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.** { *; }

# ─── Dio / OkHttp ───
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# ─── JSON Serialization ───
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.hermex.android.** { *; }

# ─── Isar ───
-keep class io.isar.** { *; }
-keepclassmembers class * {
    @io.isar.annotations.** <fields>;
}

# ─── Flutter Secure Storage ───
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ─── Keep resource names for Flutter asset lookup ───
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ─── Google Play Core (deferred components — not used, suppress R8 warnings) ───
-dontwarn com.google.android.play.core.**

