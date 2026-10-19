# 19 · advice：不改源码改行为

> 所属部分：第 3 部分 · 扩展的接入点

> 示例：`examples/19-advice.el`

advice 让你**在不修改函数源码**的情况下改变它的行为。它是「另一个包的行为不合我意」
这种情况下唯一的正规手段。

## 19.1 六种 advice

```elisp
(advice-add 'demo-save :before  #'demo-log-before)
(advice-add 'demo-save :after   #'demo-log-after)
(advice-add 'demo-save :filter-args   #'demo-fix-args)
(advice-add 'demo-save :filter-return #'demo-fix-return)
(advice-add 'demo-save :around  #'demo-around)
(advice-add 'demo-save :override #'demo-override)
```

| 类型 | 作用 | 能改参数 | 能改返回值 |
|---|---|---|---|
| `:before` | 原函数**之前**跑 | 否 | 否 |
| `:after` | 原函数**之后**跑 | 否 | 否 |
| `:filter-args` | 修改**传给**原函数的参数 | **是** | 否 |
| `:filter-return` | 修改原函数的**返回值** | 否 | **是** |
| `:around` | 把原函数**包起来** | **是** | **是** |
| `:override` | **整个替换**掉原函数 | **是** | **是** |

实测一次调用同时挂了 `:before` `:after` `:around` 时：

```
6) 现在一次调用会依次触发：
    [before] 参数 = ("F" 6)
    [after] 参数 = ("F" 6)
    [around] 耗时 0.000021 秒，返回值 "saved F=6 [advised]"
7) :override 之后: "被 override 了"（其它 advice 全被短路）
```

## 19.2 :before / :after

```elisp
(defun demo-log-before (&rest args)
  (princ (format "    [before] 参数 = %S\n" args)))
```

```
    [before] 参数 = ("a" 1)
1) :before 之后调用: "saved a=1"
```

它们接收的**参数和原函数完全相同**，返回值被忽略（`:before` 的返回值不影响原函数的参数，
`:after` 的返回值也不影响最终结果）。想改东西必须用下面四种。

## 19.3 :filter-args 与 :filter-return

```elisp
(defun demo-fix-args (args)
  "注意：接收的是**参数列表**，返回的也必须是参数列表。"
  (list (upcase (car args)) (cadr args)))
```

```
3) 加 :filter-args 后传 "c": "saved C=3"
```

```elisp
(defun demo-fix-return (ret)
  "接收返回值，返回新的返回值。"
  (concat ret " [advised]"))
```

```
4) 加 :filter-return: "saved D=4 [advised]"
```

`:filter-args` 的接口很容易写错：它接收的**不是**散开的参数，而是**一个参数列表**，
返回的也必须是参数列表。

## 19.4 :around：最强的一个

```elisp
(defun demo-around (orig &rest args)
  "第一个参数是原函数（一个可 funcall 的对象）。"
  (let ((t0 (float-time)))
    (prog1 (apply orig args)             ; 一定要调用 orig，否则原函数不跑
      (princ (format "    [around] 耗时 %.6f 秒\n" (- (float-time) t0))))))
```

```
    [around] 耗时 0.000023 秒，返回值 "saved E=5 [advised]"
```

`:around` 能做所有事：改参数、改返回值、决定要不要调用原函数、调用几次、包错误处理。
**计时、缓存、重试、包 `condition-case` 都是 `:around` 的活。**

## 19.5 【坑】advice 是全局且看不见的

```
9) 【坑】advice 是全局的、看不见的改动。三条纪律：
```

坦白说 advice 是**有风险**的手段，三条纪律：

1. **优先用 hook / 配置 / 包装函数**。advice 是最后手段 —— 因为它绕过了原作者的所有假设；
2. **一定要能撤掉**。用 `unwind-protect` 包起来（见 19.6），或者在扩展卸载时 `advice-remove`；
3. **具名函数**，不要用 lambda（见 19.7）。

调试时如果怀疑某个函数被 advice 了：`C-h f 函数名` 会显示 advice 信息，
`(advice-member-p #'fn #'target)` 判断某个 advice 是否还挂着。

## 19.6 临时 advice 的正规写法

```elisp
(let ((orig (symbol-function #'demo-save)))
  (unwind-protect
      (progn
        (advice-add #'demo-save :filter-return #'demo-temp-suffix)
        (demo-use-it))
    (advice-remove #'demo-save #'demo-temp-suffix)))
```

```
10) 临时 advice: "saved i=9 [临时]"
   摘掉后: "saved j=10"，还挂着吗: nil
```

`unwind-protect` 保证**即使中途出错**也会摘掉 advice —— 这是它和「加完再手动摘」的本质区别。

## 19.7 【坑】lambda advice 摘不掉

```
11) lambda advice 摘不掉，调用结果: "saved k=11"
   结论：advice 一律用具名函数
```

```elisp
(advice-add #'demo-save :filter-return (lambda (r) (concat r " [x]")))
(advice-remove #'demo-save (lambda (r) (concat r " [x]")))   ; ← 删不掉！
```

`advice-remove` 比较的是**函数对象是否 `eq`**，而匿名 lambda 每次求值都是新对象 ——
所以永远删不掉。**advice 一律用具名 `defun`**，这条没有例外。

## 19.8 移除

```elisp
(advice-remove 'demo-save #'demo-log-before)      ; 移一个
(advice-mapc (lambda (a _) (advice-remove 'demo-save a)) 'demo-save)  ; 移全部
```

```
8) demo-log-before 还挂着吗: t
   全部移除后: "saved h=8"，还挂着吗: nil
```

没有 `advice-remove-all` 这个函数。要移全部就用 `advice-mapc` 遍历。

> 【坑】`advice-member-p` 返回的**不是 `t`**，而是整个 advice 对象（内含字节码）。
> 直接 `%S` 打印会带裸控制字节，触发验证脚本的「控制字符」判定。要么转布尔
> `(and (advice-member-p ...) t)`，要么别打印它。

---

上一章：[18 · 可定制选项 defcustom](18-custom.md)　｜　下一章：[20 · 子进程](20-processes.md)　｜　返回：[Emacs 扩展开发指南](README.md)
