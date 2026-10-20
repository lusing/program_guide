# 48 · 类型与结构：cl-defstruct、cl-assert 与 cl-print

> 所属部分：第 11 部分 · 跟随 CL 手册：Common Lisp 扩展

> 示例：`examples/48-types-structs.el`

本章把 CL 手册余下五章一次讲完：第 4 章 Predicates 的类型谓词与派生类型（`cl-typep`、`cl-deftype`、`cl-equalp`）、第 9 章 Numbers（`cl-gcd`、`cl-floor` 家族、`cl-random`、浮点常量）、第 12 章 Structures（`cl-defstruct` 及其全部选项与内省函数）、第 2 章 Printing（`cl-prin1` 与 `cl-print-object` 泛型）、第 13 章 Assertions and Errors（`cl-assert`、`cl-check-type`）。这五章彼此独立，但合起来正好回答了「在 Emacs Lisp 里怎样像 CL 那样定义数据、约束数据、打印数据」。

开工前先亮三个**实测才看得清**的事实：其一，31.1 的 `cl-defstruct` 默认用 **record 表示**——打印成 `#s(person …)`、可以 `read` 回来，伪造 tag 的向量骗不过谓词（手册里 `[cl-struct-person …]` 的输出是旧 vector 实现时代的写法）；其二，CL 语义与字节编译器会**提前**介入：只读槽的 `setf` 在编译期就报 `point-x is a read-only slot`，`cl-check-type` 的类型实参**不求值**——写成 `'integer` 会让 `cl-typep` 的 inliner 在编译期报 `Bad type spec: 'integer`；其三，断言只是「健全性检查」，`speed=3` 且 `safety<3` 时会被字节编译器整个优化掉，断言里绝不能放副作用。每条都在下文附真实输出。

## 48.1 `cl-typep`：CL 类型判定

手册 4.1（Type Predicates）的核心是 `cl-typep`：它接受一个**类型说明符**（type specifier）——要么是一个符号，要么是以符号开头的列表——判定对象是否属于该类型。示例第 1 节把手册列的判定规则逐条跑一遍：

示例第 1 节：

```elisp
(princ (format "  (cl-typep 5 'integer) ≡ (integerp 5) → %S\n"
               (cl-typep 5 'integer)))
(princ (format "  t 是一切、nil 是空集：%S / %S\n"
               (cl-typep 'anything t) (cl-typep 'anything nil)))
(princ (format "  null ≡ nil 对象；atom ≡ 非 cons：%S / %S / %S\n"
               (cl-typep nil 'null) (cl-typep 5 'atom) (cl-typep '(1) 'atom)))
(princ (format "  character 匹配 0..255 的整数：%S / %S\n"
               (cl-typep 65 'character) (cl-typep 256 'character)))
(princ (format "  (integer 0 10) 闭区间：%S / %S / %S\n"
               (cl-typep 0 '(integer 0 10))
               (cl-typep 10 '(integer 0 10))
               (cl-typep 11 '(integer 0 10))))
(let ((exclusive '(integer 0 (5))))
  (princ (format "  单层列表上界=排他：(integer 0 (5)) 里 4 → %S、5 → %S；星号无界 → %S\n"
                 (cl-typep 4 exclusive)
                 (cl-typep 5 exclusive)
                 (cl-typep 999 '(integer 0 *)))))
(princ (format "  or 组合：(or integer (float 0 *)) 判 2.5 → %S、-1.5 → %S\n"
               (cl-typep 2.5 '(or integer (float 0 *)))
               (cl-typep -1.5 '(or integer (float 0 *)))))
(princ (format "  (member 1 2 3 4) ≡ (integer 1 4)：判 3 → %S、5 → %S\n"
               (cl-typep 3 '(member 1 2 3 4))
               (cl-typep 5 '(member 1 2 3 4))))
(princ (format "  (satisfies oddp) 调谓词：判 3 → %S、4 → %S\n"
               (cl-typep 3 '(satisfies oddp)) (cl-typep 4 '(satisfies oddp))))
(princ (format "  cl-coerce 序列互转：%S %S %S\n"
               (cl-coerce '(?a ?b) 'string)
               (cl-coerce "ab" 'list)
               (cl-coerce '(1 2) 'vector)))
(princ (format "  cl-coerce 字符与浮点：%S %S %S\n"
               (cl-coerce "x" 'character)
               (cl-coerce 'y 'character)
               (cl-coerce 3 'float)))
```

运行结果：

```
  (cl-typep 5 'integer) ≡ (integerp 5) → t
  t 是一切、nil 是空集：t / nil
  null ≡ nil 对象；atom ≡ 非 cons：t / t / nil
  character 匹配 0..255 的整数：t / t
  (integer 0 10) 闭区间：t / t / nil
  单层列表上界=排他：(integer 0 (5)) 里 4 → t、5 → nil；星号无界 → t
  or 组合：(or integer (float 0 *)) 判 2.5 → t、-1.5 → nil
  (member 1 2 3 4) ≡ (integer 1 4)：判 3 → t、5 → nil
  (satisfies oddp) 调谓词：判 3 → t、4 → nil
  cl-coerce 序列互转："ab" (97 98) [1 2]
  cl-coerce 字符与浮点：120 121 3.0
```

逐点读：

**符号类型名就是谓词名的简写。** `(cl-typep 5 'integer)` 与 `(integerp 5)` 等价；`t` 匹配任何对象、`nil` 不匹配任何对象——这两个极端让「类型」可以当集合用。`null` 只认 `nil`，`atom` 认一切非 cons。

