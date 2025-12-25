import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

android {
    namespace = "com.example.snginepro"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.panchit.www"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24  // OneSignal requires minSdk 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // ✅ زيادة Heap Memory للتعامل مع الفيديوهات الكبيرة
        multiDexEnabled = true
        dexOptions {
            javaMaxHeapSize = "4g"
        }
    }

    signingConfigs {
        create("customKey") {
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.getProperty("storeFile")?.takeIf { it.isNotBlank() }?.let {
                    storeFile = file(it)
                }
                keystoreProperties.getProperty("storePassword")?.takeIf { it.isNotBlank() }?.let {
                    storePassword = it
                }
                keystoreProperties.getProperty("keyAlias")?.takeIf { it.isNotBlank() }?.let {
                    keyAlias = it
                }
                keystoreProperties.getProperty("keyPassword")?.takeIf { it.isNotBlank() }?.let {
                    keyPassword = it
                }
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("customKey")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("customKey")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
        }
    }
}

dependencies {
    // For Flutter deferred components / dynamic features
    implementation("com.google.android.play:feature-delivery:2.1.0")
    implementation("com.google.android.play:feature-delivery-ktx:2.1.0")
    implementation("com.google.android.gms:play-services-tasks:18.2.0")
}



flutter {
    source = "../.."
}
