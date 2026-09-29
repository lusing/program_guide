# 23 · 原生线程与同步

> 对应示例：`compose_examples/app/src/main/cpp/native_threads.cpp` + `jni/NativeThreadBridge.kt`（Compose 消费层在 `samples/JniSamples.kt`）

## 1. 一条边界，两个世界

先复述第 21 章最烫的两条 JNI 线程规则，本章所有内容都踩在它们上面：

- **`JNIEnv*` 是线程局部的**：哪个线程调进 native，那个 `env` 只在该线程有效。缓存它、跨线程用它，是未定义行为
- **局部引用不出线程**：本次调用的局部引用在别的线程里是悬空的

于是原生线程的核心问题只有一个：**pthread 造的线程虚拟机不认识**，它想回头调 Java/Kotlin 代码，必须先"挂靠"（attach）到虚拟机。本章主线：pthread 基本功 → 挂靠与回调 → 同步三件套 → 调度现实。

一个先立的价值观（观点）：纯 Kotlin 项目里，协程 + `Dispatchers.IO`（第 08 章）覆盖 99% 的并发需求；原生线程属于"已有 native 库自带 worker/引擎线程"的世界——你读它、修它，新代码别轻易起手。

## 2. pthread 基本功：create/join 与三件套同步

`threadSpawnSum` 一次演齐 pthread 世界最常同框的四件东西（`native_threads.cpp`）：

```cpp
struct SumJob { jint n; jlong result; pthread_mutex_t mutex; pthread_cond_t done; bool finished; };

void* sum_worker(void* arg) {
    auto* job = static_cast<SumJob*>(arg);
    jlong sum = 0;
    for (jint i = 1; i <= job->n; i++) sum += i;
    pthread_mutex_lock(&job->mutex);
    job->result = sum;
    job->finished = true;
    pthread_cond_signal(&job->done);       // 通知：结果就绪
    pthread_mutex_unlock(&job->mutex);
    return nullptr;
}

// 调用侧：
pthread_create(&worker, nullptr, sum_worker, &job);   // 造线程
pthread_mutex_lock(&job.mutex);
while (!job.finished) {
    pthread_cond_wait(&job.done, &job.mutex);         // 等通知（用 while 防虚假唤醒）
}
pthread_mutex_unlock(&job.mutex);
pthread_join(worker, nullptr);                        // 回收线程资源
```

逐个点名：

- **`pthread_create`**：四参（线程句柄、属性、入口函数、`void*` 参数）。入口只有这一个 `void*`——要传多个值就打包结构体（`SumJob` 就是干这个的），这是 C 接口的传统艺能
- **`pthread_join`**：等线程结束并回收资源。不 join 的线程变成"僵尸资源"， detached 线程（`pthread_detach`）是另一种"不等它"的选择
- **`pthread_mutex_t`**：互斥锁。`init`/`destroy` 配对，`lock`/`unlock` 夹住共享数据的读写——注意锁保护的是**数据**不是代码段
- **`pthread_cond_t`**：条件变量。"等到某条件成立"的低成本等待。`wait` 会**原子地**放锁+睡眠，被唤醒后重新拿锁——所以 `signal` 侧必须先改条件再 signal，`wait` 侧必须把条件检查放 `while` 里（唤醒不代表条件成立，还有"虚假唤醒"这种规范允许的捣乱）

原书 7.3.4/7.5.1 的教学示例与此同构，但它把结果经 JNI 回调 UI 展示；我们把等待收敛在函数内，一条调用看见全貌。

## 3. AttachCurrentThread：原生线程挂靠虚拟机

虚拟机不认识的线程要碰 Java 世界，先挂靠（原书 7.3.3 的核心段落，2026 年原样有效）：

```cpp
// 线程入口里：
JavaVMAttachArgs args{};
args.version = JNI_VERSION_1_6;
args.name = const_cast<char*>("guide-native-worker");   // debugger/logcat 里可见的线程名
g_guideJavaVm->AttachCurrentThread(&env, &args);        // 换取本线程专属的 JNIEnv*
// ……经 env 调用 Java/Kotlin 方法……
g_guideJavaVm->DetachCurrentThread();                   // 用完分离，否则泄漏 JNI 线程槽
```

三个配套事实：

- **`JavaVM*` 从哪来**：`JNI_OnLoad` 回调的入参（本工程在 `native_threads.cpp` 顶部）。它是进程级的，可以放心存全局；`JNIEnv*` 则绝对不行——这正是两个指针的本质区别
- 重复 attach 无副作用；attach 了不 detach，线程退出时 JNI 线程表泄漏（长跑进程的慢性病）
- 回调抛的异常同样要 `ExceptionCheck`/`ExceptionClear` 处理干净再 detach（第 21 章第 6 节的纪律在线程侧加倍严格）

**一个藏得极深的坑（本工程代码里就有示范防御）**：原生线程里 `FindClass` 找**应用自己的类**会失败——attach 出来的线程拿的是系统类加载器上下文。标准解法是 **JNI_OnLoad 时预取**：那时类加载器是加载本库的 app loader，`FindClass` 必定成功；把 `jclass` 用 `NewGlobalRef` 提升成全局、`jmethodID` 一并缓存（`native_threads.cpp` 的 `g_bridgeClass`/`g_onNativeMessage`）。这个组合同时示范了第 21 章第 5 节"缓存 ID"与第 7 节"全局引用"的实战用法。

