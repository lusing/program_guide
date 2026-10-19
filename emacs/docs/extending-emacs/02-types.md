# 02 · 类型与值

> 所属部分：第 1 部分 · 语言基础

> 示例：`examples/02-types.el`

## 2.1 类型查询与谓词

`type-of` 给出类型的符号，日常判断则用一堆 `xxxp` 谓词：

```elisp
(princ (format "type-of: %S\n" (mapcar #'type-of
                                       (list 1 1.0 "s" 'sym '(1) [1] ?A))))
```

```
type-of: (integer float string symbol cons vector integer)
```

注意最后一个 `?A`（字符）的类型是 **integer**，不是 `character` —— 这是第 5 节的内容。

常用谓词一览：

```elisp
42: integerp=t numberp=t floatp=nil
"abc": stringp=t  'sym: symbolp=t
nil: null=t listp=t consp=nil symbolp=t
'(1): listp=t consp=t
```

两个反直觉但正确的点：

- `nil` 同时是「空表」和「假」，所以 `listp`、`null`、`symbolp` 对它**都为真**；
  `consp`（是不是非空 cons 单元）为假。
- `(listp nil)` → `t`，但 `(consp nil)` → `nil`。判「非空列表」要用 `consp`。

## 2.2 只有 nil 是假

这是 Lisp 家族最需要记住的语义，和其他语言差别最大：

```elisp
(princ (format "0 是真是假？%S     \"\" 是真是假？%S\n"
               (if 0 "真" "假") (if "" "真" "假")))
```

```
0 是真是假？"真"     "" 是真是假？"真"
```

**`0` 和空字符串在 Elisp 里都是真**。只有 `nil`（以及等价于 `nil` 的 `'()`）是假。

导致的常见 bug 是写 `(if (string-match ...) ...)` 之外的判断时误以为 0 是假，比如
`(if (length list) ...)` —— 空列表长度为 0，这里恰好能用，但 `(if (- x y) ...)` 就是不行的。

## 2.3 字符就是整数

```elisp
?A = 65, (char-to-string ?A) = "A", (string-to-char "A") = 65
```

`?A` 读作整数 65。`(char-to-string ?A)` 得到 `"A"`，`(string-to-char "A")` 得到 65。
没有单独的字符类型，所以 `(+ ?a 1)` = 98 是合法的 —— 这在处理 ASCII 算术时很方便。

## 2.4 整数除法

```elisp
(/ 1 2) = 0, (/ 1.0 2) = 0.5, (float 1) = 1.0
```

**两个整数相除做整除**，`(/ 1 2)` 是 0。想得到小数就必须让其中一个操作数变成浮点：

```elisp
(/ 1.0 2)      ; → 0.5
(float 1)      ; → 1.0
(* 1.0 (/ 1 2)) ; 错误：先整除就晚了，结果是 0.0
```

最后一行是个典型的顺序陷阱。

## 2.5 bignum：整数不会静默溢出

```elisp
2^70 = 1180591620717411303424, most-positive-fixnum = 2305843009213693951
```

Emacs 有原生大整数。超过 `most-positive-fixnum` 之后会自动提升为 bignum，**不会**像 C 那样回绕。
这是 Python 风格而不是 C 风格 —— 写算钱的、算哈希的代码时不用再担心溢出。

## 2.6 常用常量

```elisp
t = t, float-pi = 3.141592653589793, emacs-version = "31.1"
```

写扩展时经常用到的还有 `emacs-major-version` / `emacs-minor-version`（做版本适配）、
`most-positive-fixnum`、`nil`、`t`。特别地 `t` 是**符号**，`(eq t t)` 为真，但 `(eq t 1)` 为假。

---

上一章：[01 · 第一个程序：输出与 quote](01-hello.md)　｜　下一章：[03 · 变量与绑定](03-variables.md)　｜　返回：[Emacs 扩展开发指南](README.md)
