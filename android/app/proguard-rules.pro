# Flutter ProGuard Rules

# Add rules for Google ML Kit Text Recognition to ignore missing language models we don't use
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep ML Kit internals if needed
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.android.gms.**
