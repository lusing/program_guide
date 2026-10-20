# 06 · Filling、Macros 与注释格式

第 5 章讲了 electric keys 和 auto-newline——你**输入**时 CC Mode 的自动反应。这一章讲另外三个日常话题：**段落填充**（注释和代码折行）、**宏定义**（多行反斜杠对齐、宏展开）、**注释格式**（块注释前缀、文档注释风格）。

## 6.1 `c-fill-paragraph`：注释折行

`M-q` 在 CC Mode 里绑定到 `c-fill-paragraph`（不是 Emacs 默认的 `fill-paragraph`）。它会根据光标所在位置决定怎么折行。

### 块注释折行

光标在 `/* ... */` 注释里按 `M-q`，注释内容按 `fill-column` 折行、保持 `*` 前缀对齐：

```text
/* This is a long comment that should be wrapped when fill-paragraph is called on it. */

fill-column=60 折行后：

/* This is a long comment that should be wrapped when
   fill-paragraph is called on it. */
```

注意折行后第二行的 `*` 前缀缩进——`c-fill-paragraph` 自动对齐到第一颗 `*` 下面。

### 行注释折行

光标在 `// ...` 注释里按 `M-q`，每行都补上 `//` 前缀：

```text
// This is a long line comment that should be wrapped when fill-paragraph is called.

fill-column=50 折行后：

// This is a long line comment that should be
// wrapped when fill-paragraph is called.
```

### 代码不折行

光标在**代码**里按 `M-q`，`c-fill-paragraph` **不做任何事**（实测确认）——它只处理注释，不会把代码行拆短。这是 CC Mode 的特意设计：折行代码会破坏语法。

### `c-indent-comments-syntactically-p`

默认 `nil`——注释折行后**不**重新按 syntactic 规则缩进，只按 `c-indent-comment-alist` 的注释规则对齐。设为 `t` 则折行后重新跑完整的 syntactic 缩进。

## 6.2 多行宏：反斜杠对齐

写多行宏时，行尾的反斜杠要对齐才好看。`C-c C-\`（`c-backslash-region`）自动对齐 region 里所有反斜杠。

### 实测

```text
选中这三行，按 C-c C-\：

#define LONG_MACRO(a, b) \
  do_something_with(a) \
  + do_something_with(b)

结果：

#define LONG_MACRO(a, b)			\
  do_something_with(a)				\
  + do_something_with(b)
```

反斜杠全部对齐到列 48（`c-backslash-column` 的默认值）——用 tab 填充到目标列。

### 相关变量

| 变量 | 默认 | 作用 |
|---|---|---|
| `c-backslash-column` | 48 | 反斜杠对齐到的目标列 |
| `c-backslash-max-column` | 72 | 反斜杠不能超过的列（防止行太长） |

两个变量都是 `set-from-style`——风格可以覆盖。本机实测 gnu 和 linux 风格都用默认值 48/72。

### `c-electric-pound` 的辅助

第 5 章讲过 `#` 是 electric 键——输入 `#` 自动顶格。写多行宏时，换行后输入 `#` 会自动回到列 0，不用手动调缩进。

## 6.3 宏展开：`c-macro-expand`

`C-c C-e`（`c-macro-expand`）把选中的代码跑过 C 预处理器、把宏展开结果弹到新 buffer。

用法：

1. 选中一段含宏调用的代码（比如 `M-x mark-paragraph` 或手动选）。
2. 按 `C-c C-e`。
3. 新 buffer 显示展开后的代码。

**注意**：`c-macro-expand` 需要系统里有 C 预处理器（`cpp` 命令）。它用 `c-macro-preprocessor` 指定的命令（默认 `"cpp"`）做展开。

## 6.4 注释格式

### `c-block-comment-prefix`

块注释（`/* ... */`）续行的前缀字符串。默认是 `""`（空）——续行只缩进、不加前缀。设为 `"* "` 则续行以 `*` 开头：

```elisp
(setq c-block-comment-prefix "* ")
```

效果：

```text
/* This is a comment
 * that spans multiple
 * lines. */
```

本机实测 gnu 风格设了 `c-block-comment-prefix` 为 `""`（空字符串），linux 风格没设（用默认值 `""`）。

### `c-comment-prefix-regexp`

匹配「注释前缀」的正则——`M-;`（`comment-dwim`）插入注释时用。默认值匹配 `//` 和 `/*`：

```elisp
;; 默认值（CC Mode 5.35.2）
"\\(//+\\|\\**\\)"
```

意思是：`//`（一个或多个 `/`）或 `*`（一个或多个，用于块注释续行的 `*` 前缀）都算注释前缀。

