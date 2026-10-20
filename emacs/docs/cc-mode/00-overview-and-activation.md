# 00 · CC Mode 是什么：一套引擎、七种语言

写 C 系代码的 Emacs 用户几乎绕不开 CC Mode。它是 Emacs 自带的、编辑 C、C++、Objective-C、Java、CORBA IDL、Pike、AWK 这七类语言的**同一个** major mode 家族——七个 mode（`c-mode`、`c++-mode`、`objc-mode`、`java-mode`、`idl-mode`、`pike-mode`、`awk-mode`）共享同一套缩进引擎、同一套电键（electric keys）、同一套风格（style）系统和同一套命令。你在 C 里学会「大括号为什么要顶格」，到 Java 里就是同一个答案换一个数字。

本教程讲两件事：**怎么用** CC Mode（键位、命令、电键、注释、填充），以及**怎么配**它（缩进引擎、风格系统、字体化）。它自包含——你不需要先去读 GNU《CC Mode 手册》的某一章，所有讲解的代码和结论都在正文里，且全部在本机 GNU Emacs 31.1 + CC Mode 5.35.2 上实测过。

## 0.1 先确认你手上的版本

CC Mode 没有命令行入口，它的版本号要在一个 C 文件里问：

```text
M-x c-version RET
```

本机实测回显（echo area）：

```text
Using CC Mode version 5.35.2
```

用 batch 也能拿到同样的字符串：

```bash
emacs -Q --batch --eval "(require 'cc-mode) (with-temp-buffer (c-mode) (c-version))"
```

```text
Using CC Mode version 5.35.2
```

为什么要把版本号单列一节：CC Mode 的**手册正文**（Info 里的 `ccmode`，描述的是 5.35）和**代码实现**（5.35.2）之间有少数几处已经漂移的默认绑定。本教程一律以 5.35.2 的**实测行为**为准，漂移点会在第一次出现时当场点明。目前已经确认的两处：

- 手册第 4.1 节说 `<TAB>` 绑定 `c-indent-command`。在 5.35.2 里 `c-mode-base-map` 的 `TAB` 实际绑的是 **`c-indent-line-or-region`**（有选区时缩整段，没选区时缩当前行，平时行为与 `c-indent-command` 一致）。
- 手册第 4.4 节说 `M-j` 绑定 `c-indent-new-comment-line`。在 Emacs 31.1 里 `c-mode` 的 keymap **不再绑 `M-j`**，它会落到 global-map 的 `default-indent-new-line`。要用 CC Mode 的注释换行得显式绑（见第 6 章）。

判断命令到底绑在哪个键上，永远可以现场问 Emacs：`C-h c <键>`（`describe-key-briefly`）会告诉你这个键当前调用什么命令；反过来 `C-h f <命令> RET` 看函数的文档串，里面通常写明它绑在哪些键上。这套自助查询在第 8 章还会用到。

## 0.2 它怎么接管你的文件：auto-mode-alist 实测

CC Mode 的各 mode 是靠 `auto-mode-alist`（文件名后缀 → major mode 的映射表）自动激活的。下面是本机 `-Q` 干净状态下，对常见后缀实测的结果：

| 后缀 | 实测命中的 mode | 说明 |
|---|---|---|
| `.c` | `c-mode` | C 源码，无歧义 |
| `.h` | `c-or-c++-mode` | 头文件专用模式，见下 |
| `.cpp` | `c++-mode` | |
| `.cc` | `c++-mode` | |
| `.cxx` | `c++-mode` | |
| `.java` | `java-mode` | |
| `.idl` | `idl-mode` | CORBA IDL |
| `.pike` | `pike-mode` | |
| `.awk` | `awk-mode` | |
| `.m` | **`octave-maybe-mode`** | 注意，不是 `objc-mode` |
| `.mm` | **`nroff-mode`** | 注意，不是 `objc-mode` |

两个坑要在最上面知道，否则「为什么我打开 .m 不是 ObjC」会白白耗掉你半小时：

**`.m` 归 Octave 不归 Objective-C。** macOS 上的 Objective-C 文件以 `.m`/`.mm` 结尾，但 Emacs 全局的 `auto-mode-alist` 把 `.m` 让给了 Octave（科学计算语言）的判别模式 `octave-maybe-mode`（它会看一眼文件内容再决定用 Octave 还是别的）。想在 Emacs 里编辑 Objective-C，要么进 buffer 后手动 `M-x objc-mode`，要么把这条加到 `init.el`（放在 CC Mode 相关配置之前即可）：

