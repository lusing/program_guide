# 13 · 交互式命令

> 所属部分：第 3 部分 · 扩展的接入点
>
> **本部分导读**：前面两部分是「素材」，这一部分讲**怎么挂进 Emacs**。一个扩展能做的事，说到底就是往这几个地方 注册东西：命令（`interactive`）、按键（keymap）、模式（mode）、事件（hook）、选项（`defcustom`）、 以及包装已有函数（advice）。这七章一章一个接入点。

> 示例：`examples/13-interactive.el`

## 13.1 interactive：把函数变成命令

一个普通的 `defun` 不能用 `M-x` 调用。要变成命令，函数体第一句写 `(interactive)`：

```elisp
(defun demo-hello ()
  "打个招呼。"
  (interactive)
  (message "Hello, Emacs!"))
```

```
1) 无参命令：
   是命令吗：t
```

`(interactive)` 的作用是**告诉 Emacs 参数从哪来** —— 从键盘、从 minibuffer 提示、从当前选区。
`commandp` 判断一个函数是不是命令。

## 13.2 参数提示码

`interactive` 的字符串里，每个字符代表一个参数的来源：

| 码 | 参数类型 | 提示什么 |
|---|---|---|
| `s` | 字符串 | 在 minibuffer 里输入 |
| `n` | 数字 | 输入一个数，Emacs 保证是真数字 |
| `p` | 数字 | **前缀参数**（`C-u 5` → 5，没按 → 1） |
| `P` | 原始前缀 | `C-u` → `(4)`，没按 → `nil` |
| `r` | 两个整数 | 选区的起点和终点 |
| `f` / `F` | 文件名 | 已存在 / 可以是新文件 |
| `D` | 目录名 | — |
| `b` | buffer 名 | 已存在的 buffer |
| `d` | 位置 | 一个 point 位置 |
| `m` | mark | 当前 mark |

实测：

```
2) "s" 字符串参数：
    -> 你好, Emacs!
3) "n" 数字参数：
    -> 21 * 2 = 42
5) "r" 选区参数：
    -> 选区 [1, 6) 共 5 个字符
6) "f" 文件参数：
    -> 文件 /tmp 存在: t
```

提示串的写法有约定：**以冒号 + 空格结尾**，比如 `"你的名字: "`。这是 `checkdoc` 会检查的，
也是让提示在读起来自然的关键。

## 13.3 【重点】p 与 P 的区别

这是写命令时最容易搞错的一对：

```
4) "p" / "P" 前缀参数：
    -> p 收到: 1（没按 C-u 时是 1）
    -> p 收到: 4（没按 C-u 时是 1）
    -> P 收到: nil，转成数字是 1
    -> P 收到: (4)，转成数字是 4
```

- **`p`** 给的是一个**数字**，没按前缀参数时是 `1`（不是 nil！）。适合「重复 N 次」这种场景。
- **`P`** 给的是**未经处理的原始值**：没按时是 `nil`，`C-u` 时是 `(4)`，`C-u 5` 时是 `5`。
  适合需要区分「用户到底按没按前缀」。

想让 `P` 也拿到数字，用 `(prefix-numeric-value arg)` 转换。

## 13.4 用代码算参数

参数需要计算时，`interactive` 可以是一个表达式而不是字符串：

```elisp
(defun demo-upcase-region ()
  "把选区转成大写。"
  (interactive)
  (let ((beg (if (use-region-p) (region-beginning) (point-min)))
        (end (if (use-region-p) (region-end) (point-max))))
    (upcase-region beg end)))
```

```
7) 自定义参数计算：
    -> 已转换 11 个字符
```

形式是 `(interactive (list 表达式1 表达式2 ...))`，列表的每个元素依次对应一个参数。

## 13.5 区分「被 M-x 调用」还是「被 Lisp 调用」

```elisp
(defun demo-fn (&optional x)
  (interactive "sX: ")
  (if (called-interactively-p 'interactive)
      (message "人调用的，X = %s" x)
    "被 Lisp 调用"))
```

```
8) interactive-form: (interactive "s你的名字: ")
   普通函数: nil
    -> 被 Lisp 调用，X = abc
```

`called-interactively-p` 在需要「交互时弹提示、程序调用时静默」的场景很有用。
`interactive-form` 则能取出命令的 interactive 声明，元编程时会用到（比如自动生成文档）。

## 13.6 【坑】忘写 interactive

```
10) 没写 interactive 的函数：commandp = nil
```

函数能正常定义、能被别的 Lisp 调用，但 `M-x` 里找不到它，绑到按键上也没反应。
**这是「代码看起来没问题但 M-x 找不到」的头号原因。**

## 13.7 命令的 docstring 有额外规范

因为命令会出现在 `M-x` 的补全列表和 `C-h f` 里，docstring 的**第一行必须是完整的一句话**，
而且要能独立看懂。`checkdoc` 会检查这些。示例：

```elisp
(defun demo-do-a ()
  "命令 A。"
  (interactive))
```

---

上一章：[12 · 文件与目录](12-files.md)　｜　下一章：[14 · keymap 与按键绑定](14-keymaps.md)　｜　返回：[Emacs 扩展开发指南](README.md)
