# 01 · 全景：Common Lisp 是什么，实现生态长什么样

> 本章无示例（从第 02 章起每章配一个可运行示例 `examples/NN_topic/`）。

## 1.1 一段话定位

Common Lisp 是一门**编译型的、多范式的、可交互开发的**语言：函数式、面向对象（CLOS）、
元编程（宏）都是语言原生能力，而不是后挂的库。它 1984 年成体（Common Lisp the Language）、
**1994 年被 ANSI 标准化**（X3.226-1994），此后语言本体几乎冻结——今天写的代码和三十年前
的标准高度兼容。这份「老」恰恰是优点：标准写尽了语言的所有角落（超过 1000 页），
不同实现按同一份标准做事，可移植代码写起来比大多数「新」语言省心。

一句话：**Common Lisp 是一门「标准先行、实现百花、 REPL 为魂」的语言**。
你写的不是「SBCL 程序」或「CLISP 程序」，而是 Common Lisp 程序，
SBCL / CLISP 只是跑它的两部发动机。

## 1.2 与 Python / Scheme / Clojure 对照

| 特性 | Common Lisp | Python | Scheme | Clojure |
|---|---|---|---|---|
| 标准化 | ANSI 1994，稳定 30 年 | 参考实现即标准（CPython） | 小标准 + 大量 SRFI | 单实现演进 |
| 类型 | 动态 + 完整类型说明符 + 可选声明 | 动态 | 动态 | 动态 + 持久集合 |
| 面向对象 | CLOS（多分派，语言级） | 类单分派 | 库（无标准） | 协议/记录 |
| 错误处理 | 条件系统 + 重启（可恢复） | 异常（栈展开后处理） | 异常（SRFI） | 异常 |
| 元编程 | 宏（编译期，全语言） | 装饰器/eval（弱） | 宏（卫生 syntax-rules） | 宏 |
| 数值塔 | 整数/有理数/复数全内置 | 内置 int/complex | 内置 | 内置比率 |
| 开发节奏 | 镜像常驻，改函数热更新 | 解释执行 | 镜像常驻 | JVM 常驻 |

Scheme 是 Lisp 家族里「极简标准」的一支（教学见长）；Clojure 跑在 JVM 上换走了
持久数据结构路线；Common Lisp 是家族里「大而全、标准冻结」的那一支。

## 1.3 实现生态：一个标准，多部发动机

Common Lisp 只有标准、没有官方实现，各家实现（简称"impl"）按 ANSI CL 实现`CL:`包，
差异全部集中在**边缘**：编译策略、扩展包、启动方式。主流实现一览：

| 实现 | 类型 | 特色 | 本教程角色 |
|---|---|---|---|
| **SBCL** | 编译型（原生代码） | 最快之一、编译诊断最好、线程/FFI 完整 | **主实现**（性能、工程、扩展章） |
| **GNU CLISP** | 字节码解释+编译 | 启动快、映像小、跨平台到怪平台 | **第二实现**（可移植性对照） |
| CCL (Clozure) | 编译型 | 快、macOS 友好 | 认识即可 |
| ECL | 可嵌入 C 库 | 能编译成 C，嵌 App | 认识即可 |
| ABCL | 跑在 JVM | 与 Java 互操作 | 认识即可 |

**本教程的双实现策略**（这是本次升级的核心）：第 02–20 章 + 22/27 章的示例
同时跑在 SBCL **和** CLISP 上，两个通道的 stdout 必须**逐字节一致**；
第 21/23–26 章（ASDF、线程、FFI、性能）是 SBCL 专属扩展，单独成章。
一台机器装两个实现不为别的：**可移植性不是背规则背出来的，是 diff 出来的**。

> **实例**：`most-positive-fixnum` 在 SBCL（x86-64）是 `4611686018427387903`（62 位），
> 在 CLISP（同机）是 `281474976710655`（48 位）。写 `(< x 10000000000)` 这种代码，
> 在 SBCL 是 fixnum 快速比较、在 CLISP 已经掉进 bignum——这就是「别赌 fixnum 位宽」
> 的直观来源（22 章展开）。

## 1.4 标准的边界：ANSI 面 vs 实现扩展

