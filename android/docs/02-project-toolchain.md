# 02 · 工程结构与构建工具链

> 对应示例：`examples/01_hello_activity.kt`、`compose_examples/` Gradle 工程

## 1. 为什么用命令行学 Android

Android Studio 的"New Project"向导很贴心：选个模板，三十多个文件、三层 Gradle 配置、一堆自动生成的资源就位，点运行就能看到 Hello World。但它同时遮蔽了三个最该在第一天搞清的问题：

1. 一个 Android 应用**最少**需要什么？
2. `android.jar` 是什么，为什么编译离不开它？
3. Gradle 配置里那一堆 `compileSdk`、`namespace`、`buildFeatures` 各管什么？

本教程的回答是把变量降到最少，用两级验证体系教学（忠实于 `android/build.ps1` 的实际行为）：

| 层 | 位置 | 验证方式 | 验证什么 |
|---|---|---|---|
| 单文件示例 | `examples/*.kt` | kotlinc + `android.jar` 静态编译 | API 与语法用法 |
| Gradle 工程 | `compose_examples/` | `gradle :app:compileDebugKotlin` | 真实工程配置与 Compose 代码 |
| JNI 原生 | `compose_examples/app/src/main/cpp/` | NDK + CMake 交叉编译 | C++ 侧可编译（详见第 14 章 [JNI 与 NDK](14-jni-ndk.md)） |

命令行学 Android 不是苦行，而是把"编译一个 Activity 到底需要什么"变成一个可以亲手验证的问题。等你再打开 Android Studio，向导生成的每个文件都能对上号。

## 2. 本机工具链一览

本教程所有构建都由 `android/build.ps1` 驱动，它引用的本机工具链如下：

| 组件 | 路径 | 角色 |
|---|---|---|
| Android SDK | `G:\android` | 平台存根、构建工具、NDK 的总目录 |
| Kotlin 编译器 | `G:\scoop\apps\kotlin\current\bin\kotlinc.bat` | 编译 `examples/` 单文件示例 |
| Gradle | `G:\scoop\apps\gradle\current\bin\gradle.bat` | 编译 `compose_examples/` 工程 |
| JDK（Java 17） | `G:\scoop\apps\openjdk\current` | Gradle 与 kotlinc 的运行底座 |

脚本启动时先设两个环境变量再干活：`JAVA_HOME` 指向 JDK 目录，`ANDROID_SDK_ROOT` 指向 SDK 目录——AGP 8.x 找不到这两样会直接罢工，这是新手第一高频报错。

## 3. SDK 目录解剖

`G:\android` 是 Android SDK（Software Development Kit）的根，常用子目录各有分工：

| 目录 | 内容 | 本教程用途 |
|---|---|---|
| `platforms/android-37.1/android.jar` | 当前最高平台 API 的**编译期存根**（下一节的主角） | kotlinc 的 `-classpath` |
| `build-tools/` | 打包工具链：aapt2（编译打包资源）、d8（字节码转 dex）、R8（混淆收缩）、apksigner（签名）、zipalign（对齐优化） | 由 AGP 在 Gradle 构建中内部调用 |
| `platform-tools/` | `adb`（Android Debug Bridge，设备桥）、fastboot（刷机） | 装应用到真机、看日志 |
| `ndk/30.0.15729638/` | C/C++ 交叉编译工具链（clang 等，按 ABI 产出 `.so`） | 第 14 章、`-Jni` 开关 |
| `cmake/` | CMake + Ninja，NDK 官方推荐的原生构建前端 | `-Jni` 开关 |

`build-tools` 里那串工具值得记一遍接力顺序：**.kt/.java →(kotlinc/javac)→ .class →(d8)→ .dex →(aapt2)→ 打包资源 →(apksigner)→ 可安装 APK**。本教程的静态验证只走第一棒；后面几棒由 Gradle 流水线自动完成。`adb` 则是联调期的瑞士军刀：`adb install xxx.apk` 装应用、`adb logcat` 看运行日志，第 04 章起会反复用到。

## 4. android.jar 的本质：编译对账用的存根

`platforms/` 下每个平台目录各有一份 `android.jar`（`build.ps1` 自动选中 API 最高的 `android-37.1`，约 42 MB），解压开能看到 `android.app.Activity`、`android.widget.TextView` 等所有平台类的 class 文件——但每个方法的实现都是同一个形态：

```java
// android.jar 中方法的真实形态（示意）
public void setContentView(View view) {
    throw new RuntimeException("Stub!");
}
```

也就是说，`android.jar` 是一份**签名真实、实现为空**的接口对账文件（stub，存根）。它存在的意义是让编译器回答三个问题：这个类存在吗？这个方法叫什么？参数和返回类型是什么？至于方法体，运行时由设备上的系统框架提供——设备出厂时就带着真正的实现。