`threadNotifyBack` 把整条链跑通：pthread 起线程 → attach → `CallStaticVoidMethod` 回调 Kotlin 的 `onNativeMessage` → detach → join。Kotlin 侧 `NativeThreadBridge.lastNativeMessage` 收货——join 先于返回，读它没有竞态。

## 4. 信号量：第三种同步原语

`threadSemPingpong` 用一对信号量让两个线程打乒乓球（原书 7.5.2 的迷你版）：

```cpp
sem_init(&job.ping, 0, 0);          // 0 = 线程间用（非进程间），初值 0
// 主线程：
sem_post(&job.ping);   // 发球（计数 +1）
sem_wait(&job.pong);   // 等回球（计数 -1，为 0 则睡眠）
// worker 线程：
sem_wait(&job.ping);   // 等球
sem_post(&job.pong);   // 回球
```

三者选型一句话：**mutex** 保护"一次只能一个人动"的数据；**condvar** 表达"等到某事发生"（必须配 mutex 与 while 循环）；**semaphore** 数量化资源/配额（N 个名额、生产者消费者计数）。Kotlin 侧 `Semaphore(kotlinx.coroutines.sync)` 与它们是同宗。

## 5. MonitorEnter：借 Java 对象的锁

JNI 还提供了直接用 **Java 对象监视器**同步的函数（原书 3.7.1）：

```cpp
if (env->MonitorEnter(obj) == JNI_OK) {
    // ……临界区：等价于 Kotlin 侧 synchronized(obj) { …… }
    env->MonitorExit(obj);   // 必须配对，否则死锁
}
```

用途场景：native 与 Kotlin 代码要**互斥访问同一份共享数据**，锁的载体是同一个 Java 对象——两边 synchronized 的是同一把锁，语义才闭合。只在一侧用的锁，选哪边的原语都行。

## 6. 调度与优先级：现实检查

原书 7.6 整节讲 POSIX 调度策略（`SCHED_FIFO`/`SCHED_RR`/`SCHED_OTHER`）与优先级，但诚实版结论是：**普通应用拿不到实时调度**。

- 非 root 进程改 `SCHED_FIFO`/`SCHED_RR` 直接 `EPERM`；Android 从未对第三方应用开放这个 cap
- 应用线程全部活在 `SCHED_OTHER`（分时调度）里，`sched_priority` 恒为 0——`threadSchedInfo` 的探测输出就是这句证词
- 想表达"这个线程更重要"，可用的杠杆是 `nice` 值（`setpriority`，范围受限）与**少干活**——把热点算进 native（第 25 章）比抢调度器实在

这也是一条认知免疫：见到老代码里 `pthread_setschedparam(SCHED_FIFO, 99)`，那在真机上从来没成功过——检查返回值的话。

## 7. 常见坑

**缓存 `JNIEnv*`**：本章第一条规则的违反形态。症状是"偶尔崩在无关 JNI 调用"，单线程测试永远复现不了。全局只能存 `JavaVM*`。

**原生线程直接 `FindClass` 找应用类**：第 3 节的坑。返回 null + `NoClassDefFoundError` 挂起，接着一路崩。JNI_OnLoad 预取 + 全局引用是标准答案。

**attach 后不 detach**：短命线程死了槽还在，JNI 线程表慢慢泄漏。配对纪律同 malloc/free。

**condvar 用 if 不用 while**：虚假唤醒与多消费者竞争下条件未必成立。`pthread_cond_wait` 醒来后必须重查条件——这是 POSIX 的成文要求。

**signal 与条件修改的顺序颠倒**：先 signal 后改条件，等待方醒来看不到条件成立又睡回去——死等的经典配方。改条件（持锁）→ signal。

**裸全局变量当通信信道**：没有 mutex/atomic 保护的全局共享，在 ARM 的弱内存模型下连"看见"都不保证。要么锁，要么 C++ `std::atomic`，没有中间态。

**相信实时优先级**：第 6 节。`pthread_setschedparam` 失败是常态不是异常，返回值必须查。

## 8. 实战建议

- 新代码先问"协程能不能做"（第 08 章），原生线程留给对接既有 native 库的场景
- 对接自带线程的库时，先查清它的线程模型：回调在哪个线程？需要你 attach 吗？回调抛异常谁接？这三个问题的答案决定封装层怎么写
- 线程入口的 `void*` 参数用结构体打包，生命周期约定写进注释（join 前不能析构）
- "缓存 ID + 全局引用"的 JNI_OnLoad 模式直接抄本工程 `native_threads.cpp`，它同时是第 21 章两节内容的标准落法
- 线程命名（`JavaVMAttachArgs.name`）花不了三秒钟，logcat/debugger/tombstone 里全靠它认人
- 下一章把这线程功夫用到网络上：POSIX socket 在 native 侧怎么干活

---

上一章：[22 Bionic 与 C++ 标准库](22-bionic-cpp.md) ｜ 下一章：[24 POSIX Socket 原生网络](24-native-sockets.md) ｜ 返回：[README](../README.md)
