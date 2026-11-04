allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force Kotlin ≥ Flutter's minimum (2.2.20). Some plugins still ship 2.2.10.
extra["kotlin_version"] = "2.4.21"
subprojects {
    buildscript {
        configurations.classpath {
            resolutionStrategy.eachDependency {
                if (requested.group == "org.jetbrains.kotlin" &&
                    requested.name.startsWith("kotlin-gradle-plugin")) {
                    useVersion("2.4.21")
                    because("Flutter requires Kotlin ≥ 2.2.20")
                }
            }
        }
    }
    configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin" &&
                (requested.name.startsWith("kotlin-stdlib") ||
                    requested.name.startsWith("kotlin-reflect") ||
                    requested.name == "kotlin-gradle-plugin")) {
                useVersion("2.4.21")
                because("Align Kotlin with Flutter minimum")
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
// Play Billing Library 8.0.0 via in_app_purchase_android 0.5.3.
subprojects {
    configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.android.billingclient" &&
                requested.name == "billing") {
                useVersion("8.0.0")
                because("Pin Google Play Billing Library 8.0.0")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
