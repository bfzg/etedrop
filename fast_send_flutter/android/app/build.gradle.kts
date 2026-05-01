import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

// Android 无法从 filesDir 可靠 exec 自解压的 ffmpeg；随 jniLibs 安装到 nativeLibraryDir。
// 源文件在仓库 assets/ffmpeg/android/。必须落在 app/src/main/jniLibs/<abi>/（默认 sourceSet），
// 仅指向 build/generated 时部分 Flutter/AGP 合并链路可能打不进 APK，运行时 nativeLibraryDir 缺文件。
val ffmpegAndroidSrc = rootProject.file("../assets/ffmpeg/android")
val ffmpegJniArm64Out = layout.projectDirectory.dir("src/main/jniLibs/arm64-v8a")
val copyFfmpegAndroidJniLibs = tasks.register<Copy>("copyFfmpegAndroidJniLibs") {
    onlyIf { ffmpegAndroidSrc.exists() }
    from(ffmpegAndroidSrc) {
        include("ffmpeg")
        rename { "libffmpeg_etedrop.so" }
    }
    from(ffmpegAndroidSrc) {
        include("ffprobe")
        rename { "libffprobe_etedrop.so" }
    }
    into(ffmpegJniArm64Out)
}

tasks.configureEach {
    val n = name
    if (n.startsWith("merge") && n.endsWith("JniLibFolders")) {
        dependsOn(copyFfmpegAndroidJniLibs)
    }
}

android {
    // TODO 这里修改成自己的
    namespace = "cn.etedrop.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Required by flutter_local_notifications (and some other plugins) on Android.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "cn.etedrop.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties 存在时使用正式签名，不存在则回退 debug（仅限本地测试）。
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Java 8+ APIs desugaring for older Android versions.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