```elisp
(setq auto-mode-alist
      (cons '("\\.m\\(\\.in\\)?" . objc-mode)
            (delq (assoc "\\.m\\' " auto-mode-alist)
                  auto-mode-alist)))
```

（更省心的写法是直接 `add-to-list` 一个新条目放在列表最前：`(add-to-list 'auto-mode-alist '("\\.m\\'" . objc-mode))`——`auto-mode-alist` 从头往下匹配，先到先得。）

**`.h` 走 `c-or-c++-mode`，不是 `c-mode`。** 这个函数读文件**开头**的内容：看到 `class`、`namespace`、`template`、`#include <...>`（不带 `.h` 后缀的 C++ 标准头）这类 C++ 特征，就选 `c++-mode`，否则退回 `c-mode`。判定靠变量 `c-or-c++-modes` 和匹配逻辑在 `cc-langs.el` 里；绝大多数时候它猜得对。想让所有头文件固定用某一个 mode，绕过它即可：

```elisp
(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))
```

**`.C`（大写 C）在不同系统上是歧义的**：C++ 源码、CMake 脚本、二进制都常用它。Emacs 默认怎么处理取决于发行版打包的 `auto-mode-alist`，如果你编辑的是 C++，显式绑最稳：`(add-to-list 'auto-mode-alist '("\\.C\\'" . c++-mode))`。

## 0.3 模式行上的暗号：`C/*lahw` 在告诉你什么

CC Mode 在一行里塞了六个开关，它们的当前状态用**追加在 major mode 名字后面的字母/符号**显示在 mode line 上，不点开任何东西就能看见：

```text
<major-mode 名><注释风格><电键><自动换行><饥饿删除><子词>
   C          /或*        l        a           h          w
```

- 注释风格：`/` 表示行注释风格（`//`），`*` 表示块注释风格（`/* */`）。
- `l`：**electric**（电键模式）开启——手册里的命名是 electric，但模式行取的是这个 feature 的另一个别名的首字母。
- `a`：**auto-newline** 开启——你敲 `{` `}` `;` 等字符时自动帮你插换行。
- `h`：**hungry delete** 开启——一次退格删掉一整段空白。
- `w`：**subword** 开启——`M-f`/`M-b` 把 `NSGraphicsContext` 当三个词。

`-Q` 打开一个 C 文件时，实测默认状态是：注释风格为**块注释**（实测 `comment-start` = `"/* "`，所以指示符取 `*`）、electric 开（`l`）、auto-newline / hungry / subword 全关——模式行后缀是 `C*l`。把四个功能全开、注释风格仍是块注释，就是手册举的那个例子 `C/*lahw`。切换注释风格用 `C-c C-k`，c-mode 里它会从块注释切到行注释、后缀从 `*` 变 `/`。

六个开关对应的切换命令（**全部在 5.35.2 实测过绑定**）：

| 键 | 命令 | 作用 |
|---|---|---|
| `C-c C-k` | `c-toggle-comment-style` | 行注释 ↔ 块注释（AWK 这种只有一种的 mode 里无效） |
| `C-c C-l` | `c-toggle-electric-state` | 开关电键；关闭时顺带压制 auto-newline |
| `C-c C-a` | `c-toggle-auto-newline` | 开关 auto-newline；打开时顺带启用 electric |
| `C-c C-d` | `c-hungry-delete-forward` | **不是**开关——见下 |
| `M-x c-toggle-hungry-state` | 同左 | 开关 hungry delete |
| `C-c C-w` | `c-subword-mode` | 开关 subword |
| `M-x c-toggle-syntactic-indentation` | 同左 | 开关语法缩进 |

这里就是**手册和实现漂移的第一处**：手册第 4.5 节说 `C-c C-d` 是「开关 hungry 模式」——那是 5.31 之前的旧绑定。从 5.31 起 `C-c C-d` 改绑成了命令 **`c-hungry-delete-forward`**（向前饥饿删除，不管 hungry mode 开没开都直接删）。开关 hungry 只剩 `M-x c-toggle-hungry-state`；旧手册里 `C-c C-t` 绑「同时切 auto 和 hungry」这条在 5.35.2 的 `c-mode-base-map` 里**根本没绑**（实测 `C-c C-t` 落空）。

