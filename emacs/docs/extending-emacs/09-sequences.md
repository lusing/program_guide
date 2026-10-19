# 09 · 序列与 cl-lib

> 所属部分：第 1 部分 · 语言基础

> 示例：`examples/09-sequences.el`

## 9.1 seq.el：一套函数吃三种序列

`seq.el` 的杀手锏是**同一套函数能作用于 list、vector、string**，不用为每种类型记不同的函数名：

```elisp
(seq-map #'1+ '(1 2 3))      ; → (2 3 4)    列表
(seq-map #'1+ [1 2 3])       ; → (2 3 4)    输入是 vector，输出仍是列表！
(seq-filter (lambda (c) (= c ?a)) "aaa")  ; → (97 97 97)  字符串进去，字符列表出来
```

```
seq-map list:   (2 3 4)
seq-map vector: (2 3 4)
seq-filter string: (97 97 97)
```

> 【坑】**`seq-map` 永远返回列表**，即使输入是 vector 或字符串（源码里就是 `mapcar` +
> `nreverse`）。想要保持类型的映射，用 `seq-map` 之后自己 `apply #'vector`，或者干脆
> 用 `cl-map` 指定结果类型。

## 9.2 常用 seq-* 一览

```
seq-remove: (1 3)
seq-reduce: 10
seq-sort: (3 2 1)
seq-uniq: (1 2 3)
seq-position: 2
seq-contains-p: t
seq-elt / seq-length: 20 / 3
seq-take / seq-drop: (1 2) / (3 4)
seq-group-by 奇偶: ((nil 1 3) (t 2 4))
seq-do 累加: 6
```

几个特别有用的：

- `seq-take` / `seq-drop`：取前 n 个 / 丢掉前 n 个；
- `seq-group-by`：按某个函数分组，返回 alist（上面的例子里 key 是 t/nil，因为用 `cl-oddp` 分组）；
- `seq-uniq`：去重（用 `equal`）；
- `seq-reduce`：折叠，比手写 `while` 干净。

## 9.3 【坑】seq.el 大多是非破坏性的

```
seq-sort 后原列表: (3 1 2)，新列表: (1 2 3)
```

`seq-sort` 返回新序列，**原列表不动** —— 这正好和 `sort` 相反（第 6.8 节）。
两个函数名这么像，语义相反，是很容易混的一对。记法：`seq-*` 一律安全，不带前缀的 `sort` /
`delete` / `nconc` 一律破坏性。

## 9.4 cl-loop：功能最强的循环

`cl-lib` 的 `cl-loop` 是 Common Lisp 的 `loop` 宏，几乎能表达所有遍历需求：

```elisp
(princ (format "cl-loop collect: %S\n" (cl-loop for i from 1 to 5 collect (* i i))))
(princ (format "cl-loop 带条件: %S\n"
               (cl-loop for i from 1 to 10 when (cl-evenp i) collect i)))
(princ (format "cl-loop sum: %S\n" (cl-loop for x in '(1 2 3) sum x)))
(princ (format "cl-loop 遍历字符串: %S\n"
               (cl-loop for c across "abc" collect (upcase (char-to-string c)))))
(princ (format "cl-loop 多变量: %S\n"
               (cl-loop for a in '(1 2 3) for b in '(10 20 30) collect (+ a b))))
```

```
cl-loop collect: (1 4 9 16 25)
cl-loop 带条件: (2 4 6 8 10)
cl-loop sum: 6
cl-loop 遍历字符串: ("A" "B" "C")
cl-loop 多变量: (11 22 33)
```

注意 `for c across "abc"`：字符串也是序列，遍历得到的是**字符（整数）**，要字符串得自己 `char-to-string`（示例里还套了 `upcase` 让它变成大写）。

常用动词（子句）：

| 子句 | 作用 |
|---|---|
| `for x in list` | 遍历列表 |
| `for i from a to b` | 数值区间 |
| `for x across seq` | 遍历 vector/string |
| `collect x` | 收集成列表 |
| `sum x` / `count x` / `maximize x` | 聚合 |
| `when c` / `unless c` | 过滤 |
| `do x` | 只做副作用 |
| `while` / `until` / `thereis` / `always` | 控制 |

它比 `dolist` + 手工累加干净很多，值得花点时间熟悉。

## 9.5 cl-lib 的其他常用件

