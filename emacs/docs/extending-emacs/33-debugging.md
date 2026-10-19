# 33 · 调试：debug-on-entry、edebug 与 batch 下的排查

> 所属部分：第 9 部分 · 跟随 eintr：调试与收尾项目

> 示例：`examples/33-debugging.el`

代码写完了，它**不工作**。这时候你需要的不再是「怎么处理错误」（那是 [22 · 错误处理](22-errors.md) 讲的事），而是「**错误到底在哪、当时的值是什么**」。第 22 章是一张速查表：它告诉你 `condition-case`、`unwind-protect`、`define-error` 各自怎么用；本章是一篇**教程**，它要把这些概念用**实测数据**摆在你面前，再带你走进 Emacs 真正的调试工具——`debug-on-entry`、`backtrace-frame`、`edebug`。

eintr 用一整章（第 17 章 Debugging）讲这件事：`debug-on-entry`、`debug-on-quit`、`debug` 函数、`edebug`。本章在 Emacs 31.1 下把这一章重写一遍，把「实测可复现」放在第一位——**每个结论都能在示例里看到对应的输出**。而且本章有个特殊约束：示例要在 `--batch`（无界面）下跑，所以我们会想办法**在没有人的情况下，把只有人才能看的调试现场「录」下来**。

## 33.1 先把「错误现场」看成一坨数据

调试的第一步，是别把错误当成一句人话，而把它当成**一个数据结构**。Emacs 的错误对象永远是：

```
(错误符号 . 附加数据)     ; 更准确地说是个列表：(错误符号 数据1 数据2 ...)
```

`condition-case` 的第一个参数接到的就是它。示例第 1 节准备了四个「一调用就出错」的小函数（叫做 **thunk**，即「零参数的延时执行块」），逐个触发，把错误对象和它「变成的那句话」并排打印：

```elisp
(dolist (thunk (list (cons "显式抛出" (lambda () (error "boom")))
                     (cons "类型不符" (lambda () (car 5)))
                     (cons "除零"     (lambda () (/ 1 0)))
                     (cons "主动 signal" (lambda () (signal 'wrong-number-of-arguments '(+ 1))))))
  (condition-case err
      (funcall (cdr thunk))
    (error (princ (format "%-10s 错误对象=%-38S 变成一句话=%S\n"
                          (car thunk) err (error-message-string err))))))
```

这里有两个小而重要的技巧：

- **用 `cons` 把「名字 . 函数」配对**，再 `dolist` 遍历。`(car thunk)` 是名字，`(cdr thunk)` 是那个 lambda。`funcall` 负责真正调用它（[04 · 函数](04-functions.md) 讲过 `funcall` 与 `apply`）。这样「四件事」被写成了「一整张表」，而不是四份重复的 `condition-case`。
- **`(error …)` 作为唯一处理器**：`error` 是所有普通错误的祖先，一句就能兜住这四种。记住：这里只是**观察**错误，不是为了「处理」它——`condition-case` 在调试时最常见的用法，恰恰是「把它接住、看清它长什么样」。

输出：

```text
== 1) 错误对象的数据形状 ==
错误对象 = (错误符号 . 附加数据)

显式抛出   错误对象=(error "boom")                         变成一句话="boom"
类型不符   错误对象=(wrong-type-argument listp 5)          变成一句话="Wrong type argument: listp, 5"
除零       错误对象=(arith-error)                          变成一句话="Arithmetic error"
主动 signal 错误对象=(wrong-number-of-arguments + 1)        变成一句话="Wrong number of arguments: +, 1"
```

一行一行读：

- `(error "boom")` —— 你用 `(error "…")` 抛出的错误，符号就是 `error`，数据里装着那句原文。
- `(wrong-type-argument listp 5)` —— 这是**最有用的一种**。`car 5` 里，`car` 要一个列表却拿到了 `5`，于是符号是 `wrong-type-argument`，数据是 `(listp 5)`：`listp` 是「没通过的那个谓词」，`5` 是「实际的坏值」。**看到 `wrong-type-argument`，数据里第 1 个元素告诉你「它期望什么」，第 2 个元素告诉你「实际给了什么」**——这一条能省下你大量时间。
- `(arith-error)` —— 除零。**注意它没有附加数据**，符号后面空着。
- `(wrong-number-of-arguments + 1)` —— 实例里我们主动 `(signal 'wrong-number-of-arguments '(+ 1))`。这里引出**抛错的两个层次**：`(error "…")` 是「语法糖」，它内部其实调用的是更底层的 `signal`。`error` 的 docstring 就写着它会「把 ARGS 交给 `format-message`」拼成消息。

