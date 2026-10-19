allprojects {
    repositories {
        google()
        mavenCentral()
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
// Do not force Billing Library 8 here: in_app_purchase_android 0.4.x targets 7.1.1.
// Forcing 8.0.0 breaks Java compile (QueryProductDetailsResult / queryPurchaseHistoryAsync).

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
