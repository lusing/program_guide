# 15 · JNI 与 NDK

> 对应示例：`examples/21_jni_bridge.kt`、`compose_examples/app/src/main/cpp/native-lib.cpp`

## 1. JNI 与 NDK 分别是什么

**JNI（Java Native Interface）** 是 Java/Kotlin 字节码世界与 C/C++ 原生世界之间的**边界协议**：函数按什么规则互相找到对方、类型怎么映射、字符串怎么跨界拷贝、引用归谁管。它比 Android 古老得多（JVM 时代就有），Android 完整继承。

**NDK（Native Development Kit）** 是一套**工具链集合**：clang 交叉编译器、bionic libc 与系统头文件（sysroot）、CMake 工具链文件、调试工具等。它回答"怎么把 `.cpp` 编译成 Android CPU 能执行的 `.so`"。

| | JNI | NDK |
|---|---|---|
| 本质 | 协议/规范 | 工具集 |
| 回答的问题 | 两个世界怎么对话 | 怎么产出对话的另一方 |
| 你写的代码 | `external fun` / `Java_` 函数 | `CMakeLists.txt`、`.cpp` |
| 门槛 | 会 Kotlin/Java 即可上手 | 还要懂 C/C++ 与交叉编译 |
| 变化频率 | 稳定（多年不变） | 随 SDK 版本更新 |

一句话：JNI 是合同，NDK 是施工队。Android 的 ART 运行时完整实现了 JNI，Kotlin 编译产物就是 JVM 字节码，所以 Kotlin 与 Java 在这条边界上地位完全等同——`external fun` 对应 Java 的 `native` 方法。

本仓库两处用到：`examples/21_jni_bridge.kt` 是 Kotlin 侧的最小声明（随 examples 链路做编译验证）；`compose_examples/app/src/main/cpp/` 是带 CMake 的完整 native 工程，被 Compose 界面消费——本章以后者为主线闭环。

## 2. 什么时候需要（以及默认不需要）

值得跨界的场合基本就三种：

- **复用现成 C/C++ 库**：openssl、ffmpeg、成熟的算法/协议库——用 Kotlin 重写既昂贵又容易丢正确性
- **极限性能**：音视频编解码、加密、物理仿真这类热点路径，native 实现常有数倍吞吐
- **更贴硬件/系统底层**：个别传感器/驱动接口只有 C 头文件可用

反忠告（观点）：**默认不需要**。普通应用的瓶颈几乎从不在"Kotlin 不够快"，而在网络、IO 与布局层级；把业务逻辑搬进 C++ 是双输——平白多出内存安全、类型边界、调试三重成本，换来的毫秒没人感知。正确次序是先用 profiler 拿到证据（[第 08 章](08-threads-network.md)的性能排查思路），再决定下潜。另外每个 ABI 一份 `.so`，包体积是真金白银。

快速判断表：

| 信号 | 建议 |
|---|---|
| 有现成 C/C++ 库，功能复杂 | 包装成薄 JNI 层复用 |
| profiler 证明热点在纯计算 | 评估 native 重写热点 |
| 只是"感觉 Kotlin 慢" | 先测量，别先下潜 |
| 想增加逆向成本 | 有一定效果，但别当主因立项 |

## 3. Kotlin 侧：loadLibrary 与 external fun

`examples/21_jni_bridge.kt` 全文：

```kotlin
package guide.android.examples

object Example21JniBridge {
    init {
        System.loadLibrary("guide_native")
    }

    external fun stringFromJNI(): String
}
```

Compose 工程里的 `compose_examples/app/src/main/java/guide/android/compose/jni/GuideNativeBridge.kt` 同构，只是包名不同：

```kotlin
package guide.android.compose.jni

object GuideNativeBridge {
    init {
        System.loadLibrary("guide_native")
    }

    external fun stringFromJNI(): String
}
```

三个要点：

- **`System.loadLibrary("guide_native")`**：按名字找 `libguide_native.so`（加载器自动补 `lib` 前缀与 `.so` 后缀），搜索路径包含 APK 内打包的 native 库目录；找不到就抛 `UnsatisfiedLinkError`。注意它匹配的是 **CMake target 名**（第 6 节），两处必须一致
- **`init` 块 + `object`**：object 首次被引用时执行 init——"用前必载、只载一次"，还省去了每个调用点手动 load
- **`external fun stringFromJNI(): String`**：只有声明没有函数体，Kotlin 编译器放行；调用时 JVM 按 JNI 命名规则去已加载的库里找对应符号（下一节）