而 `(error-message-string err)` 负责把整个对象压成一句话。它的 docstring（31.1 真实文档）说：

```text
Convert an error value (ERROR-SYMBOL . DATA) to an error message.
```

**「数据」变成「人话」的规则是：把符号名里的连字符换成空格、首字母大写，再把你给的数据依 `format` 规则拼上去**。所以 `wrong-type-argument listp 5` 变成 `Wrong type argument: listp, 5`，`arith-error` 变成 `Arithmetic error`。

> **和 22 章的分工**：[22.1](22-errors.md) 用一句 `(+ 1 "x")` 演示「错误的形状」；这里则把**四种错误并排放**，让你看清「符号不同、数据长度不同」。22 章教你**写**错误处理，本章教你**看**错误现场。

## 33.2 自定义错误符号必须先用 `define-error` 登记

第 22.7 节说过要给自己的扩展定义错误类型。示例第 2 节把这件事讲透——**关键是 `error-conditions` 这个属性**。

如果你直接 `(signal 'my-config-error '("坏值"))`，Emacs 会说 `(error "Invalid error symbol" my-config-error)`：它不认识 `my-config-error`。必须先登记：

```elisp
(define-error 'my-config-error "配置文件有误")
```

`define-error` 的 docstring 说明了它的三个参数：

```text
Define NAME as a new error signal.
MESSAGE is a string that will be output to the echo area if such an error
is signaled without being caught by a 'condition-case'.
PARENT is either a signal or a list of signals from which it inherits.
Defaults to 'error'.
```

第三个参数 `PARENT`（父错误）默认就是 `error`。**这个「继承」不是语法糖，而是一个真实存在的列表属性**——`define-error` 会写入符号的 `error-conditions` 属性。示例里用 `get` 把它读出来：

```elisp
(princ (format "登记后 error-conditions = %S（含 error，所以也能被通用处理器接住）\n"
               (get 'my-config-error 'error-conditions)))
```

```text
登记后 error-conditions = (my-config-error error)（含 error，所以也能被通用处理器接住）
```

**读法**：`error-conditions` 是 `(my-config-error error)`。当这个错误被抛出时，`condition-case` 会拿这个列表去和处理器比对——`my-config-error` **和** `error` **都匹配**。所以同一个错误，既能被精确捕获，也能被通用处理器接住：

```elisp
(condition-case err
    (signal 'my-config-error '("缺少 field: name" 42))
  (my-config-error
   (princ (format "精确捕获： 错误对象=%S\n" err))))
(condition-case err
    (signal 'my-config-error '("缺少 field: name" 42))
  (error
   (princ (format "通用捕获： 一句话=%S\n" (error-message-string err)))))
```

```text
精确捕获： 错误对象=(my-config-error "缺少 field: name" 42)
通用捕获： 一句话="配置文件有误: \"缺少 field: name\", 42"
```

注意「一句话」里的 `配置文件有误` 就是你登记时给的 `MESSAGE`，后面跟冒号、再拼上你给的数据 `"缺少 field: name"` 和 `42`。**所以 `define-error` 的第一、二个参数分别决定了「失败的形状」和「默认文案」。**

## 33.3 `condition-case` 的三种用法

第 22 章演示了「精确捕获」和「不匹配就外抛」。示例第 3 节把它们和第三种「**重新抛出**」摆在一起，因为**第三种在调试里最常用**：

```elisp
;; (a) 精确匹配 + 兜底
(princ (format "(a) 精确匹配: %S\n"
               (condition-case _err
                   (signal 'my-config-error '("坏值"))
                 (my-config-error 'handled-specific)
                 (error 'handled-generic))))
```

```text
(a) 精确匹配: handled-specific
```

处理器**从上往下**匹配，第一个匹配的执行。这里 `my-config-error` 排在 `error` 前面，所以精确的那个先赢。**注意变量写成了 `_err`**：这一支用不到错误对象，只用一个占位符就行（下划线开头表示「我故意不用你」；若写成 `err` 而不使用，字节编译器会警告 `Unused lexical variable`）。

