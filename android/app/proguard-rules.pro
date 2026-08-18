# ML Kit discovers its internal components (SharedPrefManager, etc.) by
# reflectively instantiating ComponentRegistrar classes. ML Kit's own consumer
# rule only keeps the class names; in R8 full mode the no-arg constructors get
# stripped, so discovery fails silently and text recognition NPEs at runtime.
-keepclassmembers class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}

# ML Kit text recognition ships optional per-script recognizer classes
# (Chinese/Devanagari/Japanese/Korean) that this app doesn't depend on.
# R8 can't resolve them, so silence the warnings rather than pulling in
# the unused script dependencies.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions