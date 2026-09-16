# Android 应用开发指南（导读）

本指南按 `guide` 统一标准组织：**分章教程正文（`docs/`）+ 独立示例 + build 脚本 + 可编译验证**。主语言 Kotlin，UI 覆盖传统 View 体系与 Jetpack Compose 双范式，含 JNI/NDK 与实战项目。

## 章节地图

| 章 | 标题 | 一句话 | 对应示例 |
|---|---|---|---|
| 01 | [Android 平台概述与架构](docs/01-overview.md) | 从 Linux 内核到 APK，四组件与双 UI 体系的位置 | 无（概念章） |
| 02 | [工程结构与构建工具链](docs/02-project-toolchain.md) | SDK 目录、android.jar 本质、Gradle 工程解剖、build.ps1 | `examples/01` |
| 03 | [Kotlin for Android 必需子集](docs/03-kotlin-for-android.md) | null 安全、data class、Lambda/SAM、协程最小集 | `examples/01` |
| 04 | [Activity 与应用生命周期](docs/04-activity-lifecycle.md) | onCreate、回退栈、进程回收与 savedInstanceState | `examples/01` |
| 05 | [传统 View 体系：布局、控件与事件](docs/05-views-events.md) | 代码/XML 双方式建 UI、事件、Toast、属性动画 | `examples/02 03 19` |
| 06 | [Intent 与页面导航](docs/06-intents-navigation.md) | 显式/隐式 Intent、extras、回传数据 | `examples/04 20` |
| 07 | [列表与 Adapter 模式](docs/07-lists-adapters.md) | ListView/BaseAdapter/ViewHolder 到 RecyclerView | `examples/05` |
| 08 | [线程、Handler 与网络请求](docs/08-threads-network.md) | 主线程模型、Looper/Handler、网络与 JSON、协程 | `examples/06 15 16` |
| 09 | [本地数据持久化](docs/09-data-storage.md) | SharedPreferences、内部存储、SQLiteOpenHelper | `examples/07 08 09` |
| 10 | [BroadcastReceiver、Service 与通知](docs/10-system-components.md) | 广播收发、Service 起停、NotificationChannel | `examples/10 11 12` |
| 11 | [运行时权限、ContentResolver 与硬件服务](docs/11-permissions-content.md) | 危险权限流程、跨应用数据、位置与传感器 | `examples/13 14 17 18` |
| 12 | [Jetpack Compose 基础](docs/12-compose-basics.md) | 声明式 UI、remember/重组、Modifier、LazyColumn | ComposeSamples.kt |
| 13 | [Compose 工程化架构](docs/13-compose-architecture.md) | ViewModel+StateFlow、Navigation、Room、WorkManager | AdvancedSamples.kt |
| 14 | [JNI 与 NDK](docs/14-jni-ndk.md) | external fun、C++ 侧符号规则、CMake 交叉编译 | `examples/21` + cpp/ |
| 15 | [实战项目：MemoPad 便签应用](docs/15-memopad.md) | 单向数据流三层架构组装完整应用 | MemoPadSample.kt |

## 学习路线

- **入门（01~04）**：先建平台与工程的心智模型，再进 Activity 生命周期——Android 一切行为的底层逻辑
- **传统 UI 与并发（05~08）**：View 体系 + Intent + 列表 + 主线程铁律；读懂存量代码的基础
- **系统能力（09~11）**：存储选型、四组件、权限与硬件
- **现代主线（12~13）**：Compose 与工程化架构，新项目的起点
- **纵深与收束（14~15）**：JNI 打通原生层，MemoPad 把全书串成一个应用

## 编译验证

```powershell
cd G:\code\guide\android
pwsh -File .\build.ps1 -All        # 21 条 Kotlin 示例 + Compose 工程 + JNI
pwsh -File .\build.ps1 -Compose    # 仅 Gradle Compose 工程
pwsh -File .\build.ps1 -Jni        # 仅 NDK/CMake
```

三层验证：`examples/`（kotlinc + android.jar 静态编译）、`compose_examples/`（Gradle `:app:compileDebugKotlin`）、JNI（NDK 交叉编译 `libguide_native.so`）。工具链与依赖版本详见 [README.md](README.md)。

## 相关教程

本仓库兄弟教程：[Kotlin 语言指南](../kotlin/KOTLIN_GUIDE.md)（第 03 章的深入入口）、[Win32](../win32/README.md)、[MFC](../mfc/README.md)、[WPF](../wpf/README.md)（Windows 桌面谱系对照）。
