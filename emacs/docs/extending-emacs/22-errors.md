# 22 · 错误处理

> 所属部分：第 4 部分 · 与外部世界

> 示例：`examples/22-errors.el`

Elisp 的错误处理有三件套：`condition-case` 捕获、`unwind-protect` 清理、`catch`/`throw` 提前退出。再加上「自定义错误类型」和 `user-error`，就覆盖了日常扩展开发的全部场景。本章逐个跑一遍实测结果。

## 22.1 错误的形状

Emacs 的错误 = **错误符号** + **数据**。这不是比喻，而是它真的长这样：

```elisp
;; Emacs 的错误由「错误符号（error symbol）」+「数据」组成。
;; (error "格式串" ...) 会 signal 一个 'error；也可以直接 (signal 'wrong-type-argument ...)。
;; 错误信息用 (error-message-string ERR) 取。
(princ (format "1) 错误的形状: %S\n"
               (condition-case e (+ 1 "x") (error e))))
(princ (format "   转成人类可读: %S\n"
               (condition-case e (+ 1 "x") (error (error-message-string e)))))
```

```text
1) 错误的形状: (wrong-type-argument number-or-marker-p "x")
   转成人类可读: "Wrong type argument: number-or-marker-p, \"x\""
```

第一行就是被捕获到的错误对象：一个 **list**，第一个元素是错误符号 `wrong-type-argument`，后面是相关数据（这里告诉你是哪个谓词没通过、那个值是什么）。第二行是 `error-message-string` 把它转成人读的字符串——给用户看的永远是这一行。

常见的错误符号：`wrong-type-argument`、`void-function`、`void-variable`、`args-out-of-range`、`end-of-buffer`、`file-error`、`user-error`。

## 22.2 condition-case

```elisp
;; condition-case 是最常用的捕获结构：
;;      (condition-case VAR
;;          受保护的代码
;;        (错误符号1 处理代码)      ; VAR 绑定到 (符号 . 数据)
;;        (错误符号2 处理代码)
;;        (:success 处理代码))      ; 没出错时执行
(princ (format "2) 捕获 error: %S\n"
               (condition-case e
                   (error "出错了：%s" "演示")
                 (error (list 'caught (error-message-string e))))))
```

```text
2) 捕获 error: (caught "出错了：演示")
```

结构要点：

- 第 1 个参数是**变量名**（不是类型！），出错时它被绑定到错误对象；写 `nil` 表示「不关心详情」（见 22.4）；
- 第 2 个参数是受保护的代码；
- 之后是若干 handler，每个形如 `(错误符号 处理代码...)`。

`error` 是所有「正常错误」的父类，捕获它就等于捕获所有。除了错误符号，还有一个特殊 handler `:success`——它在**没出错**时执行（本例没用到）。

## 22.3 精准捕获

```elisp
;; 只处理特定错误。error 是所有错误的「父类」，
;; 写 (error ...) 会一网打尽；写具体符号才精准。
;; 常见的具体错误符号：wrong-type-argument、void-function、
;; void-variable、args-out-of-range、end-of-buffer、file-error、user-error。
(princ (format "3) 精准捕获 wrong-type-argument: %S\n"
               (condition-case e
                   (+ 1 "不是数字")
                 (wrong-type-argument (list 'caught (error-message-string e))))))
(princ (format "   不匹配的 handler 会继续往上抛: %S\n"
               (condition-case nil
                   (condition-case nil
                       (+ 1 "x")
                     (void-function 'nope))
                 (wrong-type-argument '外层接住了))))
```

```text
3) 精准捕获 wrong-type-argument: (caught "Wrong type argument: number-or-marker-p, \"不是数字\"")
   不匹配的 handler 会继续往上抛: 外层接住了
```

第二段是嵌套的两层：内层只接 `void-function`，实际抛出的是 `wrong-type-argument`，**接不住**，于是继续往外抛，被外层的 `wrong-type-argument` 接住。

