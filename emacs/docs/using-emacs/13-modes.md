# 13 · 模式：major 与 minor

从这一章开始，你会频繁遇到"模式"这个词。Emacs 的编辑行为不是铁板一块——打开 `.c` 文件时光标按 C 语言规则缩进，打开 `.txt` 文件时 `TAB` 只是插入空格，在 Dired buffer 里字母键全是文件操作命令。这些差异都来自**模式**。

Emacs 的模式分两类：**major mode**（主模式）和 **minor mode**（次模式）。理解它们的区别是理解 Emacs 行为的关键。

## 13.1 Major Mode

**每个 buffer 恰好有一个 major mode**——没有例外。Major mode 决定了这个 buffer 的大部分编辑行为：语法高亮怎么着色的、`TAB` 怎么缩进的、注释长什么样、哪些键绑了什么命令。

最基本的 major mode 叫 **Fundamental mode**——它不做任何特殊处理，每条命令都按最通用的方式工作。实际编辑中你几乎不会主动用它。

### 13.1.1 常见的 Major Mode

Major mode 大致分三族：

**文本类**：Text mode（纯文本）、Outline mode（大纲）、Org mode（笔记与任务管理）、HTML mode、TeX mode 等。

**编程类**：每种编程语言一个 mode——C mode、Python mode、Emacs Lisp mode、JavaScript mode 等等。它们都继承自一个共同的祖先 `prog-mode`。

**特殊用途类**：Dired mode（目录浏览）、Shell mode（终端交互）、Message mode（写邮件）等——这些 buffer 不对应普通文件。

### 13.1.2 怎么切换 Major Mode

Emacs 打开文件时会**自动选择** major mode（下一节讲它怎么选）。如果你想手动切换，用 `M-x` 调用目标 mode 的命令。命令名就是 mode 名加 `-mode`：

```
M-x text-mode RET       ← 切到 Text mode
M-x python-mode RET     ← 切到 Python mode
M-x emacs-lisp-mode RET ← 切到 Emacs Lisp mode
```

因为每个 buffer 只能有一个 major mode，所以切换就是"替换"——不存在"关闭"一个 major mode 的说法。

### 13.1.3 查看当前 Mode

`C-h m`（命令 `describe-mode`）显示当前 buffer 的 major mode 名字、简要说明、以及该 mode 定义的所有键绑定。这是你进入一个陌生 buffer 时第一个该按的键。

mode line（模式行）上也显示当前 major mode 的名字，在括号里，紧跟在 minor mode 指示器后面。例如：

```
-U:**--F1  *scratch*      (Lisp Interaction)
```

这里的 `(Lisp Interaction)` 就是 major mode。

### 13.1.4 Major Mode 的自动选择

打开文件时，Emacs 按以下优先级决定 major mode：

**第一步：文件局部变量。** 如果文件第一行（或第二行）包含 `-*-mode: xxx-*-` 这样的标记，Emacs 直接用指定的 mode。例如文件开头写 `; -*-Lisp-*-`，就进入 Lisp mode。

**第二步：shebang 行。** 如果文件以 `#!` 开头（Unix 脚本），Emacs 从解释器路径推断 mode。`#!/usr/bin/perl` → Perl mode，`#!/usr/bin/env python3` → Python mode。对应关系由变量 `interpreter-mode-alist` 控制。

**第三步：文件名。** 这是最常见的情况。变量 `auto-mode-alist` 是一张"文件名正则 → mode"的对照表。默认条目包括 `\\.c\\'` → `c-mode`、`\\.py\\'` → `python-mode`、`\\.el\\'` → `emacs-lisp-mode` 等几百条。

**第四步：文件内容。** 如果前三步都没匹配到，Emacs 还会用 `magic-fallback-mode-alist` 检查文件开头的内容来猜（比如检测到 HTML 标签就进 HTML mode）。

如果自动选择的结果不对，你可以手动 `M-x <mode>-mode` 切换。`M-x normal-mode` 可以重新按上述规则自动选择一次。

### 13.1.5 变量 `major-mode`

每个 buffer 有一个 buffer-local 变量 `major-mode`，其值是一个 symbol（如 `c-mode`），表示当前的 major mode。这个变量由 Emacs 自动设置，你不应该手动改它——但它常常出现在条件判断里，比如"只在 Python mode 下做某件事"。

变量 `major-mode` 的**默认值**决定新建 buffer（`C-x b` 创建的）和无法识别的文件用什么 mode。默认是 `fundamental-mode`。如果你想让新 buffer 默认进 Text mode，在 init 文件里写：

```lisp
(setq-default major-mode 'text-mode)
```

