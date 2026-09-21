# 08 · 数组、向量与序列函数

> 配套示例：[`examples/08_sequences/`](../examples/08_sequences/main.lisp)（channel: both）

CL 把「列表」和「向量」抽象成**序列**（sequence）——一份 API 通吃列表、向量、字符串。
本章先看向量/数组本身，再看序列函数族。

## 8.1 向量

```lisp
(vector 1 2 3)                     ; => #(1 2 3)     函数版
#(1 2 3)                           ; 字面量版（常量，不可修改！）
(make-array 5 :initial-element 0)  ; => #(0 0 0 0 0)
(aref #(10 20 30) 1)               ; => 20           O(1) 下标访问
(length #(1 2 3))                  ; => 3
```

**动态向量**：`:adjustable t` + `:fill-pointer`，配 `vector-push-extend`/`vector-pop`
——这是 CL 的「可增长数组」，相当于其它语言的 ArrayList：

```lisp
(let ((v (make-array 0 :adjustable t :fill-pointer 0)))
  (vector-push-extend 10 v)
  (vector-push-extend 20 v)      ; => 1   返回新元素的填充下标
  v)                             ; => #(10 20)
(vector-pop v)                   ; 弹出末尾；空了弹会报错
```

字面量向量 `#(...)` 是**编译期常量**，对它做破坏性操作是未定义行为——
和字面量列表/字符串同一条规矩（05/07 章）。

## 8.2 多维数组

```lisp
(make-array '(3 3) :initial-element 0)     ; 3×3 矩阵
(aref mat 1 1)                             ; 每个维度一个下标
(setf (aref mat 0 0) 1)                    ; setf 位置
(array-dimensions mat)                     ; => (3 3)
(array-total-size mat)                     ; => 9
(row-major-aref mat 4)                     ; 行主序一维化访问（缓存友好的遍历用它）
#2A((1 2) (3 4))                           ; 字面量写法，打印也长这样
```

## 8.3 序列抽象：一份 API，三种容器

```lisp
(length '(1 2 3))            ; => 3
(length #(1 2 3))            ; => 3
(length "abc")               ; => 3      字符串也是序列
(elt '(1 2 3) 1)             ; => 2      通用取元素（列表 O(n)，向量 O(1)）
(elt "abc" 0)                ; => #\a
(subseq '(1 2 3 4) 1 3)      ; => (2 3)
(subseq #(1 2 3 4) 1 3)      ; => #(2 3)
(reverse '(1 2 3))           ; => (3 2 1)
(copy-seq "abc")             ; => "abc"  新对象
(count 1 '(1 2 1 3))         ; => 2
```

`concatenate` 与 `coerce` 是最常用的「类型转换」入口：

```lisp
(concatenate 'list '(1 2) #(3 4))       ; => (1 2 3 4)   类型混着传也行
(concatenate 'string "ab" "cd")         ; => "abcd"
(coerce '(1 2 3) 'vector)               ; => #(1 2 3)
(coerce '(#\a #\b) 'string)             ; => "ab"
```

## 8.4 map 家族

```lisp
(mapcar #'1+ '(1 2 3))              ; => (2 3 4)      只吃列表、只回列表
(mapcar #'+ '(1 2) '(10 20))        ; => (11 22)      多列表并行喂
(map 'list #'1+ #(1 2 3))           ; => (2 3 4)
(map 'vector #'1+ #(1 2 3))         ; => #(2 3 4)
(map 'string #'char-upcase "abc")   ; => "ABC"        结果类型由第一个参数决定
```

**`mapcar` 与 `map` 的区别就是返回类型**；处理字符串/向量用 `map`。
多序列时**取最短**：`(mapcar #'+ '(1 2 3) '(10 20))` ; => `(11 22)`。

其余成员：`mapc`（只要副作用）、`mapcan`（nconc 拼接结果）、
`maplist`/`mapcon`（操作子表——与 loop 的 `for x on` 同概念）、
`map-into`（破坏性写回第一个参数，省分配）。

## 8.5 查找、计数、过滤、替换

```lisp
(find 3 '(1 2 3 4))                 ; => 3
(find-if #'evenp '(1 3 6 7))        ; => 6
(position #\l "hello")              ; => 2
(position-if #'evenp '(1 3 6))      ; => 2
(count-if #'oddp '(1 2 3 5))        ; => 3
(remove 1 '(1 2 1 3))               ; => (2 3)         非破坏
(remove-if #'oddp '(1 2 3 4))       ; => (2 4)
(substitute :x 2 '(1 2 3 2))        ; => (1 :X 3 :X)
(substitute-if 0 #'evenp '(1 2 3 4))   ; => (1 0 3 0)
(search '(2 3) '(1 2 3 4))          ; => 1   子序列位置
(mismatch '(1 2 3) '(1 9 3))        ; => 1   首个不同下标
```

