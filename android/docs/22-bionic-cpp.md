# 22 · Bionic 与 C++ 标准库

> 对应示例：`compose_examples/app/src/main/cpp/bionic_samples.cpp` + `jni/BionicBridge.kt`（Compose 消费层在 `samples/JniSamples.kt`）

## 1. Bionic：Android 自己的 libc

第 01 章的分层图里"原生库 + ART"那一层，垫在 C/C++ 代码脚下的是一个叫 **Bionic** 的东西——Android 平台的 C 标准库实现。`malloc`/`fopen`/`socket`/`pthread` 这些名字都是它提供的。

为什么放着现成的 glibc 不用另造一个？原书 6.2 节给了三条理由，2026 年依然成立：

| 动机 | 说明 |
|---|---|
| 许可 | glibc 是 LGPL，Bionic 是 BSD 系——对硬件厂商闭源定制友好 |
| 体积 | glibc 面向桌面，Bionic 刻意精简，适合移动设备 |
| 定制 | 线程/进程/信号处理针对 Linux 内核与 Android 的使用方式定制 |

代价是 **Bionic 不完整也不追求完整**：部分 glibc 扩展没有、部分 POSIX 函数缺席、`pthread` 实现细节不同（第 23 章）。从 Linux 移植 C 代码，"在 glibc 上能编"不等于"在 Bionic 上能编"——缺什么查 NDK 文档的 stable API 列表，或直接在 sysroot 头文件里找。

## 2. 系统配置与系统属性

`sysconf` 查运行时配置，`bionicPageSize`/`bionicCpuCount` 一行一个：

```cpp
long page = sysconf(_SC_PAGESIZE);        // 内存页大小（4KB 时代居多）
int cpus = sysconf(_SC_NPROCESSORS_CONF); // 系统配置的 CPU 数
```

**系统属性**（`bionicSdkProp`）是 Bionic 的 Android 特色扩展——整个系统的键值仓库，`getprop` 命令读的就是它：

```cpp
char value[PROP_VALUE_MAX] = {0};
__system_property_get("ro.build.version.sdk", value);
```

`ro.` 前缀 = readonly，启动时定死；常见键还有 `ro.product.model`（机型）、`ro.build.version.release`（版本号）。Kotlin 侧的 `Build.VERSION.SDK_INT` 最终读的也是这仓库。**属性读可以，写不行**——`persist.` 开头的属性也只有系统进程能改，应用侧它是只读信息源。

## 3. 用户与组：沙箱身份自证

第 01 章说过"每个应用一个 UID"，`bionicUidInfo` 让你在 native 侧亲眼看到这个数字：

```cpp
uid_t uid = getuid();
gid_t gid = getgid();
struct passwd* pw = getpwuid(uid);   // 查不到用户名时返回 nullptr，要判空
```

安装时系统给应用分配的 Linux UID（通常 10000 以上，`u0_aNNN`），所有沙箱权限判断都以它为锚。`getpwuid` 在 Bionic 上实现简陋（Android 没有 `/etc/passwd` 的完整等价物），查不到就返回 null——这也是 Bionic 与 glibc 行为差异的一个小样本。

## 4. 内存：三个世界的手递手

native 世界的动态内存两套 API 并存：

```cpp
void* p = malloc(1024);  free(p);        // C 世界
auto* v = new std::vector<int>(100);     // C++ 世界：new 连构造函数一起管
delete v;                                // delete 先跑析构再释放
```

原书 6.3.3 的建议照旧：C++ 对象用 `new`/`delete`（类型敏感、管构造析构），`malloc`/`free` 留给纯 C 数据和第 21 章的直接 ByteBuffer；运行期变长优先 STL 容器（`vector` 自己管理增长），别手搓 realloc。

真正要建立的是**三个内存世界的地图**：

| 世界 | 分配者 | 回收者 | 泄漏表现 |
|---|---|---|---|
| Java/Kotlin 堆 | `new`/`mutableStateOf` | GC 自动 | LeakCanary / heap dump 可见 |
| native 堆 | `malloc`/`new` | **你，手动** | Java 堆正常，进程 RSS 涨 |
| JNI 引用 | `NewGlobalRef` | `DeleteGlobalRef`（你） | 对象永远不可回收 |

第 21 章的直接 ByteBuffer 在此对号入座：它就是"native 堆的内存借了个 Java 马甲"。三个世界的泄漏症状与排查工具各不相同，混着用会互相掩护。

## 5. 标准 C 文件 I/O：FILE* 全家桶

`bionicFileRoundTrip` 走一遍 `fopen`/`fwrite`/`fread`/`fclose` 闭环（原书 6.4 节整套函数的原型舞台）：

```cpp
FILE* out = fopen(pathChars, "wb");          // 打开（"wb" 二进制写）
size_t written = fwrite(contentChars, 1, len, out);
fclose(out);                                  // 检查返回值——磁盘满的错在这暴露

FILE* in = fopen(pathChars, "rb");
size_t got = fread(buf, 1, sizeof(buf) - 1, in);
buf[got] = '\0';
fclose(in);
```

三个 Android 特色认知：

