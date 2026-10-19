# 24 · 模块、加载与打包

> 所属部分：第 5 部分 · 工程化

> 示例：`examples/24-packages.el`

Elisp 没有 `import`，它的「模块」是**特性符号（feature）**：一个文件末尾写 `(provide 'foo)` 表示「我提供了 foo」，别的文件写 `(require 'foo)` 表示「我需要 foo」。本章把这套机制、它的加载时机陷阱，以及打包规范一次讲清。

本示例会在临时目录里**真的造两个模块文件**再 `require` 它们——所以「要 require 的文件得等运行时才存在」。这不是偷懒，它逼出了真实项目里天天遇到的两条约束。

## 24.1 feature：Elisp 的「模块」

```elisp
;; Elisp 的「模块」单位是 feature（特性），用符号表示。
;; 文件末尾写 (provide 'xxx) 声明「我提供了 xxx」；
;; 别的文件写 (require 'xxx) 表示「我需要 xxx，没有就报错」。
;; features 全局变量里装着当前已加载的全部 feature。
(princ (format "1) 'seq 已加载吗: %S，'cl-lib 呢: %S\n"
               (featurep 'seq) (featurep 'cl-lib)))
```

```text
1) 'seq 已加载吗: t，'cl-lib 呢: t
```

`provide` 是文件的**出口声明**，`require` 是入口，`featurep` 是查询。Elisp 用「特性符号」而不是文件名来标识模块——所以 `(require 'demo-math)` 时，Emacs 会去 `load-path` 里找一个「提供了 `demo-math` 的文件」，并按 `demo-math.el` / `demo-math.elc` 的名字去猜。

示例造的第一个模块长这样（`demo-math.el`，写在示例的字符串里）：

```elisp
;;; demo-math.el --- 演示用数学模块 -*- lexical-binding: t; -*-

;;; Commentary:
;;; 一个最小的模块示例：几个函数 + 末尾的 provide。

;;; Code:

(defun demo-add (a b)
  "返回 A + B。"
  (+ a b))

(defun demo-mul (a b)
  "返回 A * B。"
  (* a b))

(provide 'demo-math)

;;; demo-math.el ends here
```

注意最后一行的 `(provide 'demo-math)`——**没有它，`require` 永远找不到这个文件**（Emacs 加载完会检查 feature 对不对得上）。

## 24.2 load-path

```elisp
;; load-path：require 去哪找文件。
;; 它就是个目录列表，require 'demo-math 会依次在这些目录里找
;; demo-math.el（或 .elc），找到第一个就停。
;; 【坑】往里加目录用 add-to-list（去重），别用 push（会重复添加）。
(add-to-list 'load-path demo-lib-dir)
;; 注意这里打印的是「是不是排在最前面」而不是目录名 ——
;; 临时目录名每次运行都不同，写进教程会变成不可复现的输出。
(princ (format "3) 刚加的目录排在最前面: %S\n" (eq (car load-path) demo-lib-dir)))
```

```text
3) 刚加的目录排在最前面: t
```

`add-to-list` 会**去重**且默认插到最前面，所以你的目录会**优先**被搜到（可以用它覆盖内置库，但要谨慎）。用 `push` 则会重复添加同一目录——每多一份，`require` 找不到时就要多查一次。

> 【坑】上例打印的是「是不是排在最前面」这个**布尔值**，而不是目录名。因为 `make-temp-file` 生成的目录名每次都不同（形如 `emacs-lib-XAFc4r`）。**凡是随机/时间相关的东西都别写进示例输出**，否则输出不可复现，测试也就没法比对了。

## 24.3 【重要】顶层 require 在编译期就会执行

这是本章最重要的一条。Elisp 的字节编译器**会求值顶层表单**（它需要知道符号的定义才能生成正确的代码），所以写在顶层的 `(require 'xxx)` 会在**编译期**真的去加载。

示例真的编译了一次——造一个顶层 `require` 不存在模块的文件，再把编译器写往 stderr 的消息截下来：

