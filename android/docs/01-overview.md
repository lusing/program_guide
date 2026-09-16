# 01 · Android 平台概述与架构

> 对应示例：无，本章为概念章

## 1. Android 是什么

Android 由 Andy Rubin 等人于 2003 年创立（初衷是相机操作系统，后转向手机），2005 年被 Google 收购，2007 年 11 月随开放手机联盟（Open Handset Alliance, OHA）正式公布，2008 年首部商用机 HTC Dream 上市。此后近二十年，它成为全球装机量最大的移动操作系统。

一句话定位：**Android 是基于 Linux 内核的开源移动操作系统，同时是一套完整的应用开发平台**。

这句话的两半分别对应它的两种身份：

- **作为操作系统**：内核、驱动、运行时、系统服务都是它的一部分，厂商（三星、小米……）在 AOSP（Android Open Source Project，开源项目）基础上定制自己的发行版
- **作为应用平台**：它规定了应用的物理形态（APK）、组件模型（四大组件）、API 集合（Framework API）与分发方式（应用商店/侧载）

与你在本仓库里学过的 Windows 桌面开发（Win32/MFC/WPF）对照，差异比相似更值得记住：

| | Windows 桌面（Win32/MFC/WPF） | Android |
|---|---|---|
| 程序形态 | `exe` + `dll` | APK |
| 进程模型 | 用户启动，长期驻留，"关了才没了" | 系统统一调度，后台应用随时可能被回收 |
| 界面技术 | GDI / DirectX / XAML | 传统 View 体系 / Jetpack Compose |
| 主语言 | C / C++ / C# | Kotlin（Java 仍可用，不推荐新工程） |
| 官方工具 | Visual Studio | Android Studio（本教程用命令行，见第 02 章） |
| 权限模型 | 基本没有（UAC 之外） | 安装时声明 + 运行时动态申请 |

这里藏着整门课的主轴：**桌面程序"活着"是常态，Android 应用"活着"是特例**。内存吃紧时系统可以不问你直接销毁后台应用，你的代码必须学会配合生命周期优雅地死与生——这解释了后面近一半章节为什么存在（第 04 章生命周期、第 09 章持久化）。

### 版本速览：记住断代点，不用记版本号

近二十年几十个版本，全部记住没有意义，但几个**行为断代点**值得刻在脑子里——它们改变了"能做什么"的规则，日后排查老应用行为时全靠它们：

| 版本（年份） | API | 断代点 |
|---|---|---|
| 5.0（2014） | 21 | Dalvik → ART 运行时切换 |
| 6.0（2015） | 23 | 危险权限改为运行时动态申请（第 11 章） |
| 7.0（2016） | 24 | 本教程 minSdk 下限 |
| 10（2019） | 29 | 分区存储（Scoped Storage）重写文件访问规则（第 09 章） |
| 12（2021） | 31 | 带 intent-filter 的组件必须显式声明 exported |
| 13（2022） | 33 | 通知也需要运行时权限（第 10 章） |
| 15（2024） | 35 | 当前 compileSdk 基准 |
| 16（2025） | 36 | 最新稳定大版本 |

规律很简单：越往后的版本，系统对应用越苛刻——权限收紧、后台受限、隐私加强。这不是刁难，是移动平台多应用共存与用户信任的必然代价。

## 2. 分层架构：从 Linux 内核到你的代码

Android 官方架构图自底向上五层。对应用开发者，越往上越要关心：

| 层 | 内容 | 开发者接触程度 |
|---|---|---|
| Linux 内核 | 进程/内存/驱动/电源管理，厂商按硬件定制 | 几乎不直接接触 |
| HAL（Hardware Abstraction Layer，硬件抽象层） | 给上层统一硬件接口：相机、音频、传感器 | 不接触 |
| 原生库 + ART | C/C++ 库（SQLite、OpenGL ES、媒体编解码）与 Android 运行时 | 第 14 章 JNI 会碰 |
| Java/Kotlin Framework API | Activity Manager、Window Manager、View 体系、包管理、通知……数千个类的官方 API | **主要工作面** |
| 应用层 | 你写的 APK 与系统预装应用 | 你的代码 |

三个值得先建立的认识：

1. **你的应用是系统的客户端，不是主宰**。启动 Activity、发广播、查数据库，多数动作真正的执行方是系统进程里的服务（如 ActivityManagerService），你的调用经 Binder IPC（进程间通信机制）转发过去。这与桌面程序"自己拥有一个窗口"的世界观根本不同
2. **每个应用一个沙箱**。应用安装时获得独立的 Linux 用户 ID（UID），文件与进程默认互相不可见——跨应用分享数据要走 ContentProvider（第 11 章）这种正规通道
3. **所有应用进程 fork 自 Zygote**。Zygote 是开机时预加载了运行时与公共类的"母进程"，每个应用由它 fork 而来，省去了重复初始化——这就是安卓应用启动没有想象中慢的原因

### ART：AOT 与 JIT 的混合

你的 Kotlin 代码在设备上如何变成机器码，经历过三代方案：

| 时期 | 运行时 | 策略 | 后果 |
|---|---|---|---|
| Android 4.4 及以前 | Dalvik | JIT（Just-In-Time，运行时即时编译） | 每次运行都现译，耗电 |
| 5.0–6.0 | ART（Android Runtime） | 纯 AOT（Ahead-Of-Time，安装时预编译） | 运行快了，安装变慢、占空间 |
| 7.0 至今 | ART | 混合：先 JIT 跑起来，空闲时按 profile 对热点代码 AOT | 两头兼顾 |

教学上记住一句话就够：**你写 Kotlin，工具链把它编译成 dex 字节码，设备上的 ART 负责把它变成机器码**。中间那步"AOT 还是 JIT"是系统自己的优化决策，写应用时不需要关心。

### 一次点击背后发生了什么

把上面几层串起来，走一遍"点击桌面图标到看见界面"的完整链路：

```text
点击图标 → Launcher 发出 Intent → ActivityManagerService（系统进程）裁决
    → 目标应用进程不存在 → 请求 Zygote fork 出新进程
    → 新进程里 ActivityThread.main() 就绪（主线程 + 消息循环）
    → ActivityManagerService 回调它创建 Activity 实例
    → 你的 onCreate() 被调用 → setContentView 内容上屏
```

这条链路上的每个名词都是后面某一章的主角：Intent 是组件间的语言（第 06 章），AMS 的裁决背后是任务与返回栈（第 06 章），ActivityThread 与消息循环是整个线程模型的根（第 08 章），`onCreate` 是你写代码的真正起点（第 04 章）。现在混个脸熟即可，不必看懂。

## 3. APK：应用的物理形态

APK（Android Package）是 Android 应用的安装包，本质是一个改了后缀名的 zip 包：

```text
myapp.apk
├── AndroidManifest.xml     # 应用清单（编译为二进制 XML，第 02 章）
├── classes.dex             # dex 字节码，ART 的输入（类太多时会有 classes2.dex…）
├── res/                    # 编译后的资源：布局、图片、字符串
├── resources.arsc          # 资源索引表
├── lib/<abi>/*.so          # 原生库（若有，详见第 14 章 [JNI 与 NDK](14-jni-ndk.md)）
└── META-INF/               # 签名信息
```

三个认知，直接决定你日后排查问题的方向：

1. **APK 可以被解开**。解压加反编译，布局与逻辑近乎源码级可读——Android 应用的"闭源"很薄，混淆（R8）只是抬高阅读成本，不是加密
2. **发布格式是 AAB 不是 APK**。Google Play 上传的是 AAB（Android App Bundle），由商店按设备 CPU 架构、屏幕密度生成裁剪过的 APK；本地调试与侧载（sideload，直接安装）用的仍是 APK
3. **APK 必须签名才能安装**。调试签名与发布签名是两套，签名不对升级安装会被拒绝

## 4. 四大组件：应用模型的骨架

桌面程序从 `main` 开始，一切由你驱动。Android 反过来：应用由四种**可被系统启动的组件**拼装，每个都必须在 `AndroidManifest.xml` 里登记（登记机制见第 02 章），系统在需要时实例化并回调它们：

| 组件 | 一句话 | 详见 |
|---|---|---|
| Activity（活动） | 一个承载用户界面的"屏幕"，有完整的生命周期回调 | 第 04 章 [Activity 与应用生命周期](04-activity-lifecycle.md) |
| Service（服务） | 无界面的后台工作单元：播放音乐、续传下载 | 第 10 章 [BroadcastReceiver、Service 与通知](10-system-components.md) |
| BroadcastReceiver（广播接收器） | 对系统与应用级广播的订阅者：开机、电量变化、网络切换 | 第 10 章 [BroadcastReceiver、Service 与通知](10-system-components.md) |
| ContentProvider（内容提供器） | 跨应用的结构化数据接口：通讯录、媒体库 | 第 11 章 [运行时权限、ContentResolver 与硬件服务](11-permissions-content.md) |

连接它们的主要媒介是 Intent（意图，一种异步消息描述）：**显式 Intent** 直接点名目标组件（"打开编辑页 EditActivity"），**隐式 Intent** 只声明想做的事（"查看这个 PDF"），由系统在全设备安装的应用里匹配合适的接收者——应用之间因此可以互相借力而不需要知道彼此的存在。两种形态与返回栈的完整机制详见第 06 章 [Intent 与页面导航](06-intents-navigation.md)。

我们的观点：四大组件不是四个"功能"，而是四个**入口点**。系统持有它们的生杀大权与调用时机，你不掌握 `new Activity()` 的主动权。这决定了 Android 代码的组织形态——大量"被回调"的代码 + 少量主动驱动，与桌面程序"事件循环里我说了算"的直觉相反，是转型期最大的观念切换。

## 5. 2026 年的 Android：语言与 UI 双轨

### Kotlin 是官方首选语言

2017 年 Google I/O 宣布 Kotlin 成为 Android 官方开发语言，2019 年进一步确立 Kotlin-first：新 API 优先提供 Kotlin 体验（协程扩展、KTX 扩展库），官方示例与文档默认 Kotlin。Java 与 Kotlin 完全互操作，存量 Java 代码可以继续跑，但新工程没有理由再用 Java 起步。本教程主语言为 Kotlin，第 03 章 [Kotlin for Android 必需子集](03-kotlin-for-android.md) 给出够用的语法子集，不要求先系统学完 Kotlin。

### UI 双体系并存

2021 年 7 月 Jetpack Compose 1.0 发布，Android 进入传统 View 体系与声明式 Compose 并存的时代，至今没有分出胜负：

| | 传统 View 体系 | Jetpack Compose |
|---|---|---|
| 界面描述 | XML 布局文件 + 代码操控控件树 | Kotlin 函数直接描述界面 |
| 状态更新 | 手动赋值（`setText`、`notifyDataSetChanged`） | 状态变化自动触发重组（recomposition） |
| 思想血统 | Win32/MFC/WPF 一系的"保留模式控件树" | React 一系的"声明式 UI + 差异更新" |
| 学习曲线 | 概念分散：XML、findViewById、Adapter | 函数式思维 + 重组心智模型 |
| 适用场景 | 存量代码、简单界面、与老代码互操作 | 新工程的默认选择 |

本教程两者都教，且有明确的顺序观点：第 05~07 章先走 View 体系——它是平台的地基，也仍然是数十亿设备上存量代码的现实；第 12~13 章再走 Compose——现代默认。另一个常被忽视的事实：**Compose 不会让 View 时代的知识作废**。Activity、生命周期、权限、存储、进程模型都是平台知识，Compose 改变的只是"界面怎么写"这一层。

### minSdk 的现实

本教程工程 minSdk 为 24（Android 7.0，2016 年发布），2026 年这个下限大约覆盖 97% 的活跃设备，同时解锁了绝大多数现代 API。三个 SDK 值（minSdk/compileSdk/targetSdk）的辨析详见第 02 章 [工程结构与构建工具链](02-project-toolchain.md)。

### 跨平台选项，一句话

如果目标是 iOS + Android 双端同一套代码，还有 Flutter（Dart，自绘引擎）与 Kotlin Multiplatform（KMP，共享业务逻辑、UI 各端实现）两条主流路线。本教程专注原生 Android——跨平台框架的调试与深度定制，最终都会落回原生知识。

## 6. AndroidX 与 Jetpack：官方扩展库

平台 API（`android.*` 命名空间）随系统固件发布，升级以年计、到达以设备碎片化计——指望它快速演进不现实。Google 的解法是把积极演进的部分拆出固件循环，走独立发布渠道，这就是你在依赖清单里反复看到的两个名字：

