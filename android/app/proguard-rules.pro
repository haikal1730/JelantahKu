# JelantahKu release rules.
# Keep only metadata commonly needed by JSON/reflective Android libraries.
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn javax.annotation.**
-dontwarn org.jetbrains.annotations.**