这些 toggle 函数还有一个程序化用法值得记：**都接受一个数字参数**，正数强制开、负数强制关（`c-toggle-comment-style` 里正数选块注释、负数选行注释）。这个约定让你能在 hook 里用固定值开启某个模式，而不是随上一个 buffer 的状态翻转——第 8 章的 init 片段就是靠这个写法工作的。

## 0.4 上手先动的三个变量

新接触 CC Mode 的人最先想改的设置就三个。全部实测：

**一、`c-basic-offset`——缩进一格用几列。** 这是风格系统里最重要的一个整数（风格变量的语义见第 1、3 章；现在只要知道「它是缩进的基本单位」即可）。它出厂时不是普通整数而是特殊符号 `set-from-style`（意思是「等风格系统来告诉我该是几」）。直接 `setq` 就绕过了风格：

```elisp
(setq c-basic-offset 6)
```

实测这条写进 init 后，打开 `.c` 文件里 `c-basic-offset` 变 6，风格自带的 2 被覆盖——具体机制见第 3 章的优先级实验。

**二、`c-default-style`——不同语言用哪种风格。** 出厂实测值：

```elisp
((java-mode . "java") (awk-mode . "awk") (other . "gnu"))
```

即 Java 用 java 风格、AWK 用 awk 风格、**其余全部用 `gnu`**（c/c++/objc/idl/pike 都落到 `other`）。想统一改 linux（8 列、制表符缩进、K&R 大括号）风格：

```elisp
(setq c-default-style '((java-mode . "java")
                        (awk-mode . "awk")
                        (other . "linux")))
```

**三、`c-electric-flag`——要不要电键。** 默认实测值是 `t`（开）。它的行为是：你敲 `;`、`{`、`}` 等标点，CC Mode 顺手重缩当前行。新手最常见的抱怨就是「敲个分号怎么行跑到行首了」，关掉就是：

```elisp
(setq-default c-electric-flag nil)
```

实测这条把全局默认关掉后，新开的 C buffer 的模式行从 `C*l` 变成 `C*`。当前 buffer 里临时开关，直接 `C-c C-l` 即可。

顺带一个「新手常想改」：**让 `RET` 键自动缩进新行**。标准 `RET` 只换行不缩进；把 `c-context-line-break` 绑到 `RET` 就能换行后自动缩到正确位置。坑在于：**必须在 CC Mode 的 keymap 已经存在之后再动它**——`-Q` 启动时如果 init 里第一句就写 `(define-key c-mode-base-map ...)` 而 CC Mode 还没被加载（首次遇到 `.c` 文件才 autoload），那个 keymap 变量还没求值、直接报错。所以要用 `c-initialization-hook`，等 CC Mode 加载完再执行。手册给的示例：

```elisp
(defun my-make-CR-do-indent ()
  (define-key c-mode-base-map "\C-m" 'c-context-line-break))
(add-hook 'c-initialization-hook 'my-make-CR-do-indent)
```

这是 CC Mode 也遵守的 Emacs 通用 hook 机制——CC Mode 提供了自己的一组 hook（`c-mode-common-hook` 对所有七种语言生效，`c-mode-hook` 只对 C 生效，`java-mode-hook` 只对 Java 生效，以此类推），第 3 章会系统讲。

## 0.5 配置一份 CC Mode 的五层：从低到高

同一份配置，写在不同地方的**生效顺序**不一样。手册第 6 章「Configuration Basics」原文列出的优先级，从**最低**（最容易被覆盖）到**最高**：

```text
Style
File Style
Top-level command 或 "customization interface"（M-x customize）
Hook
File Local Variable setting（文件末尾的 local variables list）
```

翻译成人话：**风格是默认值，你 init 里顶层 `setq` 覆盖它；buffer 的 hook 又覆盖顶层 `setq`；文件末尾的 local variable 再覆盖 hook。** File Style 是 rarely-used 的按文件选风格机制，介于风格与顶层 setq 之间，第 3 章的实战部分会演示。

本机实测把这条链条完整跑了一遍，代码在 `/tmp/precedence.el`，用 `emacs -Q --batch -l /tmp/precedence.el` 得到：

```text
[1] top-level setq 3, gnu style -> 3
[2] c-default-style linux -> offset=3
[3] hook 覆盖 setq -> offset=7
[4] buffer-local 覆盖 hook -> offset=11
```

四条分别对应四个写法：

