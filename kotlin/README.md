# Kotlin 编程指南（2.4.20 / JVM）

面向**会编程（Java/C++/Rust/Go 背景最佳）、初学 Kotlin** 的读者：从零教到现代 Kotlin——**K2 编译器**（2.4.20）、空安全、密封类型与穷尽 when、委托、型变 + reified、作用域函数、扩展、结构化并发协程 + Flow、与 Java 互操作、类型安全 DSL。每章"读讲解 → 跑示例 → 改代码再跑"，全部 23 个示例**四层验证**通过（kotlinc `-Werror` 编译 → kotlin.test 测试 → 运行 exit 0 → expected.txt 快照比对）。

> ⚠️ 版本敏感：本机 PATH 上的 `java` 是 8，本教程 build.ps1 自动切换 `JAVA_HOME → JDK 21`；1.x 时代教程的部分写法在 K2 下行为不同。所有代码在 **kotlinc-jvm 2.4.20 + oraclejdk-lts 21** 实测。

## 目录结构

```text
kotlin/
├── README.md        本文件
├── docs/            24 章教程（01 → 24 顺序阅读）
├── examples/        23 个示例（章号 = 目录号）
│   ├── …            21 个 kotlinc 直编示例（src/ + test/ + expected.txt）
│   ├── 17_gradle/   Gradle 多模块工程（lib+app，JUnit5，fat jar——独立构建）
│   ├── 18_javainterop/  Java/Kotlin 混编（javac→kotlinc 两遍法）
│   └── 24_todo/     实战项目（手写 JSON 解析器 + 文件存储 + CLI）
├── build.ps1        统一验证脚本（四层：编译 -Werror / 测试 / 运行 / 快照）
└── CHEATSheet.md    语法速查 + 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 三支柱、与 Java/C++/Rust/Go 对照、工具链 | — |
| [02 第一个程序](docs/02-hello.md) | kotlinc 全流程、jar、字符串模板、脚本 | `02_hello` |
| [03 变量类型控制流](docs/03-basics.md) | val/var、无隐式加宽、when 四形态、标签 | `03_basics` |
| [04 ⭐空安全](docs/04-nullsafety.md) | `?.`/`?:`/`!!`/let、lateinit、平台类型 | `04_nullsafety` |
| [05 函数](docs/05-functions.md) | 默认/具名参数、vararg、infix、tailrec | `05_functions` |
| [06 ⭐类与属性](docs/06-classes.md) | 属性 vs 字段、data class 五件套、operator | `06_classes` |
| [07 继承与接口](docs/07-inheritance.md) | 默认 final、接口默认实现、嵌套 vs inner | `07_inheritance` |
| [08 ⭐密封枚举 when](docs/08-sealed-enum.md) | 穷尽 when、ADT、守卫条件、状态机 | `08_sealed_enum` |
| [09 ⭐object与委托](docs/09-delegation.md) | 单例、companion、类委托、lazy/observable | `09_delegation` |
| [10 集合](docs/10-collections.md) | 只读双轨、管道全景、sorted/sort 陷阱 | `10_collections` |
| [11 ⭐泛型](docs/11-generics.md) | out/in、星投影、reified、类型擦除 | `11_generics` |
| [12 ⭐lambda与作用域函数](docs/12-lambdas.md) | 函数类型、真闭包、五件套、inline | `12_lambdas` |
| [13 ⭐扩展](docs/13-extensions.md) | 静态解析铁律、可空接收者、伴生扩展 | `13_extensions` |
| [14 ⭐协程基础](docs/14-coroutines.md) | suspend、launch/async、结构化并发、取消 | `14_coroutines` |
| [15 ⭐Channel与Flow](docs/15-flow.md) | 管道、冷/热流、SharedFlow/StateFlow、Mutex | `15_flow` |
| [16 错误处理](docs/16-errors.md) | try/throw 表达式、Nothing、Result 双轨 | `16_errors` |
| [17 工程化与 Gradle](docs/17-gradle.md) | 多模块、依赖范围、fat jar、JUnit5 | `17_gradle`（工程） |
| [18 ⭐Java 互操作](docs/18-javainterop.md) | 平台类型、@Jvm* 家族、SAM、两遍编译 | `18_javainterop` |
| [19 文件与文本](docs/19-files.md) | useLines、walk、java.time、Regex、JSON 编码 | `19_files` |
| [20 ⭐测试](docs/20-testing.md) | 断言画廊、表驱动、可复现随机、fake | `20_testing` |
| [21 并发线程](docs/21-concurrency.md) | 锁/原子/线程池、ThreadLocal、协程 M:N | `21_concurrency` |
| [22 函数式](docs/22-functional.md) | Sequence 惰性、组合、Either、注入时钟 | `22_functional` |
| [23 ⭐类型安全 DSL](docs/23-dsl.md) | HTML builder、@DslMarker、infix/invoke | `23_dsl` |
| [24 ⭐实战：ktodo](docs/24-todo.md) | 手写 JSON、文件存储、CLI、退出码 | `24_todo` |

## 构建工具链

- Kotlin **2.4.20**（scoop）：`G:\scoop\apps\kotlin\current\`——kotlinc-jvm + kotlin-test/kotlinx-coroutines/kotlin-reflect jar 全套。
- JDK **21**（oraclejdk-lts，scoop）：编译产物与 Gradle 运行环境；PATH 上的 java 8 不可用。
- Gradle **9.7.1**：仅 17 章示例使用（首次构建联网拉插件，约 4 分钟）。
- 控制台中文乱码先 `chcp 65001`；build.ps1 已统一 UTF-8。

## 验证命令

```powershell
cd G:\code\guide\kotlin
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                 # 全部 23 个：四层验证
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_lambdas  # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_lambdas -Update   # 改代码后刷新快照（人工核对再提交）
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean               # 清理全部 build/.gradle
```

单跑某个示例（每章标准学法）——改代码后重跑：

```powershell
cd kotlin\examples\04_nullsafety
# 编译（-Werror：警告即错误）
kotlinc-jvm -Werror -cp "…\lib\kotlin-test.jar" -d build\classes src\*.kt test\*.kt
# 跑测试 / 跑演示（JDK 21 的 java）
java -Dstdout.encoding=UTF-8 -cp "build\classes;…\lib\kotlin-stdlib.jar;…\lib\kotlin-test.jar" TestsKt
java -Dstdout.encoding=UTF-8 -cp "…" MainKt
```

四层验证含义：**L1** kotlinc `-Werror` 零警告编译；**L2** kotlin.test 断言全过（exit 0）；**L3** MainKt 运行 exit 0；**L4** stdout 与 `expected.txt` 逐行一致（快照回归）。17 章的四层是 Gradle build（含 JUnit5）+ fat jar 运行 + 快照。

## 相关教程

同仓对照：[cpp20](../cpp20/README.md)、[zig](../zig/README.md)、[go](../go/README.md)、[rust](../rust/README.md)、[dlang](../dlang/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
