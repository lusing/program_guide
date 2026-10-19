# 09 · 序列与 cl-lib

> 所属部分：第 1 部分 · 语言基础

> 示例：`examples/09-sequences.el`

## 9.1 seq.el：一套函数吃三种序列

`seq.el` 的杀手锏是**同一套函数能作用于 list、vector、string**，不用为每种类型记不同的函数名：

```elisp
(seq-map #'1+ '(1 2 3))      ; → (2 3 4)    列表
(seq-map #'1+ [1 2 3])       ; → [2 3 4]    vector
(seq-filter (lambda (c) (= c ?a)) "aaa")  ; → (97 97 97)  字符串进去，字符列表出来
```

```
seq-map list:   (2 3 4)
seq-map vector: (2 3 4)
seq-filter string: (97 97 97)
```

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

```elisp
seq-sort 后原列表: (3 1 2)，新列表: (1 2 3)
```

`seq-sort` 返回新序列，**原列表不动** —— 这正好和 `sort` 相反（第 6.8 节）。
两个函数名这么像，语义相反，是很容易混的一对。记法：`seq-*` 一律安全，不带前缀的 `sort` /
`delete` / `nconc` 一律破坏性。

## 9.4 cl-loop：功能最强的循环

`cl-lib` 的 `cl-loop` 是 Common Lisp 的 `loop` 宏，几乎能表达所有遍历需求：

```elisp
(cl-loop for i from 1 to 5 collect (* i i))          ; → (1 4 9 16 25)
(cl-loop for i from 1 to 10 when (cl-evenp i) collect i)  ; → (2 4 6 8 10)
(cl-loop for i in '(1 2 3) sum i)                    ; → 6
(cl-loop for c across "abc" collect (char-to-string c))   ; → ("A" "B" "C")
(cl-loop for (a b) in '((1 11) (2 22) (3 33)) collect b)  ; → (11 22 33)
```

```
cl-loop collect: (1 4 9 16 25)
cl-loop 带条件: (2 4 6 8 10)
cl-loop sum: 6
cl-loop 遍历字符串: ("A" "B" "C")
cl-loop 多变量: (11 22 33)
```

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
(cl-incf n)          ; 原地自增，可加步长
(cl-case kind ...)   ; 见 5.7
```

```
cl-incf 之后 n = 6
```

`cl-incf` / `cl-decf` 是宏，直接改地方（`(cl-incf (aref v 0))` 也能用）。

## 9.6 cl-defstruct：带名字的结构

```elisp
(cl-defstruct demo-point x y)     ; 自动生成 demo-point-p / demo-point-x / 构造器等
(setq p (make-demo-point :x 3 :y 4))
(demo-point-x p)                  ; → 3
```

```
结构: #s(demo-point 3 4), x = 3, 判定 = t
setf 风格改字段后: #s(demo-point 13 4)
copy 出的副本: #s(demo-point 13 4)
```

生成的东西：`make-demo-point`（构造器，支持 `:x` `:y` 关键字）、`demo-point-p`（判定）、
`demo-point-x` / `demo-point-y`（访问器，可 `setf`）、`copy-demo-point`（拷贝）、
`demo-point-p` 打印成 `#s(demo-point 3 4)`。

它比 alist 更适合「数据结构固定」的场景：有类型判定、有名字、`%S` 打印可读。

## 9.7 cl-defun 的 &key

参数多了之后 `&optional` 的位置陷阱很痛：

```elisp
(defun demo-connect (host &optional port user scheme) ...)
;; 只想改 user 也得写全前面三个 (demo-connect "h" nil "me")

(cl-defun demo-connect (host &key (port 22) (user "root") scheme) ...)
(demo-connect "h1" :user "me")    ; 只写要改的
```

```
"root@h1:22" / "me@h1:80"
```

`&key` 让调用点自解释，还支持默认值 `(port 22)`。代价是每个参数多两个字节的开销，
但可读性提升明显，参数超过 3 个就值得用。

## 9.8 cl-letf：临时改写函数或变量

测试里 mock 的标准手段：

```elisp
(cl-letf (((symbol-function 'demo-slow-call) (lambda (&rest _) "fake")))
  (demo-slow-call))     ; 用假的
;; 出了 let 自动恢复
```

```
cl-letf 临时改值: 42
```

它同时能改函数和变量（`(cl-letf (((symbol-function 'f) ...)) ...)` 改函数，
`(cl-letf ((var value)) ...)` 改变量）。第 25 章的测试用的就是这个。

---

上一章：[08 · 字符串与正则](08-strings-regexp.md)　｜　下一章：[10 · buffer 与 point](10-buffers.md)　｜　返回：[Emacs 扩展开发指南](README.md)
