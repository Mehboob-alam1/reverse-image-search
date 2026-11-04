pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // Plugins that still apply kotlin-android often pin 2.2.10; Flutter requires ≥2.2.20.
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id.startsWith("org.jetbrains.kotlin.")) {
                useVersion("2.4.21")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Cap at 8.13.0 — current Android Studio rejects AGP 9.x.
    id("com.android.application") version "8.13.0" apply false
    // Pin KGP for plugins that still apply kotlin-android (Flutter min 2.2.20).
    id("org.jetbrains.kotlin.android") version "2.4.21" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
