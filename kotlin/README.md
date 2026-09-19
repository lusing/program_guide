# Kotlin 编程指南（2.4.20 / JVM）

面向**会编程（Java/C++/Rust/Go 背景最佳）、初学 Kotlin** 的读者：从零教到现代 Kotlin——**K2 编译器**（2.4.20）、空安全、密封类型与穷尽 when、委托、型变 + reified、作用域函数、扩展、结构化并发协程 + Flow、与 Java 互操作、类型安全 DSL，最后进阶**多平台**（同一份代码编到 JS / Wasm / Native，25 章）。每章"读讲解 → 跑示例 → 改代码再跑"，全部 24 个示例**四层验证**通过（kotlinc `-Werror` 编译 → kotlin.test 测试 → 运行 exit 0 → expected.txt 快照比对）。

> ⚠️ 版本敏感：本机 PATH 上的 `java` 是 8，本教程 build.ps1 自动切换 `JAVA_HOME → JDK 21`；1.x 时代教程的部分写法在 K2 下行为不同。所有代码在 **kotlinc-jvm 2.4.20 + oraclejdk-lts 21** 实测。

## 目录结构

```text
kotlin/
├── README.md        本文件
├── docs/            25 章教程（01 → 24 顺序阅读；25 为多平台进阶专题）
├── examples/        24 个示例（章号 = 目录号）
│   ├── …            21 个 kotlinc 直编示例（src/ + test/ + expected.txt）
│   ├── 17_gradle/   Gradle 多模块工程（lib+app，JUnit5，fat jar——独立构建）
│   ├── 18_javainterop/  Java/Kotlin 混编（javac→kotlinc 两遍法）
│   ├── 24_todo/     实战项目（手写 JSON 解析器 + 文件存储 + CLI）
│   └── 25_multiplatform/  多平台四目标（js/wasm-js/wasm-wasi/native，四份快照）
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
| [25 ⭐多平台：JS/Native/Wasm](docs/25-multiplatform.md) | 四目标编译、expect/actual、cinterop、KMP | `25_multiplatform`（四目标） |

## 构建工具链

两个平台都实测过，入口脚本会自己探测（环境变量 → 平台常见位置 → PATH），不用手改路径：

| 工具 | Windows（scoop） | macOS（MacPorts，本机） |
|---|---|---|
| Kotlin **2.4.20** | `G:\scoop\apps\kotlin\current` | `/opt/local/share/java/kotlin`（kotlinc-jvm / kotlinc-js / kotlinc-wasm 全套 + lib/*.jar + stdlib klib） |
| Kotlin/Native **2.4.20** | `G:\scoop\apps\kotlin-native\current`（konanc；首跑自动下 LLVM 21 约 275MB 到 `~/.konan`） | **本机未安装**（MacPorts 无此包，GitHub 下载不通）→ 25 章 native 目标自动 `[SKIP]`，**未实测** |
| JDK **21** | `G:\scoop\apps\oraclejdk-lts\current` | `/usr/libexec/java_home -v 21` → `/opt/local/.../jdk-21-macports.jdk`（机器上另装了 25/26，PATH 上默认是 26；**konanc 在 JDK ≥ 24 会崩**，所以脚本钉 21） |
| Gradle **9.7.1** | `G:\scoop\apps\gradle\current\bin\gradle.bat` | `/opt/local/bin/gradle`（仅 17 章用；首次构建联网拉插件约 5 分钟） |
| node | 26 | 22（WasmGC 支持够了；跑 wasm-wasi 时 node 会往 **stderr** 打 `ExperimentalWarning: WASI is an experimental feature`，两个入口都按白名单滤除） |

覆盖顺序：`$KOTLIN_HOME` / `$JAVA_HOME` → 平台常见位置 → PATH。Windows 控制台中文乱码先 `chcp 65001`；两个入口都已统一 UTF-8。

## 验证命令（两个入口等价，判定完全一致）

```bash
cd kotlin
./run-all.sh                        # macOS / Linux：全部示例
./run-all.sh 12_lambdas             # 单个示例
./run-all.sh 12_lambdas --update    # 改代码后刷新快照（人工核对再提交）
./run-all.sh --clean                # 清理全部 build/.gradle
```

```powershell
pwsh ./build.ps1 -All                            # Windows（也可在 macOS 上跑）：全部示例
pwsh ./build.ps1 12_lambdas                      # 单个示例（位置参数）
pwsh ./build.ps1 -Example 12_lambdas -Update     # 刷新快照
pwsh ./build.ps1 -Clean                          # 清理
```

**macOS 实测状态（2026-09-19，kotlinc 2.4.20 + JDK 21.0.12 + Gradle 9.7.1 + node 22）**：
`./run-all.sh` 与 `pwsh ./build.ps1 -All` **结论一致 —— 通过 24、失败 0、跳过 1**，退出码 0。
跳过的是 `25_multiplatform/native`：本机没有 Kotlin/Native（MacPorts 无此包），**该目标未在 macOS 实测**。
25 章的 js / wasm-js / wasm-wasi 三目标两个入口都通过。含并发/计时/随机种子的示例（14/15/20/21）连跑三轮无偶发。

单跑某个示例（每章标准学法）——改代码后重跑。**注意 classpath 分隔符：Windows 是 `;`、macOS/Linux 是 `:`**（脚本里自动切换，手敲时要自己换）：

```bash
cd kotlin/examples/04_nullsafety                       # macOS / Linux
L=/opt/local/share/java/kotlin/lib                     # Windows: G:\scoop\apps\kotlin\current\lib
kotlinc-jvm -Werror -cp "$L/kotlin-stdlib.jar:$L/kotlin-test.jar" -d build/classes src/*.kt test/*.kt
java -Dstdout.encoding=UTF-8 -cp "build/classes:$L/kotlin-stdlib.jar:$L/kotlin-test.jar" TestsKt
java -Dstdout.encoding=UTF-8 -cp "build/classes:$L/kotlin-stdlib.jar:$L/kotlin-test.jar" MainKt
```

四层验证含义：

- **L1** kotlinc `-Werror` 编译：退出码 0 **且编译器零输出**（日志非空就算失败 —— 教程示例要求零告警）
- **L2** kotlin.test 断言全过（`TestsKt` exit 0）
- **L3** `MainKt` 运行：exit 0 + **stderr 为空** + **stdout 非空** + stdout 无多余控制字符
- **L4** stdout 与 `expected.txt` 逐行一致（快照回归；CRLF 已归一化、尾部空行已去掉）

17 章的四层是 Gradle build（含 JUnit5）+ fat jar 运行 + 快照；25 章是四目标各 `-Werror` 编译 → 运行 exit 0（断言内嵌 main，非 JVM 目标无 test runner）→ 四份 `expected-<目标>.txt` 快照。

**没有「结束标记」这条判定** —— JVM 示例崩了就是非零退出码、非 JVM 目标崩了也一样，L3 已覆盖；而快照比对本身等价于「输出完整且一字不差」。同理**没有「stdout 不得含诊断字样」这条**：kotlinc/javac/konanc 的诊断都走 stderr（L1 的日志非空与 L3 的 stderr 为空分别盖住了编译期和运行期），加模式匹配只会误伤示例里故意打印的异常文本。

**判定标准反向验证过**（2026-09-19）：临时造了 `examples/99_selftest`，六个坏样例逐条确认**两个入口都报 FAIL 且理由正确**、退出码 1：编译失败 / 往 stderr 打印 / 快照差一个词 / `exitProcess(3)` / main 什么都不打印 / 输出里混 0x07。验完已删除。

> 这一步真抓到过 bug：PowerShell 的 `-ne` **大小写不敏感**，快照比对写成 `-ne` 时「只差大小写」的输出会被判成一致，PS 入口一路绿而 shell 入口报红 → 改成 `-cne`。只跑"全绿"的验证脚本，你并不知道它是不是永远返回通过。

## 相关教程

同仓对照：[cpp20](../cpp20/README.md)、[zig](../zig/README.md)、[go](../go/README.md)、[rust](../rust/README.md)、[dlang](../dlang/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
