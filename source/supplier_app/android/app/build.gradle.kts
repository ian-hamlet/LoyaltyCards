import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing config, kept out of git - see android/key.properties (gitignored) and
// docs/project-management/ANDROID_PORT_PLAN.md Phase 5. Falls back to debug signing when
// key.properties is absent (e.g. a fresh checkout without the keystore) so `flutter run` and
// CI builds that don't need a real release signature still work.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.loyaltycards.supplier_app"
    // flutter_secure_storage 11.0.0 requires compiling against SDK 37, higher
    // than Flutter's own default (flutter.compileSdkVersion) at this SDK
    // version - see https://flutter.dev/to/review-gradle-config.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Matches the iOS bundle ID's naming (com.ianhamlet.loyaltycards.supplierApp)
        // as closely as Android package-name convention (lowercase) allows.
        applicationId = "com.ianhamlet.loyaltycards.supplier"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // No key.properties present (e.g. a fresh checkout without the keystore) -
                // fall back to debug signing so `flutter run --release` still works locally.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
