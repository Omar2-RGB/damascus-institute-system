plugins {
    id("com.android.application")
    id("kotlin-android") // <--- هاد السطر هو اللي كان ناقص وعم يعمل المشكلة!
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.damascus_institute"
    compileSdk = 36 // الإصدار الجديد
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId = "com.example.damascus_institute"
        minSdk = 21
        targetSdk = 36 // الإصدار الجديد
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}