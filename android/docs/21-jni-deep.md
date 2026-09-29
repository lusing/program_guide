# 21 · JNI 深入：字符串、数组、域与异常

> 对应示例：`compose_examples/app/src/main/cpp/jni_deep.cpp` + `jni/JniDeepBridge.kt`（Compose 消费层在 `samples/JniSamples.kt`）

## 1. 第 20 章之外还有什么

第 20 章的闭环只动了一种数据：`String` 进出。真实世界的 native 库要吃数组、要回传大块二进制、要改 Kotlin 对象的字段、要回调 Kotlin 方法、要把 Java 异常接住或抛出——这些全是 JNI 规范里的标准动作，也是本章的全部内容（对应原书第 3 章的水下部分）。

先摆一个总原则，后面每一节都是它的展开：

> **跨界是昂贵的，且引用类型都是不透明句柄。** 基本类型（`jint`/`jdouble`…）直接按值传；引用类型（`jstring`/`jintArray`/`jobject`）必须经 `JNIEnv*` 的转换函数才能碰到数据，每次转换都可能是拷贝。

一个认识论纠偏：JNI 函数**不会因为"参数是数组"就给你数组指针**。`jintArray` 在 C++ 里就是一个不透明的结构指针，直接 `arr[0]` 编译都过不了——这是设计而非缺陷，虚拟机要保住移动 GC 挪动对象的权利。

## 2. 字符串：进、出与配对释放

`JniDeepBridge.nativeGreet` 的完整链路（`jni_deep.cpp`）：

```cpp
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeGreet(JNIEnv* env, jobject, jstring name) {
    const char* nameChars = env->GetStringUTFChars(name, nullptr);   // 进
    if (nameChars == nullptr) {
        return env->NewStringUTF("OOM");    // OOM 时返回 null，规范如此
    }
    std::string greeting = std::string("你好，") + nameChars + "！";
    env->ReleaseStringUTFChars(name, nameChars);                     // 配对释放
    return env->NewStringUTF(greeting.c_str());                      // 出
}
```

四个动作各有一句要记住的话：

- **`GetStringUTFChars`（进）**：把 Java 字符串换成 `const char*`。第三参数 `isCopy` 可探知拿到的是副本还是直接指向堆中字符串（教学演示用，生产代码不依赖它）
- **`ReleaseStringUTFChars`（配对）**：不释放就泄漏——副本没人收，直接指针还压着 GC 不能动
- **`NewStringUTF`（出）**：C 字符串包装成 `jstring` 返回。**返回值归 GC 管**，不要画蛇添足去 Release
- Java 字符串**不可变**，JNI 没有任何"改字符串内容"的函数——要改就在 native 世界用 `std::string` 改完再包一层新的

Unicode 侧还有一组平行的 `GetStringChars`/`ReleaseStringChars`（UTF-16），Android 上中文用 UTF-8 组足够，知道存在即可。

## 3. 数组：Region 拷贝与 Elements 直接指针

JNI 给数组开了两条路，对应"读走"与"就地改"两种意图。

**Region 路线**——把一段数组拷进/拷出 C 数组，`nativeSumIntArray` 用的就是它：

```cpp
jint buf[256];
env->GetIntArrayRegion(arr, 0, take, buf);   // 拷一段进来
// ……像普通 C 数组一样读
```

不需要配对释放（`buf` 是自己的内存）；`SetIntArrayRegion` 反向把 C 数组写回 Java 数组。适合**一次性读走或一次性写回**。

**Elements 路线**——拿"直接指针"，`nativeScaleArrayInPlace` 演示原地缩放：

```cpp
jboolean isCopy = JNI_FALSE;
jdouble* elems = env->GetDoubleArrayElements(arr, &isCopy);
for (jsize i = 0; i < len; i++) elems[i] *= factor;
env->ReleaseDoubleArrayElements(arr, elems, 0);   // 第三参数是"释放模式"
```

释放模式是必考点：

| 模式 | 动作 | 适用 |
|---|---|---|
| `0` | 拷回内容并释放 | 改了要生效 |
| `JNI_COMMIT` | 只拷回不释放 | 周期性刷新 Java 侧进度 |
| `JNI_ABORT` | 只释放不拷回 | 只读过，改动作废 |

**选型观点**：Elements 不一定真的"零拷贝"——虚拟机完全可以给你一份副本（`isCopy == JNI_TRUE`）。所以"性能首选 Elements"是想当然；高频小读写用 Region 局部段，大批量数据直接上第 4 节的 NIO。

## 4. NIO 直接缓冲区：大数据的正确姿势