```elisp
;; (b) 处理器里没匹配上的错误会继续往外抛
(princ (format "(b) 不匹配则外抛: %S\n"
               (condition-case outer
                   (condition-case nil
                       (car 5)                 ; 抛 wrong-type-argument
                     (arith-error 'never))     ; 接不住，继续抛
                 (error (list 'outer-caught (car outer))))))
```

```text
(b) 不匹配则外抛: (outer-caught wrong-type-argument)
```

里层只想接 `arith-error`，可实际抛出的是 `wrong-type-argument`，一个都不匹配——于是错误**原样穿出**里层，被外层接住。`(car outer)` 取到的是错误**符号**。**这个「接不住的错误自动外抛」是 `condition-case` 最重要的安全性质**：你不必为每个可能错误都写处理器，只写你真正想管的，其余的照常冒泡——这样 bug 不会被悄悄吞掉。

```elisp
;; (c) 重新抛出：包装一句上下文，再抛给上层
(princ (format "(c) 重新抛出: %S\n"
               (condition-case err
                   (condition-case e
                       (/ 1 0)
                     (arith-error
                      ;; 保留原错误符号和数据，只加一句上下文
                      (signal (car e) (cons "在计算平均值时" (cdr e)))))
                 (arith-error (error-message-string err)))))
```

```text
(c) 重新抛出: "Arithmetic error: \"在计算平均值时\""
```

**这是调试里最有价值的一招**。想象一个深层函数因为除零失败了，但错误信息只说 `Arithmetic error`——你根本不知道它在算什么。`rethrow` 的做法是：接住它，**用一个更有意义的数据把它重新抛出去**，让上层（或最终的用户）看到上下文。

关键看 `(signal (car e) (cons "在计算平均值时" (cdr e)))`：

- `(car e)` 是**原来的错误符号**（`arith-error`）——换符号就改变了错误的性质，所以必须保留；
- `(cons "在计算平均值时" (cdr e))` 在**原来的数据前面插一句上下文**，其余数据原样保留；
- 这里涉及 `signal` 的 docstring 里一条容易踩的规则：

  ```text
  When re-signaling an error to propagate it to further handlers,
  DATA has to be omitted and the first argument has to be the whole
  error descriptor.
  ```

  也就是说，**如果你只是想把当前错误原封不动往上抛，应该写 `(signal (car e) (cdr e))`，或者直接用 `(signal e)`**（当整个 `e` 就是错误描述符时）。我们在示例里给了新数据（加了那句话），所以走的是「换数据」的写法。

## 33.4 `unwind-protect` 到底按什么顺序执行

第 22.6 节说「无论正常还是出错，清理都执行」。但**当正体出错时，清理和异常处理器谁先谁后**？这个顺序在写「加锁 / 开临时文件 / 改全局状态」时至关重要。示例第 4 节用一个日志列表把它录下来：

```elisp
(princ (format "顺序 = %S\n"
               (let (log)
                 (condition-case err
                     (unwind-protect
                         (progn
                           (push 'body log)     ; 1) 正体
                           (car "notalist"))    ; 正体里出错
                       (push 'cleanup log))     ; 2) 清理，无论出错与否都跑
                   (error (push (list 'handler (car err)) log))) ; 3) 处理器
                 (nreverse log))))
```

```text
== 4) unwind-protect 的执行顺序 ==
顺序 = (body cleanup (handler wrong-type-argument))
=> 先 body，再 cleanup，最后 handler。清理代码永远有机会收尾。
```

顺序是 **body → cleanup → handler**：

1. `unwind-protect` 先跑正体，`(push 'body log)` 记下 `body`；
2. 正体在 `(car "notalist")` 处出错，`unwind-protect` **先执行清理**（`cleanup`）——它不急着把错误交出去；
3. 清理跑完，错误才继续向外抛，被 `condition-case` 的处理器接住，记下 `(handler wrong-type-argument)`。

**为什么是这个顺序？** 因为清理代码常常要**依赖正体建立起来的状态**（比如关掉正体打开的文件、还原正体改过的变量）。如果让 handler 先跑，handler 里可能已经把这些状态改掉了，清理就会出错。所以 `unwind-protect` 的语义是：**只要离开正体，先无条件收拾干净，再谈错误怎么处理**。

工具本身只有两行 docstring：

```text
Do BODYFORM, protecting with UNWINDFORMS.
If BODYFORM completes normally, its value is returned
after executing the UNWINDFORMS.
If BODYFORM exits nonlocally, the UNWINDFORMS are executed anyway.
```

