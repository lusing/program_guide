# 01 · 全景：Kotlin 是什么

> 对应示例：无（本章只建立地图；从 02 章开始每章配一个可运行示例）
>
> 面向**会编程（Java/C++/Rust/Go 背景最佳）、初学 Kotlin** 的读者。

## 1.1 一句话定位

Kotlin 是一门**运行在 JVM 上的静态类型语言**，也可以编译到 JavaScript、Native（LLVM）和 WebAssembly。它由 JetBrains 在 2011 年发布、2016 年发 1.0，2017 年起是 Android 官方语言，2024 年进入 2.x 时代（K2 编译器）。核心承诺只有一条：**与 Java 100% 互操作的前提下，消灭 Java 里最疼的那几类错误和最啰嗦的那几类样板**。

它不是"更好的 Java"那么简单——空安全进了类型系统、扩展函数改写了标准库形态、协程把异步写成了同步的样子、委托属性和带接收者的 lambda 造出了 DSL 生态（Gradle KTS、kotlinx.html、Compose 都是它的产物）。

## 1.2 三个支柱

1. **空安全是类型系统的一部分**。`String` 与 `String?` 是两个类型；空指针在编译期被拦住（04 章）。
2. **一切皆表达式，一切有值**。`if`、`when`、`throw`、`try` 都是表达式；连"类没有 static"都用 companion object 这个"值"解决（03/05/09 章）。
3. **结构化并发**。协程属于一棵作用域树，父取消则子全停，异常沿树传播——没有"泄漏的孤儿任务"（14/15 章）。

## 1.3 与你已会的语言对照

| 维度 | Kotlin | Java | C++ | Rust | Go |
|---|---|---|---|---|---|
| 内存管理 | GC（JVM） | GC | 手动/RAII | 所有权 | GC |
| 空安全 | 类型系统级（`T` vs `T?`） | 注解约定（NPE 运行时炸） | 无 | 类型系统级（Option） | 无（nil 接口坑） |
| 默认可变性 | val 只读 / var 可写 | final 需显式 | const 需显式 | let/mut | const 需显式 |
| 继承 | **默认 final**，open 才可继承 | 默认可继承 | 默认非虚 | 无继承（trait 组合） | 无继承（接口组合） |
| 泛型 | 声明处型变 + reified | 使用处通配符 | 模板（单态化） | 泛型 + trait（单态化） | 泛型（类约束） |
| 异步 | 协程（语言级 suspend） | 虚拟线程/CompletableFuture | std::execution/协程库 | async/await | goroutine |
| 函数值 | lambda + 函数类型 + 接收者 lambda | lambda（SAM 转换） | lambda | 闭包 + trait | 闭包 |
| 错误处理 | 异常 + Result/sealed 双轨 | checked/unchecked 异常 | 异常/expected | Result + panic | error 返回值 + panic |
| 运行时 | JVM（丰富生态） | JVM | 无 | 无 | 小运行时 |

给 Java 老手的三句剧透：**类默认 final**（要继承写 open）；**没有 static**（用 companion object / 顶层函数）；**所有类型默认非空**（可空要显式 `?`）。

给 Rust/Go 老手的三句剧透：GC 换来了宽松的所有权心智（不用借用检查），代价是最坏停顿；空安全手感接近 `Option<T>` 但语法糖更甜（`?.`/`?:` 链）；协程 ≠ goroutine——它是**用户态调度的轻量线程，默认绑定到一棵会取消的作用域树**，逃逸要显式 GlobalScope。

## 1.4 版本与工具链（本教程实测环境）

| 组件 | 版本 | 位置（本机） |
|---|---|---|
| Kotlin 编译器 | **2.4.20**（K2） | `G:\scoop\apps\kotlin\current\bin\kotlinc-jvm.bat` |
| JDK（运行） | oraclejdk-lts **21** | `G:\scoop\apps\oraclejdk-lts\current` |
| Gradle | 9.7.1（17 章用） | `G:\scoop\apps\gradle\current` |
| 附带库 | kotlin-test、kotlinx-coroutines-core-jvm、kotlin-reflect | `…\kotlin\current\lib\` |

⚠️ 网上教程版本混杂：1.x 时代的写法绝大多数仍然成立，但 K2 编译器（2.0+）报错信息全新、部分历史 API 被移除。本教程所有代码在 **kotlinc 2.4.20** 实测。

**重要**：本机 PATH 上的 `java` 是 **Java 8**，直接用它跑 Kotlin 2.x 编译产物会出各种诡异问题——本教程的 `build.ps1` 会自动把 `JAVA_HOME` 指向 JDK 21。你复现命令时也要注意。

## 1.5 编译到哪儿：Kotlin 的四个目标

- **JVM**（本教程主线）：`.kt` → `.class` → 跑在 JRE 上；生态 = 全部 Java 生态。
- **JS**：编译成 JavaScript（前端/Node）。
- **Native**：编译成原生二进制（LLVM），无 JVM 依赖。
- **Wasm**：WebAssembly（2.x 新增，试验推进中）。

多平台共享**同一套语言与公共 stdlib**，平台差异封装在 expect/actual 机制里。本教程专注 JVM——它是 90% 的现实场景。

## 1.6 本教程的学法

每章三步：**读讲解 → 跑示例 → 改代码再跑**。

```powershell
cd G:\code\guide\kotlin
pwsh -ExecutionPolicy Bypass -File build.ps1 -All              # 全部 23 个示例：四层验证
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 04_nullsafety   # 单跑第 4 章示例
```

"四层验证"指：**编译（-Werror，警告即错误）→ 单元测试（kotlin.test）→ 运行（exit 0）→ 输出快照（与 expected.txt 逐行比对）**。改坏任何一层都会红——这也是你练习时的反馈环：故意把某行改错，跑 `-Example`，看它怎么报错。

## 1.7 全书地图

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

## 1.8 坑位清单（全书总索引）

1. PATH 上的 java 是 8：一切脚本先 `JAVA_HOME → JDK 17+`（build.ps1 已代劳）。
2. 类默认 final；要继承/被 override 必须显式 open。
3. 数值类型之间**没有隐式加宽**，`Int + Long` 都要显式转换。
4. `listOf(...)` 是**只读视图不是不可变**——底层 MutableList 变了它会跟着变。
5. 集合 `sorted*()` 返回新列表，`sort*()` 才是原地；`MutableList` 上调 sorted 不会改自己。
6. lambda 捕获 var 是真闭包（Java 只能捕 effectively final）——小心共享可变状态。
7. 扩展函数是**静态解析**的：不参与虚分发，接口上定义的扩展不会被实现类"覆写"。
8. `==` 比较值（equals），`===` 比较引用——和 Java 的 `==` 语义不同。
9. 协程别用 GlobalScope 当默认；runBlocking 只该出现在 main/测试的边界。
10. 原始字符串 `"""…"""` 里行尾的 `$` 会被当成模板起始（19 章实测）。

各章末尾的"坑位清单"有上下文细节，这里是速查版。
