# 02 · 工具链与交互方式

上一章我们知道了 Agda「类型检查通过即证明成立」，那么一个自然的工程问题浮出水面：
**我们通过什么命令、在什么界面里完成这次「检查」？** Agda 的答案有三层：命令行
`agda` 负责一次性检查与编译；`.agda-lib` 机制负责让标准库和自家模块互相找到对方；
Emacs 的 `agda2-mode` 负责日常开发中的「对话式」构造证明。本章把这三层全部实测一遍——
包括 Agda 2.8 与 Debian 打包特有的几个坑（`DEPENDS` 字段失效、`--ignore-interfaces`
炸权限、`--emacs-mode=locate` 指向不存在的路径），它们值得你在动手前就知道。

对应示例：`../examples/Ex02_toolchain.agda`

本章所有命令行输出、报错文本、协议报文均为 Agda 2.8.0 实测原样粘贴（部分路径为
复现方便用了临时目录，已标注），这也是全书引用报错的规矩：**没跑过的输出不上墙**。

## 2.1 agda 命令行：检查是主业

### 版本与帮助

```bash
$ agda --version
Agda version 2.8.0
Built with flags (cabal -f)
 - optimise-heavily: extra optimisations
```

`agda --help` 篇幅很长（光 `--guardedness`、`--cubical` 这类语言特性开关就有几十个）。
三个帮助主题值得记住：`--help=warning`（警告码）、`--help=error`（报错码）、
`--help=emacs-mode`（Emacs 模式设置）。本教程用到哪个开关就现场讲哪个。

### 检查一个文件

```bash
$ cd agda
$ agda examples/Ex01_intro.agda
Checking Ex01_intro (/home/xulun/code/programming/agda/examples/Ex01_intro.agda).
$ echo $?
0
```

三个实测事实：

1. **输出就一行 `Checking 模块名 (绝对路径).`**，没有任何「OK」字样——成功是沉默的；
2. **退出码是判定标准**：类型错误为 42，命令行参数错误为 71。写 CI 请认退出码，别 grep 输出；
3. **同一文件第二次检查完全静默**（`_build/` 缓存生效，见 2.6 节）。想强制重检查，
   可靠做法是删项目 `_build/`，而不是 `--ignore-interfaces`——原因见 2.6 节实测。

还有个轻量模式 `--only-scope-checking`：只检查「名字找不找得到」而**不做类型检查**。
Agda 没有内建的「故意让检查失败」设施，CI 里想验证「某名字不在 scope 内」，
这个开关加退出码就能搭出等价物。

### 报错怎么读

以 01 章撞过的坑为例（真实输出）：

```text
/home/xulun/code/programming/agda/examples/TmpCh02Imp.agda:4.7-8: error: [NotInScope]
Not in scope:
  +
  at /home/xulun/code/programming/agda/examples/TmpCh02Imp.agda:4.7-8
    (did you mean 'Data.Nat._+_'?)
when scope checking +
```

每份报错的骨架都是：**`文件:起始行.列-结束行.列: error: [错误标签]`**，
然后是解释、相关位置、`when ...` 出错语境。几个实用细节：

- 标签（如 `[NotInScope]`）是稳定的机器可读名，`--help=error` 能列出全部；
  搜资料时直接搜标签比搜自然语言准；
- `(did you mean ...?)` 提示经常就是答案——上图的意思是
  「你 `import Data.Nat` 了但没有 `open`，所以 `+` 还躲在限定名里」；
- 位置范围可以横跨多行：终止性检查报错的范围从类型签名起、到子句结束
  （01 章实测的 `[TerminationIssue]` 就是 `5.1-6.16`），别以为报错报错了地方。

## 2.2 标准库与 .agda-lib 机制（实测讲透）

Agda 找模块的规则只有一句话：**在所有「include 路径」下按模块名找同名文件**。
标准库、本教程的 examples/、你自己的工程，全部靠同一机制进场。

### ~/.agda/libraries：库注册表

`~/.agda/libraries` 是一个纯文本文件，每行一个 `.agda-lib` 文件的路径。本机实测：

```bash
$ cat ~/.agda/libraries
/usr/share/agda-stdlib/standard-library.agda-lib
$ cat /usr/share/agda-stdlib/standard-library.agda-lib
name: standard-library-2.3
include: src
flags:
  --warning=noUnsupportedIndexedMatch
```

`name:` 才是库的**身份证名**（不是文件名！），所以命令行引用它要用：

