plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// YOLO uses LiteRT 2.x while tflite_flutter's FFI bindings still open the
// legacy libtensorflowlite_jni.so name. Keep LiteRT 2.x as the Java runtime,
// exclude the old GPU artifact, and package only the required 1.4 JNI binary.
configurations.configureEach {
    exclude(group = "com.google.ai.edge.litert", module = "litert-gpu")
}

val legacyLiteRtNative by configurations.creating
val extractLegacyLiteRtNative by tasks.registering(Copy::class) {
    from({ legacyLiteRtNative.files.map { archive -> zipTree(archive) } })
    include("jni/**/libtensorflowlite_jni.so")
    eachFile { path = path.removePrefix("jni/") }
    includeEmptyDirs = false
    into(layout.buildDirectory.dir("generated/legacyLiteRt/jniLibs"))
}

android {
    namespace = "com.example.skincare_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Cấu hình bắt buộc cho thư viện thông báo
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.skincare_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Cấu hình bắt buộc cho thư viện lớn
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    sourceSets.getByName("main").jniLibs.srcDir(
        layout.buildDirectory.dir("generated/legacyLiteRt/jniLibs")
    )
}

flutter {
    source = "../.."
}

dependencies {
    // Thư viện hỗ trợ desugaring cho Android
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    legacyLiteRtNative("com.google.ai.edge.litert:litert:1.4.0@aar")
}

tasks.matching {
    it.name.startsWith("merge") &&
        (it.name.endsWith("NativeLibs") || it.name.endsWith("JniLibFolders"))
}.configureEach {
    dependsOn(extractLegacyLiteRtNative)
}
