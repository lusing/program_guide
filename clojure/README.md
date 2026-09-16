# Clojure 教程与示例

Clojure 入门到进阶，配套 20 个可运行示例，在 Clojure CLI（`clojure` 1.12.6.1673 / Clojure 1.12.6）上验证通过。

这里不是「语法速览」。函数式数据转换（`map` / `filter` / `reduce`）、惰性序列、解构、宏系统、多方法、记录与协议、引用类型与并发（`atom` / `ref` / `agent` / `future`）、Java 互操作、`clojure.spec`、Transducer、以及标准库的惯用写法，都在示例里实打实跑过。

## 目录结构

```text
clojure/
├── README.md                    本文件
├── Clojure编程指南.md           教程正文（25 章）
├── deps.edn                     Clojure CLI 项目描述
├── build.sh                     跨平台构建/验证入口
└── examples/
    ├── 01_hello.clj              Hello World、REPL 基础、基本输出
    ├── 02_data_types.clj         数字、字符串、关键字、布尔、nil、比值
    ├── 03_collections.clj        列表、向量、映射、集合、队列
    ├── 04_functions.clj          defn、参数模型、匿名函数、闭包
    ├── 05_control_flow.clj       if / when / cond / case / 逻辑运算
    ├── 06_destructuring.clj      顺序解构、关联解构、:as / :or
    ├── 07_higher_order.clj       map / filter / reduce / partial / comp
    ├── 08_lazy_seqs.clj          惰性序列、range / iterate / for
    ├── 09_macros.clj             defmacro、syntax-quote、unquote
    ├── 10_multimethods.clj       defmulti / defmethod、层级分发
    ├── 11_records_protocols.clj  defrecord / defprotocol / reify
    ├── 12_concurrency.clj        atom / ref / agent / future / STM
    ├── 13_java_interop.clj       Java 互操作、. / .. / doto / proxy
    ├── 14_file_io.clj            文件读写、slurp / spit / with-open / edn
    ├── 15_namespaces.clj         ns / require / 引用别名
    ├── 16_testing.clj           clojure.test、deftest / is / are
    ├── 17_spec.clj              clojure.spec.alpha、s/def / s/fdef
    ├── 18_transducers.clj        Transducer、into / comp / transduce
    ├── 19_algorithms.clj         经典算法：排序、搜索、斐波那契
    └── 20_project.clj            综合实战：数据分析管线
```

## 工具链

| 工具 | 路径候选 | 定位 |
|---|---|---|
| `clojure` | `/opt/local/bin/clojure`、`/usr/local/bin/clojure` | Clojure CLI，运行脚本、REPL、依赖管理 |
| `java` | `/usr/bin/java`、`/opt/local/bin/java` | JVM 运行时，Clojure 的底层平台 |

验证安装：

```bash
clojure --version          # 查看 Clojure CLI 版本
clojure -e '(println (clojure-version))'   # 查看 Clojure 语言版本
```

> 如果系统 PATH 中有不兼容的 `java`，需要设置 `JAVA_CMD=/usr/bin/java` 环境变量。

## 构建与验证

使用 `build.sh` 调用 `clojure -M` 运行示例，日志输出到 `build/` 目录。

| 命令 | 说明 |
|---|---|
| `./build.sh --all` | 运行全部 20 个示例 |
| `./build.sh --file 01_hello.clj` | 运行单个示例 |
| `./build.sh --file 01` | 只写编号也行 |
| `./build.sh --clean` | 清理 build 目录 |

Bash：

```bash
cd /Users/xulun/code/programming/clojure
./build.sh --all                 # 运行全部 20 个示例
./build.sh --file 01_hello.clj  # 运行单个示例
./build.sh --clean              # 清理 build 目录
```

### 判定标准

1. **退出码为 0** —— `clojure -M` 执行成功
2. **stdout 里出现结束标记** `==== NN jieshu ====` —— 证明程序完整执行到结尾
3. **build/ 目录下生成日志** —— `.log` 文件记录完整输出

失败时 `build.sh` 返回退出码 1，可以直接拿去做回归。

> 关于中文：本教程的字符串字面量里只写 ASCII，中文全部放注释。这样可以确保代码在所有环境中都能正确运行。需要输出中文时可以通过 `println` 或字符串拼接的方式，但本示例集为了可移植性统一使用英文输出。

## 各章索引

| 章 | 主题 | 关键内容 |
|---|---|---|
| 1 | 认识 Clojure | Clojure 的定位、Lisp 家族、JVM 宿主、函数式 + 不可变优先、REPL 驱动开发 |
| 2 | 工具链与运行方式 | `clojure` CLI 三种模式（`-M` / `-X` / `-A`）、REPL、deps.edn |
| 3 | Hello World 与基本输出 | `println` / `prn` / `print` / `str`、`def`、注释（示例 01） |
| 4 | 数据类型 | 整数、浮点、比值、字符串、字符、关键字、`nil`、布尔值（示例 02） |
| 5 | 集合 | 列表、向量、映射、集合、队列、集合函数（示例 03） |
| 6 | 函数与闭包 | `defn`、参数模型、可变参数、匿名函数、闭包、`apply`（示例 04） |
| 7 | 控制流 | `if` / `when` / `cond` / `case`、`when-not` / `when-let`、逻辑短路（示例 05） |
| 8 | 解构 | 顺序解构、关联解构、`:as` / `:or` / `:keys`、嵌套解构（示例 06） |
| 9 | 高阶函数 | `map` / `filter` / `reduce`、`partial` / `complement` / `comp`、`keep` / `mapcat`（示例 07） |
| 10 | 惰性序列 | `seq` / `lazy-seq`、`range` / `iterate` / `cycle`、`take` / `drop`、`for`（示例 08） |
| 11 | 宏与元编程 | `defmacro`、syntax-quote、unquote、`macroexpand`、 hygiene（示例 09） |
| 12 | 多方法 | `defmulti` / `defmethod`、层级关系 `derive` / `isa?`、分发（示例 10） |
| 13 | 记录与协议 | `defrecord` / `defprotocol` / `reify` / `extend-type`（示例 11） |
| 14 | 并发与引用类型 | `atom` / `ref` / `agent` / `future`、STM、`pmap`（示例 12） |
| 15 | Java 互操作 | `.` / `..` / `doto` / `proxy` / `gen-class`、异常处理（示例 13） |
| 16 | 文件与 I/O | `slurp` / `spit` / `with-open` / `edn` 读写、`clojure.java.io`（示例 14） |
| 17 | 命名空间 | `ns` / `require` / `refer` / `:as` 别名、`load`（示例 15） |
| 18 | 测试 | `clojure.test` / `deftest` / `is` / `are` / `testing`（示例 16） |
| 19 | clojure.spec | `s/def` / `s/fdef` / `s/valid?` / `s/conform`、instrumentation（示例 17） |
| 20 | Transducer | `into` / `comp` / `transduce` / `cat` / `dedupe`（示例 18） |
| 21 | 经典算法 | 快速排序、归并排序、二分查找、斐波那契记忆化（示例 19） |
| 22 | 综合实战 | 成绩 CSV 分析管线、聚合、报告生成（示例 20） |
| 23 | 性能与优化 | 类型提示、瞬态数据结构、数组访问、性能基准 |
| 24 | Web 开发概览 | Ring / Compojure / Reitit / Pedestal 简介 |
| 25 | 生态与工具 | Leiningen vs Clojure CLI、CIDER / Calva、shadow-cljs、ClojureScript |

## 当前状态

20 个示例在 `clojure` CLI（Clojure 1.12.6）上验证通过，REPL 可直接加载运行。