```bash
agda -l standard-library-2.3 ...
```

这正是 README「平台差异」一节说的「在 `~/.agda/libraries` 注册后用 `-l` 引用」——
注意 Debian 包里库名叫 `standard-library-2.3`（来自 `name:` 字段），不是 `standard-library`。

### .agda-lib 的字段与 include 多路径写法

一个库文件支持的字段（本机实测有效）：`name`（必填）、`include`（路径列表）、
`depend`（依赖的其他注册库名）、`flags`（附加命令行开关）、`hidden`。其中
`include` 支持两种等价写法，本教程的 `AgdaTutorial.agda-lib` 用的是单行空格分隔：

```text
name: agda-tutorial
include: examples /usr/share/agda-stdlib/src
```

即一行里放多个路径，空格分隔。多行「缩进续行」写法也实测通过（第二行起缩进）：

```text
include: examples
  /usr/share/agda-stdlib/src
```

两种都验证过（用临时项目跑检查，退出码 0）。本教程刻意把 `examples` 与标准库
`src` 塞进**同一个库的 include**，而不是用 `depend` 依赖标准库——原因见下一小节。

### 项目根自动发现

检查某文件时，Agda 会**从该文件所在目录逐级向上找 `.agda-lib` 文件**；找到后这个
目录就叫「项目根（project root）」，它的 include 自动生效——不需要 `-l`。
实测：临时目录里放一个 `DemoProj.agda-lib`（`include: examples /usr/share/agda-stdlib/src`），
然后

```bash
$ agda examples/Hello.agda      # 文件里 import Data.Nat
Checking Hello (/tmp/agda-proj/examples/Hello.agda).
```

标准库就这样被找到了。在教程项目里 `cd agda && agda examples/ExNN_xxx.agda` 的
零参数可用性完全依赖这条规则。

相关实测坑位：**一个项目根目录里最多只许放一个 `.agda-lib` 文件**，否则（哪怕你
显式 `-l` 了别的库）直接报错：

```text
/tmp/agda-lab/Dep.agda:1.1: error: [LibraryError]
The project root /tmp/agda-lab
may contain only one .agda-lib file, but I found several:
- Dep.agda-lib
- Dep2.agda-lib
```

### DEPENDS 不识别：只认小写 depend（实测）

见过有人把 CMake/Stackage 风格的大写字段名搬过来。在 2.8 实测，`DEPENDS` 是
**未知字段**，只给警告、不生效；而且如果它和别的库挤在同一个项目根，还会叠加触发
上一条坑。构造 `libB`（`DEPENDS: lib-a`，include 里故意不含 `lib-a` 的路径）后检查
`libB/src/Bar.agda`（它 `import Foo`，而 `Foo` 在 `lib-a` 里）：

```text
warning: -W[no]LibUnknownField
/tmp/agda-lab4/libB/libB.agda-lib: Unknown field 'DEPENDS'

/tmp/agda-lab4/libB/src/Bar.agda:2.1-11: error: [FileNotFound]
Failed to find source of module Foo in any of the following locations:
  /tmp/agda-lab4/libB/src/Foo.agda
  ...
```

把字段改成小写 `depend: lib-a` 后，同一命令的输出多了一行
`Checking Foo (/tmp/agda-lab4/libA/src/Foo.agda).`——依赖被真实拉起来了。
结论：**字段名是 `depend`，写错大小写不会硬失败，只会「静默少依赖 + 一条容易被
忽略的警告」**——这比硬报错阴险得多。本教程用 `include` 双路径绕开它，你写自己
项目时要么记住小写，要么像本项目一样直接 include。

顺带两个实测：

- `agda --build-library`：把**当前目录**的 `.agda-lib` 所 include 的全部模块一次性
  检查（标准库发行即用它预编译，见 2.6 节）；
- 只用 `-l` 不带 `-i` 时，**当前目录并不自动进 include 路径**：实测
  `agda -l standard-library-2.3 LibTest.agda` 会报出
  `[ModuleNameDoesntMatchFileName]`（因为候选路径列表里根本没有当前目录，模块名
  「找不到合法出生地」），加上 `-i.` 后 import 正常解析。脱离项目根的裸用法
  推荐记成固定配方：`agda -l 库名 -i. 文件`。

## 2.3 Emacs agda2-mode：日常开发的主战场