- **path 必须来自 Kotlin 侧**：`context.filesDir` 下的路径（第 09 章内部存储）。native 没有 `Context`，也无权碰应用沙箱之外——分区存储（第 09 章）的约束对 C 代码同样生效，内核看的是 UID，不看语言
- **printf 没有出口**：Android 应用的 stdout/stderr 不接任何控制台。调试输出去 logcat（第 20 章第 8 节），正式日志走文件。原书 6.4.1 的"标准流"在应用层是半残的——`stderr` 在某些系统版本会转投 logcat，但别依赖
- 与 Kotlin `File` API 双轨并存：同一文件谁都可以读写，编码与并发要自己协调

## 6. C++ 运行库：从三国杀到一统

原书第 11 章整章讲当年选 C++ 运行库的纠结——**这些纠结已成历史，但历史要读懂**，因为老代码和老文档里全是这些名字：

| 运行库 | STL | 异常 | RTTI | 状态（2026） |
|---|---|---|---|---|
| system | ✗ | ✗ | ✗ | 仍在（`none`），等于裸 C++ |
| GAbi++ | ✗ | ✗ | ✓ | r17 起移除 |
| STLport | ✓ | ✗ | ✓ | r17 起移除 |
| GNU STL（gnustl） | ✓ | ✓ | ✓ | **r18 起移除** |
| **libc++（c++_static/c++_shared）** | ✓ | ✓ | ✓ | **现役唯一全家桶** |

当年的仪式感：`Application.mk` 里 `APP_STL := gnustl_shared`，异常还要 `APP_CPPFLAGS += -fexceptions`、RTTI 要 `-frtti` 显式开启（原书 11.4/11.5 节各有一整节）。今天 CMake 时代：

```kotlin
android {
    defaultConfig {
        externalNativeBuild { cmake { arguments += "-DANDROID_STL=c++_shared" } }
    }
}
```

且 **libc++ 下异常与 RTTI 默认开启**——`bionicCppFeatures` 用 try/catch + `dynamic_cast` + `typeid` 三个探针当场验证（编译通过即证明，运行返回的字符串是给自己看的）。

**c++_static 还是 c++_shared**（原书 11.3 的现代版）：

- 单个 `.so`、想省事 → `c++_static`（链进各自的库，互不影响）
- 多个 `.so` 共用 C++ 类型跨库传递（异常、STL 容器过边界）→ **必须** `c++_shared`，且整个应用只允许一份——两个库各链一份 static、又跨库传 `std::string`，是教科书级的一类崩溃（各养各的 RTTI/异常/堆，对象在边界两边被判成不同类型）
- 本工程只有一个 `libguide_native.so`，默认（static）即可

STL 本体（容器/迭代器/算法，原书 11.6 的分类速览）不单独展开——它就是标准 C++，与平台无关。`bionicSortDoubles` 是最小样张：`std::vector` + `std::sort` 在 JNI 边界两边各做一次转换。线程安全一句记住（原书 11.7）：**多线程同时读容器安全，有写就得你自己加锁**——跨语言也不会好半分。

原书 11.8 的运行库调试模式（`_GLIBCXX_DEBUG`、STLport `_STLP_DEBUG`）对应今天 libc++ 的 `_LIBCPP_ENABLE_ASSERTIONS=1`（CMake 侧 `ANDROID_CPP_FEATURES` 之外的一个 C++ 定义），调试期开着抓迭代器误用，发布关掉换性能。

## 7. 常见坑

**glibc 惯例直接搬**：非标准函数（`strerror_r` 的 GNU 变体、`__libc` 系列）、`/etc/passwd` 全量遍历、glibc 特有扩容接口——Bionic 上编不过或行为不同。移植老代码先把编译错误当地图。

**stdout 里找日志**：`printf` 调试法在 Android 上失灵，输出进了黑洞还以为代码没跑到。native 调试输出口是 `__android_log_print`（第 20 章）。

**native 碰外部存储**：C 的 `fopen("/sdcard/...")` 在分区存储时代基本必败（第 09 章的规则按 UID 执行）。路径一律从 Kotlin `filesDir`/`cacheDir` 传入。

**双 C++ 运行库混链**：第 6 节的 static 混用崩溃。症状是跨库传递的 C++ 对象上 `dynamic_cast` 失败、异常跨库后变 `std::bad_exception`、双重释放——查崩溃点先数 `.so` 里带了几份 libc++。

**`getpwuid` 不判空**：返回 nullptr 是正常路径不是异常，直接 `pw->pw_name` 就 segfault。

**fclose 不查返回值**：缓冲输出的磁盘满错误在 fclose 才暴露，吞掉它就是"写文件成功"的假象。

## 8. 实战建议

- 移植 C/C++ 库前先跑一次"API 面检"：对 NDK stable API 列表（`ndk/docs/`）粗筛，缺的早发现早绕路
- native 文件路径永远由 Kotlin 侧注入，native 代码不做路径拼装——权限模型变化时只改一处
- 新工程 C++ 运行库无脑选默认（static），出现第二个 `.so` 且要跨库传 C++ 类型时再切 `c++_shared`，并保证全应用唯一
- 调试期开 libc++ 断言抓 STL 误用，性能基准在关闭断言后测
- 三个内存世界（第 4 节的表）贴墙上：分配者与回收者对不上的，全是泄漏候选
- 下一章进入并发：Bionic 的 pthread 与 Java 线程如何在 JNI 边界两侧共存

---

上一章：[21 JNI 深入：字符串、数组、域与异常](21-jni-deep.md) ｜ 下一章：[23 原生线程与同步](23-native-threads.md) ｜ 返回：[README](../README.md)
