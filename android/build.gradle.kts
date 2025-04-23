allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

configurations.all {
    resolutionStrategy {
        force("androidx.core:core-ktx:1.6.0")
    }
}

subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") ||
            plugins.hasPlugin("com.android.library")) {
            configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(34)
                buildToolsVersion = "34.0.0"
                ndkVersion = "27.0.12077973"

                defaultConfig {
                    targetSdkVersion(34)
                    minSdkVersion(21)
                }

                buildTypes {
                    getByName("release") {
                        proguardFiles(
                            getDefaultProguardFile("proguard-android-optimize.txt"),
                            "proguard-rules.pro"
                        )
                    }
                }
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