Agda 的交互式开发**只有一条被官方认真维护的通道：Emacs**。Debian 下 `apt install
elpa-agda2-mode` 即得（版本实测与 agda 2.8.0-2build1 同步）。注意一个 Debian 坑：
`agda --emacs-mode=locate` 打印的是 `/usr/share/libghc-agda-dev/emacs-mode/agda2.el`
——**这个路径在本机不存在**，apt 把 elisp 实际装到了
`/usr/share/emacs/site-lisp/elpa-src/agda2-mode-2.8.0/`，别照着 locate 配 `load-path`。

### 核心工作流：加载 → 看孔 → 填孔

在 Emacs 里打开 `examples/Ex02_toolchain.agda`，按下 `C-c C-l`（加载/类型检查），
状态栏出现 `Checked`。日常键位（全部取自 2.8.0 版 `agda2-mode.el` 源码的
command table，实测版本一致）：

| 键 | 命令 | 干什么 |
|---|---|---|
| `C-c C-l` | Load | 保存并类型检查当前文件（**一切交互的前提**） |
| `C-c C-,` | Goal type and context | 光标处目标（孔洞）的类型 + 上下文 |
| `C-c C-r` | Refine | 把孔洞展开一层（`?` → 构造器/λ 的骨架） |
| `C-c C-c` | Case | 对模式变量 case split 生成子句 |
| `C-c C-SPC` | Give | 把孔洞里的表达式「交卷」，检查并收缩 |
| `C-c C-f` / `C-c C-b` | Next/Previous goal | 在孔洞间来回跳 |
| `C-c C-n` | Evaluate term | 交互式 Compute：把项归约成规范形 |
| `C-c C-e` | Context | 只看当前上下文 |
| `C-c C-x C-c` | Compile | 走 2.4 节的编译流水线 |

「跳孔」还有第二个入口：agda2-mode 把报错/目标信息缓冲挂到了 Emacs compilation
跳转机制上（源码实测设置了 `compilation-error-regexp-alist`），所以标准的
**`C-x \`` / `C-u C-x \``（next-error）**也能在报错与孔洞间逐个跳——README 工具链表里写的就是它。

**孔洞（hole）** 写作 `?`（具名版 `?name`），是交互式构造证明的主角。典型剧本：

```agda
proof : 2 + 3 ≡ 5
proof = ?        -- 先打个问号
```

`C-c C-l` 后，*All Goals* 缓冲显示：

```text
?0 : 2 + 3 ≡ 5
```

——这就是 Agda 在问你「这个类型你打算填什么」。光标停在 `?` 上按 `C-c C-,`
看类型与上下文，想好了把 `?` 改成 `refl` 再 `C-c C-l`；更激进的做法是
`C-c C-r` 让 Agda 自己展开、`C-c C-SPC` 就地交卷。

两个红线级注意事项（都实测过）：

1. **带未填孔洞的文件过不了命令行检查**：`agda` 直接报 `[UnsolvedInteractionMetas]`
   （原文见 2.8 坑位清单）。所以本教程示例文件里**从不留孔**；
2. `Check` / `Compute` 这类交互命令**不是源文件语法**。源文件里「展示求值」
   用 01 章的等式证明（`_ : 2 + 3 ≡ 5` 配 `refl`）表达。

### 命令行会话：C-c C-l 背后到底发了什么

agda2-mode 没有魔法：它在后台以 `agda --interaction` 起子进程，用「每行一条命令、
每行一条 lisp 应答」的协议对话。下面是在本项目跑出的**真实双向报文**
（用 `printf | agda --interaction` 手工扮演 Emacs）：

```text
IOTCM "/home/xulun/code/programming/agda/examples/HoleDemo.agda" None Indirect (Cmd_load "/home/xulun/code/programming/agda/examples/HoleDemo.agda" [])
Agda2> (agda2-status-action "")
(agda2-info-action "*Type-checking*" "" nil)
(agda2-highlight-clear)
(agda2-info-action "*Type-checking*" "Checking HoleDemo (/home/xulun/code/programming/agda/examples/HoleDemo.agda).\n" t)
(agda2-status-action "")
(agda2-info-action "*All Goals*" "?0 : 2 + 3 ≡ 5\n" nil)
((last . 1) . (agda2-goals-action '(0)))
Agda2>
```