```elisp
;; 【重要】顶层表单在字节编译时会被求值 —— 所以**顶层 (require 'xxx) 会在
;; 编译期就真的去加载**。文件不存在时编译直接失败（是 Error，不是 Warning）。
;; 下面真编译一次，并把编译器写往 stderr 的消息截下来。
(defvar demo-bad-src (expand-file-name "demo-bad.el" demo-lib-dir))
(with-temp-file demo-bad-src
  (insert ";;; -*- lexical-binding: t; -*-\n"
          "(require 'demo-not-yet)\n"
          "(defun demo-bad-use () (demo-not-yet-add 1 2))\n"
          "(provide 'demo-bad)\n"))
(let ((msgs nil))
  (cl-letf (((symbol-function 'message)
             (lambda (fmt &rest args) (push (apply #'format fmt args) msgs))))
    (byte-compile-file demo-bad-src))
  (princ (format "3b) 编译顶层 require 一个不存在模块的文件:\n%s\n"
                 (replace-regexp-in-string
                  (regexp-quote demo-bad-src) "<临时目录>/demo-bad.el"
                  (string-trim (mapconcat #'identity (nreverse msgs) "\n"))
                  t t))))
```

源文件其实只有四行：

```elisp
;;; -*- lexical-binding: t; -*-
(require 'demo-not-yet)
(defun demo-bad-use () (demo-not-yet-add 1 2))
(provide 'demo-bad)
```

编译它，实测输出：

```text
3b) 编译顶层 require 一个不存在模块的文件:
In toplevel form:
<临时目录>/demo-bad.el:2:11: Error: Cannot open load file: No such file or directory, demo-not-yet
```

注意两点：

1. 它是 **Error**，不是 Warning——编译直接失败；
2. 错误位置 `2:11` 指的是**源文件**里 `(require ...)` 那一行的符号位置，不是你正在编译的主文件。

（示例里用 `cl-letf` 临时改写 `message` 来截获编译器输出，并用 `replace-regexp-in-string` 把临时目录路径换成 `<临时目录>`——这也是「让输出可复现」的标准手法。）

### 怎么办

两条路，示例两条都用了：

- 把 `require` 挪进**函数体**（函数体不会在编译期执行）；
- 用 `declare-function` 告诉编译器「这个函数将来会有」。

示例开头的这两行就是后者：

```elisp
(declare-function demo-add "demo-math")
(declare-function demo-hi  "demo-greet")
```

`declare-function` **只声明、不加载**，它唯一的作用是消掉字节编译器的 "not known to be defined" 警告。

一般包的写法是：**依赖内置库的 `require` 放顶层**（编译期肯定存在），**依赖「运行期才生成的东西」放进函数体**。

## 24.4 require / featurep 的实际效果

```elisp
;; 下面这段整体包在一个函数里 —— 这是本示例最重要的一条经验：
;; **顶层 (require 'xxx) 会被字节编译器在编译期就尝试加载。**
;; 本示例的模块文件是运行时才生成的，编译期根本不存在，
;; 所以顶层 require 会直接让编译失败。
(defun demo-module-demo ()
  "演示 require / load-file / 找不到模块时的处理。"

  ;; 4) require 并调用。成功后 feature 会进 features 列表。
  ;;    【坑】require 找不到文件会**直接报错**（不是返回 nil）。
  ;;    想「有就用、没有就降级」就写 (require 'xxx nil t)，最后的 t = 不报错。
  (require 'demo-math)
  (princ (format "4) require 之后: featurep = %S, demo-add(3,4) = %S\n"
                 (featurep 'demo-math) (demo-add 3 4)))
  ...)
(demo-module-demo)
```

```text
4) require 之后: featurep = t, demo-add(3,4) = 7
```

## 24.5 【坑】require 找不到文件会报错

