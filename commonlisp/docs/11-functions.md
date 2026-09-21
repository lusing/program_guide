# 11 · 函数：参数模型、多值与闭包工程

> 配套示例：[`examples/11_functions/`](../examples/11_functions/main.lisp)（channel: both）

## 11.1 参数模型的四件套

`defun` 的形参列表可以按顺序摆四段（实测）：

```lisp
(defun opt (a &optional (b :b默认值)) (list a b))
(opt 1)          ; => (1 :B默认值)
(opt 1 2)        ; => (1 2)

(defun rest-only (&rest xs) (list (length xs) xs))
(rest-only)          ; => (0 NIL)
(rest-only 1 2 3)    ; => (3 (1 2 3))

(defun keyed (&key a (b 2) (c 3 c-p)) (list a b (and c-p t)))
(keyed :a 1)             ; => (1 2 NIL)
(keyed :a 1 :c nil)      ; => (1 2 T)     ← 显式传 nil 也算「给过」

(defun aux (a &aux (b (* a 2))) (list a b))
(aux 5)          ; => (5 10)       &aux 是纯局部变量
```

**supplied-p 变量**（`c-p`/`b-p` 这种第三段）很关键——`nil` 也是合法值，
不带它就分不出「没给」和「给了 nil」：

```lisp
(defun opt-sp (a &optional (b 10 b-p)) (list a b (and b-p t)))
(opt-sp 1)          ; => (1 10 NIL)
(opt-sp 1 nil)      ; => (1 NIL T)
```

默认值表达式**可以引用前面的参数**：`(defun f (a &optional (b (1+ a))) ...)`。

段序规则：`必需 → &optional → &rest → &key → &allow-other-keys`。
`&rest` 与 `&key` **共享同一批实参**——`r` 拿到完整的 `(:K1 3)`，`k1` 再从中解析：

```lisp
(defun mixed (a &rest r &key k1 &allow-other-keys) (list a r k1))
(mixed 1 :k1 3)     ; => (1 (:K1 3) 3)
```

**⚠️ 双实现差异（实测）**：

- SBCL 对 `&optional` 与 `&key` 同列发 style-warning（合法但劝退）——别混用；
- 只要写了 `&key`，多余的「像关键字的参数」必须 `&allow-other-keys` 放行，
  否则报 illegal keyword——哪怕它们本来是想进 `&rest` 的（两个实现都拦）；
- 转发参数的省心写法是纯 `&rest` + `getf` 挑键（示例 11 的 forwarder）。

## 11.2 lambda / funcall / apply / #'

```lisp
(funcall (lambda (x) (* x x)) 6)     ; => 36
(apply #'+ '(1 2 3 4 5))             ; => 15
(apply #'+ 1 2 '(3 4 5))             ; => 15
```

三种「函数设计符」都能传：`#'car`（函数对象）、`'car`（符号）、`(lambda ...)`。
`#'` 是 `(function car)` 的简写。

**apply 的最后一个参数必须是列表**——忘了结尾的 `nil` 会报
`dotted argument list`（CLISP 实测），SBCL 直接类型错误。

因为变量格和函数格分开（06 章），把函数存在变量里调用必须 `funcall`：

```lisp
(let ((f #'car)) (funcall f '(1 2)))     ; => 1
```

**不能**写 `(f '(1 2))`——那会被当成「调用名为 F 的函数」。

## 11.3 多值

CL 用**多值**（values）而不是元组返回多个结果：

```lisp
(floor 7 2)                                 ; => 3            ← 只显示第一个值
(multiple-value-list (floor 7 2))           ; => (3 1)
(nth-value 1 (floor 7 2))                   ; => 1
(multiple-value-bind (q r) (floor 7 2) ...) ; q=3 r=1
```

关键性质：**单值上下文里多余值被静默丢弃**：

```lisp
(list (values 1 2))      ; => (1)     ← 2 被丢了，不报错
```

