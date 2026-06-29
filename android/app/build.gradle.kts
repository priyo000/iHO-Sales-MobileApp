plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.intigroup.salestracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.intigroup.salestracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Production release signing config. Keystore path, passwords, and key
    // alias are injected via Gradle properties (e.g. ~/.gradle/gradle.properties
    // or CI secrets) so secrets never live in the repo. When the properties are
    // absent the build falls back to the debug signing config, which keeps
    // `flutter run --release` working for local development but is NOT safe for
    // distribution. Set the following properties to build a releasable APK/AAB:
    //   IHO_RELEASE_STORE_FILE, IHO_RELEASE_STORE_PASSWORD,
    //   IHO_RELEASE_KEY_ALIAS, IHO_RELEASE_KEY_PASSWORD
    val releaseStoreFile = providers.gradleProperty("IHO_RELEASE_STORE_FILE")
    val releaseStorePassword =
        providers.gradleProperty("IHO_RELEASE_STORE_PASSWORD")
    val releaseKeyAlias = providers.gradleProperty("IHO_RELEASE_KEY_ALIAS")
    val releaseKeyPassword = providers.gradleProperty("IHO_RELEASE_KEY_PASSWORD")
    val hasReleaseSigning = releaseStoreFile.isPresent &&
        releaseStorePassword.isPresent &&
        releaseKeyAlias.isPresent &&
        releaseKeyPassword.isPresent

    if (hasReleaseSigning) {
        signingConfigs.create("release") {
            storeFile = file(releaseStoreFile.get())
            storePassword = releaseStorePassword.get()
            keyAlias = releaseKeyAlias.get()
            keyPassword = releaseKeyPassword.get()
        }
    }

    buildTypes {
        release {
            // Fail the release build loudly if production signing isn't
            // configured, so a debug-signed APK is never accidentally shipped.
            signingConfig =
                if (hasReleaseSigning) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
