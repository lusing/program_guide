# 36 · 数字：整除、取整、bignum 与位运算

> 所属部分：第 10 部分 · 对照参考手册补齐的主题

> 示例：`examples/36-numbers.el`

[02 · 类型与值](02-types.md) 只给了数字一个概览：整数、浮点、整数除法、bignum 各露了一面。那一章的任务是「认清类型」，所以每个话题都点到为止。但数字是**日常写代码时最容易踩坑的一类值**——它看起来最简单，坑却最深：`(/ 7 2)` 为什么是 `3`？`(round 2.5)` 为什么是 `2`？`0.1 + 0.2` 为什么不等于 `0.3`？右移一个负数为什么得到一个巨大的正数？

本章对应 Elisp 参考手册的 **Numbers** 一章，把这些问题逐个实测出来。**每一个结论下面都跟着示例真跑出来的输出**，不是「应该是这样」。

## 36.1 两种数字：整数与浮点

Elisp 只有两种数字：**整数**（任意精度，见 36.4）和**浮点**（IEEE 754 双精度）。示例第 1 节：

```elisp
(dolist (v (list 42 -7 3.14 1.0e+INF 1.0e+NaN))
  (princ (format "  %-12S type=%-8S integerp=%-5S floatp=%S\n"
                 v (type-of v) (integerp v) (floatp v))))
```

```
== 1) 整数与浮点 ==
  42           type=integer  integerp=t     floatp=nil
  -7           type=integer  integerp=t     floatp=nil
  3.14         type=float    integerp=nil   floatp=t
  1.0e+INF     type=float    integerp=nil   floatp=t
  1.0e+NaN     type=float    integerp=nil   floatp=t
```

最后两个值得单独看：`1.0e+INF`（正无穷）和 `1.0e+NaN`（不是数）**都是 float**。它们不是错误，是 IEEE 754 规定的合法浮点值，能参与运算、能比较（36.5 讲它们的脾气）。写法里的 `e+` 是科学计数法，`1.0e+INF` 读作「1.0 × 10^+INF」。

## 36.2 一个 `/`，两种语义

这是新手最常撞的第一堵墙。示例第 2 节：

```elisp
(princ (format "  (/ 7 2)   = %S\n" (/ 7 2)))
(princ (format "  (/ 7 2.0) = %S\n" (/ 7 2.0)))
(princ (format "  (/ 7.0 2) = %S\n" (/ 7.0 2)))
(princ (format "  (/ -7 2)  = %S   ; 朝零截断，不是向下取整\n" (/ -7 2)))
(princ (format "  (mod 7 2) = %S   ; 余数符号跟除数\n" (mod 7 2)))
(princ (format "  (%% 7 2)  = %S   ; 余数符号跟被除数\n" (% 7 2)))
(princ (format "  (mod -7 2) = %S  (%% -7 2) = %S\n" (mod -7 2) (% -7 2)))
(princ (format "  (mod 7 -2) = %S  (%% 7 -2) = %S\n" (mod 7 -2) (% 7 -2)))
```

```
== 2) 除法与取余 ==
  (/ 7 2)   = 3
  (/ 7 2.0) = 3.5
  (/ 7.0 2) = 3.5
  (/ -7 2)  = -3   ; 朝零截断，不是向下取整
  (mod 7 2) = 1   ; 余数符号跟除数
  (% 7 2)  = 1   ; 余数符号跟被除数
  (mod -7 2) = 1  (% -7 2) = -1
  (mod 7 -2) = -1  (% 7 -2) = 1
```

规则一句话：**只要有一个参数是浮点，就是普通除法；全是整数，就是「截断整除」**。`(/ 7 2)` 得 `3` 而不是 `3.5`，也不是 `4`。

想显式控制，就用下面的函数，别指望 `/` 猜你的心思。

`mod` 和 `%` 的区别只在**负数**上才看得出来，而它们的分工很清楚：

- `(mod a b)` —— 数学上的模，余数**跟除数同号**。`(mod -7 2)` = `1`（因为 `-7 = -4×2 + 1`）。
- `(% a b)` —— C 语言风格的取余，余数**跟被除数同号**。`(% -7 2)` = `-1`（因为 `-7 = -3×2 + (-1)`）。