图像帧、音频块、采样缓冲这类**大块二进制**，JNI 官方推荐姿势是直接 `ByteBuffer`：native `malloc` 一块内存，包成 Java 对象双向直读——两侧操作**同一块**内存，没有来回拷贝。

```cpp
// nativeMakeDirectBuffer：native 造，Kotlin 用
auto* raw = static_cast<unsigned char*>(malloc(capacity));
jobject buf = env->NewDirectByteBuffer(raw, capacity);

// nativeDirectBufferSum：Kotlin 造的，native 直读
void* raw = env->GetDirectBufferAddress(buf);
jlong cap = env->GetDirectBufferCapacity(buf);
```

但自由的代价是：**这块内存不在 GC 管辖内**。`malloc` 的必须有人 `free`——本例配了 `nativeFreeDirectBuffer`，Kotlin 侧用完显式调用。忘了就是典型 native 泄漏，profiler 里看 Java 堆毫无异常，进程 RSS 却一路涨。

## 5. 访问域与调用方法：native 回 Java

前面都是"数据跨界"，现在让 native **回头操作 Java 世界**。入口三步（`nativeBumpCounter`）：

```cpp
jclass clazz = env->GetObjectClass(counter);          // ① 从实例拿类
jfieldID fieldId = env->GetFieldID(clazz, "count", "I"); // ② 名字+描述符定位域
jint value = env->GetIntField(counter, fieldId);      // ③ 真正读值
env->SetIntField(counter, fieldId, value + 1);        //    写回
```

静态域是 `GetStaticFieldID`/`GetStaticIntField` 一套平行函数；方法同理——实例方法 `GetMethodID` + `CallObjectMethod`（`nativePingSelf` 回调 Kotlin 的 `pingFromKotlin`），静态方法 `GetStaticMethodID` + `CallStaticObjectMethod`（`nativeStaticInfo`）。

**描述符**是这套寻址的语言，第 ② 步里 `"I"` 就是 Int 的描述符。映射表：

| 类型 | 描述符 | 类型 | 描述符 |
|---|---|---|---|
| `Int` | `I` | `String` | `Ljava/lang/String;` |
| `Long` | `J`（不是 L！） | 任意类 | `L全限定名;`（点换斜杠，带分号） |
| `Boolean` | `Z`（不是 B！） | `IntArray` | `[I` |
| `Double` | `D` | `DoubleArray` | `[D` |
| 方法 | `(参数)返回值` | `Array<String>` | `[Ljava/lang/String;` |

例如 `nativePingSelf` 回调的方法描述符是 `(Ljava/lang/String;)Ljava/lang/String;`。手写容易错，**用工具对账**：`javap -s` 直接吐出每个方法/字段的描述符（原书 3.4.6 节用整节讲这个工具；当年它还要配 Eclipse 外部工具菜单，今天 Android Studio 里对着编译产物跑一条命令即可）。顺带一提：老书里的 `javah` 生成头文件工具已在 JDK 10 移除，现代等价物是 `javac -h`。

**性能观点**（原书小贴士，2026 年依然成立）：每取一个域值要两三个 JNI 调用，native 频繁回头取值是自毁性能。正确姿势是**把所有需要的参数一次性传进 native**，让 native 只在必要时（回调 UI、通知进度）才回头。同理，`jfieldID`/`jmethodID` 查一次可以缓存复用（ID 在类存活期间有效），别在循环里反复 `GetFieldID`。

## 6. 异常：两个方向都要管

JNI 的异常模型与 Java 有一处关键不同：**抛出异常不会中断 native 代码的执行**。`ThrowNew` 只是把一个异常"挂起"（pending），native 函数还会继续跑——所以抛完必须自己收尾释放资源、返回哨兵值，把控制权交回 Java 侧，异常才在那里炸出来。

```cpp
// nativeCheckedSqrt：native 主动抛
if (x < 0) {
    jclass clazz = env->FindClass("java/lang/IllegalArgumentException");
    env->ThrowNew(clazz, "nativeCheckedSqrt: 负数没有实平方根（异常从 C++ 抛出）");
    return NAN;   // 哨兵值：调用方要么收到异常要么收到 NaN
}
```

反方向，**native 调用的 Java 方法可能抛异常**。JNI 没有"自动 try"——挂起的异常不清掉，会在你返回 Java 的瞬间炸在莫名其妙的栈帧上。标准三连（`nativeCatchAndReport`）：

```cpp
env->CallObjectMethod(thiz, methodId);          // 调了会抛的 boom()
jthrowable ex = env->ExceptionOccurred();       // 查询
if (ex != nullptr) {
    env->ExceptionClear();                      // 清除——之后才能安全继续调 JNI
    // ……可以经 getMessage 读取异常信息再决定怎么办
}
```

