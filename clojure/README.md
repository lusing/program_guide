# Clojure 教程与示例

Clojure 入门到进阶，配套 24 个可运行示例 + 1 个 Leiningen 工程，教程正文 28 章（`Clojure编程指南.md`）。

双工具链验证：macOS/Linux 用 **Clojure CLI 1.12.6**（`build.sh`），Windows 用 **Leiningen 2.13.0 + OpenJDK 26**（`build.ps1`），两侧依赖声明（`deps.edn` / `project.clj`）一致。

这里不是「语法速览」。函数式数据转换（`map` / `filter` / `reduce`）、惰性序列、解构、宏系统、多方法、记录与协议、引用类型与并发（`atom` / `ref` / `agent` / `future`）、Java 互操作、`clojure.spec`、Transducer、性能优化（类型提示实测 537 倍）、core.async、Ring Web（嵌入式 Jetty 起真服务器发真请求）、Leiningen 全流程（test → run → uberjar → java -jar），以及压轴的 MiniLisp 解释器，都在示例里实打实跑过。

## 目录结构

```text
clojure/
├── README.md                    本文件
├── Clojure编程指南.md           教程正文（28 章）
├── deps.edn                     Clojure CLI 依赖描述（macOS/Linux 侧）
├── project.clj                  Leiningen 工程描述（Windows 侧）
├── build.sh                     macOS/Linux 构建入口（Clojure CLI）
├── build.ps1                    Windows 构建入口（Leiningen，需 pwsh 7+，无 BOM）
├── examples/                    24 个示例脚本（章 3-20 → 01-18，章 21-25/28 → 19-24）
│   ├── 01_hello.clj             Hello World、REPL 基础、基本输出
│   ├── 02_data_types.clj        数字、字符串、关键字、布尔、nil、比值
│   ├── 03_collections.clj       列表、向量、映射、集合、队列
│   ├── 04_functions.clj         defn、参数模型、匿名函数、闭包
│   ├── 05_control_flow.clj      if / when / cond / case / 逻辑运算
│   ├── 06_destructuring.clj     顺序解构、关联解构、:as / :or
│   ├── 07_higher_order.clj      map / filter / reduce / partial / comp
│   ├── 08_lazy_seqs.clj         惰性序列、range / iterate / for
│   ├── 09_macros.clj            defmacro、syntax-quote、unquote
│   ├── 10_multimethods.clj      defmulti / defmethod、层级分发
│   ├── 11_records_protocols.clj defrecord / defprotocol / reify
│   ├── 12_concurrency.clj       atom / ref / agent / future / STM
│   ├── 13_java_interop.clj      Java 互操作、. / .. / doto / proxy
│   ├── 14_file_io.clj           文件读写、slurp / spit / with-open / edn
│   ├── 15_namespaces.clj        ns / require / 引用别名
│   ├── 16_testing.clj           clojure.test、deftest / is / are
│   ├── 17_spec.clj              clojure.spec.alpha、s/def / s/fdef
│   ├── 18_transducers.clj       Transducer、into / comp / transduce
│   ├── 19_algorithms.clj        经典算法：排序、搜索、斐波那契
│   ├── 20_project.clj           综合实战：成绩数据分析管线
│   ├── 21_performance.clj       性能：类型提示 / 瞬态 / 数组 / memoize
│   ├── 22_core_async.clj        core.async：channel / go / 工作池 / pipeline
│   ├── 23_ring_web.clj          Ring：handler / 中间件 / Jetty 真实 HTTP
│   └── 24_minilisp.clj          压轴：MiniLisp 解释器（TCO，33 断言）
└── lein-lab/                    Leiningen 工程实战（test/run/uberjar/java -jar）
    ├── project.clj              defproject / :main / :profiles / :aot
    ├── src/lein_lab/            core.clj（入口）+ text.clj（工具）
    └── test/lein_lab/           core_test.clj（6 tests / 15 assertions）
```

## 工具链

