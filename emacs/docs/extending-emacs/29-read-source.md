# 29 · 读懂真实函数：三个 buffer 命令的走查

> 所属部分：第 8 部分 · 跟随 eintr：读懂真实代码

> 示例：`examples/29-read-source.el`

前 28 章都是自己写函数。从这一章开始换一种练法：**拿 Emacs 自带的真实源码，逐行读下来**。这是 eintr 后半部分最看重的能力——原书从第 4 章起就带着读者读 `beginning-of-buffer`、`mark-whole-buffer`、`append-to-buffer` 这些真实命令，理由是「读懂别人的代码，比多写十行自己的代码长进更快」。

难点在于：这些函数不在你打开的文件里，而在 Emacs 的安装目录下，而且很多是**压缩过的 `.el.gz`**。所以第一步要先解决「怎么把源码抓出来」，第二步才是「怎么读」。

这一章用三个最简单的 buffer 命令做样本，全部基于 **Emacs 31.1** 的真实源码。读完你会掌握一套可复用的「读源码」流程。

## 29.1 先解决工具：从一个函数名找到它的源码

Emacs 里每个已加载的函数都记着一件事：「我编译自哪个文件」。用 `symbol-file` 就能问出来：

```elisp
;;; ---------- 1) 工具：从一个函数名找到它的源码 ----------
;;; symbol-file 告诉你「这个函数编译自哪个文件」；
;;; 源码通常是同名 .el（本机是压缩过的 .el.gz）。
(defun my-source-file (sym)
  "返回 SYM 的定义所在源码文件的路径；找不到返回 nil。"
  (let* ((compiled (symbol-file sym 'defun))
         (base (and compiled
                    (if (string-match-p "\\.elc\\'" compiled)
                        (substring compiled 0 -1)
                      compiled))))
    (cond ((null base) nil)
          ((file-exists-p base) base)
          ((file-exists-p (concat base ".gz")) (concat base ".gz"))
          (t nil))))
```

这里有三处必须解释的细节，否则在别的机器上会失败：

1. **`(symbol-file sym 'defun)`** 返回的是 **`.elc`**（字节编译产物）的路径，不是 `.el`。真实源码要么和它同目录同名，要么是 `.el.gz`。
2. **`(substring compiled 0 -1)`** 去掉末尾那个 `c`：`simple.elc` → `simple.el`。负下标表示「从末尾数」，`-1` 就是「去掉最后一个字符」（第 8 章的 `substring` 用得上）。
3. **`.el` 不存在就试 `.el.gz`**。这一点在 MacPorts / Homebrew 装的 Emacs 上尤其重要——它们为了省空间，把 Lisp 源码压成了 gzip。

拿到文件路径后，还要把函数定义**那一段文本**抠出来。做法是正则定位 + `forward-sexp` 跳到表达式末尾：

```elisp
(defun my-defun-source (sym)
  "抓出 SYM 的 defun 原文；抓不到返回 nil。"
  (let ((file (my-source-file sym)))
    (when file
      (with-temp-buffer
        ;; jka-compr-verbose 置 nil，读 .el.gz 时不打印「正在解压」的提示
        (let ((jka-compr-verbose nil))
          (insert-file-contents file))
        (goto-char (point-min))
        (when (re-search-forward
               (concat "^(def\\(?:un\\|macro\\|subst\\)[ \t\n]+"
                       (regexp-quote (symbol-name sym)) "[ \t\n]")
               nil t)
          (beginning-of-line)
          (let ((start (point)))
            (condition-case nil
                (forward-sexp)
              (error (goto-char (point-max))))
            (buffer-substring-no-properties start (point))))))))
```

逐点说明：

