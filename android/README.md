# Android 应用开发教程（Kotlin · View + Compose 双范式）

面向**会编程（任意语言背景）、初学 Android 应用开发**的读者：从平台架构、
工程工具链讲到传统 View 体系与系统能力，再到 **Jetpack Compose 三部曲**与
JNI/NDK，最后以实战项目 **MemoPad 便签应用**收束。传统 View（05–08）与
Compose（12–14）两套并存 UI 范式都讲——新项目从 Compose 开始，读懂存量
代码仍需 View 体系。

> 核心理念：**先弄清"APK 是什么、Gradle 在干嘛"，再写 UI。** Activity
> 生命周期（04 章）是一切行为的底层逻辑；Compose（12 章）是全书分水岭，
> 从命令式转向声明式心智模型。

## 目录结构

```text
android/
├── README.md        本文件
├── build.ps1        构建验证脚本（PowerShell 7，UTF-8 无 BOM）
├── docs/            16 章教程（01 → 16 顺序阅读）
├── examples/        21 条 Kotlin API 示例（kotlinc + android.jar 编译验证）
├── compose_examples/ Gradle 工程：Compose + ViewModel + Navigation + Room + WorkManager + JNI
│   └── app/src/main/
│       ├── java/guide/android/compose/samples/  ComposeSamples / UiSamples / AdvancedSamples / MemoPadSample
│       ├── java/guide/android/compose/jni/      GuideNativeBridge（external fun 声明）
│       ├── cpp/                                  native-lib.cpp + CMakeLists.txt
│       └── AndroidManifest.xml
└── build/           构建输出（已 gitignore）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 平台概述与架构](docs/01-overview.md) | 从 Linux 内核到 APK，四组件与双 UI 体系 | —（概念章） |
| [02 工程结构与构建工具链](docs/02-project-toolchain.md) | SDK 目录、android.jar 本质、Gradle 工程解剖 | `01_hello_activity` |
| [03 Kotlin for Android 必需子集](docs/03-kotlin-for-android.md) | null 安全、data class、Lambda/SAM、协程最小集 | `01_hello_activity` |
| [04 Activity 与应用生命周期](docs/04-activity-lifecycle.md) | onCreate、回退栈、进程回收、savedInstanceState | `01_hello_activity` |
| [05 传统 View 体系](docs/05-views-events.md) | 代码/XML 双方式建 UI、事件、Toast、属性动画 | `02` `03` `19` |
| [06 Intent 与页面导航](docs/06-intents-navigation.md) | 显式/隐式 Intent、extras、回传数据 | `04` `20` |
| [07 列表与 Adapter 模式](docs/07-lists-adapters.md) | ListView/ViewHolder 到 RecyclerView | `05` |
| [08 线程、Handler 与网络](docs/08-threads-network.md) | 主线程模型、Looper/Handler、网络与 JSON、协程 | `06` `15` `16` |
| [09 本地数据持久化](docs/09-data-storage.md) | SharedPreferences、内部存储、SQLiteOpenHelper | `07` `08` `09` |
| [10 广播、Service 与通知](docs/10-system-components.md) | 广播收发、Service 起停、NotificationChannel | `10` `11` `12` |
| [11 权限、ContentResolver 与硬件](docs/11-permissions-content.md) | 危险权限流程、跨应用数据、位置与传感器 | `13` `14` `17` `18` |
| [12 Jetpack Compose 基础](docs/12-compose-basics.md) | 声明式 UI、remember/重组、Modifier、布局三件套 | `ComposeSamples.kt` |
| [13 Compose 组件与交互](docs/13-compose-ui.md) | 组件速查、Scaffold、对话框、副作用、动画 | `UiSamples.kt` |
| [14 Compose 工程化架构](docs/14-compose-architecture.md) | ViewModel+StateFlow、UiState、Navigation、Room、WorkManager | `AdvancedSamples.kt` |
| [15 JNI 与 NDK](docs/15-jni-ndk.md) | external fun、C++ 侧符号规则、CMake 交叉编译 | `21_jni_bridge` + `cpp/` |
| [16 实战项目：MemoPad](docs/16-memopad.md) | 单向数据流三层架构组装完整应用 | `MemoPadSample.kt` |

学习路线：01–04 建心智模型 → 05–08 传统 UI 与并发 → 09–11 系统能力 →
12–14 Compose 现代主线 → 15–16 JNI 纵深与实战收束。

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| Android SDK | `G:\android`（`build.ps1` 自动选 `platforms` 下最高 API 的 `android.jar`，写作时为 android-37.1） |
| Kotlin 编译器 | `G:\scoop\apps\kotlin\current\bin\kotlinc.bat` |
| Gradle | `G:\scoop\apps\gradle\current\bin\gradle.bat` |
| JDK | `G:\scoop\apps\openjdk\current`（Java 17） |
| Compose 工程 | AGP 8.7.3、Kotlin 2.0.21、compileSdk 35、minSdk 24 |
| 核心依赖 | Compose ui 1.7.8、material3 1.3.1、material-icons-core 1.7.8、navigation-compose 2.8.5、lifecycle 2.8.7、room 2.6.1、work-runtime-ktx 2.10.0 |

## 验证命令

```powershell
cd android
pwsh -File .\build.ps1 -All                          # 全量：21 条 Kotlin 示例 + Compose 工程 + JNI
pwsh -File .\build.ps1 -File 12_notifications.kt     # 单文件编译验证
pwsh -File .\build.ps1 -Compose                      # 仅 Compose 工程（gradle compileDebugKotlin）
pwsh -File .\build.ps1 -Jni                          # 仅 JNI（NDK + CMake 交叉编译 libguide_native.so）
pwsh -File .\build.ps1 -Clean                        # 清理 build 目录
```

**判定标准**：三层编译验证全部退出码 0——`examples/` 用 `kotlinc -classpath
android.jar` 静态编译（API 调用与语法可信）；`compose_examples/` 用 Gradle
`:app:compileDebugKotlin`；JNI 用 NDK CMake 交叉编译出 `libguide_native.so`
（NDK 30.0.15729638、arm64-v8a、android-24）。运行示例需真实设备或模拟器，
不在本仓库验证范围。

## 平台差异说明

- `build.ps1` 为 UTF-8 **无 BOM** 编码，必须用 **PowerShell 7（pwsh）** 运行；
  Windows PowerShell 5.1 会把中文脚本误读为 ANSI 直接报语法错。
- `build.ps1` 自动探测 `platforms/` 下最高 API（不硬编码 compileSdk 的 35）。
- 刻意不接 Room/KSP 注解处理器：Room 三件套只定义不实例化（14 章如实说明）。

## 示例怎么读

- 每章开头 blockquote 标注对应示例文件；`examples/` 按**主题聚合编号**
  （01–21），与章号不一一对应——完整映射见上方章节索引表。
- Compose 示例集中在 `compose_examples/` 工程的 4 个 samples 文件里
  （23 条示例，含 @Preview 与 UiState 三态）。
- 改示例后跑对应验证：Kotlin 单文件 `-File`，Compose 工程 `-Compose`，JNI `-Jni`。

## 实战项目：MemoPad

`compose_examples/.../samples/MemoPadSample.kt` 是一个约 330 行的完整应用：
Compose 列表/编辑双屏、Navigation 路由、ViewModel + StateFlow 单向数据流、
JSON 文件持久化、WorkManager 后台备份，零新增依赖。详见
[16 章](docs/16-memopad.md)。

## 相关教程

语言底座 [kotlin](../kotlin/README.md)（第 03 章的深入入口）；跨平台 UI 对照
[flutter](../flutter/README.md) 与 [dart](../dart/README.md)；Windows 桌面谱系
[win32](../win32/README.md) / [mfc](../mfc/README.md) / [wpf](../wpf/README.md)。
