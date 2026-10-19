# 07 · 列表与关联结构

> 所属部分：第 1 部分 · 语言基础

> 示例：`examples/07-lists.el`

## 7.1 cons 单元

列表不是数组，而是一条**由 cons 单元串起来的链**。每个 cons 有两个格子：`car` 和 `cdr`。

```elisp
(cons 1 2)      ; → (1 . 2)   点对：cdr 不是列表
(list 1 2 3)    ; → (1 2 3)
```

```
(cons 1 2) = (1 . 2)      <- 点对的写法
(list 1 2 3) = (1 2 3)
car = 1, cdr = (2 3)
cadr = 2, cddr = (3)  <- c[a/d]+r 可组合，最多四层
```

`(1 2 3)` 是 `(1 . (2 . (3 . nil)))` 的简写，末尾的 `nil` 就是空表。
`cadr` 是 `(car (cdr x))` 的简写，`c` 和 `r` 之间最多四个 `a`/`d`（`caadr` 可以，`cadaadr` 不行）。

## 7.2 构造

```elisp
(make-list 3 'x)              ; → (x x x)
(number-sequence 1 5)         ; → (1 2 3 4 5)
(number-sequence 1 9 2)       ; → (1 3 5 7 9)
```

```
make-list: (x x x)
number-sequence 1..5: (1 2 3 4 5)，步长 2: (1 3 5 7 9)
```

## 7.3 当栈用：push / pop

```elisp
(let ((stack nil))
  (push 1 stack)     ; → (1)
  (push 2 stack)     ; → (2 1)   注意是插到**前面**
  (pop stack))       ; → 2，stack 变成 (1)
```

```
push 两次: (2 1)，pop 出 2，剩下 (1)
```

`push` 和 `pop` 都是宏，直接改变量指向的位置。因为插在前面，从 `push` 攒出来的列表是**逆序**的，
需要正序时在最后 `(nreverse result)`。

## 7.4 取元素

```elisp
(nth 1 '(a b c d))       ; → b      下标从 0 开始
(nthcdr 2 '(a b c d))    ; → (c d)  跳过 n 个格子
(last '(a b c d))        ; → (d)    返回最后一个 cons（是个列表！）
(butlast '(a b c d))     ; → (a b c)
(car (last x))           ; 才是「最后一个元素」
```

```
nth 1 = b, nthcdr 2 = (c d), last = (d), butlast = (a b)
```

`last` 返回的是**列表而不是元素**，这个不一致非常容易写错。

## 7.5 【坑】append 与 nconc

```elisp
(append '(1 2) '(3 4))   ; → (1 2 3 4)，参数不变
(nconc  '(1 2) '(3 4))   ; → (1 2 3 4)，但第一个参数被改掉了
```

```
append: (1 2 3 4)，之后 a 仍是 (1 2)
nconc:  (1 2 3 4)，之后 a 变成 (1 2 3 4)
```

- `append` 复制除**最后一个**参数之外的所有参数（省一次复制），非破坏性，安全；
- `nconc` 直接把前一个列表的尾巴接到后一个上，破坏性、更省内存，但会**改掉前面的列表**。

写扩展时默认用 `append`。只有在明确知道那些列表是临时变量、没有别的地方引用时，才考虑 `nconc`。

## 7.6 【坑】共享结构

```elisp
(let ((x (list 1 2 3))
      (y nil))
  (setq y x)
  (setcar y 99)
  (princ (format "改了 y 的 car 之后，x = %S，y = %S\n" x y)))
```

```
改了 y 的 car 之后，x = (99 2 3)，y = (99 2 3)
```

`setq` 只复制「指向链头的指针」——`y` 和 `x` 是同一个对象，改 `y` 就是改 `x`。
（注意示例用 `(list 1 2 3)` 造列表而不是字面量 `'(1 2 3)`——**对字面量做破坏性操作是未定义行为**，字节编译器会警告。）

想让两个列表独立，必须显式复制：

- `copy-sequence`：**浅**拷贝——顶层是新 cons，嵌套的子列表仍是共享的；
- `copy-tree`：**深**拷贝——递归复制所有层级。