两者对正数结果一样。**做环形索引（比如 kill ring 的下标回绕）该用 `mod`**，因为它的结果始终落在 `[0, b)` 里；用 `%` 会拿到负数下标。

## 36.3 取整四兄弟，以及 `round` 的怪脾气

示例第 3 节把四个函数并排放：

```elisp
(dolist (x (list 1.7 -1.7 2.5 3.5 -2.5))
  (princ (format "  %-6S truncate=%-4S floor=%-4S ceiling=%-4S round=%S\n"
                 x (truncate x) (floor x) (ceiling x) (round x))))
```

```
== 3) 取整 ==
  1.7    truncate=1    floor=1    ceiling=2    round=2
  -1.7   truncate=-1   floor=-2   ceiling=-1   round=-2
  2.5    truncate=2    floor=2    ceiling=3    round=2
  3.5    truncate=3    floor=3    ceiling=4    round=4
  -2.5   truncate=-2   floor=-3   ceiling=-2   round=-2
  --- 两参数版：自带「先除后取整」---
  (/ 5 2)=2  (floor 5 2)=2  (truncate 5 2)=2  (mod 5 2)=1
  --- 名字前面加 f 的版本返回浮点 ---
  (truncate 1.7)=1   (ftruncate 1.7)=1.0
  (ffloor 1.7)=1.0  (fceiling 1.7)=2.0  (fround 1.7)=2.0
```

四个方向记住这句口诀：

| 函数 | 方向 | 1.7 | -1.7 |
|---|---|---|---|
| `truncate` | 朝 **0** 靠 | 1 | -1 |
| `floor` | 朝 **负无穷** | 1 | -2 |
| `ceiling` | 朝 **正无穷** | 2 | -1 |
| `round` | 朝**最近整数** | 2 | -2 |

正数时 `truncate` 和 `floor` 一样、`ceiling` 和 `round` 多半一样；**差别全部集中在负数**上，所以看表时请盯着 `-1.7` 那一列。

> 【坑】`round` 用的是**「银行家舍入」**（round half to even）：正好落在 `.5` 上时取最近的**偶数**。看实测：`(round 2.5)` = **2**（不是 3！），`(round 3.5)` = **4**，`(round -2.5)` = **-2**。这么设计是为了让大量数据求和时误差不朝一边偏。如果你要的是「四舍五入、`.5` 一律进」，别用 `round`，自己写 `(floor (+ x 0.5))`。

另外两个变体：

- **两参数版**：`(floor 5 2)` 等价于 `(floor (/ 5 2.0))`，自带「先除后取整」。`mod` 的两参数版也同理。用它们能少写一次浮点转换，也避免中间结果被截断两次。
- **`f` 前缀版**：`ftruncate`/`ffloor`/`fceiling`/`fround` **返回浮点**（`1.0` 而不是 `1`）。当你把结果继续拿去做浮点运算、不希望被 `format "%d"` 之类的地方意外当整数处理时用它。

## 36.4 bignum：整数不会溢出

C、Java、Go 里 `int` 溢出是日常 bug；Elisp 里**不会**。示例第 4 节：

```elisp
(princ (format "  most-positive-fixnum = %S\n" most-positive-fixnum))
(princ (format "  fixnump=%S  integerp=%S\n"
               (fixnump most-positive-fixnum) (integerp most-positive-fixnum)))
(let ((big (1+ most-positive-fixnum)))
  (princ (format "  (1+ most-positive-fixnum) = %S\n" big))
  (princ (format "     fixnump=%S  integerp=%S  bignump=%S\n"
                 (fixnump big) (integerp big) (bignump big))))
(princ (format "  (expt 2 100) = %S\n" (expt 2 100)))
(princ (format "  (* (expt 2 62) 8) = %S   ; 换别的语言这里早溢出了\n"
               (* (expt 2 62) 8)))
```

```
== 4) fixnum 与 bignum ==
  most-positive-fixnum = 2305843009213693951
  fixnump=t  integerp=t
  (1+ most-positive-fixnum) = 2305843009213693952
     fixnump=nil  integerp=t  bignump=t
  (expt 2 100) = 1267650600228229401496703205376
  (* (expt 2 62) 8) = 36893488147419103232   ; 换别的语言这里早溢出了
  (abs most-negative-fixnum) = 2305843009213693952  fixnump=nil
```

