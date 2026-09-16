# Android 应用开发教程

一套从零开始的 Android 实用教程：16 章正文 + 21 条 Kotlin API 示例 + 23 条 Jetpack Compose 示例 + JNI/NDK 示例 + 1 个实战项目 MemoPad。全部代码在本机工具链上编译验证（kotlinc + android.jar 静态编译、Gradle Compose 工程编译、NDK CMake 交叉编译），教程正文见 `docs/`。

## 快速开始

```powershell
cd G:\code\guide\android
pwsh -File .\build.ps1 -All      # 全量：21 条 Kotlin 示例 + Compose 工程 + JNI
pwsh -File .\build.ps1 -File 12_notifications.kt   # 单文件编译验证
pwsh -File .\build.ps1 -Compose   # 仅 Compose 工程（gradle compileDebugKotlin）
pwsh -File .\build.ps1 -Jni       # 仅 JNI（NDK + CMake 交叉编译 libguide_native.so）
pwsh -File .\build.ps1 -Clean     # 清理 build 目录
```

> 注意：`build.ps1` 为 UTF-8 无 BOM 编码，需要 PowerShell 7（pwsh）运行；Windows PowerShell 5.1 会把中文脚本误读为 ANSI 导致解析失败。

## 目录结构

```text
android/
├── README.md                     # 本文件
├── Android应用开发指南.md          # 教程导读（章节地图与学习路线）
├── build.ps1                     # 一键构建验证脚本
├── docs/                         # 教程正文（按章组织）
│   ├── 01-overview.md            # Android 平台概述与架构
│   ├── 02-project-toolchain.md   # 工程结构与构建工具链
│   ├── 03-kotlin-for-android.md  # Kotlin for Android 必需子集
│   ├── 04-activity-lifecycle.md  # Activity 与应用生命周期
│   ├── 05-views-events.md        # 传统 View 体系：布局、控件与事件
│   ├── 06-intents-navigation.md  # Intent 与页面导航
│   ├── 07-lists-adapters.md      # 列表与 Adapter 模式
│   ├── 08-threads-network.md     # 线程、Handler 与网络请求
│   ├── 09-data-storage.md        # 本地数据持久化
│   ├── 10-system-components.md   # BroadcastReceiver、Service 与通知
│   ├── 11-permissions-content.md # 运行时权限、ContentResolver 与硬件服务
│   ├── 12-compose-basics.md      # Jetpack Compose 基础
│   ├── 13-compose-ui.md          # Compose 组件与交互
│   ├── 14-compose-architecture.md # Compose 工程化架构
│   ├── 15-jni-ndk.md             # JNI 与 NDK
│   └── 16-memopad.md             # 实战项目：MemoPad 便签应用
├── examples/                     # 21 条 Kotlin API 示例（kotlinc + android.jar 编译验证）
│   ├── 01_hello_activity.kt      # ... 每章文档开头标注对应示例
│   └── 21_jni_bridge.kt
└── compose_examples/             # Gradle 工程：Compose + ViewModel + Navigation + Room + WorkManager + JNI
    └── app/src/main/
        ├── java/guide/android/compose/samples/   # ComposeSamples / AdvancedSamples / MemoPadSample
        ├── java/guide/android/compose/jni/       # GuideNativeBridge（external fun 声明）
        ├── cpp/                                   # native-lib.cpp + CMakeLists.txt
        └── AndroidManifest.xml
```

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| Android SDK | `G:\android`（`build.ps1` 自动选 `platforms` 下最高 API 的 `android.jar`，写作时为 android-37.1） |
| Kotlin 编译器 | `G:\scoop\apps\kotlin\current\bin\kotlinc.bat` |
| Gradle | `G:\scoop\apps\gradle\current\bin\gradle.bat` |
| JDK | `G:\scoop\apps\openjdk\current`（Java 17） |
| Compose 工程 | AGP 8.7.3、Kotlin 2.0.21、compileSdk 35、minSdk 24 |
| 核心依赖 | Compose ui 1.7.8、material3 1.3.1、material-icons-core 1.7.8、navigation-compose 2.8.5、lifecycle 2.8.7、room 2.6.1、work-runtime-ktx 2.10.0 |

验证体系分三层：`examples/` 用 `kotlinc -classpath android.jar` 做静态编译验证（API 调用与语法可信）；`compose_examples/` 用 Gradle 编译验证（含 KSP 之前的注解库）；JNI 用 NDK CMake 交叉编译出 `libguide_native.so`。运行示例需真实设备或模拟器，不在本仓库验证范围内。

## 学习路线

1. **01~03**：平台架构、工程与工具链、Kotlin 子集——先弄清"APK 是什么、Gradle 在干嘛"
2. **04~08**：Activity 生命周期、View 体系、Intent、列表、线程与网络——传统 Android 的骨架
3. **09~11**：存储、四组件里的 Service/Broadcast/通知、权限与硬件——系统能力
4. **12~14**：Compose 三部曲——基础心智模型、组件与交互（Scaffold/动画/副作用）、工程化架构（ViewModel/StateFlow/Navigation/Room/WorkManager），现代 Android 的主线
5. **15~16**：JNI/NDK 与实战项目 MemoPad，把全书知识串进一个可扩展的应用

传统 View 体系（04~08）与 Compose（12~14）是两套并存的 UI 范式：新项目从 Compose 开始，但读懂存量代码仍需 View 体系——这也是教程两者都讲的原因。

## 实战项目：MemoPad 便签

`compose_examples/.../samples/MemoPadSample.kt` 是一个约 330 行的完整应用：Compose 列表/编辑双屏、Navigation 路由、ViewModel + StateFlow 单向数据流、JSON 文件持久化、WorkManager 后台备份，零新增依赖。详见 [docs/16-memopad.md](docs/16-memopad.md)。