- **AndroidX**（`androidx.*` 命名空间）：官方兼容与扩展库家族，向后兼容到很老的 minSdk，独立版本号、按周迭代。第 02 章依赖清单里清一色的 `androidx.compose...`、`androidx.room...` 全是它
- **Jetpack**：AndroidX 加上官方架构指南的品牌伞名。Compose、Room、WorkManager、Navigation、Lifecycle 都在旗下

| 库 | 一句话 | 本教程 |
|---|---|---|
| appcompat | 让新平台的界面行为在老系统上可用 | 第 05 章 |
| Lifecycle | 感知生命周期的状态与作用域 | 第 04、13 章 |
| Room | SQLite 之上的对象映射层 | 第 09 章 |
| WorkManager | 可约束、可延续的后台任务调度 | 第 10 章 |
| Navigation | 页面路由与返回栈管理 | 第 06、13 章 |
| Compose | 声明式 UI 全家桶 | 第 12、13 章 |

一条实用的判断标准：**能用 AndroidX 就不用裸平台 API**。前者修 bug 快、跨设备行为一致，不受碎片化拖累；后者只在涉及系统底层能力（ContentResolver、PackageManager、SensorManager 等，第 11 章）时才是唯一选择。

## 7. 与本套教程其他线的关系

本仓库（`G:\code\guide`）已有 Win32、MFC、WPF 三套 Windows 桌面教程，Android 线是它们的移动端对应物。几个核心概念可以对照着学，能省一半力气：

| 概念 | Windows 桌面线 | Android 线 |
|---|---|---|
| 声明式界面 | WPF XAML | Compose 函数（第 12 章） |
| 状态驱动的界面更新 | WPF 数据绑定 | Compose 状态与重组（第 12 章） |
| MVVM 架构 | WPF ViewModel + INPC | ViewModel + StateFlow（第 13 章） |
| UI 线程纪律 | Dispatcher | 主线程 + 协程（第 08 章） |
| 页面导航 | WPF 导航窗口 | Intent 与返回栈（第 06 章） |
| 列表的虚拟化 | ItemsControl | RecyclerView 与 Adapter（第 07 章） |
| C/C++ 互操作 | MFC/Win32 本身就是 C++ | JNI 与 NDK（第 14 章） |

最大的分野只有一条：桌面线里进程是你的，Android 线里进程是系统的。所有表格里看似平行的概念，落到代码里都带着这个前提的印记。

## 8. 本教程结构：15 章地图

| 章 | 文件 | 标题 | 一句话 |
|---|---|---|---|
| 01 | `01-overview.md` | Android 平台概述与架构 | 本章：平台全景与学习地图 |
| 02 | `02-project-toolchain.md` | 工程结构与构建工具链 | SDK、android.jar、Gradle、build.ps1 |
| 03 | `03-kotlin-for-android.md` | Kotlin for Android 必需子集 | 不系统学 Kotlin，够用就走 |
| 04 | `04-activity-lifecycle.md` | Activity 与应用生命周期 | 一个屏幕的生老病死 |
| 05 | `05-views-events.md` | 传统 View 体系：布局、控件与事件 | XML 布局与控件树的地基 |
| 06 | `06-intents-navigation.md` | Intent 与页面导航 | 组件间的消息与页面跳转 |
| 07 | `07-lists-adapters.md` | 列表与 Adapter 模式 | RecyclerView 与ViewHolder 回收复用 |
| 08 | `08-threads-network.md` | 线程、Handler 与网络请求 | 主线程禁令与异步的世界 |
| 09 | `09-data-storage.md` | 本地数据持久化 | SharedPreferences、文件与 Room |
| 10 | `10-system-components.md` | BroadcastReceiver、Service 与通知 | 无界面组件与系统级交互 |
| 11 | `11-permissions-content.md` | 运行时权限、ContentResolver 与硬件服务 | 敏感资源的中介模式 |
| 12 | `12-compose-basics.md` | Jetpack Compose 基础 | 声明式 UI 的心智模型 |
| 13 | `13-compose-architecture.md` | Compose 工程化架构 | 状态、导航与 ViewModel 分层 |
| 14 | `14-jni-ndk.md` | JNI 与 NDK | Kotlin 与 C/C++ 的边界 |
| 15 | `15-memopad.md` | 实战项目：MemoPad 便签应用 | 15 章知识串成一个完整应用 |