机制是这样的：

- **fixnum** = 能塞进一个机器字（再留几个标签位）的小整数。本机 64 位下上界是 `most-positive-fixnum` = `2305843009213693951`（即 2^61 − 1）。它快，走机器指令。
- **bignum** = 任意精度整数，用 GMP 实现。一旦运算结果超出 fixnum 范围，**自动升级**，你不需要做任何声明。

于是 `(expt 2 100)` 老老实实给出 31 位精确数字，而不是一个溢出后的负数。

三个谓词要分清：`integerp` 问「是不是整数」（fixnum 和 bignum 都是 `t`），`fixnump` 问「是不是小整数」，`bignump` 问「是不是大整数」。**日常判断用 `integerp`**，只有关心性能/存储时才区分后两个。

顺带一个经典陷阱：`(abs most-negative-fixnum)` 的结果是 `2305843009213693952`，`fixnump` 为 `nil`——因为**负数的范围比正数多一个**，取绝对值就越界了，自动变成 bignum。这正是「别的语言里那个著名的 `abs(INT_MIN)` 还是负数」的坑，在 Elisp 里被 bignum 接住了。

## 36.5 浮点：不能当精确数用

示例第 5 节把浮点的所有「反直觉」一次性摆出来：

```elisp
(princ (format "  (+ 0.1 0.2)        = %S\n" (+ 0.1 0.2)))
(princ (format "  (= (+ 0.1 0.2) 0.3) = %S   ; 直接比相等是错的\n"
               (= (+ 0.1 0.2) 0.3)))
(princ (format "  差值 = %S\n" (- (+ 0.1 0.2) 0.3)))
(let ((eps 1e-9))
  (princ (format "  (< (abs (- (+ 0.1 0.2) 0.3)) %S) = %S   ; 用容差比较\n"
                 eps (< (abs (- (+ 0.1 0.2) 0.3)) eps))))
(princ (format "  (sqrt -1) = %S   (/ 1.0 0) = %S   (/ 0.0 0.0) = %S\n"
               (sqrt -1) (/ 1.0 0) (/ 0.0 0.0)))
(princ (format "  (= 1.0e+NaN 1.0e+NaN) = %S   ; NaN 不等于自己\n"
               (= 1.0e+NaN 1.0e+NaN)))
(princ (format "  (isnan 1.0e+NaN) = %S   (> 1.0e+INF 1.0e+308) = %S\n"
               (isnan 1.0e+NaN) (> 1.0e+INF 1.0e+308)))
(princ (format "  (- 1.0e+INF 1.0e+INF) = %S\n" (- 1.0e+INF 1.0e+INF)))
(princ (format "  (sin float-pi) = %S   ; 圆周率也是浮点，不为 0\n" (sin float-pi)))
(princ (format "  (/ 1 0) -> %S\n"
               (condition-case err (/ 1 0) (arith-error (error-message-string err)))))
```

```
== 5) 浮点的精度与特殊值 ==
  (+ 0.1 0.2)        = 0.30000000000000004
  (= (+ 0.1 0.2) 0.3) = nil   ; 直接比相等是错的
  差值 = 5.551115123125783e-17
  (< (abs (- (+ 0.1 0.2) 0.3)) 1e-09) = t   ; 用容差比较
  (sqrt -1) = -0.0e+NaN   (/ 1.0 0) = 1.0e+INF   (/ 0.0 0.0) = -0.0e+NaN
  (= 1.0e+NaN 1.0e+NaN) = nil   ; NaN 不等于自己
  (isnan 1.0e+NaN) = t   (> 1.0e+INF 1.0e+308) = t
  (- 1.0e+INF 1.0e+INF) = -0.0e+NaN
  (sin float-pi) = 1.2246467991473532e-16   ; 圆周率也是浮点，不为 0
  (/ 1 0) -> "Arithmetic error"
```

逐条说：