读法：`IOTCM "<当前文件>" <高亮级别> <输出模式> (命令 参数...)` 是请求；应答是
**给 Emacs 执行的 lisp 动作**——往 *Type-checking* 缓冲贴字、刷新状态栏、
`agda2-goals-action` 登记孔洞列表。你在 Emacs 里看到的 *All Goals* 缓冲，源头
就是上面第 6 行那个字符串。看懂这一层之后，「C-c C-l 卡住了」之类的问题
（比如 Agda 进程其实已经崩了）只要去看 `*agda2*` 进程缓冲就一目了然。

`--interaction` 的怪癖（实测）：**不接受文件参数**（`agda --interaction foo.agda`
报 `Error: Must not specify an input file (...) with --interaction`，退出码 71——
文件在 Load 命令里给）；命令串里的 `None`/`Indirect` 是**不带引号的枚举构造器**，
照抄成 `"None"` 会收获一排 `Agda2> cannot read:`。

## 2.4 --compile：编译流水线

类型检查通过后，`--compile`（MAlonzo 后端，默认）把程序编译成机器码：

```bash
$ agda --compile examples/Ex02_toolchain.agda
Compiling IO in /usr/share/agda-stdlib/_build/2.8.0/agda/src/IO.agdai to
  /home/xulun/code/programming/agda/examples/MAlonzo/Code/IO.hs
Calling: ghc -O -o .../examples/Ex02_toolchain -Werror -i.../examples \
  -main-is MAlonzo.Code.Ex02_toolchain .../examples/MAlonzo/Code/Ex02_toolchain.hs --make
[18 of 18] Linking /home/xulun/code/programming/agda/examples/Ex02_toolchain
$ ./examples/Ex02_toolchain
hello agda from Ex02
```

流水线三步：**Agda 类型检查（产出 `.agdai` 接口）→ 逐模块生成 Haskell 源码到
`MAlonzo/Code/` → 调 GHC 链接成可执行文件**。因此编译需要本机有 GHC（本机实测
ghc 随 agda-bin 依赖链在场）。

实测要点：

- **可执行文件生成在源文件同目录**（`examples/Ex02_toolchain`，无扩展名），
  `MAlonzo/` 中间产物也在源文件旁边——模块按 include 解析后「住在」`examples/` 下；
  想控制产物位置用 `--compile-dir=DIR`；
- 编译一个 IO 程序约 1–2 分钟（18 个 Haskell 模块起步），比纯检查慢一个量级；
  20 章会给出「检查与编译分工」的完整约定；
- 编译只认 `main`：示例里那个最小 `main : Main`（`main = run (putStrLn ...)`）
  就是全部——它同时验证了 `--guardedness` 规则：文件第一行的 pragma 一旦删掉，
  检查阶段就直接报 `[InfectiveImport]`（真实报错原文见 2.8 坑位清单）。

## 2.5 -I 与 --interaction-mode、VSCode 现状

### agda -I：被放弃的命令行 REPL

`agda --help` 里 `-I, --interactive` 的说明是「start in interactive mode」。实测
启动后先给你一屏 ASCII 艺术横幅，紧跟着这一行：

```text
The interactive mode is no longer under active development. Use at your own risk.
Main>
```

它存在、能进能出（提示符 `Main>`，`:?` 看帮助），但官方明示不再维护，且非交互
stdin 下 EOF 直接抛 Haskell 异常退出。**教程与日常工作都不要把它当主交互方式**：
命令行就交给 `agda 文件` 和 `--compile`，交互交给 Emacs。

### --interaction-mode 在 2.8 已被移除

老资料（≤ 2.5 时代）里的 `--interaction-mode=SimpleInteractionMode`（一种纯文本、
非 elisp 的简易交互模式）在 2.8 实测**不存在**：

```text
Error: Unrecognized option:
--interaction-mode=Foo
```

Agda 源码 `OPTIONS --interaction-mode` 的通路同样关闭。现在交互只有两条正门：
`--interaction`（Agda2> 协议，Emacs 模式用）与 `--interaction-json`（帮助原文：
「for use with other editors such as Atom」，即给第三方编辑器用的 JSON 封装）。

### VSCode 现状一句话

Agda 官方不发 VSCode 扩展；社区有若干非官方插件（基于 `--interaction-json` /
Agda2 协议包装），能拿到高亮 + 加载 + 孔洞的基本盘，但目标操作
（Refine/Case/Give）与上下文视图的完整度明显落后于 Emacs 模式。本教程按社区主流
给 Emacs 配置；命令行党「`agda` 检查 + 编辑器随便」也完全可学——示例全部保证
命令行可验证。

## 2.6 编译产物与 _build/ 缓存目录实测

