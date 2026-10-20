# 02 · c-offsets-alist 实战：offset 的形态与 line-up 函数

第 1 章讲了缩进两步模型的**第一步**——把一行代码分析成一串 syntactic element（symbol + anchor）。这一章讲**第二步**：拿到 syntactic symbol 之后去 `c-offsets-alist` 查一个 offset，把 offset 应用到 anchor 上得到缩进。这一步里 CC Mode 提供的表达力**远超「缩几列」这么一句话**：offset 可以是整数、特殊符号、绝对列的向量、函数、另一个 syntactic symbol、有变量绑定的符号、甚至是一个组合列表。理解这七种形态，你才能真正把 CC Mode 的缩进调到想要的样子——不然只能挑一个内置风格用，遇到不合胃口的地方就没辙。

## 2.1 `c-offsets-alist` 是什么

**一句话**：一个关联表（alist），把每个 syntactic symbol 映到一个 offset 上。手册第 11.1 节的定义：

```elisp
;; c-offsets-alist 长这样的片段（真实 gnu 风格里的一部分，本机实测）
((statement            . 0)
 (substatement         . +)
 (cpp-macro            . [0])
 (topmost-intro-cont   . (first c-lineup-topmost-intro-cont
                                c-lineup-gnu-DEFUN-intro-cont))
 (arglist-cont-nonempty . (c-lineup-gcc-asm-reg c-lineup-arglist))
 ...)
```

**buffer-local 与全局值不对称**，这是很多配置困惑的根源：