**`character` 在 Emacs 里是个范围谓词。** Emacs 没有独立字符类型，字符就是整数；手册因此把 `character` 定义为「0 到 255 的整数」——`65`（即 `?A`）通过，`256` 不通过。这解释了为什么 `?A` 和 `65` 在 Emacs 里永远无法区分。

**数字区间类型：`(integer 下界 上界)`，闭区间；上界写成单层列表 `(5)` 表示排他；星号 `*` 表示无界。** `(integer 0 10)` 里 `0` 和 `10` 都算数、`11` 不算；`(integer 0 (5))` 里 `4` 算、`5` 不算；`(integer 0 *)` 是「自然数」。有一个 31.1 实测坑：把 `(integer 0 (5))` 写成**字面量**直接传给 `cl-typep` 时，字节编译器的 `cl-typep--inliner` 处理不了排他上界，会报 `Optimization failure for cl-typep … Bad type spec: 'integer`（只是优化失败，运行结果仍对，但 `run-all.sh` 视任何警告为失败）——示例因此把说明符绑进 `exclusive` 变量再传，inliner 见到非字面量就不内联，警告消失。

**组合说明符：`or` 并集、`member` 枚举、`satisfies` 调任意谓词。** `(or integer (float 0 *))` 命中非负浮点 `2.5` 但不命中 `-1.5`；`(member 1 2 3 4)` 等价于 `(integer 1 4)`；`(satisfies oddp)` 把判定交给谓词函数——手册特意提醒 `satisfies` 的谓词对 `cl-typep` 的调用者应是「无副作用、对一切对象有定义」的。

**`cl-coerce` 是类型判定的另一面：显式转换。** 序列之间互转（列表↔字符串↔向量，字符串的元素是字符码）、`"x"` 或符号 `'y` 转字符码（取首字符/名字首字符）、整数转浮点。转不了就报错（比如把多字符字符串转 `character`）。

最后一条机制性事实写在示例的纯文本行里：`cl-typep` 判定一个「符号开头」的类型名时，靠的是一个叫 `类型名-p` 的谓词函数。这就是为什么 `cl-defstruct` 定义的结构类型能被 `cl-typep` 识别（见 48.9）——结构谓词 `person-p` 正好是这个名字。

## 48.2 `cl-deftype`：派生类型

手册 4.2（Derived Types）允许用 `cl-deftype` 定义新类型名——地位与内建类型完全平等。示例第 2 节用手册自己的 `unsigned-byte` 例子：

示例第 2 节：

```elisp
(cl-deftype unsigned-byte (&optional bits)
  (list 'integer 0 (if (eq bits '*) bits (1- (ash 1 bits)))))
(princ (format "  (unsigned-byte 8) ≡ (integer 0 255)：判 200 → %S、300 → %S\n"
               (cl-typep 200 '(unsigned-byte 8))
               (cl-typep 300 '(unsigned-byte 8))))
(princ (format "  裸符号 ≡ 不带参调用：unsigned-byte ≡ (integer 0 *)：判 -1 → %S、999 → %S\n"
               (cl-typep -1 'unsigned-byte)
               (cl-typep 999 'unsigned-byte)))
(princ (format "  未给默认值的 &optional 参数默认 *：→ %S\n"
               (cl-typep 999999999 'unsigned-byte)))
```

运行结果：

```
  (unsigned-byte 8) ≡ (integer 0 255)：判 200 → t、300 → nil
  裸符号 ≡ 不带参调用：unsigned-byte ≡ (integer 0 *)：判 -1 → nil、999 → t
  未给默认值的 &optional 参数默认 *：→ t
```

逐点读：

**`cl-deftype` 像 `defmacro`：遇到类型名就把 body 展开成等价的类型说明符。** `(unsigned-byte 8)` 在使用处被展开为 `(integer 0 255)`，所以 `200` 通过、`300` 不通过。body 里 `(ash 1 bits)` 是 2 的 bits 次方，减一得上界。

**类型形参的默认值约定是 `*`。** `&optional bits` 不给默认形时，裸写 `unsigned-byte` 等价于 `(unsigned-byte *)`，进而展开为 `(integer 0 *)`——「任意长度的非负整数」，所以 `-1` 不通过而 `999`、`999999999` 都通过。

**同一套类型名处处通用。** `cl-typecase` 的分支键、`cl-check-type` 的类型实参（48.12）、`cl-map` 的结果类型（47.2）吃的都是这套说明符，派生类型在哪都能用。手册还留了一句告诫：派生类型也可以做 `cl-defmethod` 的特化器，但参数 precedence 的排序规则未定义——写方法分派时别把关键逻辑押在这上面。

## 48.3 `cl-equalp`：更宽松的相等

手册 4.3（Equality Predicates）在 `eq`/`eql`/`equal` 之外补一个 `cl-equalp`：对数字和字符串刻意放宽。示例第 3 节：

示例第 3 节：

```elisp
(princ (format "  字符串大小写不敏感：%S（equal 是 %S）\n"
               (cl-equalp "Foo" "foo") (equal "Foo" "foo")))
(princ (format "  数字跨类型：3 vs 3.0 → %S（equal 是 %S）\n"
               (cl-equalp 3 3.0) (equal 3 3.0)))
(princ (format "  向量与 cons 递归比较：%S\n"
               (cl-equalp [1 (2 . 3) "Ab"] [1 (2 . 3) "aB"])))
(princ (format "  字符串不与整数向量比（与 CL 的差异）：%S\n"
               (cl-equalp "ab" [?a ?b])))
```

运行结果：

```
  字符串大小写不敏感：t（equal 是 nil）
  数字跨类型：3 vs 3.0 → t（equal 是 nil）
  向量与 cons 递归比较：t
  字符串不与整数向量比（与 CL 的差异）：nil
```