每次成功类型检查，Agda 在**项目根**（那个被自动发现的 `.agda-lib` 所在目录）下
维护接口缓存。实测本项目结构：

```text
_build/
└── 2.8.0/                  ← 按 Agda 版本分目录（换版本自动全量重检）
    └── agda/
        └── examples/
            ├── Ex01_intro.agdai
            └── Ex02_toolchain.agdai
```

三个实测结论：

1. **快慢差异巨大**：标准库发行时已预编译（`/usr/share/agda-stdlib/_build/2.8.0/`
   整树 `.agdai` 由 Debian 包直接提供），所以 import 一堆标准库模块的文件秒级
   检完；若你的机器上 stdlib 是首次现场编译，第一次会很久——别误以为卡死；
2. **`--ignore-interfaces` 在 Debian 安装下有硬伤**：它不只重检你的文件，还会尝试
   把标准库的 `.agdai` **写回系统只读目录**，实测报：
   `Failed to write interface /usr/share/agda-stdlib/_build/... removeLink: permission denied`
   并失败退出。想「干净重检」自己的项目，正确姿势是删项目根的 `_build/`
   （即 `./build.sh clean`），而不是这个开关；
3. 换 Agda 版本（比如从源码装了新版）后 `_build/2.8.0` 自然失效——版本号目录
   就是为此设计的，接口格式跨版本不兼容（2.6.x 起引入，本机实测目录名即版本）。

## 2.7 本章示例导读

`../examples/Ex02_toolchain.agda` 是「交互无关但可检查」的最小集：

- 首行 `{-# OPTIONS --guardedness #-}`：IO 的入场券（2.4 节）；
- `answer = 6 * 7` + `_ : answer ≡ 42` 配 `refl`：交互式 `Compute` 的源文件替身；
- `main : Main`：`--compile` 流水线的靶子（本章只做类型检查；20 章约定完整 IO）。

验证命令：`cd agda && timeout 600 agda examples/Ex02_toolchain.agda`（实测退出码 0）。

## 2.8 坑位清单（本章实测）

1. **一个目录只许一个 `.agda-lib`**：多放一个，连累该目录下所有文件的检查
   （`[LibraryError] The project root ... may contain only one .agda-lib file`），
   哪怕你根本没用它；
2. **`DEPENDS:` 大写不识别**：只报 `LibUnknownField` 警告然后**当没有这个字段**，
   表现为「依赖明明写了却找不到模块」的 `[FileNotFound]`。字段名是小写 `depend:`
   （实测小写生效、大写无效）；
3. **`-l 库名` 不会自动带上当前目录**：裸目录里 `agda -l standard-library-2.3 file.agda`
   会以诡异的 `[ModuleNameDoesntMatchFileName]` 失败，加 `-i.` 即愈（实测）；
4. **`--ignore-interfaces` 在 Debian 标准库上炸权限**：试图回写系统 `_build`，
   permission denied 退出码 42。清缓存请用删项目 `_build/` / `build.sh clean`；
5. **`agda --emacs-mode=locate` 在 Debian 包下指向不存在的路径**
   （`/usr/share/libghc-agda-dev/emacs-mode/agda2.el`），真实 elisp 在
   `/usr/share/emacs/site-lisp/elpa-src/agda2-mode-2.8.0/`（apt 装位）；
6. **带孔 `?` 的文件过不了命令行检查**：`agda` 视未解孔为错误
   （`[UnsolvedInteractionMetas] Unsolved interaction metas at the following locations: ...`）。
   CI 里要允许留孔得加 `--allow-unsolved-metas`（帮助原文如此，慎用）；
7. **`--interaction` 拒绝文件参数**（`Must not specify an input file ... with
   --interaction`，退出码 71）；`--interaction-mode` 选项在 2.8 已整个不存在
   （`Unrecognized option`），照老教程配置编辑器会翻车；
8. **`--compile` 产物在源文件同目录而非项目根**：可执行文件是 `examples/ExNN_name`、
   中间 Haskell 在 `examples/MAlonzo/`。写脚本/`.gitignore` 时路径要按这个实测来；
9. **检查成功是沉默的**：`Checking ...` 只在真正重检时打印，缓存命中时零输出。
   别把「没输出」当成「没跑」。

---
上一章：[01 · 认识 Agda](01-intro.md) ｜ 下一章：[03 · 第一个文件](03-basics.md) ｜ 返回：[README](../README.md)
