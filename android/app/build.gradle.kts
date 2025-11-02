import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("kotlin-parcelize")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
// Prefer environment variables for keystore values (safer for CI).
val envStoreFile = System.getenv("KEYSTORE_STORE_FILE")
val envStorePassword = System.getenv("KEYSTORE_STORE_PASSWORD")
val envKeyAlias = System.getenv("KEYSTORE_KEY_ALIAS")
val envKeyPassword = System.getenv("KEYSTORE_KEY_PASSWORD")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "th.ac.rmuttt.ct.homemadebliss"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Required by flutter_local_notifications (and other libs) for Java 8+ APIs on older Android
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "th.ac.rmuttt.ct.homemadebliss"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // First try environment variables (CI-friendly)
            if (!envStoreFile.isNullOrBlank()) {
                storeFile = file(envStoreFile)
                storePassword = envStorePassword
                keyAlias = envKeyAlias
                keyPassword = envKeyPassword
            } else if (keystorePropertiesFile.exists()) {
                // Fallback to local key.properties
                val storePath = keystoreProperties["storeFile"] as String?
                if (!storePath.isNullOrBlank()) {
                    storeFile = file(storePath)
                }
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    lint {
        // Lint can consume a lot of metaspace on CI; skip release lint during automated builds.
        checkReleaseBuilds = false
        abortOnError = false
    }

    dependencies {
        // Import the Firebase BoM
        implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
        // Core library desugaring support library
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
        // เพิ่ม Firebase services ที่ต้องการ เช่น :
        // implementation("com.google.firebase:firebase-analytics")
        // implementation("com.google.firebase:firebase-auth")
    }
}

flutter {
    source = "../.."
}
