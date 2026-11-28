# 构建配置模板

本文件提供完整的构建配置模板，确保你的项目能够正确编译和运行 Backdrop 2.0.0 液态玻璃效果。

> **版本基线**（与官方 kmp 分支 libs.versions.toml 对齐，2026-08 实测）：
> AGP 9.3.0 / Kotlin 2.4.10 / Compose Multiplatform 1.11.1 / shapes 1.2.0 / compileSdk 37 / **minSdk 21**。
> backdrop 2.0.0 是 Compose Multiplatform 库，支持 Android-only 工程与 KMP 工程两种接入方式（见下）。

## 项目级 build.gradle.kts

### 方案 A：Android-only 工程

```kotlin
// build.gradle.kts (Project level)
plugins {
    id("com.android.application") version "9.3.0" apply false
    id("com.android.library") version "9.3.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.10" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.10" apply false
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
```

### 方案 B：KMP 工程（backdrop 2.0.0 的目标形态）

```kotlin
// build.gradle.kts (Project level)
plugins {
    id("com.android.application") version "9.3.0" apply false
    id("com.android.kotlin.multiplatform.library") version "9.3.0" apply false
    id("org.jetbrains.kotlin.multiplatform") version "2.4.10" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.10" apply false
    id("org.jetbrains.compose") version "1.11.1" apply false
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
```

## 模块级 build.gradle.kts

### 方案 A：Android-only 模块

```kotlin
// build.gradle.kts (Module level)
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")  // Kotlin 2.x 起取代 composeOptions
}

android {
    namespace = "com.example.liquidglass"
    compileSdk = 37  // 对齐官方（backdrop 2.0.0 官方构建用 compileSdk 37）

    defaultConfig {
        applicationId = "com.example.liquidglass"
        minSdk = 21  // Backdrop 2.0.0 最低要求（官方库实测 minSdk 21）
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // Backdrop 核心库（2.0.0，Compose Multiplatform）
    implementation("io.github.kyant0:backdrop:2.0.0")

    // shapes 库：backdrop 的传递依赖，直接使用 com.kyant.shapes 的 Shape 时才需要显式声明
    implementation("io.github.kyant0:shapes:1.2.0")

    // Compose BOM（与 Kotlin 2.4.x / CMP 1.11.x 配套的 androidx compose 版本）
    implementation(platform("androidx.compose:compose-bom:2025.09.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.foundation:foundation-layout")
    implementation("androidx.compose.animation:animation")

    // Activity
    implementation("androidx.activity:activity-compose:1.13.0")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")

    // Test
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.7.0")
    androidTestImplementation(platform("androidx.compose:compose-bom:2025.09.00"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
```

### 方案 B：KMP 模块（commonMain 声明依赖）

```kotlin
// build.gradle.kts (Module level, KMP)
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.multiplatform")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.compose")
}

kotlin {
    androidTarget()

    listOf(iosX64(), iosArm64(), iosSimulatorArm64()).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "ComposeApp"
            isStatic = true
        }
    }

    sourceSets {
        commonMain.dependencies {
            implementation("io.github.kyant0:backdrop:2.0.0")
            implementation(compose.runtime)
            implementation(compose.foundation)
            implementation(compose.ui)
            implementation(compose.material3)
            implementation(compose.components.resources)  // SdfShader 等依赖
        }
        androidMain.dependencies {
            implementation("androidx.activity:activity-compose:1.13.0")
        }
    }
}

android {
    namespace = "com.example.liquidglass"
    compileSdk = 37
    defaultConfig {
        applicationId = "com.example.liquidglass"
        minSdk = 21
        targetSdk = 37
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
```

## settings.gradle.kts

```kotlin
// settings.gradle.kts
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "LiquidGlassApp"
include(":app")
```

## gradle.properties

```properties
# Project-wide Gradle settings
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true

# AndroidX
android.useAndroidX=true
android.enableJetifier=false

# Kotlin
kotlin.code.style=official

# Compose
# Kotlin 2.x 使用 org.jetbrains.kotlin.plugin.compose 插件，无需设置 compiler 版本
```

## 版本说明

### Backdrop 版本选择

| 版本 | 最低 SDK | 备注 |
|------|---------|------|
| 1.x | API 21（Android 专属） | 基础模糊、折射、色散 |
| 2.0.0 | API 21（官方库实测 minSdk 21） | **Compose Multiplatform**（首个 KMP 版），推荐使用 |

> 2.0.0 起移除 Android 专属 effects 实现，改用 Compose 跨平台版本；新增通用 `RuntimeShader` 接口与 `runtimeShaderEffect`（详见 SKILL.md「1.x → 2.0 迁移说明」）。