这个设计思想与 .NET 的引用程序集（reference assembly）同源：编译期给"目录"，运行期换"实体"。理解了这一点，两件事同时得到解释：

1. **为什么 `build.ps1` 能做静态验证**：编译只需要签名对账，不需要实现。kotlinc 挂上 `android.jar`，就能严格检查你的 API 用法是否真实存在、类型是否匹配——这正是本教程"API 与语法可信"承诺的机制基础
2. **为什么不能拿 `android.jar` 在桌面 JVM 上跑 Android 程序**：类都在，一调方法就抛 `Stub!`。Android 程序只能跑在 Android 运行时上，没有捷径

另外注意版本对应：`build.ps1` 自动扫 `platforms/` 下所有 `android-*` 目录，选 API 最高的那个 `android.jar`（写作时为 `android-37.1`，API 37）。SDK 升级装了新平台后，脚本无需修改。它与 Compose 工程显式声明的 `compileSdk = 35` 并不冲突：examples 只做静态对账，存根略新只会让检查更严，不会引入运行时差异；真实工程则必须钉住 compileSdk 以保证行为可复现。

## 5. 最小 Android 程序长什么样

`examples/01_hello_activity.kt` 全文，14 行：

```kotlin
package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.widget.TextView

class Example01HelloActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val textView = TextView(this)
        textView.text = "Hello Android Kotlin"
        setContentView(textView)
    }
}
```

与桌面的"最小程序"对照着看，三个本质差异：

- **没有 `main` 函数**：Activity 是被系统回调的组件（第 01 章的"入口点"概念），`onCreate` 就是它的出生证明。生命周期回调的完整体系见第 04 章 [Activity 与应用生命周期](04-activity-lifecycle.md)
- **界面是代码建出来的控件树**：`TextView(this)` 创建控件，`setContentView` 把它挂到窗口——等价于桌面框架的"创建主窗口并显示"。XML 布局的写法见第 05 章 [传统 View 体系：布局、控件与事件](05-views-events.md)
- **一个 Activity 一个类**：不需要工程、不需要资源配置，一个 `.kt` 文件就是一个可讲授的知识单元——这正是本教程采用单文件示例的原因

验证它的编译（在 PowerShell 中）：

```powershell
cd G:\code\guide\android
.\build.ps1 -File 01_hello_activity.kt
```

`build.ps1` 实际执行的命令是：

```text
kotlinc -jvm-target 1.8 -classpath G:\android\platforms\android-37.1\android.jar \
        -d build\classes\01_hello_activity 01_hello_activity.kt
```

产出 `.class` 文件（JVM 字节码）。离"能安装的 APK"还差 d8 转 dex、aapt2 打包、签名三步，外加一份 `AndroidManifest.xml` 把这个类登记为组件——本教程的验证停在第一棒（编译对账），后几棒在 Gradle 工程里由流水线完成。

## 6. Gradle 工程解剖：compose_examples 标本

真实 Android 工程绕不开 Gradle——官方构建系统，负责依赖解析、资源合并、多变体打包。本教程的标本是 `compose_examples/`，目录骨架：

```text
compose_examples/
├── settings.gradle.kts        # 工程范围：模块清单与仓库
├── build.gradle.kts           # 根构建脚本：插件版本统一声明
└── app/                       # 唯一的模块
    ├── build.gradle.kts       # 模块配置：SDK 值、依赖、原生构建
    └── src/main/
        ├── AndroidManifest.xml
        ├── java/guide/android/compose/samples/   # Kotlin 源码
        └── cpp/native-lib.cpp                    # JNI 源码 + CMakeLists.txt
```

### settings.gradle.kts：工程的大门

```kotlin
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

rootProject.name = "compose_examples"
include(":app")
```

三件事：**解析插件去哪找**（google 仓放 Android/Compose 插件，mavenCentral 放通用库，gradlePluginPortal 是 Gradle 官方插件仓）；**解析依赖去哪找**——`FAIL_ON_PROJECT_REPOS` 是个好约束，禁止模块私设仓库，仓库必须集中声明在此；**工程叫什么、有哪些模块**（本工程只有一个 `:app` 模块）。

### 根 build.gradle.kts：版本只说一遍

```kotlin
plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.21" apply false
}
```

三个插件，`apply false` 表示"根工程只锁定版本，不启用"，真正的启用在各模块里。注意第三个：Kotlin 2.0 起 Compose 编译器**随 Kotlin 编译器版本走**（两者版本号一致，都是 2.0.21），旧教程里单独配置的 `composeOptions.kotlinCompilerExtensionVersion` 已成为历史——照抄旧代码会踩坑。

### app/build.gradle.kts：一行行说清