1. **`0.1 + 0.2 ≠ 0.3`**。这不是 Elisp 的 bug，是二进制浮点表示不了 `0.1`（就像十进制表示不了 1/3）。差值是 `5.55e-17`。
2. **浮点比较一律用容差**：`(< (abs (- a b)) eps)`。`eps` 取多少取决于你的量级，工程上常用 `1e-9`。
3. **`NaN` 不等于自己**。`(= 1.0e+NaN 1.0e+NaN)` 是 `nil`——这是 IEEE 754 的规定，也是**唯一一个「自己和自己不相等」的值**。判断它要用 `(isnan x)`。
4. **整数除零和浮点除零是两回事**：`(/ 1 0)` 抛 `arith-error`（`Arithmetic error`），而 `(/ 1.0 0)` 平平静静返回 `1.0e+INF`。**要不要报错，取决于你写的是整数还是浮点**——同一行代码加个 `.0` 就从「崩溃」变成「继续算」。
5. **无穷减无穷得到 NaN**，不是 0。
6. **`(sin float-pi)` 不是 0**，是 `1.22e-16`。`float-pi` 只是 π 的浮点近似，三角函数的结果永远带误差。

## 36.6 位运算：`ash` 与 `lsh` 的分水岭

示例第 6 节：

```elisp
(princ (format "  (logand 12 10)=%S (logior 12 10)=%S (logxor 12 10)=%S\n"
               (logand 12 10) (logior 12 10) (logxor 12 10)))
(princ (format "  (lognot 0)=%S   (logcount 15)=%S   (logb 8)=%S\n"
               (lognot 0) (logcount 15) (logb 8)))
(princ "  --- 左移两者一致；右移分道扬镳 ---\n")
(princ (format "  (lsh 1 2) = %S   (ash 1 2) = %S\n"
               (with-no-warnings (lsh 1 2)) (ash 1 2)))
(princ "  lsh 是逻辑移位（右移高位补 0），ash 是算术移位（右移保留符号）：\n")
(princ (format "  (lsh -8 -1) = %S\n" (with-no-warnings (lsh -8 -1))))
(princ (format "  (ash -8 -1) = %S\n" (ash -8 -1)))
(princ (format "  (lsh -1 -1) = %S\n" (with-no-warnings (lsh -1 -1))))
(princ (format "  (ash -1 -1) = %S\n" (ash -1 -1)))
```

```
== 6) 位运算 ==
  (logand 12 10)=8 (logior 12 10)=14 (logxor 12 10)=6
  (lognot 0)=-1   (logcount 15)=4   (logb 8)=3
  --- 左移两者一致；右移分道扬镳 ---
  (lsh 1 2) = 4   (ash 1 2) = 4
  lsh 是逻辑移位（右移高位补 0），ash 是算术移位（右移保留符号）：
  (lsh -8 -1) = 2305843009213693948
  (ash -8 -1) = -4
  (lsh -1 -1) = 2305843009213693951
  (ash -1 -1) = -1
```

基础四个：`logand`（与）、`logior`（或）、`logxor`（异或）、`lognot`（取反，注意它按**无限位补码**算，所以 `(lognot 0)` = `-1`）。辅助三个：`logcount` 数二进制里有多少个 1，`logb` 返回「以 2 为底的对数取整」（即最高位的序号）。

移位是本节的重点。两个函数：

- **`ash`（arithmetic shift，算术移位）**：右移时**高位补符号位**。`(ash -8 -1)` = `-4`，`(ash -1 -1)` = `-1`（`-1` 的补码全是 1，怎么移都是 -1）。
- **`lsh`（logical shift，逻辑移位）**：右移时**高位补 0**。`(lsh -8 -1)` = `2305843009213693948`——一个巨大的正数，因为负数的补码高位全是 1，补 0 之后符号位就没了。

**左移两者完全一样**，所以只有右移负数时才会发现区别。而 Emacs 的态度很明确：**字节编译器会警告你别用 `lsh`**。示例把这条警告当场抓了下来（用 `byte-compile-log-warning-function` 接住，免得它跑到 stderr 上）：

