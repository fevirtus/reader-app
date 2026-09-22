import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("kotlin-parcelize")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") apply false
}

// Opt-in side-by-side device test build; production identity/signing stay unchanged.
val integrationTarget = project.findProperty("target")?.toString()?.replace('\\', '/')
    ?.contains("integration_test/") == true
val deviceTestBuild = integrationTarget || System.getenv("READER_DEVICE_TEST") == "1"
if (!deviceTestBuild) apply(plugin = "com.google.gms.google-services")

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseStoreFile = keystoreProperties.getProperty("storeFile")
val hasReleaseSigning = !releaseStoreFile.isNullOrBlank()

android {
    namespace = "com.example.reader_app"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = if (deviceTestBuild) "dev.fevirtus.reader.test" else "dev.fevirtus.reader"
        manifestPlaceholders["readerAppLabel"] = if (deviceTestBuild) "Reader TTS Test" else "Virtus's Reader"
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
                storeFile = file(releaseStoreFile!!)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Use release keystore when available; fallback to debug for local dev builds.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    implementation("androidx.media:media:1.7.0")
}

flutter {
    source = "../.."
}
