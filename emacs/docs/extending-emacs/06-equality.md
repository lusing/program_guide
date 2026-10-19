# 06 · 相等性：eq / eql / = / equal

> 所属部分：第 1 部分 · 语言基础
>
> 示例：`examples/06-equality.el`

「比较」在 Elisp 里拆成了四个函数。选错**不会报错**，只会静默给出错误结果——本章把这些函数的边界逐个划清楚。所有输出都是示例真跑出来的。

## 6.1 eq：比「是不是同一个对象」

`eq` 最严格也最快：两个参数是不是**同一个内存对象**。符号、`nil`、`t`、字符（它们就是小整数）在 Emacs 里是唯一对象或立即值，`eq` 判断全部正确：

```elisp
(princ (format "eq 'a 'a = %S,  eq nil nil = %S,  eq 1 1 = %S\n"
               (eq 'a 'a) (eq nil nil) (eq 1 1)))
```

```
eq 'a 'a = t,  eq nil nil = t,  eq 1 1 = t
```

但对**浮点、字符串、列表、bignum** 这些「每次求值都造出新对象」的值，`eq` 一律为假：

```elisp
(let ((a (+ 0.5 0.5)) (b (+ 1.0 0.0)))
  (princ (format "eq 两个不同的 1.0 = %S\n" (eq a b))))
(let ((a "abc") (b (copy-sequence "abc")))
  (princ (format "eq 两个内容相同的字符串 = %S，equal = %S\n"
                 (eq a b) (equal a b))))
(princ (format "eq (list 1) (list 1) = %S  <- 两个不同的 cons\n"
               (eq (list 1) (list 1))))
```

```
eq 两个不同的 1.0 = nil
eq 两个内容相同的字符串 = nil，equal = t
eq (list 1) (list 1) = nil  <- 两个不同的 cons
```

> 演示时特意把字面量绑到变量上再比。直接写 `(eq 1.0 1.0)` 的话，Emacs 31 的字节编译器会直接抓住：
>
> ```text
> Warning: 'eq' called with literal float that may never match (arg 1)
> ```
>
> 编译器知道「两个字面量浮点 `eq` 永远为假」，主动警告。这条本身就是「`eq` 不用在浮点上」的最好证据。

## 6.2 eql：eq 加上「数值相同且类型相同」

`eql` 修好了浮点的数值比较，但仍然要求类型一致：

```elisp
(princ (format "eql 1.0 1.0 = %S,  eql 1 1.0 = %S,  (= 1 1.0) = %S\n"
               (eql 1.0 1.0) (eql 1 1.0) (= 1 1.0)))
(princ (format "eql -0.0 0.0 = %S,  (= -0.0 0.0) = %S\n"
               (eql -0.0 0.0) (= -0.0 0.0)))
```

```
eql 1.0 1.0 = t,  eql 1 1.0 = nil,  (= 1 1.0) = t
eql -0.0 0.0 = nil,  (= -0.0 0.0) = t
```

`(eql 1 1.0)` 是 `nil`——1 是整数、1.0 是浮点，类型不同。更刁钻的是 `-0.0` 和 `0.0`：数值相等，但符号位不同，`eql` 认为不等，`=` 认为相等。`eql` 是「哈希键语义」的默认选择：`cl-case`、`make-hash-table` 的默认 `:test 'eq` 旁边的 `eql`，都用它。

### bignum 与 eq 的坑

超过 `most-positive-fixnum` 的整数是**独立分配的大整数对象**，两个内容相同的大整数 `eq` 为假：

```elisp
(let ((a (expt 2 70)) (b (expt 2 70)))
  (princ (format "bignum: eq=%S eql=%S equal=%S\n" (eq a b) (eql a b) (equal a b))))
```

```
bignum: eq=nil eql=t equal=t
```

实际影响：**用 `:test 'eq` 的哈希表存放大整数键会「查不到刚放进去的键」**（每次放进去的都是新对象）。存整数的哈希表要么用 `:test 'eql`，要么确保键都是 fixnum。

## 6.3 =：只比数

```elisp
(princ (format "= 3 3.0 = %S\n" (= 3 3.0)))
```

```
= 3 3.0 = t
```

`=` 只接受数字，会做类型提升。**比数字一律用 `=`**，不要用 `eq`/`eql`。喂非数字会报 `wrong-type-argument`——这其实是好事：错误当场暴露，而不是像 `eq` 那样默默返回 `nil`。

## 6.4 equal：递归比结构（日常最常用）

```elisp
(princ (format "equal \"aa\" (concat \"a\" \"a\") = %S\n"
               (equal "aa" (concat "a" "a"))))
(princ (format "equal (list 1 2) (list 1 2) = %S\n" (equal (list 1 2) (list 1 2))))
(princ (format "equal '(1 (2)) '(1 (2)) = %S\n" (equal '(1 (2)) '(1 (2)))))
```

```
equal "aa" (concat "a" "a") = t
equal (list 1 2) (list 1 2) = t
equal '(1 (2)) '(1 (2)) = t
```

