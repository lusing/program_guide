# Clojure 编程指南（1.12 / Leiningen 2.13）

面向**会编程、初学 Clojure** 的读者：从 S-表达式讲到能写出自己的 Lisp 解释器。**28 章文档 + 24 个可运行示例 + 1 个 Leiningen 工程**，每章"读讲解 → 跑示例 → 改代码再跑"。Clojure 特色全部独立成章细讲：集合与持久化（05）、函数与闭包（06）、解构（08）、高阶函数与线程宏（09）、惰性序列（10）、宏（11）、并发与引用类型（14）、Transducer（20）、core.async（24）、Ring Web（25）、性能优化（23）、压轴 MiniLisp 解释器（28）。

> 双工具链验证：**Windows = Leiningen 2.13 + OpenJDK 26**（`build.ps1`，25 个验证单元全绿）；**macOS/Linux = Clojure CLI 1.12.6**（`build.sh`）。两侧依赖声明（`project.clj` / `deps.edn`）一致。所有坑位实测收录在 [CHEATSheet.md](CHEATSheet.md)。

## 目录结构

```text
clojure/
├── README.md               本文件
├── docs/                   28 章教程（01 → 28 顺序阅读）
├── CHEATSheet.md           语法速查 + 语言坑 L1-L46 + Windows 坑 W1-W8
├── examples/               24 个示例脚本（单文件、可直接跑）
│   ├── 01_hello.clj ...    章 3-20 → 01-18
│   └── 19-24_*.clj         章 21-25 / 28 → 19-24
├── lein-lab/               Leiningen 工程（章 26：test/run/uberjar/java -jar）
├── project.clj             Leiningen 依赖描述（Windows 侧）
├── deps.edn                Clojure CLI 依赖描述（macOS/Linux 侧）
├── build.ps1               Windows 构建入口（pwsh 7+，无 BOM）
├── build.sh                macOS/Linux 构建入口（Clojure CLI）
└── build/                  验证日志（不入库）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 ⭐认识 Clojure](docs/01-overview.md) | 三根支柱、值/标识/时间、Lisp 家族对照、Lisp-1 澄清 | — |
| [02 工具链与运行方式](docs/02-toolchain.md) | CLI 三模式、deps.edn、lein 对照、REPL 工作流、JAVA_CMD 坑 | — |
| [03 Hello World](docs/03-hello.md) | 输出四函数、str/format、def/defn、注释三件套、-main | `01_hello` |
| [04 数据类型](docs/04-data-types.md) | 比值、BigInt 升位、关键字、真值语义（只有两个假）、NaN | `02_data_types` |
| [05 ⭐集合](docs/05-collections.md) | 四种集合、结构共享（32 叉树）、seq 抽象、-in 家族、相等语义 | `03_collections` |
| [06 ⭐函数与闭包](docs/06-functions.md) | 多 arity、键值尾参、闭包、IFn 广义调用（坑王 Symbol） | `04_functions` |
| [07 ⭐控制流](docs/07-control-flow.md) | 一切皆表达式、cond 家族、and/or 语义、loop/recur TCO | `05_control_flow` |
| [08 ⭐解构](docs/08-destructuring.md) | 顺序/关联/嵌套、:or/:as、参数解构即文档 | `06_destructuring` |
| [09 ⭐高阶函数](docs/09-higher-order.md) | 三板斧、线程宏全家、juxt 多级排序、group-by 双子星 | `07_higher_order` |
| [10 ⭐惰性序列](docs/10-lazy-seqs.md) | 无限流、lazy-seq 模板、chunk=32、头部驻留泄漏 | `08_lazy_seqs` |
| [11 ⭐宏与元编程](docs/11-macros.md) | quote 家族、gensym 卫生、"只求值一次"、macroexpand 调试 | `09_macros` |
| [12 多方法](docs/12-multimethods.md) | 任意分发函数、derive/isa? 层级、vs 协议选型表 | `10_multimethods` |
| [13 记录与协议](docs/13-records-protocols.md) | defrecord/defprotocol/reify/extend-*、record≠map 相等 | `11_records_protocols` |
| [14 ⭐并发与引用类型](docs/14-concurrency.md) | atom/STM/agent/future 选型表、validator/watcher、重试语义 | `12_concurrency` |
| [15 Java 互操作](docs/15-java-interop.md) | 调用四式、doto、数组三宏、proxy/reify、类型提示 | `13_java_interop` |
| [16 文件与 I/O](docs/16-file-io.md) | slurp/spit、with-open 铁律、EDN vs read-string 安全 | `14_file_io` |
| [17 命名空间](docs/17-namespaces.md) | ns 解剖、ns→路径硬规则、:reload 热加载、REPL 内省 | `15_namespaces` |
| [18 测试](docs/18-testing.md) | deftest/is/are/testing、fixtures、表驱动、退出码 | `16_testing` |
| [19 clojure.spec](docs/19-spec.md) | s/def 注册表、s/cat 正则操作符、fdef+instrument、生成测试 | `17_spec` |
| [20 ⭐Transducer](docs/20-transducers.md) | rf→rf 本质、四大入口、cat/halt-when、自定义模板 | `18_transducers` |
| [21 经典算法](docs/21-algorithms.md) | 三路快排（丢 pivot 实测案）、筛法、Kahn、Dijkstra | `19_algorithms` |
| [22 综合实战：成绩管线](docs/22-project.md) | CSV→验证→富化→聚合→EDN 报告的数据管线设计 | `20_project` |
| [23 ⭐性能与优化](docs/23-performance.md) | 反射 537 倍实测、装箱、transient、数组 26 倍、决策树 | `21_performance` |
| [24 ⭐core.async](docs/24-core-async.md) | go 停车 vs 阻塞、工作池、alts!!/timeout、三种缓冲 | `22_core_async` |
| [25 Web 实战：Ring](docs/25-ring-web.md) | map 进 map 出、手写路由、中间件、Jetty 真实 HTTP | `23_ring_web` |
| [26 Leiningen 项目实战](docs/26-leiningen.md) | 布局规则、profile、四步验证链、AOT/gen-class | `lein-lab/` |
| [27 生态与工具](docs/27-ecosystem.md) | 编辑器、库地图、ClojureScript、babashka、资源 | — |
| [28 ⭐压轴：MiniLisp 解释器](docs/28-minilisp.md) | tokenizer→parser→env 链→TCO 求值器、Symbol 静默坑实录 | `24_minilisp` |

## 构建与验证

### Windows（pwsh 7+，脚本无 BOM）

| 命令 | 说明 |
|---|---|
| `pwsh build.ps1 -All` | 24 示例 + lein-lab 四步链（25 验证单元） |
| `pwsh build.ps1 -File 24` | 单跑一个示例（编号 / 文件名均可） |
| `pwsh build.ps1 -Lab` | lein-lab：test → run → uberjar → java -jar |
| `pwsh build.ps1 -Clean` | 清理 build/ 与 target/ |

工具链：`lein` 在 `G:\scoop\apps\leiningen\current`（2.13.0）；JDK 探测自动跳过 PATH 里的 Java 8（lein 2.13 需要 JDK 16+，见 CHEATSheet W1）。

### macOS / Linux（Clojure CLI）

```bash
./build.sh --all            # 全部示例
./build.sh --lab            # lein-lab 四步链
./build.sh --file 01_hello.clj
```

前置：JDK + Clojure CLI（`--lab` 另需 Leiningen），安装步骤见 [02 章](docs/02-toolchain.md)。

### 判定标准（三层）

1. 退出码 0；2. stdout 出现结束标记 `==== NN jieshu ====`（lab 为 `==== LAB jieshu ====`）；3. `build/` 生成 `.log`。算法类示例另有 `(= (sort x) (f x))` 对账断言（CHEATSheet W8 的教训）。

## 依赖版本

Clojure 1.12.6 · core.async 1.9.865 · ring/ring-core + ring-jetty-adapter 1.15.5（Jetty 12.1.8；ring 在 **Clojars**）。示例字符串只写 ASCII、中文进注释，绕开控制台编码差异。