逐点读：

**两处放宽都直击 `equal` 的痛点。** 字符串按大小写不敏感比（`"Foo"` 与 `"foo"` 相等），数字跨整数/浮点按数值比（`3` 与 `3.0` 相等）——而 `equal` 对这两对都答 `nil`（Emacs 的 `equal` 对数字本来就按 `eql` 语义，`3` ≠ `3.0`）。

**向量、cons、字符串（作序列）递归比。** 嵌套结构 `[1 (2 . 3) "Ab"]` 与 `[1 (2 . 3) "aB"]` 深层相等——内层字符串同样大小写不敏感。

**与 CL 的两点差异要记牢。** 其一，CL 的 `equalp` 认为字符串等于同字符的整数向量（因为 CL 字符串是特化向量），Emacs 实测 `"ab"` 与 `[?a ?b]` **不等**——字符串不与整数向量比。其二，CL 的 `equalp` 按大小写不敏感比**字符对象**，Emacs 没有独立字符类型，这条被略去；其余对象一律按 `equal` 比。这两条差异写在示例的纯文本行里，是手册原文明说的。

## 48.4 数字小函数：`cl-digit-char-p` / `cl-gcd` / `cl-lcm` / `cl-isqrt`

手册第 9 章（Numbers）在 Emacs 侧只落地了一小撮函数：9.1 全章只剩 `cl-digit-char-p`（`cl-oddp`、`cl-plusp` 之类手册没有单列），9.2 给出最大公约数一族与整除家族。示例第 4 节先过小函数：

示例第 4 节：

```elisp
(princ (format "  cl-digit-char-p 返回数字值：?9 十进制 → %S；?f 十六进制 → %S；?f 十进制 → %S\n"
               (cl-digit-char-p ?9)
               (cl-digit-char-p ?f 16)
               (cl-digit-char-p ?f 10)))
(princ (format "  cl-gcd 12 18 → %S；单参取绝对值 → %S；零参 → 0\n"
               (cl-gcd 12 18) (cl-gcd -12) (cl-gcd)))
(princ (format "  cl-lcm 4 6 → %S；零参 → %S\n"
               (cl-lcm 4 6) (cl-lcm)))
(princ (format "  cl-isqrt 整数平方根：17 → %S、16 → %S\n"
               (cl-isqrt 17) (cl-isqrt 16)))
```

运行结果：

```
  cl-digit-char-p 返回数字值：?9 十进制 → 9；?f 十六进制 → 15；?f 十进制 → nil
  cl-gcd 12 18 → 6；单参取绝对值 → 12；零参 → 0
  cl-lcm 4 6 → 12；零参 → 1
  cl-isqrt 整数平方根：17 → 4、16 → 4
```

逐点读：

**`cl-digit-char-p` 命中时返回数字值而不是 `t`。** `?9` 十进制得 `9`，`?f` 十六进制得 `15`，`?f` 十进制得 `nil`——「判字符是否为数字」与「取该数字的值」一步完成，第二参数是进制（默认 10）。

**`cl-gcd` / `cl-lcm` 接受任意多个参数。** 公约数/公倍数按结合律归约；`cl-gcd` 单参取绝对值、零参返回 `0`（加法律单位元），`cl-lcm` 零参返回 `1`（乘法律单位元）——这两个零参值是 CL 规格写死的，背下来比推合理快。

**`cl-isqrt` 是向下取整的整数平方根。** `17` 得 `4`、`16` 得 `4`；等价于 `(floor (sqrt x))` 但不经过浮点，大整数上不会丢精度。

## 48.5 整除四兄弟：`cl-floor` / `cl-ceiling` / `cl-truncate` / `cl-round` 与 `cl-mod` / `cl-rem`

手册 9.2 的重头是整除家族：同一个「除法」，按商向哪个方向取整分成四种，余数符号随之不同。Emacs Lisp 没有多值，返回值改成**「商 余数」两元素列表**。示例第 5 节：

示例第 5 节：

```elisp
(princ (format "  cl-floor 7 2 → %S；-7 2 → %S（商向 -∞ 取整）\n"
               (cl-floor 7 2) (cl-floor -7 2)))
(princ (format "  cl-ceiling 7 2 → %S（商向 +∞ 取整，余数 ≤ 0）\n"
               (cl-ceiling 7 2)))
(princ (format "  cl-truncate -7 2 → %S（商向 0 取整）\n"
               (cl-truncate -7 2)))
(princ (format "  cl-round 平局靠偶：5 2 → %S；7 2 → %S\n"
               (cl-round 5 2) (cl-round 7 2)))
(princ (format "  单参浮点：(cl-floor -2.5) → %S（首值是整数、余值是浮点）\n"
               (cl-floor -2.5)))
(princ (format "  cl-mod ≡ cl-floor 第二值 → %S；cl-rem ≡ cl-truncate 第二值 → %S；原生 %% → %S\n"
               (cl-mod -7 2) (cl-rem -7 2) (% -7 2)))
```

运行结果：

```
  cl-floor 7 2 → (3 1)；-7 2 → (-4 1)（商向 -∞ 取整）
  cl-ceiling 7 2 → (4 -1)（商向 +∞ 取整，余数 ≤ 0）
  cl-truncate -7 2 → (-3 -1)（商向 0 取整）
  cl-round 平局靠偶：5 2 → (2 1)；7 2 → (4 -1)
  单参浮点：(cl-floor -2.5) → (-3 0.5)（首值是整数、余值是浮点）
  cl-mod ≡ cl-floor 第二值 → 1；cl-rem ≡ cl-truncate 第二值 → -1；原生 % → -1
```

逐点读：