学习路线分四段：**地基**（01–03，平台与语言）→ **平台核心**（04–11，传统 View 体系与系统能力，占全书一半）→ **现代 UI**（12–13，Compose）→ **原生与实战**（14–15）。建议按序走，第 05 章开始的每个示例都值得动手改。

## 9. 本教程的验证体系

本教程代码分两层，验证方式也不同（忠实于 `android/build.ps1` 的实际行为）：

1. **`examples/` 下的单文件示例**（`01_hello_activity.kt` 等）：用 kotlinc 挂上 `android.jar` 做**静态编译验证**——确认 API 名称、参数、类型的用法真实无误
2. **`compose_examples/` Gradle 工程**：跑 `gradle :app:compileDebugKotlin` 验证完整工程配置与 Compose 代码可编译
3. **JNI 部分**：NDK + CMake 交叉编译验证 C++ 侧（详见第 14 章）

教学定位一句话：**API 与语法可信，运行需要真机**。所有正文里的 API 用法都通过了编译对账，不是凭记忆手写；但"编译通过"不等于"运行通过"——Android 程序的运行需要真实设备或模拟器，本教程不内置模拟器搭建流程。为什么只靠编译就能对账 API？答案是 `android.jar` 的特殊本质，这是第 02 章的主角。

两层验证的边界，一张表说清：

| 验证层 | 覆盖 | 不覆盖 |
|---|---|---|
| kotlinc + android.jar | API 存在性、签名、类型、语法 | 运行行为、资源打包、Manifest 登记是否齐全 |
| Gradle `:app:compileDebugKotlin` | 工程配置正确性、依赖解析、Compose 编译 | 布局实际观感、运行时崩溃、真机行为差异 |

所以读本书示例时请建立双重预期：代码里的 API 用法可以放心抄；运行效果需要你自己上真机验证——这也是学习的一部分，而不是负担。

## 10. 常见坑

**把 Android 当"换个 API 的桌面编程"**：最大的观念坑。没有"程序退出"的概念（只有退到后台），成员变量说没就没（进程随时可能被杀），任何需要跨启动保留的状态都必须落盘（第 09 章）。带着桌面直觉写，会在第 04 章到处碰壁。

**API Level 与版本号混淆**：Android 15 对应 API 35，Android 7.0 对应 API 24，两套数字并行。文档、`compileSdk`、`Build.VERSION` 说的都是 API Level，不是版本号。三个 SDK 值的辨析见第 02 章。

**学了 Compose 就想跳过 View 体系（或反过来死守 View）**：跳过 View 体系，你将读不懂存量代码与大量官方文档；死守 View 不学 Compose，新工程没有竞争力。正确姿势是本教程的顺序：先地基后现代。

**期待教程示例"双击就跑"**：本教程验证到编译级（见第 9 节）。要看运行效果，需要自备真机（开开发者模式 + USB 调试）或模拟器，并用 `adb install` 安装——这是教学定位的取舍，不是缺陷。

**以为 android.jar 是"Android 的类库实现"**：它只是编译对账用的空壳存根，拿到桌面 JVM 上一跑就抛 `Stub!` 异常。为什么如此设计、为什么反而成全了本教程的验证方式，详见第 02 章 [工程结构与构建工具链](02-project-toolchain.md)。

## 11. 实战建议

- 按章序走，前 11 章是层层依赖的地基，第 12 章起才进入 Compose；跳章学 Compose 会同时欠下生命周期与状态两笔债
- 尽早备一台开了开发者模式的真机或一个模拟器：第 04 章起，"跑起来看"与"编译过"的收获差一个量级
- 笔记分两栏记：**平台知识**（生命周期、权限、存储、进程）与 **UI 框架知识**（View/Compose）分开归档——换 UI 框架时只有一栏作废
- 查官方文档先看 API Level 标注：右上角的"Added in API level N"决定这个 API 在 minSdk 24 上能不能直接用
- 行为与预期不符时，按"生命周期 → 权限 → 线程 → UI"的顺序排查，前三者的命中率远高于 UI 本身
- 装一台系统版本较新的真机或模拟器做主要测试机，另一台贴近 minSdk 24 的旧设备做兼容抽查——两端各测一遍，胜过中间机型测十遍

---

下一章：[02 工程结构与构建工具链](02-project-toolchain.md)