`(nreverse log)` 那步顺带说明一下：我们用 `push` 往里塞，得到的是**逆序**；`nreverse` 把它翻正，好在输出里按发生顺序读。`push`/`nreverse` 这套「倒着收集、最后翻正」是 Elisp 里**攒列表的标准姿势**——因为往列表**头部**插是 O(1)，往尾部追加是 O(n)。

## 33.5 `backtrace-frame`：把调用栈一帧一帧读出来

出错时最想知道的是「**我是从哪一路调到这里的**」。人看的是 backtrace 缓冲区；程序里读的是 `backtrace-frame`。它的 docstring（31.1）描述得很准：

```text
Return the function and arguments NFRAMES up from current execution point.
If non-nil, BASE should be a function, and NFRAMES counts from its
nearest activation frame.  BASE can also be of the form (OFFSET . FUNCTION)
in which case OFFSET will be added to NFRAMES.
If the frame has not evaluated the arguments yet (or is a special form),
the value is (nil FUNCTION ARG-FORMS...).
If the frame has evaluated its arguments and called its function already,
the value is (t FUNCTION ARG-VALUES...).
A &rest arg is represented as the tail of the list ARG-VALUES.
FUNCTION is whatever was supplied as car of evaluated list,
or a lambda expression for macro calls.
If NFRAMES is more than the number of frames, the value is nil.
```

三个要点：

- **帧号从 0 开始，0 是最内层（最近的一次调用）**，往外递增；
- 超出栈深时返回 `nil`——**这正好可以当「循环到头了」的终止条件**；
- 每个帧是 `(t 函数 实参...)` 或 `(nil 函数 形参...)`，所以**第二个元素**（`(cadr frame)`）就是「正在执行的那个函数」。

示例第 5 节造了三个互相调用的函数 `my-level-1 → my-level-2 → my-call-stack`，在**最内层**把栈上属于本示例的帧收集起来：

```elisp
(defun my-call-stack ()
  "收集当前调用栈里属于本示例的那几帧，从外到内返回。"
  (let ((n 0) acc done)
    (while (not done)
      (let ((frame (backtrace-frame n)))
        (if frame
            (progn
              (when (memq (cadr frame) '(my-level-1 my-level-2 my-call-stack))
                (push (cadr frame) acc))
              (setq n (1+ n)))
          (setq done t))))
    acc))

(defun my-level-2 () (my-call-stack))
(defun my-level-1 () (my-level-2))
```

```text
== 5) 走一遍调用栈 ==
调用栈（外 -> 内）= (my-level-1 my-level-2 my-call-stack)
```

逐点读：

- `(backtrace-frame n)` 从 `n = 0` 开始**逐帧往外**取；取到 `nil` 说明到头了，把 `done` 置真、退出 `while`（[05 · 控制流](05-control-flow.md) 讲的 `while` + 标志位）。
- `(memq (cadr frame) '(my-level-1 my-level-2 my-call-stack))` 是个**过滤器**。为什么要过滤？因为**真实调用栈里还夹着大量不属于我们代码的帧**——顶部有 `while`/`let` 这类宏展开出来的帧、底部有加载器和 `load` 的帧。而且更麻烦的是：**字节编译会把这些宏帧消掉，解释执行时却不会**，于是同一段代码「编译跑」和「解释跑」的栈长得不一样。**过滤成「只留我自己的函数名」，两种跑法就能给出同一个答案**——这正是示例能被 `run-all.sh` 稳定验证的前提。

> 示例里 `push` 得到的顺序天然是「内 → 外」（因为从最内层开始收集），所以输出 `(my-level-1 my-level-2 my-call-stack)` 是**外 → 内**的读法，与 docstring 一致。**这类「push 出来的顺序到底是正还是反」的坑，务必用实测确认**——不要凭直觉。
>
> 另外，`backtrace`（不带 `-frame`）这个函数是**把整条栈打印到 `standard-output`** 的，它**不返回栈**——返回值是 `nil`。想在程序里拿字符串，得写 `(with-output-to-string (backtrace))`。示例没用它，正是因为直接打印会混进加载路径等噪声，不适合做「可验证的输出」。

## 33.6 `debug-on-entry`：让某个函数一被调用就停下

前面几节都是「错误已经发生，怎么观察」。而 `debug-on-entry` 是**埋伏**：你指定一个函数，让它**每次被调用时都进入调试器**，从进入的那一刻起观察参数、单步、看变量。这正是 eintr 第 17 章的第一件工具。