**取整方向是唯一要记住的差异。** `cl-floor` 商向 -∞ 取整（`-7/2` 得 `-4`），余数与除数同号（得 `1`）；`cl-ceiling` 向 +∞（得 `4`），余数 ≤ 0；`cl-truncate` 向 0（得 `-3`），余数与被除数同号（`-1`）；`cl-round` 四舍五入、**平局靠偶**——`5/2=2.5` 收到 `2`（偶），`7/2=3.5` 收到 `4`（偶）。四种都保证恒等式 `q*y+r=x`。

**单参数等价于除以 1，且支持浮点输入。** `(cl-floor -2.5)` 得 `(-3 0.5)`：首值是整数、余值保持浮点类型。`cl-floor x` ≡ `cl-floor x 1`。

**`cl-mod` / `cl-rem` 各取一个余数语义。** `cl-mod` 是 `cl-floor` 的余数（与除数同号，`-7` mod `2` 得 `1`），`cl-rem` 是 `cl-truncate` 的余数（与被除数同号，得 `-1`）——原生 `%` 与 `cl-rem` 一致。负数取模想要非负结果时用 `cl-mod`，这是它存在的全部理由。

## 48.6 `cl-parse-integer`

同样出自手册 9.2：比 `string-to-number` 严格的整数解析器。示例第 6 节：

示例第 6 节：

```elisp
(princ (format "  十进制直取 → %S；:radix 16 → %S；空白忽略 → %S\n"
               (cl-parse-integer "42")
               (cl-parse-integer "ff" :radix 16)
               (cl-parse-integer "  42  ")))
(princ (format "  :start/:end 窗口 → %S\n"
               (cl-parse-integer "xx42yy" :start 2 :end 4)))
(princ (format "  垃圾默认报错 → %S\n"
               (condition-case err
                   (cl-parse-integer "42junk")
                 (error (error-message-string err)))))
(princ (format "  :junk-allowed t 容忍尾部 → %S；全非数字 → %S\n"
               (cl-parse-integer "42junk" :junk-allowed t)
               (cl-parse-integer "junk" :junk-allowed t)))
```

运行结果：

```
  十进制直取 → 42；:radix 16 → 255；空白忽略 → 42
  :start/:end 窗口 → 42
  垃圾默认报错 → "Not an integer string: ‘42junk’"
  :junk-allowed t 容忍尾部 → 42；全非数字 → nil
```

逐点读：

**默认行为：跳过首尾空白、整串必须是合法整数。** `"  42  "` 得 `42`；`"42junk"` 直接报错 `Not an integer string: ‘42junk’`（31.1 的错误串用弯引号包裹原文）。

**三个关键字各管一件事。** `:radix` 换进制（2–36）；`:start`/`:end` 划子串窗口（含头不含尾），`"xx42yy"` 的 2 到 4 正是 `"42"`；`:junk-allowed t` 容忍尾部垃圾（解析到哪儿算哪儿，`"42junk"` 得 `42`），且解析不出任何数字时返回 `nil` 而不是报错——容错场景全靠它。

## 48.7 随机数：`cl-random` 与 `cl-make-random-state`

手册 9.3（Random Numbers）的 `cl-random` 与原生 `random` 同源，但配套的 `cl-make-random-state` 给 Emacs 带来了**显式随机状态**——可复现性的关键。示例第 7 节：

示例第 7 节：

```elisp
(let ((s (cl-make-random-state 42)))
  (princ (format "  种子 42（Emacs 扩展：整数直接当种子）前三发 → %S %S %S\n"
                 (cl-random 100 s) (cl-random 100 s) (cl-random 100 s))))
(let ((s1 (cl-make-random-state 7))
      (s2 (cl-make-random-state 7)))
  (princ (format "  同种子两个 state 序列相同 → %S vs %S\n"
                 (cl-random 1000 s1) (cl-random 1000 s2))))
(let ((s (cl-make-random-state 1)))
  (princ (format "  (cl-random 1.0 s) 返回同类型：[0,1) 的浮点 → %S\n"
                 (cl-random 1.0 s))))
(princ (format "  cl-random-state-p → %S / %S\n"
               (cl-random-state-p (cl-make-random-state))
               (cl-random-state-p 'nope)))
```

运行结果：

```
  种子 42（Emacs 扩展：整数直接当种子）前三发 → 51 82 73
  同种子两个 state 序列相同 → 28 vs 28
  (cl-random 1.0 s) 返回同类型：[0,1) 的浮点 → 0.619882345199585
  cl-random-state-p → t / nil
```

逐点读：

**整数种子是 Emacs 对 CL 的扩展。** CL 的 `make-random-state` 只接受 `nil`（拷贝当前状态）或 `t`（随机初始化）；Emacs 额外允许直接传整数当种子——`42` 的前三发固定为 `51 82 73`，同种子的两个 state 产出完全相同的序列（`28 vs 28`）。这就是可复现实验的全部秘诀。

**`cl-random` 的上界参数决定返回类型。** 上界是整数 `n` 返回 `[0, n)` 的整数；上界是浮点（如 `1.0`）返回同类型浮点 `[0, 1.0)`。

**省略 state 用的是全局 `cl--random-state`。** 多段代码交错调用会互相影响、不可复现；要可复现就显式造 state。手册还点明 state 对象**可打印、可 `read`**——调试时用 `(cl-make-random-state t)` 取时间种子后把 state 存盘，事后能精确重放。`cl-random-state-p` 是谓词。

## 48.8 浮点常量：`cl-float-limits` 一族

手册 9.4（Float Parameters）定义了一套描述浮点格式的常量。Emacs 只有 IEEE binary64 一种浮点，所以只有一套值；且**必须先调用 `(cl-float-limits)` 初始化**，否则这些变量的值未指定。示例第 8 节：