## 13.2 Minor Mode

Minor mode 是可选的功能开关。与 major mode 的区别：

| | Major Mode | Minor Mode |
|---|---|---|
| 数量 | 每个 buffer 恰好一个 | 可以同时开任意多个 |
| 作用 | 决定整个编辑环境 | 叠加一个特定功能 |
| 开关 | 只能切换为另一个 | 独立地开/关 |

Minor mode 又分两种：

**Buffer-local minor mode**：只在当前 buffer 生效。比如 Auto Fill mode（自动断行）、Flyspell mode（拼写检查）、Visual Line mode（视觉折行）。

**Global minor mode**：对所有 buffer 生效。比如 Line Number mode（mode line 显示行号）、Column Number mode（显示列号）、Delete Selection mode（选中文本后输入会替换选中内容）。

### 13.2.1 怎么开关 Minor Mode

每个 minor mode 都有一个同名的 mode 命令。调用方式：

```
M-x auto-fill-mode RET     ← 切换 Auto Fill mode
M-x show-paren-mode RET    ← 切换 Show Paren mode
M-x which-function-mode RET ← 切换 Which Function mode
```

不带参数调用 = **切换**（开的变关、关的变开）。带正参数 = 强制开启，带负参数或零 = 强制关闭。

有些 minor mode 还绑了快捷键。比如 `M-x auto-fill-mode` 没有默认快捷键，但 `overwrite-mode` 绑在了 `<Insert>` 键上。

### 13.2.2 Mode Line 上的 Minor Mode 标记

Buffer-local minor mode 开启时，mode line 上会显示一个短标记。常见的有：

- `Fill`：Auto Fill mode 已开启
- `Fly`：Flyspell mode 已开启
- `Ovwrt`：Overwrite mode 已开启

Global minor mode 的标记通常不在 mode line 上显示（比如 Line Number mode 是直接在 mode line 上显示行号，而不是一个 `Ln` 标记）。

### 13.2.3 Mode 变量

每个 minor mode 有一个同名的 **mode 变量**。变量值为非 `nil` 表示 mode 已开启，`nil` 表示关闭。例如 `auto-fill-mode` 这个变量的值反映 Auto Fill mode 的状态。

**不要直接 setq 这个变量来开关 mode**——变量只记录状态，不触发模式切换的逻辑。正确做法是调用 mode 命令。但通过 Customize 界面设置变量是安全的，因为 Customize 会自动调用 mode 命令。

## 13.3 Mode Hook：定制的接入点

每个 major mode（Fundamental mode 除外）都有一个 **mode hook**——一个 Lisp 函数列表，在该 mode 被启用时自动运行。Hook 的名字是 mode 名加 `-hook`：`text-mode-hook`、`c-mode-hook`、`python-mode-hook` 等。

此外还有两个**通用 hook**：

- `text-mode-hook`：所有文本类 major mode 启用时运行（在模式自己的 hook 之前）。
- `prog-mode-hook`：所有编程类 major mode 启用时运行（在模式自己的 hook 之前）。

Hook 最常见的用途是在进入某种 mode 时自动开启某些 minor mode。例如，在 init 文件里写：

```lisp
(add-hook 'text-mode-hook 'flyspell-mode)      ;; 文本 mode 自动开拼写检查
(add-hook 'prog-mode-hook 'display-line-numbers-mode) ;; 编程 mode 自动显示行号
(add-hook 'emacs-lisp-mode-hook 'eldoc-mode)   ;; Emacs Lisp mode 自动开 eldoc
```

Hook 是"定制"层面的概念——你不需要会写 Lisp 函数也能用，`add-hook` 加已有的 mode 命令就够了。更复杂的定制（比如设置某个 buffer-local 变量）需要写一个简单的 lambda 或 defun，这超出了本教程"使用"的范围。

## 13.4 小结

- 每个 buffer 恰好一个 major mode，决定整体编辑行为。
- Major mode 由文件名、shebang、文件局部变量自动选择，也可以 `M-x <name>-mode` 手动切换。
- `C-h m`（`describe-mode`）查看当前 mode 的说明和键绑定。
- Minor mode 是可以叠加的功能开关，分 buffer-local 和 global 两种。
- Mode hook 是在 mode 启用时自动执行定制的机制，最常见的用法是自动开启 minor mode。

下一章讲程序编辑——在编程 mode 下，Emacs 提供了表达式移动、括号匹配、注释操作、语法高亮等一系列专门功能。

---

上一章：[12 · 文本编辑](12-text-editing.md) ｜ 下一章：[14 · 程序编辑](14-programs.md) ｜ 返回：[使用 Emacs 教程](README.md)
