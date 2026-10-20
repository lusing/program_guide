# 01 · 缩进引擎：两步模型与 syntactic context

第 00 章讲了 CC Mode 是什么、怎么启用、模式行上六个开关、以及配置的五层优先级。这一章进入 CC Mode 最核心也最容易被误读的部分——**缩进引擎**。为什么按 `{` 之后 `if (a)` 下面那行 `{` 有时候跟着 `if` 缩、有时候顶到行首、有时候跑到最外层？为什么改一个 `c-basic-offset` 就能让整份代码形状一致地变宽？为什么别人写的一段代码你打开后完全不用调 TAB 就能自动对齐？这些问题的答案都在这一节。把「CC Mode 拿到一行代码到底做了哪两步」讲透，后面第 2 章的 offset 配置、第 3 章的风格系统、第 5 章的电键行为才都有立足点。

## 1.1 两步模型：分析 + 查 offset

CC Mode 手册第 10 章「Indentation Engine Basics」开头就给了一次干脆的定义——一行动代码的缩进被拆成两步：

1. **分析**：看这行代码，确定它的**syntactic symbol**（是哪种语言构造）和**anchor position**（往回找到哪一处位置作为参照）。举例：如果上一行有一个未闭合的 `{`，anchor 通常就是那个 `{` 所在的字符位置。
2. **算**：把这行涉及的每一个 syntactic symbol 拿去查 `c-offsets-alist`（一个「symbol → 缩进规则」的关联表），得到对应的 **offset**——最常见的偏移写作符号 `+`，意思是「在 anchor 的基础上再加一整个缩进单位」。offset 应用到 anchor 上，就得到这一行的最终缩进列。

写成一句公式：

```text
最终缩进 = 应用( offset[syntactic symbol], anchor position )
```

这里三个词都得记牢：**syntactic symbol**（是哪种构造，比如 `defun-open` / `substatement` / `case-label`）、**anchor position**（回看到的参照位置，通常是某个 `{` 或 `(` 的 buffer 偏移）、**offset**（这个 symbol 在 anchor 上加减多少，写在 `c-offsets-alist` 里）。这三件事一旦能独立解释，剩下 CC Mode 的所有缩进行为都只是「换花样」——第 2 章会展开 offset 的七种形态，第 3 章会讲内置风格怎么组合这些形态。

## 1.2 syntactic context：一行的完整身份

严格说，一行代码不只对应「一个 syntactic symbol」，而是对应一个 **syntactic context**——一串 **syntactic element** 的列表。手册里给的原型：

```elisp
((defun-block-intro 1959))
```

这是**只有一个 element** 的 context。每个 element 是一个 list，第一个元素是 syntactic symbol，后面的元素是相关的辅助数据——最常见的是 anchor position。像 `1959` 这种大整数就是 buffer 位置，指「这一行相对这个位置缩进」。

一行的 context 可以有**多个 element**——比如一行既是外层函数的顶层语句、又刚被 `else` 打开一个子块，两个 syntactic symbol 都算这条行的身份；CC Mode 会分别查每个 symbol 的 offset，然后把它们**加**起来（细节第 2 章）。这就是为什么有些行为「只调一个 offset 不够」——一行的缩进是多个 offset 的和。

再举一个本机实测的例子——一行的**纯注释**（整行只有注释、没有代码）：

```c
void draw_list(List<Drawables>& drawables)
{
        // call virtual draw()
    for (int i = 0; i < n; ++i)
    {
        drawables[i].draw();
    }
}
```

把光标放在那行注释上按 `C-c C-s`，本机实测 syntactic context 是：

```elisp
((defun-block-intro 44) (comment-intro))
```

——两个 element：带 anchor 的是 `(defun-block-intro 44)`（它为这行提供参照位置，44 是函数体 `{` 之后），不带 anchor 的是 `(comment-intro)`（注释本身没有「相对缩进」概念，它只标记身份）。手册第 10.1 节用词序写作 `((comment-intro) (defun-block-intro 46))`，本机 5.35.2 实测是上面这个顺序、anchor 数值也不同——**element 的次序和 anchor 数字都不是稳定的，要记的是「一个带 anchor 的 element + 一个不带 anchor 的 `comment-intro`」这个结构**。

## 1.3 一次实测：三行代码分别是什么 syntactic context

上面是抽象定义，下面跑一遍真实数据。**本机实测** Emacs 31.1 + CC Mode 5.35.2，`c-mode`，gnu 风格（`c-basic-offset` = 2）：