- **`insert-file-contents` 能自动解压**。只要 `jka-compr` 已加载，插进来的就是解压后的文本，你不用手动 `gunzip`；
- **`(let ((jka-compr-verbose nil)) …)`** 是必须的。默认情况下读 `.el.gz` 会打印一行 `uncompressing simple.el.gz...`，这行字会进 stderr，破坏我们「运行 stderr 必须为空」的标准；
- **正则 `^(def\(?:un\|macro\|subst\)[ \t\n]+NAME[ \t\n]`** 同时覆盖 `defun` / `defmacro` / `defsubst` 三种定义形式；`\(?:…\)` 是非捕获分组，`regexp-quote` 把函数名里的特殊字符转义掉；
- **`forward-sexp` 从表达式头部跳到尾部**——这才是关键。因为一个 `defun` 里可能有嵌套的括号、字符串里还可能带括号，靠数括号是不可靠的，而 `forward-sexp` 懂 Lisp 语法；
- **外面套 `condition-case`**：万一括号不配（源码被截断），至少把整行打印出来，而不是让脚本崩掉。

打印时把「位置」和「源码」一起打出来：

```elisp
(defun my-print-source (sym)
  "打印 SYM 的定义位置和源码。"
  (princ (format "\n----- %S -----\n" sym))
  (princ (format "定义在：%s\n" (or (my-source-file sym) "（找不到）")))
  (let ((src (my-defun-source sym)))
    (if src
        (princ (concat src "\n"))
      (princ "找不到源码原文\n"))))
```

调用它，`beginning-of-buffer` 和 `mark-whole-buffer` 的原文就都出来了：

```elisp
(princ "== 1) 从符号名找到源码 ==\n")
(my-print-source 'beginning-of-buffer)
(my-print-source 'mark-whole-buffer)
```

输出（本机 Emacs 31.1）：

```
== 1) 从符号名找到源码 ==

----- beginning-of-buffer -----
定义在：/opt/local/share/emacs/31.1/lisp/simple.el.gz
(defun beginning-of-buffer (&optional arg)
  "Move point to the beginning of the buffer.
...
```

**这套工具就是接下来几章的眼睛。** 只要把函数名换掉，你就能读 Emacs 里任何一个函数的源码。

> 【坑】不要用 `(find-function 'car)` 之类的交互命令——它们会开新窗口，在 `--batch` 下不工作。我们这套工具全程只依赖 `symbol-file` 和文本操作，批处理里稳定可靠。
>
> 【坑】如果某个函数在 C 里实现（比如 `car`、`goto-char`），`symbol-file` 会返回 `nil` 或一个 `.c` 文件。Lisp 层能读的就是纯 Lisp 写的函数，像 `car` 这种「内置子程序」（显示为 `#<subr car>`）要看 C 源码，超出本章范围。

## 29.2 第一例：`beginning-of-buffer`

这是抓到的 31.1 真实源码（位于 `simple.el`）：

```elisp
(defun beginning-of-buffer (&optional arg)
  "Move point to the beginning of the buffer.
With numeric arg N, put point N/10 of the way from the beginning.
If the buffer is narrowed, this command uses the beginning of the
accessible part of the buffer.

Push mark at previous position, unless either a \\[universal-argument] prefix
is supplied, or Transient Mark mode is enabled and the mark is active."
  (declare (interactive-only "use `(goto-char (point-min))' instead."))
  (interactive "^P")
  (or (consp arg)
      (region-active-p)
      (push-mark))
  (let ((size (- (point-max) (point-min))))
    (goto-char (if (and arg (not (consp arg)))
		   (+ (point-min) 1
		      (/ (* size (prefix-numeric-value arg)) 10))
		 (point-min))))
  (if (and arg (not (consp arg))) (forward-line 1)))
```

一行行读：

**`(interactive "^P")`** —— `^` 表示「如果设了 `shift-select-mode`，本命令会扩展选区」；`P` 是前缀参数的**原始形式**（`nil` / 一个数字 / 一个 `(4)` 这样的列表），不是 `prefix-numeric-value` 转换后的数字。**为什么要原始形式？** 因为下面要靠「是不是列表」来区分「没给参数」和「给了参数」。

**`(declare (interactive-only "use `(goto-char (point-min))' instead."))`** —— 这是 31.x 才广泛使用的一种「声明」：告诉字节编译器「本函数只该被用户交互调用，Lisp 程序里请改用 `goto-char`」。后果是：**你在 Lisp 代码里直接 `(beginning-of-buffer)`，字节编译会发出警告**。我们在示例里用 `with-no-warnings` 明确表示「我知情，别拦我」：

```elisp
(with-no-warnings (beginning-of-buffer))
```

**`(or (consp arg) (region-active-p) (push-mark))`** —— 这是一个「守卫」：只有在「参数不是列表」**且**「选区没激活」时，才执行 `push-mark`（把当前位置压入 mark 环）。

`(consp arg)` 判断的是「参数是不是一个 cons」。当用户按 `M-<` 时不带参数，`arg` 是 `nil`，`consp` 为假；按 `C-u M-<` 时 `arg` 是 `(4)`，`consp` 为真。所以这一行的意思是「**给前缀参数就不 push mark**」。

**核心的三行**：

```elisp
(let ((size (- (point-max) (point-min))))
  (goto-char (if (and arg (not (consp arg)))
		   (+ (point-min) 1 (/ (* size (prefix-numeric-value arg)) 10))
		 (point-min))))