### `c-comment-only-line-offset`

注释-only 行（整行只有注释、没有代码）的缩进偏移。可以是一个整数（相对 anchor 的偏移）或一个 dotted pair `(MIN . MAX)`（最小/最大偏移范围）。

本机实测 gnu 风格是 `(0 . 0)`——注释-only 行跟 anchor 同列、不额外偏移。linux 风格是 `0`（等价于 `(0 . 0)`）。

### `c-indent-comment-alist`

一个 alist，控制注释折行后怎么对齐。key 是注释类型（`block-line`、`block-intro` 等），value 是对齐方式（`block` 对齐到块注释的 `*` 列、`line` 对齐到行注释的 `//` 列等）。通常不用改——默认值在绝大多数场景下都对。

### `c-doc-comment-style`

文档注释风格——控制 `M-;` 在函数/类型上方插入文档注释时用哪种格式。本机实测 gnu 风格的值：

```elisp
((java-mode . javadoc)
 (pike-mode . autodoc)
 (c-mode    . gtkdoc)
 (c++-mode  . gtkdoc))
```

即：Java 文件用 Javadoc（`/** ... */`）、Pike 文件用 Autodoc、C/C++ 文件用 GTK-Doc。这个变量是 `set-from-style`——风格可以覆盖。

## 6.5 实战：写一段带注释和宏的代码

假设你要写这样一个头文件片段：

```c
#ifndef MY_HEADER_H
#define MY_HEADER_H

/* This function computes the factorial of a non-negative integer.
   It uses an iterative approach to avoid stack overflow for large inputs.
   The result is undefined for negative inputs. */
int factorial(int n);

/* Compute the greatest common divisor of two integers.
   Uses the Euclidean algorithm. */
int gcd(int a, int b);

#define MAX(a, b) \
  ((a) > (b) ? (a) : (b))

#define MIN(a, b) \
  ((a) < (b) ? (a) : (b))

#endif /* MY_HEADER_H */
```

**操作步骤**：

1. 写块注释时，先写 `/*` 然后随便写内容。写完后光标放注释里按 `M-q`，`c-fill-paragraph` 自动按 `fill-column` 折行、保持 `*` 前缀对齐。
2. 写 `#define MAX(a, b) \` 后换行写续行。写完后选中整个宏按 `C-c C-\`，反斜杠自动对齐。
3. `#endif` 后面的 `/* MY_HEADER_H */` 是可选的——写上方便定位 `#endif` 对应哪个 `#ifndef`。

## 6.6 常见坑

**坑 1：`M-q` 折行代码**

`c-fill-paragraph` 只处理注释——光标在代码里按 `M-q` 没有效果。这是设计行为，不是 bug。

**坑 2：块注释折行后 `*` 前缀没对齐**

检查 `c-block-comment-prefix` 和 `c-indent-comment-alist`。如果 `c-block-comment-prefix` 是 `""`（默认），续行只缩进不加 `*` 前缀；要 `*` 前缀就设成 `"* "`。

**坑 3：`C-c C-\` 对齐到列 48 但我的代码更宽**

改 `c-backslash-column`：

```elisp
(setq c-backslash-column 72)   ;; 对齐到列 72
```

**坑 4：`C-c C-e` 宏展开报「cpp not found」**

`c-macro-expand` 需要系统里有 `cpp` 命令。macOS 上装了 Xcode Command Line Tools 就有。检查：

```bash
which cpp
```

如果没有，装 Command Line Tools：`xcode-select --install`。

**坑 5：`M-;` 在函数上方插入了错误的文档注释风格**

检查 `c-doc-comment-style`——它决定用 Javadoc、GTK-Doc 还是 Autodoc。如果你想统一用 Javadoc：

```elisp
(setq c-doc-comment-style 'javadoc)   ;; 所有 CC Mode buffer 都用 Javadoc
```

## 6.7 本章导航速查

- 注释折行：`M-q`（`c-fill-paragraph`）。
- 反斜杠对齐：`C-c C-\`（`c-backslash-region`）。
- 宏展开：`C-c C-e`（`c-macro-expand`）。
- 块注释前缀：`c-block-comment-prefix`。
- 文档注释风格：`c-doc-comment-style`。
- 注释-only 行缩进：`c-comment-only-line-offset`。

---

上一章：[05 · Electric Keys 与 Auto-newline](05-electric-and-auto-newline.md)　｜　下一章：[07 · Font Locking：语法高亮](07-font-locking.md)　｜　返回：[CC Mode 教程](README.md)