示例第 8 节：

```elisp
(cl-float-limits)
(princ (format "  cl-most-positive-float → %S\n" cl-most-positive-float))
(princ (format "  cl-least-positive-float（次正规最小正数）→ %S\n"
               cl-least-positive-float))
(princ (format "  cl-least-positive-normalized-float → %S\n"
               cl-least-positive-normalized-float))
(princ (format "  cl-float-epsilon → %S\n" cl-float-epsilon))
(princ (format "  1.0 + epsilon ≠ 1.0：%S；1.0 + epsilon/2 ≡ 1.0：%S\n"
               (= 1.0 (+ 1.0 cl-float-epsilon))
               (= 1.0 (+ 1.0 (/ cl-float-epsilon 2)))))
```

运行结果：

```
  cl-most-positive-float → 1.7976931348623157e+308
  cl-least-positive-float（次正规最小正数）→ 5e-324
  cl-least-positive-normalized-float → 2.2250738585072014e-308
  cl-float-epsilon → 2.220446049250313e-16
  1.0 + epsilon ≠ 1.0：nil；1.0 + epsilon/2 ≡ 1.0：t
```

逐点读：

**四个常量各描述 binary64 的一条边界。** 最大有限值约 `1.8e308`；最小正数 `5e-324` 是次正规（denormalized）数；最小**正规**正数约 `2.2e-308`——两者之间是精度逐渐损失的次正规地带。配套的 `cl-most-negative-float`、`cl-least-negative-float` 等同名取负，手册列表里都有。

**`cl-float-epsilon` 是「1.0 与比它大的下一个浮点数之差」。** 实测 `1.0 + epsilon` 真的大于 `1.0`（`=` 答 `nil`），而 `1.0 + epsilon/2` 被舍入回 `1.0`（答 `t`）——它是浮点比较该取多大容差的标尺：比较两个近 1.0 的计算结果，容差至少得是 epsilon 的若干倍。

## 48.9 `cl-defstruct`：基础四件套

手册第 12 章（Structures）是 cl-lib 里使用面最广的一章。`(cl-defstruct person …)` 一次定义出**构造器、复制器、谓词、每个槽的访问子**四件套。示例第 9 节：

示例第 9 节：

```elisp
(cl-defstruct person first-name (age 0) sex)
(let ((birthday-boy (make-person :first-name "Peter" :age 23 :sex "male")))
  (princ (format "  构造（31.1 默认 record 表示）→ %S\n" birthday-boy))
  (princ (format "  缺省槽：age 默认 0、其余 nil → %S\n" (make-person)))
  (princ (format "  访问子 → %S / %S\n"
                 (person-first-name birthday-boy) (person-age birthday-boy)))
  (setf (person-first-name birthday-boy) "Old Peter")
  (cl-incf (person-age birthday-boy))
  (princ (format "  setf + cl-incf 改槽后 → %S\n" birthday-boy))
  (let ((other (copy-person birthday-boy)))
    (princ (format "  copy-person：eq → %S，但槽值 eq → %S\n"
                   (eq birthday-boy other)
                   (eq (person-first-name birthday-boy)
                       (person-first-name other)))))
  (princ (format "  person-p：本尊 %S / 向量 %S / 字符串 %S\n"
                 (person-p birthday-boy) (person-p [1 2 3]) (person-p "Bogus")))
  (princ (format "  伪造 tag 的向量：%S（record 表示下骗不过；旧 vector 实现会中招）\n"
                 (person-p '[cl-struct-person counterfeit person object])))
  (princ (format "  #s 语法可 read 回来：%S\n"
                 (person-p (car (read-from-string
                                 (prin1-to-string birthday-boy))))))
  (princ (format "  cl-typep 认结构类型（靠 person-p）→ %S\n"
                 (cl-typep birthday-boy 'person))))
```

运行结果：

```
  构造（31.1 默认 record 表示）→ #s(person "Peter" 23 "male")
  缺省槽：age 默认 0、其余 nil → #s(person nil 0 nil)
  访问子 → "Peter" / 23
  setf + cl-incf 改槽后 → #s(person "Old Peter" 24 "male")
  copy-person：eq → nil，但槽值 eq → t
  person-p：本尊 t / 向量 nil / 字符串 nil
  伪造 tag 的向量：nil（record 表示下骗不过；旧 vector 实现会中招）
  #s 语法可 read 回来：t
  cl-typep 认结构类型（靠 person-p）→ t
```

逐点读：

**31.1 默认 record 表示，打印成 `#s(类型名 槽值…)`。** 构造器 `make-person` 按关键字给槽赋初值，槽定义 `(age 0)` 里的 `0` 是缺省值，没写缺省值的槽默认 `nil`。访问子 `person-first-name` 等是**可 `setf` 的广义变量**，`cl-incf` 之类就地修改宏直接可用。

**复制器是浅拷贝。** `copy-person` 返回新对象（`eq` 答 `nil`），但槽值本身不复制——新旧对象的同名槽值仍是 `eq` 的（答 `t`）。改槽值对象会互相看见，改槽本身（`setf`）不会。

**谓词 `person-p` 在 record 表示下是防伪的。** 普通向量、字符串都答 `nil`；关键是手工伪造 tag 的向量 `[cl-struct-person …]` 也答 `nil`——record 类型有真正的类型身份，不靠首元素认亲。手册里印的 `[cl-struct-person …]` 式输出是**旧 vector 实现**时代的产物，那个实现下伪造向量能骗过谓词；31.1 不会。

