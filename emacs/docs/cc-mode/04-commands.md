# 04 · 日常命令：缩进、注释、移动、预处理

前三章把 CC Mode 的底层机制（syntactic context、offset、风格）讲透了。这一章换视角：你打开一个 C 文件，**每天真正按的那些键**——缩进当前行/区域/函数、注释和取消注释、在函数和语句间跳、在 `#if` 嵌套里上下走、宏展开、反斜杠对齐……全部实测过。

## 4.1 缩进命令族

### `TAB`（`c-indent-line-or-region`）

CC Mode 重定义了 `TAB`——不再是「插入一个制表符」，而是「按 CC Mode 规则缩进」。具体行为取决于 `c-tab-always-indent`（默认 `t`）：

- `c-tab-always-indent=t`（默认）：`TAB` **总是缩进**当前行（如果 region 激活则缩进整个 region），**绝不插入 tab 字符**。
- `c-tab-always-indent=nil`：`TAB` 在行首缩进、行中插入 tab。
- `c-tab-always-indent=other`：行首缩进、行中插入 tab、行尾缩进。

本机实测（c-mode, `c-tab-always-indent=t`）：光标在任何位置按 `TAB`，当前行被重新缩进。

### `C-M-\`（`indent-region`）

缩进整个 region。这是「换风格后重排代码」的标配：`C-x h`（全选）+ `C-M-\`（重排）。

### `C-M-q`（`c-indent-exp`）

缩进「当前表达式」——通常是一个函数体或一个复合语句。光标在 `{` 上按 `C-M-q`，整个 `{}` 块被重排。

### `C-c C-q`（`c-indent-defun`）

缩进当前函数定义。光标在函数体内任何位置按 `C-c C-q`，整个函数（从返回类型到闭 `}`）被重排。

**对比**：

| 键 | 命令 | 作用范围 |
|---|---|---|
| `TAB` | `c-indent-line-or-region` | 当前行（或 region） |
| `C-M-\` | `indent-region` | region |
| `C-M-q` | `c-indent-exp` | 当前表达式（`{}` 块） |
| `C-c C-q` | `c-indent-defun` | 当前函数 |

### `C-j`（`electric-newline-and-maybe-indent`）

换行 + 缩进新行。跟 `RET` 的区别：`C-j` 换行后自动按 CC Mode 规则缩进；`RET` 只换行不缩进（`RET` 绑定到 `newline`，不是 electric）。

## 4.2 注释命令

### `M-;`（`comment-dwim`）

智能注释——Emacs 通用命令，CC Mode 没重定义。行为取决于上下文：

- region 激活：注释/取消注释整个 region。
- 光标在注释里：去掉注释前缀。
- 否则：在当前行尾插入注释。

### `C-c C-c`（`comment-region`）

注释当前 region。CC Mode 里默认用 `/* ... */` 风格（C 块注释）。

### `M-x uncomment-region`

取消注释。

### `C-c C-k`（`c-toggle-comment-style`）

在 `/* ... */` 和 `// ...` 两种注释风格间切换。本机实测：c-mode 默认是 `/*`（block comment style），按 `C-c C-k` 切到 `//`（line comment style），再按切回来。

## 4.3 移动命令

### 函数级移动

| 键 | 命令 | 作用 |
|---|---|---|
| `C-M-a` | `c-beginning-of-defun` | 跳到当前函数开头 |
| `C-M-e` | `c-end-of-defun` | 跳到当前函数末尾 |
| `C-M-h` | `c-mark-function` | 选中当前函数 |

`C-M-a`/`C-M-e` 是 CC Mode 重定义的版本（Emacs 默认的 `beginning-of-defun`/`end-of-defun` 靠 `defun-prompt-regexp` 匹配，CC Mode 用自己的语法分析更准）。

### 语句级移动

| 键 | 命令 | 作用 |
|---|---|---|
| `M-a` | `c-beginning-of-statement` | 跳到当前语句开头 |
| `M-e` | `c-end-of-statement` | 跳到当前语句末尾 |

本机实测：光标在 `x++;` 上按 `M-a`，光标移到 `x` 前面；按 `M-e`，光标移到 `;` 后面。

### 括号级移动

| 键 | 命令 | 作用 |
|---|---|---|
| `C-M-f` | `forward-sexp` | 向前跳一个 S-表达式（越过匹配的 `()`/`{}`/`[]`） |
| `C-M-b` | `backward-sexp` | 向后跳一个 S-表达式 |

CC Mode 没重定义这两个——它们靠 Emacs 内置的括号匹配，在 C 代码里同样有效。

### 条件编译移动

这是 CC Mode 特有的、处理 `#if`/`#ifdef`/`#ifndef` 嵌套的命令族：

| 键 | 命令 | 作用 |
|---|---|---|
| `C-c C-u` | `c-up-conditional` | 跳到上一层 `#if` |
| `C-c C-p` | `c-backward-conditional` | 向后跳到上一个 `#if`/`#elif`/`#else`/`#endif` |
| `C-c C-n` | `c-forward-conditional` | 向前跳到下一个 `#if`/`#elif`/`#else`/`#endif` |

本机实测（这段代码）：

```c
#if A
int a;
#if B
int b;
#endif
int c;
#endif
```

光标在 `int b;` 上：

```text
C-c C-u → 跳到 #if B（第 3 行）
C-c C-u → 跳到 #if A（第 1 行）
```

光标在 `int a;` 上：

```text
C-c C-n → 跳到 int c;（第 6 行，跳过 #if B 嵌套）
```