| 工具 | Windows 实测位置 | 定位 |
|---|---|---|
| `lein` | `G:\scoop\apps\leiningen\current`（2.13.0） | 依赖解析 + classpath + lein-lab 工程全流程 |
| `java` | `G:\scoop\apps\openjdk\current`（26.0.2.1） | 实际执行（`clojure.main`） |
| `clojure` CLI | macOS 侧 `/opt/local/bin/clojure`（1.12.6） | macOS/Linux 构建入口 |

验证安装：

```powershell
# Windows：lein 需要显式指定 JDK（见下方坑 1）
$env:JAVA_CMD = 'G:\scoop\apps\openjdk\current\bin\java.exe'
lein version            # Leiningen 2.13.0 on Java 26.0.2.1 ...
```

## 构建与验证

### Windows（pwsh 7+，脚本无 BOM）

| 命令 | 说明 |
|---|---|
| `pwsh build.ps1 -All` | 运行全部 24 个示例 + lein-lab 四步链（25 个验证单元） |
| `pwsh build.ps1 -File 24` | 运行单个示例（编号 / 文件名均可） |
| `pwsh build.ps1 -File 01_hello.clj` | 同上 |
| `pwsh build.ps1 -Lab` | 只跑 lein-lab（test → run → uberjar → java -jar） |
| `pwsh build.ps1 -Clean` | 清理 build/ 与 target/ |

### macOS / Linux（Clojure CLI）

```bash
./build.sh --all                 # 运行全部示例（clojure -M）
./build.sh --file 01_hello.clj   # 运行单个示例
./build.sh --clean               # 清理 build 目录
```

### 判定标准（三层）

1. **退出码为 0** —— java / lein 执行成功
2. **stdout 出现结束标记** `==== NN jieshu ====`（lein-lab 为 `==== LAB jieshu ====`）—— 证明程序完整执行到结尾
3. **build/ 目录生成 .log 日志** —— 记录完整输出

失败时脚本退出码 1，可直接拿去做回归。

> 关于中文：示例的字符串字面量只写 ASCII，中文全部放注释，保证在任何控制台编码下都能正确运行。

## 各章索引

| 章 | 主题 | 关键内容 |
|---|---|---|
| 1 | 认识 Clojure | 定位、Lisp 家族（Lisp-1）、JVM 宿主、REPL 驱动开发 |
| 2 | 工具链与运行方式 | Clojure CLI 三模式、deps.edn、**Leiningen 对照** |
| 3 | Hello World 与基本输出 | `println` / `prn` / `str`、`def`、注释（示例 01） |
| 4 | 数据类型 | 整数、浮点、比值、字符串、关键字、`nil`、布尔（示例 02） |
| 5 | 集合 | 列表、向量、映射、集合、队列（示例 03） |
| 6 | 函数与闭包 | `defn`、参数模型、可变参数、闭包、`apply`（示例 04） |
| 7 | 控制流 | `if` / `when` / `cond` / `case`、逻辑短路（示例 05） |
| 8 | 解构 | 顺序/关联解构、`:as` / `:or` / `:keys`、嵌套（示例 06） |
| 9 | 高阶函数 | `map` / `filter` / `reduce`、`partial` / `comp`、`juxt`（示例 07） |
| 10 | 惰性序列 | `lazy-seq`、`range` / `iterate` / `cycle`、`for`（示例 08） |
| 11 | 宏与元编程 | `defmacro`、syntax-quote、unquote、`macroexpand`（示例 09） |
| 12 | 多方法 | `defmulti` / `defmethod`、`derive` / `isa?`（示例 10） |
| 13 | 记录与协议 | `defrecord` / `defprotocol` / `reify` / `extend-type`（示例 11） |
| 14 | 并发与引用类型 | `atom` / `ref` / `agent` / `future`、STM、`pmap`（示例 12） |
| 15 | Java 互操作 | `.` / `..` / `doto` / `proxy`、异常处理（示例 13） |
| 16 | 文件与 I/O | `slurp` / `spit` / `with-open` / EDN（示例 14） |
| 17 | 命名空间 | `ns` / `require` / `:as` 别名、`load`（示例 15） |
| 18 | 测试 | `clojure.test` / `deftest` / `is` / `are` / `testing`（示例 16） |
| 19 | clojure.spec | `s/def` / `s/fdef` / `s/valid?` / `s/conform`（示例 17） |
| 20 | Transducer | `into` / `comp` / `transduce` / `cat` / `dedupe`（示例 18） |
| 21 | 经典算法 | 快排、归并、二分查找、斐波那契记忆化（示例 19） |
| 22 | 综合实战：成绩管线 | CSV 解析、聚合、报告生成（示例 20） |
| 23 | 性能与优化 | 类型提示（537 倍）、瞬态、数组（26 倍）、memoize（示例 21） |
| 24 | core.async | channel / go / 工作池 / alts!! / pipeline / 缓冲策略（示例 22） |
| 25 | Web 开发实战：Ring | handler / 中间件 / Jetty 真实 HTTP 全链路（示例 23） |
| 26 | Leiningen 项目实战 | 布局 / profile / test / uberjar / java -jar（lein-lab） |
| 27 | 生态与工具 | CLI vs Lein、编辑器、核心库、ClojureScript |
| 28 | 压轴：MiniLisp 解释器 | tokenizer / parser / env 链 / TCO / 脱糖（示例 24） |