```elisp
;; 第 1 层——风格默认（gnu 是 2）被顶层 setq 覆盖
(setq c-basic-offset 3)              ;; 之后开 c-mode 实测读到 3，不是 2

;; 第 2 层——顶层 setq 的变量会"钉住"，让后续风格换不掉它
(setq c-default-style '((other . "linux")))
;; 上面那句之后开 c-mode 依然读到 3——因为 c-basic-offset 已经被顶层 setq
;; 改成了 3，风格系统检测到值不是 set-from-style，就不覆盖它。

;; 第 3 层——hook 覆盖顶层 setq
(defun my-hook-7 () (setq c-basic-offset 7))
(add-hook 'c-mode-hook 'my-hook-7)   ;; 之后开 c-mode 实测读到 7

;; 第 4 层——file-local（等价于 buffer-local setq）覆盖 hook
;; 实测在 buffer 里 (setq-local c-basic-offset 11) 读到 11
```

第 2 层的「风格换不掉 setq」是版本演进里一个**重要的修复**：CC Mode 5.26 之前，你顶层 `setq` 过一个变量后一旦换风格就会被风格里的值重新覆盖，非常反直觉。5.26 起改成「全局绑定仍然是 `set-from-style` 符号的变量，才由风格初始化；被 setq 过的保留」——上面第 2 步的实测就是这个行为。手册脚注提到还有个逃生舱 `c-old-style-variable-behavior` 可以恢复旧行为，**不要碰它**。

一个特殊变量例外要知道：`c-offsets-alist`（第 2、3 章的主角）出厂默认不是 `set-from-style` 而是空表 `nil`，所以你用 `c-set-offset` 一条条加进去的 offset 在风格初始化后**仍然保留**——它天生就是让你覆盖风格而不用重定义风格的设计。

## 0.6 十六个「风格变量」一览

CC Mode 的风格系统能一次性设置的变量，手册第 6.2 节列了十六个，编号叫「style variables」。这张表是第 3 章「风格定义」和第 1、2 章「缩进配置」共同引用的地基，先原样列在这里（右边括号里是它们各自被讲透的章节）：

```text
c-indent-comment-alist                 c-indent-comments-syntactically-p   （第 4 章 注释命令）
c-doc-comment-style                                                                    （第 7 章 Doc Comments）
c-block-comment-prefix                 c-comment-prefix-regexp                           （第 6 章 填充与前缀）
c-hanging-braces-alist                                                                 （第 5 章 Hanging Braces）
c-hanging-colons-alist                                                                 （第 5 章 Hanging Colons）
c-hanging-semi&comma-criteria                                                          （第 5 章 Hanging Semicolons/Commas）
c-cleanup-list                                                                         （第 5 章 Clean-ups）
c-basic-offset                                                                         （第 2 章）
c-offsets-alist                                                                        （第 1、2 章）
c-comment-only-line-offset                                                             （第 2 章 Comment Line-Up）
c-special-indent-hook                  c-label-minimum-indentation                      （第 2 章 Other Indentation）
c-backslash-column                     c-backslash-max-column                           （第 6 章 多行宏反斜杠）
```

三个和风格变量有关的行为要知道（都实测过或在手册第 6.2 节明说）：

1. **它们默认是 buffer-local**：一个 C buffer 里的 `c-basic-offset` 改成一个值，Java buffer 不受影响。想让它们变成真全局，在 CC Mode **初始化之前**（即第一次打开 `.c/.h` 文件之前）把 `c-style-variables-are-local-p` 设成 `nil`。实测 `-Q` 干净值：`(default-value 'c-style-variables-are-local-p)` 返回 `t`。
2. **全局绑定的出厂值是特殊符号 `set-from-style`**（不是数字）——这是风格系统的触发器：CC Mode 初始化 buffer 时看到「哦这个变量还没被人显式 setq」，就从当前风格里取。两个例外：`c-offsets-alist`（空表 `nil`）和 `c-special-indent-hook`（风格只能往这个 hook 上**加**函数不能删）。
3. **顶层 setq + `c-set-offset` 的值被存进一个叫 `user` 的特别风格**：CC Mode 首次初始化时把你已经改过的全局变量快照成一个名叫 `user` 的风格，之后你在 `M-x c-set-style user` 能回滚到这个快照。实测 `c-style-alist` 里能查到 `user` 条目，出厂还带了另一个 `cc-mode` 是内置的初始默认（两个都是给风格系统兜底用的，日常用不到）。

## 0.7 一份最小能跑的 init 片段