handler 按**书写顺序**匹配，第一个匹配的执行。都不匹配就继续往外抛。

**只捕获你知道怎么处理的错误** —— 一个全捕获的 `(error ...)` 会把真正的 bug 一起吃掉，让「内部状态坏了」和「用户没选中文本」变成同一种表现。

## 22.4 【坑】condition-case nil 会丢掉错误详情

```elisp
;; 【坑】(condition-case nil ...) 用 nil 当变量时会**忽略错误详情** ——
;; 你只能知道「出错了」，拿不到消息，也没法判断是哪一类错。
;; 日志/调试时一定要给变量；只在乎成败时写 nil 才合适。
(princ (format "4) 用 nil 只能知道出错了: %S\n"
               (condition-case nil (error "这条消息你拿不到") (error '出错了))))
(princ (format "   给变量就能拿到详情: %S\n"
               (condition-case e (error "这条消息你拿得到") (error (error-message-string e)))))
```

```text
4) 用 nil 只能知道出错了: 出错了
   给变量就能拿到详情: "这条消息你拿得到"
```

同样是「出错」，左边你只拿到自己写的 `'出错了`，右边拿到了完整的消息。所以：

- 只想「知道出错了」→ 写 `nil` 没问题；
- **日志和调试** → 一定要给变量，否则你会面对一堆「某处出错了」却查不出是哪句。

> 【坑】给了变量却**不用**它，字节编译器会警告「unused variable」。要么用上它（哪怕只是 `(princ (format "%S" e))`），要么就干脆写 `nil`。

## 22.5 ignore-errors

```elisp
;; 只关心「出错没出错」时，用 ignore-errors 更简洁：
;; 出错返回 nil，正常返回 body 的值。
(princ (format "5) ignore-errors 正常: %S，出错: %S\n"
               (ignore-errors (+ 1 2))
               (ignore-errors (+ 1 "x"))))
;; 【坑】ignore-errors 会把「返回值恰好是 nil」和「出错」混在一起，
;; 分不清的时候老老实实用 condition-case。
```

```text
5) ignore-errors 正常: 3，出错: nil
```

比 `condition-case` 简洁，但**把错误彻底吞掉了**。适合「这个操作失败也没关系」的场景（读一个可能不存在的文件、删一个可能不存在的 buffer）。

> 【坑】`ignore-errors` 返回 `nil` 有**两种**含义：「出错了」和「正常返回了 nil」。如果 body 本来就可能返回 `nil`（比如 `(ignore-errors (assoc k alist))`），你就分不清了——这种时候回到 `condition-case`。

## 22.6 unwind-protect：清理

```elisp
;; unwind-protect：无论是否出错都执行清理。
;;      (unwind-protect
;;          主体
;;       清理代码...)
;; 典型用途：关文件、删临时文件、移除 advice、恢复全局变量。
(defvar demo-cleanup-log nil)
(defun demo-risky ()
  "演示 unwind-protect。"
  (unwind-protect
      (progn
        (push "干活" demo-cleanup-log)
        (error "中途失败"))
    (push "清理" demo-cleanup-log)))
(princ (format "6) %S\n"
               (progn (ignore-errors (demo-risky))
                      (nreverse demo-cleanup-log))))
```

```text
6) ("干活" "清理")
```

`demo-risky` 的 body 干到一半抛了错，但日志里**两条都在**——`unwind-protect` 的清理段执行了。这是**资源清理的唯一正确方式**：

- body 正常结束 → 执行清理；
- body 报错并往外抛 → 执行清理后继续抛；
- body 里 `throw` 出去 → 执行清理。

所以「临时改全局变量 / 挂 advice / 建临时文件 / 起进程」的清理一律放这儿。注意清理段可以有多句，按顺序全跑。

## 22.7 自定义错误类型

```elisp
;; 自定义错误类型：define-error。第三个参数是「父错误符号」。
;; 有了自己的错误符号，别人就能精准捕获你的错误。
(define-error 'demo-network-error "网络相关错误")
(define-error 'demo-timeout-error "超时" 'demo-network-error)
(princ (format "7) 自定义错误: %S\n"
               (condition-case e
                   (signal 'demo-timeout-error '("连接超时" 30))
                 (demo-network-error (list 'caught (error-message-string e))))))
;; 注意：捕获父类型 demo-network-error 也能接住子类型 demo-timeout-error，
;; 这就是为什么要给错误分类。
```

```text
7) 自定义错误: (caught "超时: \"连接超时\", 30")
```

这里定义了**两层**：`demo-timeout-error` 的父是 `demo-network-error`，后者默认父是 `error`。而捕获时写的是**父类型** `demo-network-error`，照样接住了子类型。这个「按父类型捕获」的继承关系，就是给错误分类的全部价值：

- 调用方可以 `(condition-case e ... (demo-timeout-error ...))` 精准处理超时；
- 也可以只写 `(demo-network-error ...)` 兜住所有网络类问题；
- 更外层还能用 `(error ...)` 一网打尽。

**给自己的扩展定义错误类型是好习惯** —— 调用方就能区分「你的扩展超时了」和「Emacs 抛了别的错」。

## 22.8 user-error

```elisp
;; user-error：给用户看的错误。它**不会**进入 debug（debug-on-error 时也不弹 backtrace），
;; 适合「用户输入不合法」这类预期内的失败。
(princ (format "8) user-error: %S\n"
               (condition-case e
                   (user-error "请先选中一段文本")
                 (user-error (error-message-string e)))))
```

```text
8) user-error: "请先选中一段文本"
```

`user-error` 专门用于「用户操作不当」的情况。它的特别之处是**不会进入 debugger** —— 即使用户开了 `debug-on-error`，`user-error` 也不弹 backtrace。所以：

- 「你没选中文本」「这个文件不是你的格式」→ `user-error`；
- 「内部状态坏了」→ `error`。

这样开发者调试自己的代码时不会被用户的误操作干扰。

## 22.9 catch / throw：提前退出

```elisp
;; catch / throw：非局部退出，是 Elisp 里唯一的「提前 return」手段。
;; throw 指定 tag 和值；catch 返回那个值。
(princ (format "9) catch/throw: %S\n"
               (catch 'found
                 (dolist (x '(1 2 3 4 5))
                   (when (= x 3)
                     (throw 'found (format "在 %d 处跳出" x))))
                 "没找到")))
```

```text
9) catch/throw: "在 3 处跳出"
```

Elisp 没有 `return` / `break`。**`catch` + `throw` 是唯一的「提前跳出去」手段**，在深层嵌套里特别有用——`throw` 可以直接从三层循环里跳到最外层，不用层层判断返回值。

```elisp
;; 【坑】catch 的 tag 如果没被 throw，catch 返回 body 最后一个表达式的值；
;; 而 throw 找不到对应的 catch 会报 no-catch 错误。
(princ (format "10) 没有 throw 时: %S\n"
               (catch 'nobody (progn 1 2 3))))
;; throw 找不到 catch 会 signal 一个 no-catch 错误 —— 内置错误符号，
;; 但字节编译器不认识它（会报 free variable），所以这里用 error 兜住。
(princ (format "    没有 catch 时: %S\n"
               (condition-case e
                   (throw 'no-such-tag 1)
                 (error (error-message-string e)))))
```

```text
10) 没有 throw 时: 3
    没有 catch 时: "No catch for tag: no-such-tag, 1"
```

两个方向都要记住：

- 执行到 `catch` 末尾都没有 `throw` → `catch` 返回 body 最后一个表达式的值（上面是 `3`，来自 `(progn 1 2 3)`）。所以「没找到」这个值要写在 body 末尾，像第 9 段里的 `"没找到"`；
- `throw` 找不到对应的 `catch` → signal 一个 `no-catch` 错误。

> 【坑】字节编译器**不认识** `no-catch` 这个错误符号，写 `(condition-case e (throw ...) (no-catch ...))` 会得到 "reference to free variable" 之类的警告。用 `(error ...)` 兜住即可（上面就是这么做的）。

## 22.10 断言

```elisp
;; 断言：cl-assert（来自 cl-lib）在字节编译且关闭 debug 时会被优化掉，
;; 适合写「内部不变量」；给用户看的校验用 user-error。
(require 'cl-lib)
(princ (format "11) cl-assert 通过: %S\n"
               (progn (cl-assert (= 1 1)) "ok"))
(princ (format "    cl-assert 失败: %S\n"
               (condition-case nil
                   (cl-assert (= 1 2))
                 (error '断言失败))))
```

```text
11) cl-assert 通过: "ok"
    cl-assert 失败: 断言失败
```

`cl-assert` 用于「这里一定为真」的检查。

> 【坑】**`cl-assert` 在字节编译时如果 `debug` 是关的，某些情况下会被优化掉。** 所以不要用 `cl-assert` 做「必须有副作用」的检查 —— 要保证执行就用 `(unless cond (error ...))`。给用户看的校验用 `user-error`，别用 `cl-assert`。

## 22.11 调试开关

```elisp
;; 调试开关：
;;     debug-on-error = t  出错时进入调试器（开发时开）
;;     debug-on-quit  = t  C-g 时进入调试器（排查卡死很有用）
;;     toggle-debug-on-error  M-x 里直接切
;; 【坑】写交互式扩展时，把错误直接抛给用户是很差的体验；
;; 预期内的失败用 user-error，意外失败用 condition-case 兜住并给出提示。
(princ "12) 开发期建议 M-x toggle-debug-on-error\n")
```

```text
12) 开发期建议 M-x toggle-debug-on-error
```

| 开关 | 作用 |
|---|---|
| `toggle-debug-on-error` | 未捕获的错误弹 backtrace |
| `debug-on-message` | 匹配某个正则的 message 时弹 |
| `debug-on-quit` | `C-g` 时弹 |

开发时打开 `toggle-debug-on-error`，能立刻看到出错位置和完整调用栈 —— 这比在代码里到处插 `princ` 高效得多。

最后一条实践建议：**写交互式扩展时，把原始错误直接抛给用户是很差的体验**。预期内的失败用 `user-error`，意外失败用 `condition-case` 兜住并给出人话提示。

## 22.12 坑位清单

1. 把 `condition-case` 的第 1 个参数当类型写 —— 它是**变量名**；写 `nil` 等于放弃错误详情。
2. 无脑写 `(error ...)` 全捕获 —— 把 bug 和用户误操作混成一类，调试时无从下手。
3. 用了 `ignore-errors` 又需要区分「返回 nil」和「出错」—— 它两者都返回 `nil`。
4. 给了捕获变量却不用 —— 字节编译器警告 unused variable。
5. 清理代码写在 body 里而不是 `unwind-protect` —— 出错/`throw` 时不会执行，资源泄漏。
6. 自定义错误不给父符号 —— 分类失效，调用方只能全捕获或逐个列。
7. 用 `error` 报告「用户没选中文本」—— 应该用 `user-error`，别让误操作弹 backtrace。
8. 以为 `catch` 没被 `throw` 时返回 `nil` —— 它返回 body 最后一个表达式的值。
9. 用 `no-catch` 当 handler 符号 —— 编译器不认识它，会报 free variable；用 `(error ...)` 兜。
10. 指望 `cl-assert` 一定执行 —— 字节编译 + 关闭 debug 时它可能被优化掉。

---

上一章：[21 · 定时器](21-timers.md)　｜　下一章：[23 · 宏](23-macros.md)　｜　返回：[Emacs 扩展开发指南](README.md)