```elisp
;;; 字节编译器会劝你别用 lsh。把这条警告当场抓下来，而不是让它跑到 stderr 上。
(let (warns)
  (let ((byte-compile-log-warning-function
         (lambda (string &optional _position _fill _level)
           (push string warns))))
    (byte-compile '(lambda () (lsh -8 -1))))
  (princ (format "  字节编译器对 (lsh -8 -1) 的警告原文： %S\n"
                 (car (nreverse warns)))))
```

```
  字节编译器对 (lsh -8 -1) 的警告原文： "avoid ‘lsh’; use ‘ash’ instead"
```

所以示例里那几个 `lsh` 都套了 `with-no-warnings`（[05 · 控制流](05-control-flow.md) 用过它），否则本章示例自己就编译不过「零警告」这一关。**结论：日常一律用 `ash`**，只有你真的想要「把整数当成一串无符号位」时才用 `lsh`，而且要用得很小心。

## 36.7 随机数：想可复现就播种

`(random N)` 返回 `[0, N)` 里的随机整数。问题是——**示例要能被反复验证，输出不能每次都变**。Emacs 给的答案是「用字符串播种」：

```elisp
(let (a b)
  (random "demo-seed")
  (setq a (list (random 100) (random 100) (random 100)))
  (random "demo-seed")
  (setq b (list (random 100) (random 100) (random 100)))
  (princ (format "  同一种子两次结果： %S\n" a))
  (princ (format "                    %S\n" b))
  (princ (format "  两次相等？ %S\n" (equal a b))))
(princ (format "  (random 1) = %S   ; 上限为 1 时只能是 0\n" (random 1)))
```

```
== 7) 随机数 ==
  同一种子两次结果： (20 14 93)
                    (20 14 93)
  两次相等？ t
  (random 1) = 0   ; 上限为 1 时只能是 0
```

- `(random "字符串")` **重置**随机数发生器，之后取的数列完全确定。
- `random` 的**参数是上界，不含**：`(random 100)` 给 0..99，`(random 1)` 恒为 `0`。
- 参数必须是正整数（或 `t`，表示「重新随机播种」）。**写测试/可复现示例时务必播种**，否则你的测试会「偶尔红」。

## 36.8 字符串 ↔ 数字

示例第 8 节：

```elisp
(princ (format "  (string-to-number \"42\")      = %S\n" (string-to-number "42")))
(princ (format "  (string-to-number \"3.5\")     = %S\n" (string-to-number "3.5")))
(princ (format "  (string-to-number \"0x1f\")    = %S   ; 默认按十进制，认不出 0x\n"
               (string-to-number "0x1f")))
(princ (format "  (string-to-number \"1f\" 16)   = %S   ; 进制是第二个参数\n"
               (string-to-number "1f" 16)))
(princ (format "  (string-to-number \"abc\")     = %S   ; 解析失败返回 0，不报错\n"
               (string-to-number "abc")))
(princ (format "  (number-to-string 42)   = %S\n" (number-to-string 42)))
(princ (format "  (number-to-string 3.0)  = %S\n" (number-to-string 3.0)))
(princ (format "  (cl-parse-integer \"42\")        = %S\n" (cl-parse-integer "42")))
(princ (format "  (cl-parse-integer \"  42abc\" :start 2 :end 4) = %S\n"
               (cl-parse-integer "  42abc" :start 2 :end 4)))
```

```
== 8) 字符串 <-> 数字 ==
  (string-to-number "42")      = 42
  (string-to-number "3.5")     = 3.5
  (string-to-number "0x1f")    = 0   ; 默认按十进制，认不出 0x
  (string-to-number "1f" 16)   = 31   ; 进制是第二个参数
  (string-to-number "abc")     = 0   ; 解析失败返回 0，不报错
  (number-to-string 42)   = "42"
  (number-to-string 3.0)  = "3.0"
  (cl-parse-integer "42")        = 42
  (cl-parse-integer "  42abc" :start 2 :end 4) = 42
  --- format 的动词 ---
    %d=255  %5.2f= 3.14  %e=1.234500e+04  %x=ff  %o=10  %g=1e-07
```

三个坑，全在这里：

