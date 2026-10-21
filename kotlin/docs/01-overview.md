# 01 · 全景：Kotlin 是什么

> 对应示例：无（本章只建立地图；从 02 章开始每章配一个可运行示例）
>
> 面向**已经会编程（Java/C++/Rust/Go 背景最佳）、初学 Kotlin** 的读者。
> 本章不教你写代码，而是回答四个问题：Kotlin 为什么存在、它和你已会的语言差在哪、
> 标准库的 24 个包各管什么、这本教程怎么学、用什么版本验证。

## 1.1 为什么会有 Kotlin：从 Java 的三类痛说起

要理解一门语言，先看它想消灭什么。Kotlin 由 JetBrains 在 2010 年立项、2011 年公开、2016 年发布 1.0——它的设计团队就是写 IntelliJ IDEA 的那批人，每天在几百万行 Java 代码上工作，对 Java 的痛有第一手的、长达十年的体感。这些痛可以归为三类：

**第一类：运行时才知道的错误。** 最典型的是 `NullPointerException`。Java 的类型系统知道"这是一个 String"，却不知道"这个 String 能不能是 null"，于是 `user.getAddress().getCity()` 这种再普通不过的代码，每一环都可能在生产环境爆炸。空引用被它的发明者 Tony Hoare 称为"十亿美元错误"——它不是 Java 独有的问题，但 Java 把它留给了运行时。

**第二类：不得不写的样板。** 一个只装三个字段的类，在 Java 里要写构造器、getter、`equals`、`hashCode`、`toString`，五十行起步；想给"别人的类"（比如 JDK 的 `String`）加一个工具方法，只能发明 `StringUtils` 这种到处是静态方法的"工具类孤儿院"。代码量上去了，信息量没上去——阅读成本全在噪音里。

**第三类：异步代码的形态。** 回调套回调的"回调地狱"，或者 `CompletableFuture` 那种把业务逻辑拆碎装进管线算子的写法，都让"先做什么后做什么"这件本来很直观的事变得难以阅读和排错。

Kotlin 的回答是：在与 Java 100% 互操作的前提下，把第一类错误**移进类型系统**（编译期拦住），把第二类样板**交给编译器生成**，把第三类异步**写成同步的样子**（协程）。2017 年 Google 宣布 Kotlin 成为 Android 官方语言，2019 年宣布 Android 开发 "Kotlin-first"，2024 年 Kotlin 进入 2.x 时代、默认启用全新重写的 K2 编译器。今天它的主战场早已不限于 Android：服务端（Spring、Ktor）、多平台（iOS 共享逻辑）、桌面（Compose Desktop）、甚至编译到原生二进制和 WebAssembly。

## 1.2 一句话定位

Kotlin 是一门**静态类型、与 Java 深度互操作的多平台语言**。"互操作"不是口号，而是具体到字节码层面的事实：

- Kotlin 编译产物就是普通 `.class` 文件，Java 代码可以像调 Java 一样调 Kotlin，反之亦然；
- 一个工程里可以 `.java` 和 `.kt` 文件混放，互相引用，甚至互相继承；
- 整个 Java 生态——Spring、Netty、Maven 中央仓库里那几百万个 jar——对 Kotlin 全部直接可用。

这意味着 Kotlin 不是在"替代 Java 生态"，而是"给 Java 生态换一门更好的前端语言"。学 Kotlin 的每一分投入都不会把你锁进一个小众孤岛，这是它区别于很多"JVM 新语言"的根本一点（18 章会专门实测互操作的每个细节）。

但"更好的 Java"这个说法又低估了它。空安全进了类型系统之后，整个标准库的形态都被改写——解析函数返回 `Int?` 而不是抛异常，映射函数返回 `T?` 而不是返回 null 碰运气；扩展函数让"给别人的类加方法"成为一等公民，标准库一半的能力是扩展函数；委托属性和带接收者的 lambda 则造出了一个 DSL 生态——Gradle 的 Kotlin 脚本（`build.gradle.kts`）、Compose 的声明式 UI、kotlinx.html，都是同一种语言机制的产物。学完这本教程你会发现，Kotlin 的现代化不是"语法糖更甜"，而是几件精心设计的小事互相咬合，最终改变了代码的组织方式。

