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
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.foodviewer"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Java 17 + desugaring support
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // ✅ Add this line for desugaring support
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // You can keep other dependencies Flutter adds automatically
}

flutter {
    source = "../.."
}