```elisp
;; 6) 找不到时的两种表现
(princ (format "6) require 不存在的（noerror=t）: %S\n"
               (require 'demo-nope-nope nil t)))
(princ (format "   不加 noerror 就会报错: %S\n"
               (condition-case nil
                   (require 'demo-nope-nope)
                 (error '确实报错了))))
```

```text
6) require 不存在的（noerror=t）: nil
   不加 noerror 就会报错: 确实报错了
```

`require` 的第 3 个参数 `noerror` 为 `t` 时，找不到就返回 `nil` 而不是报错。「有就用、没有就降级」的场景一律写 `(require 'xxx nil t)`。

## 24.6 传递依赖自动处理

示例造的第二个模块 `demo-greet.el` 内部自己 `require` 了 `demo-math`：

```elisp
;;; demo-greet.el --- 演示用问候模块 -*- lexical-binding: t; -*-

;;; Code:

;;; require 要写在「用到该模块之前」。
;;; 但它有代价（要查 load-path、要 load 文件），
;;; 只在「本文件一加载就必须有」的时候才写在顶层。
(require 'demo-math)

(defun demo-hi (n)
  "返回一句问候，数字用 demo-math 算出来。"
  (format "hi, %d" (demo-add n 1)))

(provide 'demo-greet)

;;; demo-greet.el ends here
```

```elisp
;; 5) require 会自动处理传递依赖：require 'demo-greet 时，
;;    它内部那句 (require 'demo-math) 也会被执行（这里已加载过，直接跳过）。
(require 'demo-greet)
(princ (format "5) 依赖被自动处理，demo-hi(10) = %S\n" (demo-hi 10)))
```

```text
5) 依赖被自动处理，demo-hi(10) = "hi, 11"
```

`require` 一个模块时，它内部的 `require` 也会被执行——而且已加载过的直接跳过（靠 `features` 列表判断）。这就是为什么 `provide` / `require` 能构成一个**正确的依赖图**：你只管声明直接依赖，传递依赖自动展开，重复加载自动跳过。

## 24.7 load 与 load-file

```elisp
;; 7) 只加载、不声明 feature：load / load-file。
;;    load       按 load-path 找（给符号名或文件名）
;;    load-file  按绝对路径加载
;;    两者都不管 provide，重复调用会重复执行 —— 调试时好用，生产代码别这么干。
;;    【坑】load 默认会往 stderr 打一行 "Loading xxx.el (source)..."。
;;    关掉它要用 load 的第三个参数 NOMESSAGE（load-file 没有这个参数，
;;    它等价于 (load FILE nil nil t)，一定会打消息）。
(load (expand-file-name "demo-math.el" demo-lib-dir) nil t)
(princ (format "7) 再 load 一次之后 featurep = %S（重复加载不影响 feature）\n"
               (featurep 'demo-math)))
(princ (format "   load-verbose 在 Emacs %d 里还存在吗: %S（已经没有了，别再 let 绑它）\n"
               emacs-major-version (boundp 'load-verbose)))
```

```text
7) 再 load 一次之后 featurep = t（重复加载不影响 feature）
   load-verbose 在 Emacs 31 里还存在吗: nil（已经没有了，别再 let 绑它）
```

区别：

| 函数 | 找文件的方式 | 管不管 `provide` |
|---|---|---|
| `require` | load-path，**按 feature 匹配，已加载则跳过** | 管 |
| `load` | load-path | **不管** |
| `load-file` | 绝对路径 | **不管** |

`load` / `load-file` 每次都会**重新执行**文件内容（调试时正好用得上——改完源码直接 `M-x eval-buffer` 就是同一个道理）。

> 【坑】`load` 的参数顺序是 `(load FILE &optional NOERROR NOMESSAGE NOSUFFIX MUST-SUFFIX)`，**静音是第 3 个参数**（`NOERROR` 是第 2 个）。写成 `(load "x" nil nil t)` 那样静音是错的——第 4 个是 `NOSUFFIX`，意思是「不要自动补 `.el`/`.elc` 后缀」。