```

- `size` 是缓冲区长度；
- 如果 `arg` 是一个**普通数字**（不是 `(4)` 这种列表）——比如 `M-5 M-<`——就把 point 放到 `point-min + 1 + size*arg/10`，也就是**从开头数 N/10 处**；
- 否则（没参数，或参数是 `C-u` 那种裸列表）就干脆 `(goto-char (point-min))`。

**`(if (and arg (not (consp arg))) (forward-line 1))`** —— 走到 N/10 处后，再**下移一行**，落到行首。

### 动手验证 N/10 语义

光读不够，自己造一个缓冲区跑一遍。造一个 10 行、每行 10 个字符的缓冲区（共 110 个字符）：

```elisp
(defun my-demo-buffer ()
  "造一个 10 行 x 10 列的演示缓冲区。"
  (let ((buf (get-buffer-create " *demo-29*")))
    (with-current-buffer buf
      (erase-buffer)
      (dotimes (_ 10)
        (insert "0123456789\n")))
    buf))

(defun my-line-of (pos)
  "返回 POS 所在的行号（从 1 开始）。"
  (save-excursion
    (goto-char pos)
    (line-number-at-pos)))
```

然后分别在「无参数」和「参数 5」两种情况下调用：

```elisp
(with-current-buffer (my-demo-buffer)
  ;; push-mark 会往 stderr 打印 "Mark set"，这里静音
  (let ((inhibit-message t))
    (goto-char (point-max))
    (with-no-warnings (beginning-of-buffer))
    (princ (format "无参数：point=%S，在第 %S 行（point-min=%S point-max=%S）\n"
                   (point) (my-line-of (point)) (point-min) (point-max)))
    (goto-char (point-max))
    (with-no-warnings (beginning-of-buffer 5))
    (princ (format "参数 5：point=%S，在第 %S 行   <- 走到 5/10 处再下移一行\n"
                   (point) (my-line-of (point))))))
