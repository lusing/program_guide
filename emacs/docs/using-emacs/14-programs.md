# 14 · 程序编辑

前面讲的文本单位（词、句、段）面向人类语言。程序代码有自己的结构：**表达式、括号、函数定义**。Emacs 为这些结构提供了一整套操作命令。这一章讲的就是在编程 major mode 下，怎么利用这些结构高效编辑。

## 14.1 编程 Major Mode 概览

Emacs 内置了几十种编程语言的 major mode：C、C++、Python、Java、JavaScript、Ruby、Perl、Shell、Lisp、Scheme、Go、Rust、TypeScript……每种 mode 都定义了该语言的：

- 表达式语法（什么算一个"平衡表达式"）
- 缩进规则
- 注释格式（`comment-start` 变量，如 C 里是 `"// "`，Lisp 里是 `"; "`）
- 语法高亮规则
- 函数定义的边界（defun 的概念）

所有编程 mode 都继承自 `prog-mode`。进入任何编程 mode 时，Emacs 先运行 `prog-mode-hook`，再运行该 mode 自己的 hook（如 `c-mode-hook`）。

如果 Emacs 编译时链接了 **tree-sitter** 库，还会提供一组以 `-ts-` 命名的 mode（如 `c-ts-mode`、`python-ts-mode`），它们用增量解析器获得更精确的语法理解。

## 14.2 程序缩进

### 14.2.1 单行缩进：`TAB`

在编程 mode 下，`TAB`（命令 `indent-for-tab-command`）的行为是：**根据前几行的语法结构，重新缩进当前行**。这是保持代码整齐的最基本操作——每次写完一行，按 `TAB` 让 Emacs 帮你缩进。

如果 `TAB` 按下时 region 处于激活状态，它会缩进 region 内的**所有行**。

如果光标当前在行首的缩进区域（空白字符上），`TAB` 缩进后会把光标移到第一个非空白字符处。

### 14.2.2 多行缩进

| 键 | 命令 | 作用 |
|---|---|---|
| `C-M-\` | `indent-region` | 缩进 region 内的每一行 |
| `C-M-q` | 模式相关函数 | 重缩进一个括号组内的所有行 |

`C-M-\` 是最常用的批量缩进命令。选好 region 后按它，region 内每一行都按 `TAB` 的规则重新缩进。带数值参数 N 时，把 region 内每行都缩进到第 N 列。

`C-M-q` 把光标所在的括号组（如一个函数体、一个 `let` 块）内的所有行重新缩进，但不改变括号组首行的缩进。如果你连首行也要修正，先按 `TAB` 再按 `C-M-q`。

`C-u TAB`（带参数的 `TAB`）在 Lisp、C 等 mode 下会把当前行所在的括号组**整体平移**——首行缩进修正后，后面的行跟着移动相同距离，不改变相对缩进。

## 14.3 注释操作

| 键 | 命令 | 作用 |
|---|---|---|
| `M-;` | `comment-dwim` | 智能插入/对齐/取消注释 |

`M-;` 是 `comment-dwim`（Do What I Mean）的绑定——它根据当前状态做不同的事：

- **region 激活时**：给 region 内每行加注释（或去掉注释，如果已有注释）。
- **行尾有注释时**：把注释对齐到标准位置。
- **其他情况**：在当前行插入注释。

这个"智能"命令覆盖了大多数注释操作场景。

如果要给整个 region 加注释（不管当前状态），也可以用 `M-x comment-region`。很多编程 mode 还绑了 `C-c ;` 或类似键来调用它。去掉注释用 `M-x uncomment-region`。

**注释的格式**由 major mode 决定。变量 `comment-start` 定义注释起始串（如 `"// "`、`"; "`、`"# "`）。变量 `comment-end` 定义注释结束串（C 里是 `""`，`/* */` 式注释里是 `" */"`）。

**Lisp 代码里的注释约定**：

```lisp
;;; 三个分号：段标题，靠左对齐
;;  两个分号：行级注释，按代码缩进
(defun foo (x)
  ;; 一个分号：行尾注释
  (1+ x))           ; 行尾注释
