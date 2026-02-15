plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.koogwz_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.koogwz_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ✅ OPTIMISATION : Réduction de la taille de l'APK
            minifyEnabled = true
            shrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Signing avec debug key (à remplacer en production)
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ✅ SPLIT APK : Créer un APK par architecture (réduit drastiquement la taille)
    splits {
        abi {
            enable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            universalApk = false
        }
    }
}

flutter {
    source = "../.."
}