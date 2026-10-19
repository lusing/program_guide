# 06 · 相等性：eq / eql / = / equal

> 所属部分：第 1 部分 · 语言基础

> 示例：`examples/06-equality.el`

这一章单独成一章，是因为「比较」在 Elisp 里分了四个函数，选错不会报错，只会静默给出错误结果。

## 6.1 eq：比「同一对象」

```elisp
eq 'a 'a = t,  eq nil nil = t,  eq 1 1 = t
```

`eq` 最严格也最快：**两个参数是不是同一个内存对象**。符号、`nil`、小整数（fixnum）在 Emacs 里是
立即值或唯一对象，所以 `eq` 都能正确判断。

但对**浮点和字符串**就不行了：

```elisp
eq 两个不同的 1.0 = nil
eq 两个内容相同的字符串 = nil，equal = t
```

实测 `(eq 1.0 1.0)` 在本机是 `nil` —— 每个浮点字面量都是独立分配的对象。
字符串同理，两个内容一样的字符串是**两个对象**。

> 注意 `(eq 1.0 1.0)` 到底是 `t` 还是 `nil` 属于实现细节（不同版本、是否字节编译都可能不一样）。
> 正因为不可依赖，所以结论是：**`eq` 不用在浮点和字符串上**。

## 6.2 eql：eq 加上「数值相同且类型相同」

```elisp
eql 1.0 1.0 = t,  eql 1 1.0 = nil,  (= 1 1.0) = t
```

`eql` 修好了浮点的问题，但仍然要求类型一致：`(eql 1 1.0)` 是 `nil`。
它主要用在需要「哈希键语义」的地方 —— 比如 `cl-case`、`hash-table` 的默认比较。

## 6.3 =：只比数

```elisp
= 3 3.0 = t
```

只对数字有效，会做类型提升。**比数一律用 `=`**，不要用 `eq`/`eql`。传非数字会报
`wrong-type-argument`（这其实是好事，说明错误能立刻暴露）。

## 6.4 equal：递归比结构（日常最常用）

```elisp
equal "aa" (concat "a" "a") = t
equal (list 1 2) (list 1 2) = t
equal '(1 (2)) '(1 (2)) = t
```

`equal` 递归比较结构：字符串比内容，列表逐元素比，嵌套列表递归下去。**判断两个值「是不是一样」
就用 `equal`** —— 它是正确性优先的选择。

## 6.5 equal 会忽略文本属性

```elisp
equal = t, equal-including-properties = nil
```

一个带 face 属性的字符串和同内容无属性的字符串，`equal` 认为相等，
`equal-including-properties` 认为不等（第 11 章会详细讲文本属性）。

## 6.6 字符串专用比较

```elisp
string-equal "a" "A" = nil
compare-strings 忽略大小写 = t
```

- `string-equal`（别名 `string=`）：比内容，**区分大小写**；
- `string-prefix-p` / `string-suffix-p`：判前后缀；
- `compare-strings`：可取片段、可忽略大小写（第 5 个参数传 `t`）。

## 6.7 【重点】查找函数的默认比较方式各不相同

这是本章最实用的一张表。同一个「查 key」，不同函数用的比较函数不一样，写错了会**静默查不到**：

```elisp
(defvar demo-alist '(("name" . "emacs") ("ver" . "31")))

assoc  (equal)   找到: ("name" . "emacs")
assq   (eq)    找不到: nil
alist-get 默认 eq    -> nil
alist-get 传 equal   -> "emacs"
```

| 函数 | 默认比较 |
|---|---|
| `assoc` | `equal` |
| `assq` | `eq` |
| `alist-get` | `eq`（但可以传第 4 个参数指定别的） |
| `member` | `equal` |
| `memq` | `eq` |
| `cl-find` / `seq-contains-p` | `eql`（可传 `:test`） |

**所以：字符串做 key 的 alist，查值要用 `assoc` 或 `(alist-get k alist nil nil #'equal)`，
绝对不能用 `assq` / 默认的 `alist-get`** —— 后者永远返回 `nil`，而且不报错。这个坑非常常见。

## 6.8 排序要用比较函数，不是相等函数

```elisp
(sort '(3 1 2) #'<)
(sort '("b" "a") #'string<)
```

```
sort 数字: (1 2 3)
sort 字符串: ("a" "b")
非破坏的 seq-sort: (1 2 3)
```

`sort` 接受的是「小于」谓词，不是相等谓词。三个常用谓词：`<`（数）、`string<`（字符串）、
`string-collate-lessp`（按本地化顺序，中文/多语言场景用它）。

`sort` 是**破坏性的**（会改原列表），要保留原列表就用 `seq-sort`（第 9 章）或先 `copy-sequence`。

---

上一章：[05 · 控制流](05-control-flow.md)　｜　下一章：[07 · 列表与关联结构](07-lists.md)　｜　返回：[Emacs 扩展开发指南](README.md)
