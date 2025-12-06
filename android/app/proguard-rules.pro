# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve alarm callback functions
-keep class com.nithiann.not_another_alarm_clock.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Preserve entry points for Android Alarm Manager
-keep @pragma('vm:entry-point') class * { *; }
-keepclassmembers @pragma('vm:entry-point') class * { *; }

# Preserve all classes with @pragma('vm:entry-point')
-keep @pragma('vm:entry-point') class * { *; }
-keepclassmembers @pragma('vm:entry-point') class * { *; }

# Preserve top-level functions used as callbacks
-keepclassmembers class * {
    @pragma('vm:entry-point') <methods>;
}

# Preserve AlarmService and related classes
-keep class com.nithiann.not_another_alarm_clock.** { *; }

# Preserve notification service callbacks
-keepclassmembers class * {
    @pragma('vm:entry-point') *;
}