**注意**：`c-up-conditional` 需要数字参数——`(c-up-conditional 1)` 跳一层。交互式按 `C-c C-u` 默认等价于 `(c-up-conditional 1)`。

还有一个非交互式变体 `c-up-conditional-with-else`——功能相同但把 `#else` 当作「上一层」处理。`c-up-conditional` 跳过 `#else`（只认 `#if`）；`c-up-conditional-with-else` 在 `#else` 上停。这个函数没绑键，要 `M-x c-up-conditional-with-else`。

### 宏定义移动

`c-down-conditional` 从 `#if` 跳到对应的 `#else`/`#endif`。没绑键，要 `M-x c-down-conditional`。

## 4.4 其他实用命令

### `C-c C-z`（`c-display-defun-name`）

在 echo area 显示当前函数名。类似 Which Function mode（第 0 章 0.3 节）但按需显示。

### `C-c C-e`（`c-macro-expand`）

展开当前区域的宏。选中一段含宏调用的代码，按 `C-c C-e`，CC Mode 调 C 预处理器展开宏、结果弹到新 buffer。

### `C-c C-\`（`c-backslash-region`）

对齐 region 里的反斜杠续行。写多行宏时超好用：

```c
#define LONG_MACRO(a, b) \
  do_something_with(a)   \
  + do_something_with(b)
```

选中这三行按 `C-c C-\`，反斜杠全部对齐到同一列。

### `C-c C-b`（`c-submit-bug-report`）

自动收集 CC Mode 版本、Emacs 版本、相关变量值，生成一封 bug report 邮件。发现 CC Mode 行为异常时用。

## 4.5 hungry delete

`C-c C-d`（`c-hungry-delete-forward`）：「饥饿删除」——向前删除时**跳过所有空白和换行**，直到下一个非空白字符。对比普通 `C-d`（只删一个字符）：

```text
int    x    =    1;
    ↑
    光标在这里

C-d    → 删掉一个空格 → int   x    =    1;
C-c C-d → 跳过所有空白 → intx    =    1;
```

`c-hungry-delete-forward` 没绑到 `C-d` 上（`C-d` 还是普通删除），要显式按 `C-c C-d`。如果你想让 `C-d` 和 `DEL` 都变成 hungry，用 `c-toggle-hungry-state`（`M-x c-toggle-hungry-state`）——开启后 `C-d` 和 `DEL` 都走 hungry 删除。这个开关默认没绑键。

## 4.6 narrowing：聚焦一个函数

CC Mode 没重定义 narrowing——这是 Emacs 通用功能，但在处理大文件时特别有用：

- `C-x n d`（`narrow-to-defun`）：只显示当前函数，buffer 其它部分隐藏。
- `C-x n w`（`widen`）：恢复显示整个 buffer。

搭配 `C-c C-q`（重排当前函数）用：narrow 到函数 → `C-c C-q` → `C-x n w`。这样重排只影响一个函数，不会误改文件其它部分。

## 4.7 命令速查表

| 键 | 命令 | 作用 |
|---|---|---|
| `TAB` | `c-indent-line-or-region` | 缩进当前行/region |
| `C-M-\` | `indent-region` | 缩进 region |
| `C-M-q` | `c-indent-exp` | 缩进当前表达式 |
| `C-c C-q` | `c-indent-defun` | 缩进当前函数 |
| `C-j` | `electric-newline-and-maybe-indent` | 换行+缩进 |
| `M-;` | `comment-dwim` | 智能注释 |
| `C-c C-c` | `comment-region` | 注释 region |
| `C-c C-k` | `c-toggle-comment-style` | 切 `/* */` ↔ `//` |
| `C-M-a`/`C-M-e` | `c-beginning/end-of-defun` | 函数首尾 |
| `C-M-h` | `c-mark-function` | 选中函数 |
| `M-a`/`M-e` | `c-beginning/end-of-statement` | 语句首尾 |
| `C-M-f`/`C-M-b` | `forward/backward-sexp` | 括号级移动 |
| `C-c C-u` | `c-up-conditional` | 跳到上一层 `#if` |
| `C-c C-p`/`C-c C-n` | `c-backward/forward-conditional` | `#if` 前后跳 |
| `C-c C-z` | `c-display-defun-name` | 显示当前函数名 |
| `C-c C-e` | `c-macro-expand` | 宏展开 |
| `C-c C-\` | `c-backslash-region` | 对齐反斜杠 |
| `C-c C-d` | `c-hungry-delete-forward` | 饥饿删除 |
| `C-c C-b` | `c-submit-bug-report` | 提交 bug report |
| `C-x n d` / `C-x n w` | `narrow-to-defun` / `widen` | 聚焦/恢复 |

## 4.8 本章导航速查

- 缩进当前行：`TAB`；缩进函数：`C-c C-q`；缩进 region：`C-M-\`。
- 注释：`M-;`（智能）、`C-c C-c`（region）、`C-c C-k`（切风格）。
- 移动：`C-M-a`/`C-M-e`（函数）、`M-a`/`M-e`（语句）、`C-c C-u`/`C-c C-p`/`C-c C-n`（条件编译）。
- 第 5 章讲 electric keys 和 auto-newline——你输入 `{`/`}`/`;` 时 CC Mode 的「自动反应」。

---

上一章：[03 · 风格系统：c-default-style、内置风格与自定义风格](03-styles.md)　｜　下一章：[05 · Electric Keys 与 Auto-newline](05-electric-and-auto-newline.md)　｜　返回：[CC Mode 教程](README.md)