```c
void swap(int& a, int& b)
{
    int tmp = a;
    a = b;
    b = tmp;
}
```

把光标放在 `a = b;` 那行按 `C-c C-s`（`c-show-syntactic-information`），echo area 里回显：

```text
Syntactic context: ((statement 33))
```

——`statement`（普通语句），anchor 是 buffer 位置 33（对应函数体开头 `{` 之后）。把光标放在 `int tmp = a;` 那行按 `C-c C-s`：

```text
Syntactic context: ((defun-block-intro 27))
```

——`defun-block-intro`（顶层函数块的第一行），anchor 27 是 `{` 的位置。这是 CC Mode 用 syntactic symbol 表达「函数体第一行」这个概念：它是一行普通 statement，但也是**这个函数块的第一行**——所以是 `defun-block-intro` 而不是 `statement`。这两者 offset 在 gnu 风格里通常是同一个 `+`，效果都是相对 anchor 缩进一级；但符号区分让风格可以「让函数体第一行比其它语句多缩/少缩」——这就是 syntactic symbol 分类如此细致的意义。

（anchor 后面的数字是 buffer 字符位置，会随你代码的空格、行长浮动，没有记忆价值。手册同一份例子给出的数字就和本机不同——重要的是**符号**是 `statement` / `defun-block-intro`。）

再看一段有 `if` 的：

```c
int add(int val, int incr, int doit)
{
    if (doit)
        {
            return (val + incr);
        }
    return (val);
}
```

把光标放在 `{`（`if (doit)` 后面那一行）按 `C-c C-s`：

```text
Syntactic context: ((substatement-open 44))
```

——`substatement-open`（子语句块开头的花括号），anchor 44 指向 `if` 所在语句的锚点位置。这条 element 直接告诉你两件事：**这行的身份是「一个子语句的 `{`」**、**它是相对 `if` 那一行缩进的**。风格可以按这个 symbol 单独决定 `{` 是跟在 `if` 后面同一行、往下缩进、还是干脆顶格——`c-offsets-alist` 里对 `substatement-open` 设 `0` 就顶格到 `if` 所在列，设 `+` 就多缩一级，设向量 `[0]` 就绝对 0 列。第 2 章会把每种 offset 跑一遍。

顺带看这段里其它几行各自是什么（本机实测，`C-c C-s` 逐行）：

```text
L3 "    if (doit)"                -> ((defun-block-intro 38))
L4 "        {"                    -> ((substatement-open 44))
L5 "            return (val + incr);" -> ((statement-block-intro 62))
L6 "        }"                    -> ((block-close 62))
L7 "    return (val);"            -> ((statement 44))
```

一整套 `-intro` / `-open` / `-close` 的分工在这一段里全齐了：`if` 是函数体第一行（`defun-block-intro`）、它下面的 `{` 是子语句块开头（`substatement-open`）、块里第一句是 `statement-block-intro`、闭合它的 `}` 是 `block-close`、块外的 `return` 回到普通 `statement`。

（手册这段例子给的 anchor 数字与本机略不同，因为源码里空格/宽度不同；anchor 的**数值**随代码字节数浮动，符号**语义**永远稳定。学习阶段只看符号是什么、指向的 anchor 大概在哪一行，不用背数字。）

## 1.4 谁做这个分析：`c-guess-basic-syntax`

CC Mode 用来做第一步分析的内部函数叫 `c-guess-basic-syntax`——手册第 10.1 节明确写了它的用法：

```elisp
(defun my-debug-syntax ()
  "Print the syntactic context of the current line for debugging."
  (interactive)
  (message "%S" (c-guess-basic-syntax)))
```

在任意 CC Mode buffer 里 `M-x my-debug-syntax` 就能看到 echo area 打印的当前行 syntactic context。它跟 `C-c C-s` 输出的是同一个东西——`C-c C-s`（`c-show-syntactic-information`）本质上就是 `c-guess-basic-syntax` 的**交互式壳**，只不过它额外高亮 anchor position（让你直接看到「这行是相对哪一处缩进的」）。

给数字参数（`C-u C-c C-s`）时，`c-show-syntactic-information` 把 syntactic context **作为注释插进当前行**（手册原文脚注）——写自定义 line-up 函数时（第 2 章）用它把当前状态打出来调试特别顺手。

`c-guess-basic-syntax` 主要给 CC Mode 内部用，但**也是你能调用的公共 API**：手册第 10.1 节明确说「它有时在 line-up function 或 `c-special-indent-hook` 上的函数里有用」——这两个都是第 2 章会碰到的定制点。