```elisp
(let ((n 0))
  (cl-incf n 5)
  (cl-incf n)
  (princ (format "cl-incf 之后 n = %S\n" n)))
```

```
cl-incf 之后 n = 6
```

`cl-incf` / `cl-decf` 是宏，直接改地方——第二个参数是步长，而且**被改的可以是任何 `setf` 能接受的位置**（`(cl-incf (aref v 0))` 修改数组元素）。

`cl-case` / `cl-ecase`（5.7 节讲过 `cl-case`）：`cl-ecase` 在所有分支都没命中时会**报错**，适合处理「理论上不该出现」的值——把静默的 `nil` 变成响亮的错误。

```elisp
(defun demo-kind (x)
  "返回 X 的类型名。"
  (cl-case x
    (:a "A 类")
    (:b "B 类")
    (t "其它")))
(princ (format "cl-case: %S / %S\n" (demo-kind :a) (demo-kind :z)))
```

```
cl-case: "A 类" / "其它"
```

## 9.6 cl-defstruct：带名字的结构

```elisp
(cl-defstruct (demo-point (:constructor demo-point-new (x y)))
  "演示用结构。"
  x y)
(defvar demo-p (demo-point-new 3 4))
(princ (format "结构: %S, x = %S, 判定 = %S\n"
               demo-p (demo-point-x demo-p) (demo-point-p demo-p)))
(cl-incf (demo-point-x demo-p) 10)
(princ (format "setf 风格改字段后: %S\n" demo-p))
(princ (format "copy 出的副本: %S\n" (copy-demo-point demo-p)))
```

```
结构: #s(demo-point 3 4), x = 3, 判定 = t
setf 风格改字段后: #s(demo-point 13 4)
copy 出的副本: #s(demo-point 13 4)
```

`cl-defstruct` 一次定义生成一整套东西：`demo-point-new`（构造器，例子里用 `(:constructor ...)` 自定义成位置参数）、`demo-point-p`（类型判定）、`demo-point-x` / `demo-point-y`（访问器，可用 `cl-incf` / `setf` 改字段）、`copy-demo-point`（拷贝）。不指定 `:constructor` 时，默认生成 `make-demo-point`，用关键字参数调用：`(make-demo-point :x 3 :y 4)`。

它比 alist 更适合「数据结构固定」的场景：有类型判定、有名字、`%S` 打印成可读的 `#s(demo-point 3 4)`（而不是一长串 cons）。

## 9.7 cl-defun 的 &key

参数多了之后 `&optional` 的位置陷阱很痛：想改最后一个参数，得把前面全写出来。
`cl-defun` 的 `&key` 让调用点自解释，还支持默认值：

```elisp
(cl-defun demo-connect (host &key (port 22) (user "root"))
  "演示 &key 参数。"
  (format "%s@%s:%d" user host port))
(princ (format "%S / %S\n" (demo-connect "h1") (demo-connect "h1" :port 80 :user "me")))
```

```
"root@h1:22" / "me@h1:80"
```

代价是每个 `&key` 参数多一点开销，但可读性提升明显，参数超过 3 个就值得用。
另外 `&key` 参数可以配 `:allow-other-keys`，方便转发给别的函数。

## 9.8 cl-letf：临时改写函数或变量

测试里 mock 的标准手段。它和 `let` 的区别是：**`cl-letf` 改的是 place（广义位置）**，
普通变量、结构体访问器、甚至 `symbol-function` 都能临时换掉，退出自动恢复：

```elisp
(princ (format "cl-letf 临时改值: %S\n"
               (let ((demo-p (demo-point-new 1 1)))
                 (cl-letf (((demo-point-x demo-p) 42))
                   (demo-point-x demo-p)))))
```

```
cl-letf 临时改值: 42
```

这里临时把 `demo-point-x` 访问器在 `demo-p` 上的值改成了 42 —— 出来就恢复。
要 mock 整个函数，把 place 写成 `((symbol-function 'some-fn) (lambda ...))` 即可。

它同时能改函数和变量（`(cl-letf (((symbol-function 'f) ...)) ...)` 改函数，
`(cl-letf ((var value)) ...)` 改变量）。第 25 章的测试用的就是这个。

---

上一章：[08 · 字符串与正则](08-strings-regexp.md)　｜　下一章：[10 · buffer 与 point](10-buffers.md)　｜　返回：[Emacs 扩展开发指南](README.md)
