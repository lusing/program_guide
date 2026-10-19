# 00 · 先跑起来：环境、运行方式与验证标准

## 0.1 batch 模式：扩展能自动化测试的前提

Emacs 有两种工作方式。交互模式下它是编辑器；`--batch` 模式下它是一个**纯粹的 Lisp 解释器** ——
不读配置文件、不开窗口、跑完就退出：

```bash
emacs -Q --batch -l examples/01-hello.el
```

其中：

- `-Q` 等价于 `-q --no-site-file --no-splash`，即「不加载 `~/.emacs.d/init.el`」。
  写扩展时**永远**加它，否则你的输出会被用户的配置污染，问题变得不可复现。
- `--batch` 关掉交互界面，并在最后自动退出。
- `-l file` 加载文件；也可以用 `--eval '(表达式)'` 直接跑一段代码。

这套组合是整个扩展开发流程的地基：它让「运行一个扩展」变成一条可以在 CI 里跑的普通命令。

## 0.2 最重要的一条：输出往哪去

这是本指南的第一个、也是最影响写代码方式的事实，值得单独一节。Emacs 里有两个看起来都能「输出」的函数：

| 函数 | batch 模式下写到哪里 |
|---|---|
| `princ` | **stdout** |
| `message` | **stderr** |

实测：

```bash
$ emacs -Q --batch --eval '(message "MSG via message")' 2>/dev/null
$ emacs -Q --batch --eval '(princ "PRINC via princ\n")' 2>/dev/null
PRINC via princ
```

`message` 那一行第一个命令什么也没打印 —— 因为它的内容全在 stderr 里。

为什么会这样？因为 `message` 在交互模式下要把文字送进 **echo area**，那是 UI 的一部分而不是程序输出，
所以它走错误流。`princ` 才是「往标准输出写」。

**这条事实直接决定了示例怎么写**：如果示例里用了 `message` 来打印结果，那么在「stderr 必须为空」
这条判定下它就会失败。所以本仓库所有示例统一用：

```elisp
(princ (format "格式串 %d / %S\n" 一个整数 一个对象))
```

`princ` 原样输出不换行不加引号，所以换行要自己写 `\n`，所有格式化交给 `format`。

## 0.3 四个判定标准

`run-all.sh`（macOS/Linux）和 `build.ps1`（Windows）对每个示例做**三步**检查，缺一不可：

1. **字节编译**：`byte-compile-file` 退出码为 0，且 stderr 为空。
2. **加载运行**：退出码为 0。
3. **输出三条**：
   - stderr 为空；
   - stdout 里没有多余控制字符（0..31，TAB/LF/CR 除外）；
   - stdout 里有结束标记 `==== NN 结束 ====`（NN 与文件名前缀一致）。

### 为什么「stderr 为空」是认真的一条

因为**字节编译的警告也走 stderr，而退出码仍然是 0**。实测：

```elisp
;;; warn.el
;;; -*- lexical-binding: t; -*-
(defun demo-fn (x)
  (if (eq x t) 1 2)
  undefined-var-here)
```

```bash
$ emacs -Q --batch --eval '(byte-compile-file "warn.el")' 2>/dev/null
   # ← stdout 是空的，什么警告都没有
$ echo $?
0

$ emacs -Q --batch --eval '(byte-compile-file "warn.el")' 2>&1 1>/dev/null
warn.el:4:11: Warning: reference to free variable 'undefined-var-here'
warn.el:1:1: Warning: Unused lexical argument 'x'
```

于是「stderr 为空」这条规则的实际含义是：**零警告**。它把「能跑」提升成了「干净」。
本指南里那些 `【坑】` 标注的段落，绝大多数就是这条规则逼出来的 —— 写出来会被编译器抓住的东西。

### 为什么还要查控制字符

因为 `%S` 打印某些对象时会**把原始字节写进输出**。实测两个真实例子：

```bash
$ emacs -Q --batch --eval '(princ (format "%S" (kbd "C-c x")))' | cat -v
"^Cx"                      # 这里的 ^C 就是原始的 0x03 字节
```

```elisp
;; advice-member-p 返回的不是 t，而是整个 advice 对象（内含字节码）——
;; 直接 %S 打印它就会把裸控制字节写进输出，这就是第 19 章那条坑的由来
```

这类输出扔进终端会把光标搞乱，重定向到文件后 `grep` 也可能崩。所以判定脚本会扫一遍字节流，
发现 TAB/LF/CR 之外的控制字符就报失败。规避方法很简单：要么用 `key-description`/`prin1-to-string`
这类「给人看」的转换函数，要么把布尔转换掉（`(and x t)`）。

### 结束标记

每个示例最后一行固定是：

```elisp
(princ "==== 01 结束 ====\n")
```

它的作用是兜住「代码被静默截断」这种情况 —— 比如某个 `(error ...)` 让 Emacs 提前退出、
或者某段 `condition-case` 把整块吞掉了。只要能跑到底，这行就一定在。

## 0.4 交互式调试与 batch 验证的分工

别因为 batch 能自动跑就只用 batch。实际开发节奏是：

| 场景 | 用什么 |
|---|---|
| 想快速看一个表达式的结果 | 在 `*scratch*` 里写、`C-j` 求值 |
| 想知道某个函数怎么用 | `C-h f`；变量用 `C-h v` |
| 想看当前 buffer 里所有 keybinding | `C-h b`；某个前缀下用 `C-h` |
| 想看某个 face 长什么样 | `M-x list-faces-display` |
| 排查为什么出错 | `M-x toggle-debug-on-error` 打开再复现 |
| **回归验证** | `./run-all.sh` |

`M-x toggle-debug-on-error` 值得一提：打开之后任何未捕获的错误都会弹出带完整调用栈的 backtrace，
比在代码里到处插 `princ` 有效得多（见第 22 章）。

## 0.5 示例文件的统一节拍

`examples/` 下每个文件都长这样，你在自己写示例时也可以照这个模板：

```elisp
;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 07 - 列表与关联结构
;;;   点对、共享结构、破坏性操作这些容易出错的点
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "07-lists.el")'
;;; 运行：emacs -Q --batch -l 07-lists.el
;;; ============================================================

;;; 1) 第一节……
;;; 2) 第二节……
...

(princ "==== 07 结束 ====\n")
```

两处约定要注意：

- 第一行 **`;;; -*- lexical-binding: t; -*-` 不能省**。它开启词法作用域，是 2026 年写 Elisp 的默认选择。
  没有它就会退回动态作用域，闭包和 `let` 的语义会完全不同（第 3 章会详细讲这个区别）。
- 分节用 `;;; 1) 2) 3)`，与正文的讲解编号对应，方便对着指南读代码。

---

上一章：（无上一章）　｜　下一章：[01 · 第一个程序：输出与 quote](01-hello.md)　｜　返回：[Emacs 扩展开发指南](README.md)
