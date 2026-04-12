# proguard-rules.pro
# Keep AdMob classes
-keep class com.google.android.gms.ads.** { *; }
# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
