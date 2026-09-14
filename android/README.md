# Android 应用开发教程示例集（Kotlin + Compose + JNI，含进阶篇）

本目录按 `guide` 统一结构组织 Android 应用开发教程与可编译示例，主语言为 Kotlin，并提供基础篇与进阶篇。

## 目录结构

```text
android/
├── README.md
├── Android应用开发指南.md
├── build.ps1
└── examples/
    ├── 01_hello_activity.kt
    ├── ...
    └── 20_activity_result_style.kt
compose_examples/
└── app/
    └── src/main/
        ├── java/guide/android/compose/samples/ComposeSamples.kt
        ├── java/guide/android/compose/samples/AdvancedSamples.kt
        └── cpp/native-lib.cpp
```

## 构建工具链

- Android SDK：`G:\android`
- Kotlin 编译器：`G:\scoop\apps\kotlin\current\bin\kotlinc.bat`
- Gradle：`G:\scoop\apps\gradle\current\bin\gradle.bat`
- JDK：`G:\scoop\apps\openjdk\current`
- 编译基准：自动从 `G:\android\platforms\` 选择最高可用 API 的 `android.jar`

## 编译验证

```powershell
cd G:\code\guide\android
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 12_notifications.kt
```

仅 Compose：

```powershell
.\build.ps1 -Compose
```

仅 JNI：

```powershell
.\build.ps1 -Jni
```

清理：

```powershell
.\build.ps1 -Clean
```

> 说明：本目录验证包含三层：
> 1) Kotlin Android API 示例（`kotlinc + android.jar`）
> 2) Compose Gradle 工程 Kotlin 编译（`gradle :app:compileDebugKotlin`）
> 3) JNI C++ 交叉编译（NDK + CMake，含 `examples/21_jni_bridge.kt` 调用声明）
>
> 进阶篇已覆盖：`ViewModel + StateFlow`、`Navigation Compose`、`Room`、`WorkManager`。