好处是不用为「顺便返回点额外信息」包对象；代价是**忘了接就静默丢**——
调试时用 `multiple-value-list` 显式捕获看一眼。

## 11.4 flet 与 labels

```lisp
(flet ((scale-2x (x) (* x 2))) (scale-2x 4))           ; => 8    兄弟互相不可见
(labels ((even-p2 (n) (if (zerop n) t (odd-p2 (1- n))))
         (odd-p2  (n) (if (zerop n) nil (even-p2 (1- n)))))
  (even-p2 10))                                          ; => T    可互调可递归
```

**用 `labels` 写递归，`flet` 写互不调用的辅助函数。**

flet 的正当用途是**遮蔽**：临时把某个函数换成自己的版本（示例 11 用自己的
`scale-2x` 演示）。**⚠️ 别遮蔽 CL 包的名字**：SBCL 的包锁连 flet 局部绑定
`1+` 都拦（CLISP 放行）——跨实现代码只遮蔽自己包里的函数（06 章）。

在 flet 里引用**兄弟**函数等于引用外层同名函数，没有就是「未定义函数」
（SBCL 编译期就警告）。

## 11.5 尾调用：两个实现的两副面孔

网上说法很乱，直接上实测：

| 场景 | SBCL 2.6.8 | CLISP 2.49.95 |
|---|---|---|
| 自尾递归 `(self 1000000000)` | `:DONE`，不爆栈 | — |
| 互尾递归 10 亿层 | 通过 | — |
| 尾递归 **1000** 层（示例 11 的 sum-to） | 通过 | 通过 |
| 尾递归 **5000** 层 | 通过 | **Lisp stack overflow** |
| SBCL 加 `(declaim (optimize (debug 3)))` 后互递归 1000 万层 | **爆栈**（信息点名原因） | — |

SBCL 爆栈信息原文：

```
Control stack exhausted (no more space for function call frames).
This is probably due to heavily nested or infinitely recursive function
calls, or a tail call that SBCL cannot or has not optimized away.
```

**结论**：ANSI **不要求** TCO。SBCL 默认做（但 debug 3 会关掉）；CLISP 做得有限
（几千层就爆）。可移植代码的铁律：**长循环/深递归改写成 `loop`/`do`**（12 章），
别赌尾调用优化。

## 11.6 高阶函数

```lisp
(defun compose (f g) (lambda (&rest args) (funcall f (apply g args))))
(funcall (compose (lambda (x) (* 2 x)) #'1+) 5)     ; => 12

(defun make-adder (n) (lambda (x) (+ x n)))
(funcall (make-adder 10) 32)                        ; => 42
```

闭包三连（示例 11 全部可跑）：

1. **计数器**——每个实例独立的状态；
2. **银行账户**——消息风格的对象（`case` 分发 :deposit/:withdraw/:balance）；
3. **记忆化**——哈希表藏在闭包里，第二次调用命中缓存。

这三个模式覆盖了日常「闭包当对象用」的九成场景；等真需要类、继承、多分派时
再上 CLOS（19 章）。

## 11.7 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `dotted argument list` 报错 | apply 最后一个参数不是列表 | 结尾补 `nil` |
| `(f x)` 不是调用变量 f 里的函数 | 变量格≠函数格 | `funcall` |
| 深递归在 CLISP 爆栈 | TCO 实现有限（≈5000 层） | 改 `loop`/`do` |
| SBCL 提示 `&OPTIONAL and &KEY found in the same lambda list` | 混用合法但被劝退 | 二选一 |
| 传了不认识的关键字报 illegal keyword | 有 `&key` 就会校验 | `&allow-other-keys` 或纯 `&rest` |
| flet 遮蔽 `1+` 被包锁拦 | SBCL 锁 COMMON-LISP 包 | 只遮蔽自己包的名字 |
| 多值「丢了一个」 | 单值上下文静默丢弃 | `multiple-value-bind` 接 |