- `COMMON-LISP` 包（写作 `CL:`）里的 ≈978 个符号是**可移植面**：本教程 02–20 章只用它们。
- `SB-EXT` / `SB-THREAD` / `SB-ALIEN` 是 SBCL 的扩展包；CLISP 对应的是 `EXT` / `FFI` 等。
  两家的扩展**互不相通**，要用就 `#+sbcl` / `#+clisp` 分发（22 章的读取器条件）。
- 社区库（Quicklisp 上的 alexandria、bordeaux-threads、cffi）就是「扩展的可移植层」：
  一套 API 底下按 `*features*` 挑实现。26 章讲性能时会看到 bordeaux-threads 这个思路。

## 1.5 工具链一览

两个二进制就是全部：

| 命令 | 用途 | 本教程 |
|---|---|---|
| `sbcl` | REPL / 加载脚本 / 编译 | 主线，02 章起 |
| `clisp` | REPL / 跑脚本（启动快） | 对照通道，22 章 |
| `sbcl --script f.lisp` | 脚本模式（shebang） | 02 章 |
| `clisp f.lisp` | 脚本模式（注意 `-E UTF-8`） | 02 章 |
| `sbcl --load f.lisp` | 可复现加载（验证用） | 全部示例 |
| ASDF | 系统定义（SBCL 内置；CLISP 需自装） | 21 章 |
| Quicklisp | 包管理 | 21 章 |
| SLIME/sly | Emacs 下的 Lisp IDE（社区标配） | 21 章提一笔 |

安装：

```bash
# Linux（Arch）：pacman -S sbcl clisp；Debian/Ubuntu：apt install sbcl clisp
# macOS：port install sbcl clisp   （或 brew install sbcl clisp）
# Windows：scoop install sbcl（CLISP 官网下载 zip）
$ sbcl --version
SBCL 2.6.8
$ clisp --version | head -1
GNU CLISP 2.49.95+ (2024-11-03) ...
```

本教程实测基线：**SBCL 2.6.8 + GNU CLISP 2.49.95（Linux/WSL2）**；
此前版本在 macOS（SBCL 2.6.7）验证过同等内容。

## 1.6 本教程怎么学

- **读者定位**：会编程、看得懂 S 表达式、没系统写过 Lisp。不教编程本身。
- **每章节奏**：读讲解 → 跑示例 → 改代码再跑。示例在 `examples/NN_topic/main.lisp`，
  章号 = 目录号。
- **双通道验证**：`run-all.sh`（macOS/Linux）或 `build.ps1`（Windows）对每个示例执行
  四条判定（退出码 0 + stderr 空 + 无控制字符 + 结束标记），双通道示例再加一条
  **SBCL/CLISP 输出逐字节一致**——全部通过才收工。
- **正文里的 `; =>` 断言**都由 `verify-guide.py` 在 SBCL 上逐条回跑核验（mismatch 0）；
  涉及 CLISP 差异的输出会在文中显式标注「CLISP 下是……」。
- 与本仓库其他教程对照：[clojure](../clojure/README.md)（Lisp 家族、JVM 系）、
  [haskell](../haskell/README.md)（同为「老而稳」标准系函数语言）、
  [emacs](../emacs/README.md)（另一门 Lisp 方言）。

## 1.7 坑位清单

1. **「Common Lisp」不是「LISP」也不是「CommonLisp」**：上古 LISP 1.5、Maclisp、
   Interlisp 都不是它；一门教程如果教你 `prog`/`rplaca` 满天飞、没有包系统，那是方言考古。
2. **别把实现当语言**：网上代码写着 `sb-ext:...` 就直接抄到别的实现，必挂。
   扩展要么 `#+` 分发，要么用可移植库（22 章）。
3. **CLISP 的默认编码跟 locale 走**：在 `LANG` 未设/ASCII 的终端里，CLISP 读写中文
   直接报 `Invalid byte #xE4 in CHARSET:ASCII conversion`。统一加 `-E UTF-8`
   （本仓库验证脚本已内置）。
4. **SBCL 没有 REPL 之外的解释器**：它连 `--load` 都是「逐段编译执行」，
   所以编译警告（style-warning）会随时打到你脸上——这是特性不是缺陷（21 章调优姿势）。
5. **教程版本口径**：网上大量 CL 教材基于 1990 年代工具链（ILISP、CMUCL 时代），
   命令细节（如 `clisp -q -q` 的重复次数）以实现 `--help` 为准。
