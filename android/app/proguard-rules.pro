# =============================================================================
# R8 rules tuned for Play Console metrics:
#   Optimization % / Obfuscation % / Shrinking %
# Flutter apps stay modest (~15–30%) because most code is Dart native (.so),
# not DEX. These rules maximize what R8 can do on the Java/Kotlin side.
# =============================================================================

# Stronger renaming + access fixes (helps obfuscation & optimization %)
-allowaccessmodification
-repackageclasses
-overloadaggressively

# Keep attributes needed for reflection; do NOT keep whole SDKs
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*,Exceptions

# --- Flutter (minimal surface; plugins ship their own consumer rules) ---
-keep class io.flutter.embedding.android.FlutterActivity
-keep class io.flutter.embedding.android.FlutterFragmentActivity
-keep class io.flutter.embedding.android.FlutterActivityConfiguration
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.PathUtils { *; }
-dontwarn io.flutter.**

# Generated plugin registrant (reflection / class names)
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# App entry
-keep class com.deep.image.search.reverseimagesearch.facesearcher.MainActivity { *; }

# --- Let Google / Firebase / Billing use THEIR consumer ProGuard files ---
# Only dontwarn here so R8 can still shrink/obfuscate unused parts.
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
-dontwarn com.android.billingclient.**
-dontwarn com.google.android.play.core.**

# Keep AdMob classes that are loaded by class name from Flutter
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.ads.MobileAds { *; }

# Billing entry points used by in_app_purchase
-keep class com.android.billingclient.api.** { *; }

# Secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Play Core optional (in_app_update) — from missing_rules.txt
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