> 【坑】网上老教程里常见的「用 `(let ((load-verbose nil)) ...)` 静音」在 Emacs 31 已经**无效**——`load-verbose` 这个变量不存在了，实测 `boundp` 返回 `nil`（上面输出第二行）。`let` 绑一个不存在的变量不报错，所以这个错误特别隐蔽。

## 24.8 autoload：启动快的关键

```elisp
;; autoload：让「用的时候才加载」，是 Emacs 启动快的关键。
;; 写法是在函数定义**前**加一行注释（三个分号 + 井号 + autoload）：
;;
;;      ;;;###autoload
;;      (defun my-fn () ...)
;;
;; 然后由包管理器扫描这些注释，生成 xxx-autoloads.el，
;; 里面全是 (autoload 'my-fn "xxx" nil t) 这样的声明。
;; Emacs 启动时只 load 这个很小的 autoloads 文件，真正的代码等调用时才 load。
;; 【坑】cookie 的写法必须是 ;;;###autoload，多一个空格都扫不到。
(princ "8) autoload cookie 写法见上面注释\n")
```

```text
8) autoload cookie 写法见上面注释
```

示例真的跑了一次 `loaddefs-generate`。先造一个带 cookie 的源文件（它就是示例里的 `demo-pkg-source`）：

```elisp
;;; -*- lexical-binding: t; -*-

;;;###autoload
(defun demo-heavy-command ()
  "一个很重的命令：只有用户调用了才需要它的代码。"
  (interactive)
  (message "重活干完了"))

(provide 'demo-pkg)

;;; demo-pkg.el ends here
```

然后让 `loaddefs-generate` 扫它，并把生成的 autoload 声明读出来：

```elisp
;; cookie 到底生成了什么？真跑一次 loaddefs-generate 给你看。
;; 它会扫源文件中的 ;;;###autoload，把「函数 → 文件」的声明写进 autoloads 文件。
(defvar demo-al-dir (make-temp-file "emacs-al-" t))
(with-temp-file (expand-file-name "demo-pkg.el" demo-al-dir)
  (insert demo-pkg-source))
(require 'loaddefs-gen)
;; loaddefs-generate 会往 stderr 打一行 "GEN xxx-autoloads.el"，
;; 为了不污染本示例的 stderr，这里临时把 message 换成 no-op。
(cl-letf (((symbol-function 'message) #'ignore))
  (loaddefs-generate demo-al-dir (expand-file-name "demo-pkg-autoloads.el" demo-al-dir)))
(princ (format "8b) loaddefs-generate 扫出来的声明: %S\n"
               (with-temp-buffer
                 (insert-file-contents
                  (expand-file-name "demo-pkg-autoloads.el" demo-al-dir))
                 (let (found)
                   (while (re-search-forward "^(autoload " nil t)
                     (goto-char (match-beginning 0))
                     (push (read (current-buffer)) found))
                   (nreverse found)))))
(delete-directory demo-al-dir t)
```

```text
8b) loaddefs-generate 扫出来的声明: ((autoload 'demo-heavy-command "demo-pkg" "一个很重的命令：只有用户调用了才需要它的代码。" t))
```

这个 `(autoload 'demo-heavy-command "demo-pkg" "docstring" t)` 就是全部内容：**只登记「函数名 → 文件名 → 它是个命令」，一行代码都不加载**。最后那个 `t` 表示「这是个 interactive 命令」，所以 `M-x` 里能补全到它。

（示例里顺手演示了一个技巧：`loaddefs-generate` 会往 **stderr** 打一行 `GEN demo-pkg-autoloads.el`，用 `cl-letf` 临时把 `message` 换成 `#'ignore` 就能把它消掉。凡是要保证「stderr 干净」的脚本都可能用得上这一手。）

`;;;###autoload` 这个**注释**会被 `loaddefs-generate`（打包时则是 `package-generate-autoloads`）扫出来，把「函数名 → 文件路径」的映射写进 `xxx-autoloads.el`。这样 Emacs 启动时只登记映射、**不加载**你的文件；只有用户第一次调用那个命令时，才真正加载。

