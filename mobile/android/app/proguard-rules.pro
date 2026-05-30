 # Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Razorpay
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-dontwarn com.razorpay.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