## 1.3 三个设计支柱

全书三十三章，其实都在反复演绎三个支柱。现在先记住结论，后面每章都会回来加固。

**支柱一：空安全是类型系统的一部分。** 在 Kotlin 里，`String` 和 `String?` 是两个不同的类型：前者编译器保证非空，后者可以为 null、但使用时必须显式处理。空指针异常在**编译期**就被拦住，而不是留到生产环境。这是 04 章的全部内容，也是 Kotlin 最著名的特性。

**支柱二：一切皆表达式，一切有值。** `if`、`when`、`try`、`throw` 在 Kotlin 里都是表达式——它们有值，可以直接赋给变量、作为函数返回。这条原则看起来小，影响却深：没有三目运算符（`if` 表达式就够了）、没有"先声明变量再在分支里赋值"的套路（`val x = when ...` 一把到位）。更妙的是，连"类没有 static 成员"这件事，Kotlin 都用一个"值"来解决——`companion object` 本身就是一个对象、一个值（03/05/09 章逐步展开）。

**支柱三：结构化并发。** Kotlin 协程不是"go 关键字一扔就不管"的裸线程，而是挂在一棵作用域树上：父协程取消，子协程全部跟着停；子协程异常，沿树向上传播。不存在"忘了 join 而泄漏的孤儿任务"这个类别的问题（14/15 章）。

## 1.4 与你已会的语言对照

下表是全书最重要的"心智迁移图"。不要求现在全懂——每行对应后面某一章，读完相关章节回来扫一眼即可。

| 维度 | Kotlin | Java | C++ | Rust | Go |
|---|---|---|---|---|---|
| 内存管理 | GC（JVM） | GC | 手动/RAII | 所有权 | GC |
| 空安全 | 类型系统级（`T` vs `T?`） | 注解约定（NPE 运行时炸） | 无 | 类型系统级（Option） | 无（nil 接口坑） |
| 默认可变性 | `val` 只读 / `var` 可写 | `final` 需显式 | `const` 需显式 | `let`/`mut` | `const` 需显式 |
| 继承 | **默认 final**，`open` 才可继承 | 默认可继承 | 默认非虚 | 无继承（trait 组合） | 无继承（接口组合） |
| 泛型 | 声明处型变 + reified | 使用处通配符 | 模板（单态化） | 泛型 + trait（单态化） | 泛型（类型约束） |
| 异步 | 协程（语言级 `suspend`） | 虚拟线程/CompletableFuture | std::execution/协程库 | async/await | goroutine |
| 函数值 | lambda + 函数类型 + 接收者 lambda | lambda（SAM 转换） | lambda | 闭包 + trait | 闭包 |
| 错误处理 | 异常 + [Result](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-result/index.html)/sealed 双轨 | checked/unchecked 异常 | 异常/expected | Result + panic | error 返回值 + panic |
| 运行时 | JVM（全部 Java 生态） | JVM | 无 | 无 | 小运行时 |

**给 Java 老手的三句剧透**：类默认 final（要继承先写 `open`，07 章）；没有 `static`（顶层函数和 `companion object` 接管，05/09 章）；所有类型默认非空（可空必须显式写 `?`，04 章）。这三条会是你前两周报错信息的主要来源，提前认个脸熟。

**给 Rust 老手的三句剧透**：GC 换来了宽松的所有权心智——没有借用检查、没有生命周期标注，多个引用随便指，代价是 GC 停顿和失去了编译期的数据竞争防护（21 章讲并发时会更清楚这笔交易）；空安全的手感接近 `Option<T>`，但语法糖更甜——`?.` 链式下钻和 `?:` 默认值替代了大部分 `map`/`and_then`/`unwrap_or` 组合；协程不是 async/await 的染色函数模型，`suspend` 函数的挂起点由挂起函数体内部决定，调度在用户态。

**给 Go 老手的三句剧透**：Kotlin 协程 ≠ goroutine。goroutine 是"发射后不管"，协程默认绑定在一棵会级联取消的作用域树上，想逃逸必须显式写 `GlobalScope`（而被视为异味）；channel 两边都有，但 Kotlin 更推 Flow 这种"冷流 + 算子"的声明式模型（15 章）；错误处理上，Kotlin 保留了异常，同时标准库提供 [Result](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-result/index.html) 类型支持 Go 风格的"错误当值返回"，两条路线 16 章会帮你做选型。