- **`string-to-number` 默认是十进制**，`"0x1f"` 会被解析成 `0`（它读到 `x` 就停了，前面那个 `0` 就是结果）。要按 16 进制解析得写 `(string-to-number "1f" 16)`——注意此时**字符串里不要再带 `0x` 前缀**。
- **解析失败返回 `0`，不报错**。所以「用户输入的不是数字」和「用户输入的确实是 0」从返回值上分不出来。需要严格校验就用 `cl-parse-integer`（它只认整数、且不匹配就报错），或者自己用正则先过一遍（[08 · 字符串与正则](08-strings-regexp.md)）。
- **`number-to-string` 只吃数字**；反过来 `(string-to-number ...)` 只吃字符串。别指望它们像某些语言那样「自动转」。

`format` 的动词（示例里那一行用的是 `%%` 转义，因为 `%` 在 `format` 里是特殊字符）：

| 动词 | 含义 | 例子 |
|---|---|---|
| `%d` | 十进制整数 | `255` |
| `%5.2f` | 浮点，总宽 5、小数 2 位 | ` 3.14` |
| `%e` | 科学计数法 | `1.234500e+04` |
| `%x` / `%o` | 十六进制 / 八进制 | `ff` / `10` |
| `%g` | 「挑一个短的」 | `1e-07` |
| `%S` | 任何对象的**可 `read` 回**形式 | 见全章输出 |

`%S` 和 `%s` 的区别在 [01 · 第一个程序](01-hello.md) 讲过：`%S` 会加引号和转义，保证结果能被 `read` 回来；`%s` 是「给人看」。**示例输出一律用 `%S`**，这样输出的每个值都是可复现的 Lisp 对象。

## 36.9 数字上的 `=` / `eql` / `equal`

[06 · 相等性](06-equality.md) 讲过这三者，示例第 9 节补上「数字」这一格：

```elisp
(princ (format "  (= 1 1.0)     = %S   ; = 只比数值\n" (= 1 1.0)))
(princ (format "  (eql 1 1.0)   = %S   ; eql 还要求类型相同\n" (eql 1 1.0)))
(princ (format "  (equal 1 1.0) = %S\n" (equal 1 1.0)))
(princ (format "  (eql (expt 2 100) (expt 2 100)) = %S  ; bignum 按值比\n"
               (eql (expt 2 100) (expt 2 100))))
(princ (format "  (= 1.0e+INF 1.0e+INF) = %S\n" (= 1.0e+INF 1.0e+INF)))
```

```
== 9) 数字上的 = / eql / equal ==
  (= 1 1.0)     = t   ; = 只比数值
  (eql 1 1.0)   = nil   ; eql 还要求类型相同
  (equal 1 1.0) = nil
  (eql (expt 2 100) (expt 2 100)) = t  ; bignum 按值比
  (= 1.0e+INF 1.0e+INF) = t
```

- **`=` 是「数值相等」**：`1` 和 `1.0` 相等。它只接受数字（或 marker），给别的类型会报错。
- **`eql` 还要求类型一致**：`1` 和 `1.0` 不 `eql`。这是它和 `=` 唯一的差别（对数字而言）。
- **`equal` 对数字的行为跟 `eql` 一样**（都是「同值同类型」）。
- **bignum 按值比较**：两个分别算出来的 `2^100` 是 `eql` 的——大整数虽然是指针，比较时走的是数值比较。

口诀：**算数值用 `=`，放哈希表当键用 `eql`（默认）或 `equal`。**

## 36.10 常用数学函数

一屏速览（示例第 10 节的真实输出）：

```elisp
(princ (format "  (sqrt 2)=%S  (exp 1)=%S  (log (exp 1))=%S\n"
               (sqrt 2) (exp 1) (log (exp 1))))
(princ (format "  (log 8 2)=%S  (expt 2 10)=%S  (expt 2 -1)=%S  (expt 2.0 0.5)=%S\n"
               (log 8 2) (expt 2 10) (expt 2 -1) (expt 2.0 0.5)))
(princ (format "  (abs -3.5)=%S  (max 1 2.5 2)=%S  (min 1 2.5 2)=%S\n"
               (abs -3.5) (max 1 2.5 2) (min 1 2.5 2)))
(princ (format "  (float 3)=%S  (float 3.5)=%S\n" (float 3) (float 3.5)))
(princ (format "  (cl-loop for i from 1 to 10 sum i) = %S\n"
               (cl-loop for i from 1 to 10 sum i)))
```