`equal` 递归比较结构：字符串比内容，列表逐元素比，嵌套列表递归下去，数字按数值比（整数和浮点内容相同也相等）。**日常判断两个值「是不是一样」，默认就用 `equal`**——它是正确性优先的选择，慢一点但不会骗你。

## 6.5 equal 会忽略文本属性

```elisp
(let ((plain "abc")
      (fancy (propertize "abc" 'face 'bold)))
  (princ (format "equal = %S, equal-including-properties = %S\n"
                 (equal plain fancy)
                 (equal-including-properties plain fancy))))
```

```
equal = t, equal-including-properties = nil
```

一个带 face 属性的字符串和同内容无属性的字符串，`equal` 认为相等（属性不属于「内容」），`equal-including-properties` 认为不等。文本属性的完整讨论在第 11 章。

## 6.6 字符串专用比较

```elisp
(princ (format "string-equal \"a\" \"A\" = %S\n" (string-equal "a" "A")))
(princ (format "compare-strings 忽略大小写 = %S\n"
               (compare-strings "abc" 0 3 "ABC" 0 3 t)))
```

```
string-equal "a" "A" = nil
compare-strings 忽略大小写 = t
```

- `string-equal`（别名 `string=`）：比内容，**区分大小写**；
- `string-prefix-p` / `string-suffix-p`：判前后缀（注意参数顺序是「前缀, 字符串」）；
- `compare-strings`：可以只比两个字符串的片段（起止下标），第五个参数传 `t` 忽略大小写；
- `string-collate-lessp`：按本地化（locale）顺序比较，排序中文/多语言文本时用第 8 章的 `sort` 搭它。

## 6.7 【重点】查找函数的默认比较方式各不相同

这是本章最实用的一节。同样是「查一个 key」，不同函数默认用的比较函数不一样，选错了**静默查不到**，连错误都不报：

```elisp
(defvar demo-alist (list (cons "name" "emacs") (cons "ver" "31")))
(let ((k "name"))
  (princ (format "assoc  (equal)   找到: %S\n" (assoc k demo-alist)))
  (princ (format "assq   (eq)    找不到: %S\n" (assq k demo-alist)))
  (princ (format "alist-get 默认 eq    -> %S\n" (alist-get k demo-alist)))
  (princ (format "alist-get 传 equal   -> %S\n"
                 (alist-get k demo-alist nil nil #'equal))))
```

```
assoc  (equal)   找到: ("name" . "emacs")
assq   (eq)    找不到: nil
alist-get 默认 eq    -> nil
alist-get 传 equal   -> "emacs"
```

| 函数 | 默认比较 | 备注 |
|---|---|---|
| `assoc` | `equal` | 字符串 key 用它 |
| `assq` | `eq` | 只适合符号/字符/fixnum key |
| `member` | `equal` | `memq` 则是 `eq` |
| `alist-get` | `eq` | 第 5 个参数可传自定义比较函数 |
| `cl-find` / `seq-contains-p` | `eql` | 可传 `:test` 覆盖 |

**所以：字符串做 key 的 alist，查值必须用 `assoc`，或者 `(alist-get k alist nil nil #'equal)`；用 `assq` 或默认的 `alist-get` 会永远返回 `nil`。** 这个坑极常见，而且因为不报错，能藏很久。

## 6.8 排序要用比较函数，不是相等函数

```elisp
(princ (format "sort 数字: %S\n" (sort (list 3 1 2) #'<)))
(princ (format "sort 字符串: %S\n" (sort (list "b" "a") #'string<)))
(princ (format "非破坏的 seq-sort: %S\n" (seq-sort #'< (list 3 1 2))))
```

```
sort 数字: (1 2 3)
sort 字符串: ("a" "b")
非破坏的 seq-sort: (1 2 3)
```

`sort` 接受的是「小于」谓词，不是相等谓词。三个常用谓词：`<`（数字）、`string<`（字符串，按码位）、`string-collate-lessp`（按本地化顺序，中文场景选它）。

`sort` 是**破坏性的**：它就地重排传进去的那个列表，返回值也是同一个列表（被排好序的）。喂字面量常量列表还会被编译器警告（常量不该被改）。要保留原列表，先 `copy-sequence`，或者直接用非破坏的 `seq-sort`（第 9 章）。

## 6.9 本章小结

| 想干什么 | 用什么 |
|---|---|
| 比「同一对象」（符号、字符、fixnum） | `eq` |
| 比数字（含整数/浮点混比） | `=` |
| 比数值且类型一致（哈希键语义） | `eql` |
| 比「内容一样」（日常默认） | `equal` |
| 比内容且含文本属性 | `equal-including-properties` |
| 字符串 key 查 alist | `assoc`（或 `alist-get` 第 5 参传 `#'equal`） |

一条记忆线：**`eq` 比箭头，`equal` 比内容**（第 27 章会从 cons 内存模型再证明一次）。

---

上一章：[05 · 控制流](05-control-flow.md)　｜　下一章：[07 · 列表与关联结构](07-lists.md)　｜　返回：[Emacs 扩展开发指南](README.md)
