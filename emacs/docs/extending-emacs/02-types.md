# 02 · 类型与值

> 所属部分：第 1 部分 · 语言基础
>
> 示例：`examples/02-types.el`

Elisp 的类型系统有两个和其它语言不一样的地方：**没有独立的字符类型**（字符就是整数），以及 **`nil` 一个值身兼四职**（空表、假、符号、以及「没有值」）。这一章把常用类型过一遍，重点在那些「反直觉但正确」的边界上。所有输出都是示例真跑出来的。

## 2.1 类型查询与谓词

`type-of` 给出类型的符号；日常判断则用一堆 `xxxp` 谓词：

```elisp
(princ (format "type-of: %S\n" (mapcar #'type-of
                                       (list 42 3.14 "abc" 'sym '(1 . 2) [1 2] ?A))))
```

```
type-of: (integer float string symbol cons vector integer)
```

七个值七种结果。注意最后两个：`?A`（字符）的类型是 **integer**——字符没有独立类型，就是码位整数；`[1 2]` 是 **vector**（向量），和列表（cons）是两种不同的序列。

常用谓词：

```elisp
(princ (format "42: integerp=%S numberp=%S floatp=%S\n"
               (integerp 42) (numberp 42) (floatp 42)))
(princ (format "\"abc\": stringp=%S  'sym: symbolp=%S\n"
               (stringp "abc") (symbolp 'sym)))
(princ (format "nil: null=%S listp=%S consp=%S symbolp=%S\n"
               (null nil) (listp nil) (consp nil) (symbolp nil)))
(princ (format "'(1): listp=%S consp=%S\n" (listp '(1)) (consp '(1))))
```

```
42: integerp=t numberp=t floatp=nil
"abc": stringp=t  'sym: symbolp=t
nil: null=t listp=t consp=nil symbolp=t
'(1): listp=t consp=t
```

两个反直觉但正确的点：

- **`nil` 同时是「空表」和「假」**，所以 `listp`、`null`、`symbolp` 对它都为真；只有 `consp`（是不是非空 cons 单元）为假。
- 判「非空列表」要用 `consp`，不是 `listp`——`(listp nil)` 为 `t`，但 `(consp nil)` 为 `nil`。遍历列表时「还有没有下一个」的判据就是 `consp`（或直接判 `null`）。

`null` 是 `not` 的别名；`numberp` 同时接受整数和浮点。还有一批针对编辑器对象的谓词——`bufferp`、`markerp`、`keymapp`、`facep`——后面的章节会逐个遇到。

## 2.2 只有 nil 是假

```elisp
(princ (format "0 是真是假？%S     \"\" 是真是假？%S\n"
               (if 0 "真" "假") (if "" "真" "假")))
```

```
0 是真是假？"真"     "" 是真是假？"真"
```

**0 和空字符串在 Elisp 里都是真。** 只有 `nil`（以及等价的 `'()`）是假。这是 Lisp 家族最需要记住的语义，和 C 系语言差别最大。

常见的误用：`(if (- x y) ...)` 想表达「x≠y」——差为 0 时 `if` 走 else，看起来「碰巧对了」；但如果想表达「x<y」而写成 `(if (- y x) ...)`，差为 0 时同样进 else——这时该用 `(/= x y)`。原则：**涉及数值的关系判断，一律用比较函数（`<` `>` `=` `/=`），不要借道算术。**

## 2.3 字符就是整数

```elisp
(princ (format "?A = %S, (char-to-string ?A) = %S, (string-to-char \"A\") = %S\n"
               ?A (char-to-string ?A) (string-to-char "A")))
```

```
?A = 65, (char-to-string ?A) = "A", (string-to-char "A") = 65
```

`?A` 读作整数 65。没有字符类型，所以 `(+ ?a 1)` 得到 98 是合法的——处理 ASCII 算术时很方便（比如「下一个字母」写 `(1+ c)`）。反过来，字符串的下标访问拿到的也是整数：`(aref "abc" 0)` 是 97。

## 2.4 整数除法

```elisp
(princ (format "(/ 1 2) = %S, (/ 1.0 2) = %S, (float 1) = %S\n"
               (/ 1 2) (/ 1.0 2) (float 1)))
```

```
(/ 1 2) = 0, (/ 1.0 2) = 0.5, (float 1) = 1.0
```

**两个整数相除做整除**，`(/ 1 2)` 是 0。要小数必须让其中一个操作数变成浮点：

```elisp
(/ 1.0 2)       ; → 0.5
(float 1)       ; → 1.0
(* 1.0 (/ 1 2)) ; → 0.0 —— 先整除就晚了，典型的顺序陷阱
```