日常防御习惯：在"调用了可能失败的 JNI 函数"之后用 `ExceptionCheck()` 快速探测（返回 `jboolean`，不产生局部引用），需要细节时才用 `ExceptionOccurred()`（返回引用，记得 `DeleteLocalRef`）。

## 7. 引用三档：局部、全局、弱全局

GC 通过引用追踪对象，native 侧的引用分三档，生命周期完全不同：

| 档 | 产生 | 有效期 | 用途 |
|---|---|---|---|
| 局部引用 | 绝大多数 JNI 函数的返回值 | **本次 native 调用**返回即失效 | 函数内临时使用 |
| 全局引用 | `NewGlobalRef` 显式提升 | 直到 `DeleteGlobalRef` | 跨调用/跨线程持有对象 |
| 弱全局引用 | `NewWeakGlobalRef` | 直到显式删除，**不阻止 GC 回收** | 缓存可重建的对象（如 jclass） |

规范只保证一次调用里能有 16 个局部引用（`EnsureLocalCapacity` 可扩容）——循环里大量 `FindClass`/`GetObjectArrayElement` 会撑爆，用完即 `DeleteLocalRef` 是好习惯，也是原书 3.6.1 节的最佳实践。

`nativeRememberTag`/`nativeRecallTag`/`nativeForgetTag` 三件套演示全局引用跨调用存活的完整生命周期：Remember 时 `NewGlobalRef` 提升并记在静态变量里（先释放旧值防泄漏），Recall 直接返回它，Forget 时 `DeleteGlobalRef`。**忘了 Forget，对象永远不可回收**——这是 native 侧另一种形态的内存泄漏。

弱全局引用的用法要点：用之前必须 `IsSameObject(weakRef, nullptr)` 检查对象是否已被回收（回收后弱引用"等于 null"）。本教程代码不展示，真实场景常见于缓存 `jclass`。

一个易踩的隐雷：**局部引用不是"函数局部变量"的引用，是"本次 JNI 调用"的引用**。在 native 里把局部引用存进全局变量、下次调用再用——值还在，指向的对象可能早就被回收/失效了，崩溃点离案发现场极远。

## 8. 常见坑

**描述符手滑**：`J` 是 Long、`Z` 是 Boolean、类描述符结尾的分号、数组前的 `[`——四个高频错误点。`GetFieldID` 找不到就返回 null 并挂 NoSuchFieldError，后面每一步都在错误状态下狂奔。用 `javap -s` 对账。

**忘 Release / 多 Release**：`Get*Chars`/`Get*ArrayElements` 系不释放即泄漏；Release 的模式用错（只读场景传 `0` 会白拷一次回来）。配对纪律：Get 与 Release 写在同一层作用域，肉眼可配对。

**在循环里 Get/Release**：每次 Get 都可能触发拷贝与分配，循环内先取一次指针（或整段 Region），循环外统一释放。

**把 New 出来的返回值当自己的内存释放**：`NewStringUTF`/`NewIntArray` 的产物归 GC，native 侧"帮忙释放"是越权，直接崩。

**异常挂起时继续调 JNI**：`ThrowNew` 之后、`ExceptionClear` 之前，中间的 JNI 调用行为未定义（多数是莫名崩溃）。抛完就收尾返回，查到就处理干净。

**静态变量存局部引用**：第 7 节的隐雷。跨调用持有必须 `NewGlobalRef`。

## 9. 实战建议

- 接口设计成"厚数据、薄往返"：参数一次传齐（数组/ByteBuffer 打包），返回值同样打包，跨界次数最小化
- 描述符集中在常量里定义并注释来源（"经 javap -s 核对"），别散落各处手写
- `jfieldID`/`jmethodID` 缓存复用；跨线程场景配全局引用（第 23 章的 JNI_OnLoad 方案是标准姿势）
- 大块二进制一律直接 `ByteBuffer`（第 4 节），并写好 free 路径——native 内存泄漏不归 GC 报警
- native API 的错误处理约定要想清楚：抛 Java 异常（能被 Kotlin runCatching 接住）还是返回哨兵值，别混用两套
- 域/方法回调保持"通知"性质（进度、事件），别让 native 频繁回头取数据——那是设计错误，不是优化问题
- 下一章把这套机制放进 Bionic 环境：native 世界的内存、文件与系统调用长什么样

---

上一章：[20 JNI 与 NDK](20-jni-ndk.md) ｜ 下一章：[22 Bionic 与 C++ 标准库](22-bionic-cpp.md) ｜ 返回：[README](../README.md)