### 它其实是一段 advice

先看 31.1 的真实源码（`debug.el`）：

```elisp
;;;###autoload
(defun debug-on-entry (function)
  "Request FUNCTION to invoke debugger each time it is called.
  ...（docstring 从略）..."
  (interactive
   (let ((fn (function-called-at-point)) val)
     ...))
  (advice-add function :before #'debug--implement-debug-on-entry
              '((depth . -100)))
  function)
```

**关键就一行**：`debug-on-entry` 做的事，是给目标函数**挂一个 `:before` 建议（advice）**，建议体是 `debug--implement-debug-on-entry`。[19 · advice](19-advice.md) 讲过 advice 的机制——`advice-add` 把一个包装函数「贴」在原函数身上，调用原函数时先跑包装函数。所以：

- 它**不修改**函数的定义，可随时撤销；
- 它**保留了函数原有行为**（`:before` 只是先跑一下，不拦截返回值）；
- 那个 `'((depth . -100))` 表示这条 advice **排到最外层**，保证「进入函数的第一件事」就是触发调试。

### 「停下」这件事是谁干的

接着看被挂上去的那个函数：

```elisp
(defun debug--implement-debug-on-entry (&rest _ignore)
  "Conditionally call the debugger.
A call to this function is inserted by `debug-on-entry' to cause
functions to break on entry."
  (if (or inhibit-debug-on-entry debugger-jumping-flag)
      nil
    (let ((inhibit-debug-on-entry t))
      (funcall debugger 'debug :backtrace-base
               ;; An offset of 1 because we need to skip the advice
               ;; OClosure that called us.
               '(1 . debug--implement-debug-on-entry)))))
```

`(&rest _ignore)` 表示「函数自己的实参我不关心」。然后是：

- **两个「闸门」**：只要 `inhibit-debug-on-entry` 或 `debugger-jumping-flag` 非空，就直接返回 `nil`、不打断点。`debugger-jumping-flag` 的文档说得很清楚——「Non-nil means that `debug-on-entry` is disabled」，它是 `debugger-jump`、`debugger-step-through` 用来**临时关掉所有断点**的，免得调试器自己又撞上自己的断点、无限循环。
- **`(funcall debugger 'debug :backtrace-base …)`**：真正「进入调试器」这件事，是把**变量 `debugger` 的值当函数调用**。`debugger` 的文档（31.1）：

  ```text
  Function to call to invoke debugger.
  If due to frame exit, arguments are 'exit' and the value being returning...
  If due to error, arguments are 'error' and a list of arguments to 'signal'.
  If due to 'apply' or 'funcall' entry, one argument, 'lambda'.
  If due to 'eval' entry, one argument, t.
  If the desired entry point of the debugger is higher in the call stack,
  it can be specified with the keyword argument ':backtrace-base', ...
  ```

  **默认值就是那个著名的 `(setq debugger 'debug)`**，于是默认情况下它会调起交互式调试器 `debug`。`'(1 . debug--implement-debug-on-entry)` 是告诉调试器「从我这个函数再往外 1 帧开始显示栈」，这样背板上第一行是**你的函数**，而不是这层 advice 的包装壳。

### 在 `--batch` 下怎么「看到」它被调用

交互式调试器要读你的按键，`--batch` 里跑不了。但我们不需要真的看它弹窗——**只要把 `debugger` 换成一个「桩」（stub）函数，就能录下它「什么时候、带着什么参数」被调用**。这正是「把不可观察的量变成一个可以观察的函数」。

```elisp
(defun my-add (a b) (+ a b))
(defvar my-debug-log nil)

(debug-on-entry 'my-add)
(princ (format "加了断点？ %S\n"
               (not (null (advice-member-p #'debug--implement-debug-on-entry 'my-add)))))
(princ (format "当前设了断点的函数： %S\n" (debug--function-list)))

(let ((debugger (lambda (&rest args) (push args my-debug-log) 'stubbed)))
  (princ (format "照常调用 my-add(3,4)，结果 = %S（函数体照跑）\n" (my-add 3 4))))
(princ (format "debugger 被调用时的实参： %S\n" (car my-debug-log)))

(cancel-debug-on-entry 'my-add)
(princ (format "取消后还有断点？ %S\n"
               (not (null (advice-member-p #'debug--implement-debug-on-entry 'my-add)))))
```

```text
== 6) debug-on-entry 的机制 ==
加了断点？ t
当前设了断点的函数： (my-add)
照常调用 my-add(3,4)，结果 = 7（函数体照跑）
debugger 被调用时的实参： (debug :backtrace-base (1 . debug--implement-debug-on-entry))
取消后还有断点？ nil
```

几个点值得说：

- **`advice-member-p` 用来「查询某个函数身上有没有这条 advice」**。既然断点就是一条 advice，判断「有没有加断点」就等价于「有没有这条 advice」——返回真。取消之后返回 `nil`。
- **`(let ((debugger …)) …)` 是「局部换掉全局变量」**（动态作用域的一种用法，[03 · 变量](03-variables.md)）：在 `let` 体内 `debugger` 变成桩函数，`let` 结束就自动还原。**配合 `unwind-protect`，这正是「临时改全局状态、用完还原」的教科书场景**（本示例范围很小，`let` 足矣）。
- **输出里的实参完全对上了源码**：`(debug :backtrace-base (1 . debug--implement-debug-on-entry))`——第一个 `'debug` 说明「以错误/断点方式进入」，后面是 `:backtrace-base` 和那个 `(1 . …)` 偏移。**你读的源码和机器跑的行为，在此严丝合缝地互相印证。**
- **`(my-add 3 4)` 照样返回 `7`**。因为桩函数只是**记录**、返回 `'stubbed` 就完了；而真正的 `debug` 会用「读取按键→可能单步→继续」的方式返回，效果也是「函数体继续跑」。**断点不断断执行，只断断「暂停观察」。**
- **`debug--function-list` 列出所有设了断点的函数**。打出来是 `(my-add)`——注意它是靠遍历所有符号、逐一 `advice-member-p` 找出来的：

  ```elisp
  (defun debug--function-list ()
    "List of functions currently set for debug on entry."
    (let ((funs '()))
      (mapatoms
       (lambda (s)
         (when (advice-member-p #'debug--implement-debug-on-entry s)
           (push s funs))))
      funs))
  ```

  `mapatoms` 遍历**所有**已存在的符号（obarray），这个遍历顺序是**不确定的**，所以 `(my-add)` 里只有一个元素时看着很稳；真有多个时可别指望顺序。**「遍历全局表 + 判定条件」就是 `debug--function-list` 的全部**——非常简单，却是个很好的例子：**记住「记录状态」比「反查状态」更省事**，Emacs 这里选择了反查，是为了不引入额外的状态变量。
- **`cancel-debug-on-entry`** 则是把这条 advice 摘掉：

  ```elisp
  (defun cancel-debug-on-entry (&optional function)
    "Undo effect of \\[debug-on-entry] on FUNCTION.
  If FUNCTION is nil, cancel `debug-on-entry' for all functions.
  ..."
    (interactive ...)
    (if function
        (progn
          (advice-remove function #'debug--implement-debug-on-entry)
          function)
      (message "Canceling debug-on-entry for all functions")
      (mapcar #'cancel-debug-on-entry (debug--function-list))))
  ```

  传 `nil` 时它**递归地把所有断点都取消**——用 `mapcar` 对自己逐个调用。函数文档里那句「Redefining FUNCTION also cancels it」也值得记：**重新定义函数会让 advice 一起失效**（因为 advice 是挂在旧函数对象上的），调试时反复改函数、断点莫名消失，多半就是这个原因。

## 33.7 `edebug`：交互式单步

`debug-on-entry` 只能「停在入口」，看不了函数**内部**一步步怎么走。要在函数体里**单步**（step）、看每个中间表达式的值，用的是 **edebug**（Emacs 的源码级调试器）。

它的用法（这些操作只能在**有界面的交互环境**里做，`--batch` 里没有按键可读）：

- 把光标放在某个函数定义上，按 **`C-u C-M-x`**（即 `M-x edebug-defun RET`），这个函数就被**插桩**了；
- 之后一调用它，会自动弹出 `*edebug*` 窗口、光标停在第一个表达式上；
- `SPC` 走一步、`n` 下一个表达式、`i` 进入被调用的函数、`q` 退出插桩……`?` 看完整按键表。

`--batch` 里能做的，是确认它**已就绪**：

```elisp
(require 'edebug)
(princ (format "edebug 已加载： edebug-on-error=%S  edebug-on-quit=%S\n"
               edebug-on-error edebug-on-quit))
```

```text
== 7) edebug 的开关 ==
edebug 已加载： edebug-on-error=t  edebug-on-quit=t
在源码里用 C-u C-M-x 插桩，再交互运行即可单步。
```

这两个开关的含义：`edebug-on-error` 为真时，**出错的地方会自动插桩的函数停下来**（进入 edebug 而不是普通 debugger）；`edebug-on-quit` 则在 `C-g`（quit）时停下。默认都是 `t`。

> **一个真实的坑（本机实测）**：`edebug-defun` 需要先知道函数**定义在哪个文件**才能插桩。对于「用 `-l script.el` 直接加载的脚本里定义的函数」，`(symbol-file 'my-add 'defun)` 返回 `nil`，于是插桩会报 `Don't know where 'my-add' is defined`。**结论：想让 edebug 生效，函数得来自一个「能追溯到文件」的库**（比如你 `load` 的 `.el` 文件、或 `require` 进来的包），这也解释了为什么「把代码拆成文件、用 `load`/`provide` 组织」不只是整洁问题，还关系到工具链能否工作。

## 33.8 一张图理清「什么时候用哪个工具」

| 你想知道 | 用什么 | 关键点 |
|---|---|---|
| 这个错误是什么类型、带了什么数据 | `condition-case` + `error-message-string` | 错误 = `(符号 . 数据)`；`wrong-type-argument` 的数据里是「期望值/实际值」 |
| 让错误在冒出时带上上下文 | `signal` + `(cons "上下文" (cdr e))` 重新抛出 | 保留原符号，只换数据；原样上抛用 `(signal e)` |
| 清理代码的执行时机 | `unwind-protect` | 顺序恒为 body → cleanup → handler；清理先于错误处理 |
| 我是从哪一路调过来的 | `backtrace-frame` | 帧号 0 是最内层；超深返回 `nil`；**必须过滤出自己的函数名**才能抵抗宏帧差异 |
| 某个函数一被调用就停下 | `debug-on-entry` / `cancel-debug-on-entry` | 本质是 `:before` advice；`advice-member-p` 可查、`debug--function-list` 可列 |
| 函数内部一步步走 | `edebug`（`C-u C-M-x` + `SPC`/`n`） | 仅交互；函数得能追溯到来源文件才插得进桩 |
| 在交互环境里一键接管未捕获错误 | `M-x toggle-debug-on-error` | 对应变量 `debug-on-error`；`user-error` 不触发（见 [22.8](22-errors.md)） |

还要认识几个「背景变量」，它们在真实排查里随时会碰上：

- **`debug-on-error`**——「出错是否进调试器」。文档里提醒：**被 `condition-case` 捕获的错误不会进**，被 `debug-ignored-errors` 命中的也不进。
- **`debug-ignored-errors`**——一张「不值得进调试器」的清单，元素可以是错误符号，也可以是**匹配错误消息的正则**（[08 · 字符串与正则](08-strings-regexp.md)）。它优先级高于 `debug-on-error`。文档里有条实用建议：想改它的默认值要用 `setq` 整个换掉，**别用 `delq` 去删元素**。
- **`debug-on-quit`**——`C-g` 时进调试器。程序「卡住不响应」时，靠它抓现行。
- **`inhibit-debugger`**——**`--batch` 下常被设为 `t`**，这正是「为什么批处理里的错误直接让进程以非零码退出、而不是弹调试器」的原因。

**把这些串起来，就是一次真实的排查流程**：先在交互环境里 `M-x toggle-debug-on-error`，让错误一冒头就弹 backtrace；顺着 backtrace 找到出错的函数，`C-u C-M-x` 给它插桩，再用 edebug 单步看清是哪一步的哪个值不对；定位到具体函数后，若怀疑「它被调用的时机不对」，就 `debug-on-entry` 停它入口、核对实参；最后用 `condition-case` 的**重新抛出**给错误补上上下文，让下次出错时信息更完整。**调 bug 不是「看代码猜」，而是「让运行时把事实交出来」。**

下一章我们离开「查错」，回到 eintr 的另一条主线：**把你的配置本身当成代码来写**——初始化文件 `init.el` 的结构，以及那个天天在眼前、却少有人会定制的 **mode line**。

上一章：[32 · 词频统计：从 count-words 到一个完整的扩展](32-count-words.md)　｜　下一章：[34 · 初始化文件与 mode line](34-init-mode-line.md)　｜　返回：[Emacs 扩展开发指南](README.md)
