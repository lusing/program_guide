# 22 · 错误处理

> 所属部分：第 4 部分 · 与外部世界

> 示例：`examples/22-errors.el`

## 22.1 错误的形状

Emacs 的错误 = **错误符号** + **数据**。比如：

```elisp
(condition-case err (+ 1 "x") (error (princ (format "%S\n" err))))
;; err = (wrong-type-argument number-or-marker-p "x")
```

第一个元素是错误符号（一个符号，可以有「父类」），后面是相关数据。
`error-message-string` 把它转成人读的字符串。

## 22.2 condition-case

```elisp
(condition-case err
    (可能出错的代码)
  (error (处理它，err 是错误对象)))
```

```
2) 捕获 error: (caught "出错了：演示")
```

`error` 是所有「正常错误」的父类，捕获它就等于捕获所有。想拿完整的错误对象，
第一个参数必须是个符号（不能用 `nil`）。

## 22.3 精准捕获

```elisp
(condition-case err
    (+ 1 "x")
  (void-function '没有这个函数)
  (wrong-type-argument '类型不对))
```

```
3) 精准捕获 wrong-type-argument: (caught "Wrong type argument: number-or-marker-p, \"不是数字\"")
   不匹配的 handler 会继续往上抛: 外层接住了
```

handler 按**书写顺序**匹配，第一个匹配的执行。都不匹配就继续往外抛。
**只捕获你知道怎么处理的错误** —— 一个全捕获的 `(error ...)` 会把真正的 bug 一起吃掉。

## 22.4 【坑】condition-case nil 会丢掉错误详情

```elisp
(condition-case nil
    (foo)
  (error '出错了))       ; ← 拿不到错误消息
```

```
4) 【坑】(condition-case nil ...) 用 nil 当变量时会忽略错误详情
```

第一个参数写 `nil` 时无法访问错误对象。只想「知道出错了」还行，但**日志和调试**时一定要用符号。

## 22.5 ignore-errors

```elisp
(ignore-errors (/ 1 0))    ; → nil
(ignore-errors (* 1 2))    ; → 6
```

```
5) ignore-errors 正常: 3，出错: nil
```

比 `condition-case` 简洁，但**把错误彻底吞掉了**。适合「这个操作失败也没关系」的场景
（比如读一个可能不存在的文件、删一个可能不存在的 buffer）。

## 22.6 unwind-protect：清理

```elisp
(unwind-protect
    (干活)
  (清理))                  ; 无论正常返回还是出错，都会执行
```

```
6) ("干活" "清理")
```

这是**资源清理的唯一正确方式**。`unwind-protect` 保证：

- body 正常结束 → 执行清理；
- body 报错并往外抛 → 执行清理后继续抛；
- body 里 `throw` 出去 → 执行清理。

所以「临时改全局变量 / 挂 advice / 建临时文件 / 起进程」的清理一律放这儿。

## 22.7 自定义错误类型

```elisp
(define-error 'demo-timeout "操作超时" 'error)
(signal 'demo-timeout (list "连接超时" 30))
```

```
7) 自定义错误: (caught "超时: \"连接超时\", 30")
```

`define-error` 的第 3 个参数是**父错误符号**（这里是 `error`）。所以：

- 用户可以用 `(condition-case e ... (demo-timeout ...))` 精准捕获；
- 也可以用 `(error ...)` 兜住它；
- `C-h f`-式的帮助里会显示「超时: ...」这样的消息。

**给自己的扩展定义错误类型是好习惯** —— 调用方就能区分「你的扩展超时了」和「Emacs 抛了别的错」。

## 22.8 user-error

```elisp
(user-error "请先选中一段文本")
```

```
8) user-error: "请先选中一段文本"
```

`user-error` 专门用于「用户操作不当」的情况。它的特别之处是**不会进入 debugger** ——
即使用户开了 `debug-on-error`，`user-error` 也不弹 backtrace。所以：

- 「你没选中文本」「这个文件不是你的格式」→ `user-error`；
- 「内部状态坏了」→ `error`。

这样开发者调试自己的代码时不会被用户的误操作干扰。

## 22.9 catch / throw：提前退出

```elisp
(catch 'done
  (dolist (x items)
    (when (found-p x) (throw 'done x)))
  'not-found)
```

```
9) catch/throw: "在 3 处跳出"
10) 没有 throw 时: 3
```

Elisp 没有 `return` / `break`。**`catch` + `throw` 是唯一的「提前跳出去」手段**，
在深层嵌套里特别有用。

如果执行到 `catch` 末尾都没有 `throw`，`catch` 返回 body 最后一个表达式的值。

```elisp
(condition-case e
    (throw 'no-such-tag 1)
  (error (error-message-string e)))
```

```
    没有 catch 时: "No catch for tag: no-such-tag, 1"
```

`throw` 找不到对应的 `catch` 会 signal 一个 `no-catch` 错误。

> 【坑】字节编译器**不认识** `no-catch` 这个错误符号，写 `(condition-case e (throw ...) (no-catch ...))`
> 会得到 "reference to free variable" 之类的警告。用 `(error ...)` 兜住即可。

## 22.10 断言

```elisp
(cl-assert (= 1 1) nil "不该失败")        ; 通过
(cl-assert (= 1 2) nil "断言失败")        ; 报错
```

```
11) cl-assert 通过: "ok"
    cl-assert 失败: 断言失败
```

`cl-assert` 用于「这里一定为真」的检查。

> 【坑】**`cl-assert` 在字节编译时如果 `debug` 是关的，某些情况下会被优化掉。**
> 所以不要用 `cl-assert` 做「必须有副作用」的检查 —— 要保证执行就用
> `(unless cond (error ...))`。

## 22.11 调试开关

```
12) 开发期建议 M-x toggle-debug-on-error
```

| 开关 | 作用 |
|---|---|
| `toggle-debug-on-error` | 未捕获的错误弹 backtrace |
| `debug-on-message` | 匹配某个正则的 message 时弹 |
| `debug-on-quit` | `C-g` 时弹 |

开发时打开 `toggle-debug-on-error`，能立刻看到出错位置和完整调用栈 ——
这比在代码里到处插 `princ` 高效得多。

---

上一章：[21 · 定时器](21-timers.md)　｜　下一章：[23 · 宏](23-macros.md)　｜　返回：[Emacs 扩展开发指南](README.md)