```

`TAB` 会根据分号数量决定缩进位置：三个分号的注释靠左，两个分号的按代码缩进，一个分号的按行尾对齐。

## 14.4 按表达式移动

编程 mode 下，Emacs 用**平衡表达式**（balanced expression，内部叫 sexp）代替"词"作为基本单位。一个 sexp 可以是一个符号、一个数字、一个字符串，或者一对匹配括号及其中的全部内容。

| 键 | 命令 | 作用 |
|---|---|---|
| `C-M-f` | `forward-sexp` | 向前移过一个平衡表达式 |
| `C-M-b` | `backward-sexp` | 向后移过一个平衡表达式 |
| `C-M-n` | `forward-list` | 向前移过一组括号 |
| `C-M-p` | `backward-list` | 向后移过一组括号 |
| `C-M-a` | `beginning-of-defun` | 移到当前/上一个函数定义开头 |
| `C-M-e` | `end-of-defun` | 移到当前/下一个函数定义结尾 |
| `C-M-k` | `kill-sexp` | 杀死一个平衡表达式 |
| `C-M-@` | `mark-sexp` | 选中下一个平衡表达式 |

注意键位的类比关系：

| 单位 | 向前 | 向后 |
|---|---|---|
| 字符 | `C-f` | `C-b` |
| 词 | `M-f` | `M-b` |
| 表达式 | `C-M-f` | `C-M-b` |

`C-M-f` 的行为：如果光标后面是一个开括号，它会跳到匹配的闭括号后面；如果是一个符号或字符串，它跳过去。`C-M-b` 是反方向。负参数反方向走。

`C-M-n` / `C-M-p` 按**括号嵌套**移动——`C-M-n` 跳过光标后面的一个完整括号组（从开括号前到闭括号后），`C-M-p` 反向。

`C-M-a` / `C-M-e` 按**函数定义**（defun）移动。在大多数编程 mode 里，一个顶格的开括号被视为函数开头。这两个命令可以带参数——`C-u 3 C-M-a` 往回跳三个函数。

`C-M-k` 杀死光标后面的一个完整表达式。这在删除函数调用、删除整个列表时特别有用。

`C-M-@`（也可写作 `C-M-SPC`）把 mark 设在下一个个表达式末尾，选中它。连续按可以扩展选中多个表达式。

## 14.5 括号匹配

写代码时括号配对至关重要。Emacs 提供多层括号匹配支持。

### 14.5.1 内置的闪烁匹配

默认情况下，每当你输入一个闭括号（`)`、`]`、`}` 等），Emacs 会短暂高亮显示匹配的开括号。如果开括号不在屏幕上，Emacs 在 echo area 显示它附近的文本。

控制这个行为的变量：

- `blink-matching-paren`：`t`（默认）开启，`nil` 关闭，`jump` 让光标短暂跳到开括号处。
- `blink-matching-delay`：高亮持续多少秒，默认 1。
- `blink-matching-paren-distance`：向后搜索多少字符来找匹配的开括号，默认 102400。

### 14.5.2 Show Paren Mode

`M-x show-paren-mode` 开启 Show Paren mode——一个更强大的括号匹配 minor mode。开启后，只要光标在一个括号的旁边，**两个匹配括号**（以及它们之间的文本，取决于设置）都会被高亮。

Show Paren mode 默认在编辑类 buffer 里是开启的。

控制变量：

- `show-paren-style`：`parenthesis`（只高亮两个括号）、`expression`（高亮整个括号组内的文本）、`mixed`（匹配括号可见时高亮括号，不可见时高亮表达式）——默认 `mixed`。
- `show-paren-when-point-inside-paren`：`nil`（默认）只在括号外侧触发；设为 `t` 时光标在括号内侧也触发。

### 14.5.3 Electric Pair Mode

`M-x electric-pair-mode` 开启 Electric Pair mode。开启后，输入一个开括号会自动插入匹配的闭括号，光标留在两者之间。如果你还是手动打了闭括号，光标会跳过已有的闭括号而不重复插入。

在 region 激活时输入括号，会把选中内容包裹在括号里——这比先打括号再移过去选中要快得多。

### 14.5.4 用 mark-sexp 选中括号内容

`C-M-@`（`mark-sexp`）把 mark 设在光标后面的平衡表达式末尾。这在你想复制、删除或修改括号内全部内容时很有用。例如 `C-M-@ C-w` 剪切一个表达式，`C-M-@ M-w` 复制它。

## 14.6 语法高亮（Font Lock）

Font Lock mode 是一个 buffer-local 的 minor mode，负责给代码上色——关键字一种颜色、字符串一种颜色、注释一种颜色、函数名一种颜色。

Font Lock mode **默认全局开启**。在支持它的 major mode 里，打开文件就会自动启用。

`M-x font-lock-mode` 可以在当前 buffer 切换开关。`M-x global-font-lock-mode` 全局切换。

Font Lock 使用一组命名的 face 来着色，如 `font-lock-keyword-face`（关键字）、`font-lock-string-face`（字符串）、`font-lock-comment-face`（注释）、`font-lock-function-name-face`（函数名）等。你可以用 `M-x customize-group RET font-lock-faces RET` 修改这些 face 的颜色和样式。

对于大文件，Emacs 不会一次性给整个 buffer 着色——它只着色当前可见的部分，滚动时再着色新出现的部分（这叫 JIT Lock，Just-In-Time Lock）。

语法高亮的底层实现可以是正则匹配、语法表、或者 tree-sitter 解析器。具体用哪种由 major mode 决定。

## 14.7 Which Function Mode

`M-x which-function-mode` 开启 Which Function mode——一个 global minor mode。开启后，mode line（或 header line）会显示光标当前所在的**函数名**，并随光标移动实时更新。

这在编辑长文件时特别有用：你滚动到文件中间，不用 `C-M-a` 跳到函数开头就能知道自己在哪。

默认在所有支持 Imenu 的 major mode 里生效。变量 `which-func-modes` 控制生效的 mode 列表——默认值 `t` 表示所有支持的 mode。

变量 `which-func-display` 控制显示位置：`mode`（mode line，默认）、`header`（header line）、`mode-and-header`（两处都显示）。

## 14.8 小结

- 编程 mode 按语言定义了表达式语法、缩进规则、注释格式、高亮规则。
- `TAB` 按语言规则缩进当前行；`C-M-\` 缩进 region。
- `M-;`（`comment-dwim`）智能处理注释。
- `C-M-f` / `C-M-b` 按表达式移动，`C-M-a` / `C-M-e` 按函数定义移动，`C-M-k` 杀表达式。
- 括号匹配有三层：内置闪烁、Show Paren mode、Electric Pair mode。
- Font Lock mode 默认开启，负责语法高亮。
- Which Function mode 在 mode line 显示当前函数名。

下一章讲 Dired——Emacs 内置的目录与文件管理器。在 Dired 里，你可以用类似编辑文本的方式批量操作文件。

---

上一章：[13 · 模式：major 与 minor](13-modes.md) ｜ 下一章：[15 · Dired：目录与文件管理器](15-dired.md) ｜ 返回：[使用 Emacs 教程](README.md)