**`#s` 打印形式可 `read` 回来。** `(read-from-string (prin1-to-string …))` 得到一个 `person-p` 认可的对象——结构因此天然可序列化，配置文件、持久化缓存里直接写 `#s` 形式即可。

**结构类型无缝接入类型系统。** `cl-typep` 靠 `类型名-p` 谓词识别结构（48.1 的机制），`(cl-typep birthday-boy 'person)` 答 `t`；`cl-typecase` 的分支键同样能用结构名。

## 48.10 `cl-defstruct`：选项与内省

结构的定制项全部写在 `(cl-defstruct (名 (选项…)) …)` 的头部列表里。示例第 10 节集中演示：

示例第 10 节：

```elisp
(cl-defstruct (employee (:conc-name emp-)
                        (:constructor create-employee
                                      (name &optional (age 30))))
  name (age 0))
(let ((e (create-employee "Jane")))
  (princ (format "  BOA 构造器（位置参数）+ :conc-name → %S，年龄 %S\n"
                 e (emp-age e))))
(cl-defstruct point (x 0 :read-only t) (y 0))
(let ((p (make-point :x 1 :y 2)))
  (setf (point-y p) 9)
  (princ (format "  :read-only 槽：x 只能读（%S），y 可改 → %S\n" (point-x p) p)))
(cl-defstruct (astronaut (:include person (age 45)))
  helmet-size (favorite-beverage 'tang))
(let ((joe (make-person :first-name "Joe"))
      (buzz (make-astronaut :first-name "Buzz")))
  (princ (format "  :include 继承槽并覆盖默认 → %S\n" buzz))
  (princ (format "  astronaut 也是 person：%S；person 不是 astronaut：%S\n"
                 (person-p buzz) (astronaut-p joe)))
  (princ (format "  父访问子用于子类 → %S；子访问子用于父类报错 → %S\n"
                 (person-first-name buzz)
                 (condition-case err
                     (astronaut-first-name joe)
                   (error (error-message-string err))))))
(cl-defstruct (pet (:type list) :named) name)
(princ (format "  (:type list) :named 用列表表示、tag 在首位 → %S\n" (make-pet)))
(princ (format "  内省：sequence-type → %S；slot-offset age → %S\n"
               (cl-struct-sequence-type 'person)
               (cl-struct-slot-offset 'person 'age)))
(let ((b (make-person :first-name "Abe" :age 50)))
  (princ (format "  slot-info → %S\n"
                 (mapcar #'car (cl-struct-slot-info 'person))))
  (princ (format "  cl-struct-slot-value 读 → %S；" (cl-struct-slot-value 'person 'age b)))
  (setf (cl-struct-slot-value 'person 'age b) 51)
  (princ (format "setf 后 → %S\n" (person-age b))))
```

运行结果：

```
  BOA 构造器（位置参数）+ :conc-name → #s(employee "Jane" 30)，年龄 30
  :read-only 槽：x 只能读（1），y 可改 → #s(point 1 9)
  :include 继承槽并覆盖默认 → #s(astronaut "Buzz" 45 nil nil tang)
  astronaut 也是 person：t；person 不是 astronaut：nil
  父访问子用于子类 → "Buzz"；子访问子用于父类报错 → "Wrong type argument: astronaut, #s(person \"Joe\" 0 nil)"
  (:type list) :named 用列表表示、tag 在首位 → (pet nil)
  内省：sequence-type → nil；slot-offset age → 2
  slot-info → (cl-tag-slot first-name age sex)
  cl-struct-slot-value 读 → 50；setf 后 → 51
```

逐点读：

**`:conc-name` 改访问子前缀，`:constructor` 可换成 BOA（By Order of Arguments）风格。** `create-employee` 按位置传参，`"Jane"` 给 `name`，`(age 30)` 让省略时取 `30`——适合槽少且顺序稳定的场合；默认的关键字构造器 `make-名` 照样存在除非显式关掉。

**`:read-only t` 的槽只能读，且 31.1 在字节编译期就拦截。** 这是示例刻意**不放在代码里**的一条：写 `(setf (point-x p) 9)` 会让 `byte-compile-file` 直接报 `Error: point-x is a read-only slot`（实测编译输出原文），根本轮不到运行。只读槽的值只能在构造时给。

**`:include` 是「很有限的继承」。** `astronaut` 继承 `person` 的全部槽，并用 `(age 45)` 覆盖父槽缺省值；打印形式里父槽在前、子槽在后。父谓词认子对象（`person-p buzz` 得 `t`），反之不然；父访问子可用于子对象（`person-first-name buzz` 得 `"Buzz"`），但**子访问子不能用于父对象**——`astronaut-first-name` 作用在普通 `person` 上报 `Wrong type argument: astronaut, …`，因为子类访问子带类型检查（优化级别 `safety` 调低时这类检查可能消失，手册提醒别依赖它报错）。

**`:type list` / `:type vector` 换回朴素表示，`:named` 保留 tag。** `(make-pet)` 得到普通列表 `(pet nil)`：首元素是 tag、其余是槽值。`:named` 让谓词仍能工作；`:initial-offset` 还能在 tag 前留空位。没有 `:named` 的 `:type` 结构干脆没有谓词可言。

**四个内省函数在运行时查询结构定义。** `cl-struct-sequence-type` 答表示类型（record 表示下答 `nil`——它不是「序列」）；`cl-struct-slot-offset` 答槽的下标（`age` 在 tag 之后的第 2 位）；`cl-struct-slot-info` 答全部槽的描述列表，首项是 `cl-tag-slot`；`cl-struct-slot-value` 按名读槽、可 `setf`——写「按字符串/符号动态访问槽」的通用代码（如序列化库）就靠它。其余选项 `:copier`/`:predicate`/`:noinline` 改名或禁用对应设施；`:print-function` 在 31.1 被**忽略**——想定制打印请用下一节的 `cl-print-object`。

