# 19 · advice：不改源码改行为

> 所属部分：第 3 部分 · 扩展的接入点

> 示例：`examples/19-advice.el`

advice 让你**在不修改函数源码**的情况下改变它的行为。它是「另一个包的行为不合我意」
这种情况下唯一的正规手段。

## 19.1 六种 advice

```elisp
(advice-add #'demo-save :before  #'demo-log-before)
(advice-add #'demo-save :after   #'demo-log-after)
(advice-add #'demo-save :filter-args   #'demo-upcase-key)
(advice-add #'demo-save :filter-return #'demo-add-suffix)
(advice-add #'demo-save :around  #'demo-timing)
(advice-add #'demo-save :override #'demo-override)
```

| 类型 | 作用 | 能改参数 | 能改返回值 |
|---|---|---|---|
| `:before` | 原函数**之前**跑 | 否 | 否 |
| `:after` | 原函数**之后**跑 | 否 | 否 |
| `:filter-args` | 修改**传给**原函数的参数 | **是** | 否 |
| `:filter-return` | 修改原函数的**返回值** | 否 | **是** |
| `:around` | 把原函数**包起来** | **是** | **是** |
| `:override` | **整个替换**掉原函数 | **是** | **是** |

实测一次调用同时挂着 `:before` `:after` `:around` 时：

```elisp
(princ "6) 现在一次调用会依次触发：\n")
(demo-save "f" 6)
```

```
6) 现在一次调用会依次触发：
    [before] 参数 = ("F" 6)
    [after] 参数 = ("F" 6)
    [around] 耗时 0.1 秒，返回值 "saved F=6 [advised]"
```

`:override` 会把其余 advice 全部短路：

```elisp
(defun demo-override (_orig-fun &rest _args)
  "直接返回固定值。"
  "被 override 了")
(advice-add #'demo-save :override #'demo-override)
(princ (format "7) :override 之后: %S（其它 advice 全被短路）\n" (demo-save "g" 7)))
```

```
7) :override 之后: "被 override 了"（其它 advice 全被短路）
```

`:override` 是**最危险**的一个：两个包都 override 同一个函数就会互相打架。能不用就不用，
优先选 `:around`。

## 19.2 :before / :after

```elisp
(defun demo-log-before (&rest args)
  "打印调用参数。"
  (princ (format "    [before] 参数 = %S\n" args)))
(advice-add #'demo-save :before #'demo-log-before)
(princ (format "1) :before 之后调用: %S\n" (demo-save "a" 1)))
```

```
    [before] 参数 = ("a" 1)
1) :before 之后调用: "saved a=1"
```

它们接收的**参数和原函数完全相同**，返回值被忽略（`:before` 的返回值不影响原函数的参数，
`:after` 的返回值也不影响最终结果）。想改东西必须用下面四种。

## 19.3 :filter-args 与 :filter-return

```elisp
(defun demo-upcase-key (args)
  "把第一个参数（key）转成大写。"
  (cons (upcase (car args)) (cdr args)))
(advice-add #'demo-save :filter-args #'demo-upcase-key)
(princ (format "3) 加 :filter-args 后传 \"c\": %S\n" (demo-save "c" 3)))
```

```
    [before] 参数 = ("C" 3)
    [after] 参数 = ("C" 3)
3) 加 :filter-args 后传 "c": "saved C=3"
```

注意输出里 `[before]`/`[after]` 看到的也已经是**改过的大写参数** —— `:filter-args`
作用在原函数的入参上，其它 advice 看到的都是改后的值。

```elisp
(defun demo-add-suffix (result)
  "给返回值加个后缀。"
  (concat result " [advised]"))
(advice-add #'demo-save :filter-return #'demo-add-suffix)
(princ (format "4) 加 :filter-return: %S\n" (demo-save "d" 4)))
```

```
    [before] 参数 = ("D" 4)
    [after] 参数 = ("D" 4)
4) 加 :filter-return: "saved D=4 [advised]"
```

`:filter-args` 的接口很容易写错：它接收的**不是**散开的参数，而是**一个参数列表**，
返回的也必须是参数列表。

## 19.4 :around：最强的一个

```elisp
(defun demo-timing (orig-fun &rest args)
  "统计 ORIG-FUN 的运行时间。"
  (let ((t0 (current-time)))
    (sleep-for 0.1)                       ; 模拟被包住的耗时操作
    (let ((result (apply orig-fun args)))
      (princ (format "    [around] 耗时 %.1f 秒，返回值 %S\n"
                     (float-time (time-subtract (current-time) t0)) result))
      result)))
(advice-add #'demo-save :around #'demo-timing)
(princ (format "5) 加 :around: %S\n" (demo-save "e" 5)))
```