这是让「装了一堆包但启动还是很快」的机制。写包时**所有用户会直接调用的命令都应该加这个标记**。

## 24.9 with-eval-after-load

```elisp
;; with-eval-after-load：等某个 feature 加载完再做某件事。
;; 这是「不改别人源码、但要在它加载后做配置」的标准手段。
(princ "9) with-eval-after-load：\n")
(with-eval-after-load 'demo-math
  (princ "    demo-math 加载完成后执行这句\n"))
```

```text
9) with-eval-after-load：
    demo-math 加载完成后执行这句
```

「等某个 feature 加载完之后再做配置」。这是 `eval-after-load` 的现代形式（后者要求你传一个 form，前者直接吃 body），用户配置里非常常用——避免为了配一个包而提前加载它。

注意它的语义：**如果 feature 已经加载了，body 立刻执行；否则登记下来等以后**。上面这次就是「已经加载」（第 4 节 `require` 过了），所以立刻打印。

## 24.10 package.el

```elisp
;; 包管理：package.el 与 use-package
(princ (format "10) package-user-dir = %S\n" (abbreviate-file-name package-user-dir)))
(princ (format "    package-archives 有 %S 个源: %S\n"
               (length package-archives)
               (mapcar #'car package-archives)))
;; use-package 是一个宏，把 require / 按键绑定 / 配置 / 延迟加载整合在一处：
;;   (use-package magit
;;     :ensure t              ; 没装就装
;;     :bind ("C-x g" . magit-status)
;;     :custom (magit-diff-refine-hunk 'all)
;;     :hook (git-commit-setup . my-setup))
;; 注意 :ensure 需要联网；发布到 MELPA 的包才需要它。
```

```text
10) package-user-dir = "~/.emacs.d/elpa"
    package-archives 有 2 个源: ("gnu" "nongnu")
```

`package.el` 是内置的包管理器：

- `package-user-dir` —— 包装在哪个目录（默认 `~/.emacs.d/elpa`）；
- `package-archives` —— 源列表，默认只有 GNU 官方的两个（`gnu`、`nongnu`）；要装 MELPA 的包得自己加源；
- `package-install` / `package-list-packages` / `package-delete` —— 装、看、删。

相关的还有 `use-package`（第三方，但几乎是事实标准）——它把「安装 + 配置 + 延迟加载」收在一个声明式结构里，示例的注释里给了一个典型写法。

## 24.11 一个 .el 文件的标准头部

```elisp
;; 一个 .el 文件的标准头部（checkdoc / package-lint 都检查这些）：
;;      ;;; foo.el --- 一句话简介 -*- lexical-binding: t; -*-   <- 第一行，必须有
;;      ;; Version: 1.0
;;      ;; Package-Requires: ((emacs "29.1"))
;;      ;; Keywords: convenience
;;      ;; URL: https://...
;;      ;;; Commentary:      <- 说明段
;;      ;; 这里写用法说明
;;      ;;; Code:            <- 代码从这里开始
;;      (provide 'foo)
;;      ;;; foo.el ends here <- 结束标记，必须有
(princ "11) 文件头规范见上面注释，M-x checkdoc 会逐条检查\n")
```

```text
11) 文件头规范见上面注释，M-x checkdoc 会逐条检查
```

展开成真实的文件就是：

```elisp
;;; demo-package.el --- 一句话说明这个包做什么  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Your Name

;; Author: Your Name <you@example.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools convenience

;;; Commentary:

;; 这里是较长的说明：这个包做什么、怎么用、有什么已知限制。

;;; Code:

(defun demo-package-hello ()
  "打个招呼。"
  (interactive)
  (message "hi"))

(provide 'demo-package)

;;; demo-package.el ends here
```

示例把它写成真文件再加载了一次，确认这套头部确实可用：

