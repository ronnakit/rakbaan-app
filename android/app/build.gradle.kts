plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rakbaan.rakbaan_page1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.rakbaan"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // 24 (Android 7.0) is the practical floor for on-device llama.cpp:
        // it needs a 64-bit ABI, and older/32-bit-only devices can't run a
        // 2B-parameter model at a usable speed anyway.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // Ship only arm64-v8a: it's what >95% of active Android devices
            // use, and it keeps the app size down (each ABI slice of the
            // native llama.cpp library is tens of MB on its own). Add more
            // ABIs here only if you have real users on them.
            abiFilters += listOf("arm64-v8a")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