```
== 10) 常用数学函数 ==
  (sqrt 2)=1.4142135623730951  (exp 1)=2.718281828459045  (log (exp 1))=1.0
  (log 8 2)=3.0  (expt 2 10)=1024  (expt 2 -1)=0.5  (expt 2.0 0.5)=1.4142135623730951
  (abs -3.5)=3.5  (max 1 2.5 2)=2.5  (min 1 2.5 2)=1
  (float 3)=3.0  (float 3.5)=3.5
  (cl-loop for i from 1 to 10 sum i) = 55
```

几点说明：

- `log` **一个参数**是自然对数，两个参数是「以第二个数为底」：`(log 8 2)` = `3.0`。
- `expt` 的指数可以是负数（得 `0.5`）也可以是浮点（`(expt 2.0 0.5)` 就是开平方）。**只要结果不是整数，它就自然变成浮点**。
- `(float 3)` 把整数转成 `3.0`；反过来要整数得用 36.3 的取整函数。
- `cl-loop` 的 `sum` 子句来自 `cl-lib`（[09 · 序列与 cl-lib](09-sequences.md)），写「累加」比手写 `while` 清爽得多。

## 36.11 坑位清单

1. **`(/ 7 2)` 是 `3` 不是 `3.5`** —— 全是整数就做截断整除。想要浮点就把任一参数写成浮点：`(/ 7 2.0)`。
2. **`(/ -7 2)` 是 `-3` 不是 `-4`** —— 截断方向是**朝零**，不是向下取整。要向下取整用 `(floor -7 2)`。
3. **`mod` 与 `%` 只在负数上分家** —— 余数符号分别跟除数/被除数。环形下标用 `mod`。
4. **`(round 2.5)` 是 `2`** —— 银行家舍入，`.5` 取最近偶数。要「一律进位」自己写 `(floor (+ x 0.5))`。
5. **负数上四个取整函数才显出差别** —— 看表请盯 `-1.7` 那一行；正数上 `truncate`/`floor` 常常撞在一起。
6. **`0.1 + 0.2 ≠ 0.3`** —— 浮点比较一律用容差 `(< (abs (- a b)) eps)`。
7. **`NaN` 不等于自己** —— 判断用 `(isnan x)`；无穷减无穷得到 NaN 而不是 0。
8. **整数除零报错、浮点除零不报错** —— `(/ 1 0)` 抛 `arith-error`，`(/ 1.0 0)` 返回 `1.0e+INF`。
9. **右移负数时 `lsh` 和 `ash` 天差地别** —— `ash` 保留符号（`-8 → -4`），`lsh` 补 0（`-8 → 2305843009213693948`）。字节编译器会警告 `avoid ‘lsh’; use ‘ash’ instead`，日常请用 `ash`。
10. **`(string-to-number "0x1f")` 是 `0`** —— 默认十进制。要十六进制写 `(string-to-number "1f" 16)`，且字符串里别带 `0x`。
11. **解析失败返回 `0` 不报错** —— 「不是数字」和「就是 0」分不开，需要严格校验用 `cl-parse-integer`。
12. **`(random N)` 不含 N** —— `(random 1)` 恒为 `0`；写可复现的示例/测试要用 `(random "种子")` 播种。
13. **`abs` 也有「溢出」** —— `(abs most-negative-fixnum)` 越界成 bignum。Elisp 不会给你错误答案，但类型悄悄变了。
14. **`=` 和 `eql` 对数字的分歧只在类型上** —— `(= 1 1.0)` 为 `t`，`(eql 1 1.0)` 为 `nil`。

下一章换一类「看起来简单、实际有四个格子」的值：**符号（symbol）**。它同时能当名字、当变量、当函数、还自带一张属性表——理解它，才能读懂 `defadvice` 时代的老代码和今天各种「给符号打标记」的写法。

上一章：[35 · 收尾项目：打印一张带坐标的柱状图](35-graph.md)　｜　下一章：[37 · 符号：四个格子、属性表与 obarray](37-symbols.md)　｜　返回：[Emacs 扩展开发指南](README.md)
