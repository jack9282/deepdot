# Flutter Local Notifications Proguard Rules
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.** { *; }
-keep class androidx.work.** { *; }

# Keep notification related classes
-keep class * extends androidx.core.app.NotificationCompat$Builder { *; }
-keep class * extends androidx.core.app.NotificationCompat$Action { *; }

# Keep timezone related classes
-keep class org.threeten.bp.** { *; }
-keep class org.threeten.bp.zone.** { *; }

# Keep alarm manager related classes
-keep class android.app.AlarmManager { *; }
-keep class android.app.PendingIntent { *; }

# Keep notification channel related classes
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationChannelGroup { *; }

# Keep notification manager related classes
-keep class android.app.NotificationManager { *; }
-keep class android.app.Notification { *; }

# Keep broadcast receiver related classes
-keep class * extends android.content.BroadcastReceiver { *; }

# Keep service related classes
-keep class * extends android.app.Service { *; }

# Keep intent related classes
-keep class android.content.Intent { *; }
-keep class android.content.IntentFilter { *; }

# Keep bundle related classes
-keep class android.os.Bundle { *; }

# Keep parcelable related classes
-keep class * implements android.os.Parcelable { *; }

# Keep serializable related classes
-keep class * implements java.io.Serializable { *; }

# Keep enum classes
-keep enum * { *; }

# Keep annotation classes
-keep @interface * { *; }

# Keep all classes in the flutter_local_notifications package
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep all classes in the timezone package
-keep class com.example.deepdot.** { *; }

# Google Error Prone Annotations
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }

# javax.lang.model (for annotations processing)
-dontwarn javax.lang.model.**
-keep class javax.lang.model.** { *; }
-keep class javax.lang.model.element.** { *; }

# Additional rules for common issues
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.Unsafe

# Keep Guava classes if used
-dontwarn com.google.common.**
-keep class com.google.common.** { *; }

# Keep annotation attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable 