plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // FlutterFire Configuration
    id("com.google.gms.google-services")
    // Flutter Gradle Plugin must come last
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.foodviewer"
    compileSdk = flutter.compileSdkVersion

    // ✅ Fix: Kotlin DSL syntax for ndkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.foodviewer"
        // ✅ Firebase now requires minSdk 23 or higher
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            // Temporary signing config
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