配套的：`mod` 取余（结果的符号跟第二个参数走），`%` 只接受整数且更严格。整数溢出不存在（见下节），但整数除法的「截断」要时刻留心。

## 2.5 bignum：整数不会静默溢出

```elisp
(princ (format "2^70 = %S, most-positive-fixnum = %S\n"
               (expt 2 70) most-positive-fixnum))
```

```
2^70 = 1180591620717411303424, most-positive-fixnum = 2305843009213693951
```

超过 `most-positive-fixnum` 之后自动提升为 bignum，**不会**像 C 那样回绕成负数——Python 风格而不是 C 风格。写算钱的、算哈希的代码不用再防溢出。代价是超大整数的运算会走慢路径，且 `eq` 对两个内容相同的大整数为假（第 6 章有实测和规避）。

## 2.6 向量：定长数组

```elisp
(princ (format "vector: %S, aref = %S, length = %S\n"
               (vector 'a 'b 'c) (aref [10 20 30] 1) (length [1 2 3])))
```

```
vector: [a b c], aref = 20, length = 3
```

向量是**定长**的连续存储：`aref` 按下标读，`aset` 按下标写，越界直接报错。列表是链——头部插入 O(1)、随机访问 O(n)；向量是数组——随机访问 O(1)、不能变长。**按索引反复取元素用向量，顺序遍历/构建用列表。**

`[10 20 30]` 是向量的读取语法（对应列表的 `'(10 20 30)`）。字符串其实也是「字符向量」，`aref` 同样适用。

## 2.7 哈希表：O(1) 查找

```elisp
(let ((ht (make-hash-table :test 'eql)))
  (puthash 'name "emacs" ht)
  (puthash 42 "answer" ht)
  (princ (format "hash: %S, %S, 键数 = %S\n"
                 (gethash 'name ht) (gethash 42 ht) (hash-table-count ht))))
```

```
hash: "emacs", "answer", 键数 = 2
```

`make-hash-table` 的 `:test` 决定键怎么比：`eq`（默认，符号/字符/fixnum 键）、`eql`（整数键，含大整数）、`equal`（字符串/列表键）。选错了的后果见第 6 章——静默查不到。键数用 `hash-table-count`，删除用 `remhash`。

## 2.8 可变性：谁能就地改

```elisp
(let ((s (copy-sequence "abc")))
  (aset s 0 ?X)
  (princ (format "aset 之后字符串 = %S（原字面量没变）\n" s)))
```

```
aset 之后字符串 = "Xbc"（原字面量没变）
```

分两类记：

| 不可变（「改」就是造新的） | 可变（能就地改） |
|---|---|
| 数字、符号、`t`、`nil` | 字符串（`aset`） |
| | 向量（`aset`） |
| | cons（`setcar`/`setcdr`，第 27 章） |
| | 哈希表（`puthash`） |
| | buffer、marker 等编辑器对象 |

「赋值不复制」+「列表可变」两个事实叠加，产生 Elisp 最隐蔽的一类 bug——共享结构（第 27 章专门讲）。上面的示例特意用 `copy-sequence` 复制一份再改，就是为了不碰字面量：**改字面量常量会被字节编译器警告**（`attempt to modify a constant` 一类）。

## 2.9 常用常量

```elisp
(princ (format "t = %S, float-pi = %S, emacs-version = %S\n"
               t float-pi emacs-version))
```

```
t = t, float-pi = 3.141592653589793, emacs-version = "31.1"
```

写扩展经常用到的还有 `emacs-major-version` / `emacs-minor-version`（版本适配，第 3 章）、`most-positive-fixnum` / `most-negative-fixnum`。注意 `t` 是**符号**：`(eq t t)` 为真，`(eq t 1)` 为假——所以别把 `t` 当「1」用。

## 2.10 本章小结

| 类型 | 读取语法 | 判谓 | 可变？ |
|---|---|---|---|
| 整数/浮点 | `42` / `3.14` | `integerp` / `floatp` | 否 |
| 字符（就是整数） | `?A` | 同整数 | 否 |
| 字符串 | `"abc"` | `stringp` | 是 |
| 符号 | `sym` / `'sym` | `symbolp` | 否（属性表可挂东西） |
| cons/列表 | `(1 . 2)` / `(1 2 3)` | `consp` / `listp` | 是 |
| 向量 | `[1 2 3]` | `vectorp` | 是 |
| 哈希表 | 无字面量，`make-hash-table` 造 | `hash-table-p` | 是 |
| 布尔 | 只有 `nil` 为假 | `null` | — |

---

上一章：[01 · 第一个程序：输出与 quote](01-hello.md)　｜　下一章：[03 · 变量与绑定](03-variables.md)　｜　返回：[Emacs 扩展开发指南](README.md)