一次完整调用的全景：

```text
Kotlin: GuideNativeBridge.stringFromJNI()
   │  JVM 在 libguide_native.so 里按 Java_ 前缀规则找符号
   ▼
C++:   Java_guide_android_compose_jni_GuideNativeBridge_stringFromJNI(JNIEnv*, jobject)
   │  env->NewStringUTF(...) 构造 jstring
   ▼
Kotlin: 拿到普通 String，照常使用
```

如实的边界说明：`21_jni_bridge.kt` 走 `build.ps1` 的 examples 链路只做**编译验证**（kotlinc 对着 `android.jar` 编过），`native-lib.cpp` 并没有实现它对应的符号；真正"声明—实现—打包—界面消费"全链路闭环的是 Compose 工程这一份。

## 4. C++ 侧：解剖一个 JNI 函数

`compose_examples/app/src/main/cpp/native-lib.cpp` 全文：

```cpp
#include <jni.h>
#include <string>

extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_GuideNativeBridge_stringFromJNI(JNIEnv* env, jobject) {
    std::string message = "hello from C++ JNI";
    return env->NewStringUTF(message.c_str());
}
```

逐片拆解：

| 片段 | 作用 |
|---|---|
| `extern "C"` | 关掉 C++ 名字修饰（name mangling），导出符号就是字面函数名——否则 JVM 按规则找不到 |
| `JNIEXPORT` / `JNICALL` | 可见性与调用约定宏，照抄即可 |
| 返回 `jstring` | JNI 类型系统里的字符串引用（第 5 节） |
| `JNIEnv* env` | native 环境指针，所有跨界操作的唯一把手 |
| 第二参数 `jobject` | 实例方法时就是调用者（相当于 this）；static 方法则是一个 `jclass` |

**命名规则**是 JNI 的寻址方式：

```text
Java_guide_android_compose_jni_GuideNativeBridge_stringFromJNI
 = Java_ + 包名(guide.android.compose.jni 的 . 换成 _) + _ + 类名 + _ + 方法名
```

Kotlin 侧改包名、挪类、改方法名，这串必须同步——编译器完全不检查，错位的代价是运行时 `UnsatisfiedLinkError`。方法重载还需要签名后缀或 `JNI_OnLoad` 动态注册，本教程不展开。

函数体两行：`std::string` 在 native 世界内部随便用；`env->NewStringUTF(message.c_str())` 是跨界最后一步——把 UTF-8 C 字符串包装成 `jstring` 返回给 Kotlin。返回的 `jstring` 归 GC 管，不需要（也不能）手动释放。

反方向（本示例没用到，但迟早会用到）：Kotlin 传 `String` 进 native 时，用 `env->GetStringUTFChars(jstr, nullptr)` 换出 `const char*`，**用完必须** `env->ReleaseStringUTFChars(jstr, chars)` 配对释放；基本类型数组是 `GetIntArrayElements` / `ReleaseIntArrayElements` 同款套路。

两个容易忽略的事实：JNI 函数在**调用者线程**上执行——Kotlin 侧在哪个线程调，C++ 就在哪个线程跑，线程安全要自己管；`jobject` 等引用只在本次调用期间有效，想跨调用持有需经 `env` 创建全局引用（本教程不展开）。

## 5. 类型映射表

| Kotlin/Java | JNI 类型 | 备注 |
|---|---|---|
| `Int` | `jint` | 32 位（`int32_t`），别拿 C `int` 的"平台相关宽度"含糊 |
| `Long` | `jlong` | 64 位 |
| `Boolean` | `jboolean` | 8 位无符号整数（0/1），不是 C 的 `bool` |
| `Float` / `Double` | `jfloat` / `jdouble` | IEEE 754，直接对应 |
| `String` | `jstring` | 引用类型，**不是** `char*`，跨界必须转换 |
| `IntArray` | `jintArray` | 每种基本类型数组各一款（`jbyteArray`…） |
| 任意对象 | `jobject` | 引用类型的通用容器 |
| `Unit` 返回 | `void` | |

