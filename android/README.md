# Android 应用开发教程（Kotlin · View + Compose 双范式）

面向**会编程（任意语言背景）、初学 Android 应用开发**的读者：从平台架构、
工程工具链讲到传统 View 体系与系统能力，然后是**传统深水区七章**（布局菜单样式
→ 自定义绘图 → 动画三体系 → Fragment 与任务栈 → 多媒体 → 桌面组件与系统
管理器 → WebView 混合），再到 **Jetpack Compose 八章主线**（基础 → 组件 →
架构 → 状态/渲染/动画/手势四门深入课 → 依赖注入与生态），接着是 **JNI/NDK
原生线六章**（边界 → JNI 深入 → Bionic → 线程 → Socket → 媒体与 NEON），
最后以实战项目 **MemoPad 便签应用**收束。传统 View（05–08、12–18）与
Compose（19–26）两套并存 UI 范式都讲——新项目从 Compose 开始，读懂存量
代码仍需 View 体系。

> 核心理念：**先弄清"APK 是什么、Gradle 在干嘛"，再写 UI。** Activity
> 生命周期（04 章）是一切行为的底层逻辑；传统深水区（12–18）把 View 体系
> 一次讲透；Compose（19 章）是全书分水岭，从命令式转向声明式心智模型；
> 原生线（27–32 章）的立场是"看得懂、接得住，默认不下潜"。

## 目录结构

