# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve all classes in the app package
-keep class com.nithiann.not_another_alarm_clock.** { *; }

# Preserve JavaScript interface methods
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Preserve Android Alarm Manager classes
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }

# Preserve notification classes
-keep class androidx.core.app.** { *; }

# Preserve serializable classes (used by alarm callbacks)
-keep class * implements java.io.Serializable { *; }

