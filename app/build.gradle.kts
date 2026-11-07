plugins {
    id("com.android.application")
}

android {
    namespace = "dev.hyperstack"
    compileSdk = 35

    defaultConfig {
        applicationId = "dev.hyperstack"
        minSdk = 29
        targetSdk = 35
        versionCode = 1
        versionName = "0.0.1-beta"
    }

    signingConfigs {
        create("release") {
            val ks = System.getenv("KEYSTORE_FILE")
            if (!ks.isNullOrEmpty() && file(ks).exists()) {
                storeFile = file(ks)
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            val ks = System.getenv("KEYSTORE_FILE")
            signingConfig = if (!ks.isNullOrEmpty() && file(ks).exists()) {
                signingConfigs.getByName("release")
            } else {
                // No signing secrets present (e.g. local build): fall back to debug key
                // so the APK is still installable.
                signingConfigs.getByName("debug")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
}