```elisp
(let* ((x (list 1 (list 2)))
       (shallow (copy-sequence x))
       (deep (copy-tree x)))
  (setcar (nth 1 x) 99)
  (princ (format "浅拷贝跟着变 = %S，深拷贝不变 = %S\n" shallow deep)))
```

```
浅拷贝跟着变 = (1 (99))，深拷贝不变 = (1 (2))
```

这个区别在改嵌套结构（比如配置 alist）时是关键。

## 7.7 遍历与映射

```elisp
(mapcar #'1+ '(1 2 3))            ; → (2 3 4)   返回新列表
(mapc #'princ '(a b c))           ; 只做副作用，返回原列表
(mapcan (lambda (x) (list x x)) '(1 2))  ; → (1 1 2 2)  拼接结果
```

```
mapcar: (1 4 9 16)
mapcan（拼接结果）: (1 1 2 2)
mapc 只做副作用: (a b c)
```

`mapcan` 等价于 `(apply #'nconc (mapcar ...))` —— 所以它**会改掉 lambda 返回的列表**，
lambda 必须每次返回新造的列表，不能返回共享结构。

## 7.8 【坑】remove 与 delete

```
remove 2: (1 3)，原列表没变: (1 2 3 2)
delete 2: (1 3)，原列表已变: (1 3)
delete 头元素必须接返回值: (2)
```

- `remove` 非破坏，返回新列表；
- `delete` 破坏，直接在原列表上摘掉节点。

`delete` 有个额外的坑：如果删的正好是**头几个元素**，它会返回一个新的开头，
而调用方手里的变量还指着老的头。所以 `delete` 必须**接收返回值**：

```elisp
(let ((xs (list 1 1 2)))
  (princ (format "delete 头元素必须接返回值: %S\n" (delete 1 xs))))
```

```
delete 头元素必须接返回值: (2)
```

写成 `(setq xs (delete 1 xs))` 才对；直接 `(delete 1 xs)` 而不管返回值，
删头元素时 `xs` 仍指向旧头 —— 这就是「删了好像没删」的来源。

## 7.9 alist：配置类数据的首选

元素是 `(key . value)` 的列表：

```elisp
(defvar cfg '((host . "localhost") (port . 8080)))

(cdr (assq 'port cfg))          ; → 8080
(alist-get 'port cfg)           ; → 8080  （更简洁）
(alist-get 'port cfg nil nil #'equal)   ; 字符串 key 必须加这个
```

```
alist = ((host . "localhost") (port . 8080))
assq 'port = (port . 8080)，alist-get = 8080
assoc-default = "localhost"，rassoc 反查 = (port . 8080)
```

好处是**可以重复**、可以有序、查找是 O(n) 对配置量级完全够用。代价是查找慢，
数据量大（几百条以上）要换成 `hash-table`。

`rassoc` 按 value 反查 key，`assoc-default` 直接给值（找不到返回 nil），`copy-alist` 复制。

## 7.10 plist：扁平 key value 列表

```elisp
(princ (format "plist-get: %S\n" (plist-get '(:a 1 :b 2) :b)))
(princ (format "plist-put: %S\n" (plist-put (list :a 1) :b 2)))
```

```
plist-get: 2
plist-put: (:a 1 :b 2)
```

结构是 `key1 value1 key2 value2 ...`。查找是 O(n)，用 `eq` 比 key，所以 **key 必须是符号**。
`plist-put` 会**就地修改**传入的 plist（它返回改完的 plist，但参数本身也可能被改）——所以别喂字面量常量，示例里用 `(list :a 1)` 现造。

符号的属性表（`(get 'sym 'prop)` / `(put 'sym 'prop val)`）就是 plist——第 27 章的「符号抽屉柜」和第 16 章的 `derived-mode-parent` 都是它。

选择建议：

| 数据结构 | 用于 |
|---|---|
| `plist` | 少量、key 是符号、临时传递参数（`&key` 展开也是 plist） |
| `alist` | 配置、可能重复、需要有序 |
| `hash-table` | 数据量大、频繁查 |

---

上一章：[06 · 相等性：eq / eql / = / equal](06-equality.md)　｜　下一章：[08 · 字符串与正则](08-strings-regexp.md)　｜　返回：[Emacs 扩展开发指南](README.md)