规则一句话：基本类型按位宽一一对应，直接传值；引用类型（String/数组/对象）都是不透明句柄，必须经 `env` 的转换函数才能碰内部数据。

映射之外的两个"非类型"差异：Kotlin 的可空性不会跨边界检查（`null` 到 native 侧就是空句柄，解引用即崩）；对象数组（如 `Array<String>`）是 `jobjectArray`，逐元素用 `GetObjectArrayElement` 取。二进制大数据优先 `ByteArray`（`jbyteArray`），一次跨界、一批转换。

## 6. 构建：CMakeLists 与 Gradle 联动

`compose_examples/app/src/main/cpp/CMakeLists.txt` 全文：

```cmake
cmake_minimum_required(VERSION 3.22.1)
project(guide_native)

add_library(
    guide_native
    SHARED
    native-lib.cpp
)

find_library(log-lib log)
target_link_libraries(guide_native ${log-lib})
```

- `cmake_minimum_required(VERSION 3.22.1)`：与 SDK 自带 CMake/NDK 工具链的最低要求对齐
- `add_library(guide_native SHARED native-lib.cpp)`：声明一个共享库 target，产物是 `libguide_native.so`——**这个名字同时是 Kotlin 侧 `loadLibrary("guide_native")` 的锚点**
- `find_library(log-lib log)` + `target_link_libraries`：找到并链接 Android 系统 log 库（本示例没打日志，链上是给真实工程留的位置）

Gradle 侧的联动在 `app/build.gradle.kts`（连接[第 02 章](02-project-toolchain.md)的构建体系）：

```kotlin
android {
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
        }
    }
}
```

AGP 看到 `externalNativeBuild` 就会用 SDK 目录里的 CMake + NDK 工具链，为每个目标 ABI 交叉编译，产物打进 APK 的 `lib/<abi>/`。本工程 `defaultConfig` 没写 `abiFilters`，默认构建全部 ABI（`armeabi-v7a` / `arm64-v8a` / `x86` / `x86_64`）；只想覆盖部分设备时加 `abiFilters += listOf("arm64-v8a", "x86_64")` 瘦身。

另一种常见形态：拿到的是别人编译好的 `.so`（没有源码），直接放进 `app/src/main/jniLibs/<abi>/` 就能被 `loadLibrary` 找到，不需要 `externalNativeBuild`。两种来源二选一，别把同一个库既编又拷、重复打包。

本仓库 `build.ps1 -Jni` 手工复刻了同一条链，便于脱离 Gradle 验证 native 编译：取 SDK 下 NDK `30.0.15729638` 的 `build/cmake/android.toolchain.cmake` 作交叉工具链，`-DANDROID_ABI=arm64-v8a`、`-DANDROID_PLATFORM=android-24`（对应 minSdk 24），用 Ninja 在 `build/jni` 下产出 `libguide_native.so`。等价命令（`build.ps1` 内部即此流程）：

```powershell
cmake -G Ninja -S app/src/main/cpp -B build/jni `
    -DANDROID_ABI=arm64-v8a `
    -DANDROID_PLATFORM=android-24 `
    -DCMAKE_TOOLCHAIN_FILE=<ndk>/build/cmake/android.toolchain.cmake `
    -DANDROID_NDK=<ndk>
cmake --build build/jni      # 产出 build/jni/libguide_native.so
```

两条链的分工：AGP 模式的 `.so` 自动进 APK，开发调试用；`-Jni` 模式只验证 native 能否编过，产物留在 `build/jni`，适合当快速冒烟。想确认 APK 里到底打了哪些库，解包看 `lib/<abi>/` 目录有没有 `libguide_native.so`。

## 7. Compose 消费：把 JNI 结果显示到界面

`ComposeSamples.kt` 里的 `JniStatusSample`：

```kotlin
@Composable
fun JniStatusSample() {
    val nativeMessage = remember { GuideNativeBridge.stringFromJNI() }
    Text(
        text = "JNI 示例：$nativeMessage",
        modifier = Modifier.padding(vertical = 8.dp)
    )
}
```