```
    [before] 参数 = ("E" 5)
    [after] 参数 = ("E" 5)
    [around] 耗时 0.1 秒，返回值 "saved E=5 [advised]"
5) 加 :around: "saved E=5 [advised]"
```

`:around` 能做所有事：改参数、改返回值、决定要不要调用原函数、调用几次、包错误处理。
**计时、缓存、重试、包 `condition-case` 都是 `:around` 的活。**

两个要点：

- **第一个参数是原函数**（一个可 `funcall`/`apply` 的对象），后面才是原参数 ——
  顺序写反是最常见的 bug；
- **一定要调用 `orig-fun`**（哪怕条件不满足也要知道自己跳过了它），否则原函数被静默吞掉。

> 计时在 batch 下是微秒级，`%.6f` 打出来的位数每次跑都不一样（0.000023 / 0.000024…），
> 没法写进文档。所以示例里包了一个 100ms 的 `sleep-for`、用一位小数打印 ——
> 这就是「让输出可复现」的常见手法：**把不可控的粒度变粗，或者给被测操作一个已知量级**。

## 19.5 【坑】advice 是全局且看不见的

坦白说 advice 是**有风险**的手段，三条纪律：

1. **优先用 hook / 配置 / 包装函数**。advice 是最后手段 —— 因为它绕过了原作者的所有假设；
2. **一定要能撤掉**。用 `unwind-protect` 包起来（见 19.6），或者在扩展卸载时 `advice-remove`；
3. **具名函数**，不要用 lambda（见 19.7）。

另外，配套提供一个「开关命令」，让用户能一键卸载你的 advice —— 这是社区对用 advice 的包的
基本期待。

调试时如果怀疑某个函数被 advice 了：`C-h f 函数名` 会显示 advice 信息，
`(advice-member-p #'fn #'target)` 判断某个 advice 是否还挂着。

## 19.6 临时 advice 的正规写法

```elisp
(defun demo-temp-suffix (result)
  "临时给返回值加后缀。"
  (concat result " [临时]"))
(unwind-protect
    (progn
      (advice-add #'demo-save :filter-return #'demo-temp-suffix)
      (princ (format "10) 临时 advice: %S\n" (demo-save "i" 9))))
  (advice-remove #'demo-save #'demo-temp-suffix))
(princ (format "   摘掉后: %S，还挂着吗: %S\n"
               (demo-save "j" 10)
               (and (advice-member-p #'demo-temp-suffix #'demo-save) t)))
```

```
10) 临时 advice: "saved i=9 [临时]"
   摘掉后: "saved j=10"，还挂着吗: nil
```

`unwind-protect` 保证**即使中途出错**也会摘掉 advice —— 这是它和「加完再手动摘」的本质区别。

## 19.7 【坑】lambda advice 摘不掉

```elisp
(advice-add #'demo-save :filter-return (lambda (r) (concat r " [幽灵]")))
(advice-remove #'demo-save (lambda (r) (concat r " [幽灵]")))   ; ← 删不掉！
(princ (format "11) lambda advice 摘不掉，调用结果: %S\n" (demo-save "k" 11)))
```

```
11) lambda advice 摘不掉，调用结果: "saved k=11"
   结论：advice 一律用具名函数
```

`advice-remove` 比较的是**函数对象是否 `eq`**，而匿名 lambda 每次求值都是新对象 ——
所以永远删不掉。**advice 一律用具名 `defun`**，这条没有例外。

## 19.8 移除

```elisp
(princ (format "8) demo-log-before 还挂着吗: %S\n"
               (and (advice-member-p #'demo-log-before #'demo-save) t)))
(advice-mapc (lambda (a _) (advice-remove #'demo-save a)) 'demo-save)
(princ (format "   全部移除后: %S，还挂着吗: %S\n"
               (demo-save "h" 8)
               (and (advice-member-p #'demo-log-before #'demo-save) t)))
```

```
8) demo-log-before 还挂着吗: t
   全部移除后: "saved h=8"，还挂着吗: nil
```

没有 `advice-remove-all` 这个函数。要移全部就用 `advice-mapc` 遍历 —— 它把每个 advice
对象交给你的函数，无论是具名的还是匿名的都能删掉。

> 【坑】`advice-member-p` 返回的**不是 `t`**，而是整个 advice 对象（内含字节码）。
> 直接 `%S` 打印会带裸控制字节，触发验证脚本的「控制字符」判定。要么转布尔
> `(and (advice-member-p ...) t)`，要么别打印它。

---

上一章：[18 · 可定制选项 defcustom](18-custom.md)　｜　下一章：[20 · 子进程](20-processes.md)　｜　返回：[Emacs 扩展开发指南](README.md)