**给 C++ 老手的三句剧透**：没有头文件、没有前向声明、没有宏——一个文件里声明顺序无关；RAII 的思想以扩展函数形态存在（`use` 自动关资源，19 章）；模板单态化对应 Kotlin 的 reified 泛型（`inline` + `reified` 可以在运行时用 `T::class`，11/28 章），默认泛型则和 Java 一样类型擦除。

## 1.5 版本与工具链（本教程实测环境）

学语言最怕"教程版本和本机版本对不上"。本教程所有代码都在下表环境实测，版本号写死在文里，不模糊：

| 组件 | 版本 | 说明 |
|---|---|---|
| Kotlin 编译器 | **2.4.21**（K2 编译器） | 2.0 起默认启用的全新编译器前端，报错信息更准、编译更快 |
| JDK | **21**（LTS） | 编译产物按 JDK 21 运行；为何钉 21 见下 |
| Gradle | 9.x（17 章才用） | 前 16 章全部用 `kotlinc` 直编，零构建工具依赖 |
| 附带库 | kotlin-test、kotlinx-coroutines、kotlin-reflect | 随 Kotlin 发行版自带 |

**为什么 JDK 钉 21 而不是最新版？** 两个原因。其一，21 是长期支持版（LTS），企业现实部署的主流。其二是实测踩出来的硬坑：Kotlin/Native 的编译器 `konanc` 在 JDK 24 及以上会因为启动脚本的引号解析问题直接崩溃（25 章多平台编译要用它）。所以本教程所有入口脚本都**按版本探测**锁定 JDK 21——先检查 `JAVA_HOME` 是否恰好指向 21，再按已知安装路径找验证过版本的 JDK，绝不盲信 PATH 上的 `java`。

这个"别信 PATH"不是 paranoid，是实测环境里的真事：Windows 机器 PATH 上是 Java 8（跑不动 Kotlin 2.x 的产物），`JAVA_HOME` 一度指着 openjdk 27；macOS 机器装着 21/25/26 三套 JDK、PATH 上是 26。用错 JDK 跑 Kotlin，症状千奇百怪（类文件版本错误、反射 API 行为变化、konanc 崩溃），排查极费时间。你自己手敲命令时，也请养成先 `export JAVA_HOME=<JDK 21 路径>` 的习惯。

> **1.x 时代的教程还能看吗？** 能，但要带着滤镜。Kotlin 1.x 的绝大多数写法在 2.x 下依然编译通过（JetBrains 对向后兼容极为保守），真正的变化在编译器：K2 的类型推断更强（一些 1.x 需要显式标注的地方现在能推出来）、报错信息全部重写、少数历史遗留 API 被移除。本教程出现版本敏感行为时会明确标注"2.1+ 稳定"之类的门槛。

## 1.6 编译到哪儿：Kotlin 的四个目标

同一份 Kotlin 源码，可以编译到四个目标平台：

- **JVM**（本教程主线）：`.kt` → `.class`，跑在 JRE 上。生态 = 整个 Java 生态，覆盖服务端、Android、桌面的 90% 现实场景。
- **JS**：编译成 JavaScript，跑浏览器或 Node。
- **Native**：经 LLVM 编译成原生二进制（Windows `.exe`、macOS/Linux 可执行文件），不依赖 JVM，启动毫秒级。
- **Wasm**：编译成 WebAssembly（wasmJs 面向浏览器，wasmWasi 面向服务端 WASI 运行时），2.x 时代快速成熟中。

多平台的精髓是"同一门语言、同一套公共标准库"：`println`、[List](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/-list/index.html)、`when` 表达式在四个目标上语义一致，平台差异被封装进 expect/actual 机制（公共代码声明"我期望平台提供 X"，各平台给出实际实现）。第 [25 章](25-multiplatform.md)会把同一份逻辑真编到 JS/Wasm/Native 多个目标实测给你看。25 章之后还有两段进阶：26–30 章下潜**语言深水区**（数值装箱与原语数组、注解反射、inline 与 reified、成员扩展、运算符重载约定），31–33 章三个**实战项目**压轴（零依赖 HTTP 服务、终端聊天室、俄罗斯方块）。