- **`remember { ... }` 是关键**：首次组合时调用一次 native 并缓存；后续重组直接复用。去掉 `remember`，每次重组都会跨一次 JNI 边界——这里虽然便宜，习惯不能养成
- 库的加载时机也在这条链上：首次访问 `GuideNativeBridge` 触发 object 的 `init`（即 `loadLibrary`），恰好发生在首次组合执行 `remember` lambda 那一刻；加载一次后，后续调用直接走已解析的符号
- 边界在 UI 层的姿态：JNI 结果就是普通 `String`，Compose 不关心它从哪来。重的 native 调用应放进 ViewModel 或协程后台（[第 14 章](14-compose-architecture.md)的分工），回到 UI 的永远是现成的状态

顺带一个运行期自查：如果这个示例在设备上闪退并报 `UnsatisfiedLinkError`，先查两件事——APK 里有没有该设备 ABI 的 `libguide_native.so`，以及 `loadLibrary` 名字与 `add_library` 的 target 是否一致（第 8 节的完整排查）。

这也演示了跨章知识的合流：C++ 产出 → JNI 跨界 → Kotlin object 持有 → Compose 状态消费，四段各管各的。

## 8. 常见坑

**loadLibrary 名字与 CMake target 不一致**：`System.loadLibrary("guide_native")` 找的是 `libguide_native.so`，而 `.so` 名由 `add_library` 的第一个参数决定——两处任何一个改了没同步，启动即 `UnsatisfiedLinkError`。本工程两处都叫 `guide_native`。

**native 方法名与包名不匹配**：Kotlin 侧重命名/挪包后，`Java_guide_android_compose_jni_GuideNativeBridge_stringFromJNI` 这串没跟着改。编译期零提示，运行期才炸。改包名时把 C++ 侧函数名当作"包名的镜像"一起改。

**jstring 当 `char*` 直接用**：`jstring` 是不透明引用，传给 `strlen`/`printf` 编译都过不了；必须先 `GetStringUTFChars` 转换。反过来，`char*` 也不能直接当返回值，要 `NewStringUTF` 包装。

**忘 ReleaseStringUTFChars**：`GetStringUTFChars` 可能内部拷贝一份（取决于 `isCopy`），不 `Release` 就泄漏。注意方向：**读入**的（GetString 系）要手动释放；**New 出来的返回值**归 GC，不要画蛇添足。

**ABI 缺失**：模拟器通常是 `x86_64`，真机多为 `arm64-v8a`；某个 ABI 没有对应 `.so`，安装或运行就 `UnsatisfiedLinkError`。`abiFilters`、测试设备、CI 构建矩阵三处要对齐。

**忘 `extern "C"`**：C++ 编译器默认做名字修饰，导出符号变成 `_Z34Java_...` 之类的乱码，与 JNI 命名规则对不上，照样 `UnsatisfiedLinkError`。每个导出函数前都要带，示例里的 `extern "C" JNIEXPORT jstring JNICALL` 是固定三件套。

## 9. 实战建议

- 边界设计得**薄**：native API 做成少量高内聚函数（字符串进/出、`ByteArray` 传二进制），别让对象图漏过边界
- JNI 函数名与 Kotlin 声明一一对应，改包名/方法名时把 C++ 侧当镜像同步；重载能不玩就不玩
- 大块数据用 `ByteArray` / `ByteBuffer` 一次跨界，别在循环里逐个传字符串
- 联调期盯 logcat 里的 `UnsatisfiedLinkError` 详情："找不到库"（名字/ABI 问题）与"找不到符号"（命名/修饰问题）是两类病因，先分型再排查
- 保持两侧文件的镜像认知：`jni/GuideNativeBridge.kt` 对应 `cpp/native-lib.cpp`，包名/方法名改动必须两边同步评审
- 引第三方 native 库时，优先找官方预编译的 AAR（内含各 ABI 的 `.so`），自己维护源码交叉编译是最后手段
- 构建验证用 `.\build.ps1 -Jni`（纯 native 编译）与 `.\build.ps1 -Compose`（整工程含 JNI 打包链），见[第 02 章](02-project-toolchain.md)
- 模拟器（x86_64）与真机（arm64-v8a）各装一次，`JniStatusSample` 十秒钟就能确认 ABI 覆盖与链路通断
- 第 16 章实战项目是纯 Kotlin，不需要 JNI——本章的定位是"看得懂现有 native 集成、接得上真实项目"，不是"天天写"

---
上一章：[14 Compose 工程化架构](14-compose-architecture.md) ｜ 下一章：[16 实战项目：MemoPad 便签应用](16-memopad.md)
