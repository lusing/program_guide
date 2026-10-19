# 24 · 模块、加载与打包

> 所属部分：第 5 部分 · 工程化

> 示例：`examples/24-packages.el`

## 24.1 feature：Elisp 的「模块」

```elisp
(provide 'demo-math)          ; 声明「这个文件提供了 demo-math」
(require 'demo-math)          ; 「我需要 demo-math」，没有就加载它
(featurep 'demo-math)         ; 已加载吗？
```

```
1) 'seq 已加载吗: t，'cl-lib 呢: t
4) require 之后: featurep = t, demo-add(3,4) = 7
```

`provide` 是文件的**出口声明**，`require` 是入口。Elisp 用「特性符号」而不是文件名来标识模块 ——
所以 `(require 'demo-math)` 时 Emacs 会去 `load-path` 里找「提供 `demo-math` 的文件」，
并按 `demo-math.el` / `demo-math.elc` 的名字去找。

## 24.2 load-path

```elisp
(add-to-list 'load-path "/path/to/your/package")
```

```
3) load-path 现在有 26 个目录，刚加的在最前面: "emacs-lib-tDEnn7"
```

`require` / `load` 会按 `load-path` 的顺序找文件。`add-to-list` 默认插到最前面，
所以你的目录会**优先**被搜到（可以用来覆盖内置的库，谨慎使用）。

## 24.3 【坑】require 找不到文件会报错

```elisp
(require 'demo-nope-nope)          ; → 报错！
(require 'demo-nope-nope nil t)    ; → nil（不报错）
```

```
6) require 不存在的（noerror=t）: nil
   不加 noerror 就会报错: 确实报错了
```

`require` 的第 3 个参数 `noerror` 为 `t` 时，找不到就返回 `nil` 而不是报错。
「有就用、没有就降级」的场景要写 `(require 'xxx nil t)`。

## 24.4 【重要】顶层 require 在编译期就会执行

这是本示例里最重要的一条经验，也是我写这个示例时实际踩到的坑：

```elisp
;; 这样写，如果运行期才生成的模块还不存在，编译就会失败！
(require 'demo-math)

(defun demo-use () (demo-add 3 4))
```

编译时报（实测）：

```
In toplevel form:
demo-package.el:2:11: Error: Cannot open load file: No such file or directory, demo-math
```

因为**顶层表单在字节编译时会被求值**（编译器需要知道符号的定义才能生成正确的代码）。
解决办法有两个：

- 把 `require` 挪进**函数体**里（函数体不会在编译期执行）；
- 或者用 `declare-function` 告诉编译器「这个函数将来会有」：

```elisp
(declare-function demo-add "demo-math" (a b))

(defun demo-use ()
  (require 'demo-math)          ; 挪进函数体，编译期不求值
  (demo-add 3 4))
```

改完之后编译零警告 —— 实测确认。

```
4) 下面这段整体包在一个函数里 —— 这是本示例最重要的一条经验
```

一般包的写法是：**依赖别人（内置库）的 `require` 放顶层**（编译期肯定存在），
**依赖「运行期才生成的东西」放进函数体**。

## 24.5 传递依赖自动处理

```elisp
;; demo-greet.el
(require 'demo-math)
(provide 'demo-greet)
```

```
5) 依赖被自动处理，demo-hi(10) = "hi, 11"
```

`require` 一个模块时，它内部的 `require` 也会被执行 —— 而且已经加载过的直接跳过。
这就是为什么 `provide` / `require` 能构成一个正确的依赖图。

## 24.6 load 与 load-file

```elisp
(load "demo-math")                                  ; 按 load-path 找，可不给扩展名
(load "demo-math" nil nil t)                        ; 第 4 个参数 t = 静默
(load-file "/abs/path/demo-math.el")                ; 按绝对路径加载
```

```
7) load-file 之后 featurep = t（重复加载不影响 feature）
```

区别：

| 函数 | 找文件的方式 | 管不管 `provide` |
|---|---|---|
| `require` | load-path，**按 feature 匹配，已加载则跳过** | 管 |
| `load` | load-path | **不管** |
| `load-file` | 绝对路径 | **不管** |

`load` / `load-file` 每次都会**重新执行**文件内容（调试时正好用得上）。

> 【坑】`load` 默认会往 stderr 打一行 `Loading xxx.el (source)...`。写脚本时要静音，
> 用 `load` 的第 4 个参数（NOMESSAGE）：
> ```elisp
> (load "demo-math" nil nil t)      ; 最后一个 t = 不打印
> ```
> 顺便说一句：老的 `load-verbose` 变量在 Emacs 31 里**已经不存在了**（`boundp` 返回 nil），
> 用 `let` 绑它不会报错但也不起作用。

## 24.7 autoload：启动快的关键

```elisp
;;;###autoload
(defun demo-heavy-command ()
  "..."
  (interactive))
```

```
8) autoload cookie 写法见上面注释
```

`;;;###autoload` 这个**注释**会被 `loaddefs-generate`（打包时则是 `package-generate-autoloads`）
扫出来，把「函数名 → 文件路径」的映射写进 `xxx-autoloads.el`。这样 Emacs 启动时只登记映射、
**不加载**你的文件；只有用户第一次调用那个命令时，才真正加载。

这是让「装了一堆包但启动还是很快」的机制。写包时**所有用户会直接调用的命令都应该加这个标记**。

## 24.8 with-eval-after-load

```elisp
(with-eval-after-load 'demo-math
  (princ "    demo-math 加载完成后执行这句\n"))
```

```
9) with-eval-after-load：
    demo-math 加载完成后执行这句
```

「等某个 feature 加载完之后再做配置」。这是 `eval-after-load` 的现代形式，
用户配置里非常常用（避免为了配一个包而提前加载它）。

## 24.9 package.el

```elisp
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-install 'some-package)
```

```
10) package-user-dir = "~/.emacs.d/elpa"
    package-archives 有 2 个源: ("gnu" "nongnu")
```

`package.el` 是内置的包管理器。相关的还有 `use-package`（第三方，但几乎是事实标准）——
它把「安装 + 配置 + 延迟加载」收在一个声明式结构里。

## 24.10 一个 .el 文件的标准头部

```
11) 文件头规范见上面注释，M-x checkdoc 会逐条检查
```

```elisp
;;; demo-package.el --- 一句话说明这个包做什么  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Your Name

;; Author: Your Name <you@example.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools convenience
;; URL: https://example.com/demo-package

;; This file is not part of GNU Emacs.

;;; Commentary:

;; 这里是较长的说明：这个包做什么、怎么用、有什么已知限制。

;;; Code:

;; ... 你的代码 ...

(provide 'demo-package)
;;; demo-package.el ends here
```

`M-x checkdoc` 会逐条检查这些（docstring 格式、第一行是否为完整句子、
函数/变量的命名前缀等），`package-lint` 检查打包规范。**提交到 MELPA 之前必须过这两关。**

## 24.11 清理

```
12) 清理完成，临时目录还在吗: nil，demo-math 还是 feature 吗: nil
```

`(unload-feature 'demo-math)` 能把一个 feature 摘掉（它会撤销 `provide` 并恢复
被重新定义的函数）。写测试时很有用。

---

上一章：[23 · 宏](23-macros.md)　｜　下一章：[25 · 测试](25-tests.md)　｜　返回：[Emacs 扩展开发指南](README.md)