## 1.7 标准库包地图：API 索引里的 24 个包各管什么

官方文档的 [kotlin-stdlib API 索引](https://kotlinlang.org/api/core/kotlin-stdlib/) 按包罗列全部公开 API。初学者打开它往往是懵的——24 个包从哪看起？这张表按"你想干什么"重新组织，并给出本教程的对应章节。带 ⚠️ 的是**实验性 API**（要用必须先 `@OptIn`），带 🔒 的是 **JVM 专属**（多平台 common 代码里没有）：

| 包 | 管什么 | 本教程在哪 |
|---|---|---|
| `kotlin` | 语言底座：基本类型、`String`、`Array`、`Result`、`require/check`、无符号类型 ⚠️ | 02/04/16/26 |
| `kotlin.collections` | 集合创建与管道：`listOf`/`map`/`filter`/`groupBy`/`fold`/`sorted` | 10 |
| `kotlin.comparisons` | 比较积木：`compareValues`/`compareValuesBy`/`compareBy`/`thenBy` | 10.10 |
| `kotlin.concurrent` | JVM 线程助手（`thread`）；`concurrent.atomics` ⚠️ 多平台原子类 | 21.2/21.8 |
| `kotlin.contracts` | 编译器约定（`callsInPlace` 等，给库作者用） | —（库作者向，本教程不展开） |
| `kotlin.coroutines` | **挂起函数的语言级类型**（`Continuation`/`suspend` 转换） | 14–15 |
| `kotlin.enums` | 枚举：`EnumEntries`（1.9+，替代 `values()`） | 08 |
| `kotlin.experimental` | 实验性注解的旧家（新 API 多用 `@RequiresOptIn`） | — |
| `kotlin.io` | 文件扩展：`writeText`/`readLines`/`useLines`/`walk`/`copyTo` | 19.2–19.6 |
| `kotlin.io.encoding` ⚠️ | Base64（`Default`/`UrlSafe` 两套字母表） | 19.13 |
| `kotlin.io.path` | `java.nio.file.Path` 的扩展：`createTempDirectory`/`readText`/`writeText` | 19.14 |
| `kotlin.jvm` | JVM 专属：`@JvmStatic`/`@Synchronized`/`@Volatile` | 18/21 |
| `kotlin.math` | 数学函数：`sqrt`/`hypot`/`abs`（import 后用）；`roundToInt`/`absoluteValue`（成员扩展免 import） | — |
| `kotlin.properties` | 委托属性：`Delegates.notNull`/`observable`/`vetoable`、`ReadOnlyProperty`/`ReadWriteProperty` | 09.5–09.10 |
| `kotlin.random` | 随机数：`Random`/`Random.Default`/ seeded 随机（可复现测试） | 20 |
| `kotlin.ranges` | 区间与 progression：`..`/`step`/`in`、`coerceIn` | 03/06 |
| `kotlin.reflect` 🔒 | 反射：`KClass`/`KProperty`/`KFunction`（JVM 上要 kotlin-reflect） | 27 |
| `kotlin.sequences` | 惰性管道：`Sequence`/`generateSequence`/`sequence {}` | 22.2 |
| `kotlin.streams` 🔒 | 与 Java Stream 互操作：`asSequence`/`asStream`/`toList` | 22.8 |
| `kotlin.system` | 退出码：`exitProcess(code)`（CLI 工具的规范退出） | — |
| `kotlin.text` | 字符串与正则：`Regex`/`buildString`/`toIntOrNull`/`padStart` | 02/19.8/19.9 |
| `kotlin.time` | 多平台时间：`Duration`（1.6+ 稳定）/`TimeSource`/`measureTime` | 19.11 |
| `kotlin.uuid` ⚠️ | UUID 值类型：`Uuid.random()`/`Uuid.parse` | 19.12 |
| `kotlin.wasm` | Wasm 目标专属扩展 | —（25 编译到 Wasm 时会碰到） |

三条使用经验，比表本身更重要：

1. **默认导入（不用 import 就能用）的是这几个包**：`kotlin.*`、`kotlin.annotation.*`、`kotlin.collections.*`、`kotlin.comparisons.*`、`kotlin.io.*`、`kotlin.ranges.*`、`kotlin.sequences.*`、`kotlin.text.*`（JVM 上再加 `java.lang.*` 与 `kotlin.jvm.*`）——本地 kotlinc 2.4.21 实测：裸文件里 `File.writeText`/`toIntOrNull`/`compareValues`/`asSequence` 全部直接可用。**要 import 的是其余包**：`kotlin.time`、`kotlin.uuid`、`kotlin.io.encoding`、`kotlin.properties`、`kotlin.random`、`kotlin.reflect`、`kotlin.streams`……分不清"要不要 import"时，先怀疑它在非默认包里。注意**子包永远不享受默认导入**——`kotlin.io.path` 里的 `createTempDirectory` 就得显式 import，哪怕父包 `kotlin.io` 是默认的（19.14）。
2. **一半的能力是扩展函数**（`File.writeText`、`Int.seconds`、`Stream.toList`）——扩展必须 import 才能用（除非所在包默认导入），这也是新手最常见的 `unresolved reference` 来源（19.11/21.8 两次实测踩到）。
3. **看官方 API 文档先认包再看类**：同一个名字可能活在多个包里——`Duration` 在 `kotlin.time`（多平台）和 `java.time`（JVM）各有一个，同时用时 `import ... as` 起别名（19.11 的手法）；`AtomicInteger` 在 `java.util.concurrent.atomic`（JVM）而 `AtomicInt` 在 `kotlin.concurrent.atomics`（多平台，21.8）。

带 ⚠️ 的实验性包是"已发布但未冻结"的 API：能用、有测试，但未来小版本可能改签名。用它们就在**用到的最小作用域**上标 `@OptIn(XXX::class)`——标在库的公开 API 上会把实验性传染给调用方，标在私有实现里则随实现自由更换（19.12/19.13/21.8 有完整示范）。

## 1.8 关于参考书：站在哪些肩膀上

本教程的 24 章实战项目和 31–33 章压轴项目的**选题**取材自四本中文 Kotlin 书：《Kotlin 语言实例精解》（2019）、《Kotlin 从入门到进阶实战》（2018）、《零基础学 Kotlin 编程》（2018）、《Android 10 Kotlin 编程通俗演义》（2020）。它们出版于 Kotlin 1.x 时代，在当时是不错的入门材料，但直接照搬到今天会遇到三个时代差：

1. **语言版本差**：书写的是 Kotlin 1.2–1.3 时代的写法，本教程全部按 Kotlin 2.4.21 + K2 编译器重写。
2. **技术栈差**：书里的 RxJava2、Spring Boot 2、Android AsyncTask 要么已被官方取代（AsyncTask 在 Android 11 弃用，协程/Flow 是标准答案），要么已有大版本跨越（Spring Boot 3.x）。本教程的对应内容一律用现代方案：**协程与 Flow 替代 RxJava/AsyncTask**，JDK 21 基线。
3. **验证标准差**：书里的代码是"印在纸上的代码"，本教程的代码是"四层验证过的代码"（见下节）——每个示例都能在你机器上跑出与文中逐字相同的输出。

因此本教程只借选题，不借内容：所有思想在正文里用自己的话完整讲透，所有代码在 examples/ 目录可运行、可测试、可快照比对。你不需要也不应该去翻原书——这不是缩写本，是重写本。

## 1.9 本教程的学法与四层验证

每章三步：**读讲解 → 跑示例 → 改代码再跑**。前两步建立正确心智，第三步才是真正学会——把代码改坏，看编译器/测试/快照怎么报错，是最快的反馈环。

```bash
cd kotlin
./run-all.sh                      # macOS / Linux：跑全部示例，四层验证
./run-all.sh 04_nullsafety        # 单跑第 4 章示例
```

```powershell
cd kotlin
pwsh ./build.ps1 -All             # Windows（macOS/Linux 装了 pwsh 也能用）：全部示例
pwsh ./build.ps1 04_nullsafety    # 单跑第 4 章示例
```

"四层验证"是本教程的质量承诺，每一层的意义不同：

1. **L1 编译**：`kotlinc -Werror`，警告即错误——不是风格洁癖，而是 Kotlin 的多数警告（变量遮蔽、可疑的相等比较、非尾递归的 tailrec）都指向真 bug。
2. **L2 单元测试**：用 kotlin.test 断言示例里每个函数的行为，断言失败立即以非零码退出。
3. **L3 运行**：程序必须 exit 0，证明没有运行时异常。
4. **L4 输出快照**：程序标准输出与 `expected.txt` 逐行比对——保证"教程里写的输出"和"你机器上的输出"逐字相同。

你在正文里看到的每一段输出，都是 L4 快照里逐字拷出来的，不是作者想象的结果。这也是练习时的玩法：故意改错一行，跑 `./run-all.sh <示例名>`，观察它在哪一层红、报什么——那些报错信息就是你未来工作中每天要读的东西。

## 1.10 全书地图

| 章 | 主题 | Kotlin 特色强度 |
|---|---|---|
| 02–03 | 第一个程序 / 变量与控制流 | ★★☆ |
| 04 | **空安全** | ★★★ |
| 05–07 | 函数 / 类与属性 / 继承与接口 | ★★☆ |
| 08 | **密封类、枚举与 when** | ★★★ |
| 09 | **object、companion 与委托** | ★★★ |
| 10 | 集合 | ★★☆ |
| 11 | **泛型（型变 + reified）** | ★★★ |
| 12 | **高阶函数与作用域函数** | ★★★ |
| 13 | **扩展** | ★★★ |
| 14–15 | **协程基础 / Channel 与 Flow** | ★★★ |
| 16–17 | 错误处理 / Gradle 工程化 | ★★☆ |
| 18 | 与 Java 互操作 | ★★★ |
| 19–20 | 文件与文本 / **测试** | ★★☆ |
| 21–22 | 并发线程 / 函数式 | ★★☆ |
| 23 | **类型安全 DSL** | ★★★ |
| 24 | **实战：迷你待办 CLI（ktodo）** | 综合运用 |
| 25 | 多平台（JS/Wasm/Native） | ★★★ |
| 26–30 | 深水区：数值数组 / 反射 / inline / 成员扩展 / 运算符 | ★★☆ |
| 31–33 | 实战：HTTP 服务 / 聊天室 / 俄罗斯方块 | 综合运用 |

★★★ 标记的是"别的语言没有对应物、需要建立新心智"的章节，值得放慢；★★☆ 是"和你已会的差不多、快速过差异"的章节。

## 1.11 坑位清单（全书总索引）

1. PATH 上的 java 可能太老或太新：一切脚本先钉 JDK 21（入口脚本已代劳，手敲命令时自己 `export JAVA_HOME`）。
2. 类默认 final；要继承/被 override 必须显式 `open`。
3. 数值类型之间**没有隐式加宽**，`Int + Long` 都要显式转换。
4. [listOf](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/list-of.html) 返回的是**只读视图不是不可变**——底层 MutableList 变了它会跟着变。
5. 集合 `sorted*()` 返回新列表，`sort*()` 才是原地排序；在 MutableList 上调用 `sorted()` 不会改自己。
6. lambda 捕获 `var` 是真闭包（Java 只能捕获 effectively final）——小心共享可变状态。
7. 扩展函数是**静态解析**的：不参与虚分发，接口上定义的扩展不会被实现类"覆写"。
8. `==` 比较值（equals），`===` 才比较引用——和 Java 的 `==` 语义相反。
9. 协程别拿 `GlobalScope` 当默认；`runBlocking` 只该出现在 main/测试的边界。
10. 原始字符串 `"""…"""` 里行尾的 `$` 会被当成模板起始符（19 章实测）。
11. `unresolved reference` 先查 import：标准库一半能力是扩展函数，而扩展**只在所在包被导入后才可见**——`kotlin.io`/`kotlin.text` 等包默认导入（`File.writeText` 免 import），`kotlin.time`/`kotlin.concurrent.atomics` 等要手写（`Int.seconds`、`incrementAndFetch` 漏 import 就 unresolved）。1.7 的包地图列了全部分组。

各章末尾的"坑位清单"有上下文细节，这里是速查版。读完全书再回来扫一遍这张表，每一条你都会有"啊这个我踩过"的实感。

---

下一章：[02 第一个程序](02-hello.md)
