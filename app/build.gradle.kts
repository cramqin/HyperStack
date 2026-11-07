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
        versionCode = 2
        versionName = "0.0.2-beta"
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
    implementation("com.google.android.material:material:1.12.0")
}

// Align Kotlin stdlib. An old transitive kotlin-stdlib-jdk7/jdk8:1.6.21 clashes with
// kotlin-stdlib:1.8.22 (their classes merged into kotlin-stdlib in Kotlin 1.8), which
// produces "Duplicate class kotlin.*" errors. Pin everything to one version.
configurations.configureEach {
    resolutionStrategy {
        force(
            "org.jetbrains.kotlin:kotlin-stdlib:1.8.22",
            "org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.22",
            "org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22"
        )
    }
}