- 一个 CC Mode buffer 的**buffer-local** 值里，**每个 syntactic symbol 都有条目**——CC Mode 初始化 buffer 时会把当前风格的 offset 表 + 你零散 `c-set-offset` 过的条目**合并**成一张完整的表。所以你在 C 文件里 `M-:` c-offsets-alist` 会看到 50+ 条。
- **全局值**和**风格定义里**通常只写**几条**——风格只覆盖它想改变的东西，其它 symbol 走「默认 offset」。

这就是为什么手册反复强调「风格不是从零定义一切」——它是**增量层**。

## 2.2 offset 的七种形态

### 形态一：整数

整数是**相对偏移**，单位是「列」——它加到 anchor 所在列上。

```elisp
(c-set-offset 'arglist-cont-nonempty 4)   ;; 参数续行相对 anchor 多缩 4 列
```

整数最常见的用法其实是 `0`（顶到 anchor 那列、不额外缩）。上面这段 gnu 风格片段里的 `(statement . 0)` 就是这个——函数体里的普通语句跟 `defun-block-intro` 用同一个 anchor，offset 都是 0，效果都是缩进一个 `c-basic-offset`——**但两者是不同的 syntactic symbol，可以分别调**。

### 形态二：特殊符号 `+ - ++ -- * /`

这六个符号代表 `c-basic-offset` 的整数或半分倍数。手册第 11.1 节直接给了映射表（**实测确认本机有效**）：

| 符号 | 含义 |
|---|---|
| `+` | `c-basic-offset × 1` |
| `-` | `c-basic-offset × −1` |
| `++` | `c-basic-offset × 2` |
| `--` | `c-basic-offset × −2` |
| `*` | `c-basic-offset × 0.5` |
| `/` | `c-basic-offset × −0.5` |

**为什么要有这六个符号而不是直接写整数**：整数把「缩进列数」写死了，`+` 让它跟着 `c-basic-offset` 走——你改一个 `c-basic-offset = 6` 整份代码形状不变、只是每级变宽。这是风格系统的骨架。

本机实测（c-mode, gnu 风格 `c-basic-offset=2`）用 `(statement-cont . <符号>)` 逐一切换，缩进这段：

```c
int x =
    1 +
    2;
```

`statement-cont` 分别设为 `+`、`++`、`-`、`*`、`/` 的产物（列号从 0 数）：

```text
+   ->  列 2   (int x =\n  1 +\n  2;)
++  ->  列 4   (int x =\n    1 +\n    2;)
-   ->  列 1   (int x =\n 1 +\n 2;)     ← 0 + (-2) 被夹到最小可视列
*   ->  列 1   (int x =\n 1 +\n 2;)     ← 0 + (0.5×2) = 1
/   ->  列 1   (int x =\n 1 +\n 2;)     ← 0 + (-0.5×2) = -1 被夹到 1
```

`-` 与 `/` 的负数结果被 CC Mode 夹到 1 列而不是 0——因为「相对 anchor 往回缩到 0 列」等于「这行顶到最左」——CC Mode 通常对**续行**（`statement-cont`）保留至少 1 列缩进、防止续行看起来跟首行同层。这一条不在手册正文写死，是行为层。想顶到 0 列就显式用整数 0 或向量 `[0]`。

再看符号跟 `c-basic-offset` 一起动的实测：把风格切到 `linux`（`c-basic-offset=8`、用制表符缩进），把 `substatement` 设成 `+`：

```text
if (a)
        b();              ← 一个 TAB = 显示上 8 列
```

**同一个 `+`，在 gnu（cbo=2）里是 2 列，在 linux（cbo=8）里是 8 列**——这就是符号的价值。

### 形态三：向量

向量指定一个**绝对列**，覆盖之前累加的所有相对 offset，但不影响后续 syntactic element 的 offset。手册原文：

```elisp
(cpp-macro . [0])       ;; 预处理宏永远顶到第 0 列
```

向量第一个元素是整数（目标列），后面元素被忽略。这条是「让某类行**绝对顶格**」的写法——比如 gnu 风格把 `cpp-macro`（`#define` 之类）设成 `[0]`，不管你外层在什么函数里、多深缩进，`#` 一定回到列 0。

### 形态四：函数或 lambda

offset 是一个函数符号（或 lambda）时，CC Mode 调用它、把返回值再当 offset 求值。函数签名：

```elisp
(defun my-lineup (lang-ctx)
  ;; lang-ctx 是「(syntactic-symbol . anchor)」（5.28 之前的老 form，CC Mode 为了向后兼容保留）
  ;; 返回值可以是整数/向量/符号/另一个函数名，任意 offset 形态。返回 nil 视作 0。
  ...)
```

函数形态是 line-up 函数（见 2.4）的基础，也是「按上下文条件动态决定缩进」的入口。

### 形态五：另一个 syntactic symbol

offset 是一个符号且这个符号**不是函数也不是变量**时，CC Mode 把它当成另一个 syntactic symbol 去 `c-offsets-alist` 里查它的 offset。手册给的例子：

```elisp
(enum-open . class-open)   ;; 让 enum 的 { 缩进规则完全等同于 class 的 {
```

这条对「让两种结构跟同一个风格规则」特别有用——你不希望改一个风格要同时改两个 symbol。

### 形态六：有变量绑定的符号

offset 是一个符号，且这个符号**有变量绑定**（不是函数、也不是另一个 syntactic symbol）时，取变量的值当 offset。手册规定变量值必须是整数或向量——整数走相对、向量走绝对。

举例（自定义）：

```elisp
(defcustom my-arglist-offset 2
  "自定义 arglist-cont-nonempty 的相对缩进量。"
  :type 'integer
  :group 'c)
(c-set-offset 'arglist-cont-nonempty 'my-arglist-offset)
```

`my-arglist-offset` 改了，`arglist-cont-nonempty` 的实际缩进跟着改——这条是「让 offset 变成一个 `M-x customize` 能调的选项」的做法。

（手册规定：若一个符号既有函数绑定又有变量绑定，**函数优先**——因为函数是更精确的表达形式。）

### 形态七：列表 + first/min/max/add

offset 可以是一个 list，元素是若干 offset 形态；CC Mode 递归求值后按第一个元素指定的策略合并。策略有四种：

- `first`：用第一个非 `nil` 的求值结果，后续元素**不求值**。适合「按顺序试几种函数，谁认领谁定」。
- `min`：所有相对（或所有绝对）offset 求值后取最小。
- `max`：取最大。
- `add`：全部相加；若其中有绝对 offset（向量），结果是绝对、且绝对之前的相对 offset 被忽略。

手册原文片段（whitesmith 风格真实使用的合并方式）：

```elisp
(statement-block-intro add c-lineup-whitesmith-in-block c-indent-multi-line-block)
```

这里两个 line-up 函数各自返回一个相对 offset（或 `nil`），`add` 把两者累加——一个负责「whitesmith 风格里块首行相对 `{` 缩进」、另一个负责「多行块的额外缩进」，各自独立、相加。

**兼容性写法**：手册第 11.1 节的最后一段说，如果 list 第一个元素不是 `first`/`min`/`max`/`add` 之一，那么**第一个元素本身被当成一个 offset**，整个 list 按 `first` 合并。所以这两种写法等价：

```elisp
(arglist-cont-nonempty . (first c-lineup-arglist +))
(arglist-cont-nonempty . (c-lineup-arglist +))    ;; 没写 first，按 first 处理
```

**求值为 nil 的 offset 一律按 0 处理**（手册脚注 2 明说）。老手册里有个 `c-strict-syntax-p` 能让 nil 变成错误信号，5.35 已把它标记为 obsolete——原因是 line-up 函数经常返回 nil 表达「我不适用、交给下一个」——不要碰 `c-strict-syntax-p`。

## 2.3 交互式改 offset：`c-set-offset` 与 `C-c C-o`

前面所有形态都能用 `c-set-offset` 落地：

```elisp
(c-set-offset 'substatement-open 0)     ;; 顶层 setq 之前
(c-set-offset 'case-label '+)           ;; 特殊符号——实测存进 c-offsets-alist 的就是符号 +
(c-set-offset 'arglist-close 'c-lineup-arglist)  ;; 函数形态
```

**键位**：`C-c C-o`（实测在 `c-mode-base-map` 里绑到 `c-set-offset`）在 buffer 里现场改。按下去，minibuffer 先让你确认 symbol（默认取**当前行**的 syntactic symbol——所以先按 `C-c C-s` 看它是什么、再按 `C-c C-o` 直接回车就是改同一 symbol），再让你输入新 offset。这条工作流是「实验哪种 offset 让这段代码看起来对」的最短回路：改一下、TAB 一下、`C-c C-s` 再看、不满意就 `C-c C-o` 换——比写一段 Elisp 到 init 里再重启 Emacs 快得多。满意之后把这一条 `c-set-offset` 抄进 init 或 hook。

**`c-set-offset` 的两个语义细节**（实测）：

1. 它改的是**当前 buffer 的 buffer-local 值**——在 hook 里调用是「从当前风格再覆盖一个 symbol」的正确做法；在 init 顶层调用是「把 symbol 加进 `user` 风格、之后每个 CC Mode buffer 都带上」。
2. 符号是**新增或替换**——alist 里原本没这个 symbol 时 `c-set-offset` 会插入一条。

## 2.4 line-up 函数：让缩进跟着「对齐」而不是「偏移」

offset 是「相对 anchor 加几个单位」——这是**位移**。但很多代码风格关心的是**对齐**：让函数调用的续行跟第一行的参数开头对齐、让 `=` 号连成一条竖线、让运算符（`&&`、`||`）后面的续行跟在运算符后面。这些「对齐」需求 offset 表达不了，CC Mode 提供 **line-up 函数**——一组预置的 Elisp 函数，你在 `c-offsets-alist` 里把某个 symbol 的 offset 设成对应函数名，CC Mode 就会调用这个函数、返回一个具体的**绝对列或相对偏移**作为 offset 结果。

line-up 函数**接收** syntactic context 里的一个 element（形式 `(syntactic-symbol . anchor)`）、**返回**一个整数或向量或另一个函数。返回整数是「相对 anchor 的位移」、返回向量是「绝对列」。

**本机实测**：CC Mode 5.35.2 一共提供 **43 个** `c-lineup-*` 函数。下面按用途分组，每组挑一个能实测出差异的演示。

### 族一：函数调用/参数列表（arglist）

这一族是日常用得最多的——处理「函数调用的多行参数」。

- `c-lineup-arglist`：让参数续行对齐到第一个参数的列。
- `c-lineup-arglist-close-under-paren`：让闭合 `)` 对齐到对应开 `(` 的列。
- `c-lineup-arglist-intro-after-paren`：让参数续行对齐到开 `(` 的**下一列**（即紧跟 `(` 之后）。
- `c-lineup-arglist-operators`：让以中缀运算符（`+`、`,` 等）开头的行对齐到开 `(`。
- `c-lineup-close-paren`：通用版——闭合 paren 对齐到对应开 paren。

实测（gnu 风格，c-basic-offset=2）：把 `arglist-close` 从默认的 `c-lineup-arglist-close-under-paren` 换成 `c-lineup-close-paren`：

```text
默认（arglist-close = c-lineup-arglist-close-under-paren）：
g(aaa,
  bbb
  );                  ← 闭合 ) 对齐到开 ( 的列（列 1）

换成 c-lineup-close-paren：
g(aaa,
  bbb
 );                   ← 闭合 ) 对齐到开 ( 的列减 1（列 0）
```

（这个例子刻意用了「`g(` 在列 0」的写法；如果 `g(` 在更深的位置，两种函数的差别会更明显。）

### 族二：赋值/运算符续行（statement-cont）

- `c-lineup-assignments`：让续行对齐到首行的赋值运算符（`=`）之后。
- `c-lineup-math`：类似 `c-lineup-assignments`，但找不到运算符时退回 `c-basic-offset`。
- `c-lineup-cascaded-calls`：让 `.method()` 级联调用的续行对齐到点号。
- `c-lineup-ternary-bodies`：让 `?:` 三目运算符的两个分支对齐。
- `c-lineup-streamop`：让 C++ `<<` / `>>` 流运算符对齐。
- `c-lineup-gcc-asm-reg`：让 gcc 内联汇编的寄存器约束对齐。

实测（gnu 风格）：把 `statement-cont` 从默认的 `+` 换成 `c-lineup-assignments`：

```text
默认（statement-cont = +）：
void f() {
  a = 1 +
    2;                ← 缩进一个 c-basic-offset（2 列）
}

换成 c-lineup-assignments：
void f() {
  a = 1 +
      2;              ← 对齐到首行 = 号后一列
}
```

实测（gnu 风格）：`statement-cont = c-lineup-ternary-bodies`：

```text
int x = cond ?
 val1 :              ← 对齐到 ? 后一列
 val2;
```

### 族三：注释

- `c-lineup-comment`：按 `c-comment-only-line-offset` 处理注释-only 行的缩进。
- `c-lineup-C-comments`：处理 C 块注释（`/* ... */`）的续行对齐。
- `c-lineup-knr-region-comment`：K&R 函数定义区域里的注释对齐。
- `c-lineup-respect-col-0`：如果当前行已经在列 0，返回 `[0]`；否则返回 `nil`（让下一个 line-up 函数接手）——常用于「用户手动顶到列 0 的注释不要动」。

### 族四：预处理宏

- `c-lineup-cpp-define`：按 `#define` 的「参数列表缩进」对齐宏续行。

实测（gnu 风格）：`cpp-macro-cont = c-lineup-cpp-define`：

```text
#define FOO(a)                            \
  bar(a) +                                \
    baz(a)
```

### 族五：C++ 特有

- `c-lineup-template-args` / `c-lineup-template-args-indented-from-margin`：模板参数列表对齐。
- `c-lineup-java-inher` / `c-lineup-java-throws`：Java `extends`/`implements`/`throws` 对齐。
- `c-lineup-multi-inher`：C++ 多重继承列表对齐。
- `c-lineup-class-decl-init-+` / `c-lineup-class-decl-init-after-brace`：类初始化列表（构造函数后的 `: base()`）对齐。
- `c-lineup-class-field-cont`：类成员续行对齐。

### 族六：whitesmith 风格专用

- `c-lineup-whitesmith-in-block`：whitesmith 风格里块内行的缩进。
- `c-lineup-after-whitesmith-blocks`：whitesmith 风格里块后续行的补偿缩进。

这两个函数在 whitesmith 风格的 `c-offsets-alist` 里被大量使用，配合 `add` 合并策略：

```elisp
;; whitesmith 风格里真实存在的片段（本机实测）
(statement-block-intro add c-lineup-whitesmith-in-block c-indent-multi-line-block)
(statement             add c-lineup-after-whitesmith-blocks c-indent-multi-line-block)
```

`c-indent-multi-line-block` 是另一个 line-up 函数（不在 `c-lineup-` 前缀下），负责「多行块的额外缩进」——whitesmith 风格把这两个函数 `add` 起来，得到「块首行相对 `{` 缩进 + 多行块补偿」的组合效果。

### 族七：其他/特殊场景

- `c-lineup-dont-change`：返回 `nil`，表示「不要改当前行的缩进」——用于「这行我已经手动调好、CC Mode 别动」。
- `c-lineup-string-cont`：续行字符串对齐到被续的那个字符串。
- `c-lineup-inexpr-block`：表达式内嵌块（如 `({ ... })` GNU 扩展）的对齐。
- `c-lineup-2nd-brace-entry-in-arglist`：brace 列表（`{ ... }` 初始化）第二项对齐到第一项。
- `c-lineup-item-after-paren-at-boi`：boi（beginning of indentation）处是 `(` 时，对齐到 `(` 后。
- `c-lineup-runin-statements`：「run-in」风格（首个语句跟 `{` 同行）的续行对齐。
- `c-lineup-under-anchor`：直接对齐到 anchor 位置。
- `c-lineup-gnu-DEFUN-intro-cont`：Emacs C 源码里 `DEFUN` 宏的续行对齐（gnu 风格用到）。
- `c-lineup-ObjC-method-args` / `-2` / `-call` / `-call-colons`：Objective-C 方法声明/调用的冒号对齐。

### 自定义 line-up 函数

手册第 11.2 节最后一小节「Custom Line-Up」给了一段完整示例，本质是：

```elisp
(defun my-align-assignment (lang-ctx)
  "对齐 `statement-cont` 的续行到首行 `=` 号下一列。"
  (save-excursion
    (c-backward-syntactic-ws)
    (when (search-backward "=" (c-langelem-pos lang-ctx) t)
      (vector (1+ (current-column))))))   ;; 返回向量 = 绝对列
(c-set-offset 'statement-cont 'my-align-assignment)
```

`c-langelem-pos` 取当前 syntactic element 的 anchor 位置；`c-backward-syntactic-ws` 跳过空白和注释往后移。自定义 line-up 的返回形态直接对应「offset 的七种形态」——它就是一个 offset 求值器，只是求值时你能访问 syntactic context 与 buffer 内容，所以「按上下文动态定」这条能力就出来了。

## 2.5 让缩进后再改一次：`c-special-indent-hook`

有些收尾调整不属于 syntactic symbol——比如「一行的注释如果超过 80 列，把它整体往左挪」这类。CC Mode 在算完 offset、把行缩进之后，会跑 `c-special-indent-hook` 上的每个函数。手册第 6.2 节关于 style variables 的说明里点出：`c-special-indent-hook` 是**风格只能往上加函数、不能删除**的特殊风格变量——这条对「你在 init 里放了一个函数、之后 `c-set-style` 换风格不希望它被抹掉」有用。

典型用法：

```elisp
(defun my-extra-indent ()
  (save-excursion
    (back-to-indentation)
    ;; 举例：让 // 后面补一个空格
    (when (looking-at "//[^ ]")
      (search-forward "//" (line-end-position) t)
      (insert " "))))
(add-hook 'c-special-indent-hook 'my-extra-indent)
```

这个 hook 上的函数**每次缩进都会跑**，不要放昂贵操作；只放「按当前行内容做一次小调整」的函数。

## 2.6 一个 offset 实战：让 switch 里的 case 与外层同缩进

C 里 `switch/case` 有两种常见风格：

**A**：`case` 缩进一层（跟 `switch` 里的语句同级）：

```c
switch (x) {
    case 1:
        return 1;
}
```

**B**：`case` 与 `switch` 同级（顶到 switch 所在列）：

```c
switch (x) {
case 1:
    return 1;
}
```

差异就在 `case-label` 这一个 symbol 的 offset。本机实测（linux 风格 `c-basic-offset=8`、tab 缩进）：

```text
linux 默认（case-label 是 0）：
switch (x) {
case 1:                       ← 顶格，形态 B
        return 1;             ← 一个 TAB
}

把 case-label 手动改成 `+`（一个 c-basic-offset）：
switch (x) {
        case 1:               ← 一个 TAB，形态 A
                return 1;     ← 两个 TAB
}
```

（`+` 的语义见 2.2 形态二——linux 的 `c-basic-offset` 是 8、且用 tab 缩进，所以「+」在屏幕上表现为一个 TAB。）

**gnu 风格默认 `case-label` 是 0**，但配合 `c-label-minimum-indentation`（默认 1）后实际会缩进 1 列——这条差异背后是 CC Mode 对「label 行的最小可见缩进」的兜底：即便 offset 是 0，label 行至少也缩进 `c-label-minimum-indentation` 列，避免与外层大括号完全同列导致视觉上无法区分。这条兜底规则在手册第 11.3「Other Indentation」小节。

这条差异背后就是 2.2 的「整数 offset 形态」+「特殊符号形态」——**风格定义的所有内容，最终都落回这张 `c-offsets-alist`**。第 3 章讲风格系统时，你会看到内置风格里 `c-offsets-alist` 部分就是几十条这种 `(symbol . offset)` 的对。

## 2.7 本章导航速查

- 改 offset（buffer 里）：`C-c C-o`（`c-set-offset`）。
- 看当前行的 syntactic context（含 anchor 高亮）：`C-c C-s`。
- 看当前 buffer 的完整 offset 表：`C-h v c-offsets-alist`。
- 换 offset 后**立即**重排代码：`C-M-\`（`indent-region`）、`C-M-q`（`c-indent-exp`）、`C-c C-q`（`c-indent-defun`）——第 4 章命令族。
- 内置 line-up 函数的完整列表：本机 CC Mode 5.35.2 共 43 个 `c-lineup-*` 函数，按用途分组见 2.4；`M-x apropos-command c-lineup-` 可列出全部。

---

上一章：[01 · 缩进引擎：两步模型与 syntactic context](01-indentation-engine.md)　｜　下一章：[03 · 风格系统：c-default-style、内置风格与自定义风格](03-styles.md)　｜　返回：[CC Mode 教程](README.md)