```kotlin
android {
    namespace = "guide.android.compose"     // 代码包名：R 类与 Manifest 合并的基准
    compileSdk = 35                        // 用 API 35 的 android.jar 编译

    defaultConfig {
        applicationId = "guide.android.compose"  // 安装后的唯一应用 ID
        minSdk = 24                        // 最低跑在 Android 7.0
        targetSdk = 35                     // 声明"已按 API 35 的行为适配"
        versionCode = 1                    // 内部版本号（整数，升级用）
        versionName = "1.0"                // 给人看的版本号
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false        // 发布版不混淆（教学工程从简）
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17   // Java 源码/字节码级别
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true                     // 启用 Compose 编译管线
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")  // JNI 构建入口，第 14 章
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)    // Kotlin 编译目标与 Java 侧对齐
    }
}
```

初学者最迷糊的三个 SDK 值，一张表说清：

| 值 | 回答的问题 | 改动的后果 |
|---|---|---|
| `minSdk = 24` | 最低安装到哪个系统版本 | 决定能直接用哪些 API（低于下限的要么不用，要么写版本分支）；`build.ps1` 的 JNI 开关 `-DANDROID_PLATFORM=android-24` 与它刻意对齐 |
| `targetSdk = 35` | 声明适配到哪个版本的行为 | 影响系统兼容开关：运行时权限（6.0）、分区存储（10）、通知权限（13）等新行为只对 target 够高的应用生效 |
| `compileSdk = 35` | 用哪个版本的 `android.jar` 编译 | 必须 ≥ targetSdk；想用新 API 就得先升它 |

一句话记忆：**minSdk 对用户负责，targetSdk 对系统负责，compileSdk 对编译器负责**。

### 依赖清单

`dependencies` 块的版本表（与真实文件一致，后续章节逐一展开）：

| 依赖 | 版本 | 用途 | 详见 |
|---|---|---|---|
| `androidx.core:core-ktx` | 1.15.0 | 核心 KTX 扩展（`postDelayed`、`SharedPreferences` 等的 Kotlin 化封装） | 第 03/08 章 |
| `androidx.activity:activity-compose` | 1.10.1 | 在 Compose 中以托管方式使用 Activity | 第 12 章 [Jetpack Compose 基础](12-compose-basics.md) |
| `androidx.compose.ui:ui` | 1.7.8 | Compose UI 核心（组合、布局、绘制） | 第 12 章 |
| `androidx.compose.material3:material3` | 1.3.1 | Material 3 组件库 | 第 12 章 |
| `androidx.compose.ui:ui-tooling-preview` | 1.7.8 | `@Preview` 预览支持 | 第 12 章 |
| `androidx.lifecycle:lifecycle-viewmodel-compose` | 2.8.7 | ViewModel 接入 Compose | 第 13 章 [Compose 工程化架构](13-compose-architecture.md) |
| `androidx.navigation:navigation-compose` | 2.8.5 | Compose 页面导航 | 第 13 章 |
| `androidx.room:room-runtime` / `room-ktx` | 2.6.1 | SQLite ORM 持久化 | 第 09 章 [本地数据持久化](09-data-storage.md) |
| `androidx.work:work-runtime-ktx` | 2.10.0 | 可约束的后台任务调度 | 第 10 章 [BroadcastReceiver、Service 与通知](10-system-components.md) |
| `kotlinx-coroutines-android` | 1.9.0 | 协程与主线程调度器 | 第 08 章 [线程、Handler 与网络请求](08-threads-network.md) |
| `ui-tooling`（debugImplementation） | 1.7.8 | 仅调试期生效的工具实现 | 第 12 章 |

注意最后一条的 `debugImplementation`：工具类依赖只进 debug 变体、不进 release 包，这是依赖作用域（configuration）的最常见用法。

## 7. AndroidManifest.xml：应用唯一清单

每个 Android 应用必须且只能有一份 `AndroidManifest.xml`，它是应用对系统的**自我申报表**：我有哪些组件、要什么权限、入口在哪。`compose_examples` 的清单全貌：

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="true"
        android:label="ComposeExamples"
        android:supportsRtl="true">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

四个要点：

- **根元素没有 `package="..."` 属性**。AGP 8 起包名职责移交 Gradle 的 `namespace`（见上节），旧教程在 Manifest 里写 package 属性会直接构建失败
- **四大组件必须在此登记**（第 01 章的规矩落地处）：`android:name=".MainActivity"` 的前导点表示相对 `namespace` 补全
- **`exported="true"` + MAIN/LAUNCHER intent-filter = 桌面图标入口**。exported 声明"允许外部应用启动我"，从 Android 12 起带 intent-filter 的组件必须显式声明它
- **权限声明也在这里**（`<uses-permission>`，本教学工程未申请任何权限；运行时申请机制见第 11 章 [运行时权限、ContentResolver 与硬件服务](11-permissions-content.md)）