## 48.11 `cl-print`：面向人类读者的打印

手册第 2 章（Printing）对应的是独立的 `cl-print` 包（`(require 'cl-print)`）：一套**用 `cl-defgeneric`/`cl-defmethod` 组织的打印系统**，让自定义类型能控制自己的打印形式。示例第 11 节：

示例第 11 节：

```elisp
(let ((b (make-person :first-name "Peter" :age 23 :sex "male")))
  (princ (format "  cl-prin1-to-string 结构 → %S\n" (cl-prin1-to-string b)))
  (princ (format "  原生 prin1-to-string 对照 → %S\n" (prin1-to-string b)))
  (princ (format "  cl-print-string-length=4 缩略 → %S\n"
                 (let ((cl-print-string-length 4))
                   (cl-prin1-to-string "hello world"))))
  (princ (format "  cl-print-to-string-with-limit 8 字符内 → %S\n"
                 (cl-print-to-string-with-limit #'cl-prin1 '(1 2 3 4 5) 8))))
(cl-defstruct city name (population 0))
(cl-defmethod cl-print-object ((c city) stream)
  (princ (format "#<city %s pop %d>" (city-name c) (city-population c)) stream))
(let ((c (make-city :name "Paris" :population 2100000)))
  (princ (format "  自定义 cl-print-object 后 cl-prin1 → %S\n" (cl-prin1-to-string c)))
  (princ (format "  原生 prin1 不走泛型，仍按 record 打印 → %S\n" (prin1-to-string c))))
```

运行结果：

```
  cl-prin1-to-string 结构 → "#s(person :first-name \"Peter\" :age 23 :sex \"male\")"
  原生 prin1-to-string 对照 → "#s(person \"Peter\" 23 \"male\")"
  cl-print-string-length=4 缩略 → #("\"hell...\"" 5 8 (category cl-print-ellipsis-button button (t) cl-print-ellipsis ("hello world" 4 nil ("hello world"))))
  cl-print-to-string-with-limit 8 字符内 → "(1 2 3 4 5)"
  自定义 cl-print-object 后 cl-prin1 → "#<city Paris pop 2100000>"
  原生 prin1 不走泛型，仍按 record 打印 → "#s(city \"Paris\" 2100000)"
```

逐点读：

**`cl-prin1-to-string` 打印结构时带槽名关键字。** 对照原生 `prin1-to-string` 的纯位置形式，`#s(person :first-name "Peter" :age 23 :sex "male")` 一眼可读——这正是 cl-print 包的设计目标：打印给**人**看。

**`cl-print-string-length` 给长字符串加省略号。** 绑定为 `4` 时 `"hello world"` 缩成 `"hell..."`；实测打印值带着一串 text properties（`cl-print-ellipsis-button` 等）——在缓冲区里这个省略号是个**可点击按钮**，点开能展开全文。为了让按钮有内容可展开，用了省略号的对象应配套写 `cl-print-object-contents` 方法（手册原话，示例文本行有注）。

**`cl-print-to-string-with-limit` 尝试在限定字符数内打印。** 给 `8` 字符的限额打印 `(1 2 3 4 5)`——实测结果仍打出了全部 11 个字符：限额是「尽量压缩」的预算而非硬截断，元素本身省不出空间时就原样输出。

**定制打印 = 给 `cl-print-object` 写方法。** `cl-print-object` 是 `cl-defgeneric` 定义的泛型函数，`(cl-defmethod cl-print-object ((c city) stream) …)` 用结构名做特化——这是 `cl-defmethod` 特化器吃结构类型的标准用法。定义之后 `cl-prin1` 族全部走新形式（`#<city Paris pop 2100000>`，按惯例不可 `read` 的形式用 `#<…>`）；**原生 `prin1` 不走泛型**，仍按 record 默认形式打印——两个打印系统互不干扰。

## 48.12 断言：`cl-assert` 与 `cl-check-type`

手册第 13 章（Assertions and Errors）给两个宏：`cl-assert` 断表达式、`cl-check-type` 断类型。示例第 12 节：

示例第 12 节：

```elisp
(princ (format "  cl-assert 通过返回 nil → %S\n" (cl-assert (> 3 2))))
(princ (format "  失败报错含测试式 → %S\n"
               (condition-case err
                   (cl-assert (> 2 3))
                 (error (error-message-string err)))))
(let ((x 5))
  (princ (format "  show-args=t 附带实参值 → %S\n"
                 (condition-case err
                     (cl-assert (> x 10) t "x is too small")
                   (error (error-message-string err))))))
(let ((n 5) (f 1.5))
  (princ (format "  cl-check-type 通过返回 nil → %S\n" (cl-check-type n integer)))
  (princ (format "  失败抛 wrong-type-argument → %S\n"
                 (condition-case err
                     (cl-check-type f integer)
                   (error (error-message-string err))))))
(let ((x 0))
  (princ (format "  自定义串代替类型名 → %S\n"
                 (condition-case err
                     (cl-check-type x (integer 1 *) "a positive integer")
                   (error (error-message-string err))))))
```

运行结果：

```
  cl-assert 通过返回 nil → nil
  失败报错含测试式 → "Assertion failed: (> 2 3)"
  show-args=t 附带实参值 → "x is too small"
  cl-check-type 通过返回 nil → nil
  失败抛 wrong-type-argument → "Wrong type argument: integer, 1.5, f"
  自定义串代替类型名 → "Wrong type argument: \"a positive integer\", 0, x"
```

逐点读：