## 1.5 syntactic symbol 全表：按语言构造分七组

CC Mode 认识的 syntactic symbol 总数接近 60 个（手册第 10.2 节列全表 + 各子节点用真实代码演示）。**全背下来不需要**，但要建立「有分类、按符号命名」的直觉。手册自己的分组是这样的：

**Function Symbols**（顶层函数定义相关）：`topmost-intro`（顶层定义首行）、`topmost-intro-cont`（顶层定义续行）、`defun-open`（顶层函数的 `{`）、`defun-close`（顶层函数的 `}`）、`defun-block-intro`（顶层函数体的首行）、`inline-open`/`inline-close`（类内的内联方法 `{` `}`）、`func-decl-cont`（函数参数列表右括号到 `{` 之间那一段，C++/Java 的 `throws` 之类写在这里）。

**Class Symbols**（类/结构体相关）：`class-open`、`class-close`、`inher-open`/`inher-cont`/`inher-intro`（C++ 继承列表）、`member-init-intro`/`member-init-cont`（C++ 成员初始化列表）、`template-args`/`access-label`（C++ 模板实参 / `public:`/`private:`）、`block-open`/`block-close`（匿名块）、`label`/`case-label`/`substatement-label`（ goto 标签 / switch 里的 case / `if` 后紧跟的 label）。

**Conditional Construct Symbols**（条件构造）：`substatement`（`if`/`else`/`while`/`do`/`switch` 后面那一条语句本身）、`substatement-open`（这条语句如果是 `{`，那这个 `{` 是 substatement-open）、`statement-cont`（语句的续行）、`arglist-cont`/`arglist-cont-nonempty`/`arglist-close`/`arglist-intro`（`(` 参数列表的续行 / 非空续行 / 右括号 / 首行）。

**Switch Statement Symbols**（switch/case 特有）：`case-label`（`case X:` 那行）、`statement-case-intro`（`case` 后第一条语句）、`statement-case-cont`（`case` 后的续行）、`case-block-intro`/`case-block-cont`（`case` 后紧跟 `{` 块的情况）。

**Brace List / Paren List / Enum Symbols**（用大/小括号或花括号包的列表）：`brace-list-open`/`brace-list-close`/`brace-list-intro`/`brace-list-entry`/`brace-list-cont`（C 里 `int arr[] = {...};` 那种）、`paren-entry`（`(` 括号里的每一项）、`enum`（枚举项，如 `int color = { RED, GREEN };`）、`extern-intro`（`extern "C" {...}` 里的首行）。

**External Scope Symbols**（文件顶层非函数/类的其它构造）：`extern-open`/`extern-close`/`namespace-open`/`namespace-close`/`inclass`（类内的顶层构造）、`inextern`/`innamespace`、`using-method-decl`/`using-class-decl`（Objective-C 2.0 的 `@property`）。

**Statement / Literal / K&R / Objective-C / Java / Constraint Symbols**（其它）：`statement`（普通语句，前面 1.3 见过）、`top-level-cont`（顶层续行）、`string`（多行字符串里）、`c`（多行 C 块注释里）、`cpp-macro`（C++ 风格宏，即 `#define X Y`）、`knr-argdecl`/`knr-argdecl-intro`（老式 K&R C 的形参声明）、`objc-method-intro`/`objc-method-access`（Objective-C 方法头）、`annotation-top-cont`（Java 注解）、`constraint-cont`（C++20 concept/requires 续行）。

一份「完整 syntactic symbol 表 + 语义」在手册第 10.2 节里，`C-h v c-offsets-alist` 也能查到当前 buffer 里所有 symbol 的完整集合（buffer-local 值里每个 symbol 都有条目，见第 2 章）。

**命名规律**必须记，因为符号名会自己解释自己：

- `-open`：这个 `{` **打开**一个构造（`defun-open`、`class-open`、`substatement-open`、`block-open`）。
- `-close`：这个 `}` **闭合**一个构造。
- `-intro`：这个构造**开头之后的第一行**（`defun-block-intro`、`class-cont` 里的 intro、`brace-list-intro`）。
- `-cont`：**续行**（多行构造里除首行以外的行；`topmost-intro-cont`、`statement-cont`、`arglist-cont`）。