把这一节的东西抄进 `init.el`，你就得到一份「个人风格 8 列、hook 里开 auto-newline、不要 tab」的 CC Mode。这份片段是手册附录 A「Sample Init File」的简化——原样附录 A 在第 8 章会逐行拆开讲：

```elisp
;; 一、缩进基本单位 + 关掉 TAB 缩进
(setq c-basic-offset 4)
(add-hook 'c-mode-common-hook
          (lambda () (setq indent-tabs-mode nil)))

;; 二、默认风格：非 Java/AWK 一律用 linux
(setq c-default-style '((java-mode . "java")
                        (awk-mode . "awk")
                        (other . "linux")))

;; 三、单条 offset 覆盖风格
(c-set-offset 'substatement-open 0)   ;; if/while 后面紧跟的 { 不额外缩进

;; 四、开启 auto-newline（固定值 1，不用 toggle）
(add-hook 'c-mode-common-hook (lambda () (c-toggle-auto-newline 1)))

;; 五、让 RET 自动缩新行
(defun my-c-init ()
  (define-key c-mode-base-map "\C-m" 'c-context-line-break))
(add-hook 'c-initialization-hook 'my-c-init)
```

第 3 步里的 `c-set-offset` 是「只改一个 syntactic symbol 的缩进规则、不定义整个风格」的最短路径，也是第 2 章 `c-offsets-alist` 实战会反复用的命令；第 4 步用 `c-toggle-auto-newline 1` 而不是无参调用，就是为了「不管上一个 buffer 是什么状态，这里一定是开」。

## 0.8 本章导航：后面 8 章讲什么

第 1 章 · **缩进引擎**：CC Mode 拿到一行代码之后到底做哪两步（分析 syntactic symbol 和 anchor，查 offset）。手册里一整章 Syntactic Analysis/Symbols/Calculation 的内容会被讲透，配 40+ 个 syntactic symbol 的速查表。
第 2 章 · **`c-offsets-alist` 实战**：offset 的七种形态（整数、`+`/`++`/`-`/`--`/`*`/`/`、向量、函数、另一个符号、变量、列表 + `first`/`min`/`max`/`add`），line-up 函数体系，以及交互式调试命令 `C-c C-s`、`C-c C-o`。
第 3 章 · **风格系统与定制**：`c-default-style`、`c-set-style`、十种内置风格各自的实际缩进产物，`c-add-style` 自定义风格、按文件自动猜风格、File Style。
第 4 章 · **日常命令**：缩进命令族、注释命令族、移动命令族（`C-M-a`/`C-M-e`/`M-a`/`M-e`/`C-c C-p`/`C-c C-n`/`C-c C-u`）、预处理与宏命令族、`narrowing`。
第 5 章 · **电键、auto-newline、hungry delete、clean-ups**：每一枚电键分别绑哪个 `c-electric-*` 命令、在什么条件下电；`c-hanging-braces-alist` 之类的换行规则；`c-cleanup-list` 的十几种自动清理。
第 6 章 · **注释与字符串的填充、多行宏**：`M-q`（`c-fill-paragraph`）、`M-j`（需要手动绑）、`c-context-line-break`/`c-context-open-line`、`c-fillet-*` 定制、`C-c C-\`（`c-backslash-region`）与 `c-backslash-column`。
第 7 章 · **字体化（Font Locking）**：三档 `c-decoration-level` 各自高亮什么，`c-doc-comment-style` 支持 Javadoc/KDoc/Qt 三种 doc 注释，`font-lock-extra-C-*key-*` 系列变量怎么把自定义关键字染上颜色，AWK 模式的字体化差异。
第 8 章 · **定制、性能与 FAQ**：手册附录 A 的示例 init 逐行讲透；性能陷阱（backslash 列、`defun-prompt-regexp`、font-lock level 3、缓存机制）；已知限制（`#ifdef` 折叠里的 C++ 模板、`narrowing` 的副作用）；FAQ 精选。

配套：附录 A（`docs/extending-emacs/`）讲怎么**用 Elisp 写扩展**，本教程假设你不需要写扩展就能配好 CC Mode；`docs/using-emacs/14-programs.md` 是「使用 Emacs 教程」里的一节程序编辑概览，它把这一整套 CC Mode 教程链接进来。

---

上一章：（无上一章）　｜　下一章：[01 · 缩进引擎：两步模型与 syntactic context](01-indentation-engine.md)　｜　返回：[CC Mode 教程](README.md)