它们都接受 `:test` / `:key` / `:start` / `:end` / `:from-end` / `:count`。
`:test` 语义是「当相等看待」，容易写反（`(remove 2 '(1 2 3) :test #'<)` 把
「大于 2 的」当等价删掉），用的时候多想一秒。

**remove vs delete（n 前缀规矩，07 章）**：

```lisp
(delete 2 (list 1 2 3 2))           ; => (1 3)    列表上行为可移植（接返回值）
```

**⚠️ 双实现差异（实测）**：`delete` 作用在**定长向量**上的效果是实现定义——
SBCL 会挪动元素（看到 `#(1 3 2 2)`），CLISP 保持不动（`#(1 2 3 2)`）。
定长向量删元素本来就没有可移植语义：要么用 `remove` 重建，要么用带
fill-pointer 的向量。示例 08 专门踩过这条。

`remove-duplicates` 默认保留**最后**一个：

```lisp
(remove-duplicates '(1 2 1 3))                  ; => (2 1 3)
(remove-duplicates '(1 2 1 3) :from-end t)      ; => (1 2 3)   保留第一个
```

「先来的优先」必须写 `:from-end t`。

## 8.6 sort：破坏性，必须接返回值

```lisp
(sort (copy-list '(3 1 2)) #'<)         ; => (1 2 3)
(sort (vector 3 1 2) #'>)               ; => #(3 2 1)
```

- `sort` **会改掉传入的序列**；列表排序的返回值还**可能不是同一个对象**
  （允许重建链）——不接返回值 = 排序结果直接丢掉；
- 想保原数据：`(sort (copy-list ...) ...)`；
- `stable-sort` 保证相等元素相对顺序不变（多键排序用它，示例 08 演示）；
- `:key` 是「比之前先做一次变换」：`(sort people #'string< :key #'name)`。

`merge` 归并两个**已排序**序列：`(merge 'list '(1 3 5) '(2 4 6) #'<)` ; => `(1 2 3 4 5 6)`。

## 8.7 every / some / notany / notevery

```lisp
(every #'evenp '(2 4 6))                   ; => T
(some #'evenp '(1 3 4))                    ; => T
(notany #'oddp '(2 4))                     ; => T
(every #'< '(1 2 3) '(2 3 4))              ; => T   多序列并行
```

`some` 返回**第一个非 nil 的结果**（不是 T）——可用来「顺手取值」：

```lisp
(some (lambda (x) (and (evenp x) (* x 10))) '(1 3 4))     ; => 40
```

## 8.8 reduce：三个容易踩的边界

```lisp
(reduce #'+ '(1 2 3 4))                    ; => 10
(reduce #'+ '(1 2 3) :initial-value 10)    ; => 16
(reduce #'+ '())                           ; => 0        ← (+) 是 0
(reduce #'- '())                           ; 报错！(-) 零参不合法
(reduce #'- '(1 2 3))                      ; => -4       ← 左结合 1-2-3
(reduce #'- '(1 2 3) :from-end t)          ; => 2        ← 右结合 1-(2-3)
(reduce #'- '(1))                          ; => 1        ← 单元素不调函数
(reduce #'cons '((a) (b) (c)))             ; => (((A) B) C)
(reduce #'cons '((a) (b) (c)) :from-end t) ; => ((A) (B) C)
```

三个边界：**空序列**要调零参函数（`+` 行 `-` 不行）、**结合方向**默认左、
**单元素**直接返回。空表场景永远带 `:initial-value` 最稳。

## 8.9 列表 vs 向量：性能直觉

| 操作 | 列表 | 向量 |
|---|---|---|
| `nth n` / `elt n` | **O(n)** 走链 | **O(1)** 下标寻址 |
| 头部插入 | **O(1)** | O(n) |
| 尾部追加 | O(n) | O(1)（fill-pointer） |
| 顺序遍历 | 快 | 快 |

**需要下标随机访问就用向量**（`coerce lst 'vector` 一步到位）；
频繁头部增删用列表。循环里 `nth` 是 CL 最典型的性能事故。

## 8.10 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| 排序「没生效」 | sort 返回值没接 | 一定接返回值 |
| 排序把原数据改了 | sort 破坏性 | 先 copy |
| delete 向量后两实现结果不同 | 定长向量 delete 是实现定义 | remove 重建 / fill-pointer 向量 |
| 去重留了不想要的那个 | remove-duplicates 默认留最后 | `:from-end t` |
| `(reduce #'- '())` 报错 | 空序列调零参函数 | `:initial-value` |
| mapcar 结果比预期短 | 多序列取最短 | 先确认长度 |
| 改字面量 `#(...)` 崩溃 | 字面量是常量 | copy-seq / make-array |
| nth 在长列表很慢 | 链式 O(n) | 换向量 |
