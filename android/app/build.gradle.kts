plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter plugin must be applied after Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Firebase
}

android {
    namespace = "com.coinnewsextra.tv"
    compileSdk = 36 // Updated for google_sign_in_android compatibility

    defaultConfig {
        applicationId = "com.coinnewsextra.tv" // ✅ Match Firebase package
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            // TODO: replace with your real keystore before publishing
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