## Windows 实测坑（全部踩过并有对策）

1. **PATH 里的 java 是 8，lein 2.13 直接崩**：启动器传 `--enable-native-access=ALL-UNNAMED`，Java 8 报 `Unrecognized option`。且 `lein.bat` 只认 `JAVA_CMD`（不认 `JAVA_HOME`）。对策：`build.ps1` 自动探测 JDK 16+ 并设 `JAVA_CMD`。
2. **PowerShell 拆散 JVM 参数**：`& java -Dfile.encoding=UTF-8 -cp ...` 会被拆成 `-Dfile` + `.encoding=UTF-8`（ClassNotFoundException: .encoding=UTF-8）。对策：参数逐个加引号成串传递：`& $java '-Dfile.encoding=UTF-8' '-cp' $cp 'clojure.main' $file`。
3. **`/tmp` 硬编码**：原示例 13/14 用 `/tmp/...`，Windows 下变成 `G:\tmp`。对策：改用 `java.io.tmpdir` / 项目内 `build/tmp`。
4. **`HttpURLConnection` 的方法必须大写**：`(name :get)` 传给 `setRequestMethod` 报 `Invalid HTTP method: get`。
5. **POST 不设 Content-Type 会被按表单解析**：HttpURLConnection 默认 `x-www-form-urlencoded`，Ring 的 `wrap-params` 会吃掉 body。对策：显式 `Content-Type: text/plain`。
6. **`areduce`/`amap` 对 def var 触发反射**：绑定到 `^ints` 局部变量再喂给宏。
7. **Symbol 是可调用的（静默坑）**：内置表写成 `{'* '*}` 时 `*` 查到符号而非函数，`('* 2 3)` 走 `(get 2 * 3)` 返回 3，全程无异常。只能靠断言抓。
8. **`(try ...)` 不能放进 PS 分组表达式**：`$x = (cd d; try {...} finally {...})` 是语法错误。对策：辅助函数 + `finally` 内 Pop-Location。
9. **Clojars 偶发 SSL 握手失败**：`lein deps` 重试即可；首次拉依赖需要网络可达 Maven Central + Clojars（ring 系列在 Clojars，不在 Central）。
10. **SLF4J NOP 警告**：Jetty 12 只带 API 不带实现，无害；加 logback 依赖消除。

## 当前状态

- 24 个示例 + lein-lab 全链路在 **Windows 11 / Leiningen 2.13.0 / OpenJDK 26.0.2 / Clojure 1.12.6** 上全量验证通过（`pwsh build.ps1 -All`，25 个验证单元全绿）。
- 此前 20 个示例曾在 **macOS / Clojure CLI 1.12.6** 上验证通过（`./build.sh --all`）；`build.sh` 沿用，新增示例同样兼容（依赖已写入 `deps.edn`）。
- 依赖版本：Clojure 1.12.6、core.async 1.9.865、ring/ring-core + ring-jetty-adapter 1.15.5（Jetty 12.1.8）。