```

输出：

```
== 2) beginning-of-buffer 的 N/10 语义 ==
无参数：point=1，在第 1 行（point-min=1 point-max=111）
参数 5：point=67，在第 7 行   <- 走到 5/10 处再下移一行
```

把数字代进源码里的公式核对：`size = 111 - 1 = 110`，`arg = 5`，于是 `point = 1 + 1 + 110*5/10 = 1 + 1 + 55 = 57`；再 `forward-line 1` 走到下一行，落到 `67`，正好是第 7 行的行首。**源码说的和实际跑的完全对上**，这就叫「读懂」。

> 【坑】`(let ((inhibit-message t)) …)` 不能省。`beginning-of-buffer` 里的 `push-mark` 会发出 `Mark set` 消息，而 `message` 写的是 **stderr**。不静音的话这一节就会破坏「运行 stderr 必须为空」的标准。
>
> 【坑】`with-no-warnings` 包住的调用**不会**触发「interactive-only」的编译警告，但 `push-mark` 的运行时消息照样会发生。编译期的声明（`declare`）和运行期的行为是两码事，别混起来。

## 29.3 第二例：`mark-whole-buffer`

这是 `C-x h` 绑定的命令，31.1 的真实源码：

```elisp
(defun mark-whole-buffer ()
  "Put point at beginning and mark at end of buffer.
Also push mark at point before pushing mark at end of buffer.
If narrowing is in effect, uses only the accessible part of the buffer.
You probably should not use this function in Lisp programs;
it is usually a mistake for a Lisp function to use any subroutine
that uses or sets the mark."
  (declare (interactive-only t))
  (interactive)
  (push-mark)
  (push-mark (point-max) nil t)
  ;; This is really `point-min' in most cases, but if we're in the
  ;; minibuffer, this is at the end of the prompt.
  (goto-char (minibuffer-prompt-end)))
```

四个动作，清楚得像说明书：

1. **`(push-mark)`** —— 先在**当前位置**压一个标记（无参数 → 文中的说法是「also push mark at point」）；
2. **`(push-mark (point-max) nil t)`** —— 再在**末尾**压一个标记，且第三个参数为 `t`，表示「这个标记要**激活**（activate），让整段成为一个可见选区」；
3. **`(goto-char (minibuffer-prompt-end))`** —— 把 point 移到开头。这里用 `minibuffer-prompt-end` 而不是 `point-min`，是为了在 minibuffer 里也能正确工作（minibuffer 的「开头」在提示符之后）。

`(declare (interactive-only t))` 和上一例同理：文档字符串里那句 "You probably should not use this function in Lisp programs" 现在由编译器替你盯着。我们照旧用 `with-no-warnings` 绕过。

### 验证 point 与 mark 各归各位

```elisp
(with-current-buffer (my-demo-buffer)
  (goto-char 30)
  (let ((inhibit-message t))
    (with-no-warnings (mark-whole-buffer))
    (princ (format "point=%S（在开头），mark=%S（在末尾），use-region-p -> %S\n"
                   (point) (mark) (use-region-p)))
    (princ (format "region 里的字符数 = %S\n"
                   (- (mark) (point))))))
```

输出：

```
== 3) mark-whole-buffer ==
point=1（在开头），mark=111（在末尾），use-region-p -> nil
region 里的字符数 = 110
```

`point` 在 1、`mark` 在 111，两者之间的 110 个字符就是整个缓冲区——**这就是「全选」的实现**。注意 `use-region-p` 返回 `nil`：因为 `mark-whole-buffer` 里那个 `(push-mark (point-max) nil t)` 确实激活了 mark，但在 `--batch` 下没有选中高亮的 UI，`use-region-p` 还要求 `transient-mark-mode` 等条件，所以这里是 `nil`——**这正是为什么它会先把 mark 压到末尾**：真正让「mark 生效」的是 mark 本身，而不是 `use-region-p`。

## 29.4 第三例：`append-to-buffer`

把当前缓冲区的一段文本追加到另一个缓冲区。31.1 的真实源码：

```elisp
(defun append-to-buffer (buffer start end)
  "Append to specified BUFFER the text of the region.
...
When calling from a program, give three arguments:
BUFFER (or buffer name), START and END.
START and END specify the portion of the current buffer to be copied."
  (interactive
   (list (read-buffer "Append to buffer: " (other-buffer (current-buffer) t))
	 (region-beginning) (region-end)))
  (let* ((oldbuf (current-buffer))
         (append-to (get-buffer-create buffer))
         (windows (get-buffer-window-list append-to t t))
         point)
    (save-excursion
      (with-current-buffer append-to
        (setq point (point))
        (barf-if-buffer-read-only)
        (insert-buffer-substring oldbuf start end)
        (dolist (window windows)
          (when (= (window-point window) point)
            (set-window-point window (point))))))))
```

这段代码信息量很大，值得逐块拆。

**`interactive` 里的 `(list …)`** —— 这是交互式命令的经典写法：`interactive` 后面跟一个表达式，它的返回值会**替换整个参数列表**。这里返回 `(buffer start end)` 三个值，分别喂给 `buffer`、`start`、`end` 三个参数。

- `(read-buffer "Append to buffer: " (other-buffer (current-buffer) t))` —— 在 minibuffer 里提示用户输缓冲区名；**默认值**是 `(other-buffer (current-buffer) t)`，即「上一个用过的缓冲区」，第二个参数 `t` 表示「排除当前缓冲区」；
- `(region-beginning)` / `(region-end)` —— 取当前选区的起点和终点。所以 `append-to-buffer` 只能对「有选区」的情况交互式使用，这也解释了为什么它适合放在 `mouse-drag` 之类的场景。

**`let*` 里的四个绑定**（注意是 `let*`，后面的绑定能用前面的）：

- `oldbuf` —— 记住**来源**缓冲区；
- `append-to` —— `(get-buffer-create buffer)`，拿到（必要时**新建**）目标缓冲区；
- `windows` —— 目标缓冲区当前显示在哪些窗口里（一个缓冲区可能同时显示在多个窗口）；
- `point` —— 先留空，稍后填。

**`(save-excursion …)`** —— 包住整块，保证结束后「当前缓冲区、point、mark」都还原到进入前的状态。人工操作里这很重要，因为下面要切走。

**`(with-current-buffer append-to …)`** —— 临时把「当前缓冲区」切成目标缓冲区。`save-excursion` + `with-current-buffer` 是一对黄金搭档：前者管「事后还原」，后者管「临时切换」。

目标缓冲区里做的四件事：

1. **`(setq point (point))`** —— 记下切换过去时的插入点（用于最后修窗口光标）；
2. **`(barf-if-buffer-read-only)`** —— 如果目标缓冲区是只读的，立刻报错退出（`barf-if-…` 是 Emacs 的命名习惯：**明确地拒绝**并抛出错误）；
3. **`(insert-buffer-substring oldbuf start end)`** —— **核心动作**：从 `oldbuf` 的 `start..end` 抄一段文本，插到当前（目标）缓冲区的插入点。因为插入点默认在末尾（进入缓冲区时 point 在之前的位置），所以是「追加」；
4. **`(dolist (window windows) …)`** —— 遍历显示着目标缓冲区的每个窗口。如果某个窗口的光标原本停在「我们插入的起点」，就把窗口光标挪到新的末尾，免得用户看到光标「留在原地不动」。

这一段的模式很典型：**取数据 → 切上下文 → 做操作 → 修外围（窗口/光标）**。Emacs 里几乎所有「静默改别的缓冲区」的函数都是这个骨架。

### 验证：追加两次

```elisp
(princ "\n== 4) append-to-buffer ==\n")
(let ((target " *demo-29-target*"))
  (when (get-buffer target) (kill-buffer target))
  (with-temp-buffer
    (insert "alpha beta gamma\n")
    ;; 取前 6 个字符 "alpha " 追加过去
    (append-to-buffer target (point-min) (+ (point-min) 6))
    ;; 再追加一次：因为插入点停在末尾，所以内容会接在后面
    (append-to-buffer target (point-min) (+ (point-min) 5)))
  (princ (format "目标缓冲区内容 = %S\n"
                 (with-current-buffer target (buffer-string))))
  (kill-buffer target))
```

输出：

```
== 4) append-to-buffer ==
目标缓冲区内容 = "alpha alpha"
```

第一次追加 `"alpha "`（`point-min` 起 6 个字符），第二次追加 `"alpha"`（5 个字符）。因为进入目标缓冲区时插入点在**上一次的末尾**，所以第二次接在了后面，而不是覆盖——这就是「append（追加）」而不是「insert（插入到某个位置）」的由来。

> 【坑】缓冲区名以空格开头（如 `" *demo-29-target*"`）是一个约定：**这种缓冲区不显示在缓冲区列表里**，是「内部使用」的。写临时演示缓冲区时沿用这个约定，免得弄乱用户的 `C-x b`。
>
> 【坑】`get-buffer-create` **会新建**缓冲区，所以调用前要检查并清掉旧的（`(when (get-buffer target) (kill-buffer target))`），否则两次运行的结果会叠加。

## 29.5 自己动手：把 `append-to-buffer` 的核心动作写一遍

读完源码，最有效的巩固方式是**把它最核心的那一行拿出来自己写一遍**。`append-to-buffer` 里真正干活的只有三件事：

| 源码里的动作 | 作用 |
|---|---|
| `(get-buffer-create buffer)` | 拿到（必要时新建）目标缓冲区 |
| `(with-current-buffer append-to …)` | 临时把「当前缓冲区」切到目标上 |
| `(insert-buffer-substring oldbuf start end)` | 从来源缓冲区取一段文本插进来 |

自己写一遍：

```elisp
(princ "\n== 5) 手写 append-to-buffer 的核心动作 ==\n")
(let ((target " *demo-29-keys*")
      (src " *demo-29-src*"))
  (dolist (b (list target src))
    (when (get-buffer b) (kill-buffer b)))
  (with-current-buffer (get-buffer-create src)
    (insert "papertrail\n"))
  (with-current-buffer (get-buffer-create target)
    (insert "前缀：")
    ;; 从 src 的第 1 到第 6 个字符取出来（即 "paper"）
    (insert-buffer-substring src 1 6))
  (princ (format "结果 = %S\n"
                 (with-current-buffer target (buffer-string))))
  (kill-buffer target)
  (kill-buffer src))
```

输出：

```
== 5) 手写 append-to-buffer 的核心动作 ==
结果 = "前缀：paper"
```

从 `src` 取第 1 到第 6 个字符（`"paper"`），接到了目标缓冲区的 `"前缀："` 后面。

> 【坑】`insert-buffer-substring` 的 `start` / `end` 是**哪个缓冲区的坐标**？是**来源缓冲区**的。这一点最容易搞错：如果写成 `(insert-buffer-substring (other-buffer) (point-min) 6)`，而当前正处于目标缓冲区里，`(point-min)` 指的就是**目标**的开头，取出来的内容会完全不对。**取谁的内容，就把谁的坐标写清楚**——这是写这类函数时的第一原则。

## 29.6 这套读源码的流程，可以复用到任何函数

把这一章做的事总结成一套动作，换成任何函数名都能用：

1. **定位**：`(symbol-file 'foo 'defun)` 拿到 `.elc` 路径，去尾得 `.el`，不存在再试 `.el.gz`；
2. **抓取**：`insert-file-contents` 自动解压，正则定位 `^(defun foo ` 后 `forward-sexp` 到表达式尾；
3. **通读**：先看 `interactive` 形式（决定这是「给用户的命令」还是「给程序的函数」），再看 `declare`（有没有 `interactive-only` 之类的约束），最后读主体；
4. **验证**：造一个最小缓冲区，真的跑一遍，把源码里的公式和实际输出对上；
5. **重写核心**：把最关键的一两行自己写一遍。

第 30–32 章会一直用这套流程，读越来越大的函数。

## 29.7 小结

| 要素 | 写法 / 结论 |
|---|---|
| 找源码文件 | `(symbol-file sym 'defun)` → `.elc`；去尾试 `.el`，再试 `.el.gz` |
| 读压缩源码 | `jka-compr` 自动解压；`(let ((jka-compr-verbose nil)) …)` 静音 |
| 抠出定义 | 正则 `^(def\(?:un\|macro\|subst\)[ \t\n]+NAME` + `forward-sexp` |
| `interactive "^P"` | `^` 扩展选区，`P` 传原始前缀（`nil` / 数字 / 列表） |
| `(declare (interactive-only …))` | 在 Lisp 里直接调用会触发编译警告；用 `with-no-warnings` 表示知情 |
| `beginning-of-buffer` | 无参数 → 开头；数字参数 N → `point-min + 1 + size*N/10` 再下移一行 |
| `mark-whole-buffer` | `push-mark` + `push-mark (point-max) nil t` + `goto-char (minibuffer-prompt-end)` |
| 静音 `Mark set` | `(let ((inhibit-message t)) …)`——`message` 走 stderr |
| 追加的骨架 | `get-buffer-create` + `save-excursion` + `with-current-buffer` + `insert-buffer-substring` |

下一章读一组更有意思的函数：**kill ring（剪切环）的实现**。`zap-to-char`、`kill-region`、`yank` 这些你天天按的命令，内部是怎么把文本存进环、又从哪里取出来的——全部是真实源码。

上一章：[28 · 递归：让函数调用自己](28-recursion.md)　｜　下一章：[30 · kill ring：剪切与粘贴的实现](30-kill-ring.md)　｜　返回：[Emacs 扩展开发指南](README.md)