### 推荐版本组合

```kotlin
// 与官方 kmp 分支 libs.versions.toml 对齐（2026-08）
dependencies {
    implementation("io.github.kyant0:backdrop:2.0.0")
    implementation("io.github.kyant0:shapes:1.2.0")  // backdrop 传递依赖，可选
}
```

## ProGuard 配置

```proguard
# Backdrop
-keep class com.kyant.backdrop.** { *; }
-keepclassmembers class com.kyant.backdrop.** { *; }

# Shapes
-keep class com.kyant.shapes.** { *; }
-keepclassmembers class com.kyant.shapes.** { *; }

# Runtime Shader
-keep class com.kyant.backdrop.internal.** { *; }
```

## 多模块项目配置

如果你的项目是多模块的：

### settings.gradle.kts

```kotlin
include(":app")
include(":feature:home")
include(":feature:detail")
include(":core:designsystem")
include(":core:ui")
```

### 在 designsystem 模块中导出玻璃组件

```kotlin
// core/designsystem/build.gradle.kts
dependencies {
    implementation("io.github.kyant0:backdrop:2.0.0")
    implementation("io.github.kyant0:shapes:1.2.0")
    implementation(platform("androidx.compose:compose-bom:2025.09.00"))
    implementation("androidx.compose.ui:ui")
}

// 导出公共 API
class DesignSystem {
    companion object {
        val Components = GlassComponents
    }
}

object GlassComponents {
    val Button = LiquidButton
    val Slider = LiquidSlider
    val Toggle = LiquidToggle
}
```

### 在其他模块中使用

```kotlin
// feature/home/build.gradle.kts
dependencies {
    implementation(project(":core:designsystem"))
}

@Composable
fun HomeScreen() {
    DesignSystem.Components.Button(
        onClick = { },
        backdrop = rememberLayerBackdrop()
    ) {
        Text("Home")
    }
}
```

## CI/CD 配置

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Gradle
        uses: gradle/gradle-build-action@v3

      - name: Build Debug
        run: ./gradlew assembleDebug

      - name: Run Tests
        run: ./gradlew test
```

## 发布配置

如果你需要将玻璃组件作为独立库发布：

```kotlin
// 在 library 模块的 build.gradle.kts 中
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("maven-publish")
}

android {
    // ...
    publishing {
        singleVariant("release") {
            withSourcesJar()
            withJavadocJar()
        }
    }
}

publishing {
    publications {
        register<MavenPublication>("release") {
            groupId = "com.example"
            artifactId = "liquid-glass"
            version = "1.0.0"

            afterEvaluate {
                from(components["release"])
            }
        }
    }

    repositories {
        maven {
            url = uri("https://maven.pkg.github.com/username/repo")
            credentials {
                username = project.findProperty("gpr.user") as String? ?: System.getenv("USERNAME")
                password = project.findProperty("gpr.key") as String? ?: System.getenv("TOKEN")
            }
        }
    }
}
```

## 检查清单

在开始开发前，请确认：

- [ ] `minSdk` >= 21（effects 需 Android 12+ 运行时；RuntimeShader 需 13+）
- [ ] `compileSdk` >= 37
- [ ] 已启用 Compose（Kotlin 2.x 使用 `org.jetbrains.kotlin.plugin.compose` 插件）
- [ ] 已添加 Backdrop 2.0.0 依赖
- [ ] 已添加 Shapes 依赖（可选，backdrop 传递依赖）
- [ ] 已配置 Kotlin 2.1.0+（官方构建使用 2.4.10）
- [ ] KMP 工程已应用 `org.jetbrains.compose` 插件

## 验证构建

```bash
# 清理并构建
./gradlew clean assembleDebug

# 运行测试
./gradlew test

# 检查依赖
./gradlew dependencies
```

## 常见构建错误

### 错误：找不到 Backdrop 库

```bash
# 解决方案：确保 Maven Central 已添加
repositories {
    google()
    mavenCentral()  # 必须包含
}
```

### 错误：Compose 版本冲突

```bash
# 使用 Compose BOM 统一版本（Android-only 工程）
implementation(platform("androidx.compose:compose-bom:2025.09.00"))
# KMP 工程统一使用 org.jetbrains.compose 插件版本（1.11.1），不混用 androidx compose 坐标
```

### 错误：RenderEffect 不支持

```bash
# minSdk >= 21 即可编译；effects 在 Android 12+ 运行时生效（RenderEffect），
# RuntimeShader 类效果需 Android 13+。低版本运行时静默跳过。
# 在代码中检查支持性
if (isRenderEffectSupported()) {
    // 使用效果
}
```