对照第 5 节的单文件示例：`Example01HelloActivity` 若要变成可运行应用，只差在某个应用的 Manifest 里加一条 `<activity>` 声明——类与登记，缺一不可。

## 8. build.ps1：四个开关

`build.ps1` 是本教程的构建入口，五种用法：

| 命令 | 做什么 |
|---|---|
| `.\build.ps1 -All` | 依次执行：`examples/` 全部 `.kt` 单文件编译 → Compose 工程 Gradle 编译 → JNI 交叉编译，全绿才算过 |
| `.\build.ps1 -File 01_hello_activity.kt` | 单文件 kotlinc 编译验证（改完一个示例最快的手感回路） |
| `.\build.ps1 -Compose` | `gradle -p compose_examples --no-daemon --warning-mode none clean :app:compileDebugKotlin` |
| `.\build.ps1 -Jni` | CMake(Ninja) 配置并构建 JNI：`arm64-v8a` + `android-24`，工具链取 `ndk/30.0.15729638` |
| `.\build.ps1 -Clean` | 删除 `build/` 输出目录 |

两个"为什么"：

- **为什么 Compose 必须走 Gradle 而不能像 examples 那样单文件？** Compose 的 `@Composable` 函数需要编译器插件在编译管线里做代码变换，`androidx` 依赖也要从远程仓库解析——这两样 kotlinc 裸调给不了，只有完整 Gradle 工程能提供
- **为什么 `-Jni` 指定 `ANDROID_PLATFORM=android-24`？** 与 `minSdk = 24` 对齐。NDK 的平台版本决定链接期可用的 libc 等系统库符号下限，高过低配会在老设备上加载失败——两处版本应视为同一决策的两面

## 9. 常见坑

**在桌面 JVM 上运行"编译通过"的 Android 代码**：`android.jar` 是存根（第 4 节），桌面 JVM 上调用任何平台 API 都抛 `RuntimeException("Stub!")`。"编译过了"与"能运行"之间隔着设备、Manifest、打包与签名。

**三个 SDK 值当同一个东西改**：`compileSdk` 低于 `targetSdk` 直接构建报错；只升 `targetSdk` 不回归测试更隐蔽——运行时权限、分区存储、通知权限等行为开关会悄悄翻转。升级 targetSdk 前先读官方行为变更文档。

**namespace / applicationId / Manifest package 三者混淆**：`namespace` 管 R 类与代码包名，`applicationId` 管安装后的唯一身份（两者可以不同，比如免费版/专业版共用代码）；Manifest 的 `package` 属性在 AGP 8 已废除。照抄 2022 年前的教程会踩这个坑。

**JDK 版本不对**：AGP 8.7 要求 JDK 17，`JAVA_HOME` 指向 8 或 11 时 Gradle 直接失败。`build.ps1` 已强制设 `JAVA_HOME` 为 `G:\scoop\apps\openjdk\current`，自己开终端手动跑 Gradle 时要记得同样设置。

**把首次 Gradle 构建的漫长等待当故障**：第一次 `gradle :app:compileDebugKotlin` 要从 `google()`/`mavenCentral()` 联网拉全部依赖，加上 `--no-daemon` 每次冷启动 JVM，十几分钟属正常。之后依赖进了本地缓存（`~/.gradle/caches`）才会快起来。

**改了 `build.ps1` 的 android.jar 选择逻辑**：脚本选"API 最高"的 `android.jar` 是刻意的——永远用最新存根编译，与 `compileSdk` 语义一致。手动锁死旧版本反而制造 examples 与 Compose 工程的对账偏差。

## 10. 实战建议

- 学习回路固定为：读一章 → `.\build.ps1 -File <对应示例>` → 改示例里的参数/API 再编译，让编译器当第一任老师
- 每次跑 `-Compose` 前后对照 `app/build.gradle.kts` 的注释逐行回想用途，三遍之后 Gradle 工程对你不再有魔法
- 升级依赖一次只动一个版本号，编译通过后再动下一个——多版本同升时报错无法归因
- 把 `minSdk` 与 NDK 的 `ANDROID_PLATFORM` 当成同一决策维护，改一处查另一处
- 好奇时把 `android.jar` 当 zip 解开看看：浏览 `android/app/Activity.class` 的存在本身就是第 4 节"存根"概念最直观的注脚
- 真机联调常备 `adb devices`（确认连接）与 `adb logcat`（看崩溃栈），第 04 章起它们是标准装备

---

上一章：[01 Android 平台概述与架构](01-overview.md) ｜ 下一章：[03 Kotlin for Android 必需子集](03-kotlin-for-android.md)