```elisp
;; 11b) 把上面那套规范写成一个真文件，加载一次确认它确实可用。
(with-temp-file (expand-file-name "demo-package.el" demo-lib-dir)
  (insert demo-package-source))
(princ (format "11b) 按标准头部写的文件能正常加载并 provide: %S\n"
               (progn (load (expand-file-name "demo-package.el" demo-lib-dir) nil t)
                      (featurep 'demo-package))))
```

```text
11b) 按标准头部写的文件能正常加载并 provide: t
```

各行作用：

| 行 | 谁在读 | 干什么 |
|---|---|---|
| `;;; foo.el --- 简介 -*- lexical-binding: t; -*-` | 所有人 | 第一行必须是这个格式；`lexical-binding` 决定用**词法作用域**（新代码一律开） |
| `;; Version:` / `;; Package-Requires:` | 包管理器 | 版本与依赖（`(emacs "27.1")` 表示最低要求） |
| `;; Keywords:` | MELPA / 检索 | 必须是 `finder-known-keywords` 里的标准词 |
| `;;; Commentary:` | 人 | 用法说明 |
| `;;; Code:` | checkdoc | 代码段起点 |
| `(provide 'foo)` | require | 出口声明 |
| `;;; foo.el ends here` | checkdoc / package-lint | 结束标记，必须有 |

`M-x checkdoc` 会逐条检查这些（docstring 格式、第一行是否为完整句子、函数/变量的命名前缀等），`package-lint` 检查打包规范。**提交到 MELPA 之前必须过这两关。**

## 24.12 清理

```elisp
;; 清理：把 feature 摘掉、把 load-path 还原、删掉临时目录。
;; 真实项目里不需要这一步，这里只是不想污染本进程的状态。
(setq features (delq 'demo-math (delq 'demo-greet features)))
(setq load-path (delete demo-lib-dir load-path))
(delete-directory demo-lib-dir t)
(princ (format "12) 清理完成，临时目录还在吗: %S，demo-math 还是 feature 吗: %S\n"
               (file-exists-p demo-lib-dir) (featurep 'demo-math)))
```

```text
12) 清理完成，临时目录还在吗: nil，demo-math 还是 feature 吗: nil
```

`(unload-feature 'demo-math)` 能把一个 feature 摘掉（它会撤销 `provide` 并恢复被重新定义的函数），写测试时很有用。上面用的是更直接的方法：从 `features` 里 `delq` 掉符号。

## 24.13 坑位清单

1. 顶层 `(require 'xxx)` 依赖一个编译期还不存在的文件 —— 编译直接 Error 失败；挪进函数体。
2. 挪进函数体后编译器报 "not known to be defined" —— 用 `declare-function` 补声明。
3. 以为 `require` 找不到会返回 `nil` —— 它**报错**；要降级写 `(require 'x nil t)`。
4. 文件末尾忘写 `(provide ...)` —— `require` 永远找不到它。
5. feature 名和文件名对不上 —— `provide 'foo` 必须放在 `foo.el` 里，否则 `require` 猜不到文件名。
6. 用 `push` 往 `load-path` 加目录 —— 会重复；用 `add-to-list`。
7. 把 `load` 的第 4 个参数当静音开关 —— 静音是第 3 个（`NOMESSAGE`）。
8. 用 `(let ((load-verbose nil)) ...)` 静音 —— Emacs 31 里这个变量已经不存在，`boundp` 为 `nil`。
9. autoload cookie 写成 `;;;### autoload` 或多一个空格 —— 扫不到，你的命令就不会被登记。
10. 用 `load` / `load-file` 做正式的依赖管理 —— 它们不管 `provide`，每次都重新执行，也会重复定义函数。
11. 把随机目录名/时间戳写进示例输出 —— 输出不可复现，测试没法比对；打印布尔性质或用占位符替换。
12. 忘了文件末尾的 `;;; foo.el ends here` —— `checkdoc` / `package-lint` 会拦。

---

上一章：[23 · 宏](23-macros.md)　｜　下一章：[25 · 测试](25-tests.md)　｜　返回：[Emacs 扩展开发指南](README.md)