一行的 syntactic symbol 长什么样，几乎能直接从「这行首字符是什么 + 上一行是什么构造」推出来——`if (a)` 之后如果换行放 `{`，符号是 `substatement-open`；如果同一行写 `if (a) {` 换行后代码，代码行符号是 `substatement`；`switch` 里的 `case X:` 是 `case-label`。剩下想不通的按 `C-c C-s` 现场看，永远比猜快。

## 1.6 anchor 与 label/注释的特殊规则

一条容易被忽略但对**读懂 CC Mode 输出**很重要的规则：手册第 10.1 节明说，「一行开头是 label 或纯注释时，这一行**永远不会是后面某行的 anchor**」。CC Mode 会跳过它们，往后（往上）找到最近一条既不是 label 也不是注释、并且 nest 层数一样的行作为 anchor。

手册给的 Pike 例子：

```text
1: int a()
2: {
3:   foo: {
4:     bar: if (t)
5:         x;
6:       y;
7:     }
8:     y;
9: }
```

第 4 行 `bar: if (t)` 的 syntactic context 是：

```elisp
((defun-block-intro 9) (label 9))
```

——两个 element：一个补 anchor 的 `defun-block-intro`（位置 9 是第 2 行的 `{`，因为第 3 行有 label 不能作为 anchor，CC Mode 往上跳到第 2 行 `{`），一个说明「这行开头是 label」的 `label`（同样 anchor 到位置 9）。这条规则让风格可以给 label 单独缩进——比如 C 里 `goto` 目标常顶到某个特殊列，就是靠 `label` symbol 的 offset 和 `defun-block-intro`/`statement-block-intro` 的 offset 不同来实现的。

## 1.7 关掉整套引擎：`c-syntactic-indentation`

有时候你就是不想让 CC Mode 按语法缩进——比如编辑一份被格式化脚本改过的老代码，每行独立缩进更稳。手册第 10 章的 `c-syntactic-indentation` 就是这个逃生舱：

```elisp
(setq-default c-syntactic-indentation nil)
```

实测 `-Q` 干净状态默认值是 `t`（开）。关掉之后：

- **所有缩进命令都变成「跟上一行缩进一样深」**，不再做任何 syntactic 分析；
- `<TAB>`（`c-indent-line-or-region`，见 00 章的版本漂移）变成「按 `c-basic-offset` 加减」——`C-u TAB` 是反方向；
- 风格系统、`c-offsets-alist`、`c-special-indent-hook` **都失去效果**（手册原文点名这三个失效）；
- 电键里那些「重缩当前行」的行为也失效（因为重缩就是靠语法分析），但像 `#` 强制顶格、`}` 自动换行这些不依赖缩进的电键行为还在。

当前 buffer 里临时切换用 `M-x c-toggle-syntactic-indentation`（这个命令在 `c-mode-base-map` 里没有默认键位，只能 `M-x` 调，00 章表格里也标了这一点）。

这条开关适合的场景不多，但值得知道：**它让你能把「CC Mode 的缩进引擎关掉」变成一次操作，而不是逐个关 electric/auto-newline/hungry delete**。调试某一行 CC Mode 算出的缩进让你意外时，先按 `M-x c-toggle-syntactic-indentation` 关掉，看关掉前后差异——如果关掉后你满意，说明 CC Mode 的分析结果和你的直觉不一样，问题在 `c-offsets-alist`；如果关掉后你也不满意，问题在 anchor 定位（回看代码本身是否有 CC Mode 认不出的构造）。

## 1.8 本章导航速查

- 现场看某行的 syntactic context：`C-c C-s`（`c-show-syntactic-information`）。加数字参数（`C-u C-c C-s`）把结果作为注释插进当前行。
- 现场看某行 offset 是从哪来的：`C-h v c-offsets-alist` 查当前 buffer 的绑定，或者 `C-h k TAB` 查 `<TAB>` 绑到什么命令、命令的文档串里讲清「先分析、再查 offset」。
- 现场改一个 symbol 的 offset：`C-c C-o`（`c-set-offset`），提示「symbol 是什么、offset 改成什么」——第 2 章专门讲 offset 的形态。
- 现场切风格：`C-c .`（`c-set-style`）——第 3 章。
- 关掉整个引擎：`M-x c-toggle-syntactic-indentation`。

---

上一章：[00 · CC Mode 是什么：一套引擎、七种语言](00-overview-and-activation.md)　｜　下一章：[02 · c-offsets-alist 实战：offset 的形态与 line-up 函数](02-c-offsets-alist.md)　｜　返回：[CC Mode 教程](README.md)