**`cl-assert` 通过时返回 `nil`，失败时报 `Assertion failed: (> 2 3)`**——错误消息自动带上测试式原文。第二参数 `show-args` 传非 `nil` 时，按手册应附带实参值；31.1 实测 `error-message-string`（连 error 的 data 一起）只给出消息串本身，所以示例把要展示的值直接写进消息串（`"x is too small"` 这类自定义消息跟在 `show-args` 之后）——想让错误消息有用，自己把关键值 format 进去最保险。

**`cl-check-type` 的类型实参不求值——这是 31.1 实测踩出来的坑。** 写成 `(cl-check-type x integer)`、`(cl-check-type x (integer 1 *))`，**不要加引号**。加成 `'integer` 后宏把 `(quote integer)` 当成了类型说明符，字节编译期 `cl-typep--inliner` 就报 `Optimization failure … Bad type spec: 'integer`。另外首参按 CL 惯例应是个 place（变量、访问子之类），直接传字面量常量同样会触发这条编译器警告——示例因此先 `let` 绑定再检查。

**失败时抛的是标准 `wrong-type-argument`。** 消息三段式：期望类型、实际值、place 名——`Wrong type argument: integer, 1.5, f` 里 `f` 就是变量名。给了自定义串（`"a positive integer"`）时串顶替类型名出现在第一段。因为是标准错误符号，既有的 `condition-case` 处理 `wrong-type-argument` 的代码直接兼容。

**断言只做健全性检查。** 字节编译器在 `speed=3` 且 `safety<3` 时会把 `cl-assert`、`cl-check-type` 整个优化掉——断言里千万别放副作用（`(cl-assert (setq …))` 这种写法在优化后行为完全不同）。CL 里 `check-type` 的失败是可续错误（交互修值后继续），Emacs 没有可续错误概念，失败就是普通错误。

## 48.13 小结：一张表

| 主题 | 函数 / 宏 | 一句话备忘 |
| --- | --- | --- |
| 类型判定 | `cl-typep` / `cl-coerce` | 类型说明符=符号或符号开头的列表；`(integer 0 (5))` 排他上界字面量会触发 inliner 警告，绑变量绕开 |
| 派生类型 | `cl-deftype` | 像 defmacro 展开成等价说明符；`&optional` 默认 `*`；可作方法特化但排序未定义 |
| 宽松相等 | `cl-equalp` | 字符串大小写不敏感、数字跨类型；字符串不与整数向量比（与 CL 差异） |
| 数字小函数 | `cl-digit-char-p` / `cl-gcd` / `cl-lcm` / `cl-isqrt` | digit-char-p 返回数字值；gcd 零参 0、lcm 零参 1 |
| 整除家族 | `cl-floor` / `cl-ceiling` / `cl-truncate` / `cl-round` / `cl-mod` / `cl-rem` | 返回 (商 余数) 列表；负数取模要非负用 cl-mod；cl-round 平局靠偶 |
| 整数解析 | `cl-parse-integer` | `:radix`/`:start`/`:end`/`:junk-allowed`；默认遇垃圾报错 |
| 随机数 | `cl-random` / `cl-make-random-state` / `cl-random-state-p` | 整数种子是 Emacs 扩展；state 可打印可 read，显式 state 才可复现 |
| 浮点常量 | `cl-float-limits` + `cl-most-positive-float` 等 | 先调 cl-float-limits 初始化；epsilon 是浮点容差的标尺 |
| 结构 | `cl-defstruct` / `make-名` / `copy-名` / `名-p` / `名-槽` | 31.1 默认 record 表示（#s 可 read、伪造向量骗不过谓词）；复制器是浅拷贝 |
| 结构选项 | `:conc-name` / `:constructor` / `:read-only` / `:include` / `:type` / `:named` | 只读槽 setf 编译期报错；:include 父谓词认子对象；:print-function 被忽略 |
| 结构内省 | `cl-struct-sequence-type` / `cl-struct-slot-offset` / `cl-struct-slot-info` / `cl-struct-slot-value` | slot-value 按名动态读写槽，可 setf |
| 打印 | `cl-prin1-to-string` / `cl-print-object` / `cl-print-string-length` / `cl-print-to-string-with-limit` | cl-print 打印结构带槽名；定制打印写 cl-defmethod；原生 prin1 不走泛型 |
| 断言 | `cl-assert` / `cl-check-type` | check-type 类型实参不求值（别加引号）；speed=3 且 safety<3 时被优化掉，禁放副作用 |

三条 31.1 实测要点，再强调一遍：`cl-defstruct` 的 record 表示让结构打印可 `read`、谓词防伪——手册里 `[cl-struct-person …]` 的旧输出已成历史；字节编译器比你想的更勤快——只读槽的 `setf`、`cl-check-type` 加引号的类型实参、`cl-typep` 的排他上界字面量，全都在**编译期**现形，跑 `run-all.sh` 时警告即失败，这些坑躲无可躲；断言是调试期的脚手架，`speed=3`/`safety<3` 下会被优化掉，正式逻辑永远不要押在断言上。

至此第 11 部分讲完：41–43 章的宏与编译期设施、44 章的广义变量、45 章的作用域与控制流、46 章的 `cl-loop`、47 章的序列与列表、本章的类型/结构/断言/打印——cl-lib 的全貌已经展开。附录 A 把散落在各章的「实测坑」集中成一份速查表，写代码前翻一遍能省不少编译器警告。

上一章：[47 · 序列与列表：cl-map、cl-reduce 与列表构造](47-sequences-lists.md)　｜　下一章：[附录 A · 常见坑速查](appendix-a-pitfalls.md)　｜　返回：[Emacs 扩展开发指南](README.md)