```text
android/
├── README.md        本文件
├── build.ps1        构建验证脚本（PowerShell 7，UTF-8 无 BOM）
├── docs/            33 章教程（01 → 33 顺序阅读）
├── examples/        27 条 Kotlin API 示例（kotlinc + android.jar 编译验证）
├── compose_examples/ Gradle 工程：Compose + ViewModel + Navigation + Room + WorkManager + Fragment + JNI
│   └── app/src/main/
│       ├── java/guide/android/compose/samples/  ComposeSamples / UiSamples / AdvancedSamples /
│       │     StateSamples / LayoutDrawSamples / AnimationSamples / GestureSamples /
│       │     EcosystemSamples / FragmentSamples / JniSamples / MemoPadSample
│       ├── java/guide/android/compose/jni/      六个 bridge object（external fun 声明，
│       │     与 cpp/ 文件一一镜像）
│       ├── cpp/                                  native-lib + jni_deep + bionic_samples +
│       │     native_threads + native_sockets + native_media + CMakeLists.txt
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
| [06 Intent 与页面导航](docs/06-intents-navigation.md) | 显式/隐式 Intent、七属性与 filter 匹配、回传数据 | `04` `20` |
| [07 列表与 Adapter 模式](docs/07-lists-adapters.md) | ListView/ViewHolder 到 RecyclerView | `05` |
| [08 线程、Handler 与网络](docs/08-threads-network.md) | 主线程模型、Looper/Handler、网络与 JSON、协程 | `06` `15` `16` |
| [09 本地数据持久化](docs/09-data-storage.md) | SharedPreferences、内部存储、SQLiteOpenHelper | `07` `08` `09` |
| [10 广播、Service 与通知](docs/10-system-components.md) | 广播收发、Service 起停、NotificationChannel | `10` `11` `12` |
| [11 权限、ContentResolver 与硬件](docs/11-permissions-content.md) | 危险权限流程、跨应用数据（读与自建）、位置与传感器 | `13` `14` `17` `18` |
| [12 传统 View 深水区：布局、菜单与样式](docs/12-views-deep.md) | 六大布局、对话框六法、三种菜单、样式主题、Drawable 七类 | `22_layouts_menus_styles` |
| [13 自定义 View 与绘图](docs/13-custom-view-drawing.md) | 三回调、Canvas/Paint/Path、Shader、Matrix、双缓冲、SurfaceView、手势 | `23_custom_view_drawing` |
| [14 动画三体系](docs/14-view-animations.md) | 逐帧、补间、属性动画，Interpolator、Keyframe、AnimatorSet | `24_view_animations` |
| [15 Fragment 与任务栈](docs/15-fragment-tasks.md) | 双链条生命周期、事务与回退栈、通信三正道、四种加载模式 | `FragmentSamples.kt` |
| [16 多媒体开发](docs/16-media.md) | MediaPlayer 状态机、SoundPool、音频焦点、录制、Camera2 | `25_media_playback` |
| [17 桌面组件与系统管理器](docs/17-appwidget-managers.md) | AppWidget/RemoteViews、动态壁纸、闹钟/振动/短信五管理器 | `26_appwidget_managers` |
| [18 WebView 与混合开发](docs/18-webview-hybrid.md) | 迷你浏览器、JS 桥双向、两个 Client、安全底线 | `27_webview_hybrid` |
| [19 Jetpack Compose 基础](docs/19-compose-basics.md) | 声明式 UI、remember/重组、Modifier、布局三件套、互操作 | `ComposeSamples.kt` |
| [20 Compose 组件与交互](docs/20-compose-ui.md) | 组件速查、Scaffold、对话框、副作用、动画入门、主题定制 | `UiSamples.kt` |
| [21 Compose 工程化架构](docs/21-compose-architecture.md) | ViewModel+StateFlow、UiState、Navigation、Room、WorkManager | `AdvancedSamples.kt` |
| [22 Compose 状态与重组深入](docs/22-compose-state.md) | 稳定性与跳过、key、rememberSaveable、derivedStateOf、snapshotFlow、StateHolder | `StateSamples.kt` |
| [23 Compose 自定义布局与绘制](docs/23-compose-layout-draw.md) | 三阶段、Modifier.layout、Layout/Intrinsic、Canvas、DrawModifier | `LayoutDrawSamples.kt` |
| [24 Compose 动画进阶](docs/24-compose-animation.md) | AnimationSpec 家族、updateTransition、Animatable、TwoWayConverter、骨架屏/收藏按钮 | `AnimationSamples.kt` |
| [25 Compose 手势处理](docs/25-compose-gestures.md) | detectTap/Drag/Transform、anchoredDraggable、nestedScroll、Fling | `GestureSamples.kt` |
| [26 Compose 依赖注入与生态](docs/26-compose-di-ecosystem.md) | 手写 AppContainer、Hilt 概念、Coil/Lottie/Accompanist 现状 | `EcosystemSamples.kt` |
| [27 JNI 与 NDK](docs/27-jni-ndk.md) | external fun、符号规则、CMake 交叉编译、构建沿革、原生日志、SWIG | `21_jni_bridge` + `cpp/native-lib.cpp` |
| [28 JNI 深入](docs/28-jni-deep.md) | 字符串/数组/NIO/域与方法/异常/引用三档 | `cpp/jni_deep.cpp` + `JniDeepBridge.kt` |
| [29 Bionic 与 C++ 标准库](docs/29-bionic-cpp.md) | sysconf/系统属性/沙箱身份/FILE* I/O、运行库变迁 | `cpp/bionic_samples.cpp` + `BionicBridge.kt` |
| [30 原生线程与同步](docs/30-native-threads.md) | pthread、互斥/条件变量/信号量、AttachCurrentThread | `cpp/native_threads.cpp` + `NativeThreadBridge.kt` |
| [31 POSIX Socket 原生网络](docs/31-native-sockets.md) | TCP/UDP/UNIX domain 回环、字节序、epoll 坐标 | `cpp/native_sockets.cpp` + `SocketBridge.kt` |
| [32 原生图形、音频与性能](docs/32-native-media-perf.md) | Bitmap 直访、EGL/OpenSL ES 现状校准、NEON、simpleperf | `cpp/native_media.cpp` + `MediaBridge.kt` |
| [33 实战项目：MemoPad](docs/33-memopad.md) | 单向数据流三层架构组装完整应用 | `MemoPadSample.kt` |

学习路线：01–04 建心智模型 → 05–08 传统 UI 与并发 → 09–11 系统能力 →
12–18 传统深水区（布局/自绘/动画/Fragment/多媒体/桌面组件/WebView）→
19–21 Compose 主线（基础/组件/架构）→ 22–25 四门深入课（状态·渲染·动画·
手势，按需精读）→ 26 生态 → 27 JNI 边界（必修）→ 28–32 原生线纵深
（选修）→ 33 实战收束。

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| Android SDK | `G:\android`（`build.ps1` 自动选 `platforms` 下最高 API 的 `android.jar`，写作时为 android-37.1） |
| Kotlin 编译器 | `G:\scoop\apps\kotlin\current\bin\kotlinc.bat` |
| Gradle | `G:\scoop\apps\gradle\current\bin\gradle.bat` |
| JDK | `G:\scoop\apps\openjdk\current`（Java 17） |
| Compose 工程 | AGP 8.7.3、Kotlin 2.0.21、compileSdk 35、minSdk 24 |
| 核心依赖 | Compose ui 1.7.8、material3 1.3.1、material-icons-core 1.7.8、navigation-compose 2.8.5、lifecycle 2.8.7、room 2.6.1、work-runtime-ktx 2.10.0、fragment-ktx 1.8.6 |

## 验证命令

```powershell
cd android
pwsh -File .\build.ps1 -All                          # 全量：27 条 Kotlin 示例 + Compose 工程 + JNI
pwsh -File .\build.ps1 -File 12_notifications.kt     # 单文件编译验证
pwsh -File .\build.ps1 -Compose                      # 仅 Compose 工程（gradle compileDebugKotlin）
pwsh -File .\build.ps1 -Jni                          # 仅 JNI（NDK + CMake 交叉编译 libguide_native.so）
pwsh -File .\build.ps1 -Clean                        # 清理 build 目录
```

**判定标准**：三层编译验证全部退出码 0——`examples/` 用 `kotlinc -classpath
android.jar` 静态编译（API 调用与语法可信）；`compose_examples/` 用 Gradle
`:app:compileDebugKotlin`；JNI 用 NDK CMake 交叉编译出 `libguide_native.so`
（NDK 30.0.15729638、arm64-v8a、android-24，27–32 章六个 cpp 文件全量编入，
链 log/jnigraphics/OpenSLES/EGL 四个系统库）。运行示例需真实设备或模拟器，
不在本仓库验证范围。

## 平台差异说明

- `build.ps1` 为 UTF-8 **无 BOM** 编码，必须用 **PowerShell 7（pwsh）** 运行；
  Windows PowerShell 5.1 会把中文脚本误读为 ANSI 直接报语法错。
- `build.ps1` 自动探测 `platforms/` 下最高 API（不硬编码 compileSdk 的 35）。
- 刻意不接 Room/KSP/Hilt 注解处理器：Room 三件套与手写 DI 容器只定义不实例化
  （21、26 章如实说明接法与代价）；Fragment 是唯一新增依赖（androidx.fragment，
  15 章的示例需要）。

## 示例怎么读

- 每章开头 blockquote 标注对应示例文件；`examples/` 按**主题聚合编号**
  （01–27），与章号不一一对应——完整映射见上方章节索引表。
- Compose/Gradle 侧示例集中在 `compose_examples/` 工程的 11 个 samples 文件里
  （70 条示例：19–26 章 51 条 + 15 章 Fragment 1 条 + 原生线 27–32 章 17 条 +
  MemoPad 1 条，含 @Preview、UiState 三态、手势/动画/自绘、Fragment 事务、
  JNI/线程/Socket/NEON 等条目）。
- 原生线示例双份镜像：`jni/` 一个 Kotlin object 对应 `cpp/` 一个 C++ 文件，
  改名/改签名必须两侧同步（第 27 章的镜像纪律）。
- MainActivity 外层 Column 带 `verticalScroll`，因此嵌套的 LazyColumn/Scaffold
  必须**定高**（嵌套无限高度会运行期崩溃，教程 19 章第 8 节讲透）。
- 改示例后跑对应验证：Kotlin 单文件 `-File`，Compose/Fragment 工程 `-Compose`，
  JNI `-Jni`。

## 实战项目：MemoPad

`compose_examples/.../samples/MemoPadSample.kt` 是一个约 330 行的完整应用：
Compose 列表/编辑双屏、Navigation 路由、ViewModel + StateFlow 单向数据流、
JSON 文件持久化、WorkManager 后台备份，零新增依赖。详见
[33 章](docs/33-memopad.md)。

## 相关教程

语言底座 [kotlin](../kotlin/README.md)（第 03 章的深入入口）；跨平台 UI 对照
[flutter](../flutter/README.md) 与 [dart](../dart/README.md)；Windows 桌面谱系
[win32](../win32/README.md) / [mfc](../mfc/README.md) / [wpf](../wpf/README.md)。
