plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter plugin must be applied after Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Firebase
}

android {
    namespace = "com.coinnewsextratv.cnetv"
    compileSdk = 36 // Updated for google_sign_in_android compatibility

    defaultConfig {
        applicationId = "com.coinnewsextratv.cnetv" // ✅ Match Firebase package
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 32
        versionName = "2.1.0"

        // Enable split APKs per ABI
        ndk {
            abiFilters += setOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // TODO: replace with your real keystore before publishing
            signingConfig = signingConfigs.getByName("debug")

            // Enable code shrinking & resource shrinking
            isMinifyEnabled = true         // Shrinks code using R8
            isShrinkResources = true       // Removes unused resources
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Suppress obsolete options warning in Kotlin DSL
tasks.withType<JavaCompile> {
    options.compilerArgs.add("-Xlint:-options")
}
