# Google ML Kit — optional script modules (Chinese/Japanese/Korean/Devanagari) are not bundled;
# receipt OCR uses Latin only. Required for release R8 minification.
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }
