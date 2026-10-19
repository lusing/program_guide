# 39 · 哈希表：测试函数、遍历与弱引用

> 所属部分：第 10 部分 · 对照参考手册补齐的主题

> 示例：`examples/39-hash-tables.el`

「一堆键对应一堆值」在 Elisp 里有三种常见做法：plist（`:key value` 交替的列表）、alist（`((key . value) …)`）、哈希表。前两种在 [07 · 列表与关联结构](07-lists.md) 讲过，它们是**链表**，查找是从头扫到尾；哈希表是真正的**散列表**，查找代价跟表里有多少东西无关。

本章对应参考手册的 **Hash Tables** 一章。为什么值得单开一章？因为哈希表的几个坑跟列表完全不同：

- **`:test` 默认不是 `equal`** —— 是 `eql`。用字符串做键，`puthash` 进去 `gethash` 取不出来，而且不会报错。
- **没有 `hash-table-keys` / `hash-table-values`** —— 遍历只有 `maphash` 一条路。
- **遍历中新增键会死循环** —— 不是「结果不对」，是 Emacs 直接卡住。
- **`:rehash-size` 之类的参数已经废弃** —— 传了不报错，也完全不起作用。

这几个都不是靠读文档能记住的，得实测。本章照旧：结论全部来自本机 Emacs 31.1 的真实输出。

## 39.1 创建、写入、读取、删除

哈希表的全部基本操作只有五个函数：`make-hash-table` 造表、`puthash` 写、`gethash` 读、`remhash` 删单个、`clrhash` 清空。示例第 1 节：

```elisp
(let ((h (make-hash-table :test 'equal)))
  (princ (format "  刚建好: count=%S size=%S test=%S weakness=%S\n"
                 (hash-table-count h) (hash-table-size h)
                 (hash-table-test h) (hash-table-weakness h)))
  (puthash "a" 1 h)
  (puthash "b" 2 h)
  (princ (format "  放两个: count=%S size=%S\n"
                 (hash-table-count h) (hash-table-size h)))
  (princ (format "  读: (gethash \"a\")=%S  (gethash \"z\")=%S  (gethash \"z\" h 'miss)=%S\n"
                 (gethash "a" h) (gethash "z" h) (gethash "z" h 'miss)))
  (puthash "a" 99 h)
  (princ (format "  覆盖: 再 (puthash \"a\" 99) 后 count=%S 值=%S\n"
                 (hash-table-count h) (gethash "a" h)))
  (remhash "b" h)
  (princ (format "  (remhash \"b\") 后 count=%S  (gethash \"b\")=%S\n"
                 (hash-table-count h) (gethash "b" h 'miss)))
  (clrhash h)
  (princ (format "  (clrhash) 后 count=%S size=%S（容量不退）\n"
                 (hash-table-count h) (hash-table-size h))))
```

```
== 1) 创建、写入、读取、删除 ==
  刚建好: count=0 size=0 test=equal weakness=nil
  放两个: count=2 size=6
  读: (gethash "a")=1  (gethash "z")=nil  (gethash "z" h 'miss)=miss
  覆盖: 再 (puthash "a" 99) 后 count=2 值=99
  (remhash "b") 后 count=1  (gethash "b")=miss
  (clrhash) 后 count=0 size=6（容量不退）
```

要留意的几点：

- **`hash-table-count` 是「元素个数」，`hash-table-size` 是「槽位数」**。刚建好的空表 `size=0`，插了两个之后 `size=6`——槽位是批量分配的，不等于元素个数。
- **`gethash` 找不到就返回 `nil`**，跟「值是 `nil`」混在一起。想区分就给第三个参数当默认值：`(gethash "z" h 'miss)` 返回 `miss`。注意默认值只在**键不存在**时返回，39.10 会讲这个值本身是 `nil` 的坑。
- **`puthash` 同一个键会覆盖**，不会变成两条（`count` 还是 2）。所以 `puthash` 也兼作「更新」。
- **`clrhash` 只清元素不清容量**：清空后 `count=0` 而 `size` 仍然是 6。

`make-hash-table` 的所有关键字参数：`:test`（测试函数）、`:size`（预估容量，只是提示）、`:weakness`（弱引用类型）、以及三个已废弃的 `:rehash-size` / `:rehash-threshold` / `:purecopy`（39.6 讲）。

## 39.2 默认 `:test` 是 `eql`：字符串键陷阱

这是新手撞哈希表撞得最狠的一处。示例第 2 节：

```elisp
(let ((h (make-hash-table)))
  (princ (format "  (make-hash-table) 的 test=%S\n" (hash-table-test h)))
  (puthash (demo-str "a") 1 h)
  (puthash (demo-str "a") 2 h)
  (princ (format "  两个内容都是 \"a\" 的字符串: count=%S\n" (hash-table-count h)))
  (princ (format "  再用一个全新的 \"a\" 去查: %S\n"
                 (gethash (demo-str "a") h 'miss)))
  (princ "  原因：eql 比的是「同一个对象，或同样的数 / 字符」，\n")
  (princ "        不是「内容相同」。两个字符串对象永远不 eql。\n"))
(let* ((h (make-hash-table))
       (k (demo-str "a")))
  (puthash k 1 h)
  (princ (format "  用同一个对象做键: (gethash k)=%S  count=%S\n"
                 (gethash k h) (hash-table-count h)))
  (remhash k h)
  (princ (format "  (remhash k) 同一个对象才删得掉: count=%S\n" (hash-table-count h))))
(let ((h (make-hash-table :test 'equal)))
  (puthash (demo-str "a") 1 h)
  (puthash (demo-str "a") 2 h)
  (princ (format "  改成 :test equal: count=%S  (gethash \"a\")=%S\n"
                 (hash-table-count h) (gethash (demo-str "a") h))))
```

```
== 2) 默认 :test 是 eql ==
  (make-hash-table) 的 test=eql
  两个内容都是 "a" 的字符串: count=2
  再用一个全新的 "a" 去查: miss
  原因：eql 比的是「同一个对象，或同样的数 / 字符」，
        不是「内容相同」。两个字符串对象永远不 eql。
  用同一个对象做键: (gethash k)=1  count=1
  (remhash k) 同一个对象才删得掉: count=0
  改成 :test equal: count=1  (gethash "a")=2
  把字符串 intern 成符号, eq 表也认: (gethash 'apple h)=1 count=1
  再放一次 (intern "apple"): count=1 值=2
```

（`demo-str` 是示例开头定义的小工具，就是 `(copy-sequence s)`，用来确保每次拿到的是一个**全新的**字符串对象，排除「字面量是不是复用同一个对象」的干扰。）

三步结论：

1. **`make-hash-table` 的默认 `:test` 是 `eql`**，不是 `equal`。
2. 两个内容都是 `"a"` 的字符串**永远不 `eql`**（`eql` 只在「同一个对象」或「同样的数/字符」时成立），所以放进去了两条，`count=2`；再拿一个新的 `"a"` 去查，查出来 `miss`。**全程不报错**——这是最要命的地方。
3. 反过来，只要**同一个字符串对象**做键，读写删除都正常；换成 `:test 'equal` 后，内容相同就算同一个键，第二次 `puthash` 变成覆盖，`count=1`。

判据很简单：**键是字符串、列表、向量这类「内容型」对象，一律写 `:test 'equal`**。只有键是符号、整数、字符这类「同一性型」对象时，默认的 `eql` 才顺手。

顺带一提：把字符串 `intern` 成符号（[37 · 符号](37-symbols.md) 讲过）也是一种绕法——

```elisp
(let ((h (make-hash-table :test 'eq)))
  (puthash (intern "apple") 1 h)
  (princ (format "  把字符串 intern 成符号, eq 表也认: (gethash 'apple h)=%S count=%S\n"
                 (gethash 'apple h) (hash-table-count h)))
  (puthash (intern "apple") 2 h)
  (princ (format "  再放一次 (intern \"apple\"): count=%S 值=%S\n"
                 (hash-table-count h) (gethash 'apple h))))
```

符号是全局唯一的（`intern` 同一个名字永远得到同一个对象），所以 `eq` 就够了，而且比 `equal` 快。上面输出里 `(gethash 'apple h)` 直接查到了值，第二次 `puthash` 同一个符号变成覆盖（`count` 还是 1）。代价是键必须是合法的符号名，而且会永久占住 obarray——**别拿用户输入去 `intern`**，那是典型的内存泄漏写法。

## 39.3 `eq` / `eql` / `equal` 的边界

[06 · 相等性](06-equality.md) 讲过这三个谓词的语义，这里看它们在**做哈希表测试函数**时各自的表现。示例第 3 节：

```elisp
(let ((heq (make-hash-table :test 'eq))
      (heql (make-hash-table :test 'eql))
      (hequal (make-hash-table :test 'equal))
      (big (expt 2 70)))
  (puthash big 'yes heq)
  (puthash big 'yes heql)
  (puthash big 'yes hequal)
  (princ (format "  bignum %S:\n    eq=%S eql=%S equal=%S\n"
                 big
                 (gethash (expt 2 70) heq 'miss)
                 (gethash (expt 2 70) heql 'miss)
                 (gethash (expt 2 70) hequal 'miss)))
  (puthash 1.0 'yes heq)
  (puthash 1.0 'yes heql)
  (princ (format "  浮点数 1.0: eq=%S eql=%S（两个 1.0 不是同一个对象）\n"
                 (gethash 1.0 heq 'miss) (gethash 1.0 heql 'miss)))
  (puthash (demo-str "s") 'yes heq)
  (puthash (demo-str "s") 'yes heql)
  (puthash (demo-str "s") 'yes hequal)
  (princ (format "  字符串 \"s\": eq=%S eql=%S equal=%S\n"
                 (gethash (demo-str "s") heq 'miss)
                 (gethash (demo-str "s") heql 'miss)
                 (gethash (demo-str "s") hequal 'miss)))
  (puthash (list 1 2) 'yes hequal)
  (princ (format "  列表 '(1 2) 只有 equal 认: %S\n"
                 (gethash (list 1 2) hequal 'miss))))
```

```
== 3) eq / eql / equal 的边界 ==
  bignum 1180591620717411303424:
    eq=miss eql=yes equal=yes
  浮点数 1.0: eq=miss eql=yes（两个 1.0 不是同一个对象）
  字符串 "s": eq=miss eql=miss equal=yes
  列表 '(1 2) 只有 equal 认: yes
```

逐行解释：

- **bignum**（超过 fixnum 范围的大整数，`(expt 2 70)` = 1180591620717411303424）：`eq` 查不到，`eql` 和 `equal` 都查得到。因为大整数不是「同一个对象」，但 `eql` 对同类型同值的**数字**仍然成立（[36 · 数字](36-numbers.md) 讲过 fixnum 和 bignum 的区别）。
- **浮点数 `1.0`**：同样，`eq` 查不到、`eql` 查得到。注意这是 Emacs 的 `eql` 特有的行为——Common Lisp 的 `eql` 对浮点数是不成立的，别照搬。
- **字符串**：`eq` 和 `eql` 都查不到，只有 `equal` 行。这就是 39.2 那个坑的根因。
- **列表**：只有 `equal` 认，`eq`/`eql` 都没戏。所以想用列表（比如坐标 `(x y)`）做键，必须 `:test 'equal`。

一句话选型：

| 键的类型 | 该用哪个 |
|---|---|
| 符号、intern 过的字符串 | `eq`（最快） |
| 整数、字符、浮点数 | `eql`（默认） |
| 字符串、列表、向量等复合对象 | `equal` |

## 39.4 自定义测试函数

内置的三个不够用时（比如想「忽略大小写」），可以自己注册一个。要用 `define-hash-table-test`，并且**同时提供相等函数和哈希函数**。示例第 4 节：

```elisp
(defun demo-ci-equal (a b)
  "忽略大小写地比较两个字符串。"
  (string-equal (downcase a) (downcase b)))
(defun demo-ci-hash (s)
  "DEMO-CI-EQUAL 配套的哈希函数：先把键归一化再取 sxhash。"
  (sxhash-equal (downcase s)))
(define-hash-table-test 'demo-ci #'demo-ci-equal #'demo-ci-hash)
(let ((h (make-hash-table :test 'demo-ci)))
  (puthash "Hello" 1 h)
  (princ (format "  test=%S\n" (hash-table-test h)))
  (princ (format "  \"hello\"=%S  \"HELLO\"=%S  \"World\"=%S\n"
                 (gethash "hello" h 'miss)
                 (gethash "HELLO" h 'miss)
                 (gethash "World" h 'miss)))
  (princ (format "  表里只有 %S 个键: %S\n" (hash-table-count h) (demo-hash-keys h))))
(princ "  --- 测试函数必须先注册 ---\n")
(princ (format "  直接用没注册的符号: %S\n"
               (condition-case err (make-hash-table :test 'no-such-test)
                 (error (error-message-string err)))))
(princ (format "  equal-including-properties 也不在内置列表里: %S\n"
               (condition-case err
                   (make-hash-table :test 'equal-including-properties)
                 (error (error-message-string err)))))
(define-hash-table-test 'demo-props #'equal-including-properties #'sxhash-equal)
(let* ((bare (demo-str "abc"))
       (fancy (let ((s (demo-str "abc")))
                (put-text-property 0 1 'face 'bold s)
                s))
       (h (make-hash-table :test 'demo-props)))
  (puthash bare 'plain h)
  (princ (format "  注册后可用: 不带属性查=%S 带 face 属性查=%S\n"
                 (gethash bare h 'miss) (gethash fancy h 'miss)))
  (puthash fancy 'fancy h)
  (princ (format "  两个都放进去: count=%S（属性不同算两个键）\n" (hash-table-count h))))
```

```
== 4) 自定义测试函数 ==
  test=demo-ci
  "hello"=1  "HELLO"=1  "World"=miss
  表里只有 1 个键: ("Hello")
  --- 测试函数必须先注册 ---
  直接用没注册的符号: "Invalid hash table test: no-such-test"
  equal-including-properties 也不在内置列表里: "Invalid hash table test: equal-including-properties"
  注册后可用: 不带属性查=plain 带 face 属性查=miss
  两个都放进去: count=2（属性不同算两个键）
```

关键点：

- **哈希函数必须和相等函数配套**。规则是「相等函数认为相等的两个键，哈希函数必须算出同一个值」。这里 `demo-ci-equal` 忽略大小写，那 `demo-ci-hash` 就必须先把键 `downcase` 再取哈希——如果直接写 `(sxhash-equal s)`，`"Hello"` 和 `"hello"` 会算出不同的哈希值，被分到不同的桶里，永远匹配不上。这是自定义 test 最常见的错误，而且症状是「有时候能查到有时候查不到」，非常难查。
- **`sxhash-equal` 是给 `equal` 配套的哈希函数**（还有 `sxhash-eq`、`sxhash-eql`）。裸的 `sxhash` 是通用版本。选哪个取决于你的相等函数跟哪个谓词语义接近。
- **没注册的符号直接报错**，不会静默退化：`Invalid hash table test: no-such-test`。
- **`equal-including-properties` 不在内置列表里**，直接当 `:test` 也报错。但它注册之后能用——上面 `demo-props` 就是这个例子：带 `face` 属性的 `"abc"` 和不带属性的 `"abc"` 会被当成**两个不同的键**（`count=2`）。

顺带说清楚 `equal` 和 `equal-including-properties` 的差别（文本属性在 [12 · 文本属性](12-text-properties.md) 讲）：前者只比字符串内容，后者连 `face`、`read-only` 这些属性一起比。默认哈希表用的是 `equal`，所以「同一个词在不同位置有不同 face」在表里是同一个键——这通常正是你想要的。

## 39.5 遍历：只有 `maphash`

Emacs 的哈希表 API 很小。示例第 5 节先把「没有的东西」列清楚：

```elisp
(princ (format "  hash-table-keys? %S  hash-table-values? %S\n"
               (fboundp 'hash-table-keys) (fboundp 'hash-table-values)))
(princ (format "  hash-table-empty-p? %S  hash-table-to-alist? %S\n"
               (fboundp 'hash-table-empty-p) (fboundp 'hash-table-to-alist)))
(princ "  四个都没有——键和值只能自己 maphash 收集，判空用 count。\n")
(let ((h (make-hash-table :test 'equal))
      (i 0))
  (dolist (k '("a" "b" "c"))
    (setq i (1+ i))
    (puthash k i h))
  (let (ks vs)
    (maphash (lambda (k v) (push k ks) (push v vs)) h)
    (princ (format "  maphash 收集: 键=%S  值=%S\n"
                   (sort ks #'string<) (sort vs #'<))))
  (princ (format "  判空: count=%S  (zerop count)=%S\n"
                 (hash-table-count h) (zerop (hash-table-count h))))
  (clrhash h)
  (princ (format "  clrhash 之后 (zerop count)=%S\n" (zerop (hash-table-count h))))
  (princ (format "  哈希表不是序列: (length h) -> %S\n"
                 (condition-case err (length h)
                   (error (error-message-string err))))))
```

```
== 5) 遍历：只有 maphash ==
  hash-table-keys? nil  hash-table-values? nil
  hash-table-empty-p? nil  hash-table-to-alist? nil
  四个都没有——键和值只能自己 maphash 收集，判空用 count。
  maphash 收集: 键=("a" "b" "c")  值=(1 2 3)
  判空: count=3  (zerop count)=nil
  clrhash 之后 (zerop count)=t
  哈希表不是序列: (length h) -> "Wrong type argument: sequencep, #s(hash-table test equal)"
```

- **`hash-table-keys` / `hash-table-values` / `hash-table-empty-p` / `hash-table-to-alist` 在 Emacs 31.1 全都不存在**（`fboundp` 一律 `nil`）。网上很多代码片段会直接写 `(hash-table-keys h)`，那是别的 Lisp 方言或者旧补丁，在本机一定会报 `void-function`。自己 `maphash` 收集是唯一稳妥写法：

  ```elisp
  (defun demo-hash-keys (table)
    "返回 TABLE 里所有键的列表（顺序未定义）。"
    (let (ks)
      (maphash (lambda (k _v) (push k ks)) table)
      (nreverse ks)))
  ```

- **判空用 `(zerop (hash-table-count h))`**，别指望 `hash-table-empty-p`。
- **哈希表不是序列**：`length`、`seq-*` 系列、`dolist` 全都不认它，报 `Wrong type argument: sequencep`。
- **`maphash` 的顺序是未定义的**。上面输出里键刚好是 `("a" "b" "c")`，但那只是「这次实现碰巧」，不能依赖。要稳定输出就自己 `sort`。

接下来是遍历中修改——三种情况，两种安全、一种要命：

```elisp
(let ((h (make-hash-table :test 'equal))
      (n 0))
  (dotimes (i 4) (puthash (1+ i) (1+ i) h))
  (maphash (lambda (k _v) (setq n (1+ n)) (puthash k (* 10 k) h)) h)
  (princ (format "  改已有键: 回调 %S 次 count=%S 1=%S 4=%S（安全）\n"
                 n (hash-table-count h) (gethash 1 h) (gethash 4 h))))
(let ((h (make-hash-table :test 'equal))
      seen)
  (dotimes (i 4) (puthash i i h))
  (maphash (lambda (k _v) (push k seen) (remhash k h)) h)
  (princ (format "  删除当前键: 看到 %S 个 %S，删完 count=%S（安全）\n"
                 (length seen) (sort seen #'<) (hash-table-count h))))
(let ((h (make-hash-table :test 'equal))
      (n 0)
      (added nil))
  (puthash 0 'zero h)
  (maphash (lambda (_k _v)
             (setq n (1+ n))
             (unless added (setq added t) (puthash 'new 'val h)))
           h)
  (princ (format "  新增一个键: 回调被调了 %S 次（本来只有 1 个键）\n" n))
  (princ (format "  表里现在有 %S 个键——新键也被遍历到了。\n" (hash-table-count h)))
  (princ "  所以：遍历中不断新增 = 死循环，必须先收集键再改。\n"))
```

```
  --- 遍历中改 / 删 / 加 ---
  改已有键: 回调 4 次 count=4 1=10 4=40（安全）
  删除当前键: 看到 4 个 (0 1 2 3)，删完 count=0（安全）
  新增一个键: 回调被调了 2 次（本来只有 1 个键）
  表里现在有 2 个键——新键也被遍历到了。
  所以：遍历中不断新增 = 死循环，必须先收集键再改。
  正确写法（先收集键，再对收集结果循环）: count=4 键=("a" "a-copy" "b" "b-copy")
```

- **改已有键的值**：安全。回调被调用 4 次，`count` 没变，值都改成了 10 倍。
- **删除当前键**：安全。4 个键都被看到，删完 `count=0`。（别的语言里「遍历中删」经常是未定义行为，Emacs 这里明确可以。）
- **新增键：危险**。本来只有 1 个键，回调却被调了 2 次——**新加进去的键也被这次遍历看到了**。所以「遍历时不断往里塞新键」不会停下来，而是无限循环。上面这段用了 `added` 护栏才没卡住；不加护栏的话 Emacs 会一直跑到你杀掉进程。

正确写法是**先把键收集出来，再对收集结果做循环**：

```elisp
(let ((h (make-hash-table :test 'equal))
      keys)
  (puthash "a" 1 h)
  (puthash "b" 2 h)
  (maphash (lambda (k _v) (push k keys)) h)
  (dolist (k keys)
    (puthash (concat k "-copy") (gethash k h) h))
  (princ (format "  正确写法（先收集键，再对收集结果循环）: count=%S 键=%S\n"
                 (hash-table-count h) (sort (demo-hash-keys h) #'string<))))
```

```
  正确写法（先收集键，再对收集结果循环）: count=4 键=("a" "a-copy" "b" "b-copy")
```

`maphash` 先把键收进 `keys`，之后 `dolist` 只在那份**快照**上循环，新增多少都跟遍历无关。结果 2 个键变 4 个（各加了一份 `-copy`），循环正常结束。

## 39.6 容量：`:size` 只是提示

示例第 6 节：

```elisp
(let ((h (make-hash-table :test 'equal)))
  (princ (format "  刚建好: count=%S size=%S（还没插东西，一个槽都不分配）\n"
                 (hash-table-count h) (hash-table-size h)))
  (dotimes (i 6) (puthash i i h))
  (princ (format "  塞到第 6 个: count=%S size=%S\n"
                 (hash-table-count h) (hash-table-size h)))
  (dotimes (i 100) (puthash (+ 100 i) i h))
  (princ (format "  再塞 100 个: count=%S size=%S（自己长，不用管）\n"
                 (hash-table-count h) (hash-table-size h))))
(let ((h (make-hash-table :size 1)))
  (princ (format "  :size 1 初始 size=%S\n" (hash-table-size h)))
  (dotimes (i 200) (puthash i i h))
  (princ (format "  塞 200 个后 count=%S size=%S——:size 只是提示，小了兜不住也大了不浪费\n"
                 (hash-table-count h) (hash-table-size h))))
(let ((h (make-hash-table :size 100)))
  (dotimes (i 300) (puthash i i h))
  (princ (format "  :size 100 塞 300 个: size=%S\n" (hash-table-size h)))
  (clrhash h)
  (princ (format "  (clrhash) 后容量不退: size=%S count=%S\n"
                 (hash-table-size h) (hash-table-count h))))
(princ "  --- :rehash-size / :rehash-threshold / :purecopy 已废弃 ---\n")
(let ((h (make-hash-table :rehash-size 2.0 :rehash-threshold 0.5 :purecopy t)))
  (princ (format "  传了 :rehash-size 2.0 和 :rehash-threshold 0.5，照样读到 %S / %S\n"
                 (hash-table-rehash-size h) (hash-table-rehash-threshold h))))
(princ "  make-hash-table 的 docstring 原文：\n")
(princ "    The keywords arguments :rehash-threshold, :rehash-size,\n")
(princ "    and :purecopy are obsolete and ignored.\n")
(princ (format "  但完全陌生的关键字照样报错: %S\n"
               (condition-case err (make-hash-table :bogus 1)
                 (error (error-message-string err)))))
```

```
== 6) 容量：:size 只是提示 ==
  刚建好: count=0 size=0（还没插东西，一个槽都不分配）
  塞到第 6 个: count=6 size=6
  再塞 100 个: count=106 size=192（自己长，不用管）
  :size 1 初始 size=1
  塞 200 个后 count=200 size=384——:size 只是提示，小了兜不住也大了不浪费
  :size 100 塞 300 个: size=400
  (clrhash) 后容量不退: size=400 count=0
  --- :rehash-size / :rehash-threshold / :purecopy 已废弃 ---
  传了 :rehash-size 2.0 和 :rehash-threshold 0.5，照样读到 1.5 / 0.8125
  make-hash-table 的 docstring 原文：
    The keywords arguments :rehash-threshold, :rehash-size,
    and :purecopy are obsolete and ignored.
  但完全陌生的关键字照样报错: "Invalid keyword argument: :bogus"
```

- **空表 `size=0`**：Emacs 是**惰性分配**的，不插东西就一个槽都不占。所以可以放心地给每个 buffer 挂一张空表当缓存。
- **`:size` 只是提示**。`:size 1` 塞 200 个照样能装（`size` 自己涨到 384）；`:size 100` 塞 300 个涨到 400。传小了不会溢出，传大了也不会浪费到哪去。手册的说法是「may help performance slightly if the size is known in advance but is never required」——**只在你知道大概规模、又很在意那一点性能时才写**。
- **`:rehash-size`、`:rehash-threshold`、`:purecopy` 已经废弃**，docstring 原文就是 *"are obsolete and ignored"*。传进去不报错（所以老代码不会崩），但完全不起作用：`hash-table-rehash-size` 恒为 `1.5`、`hash-table-rehash-threshold` 恒为 `0.8125`。这两个访问器现在基本只剩「告诉你内置常数是多少」的用途。
- **但陌生的关键字照样报错**：`:bogus 1` 会报 `Invalid keyword argument: :bogus`。废弃 ≠ 随便写。

## 39.7 打印与读回

哈希表可以被 `prin1` 打印、被 `read` 读回来。示例第 7 节：

```elisp
(let* ((h (make-hash-table :test 'equal))
       (str (progn (puthash "a" 1 h) (puthash "b" 2 h) (prin1-to-string h))))
  (princ (format "  prin1: %S\n" str))
  (let ((h2 (read str)))
    (princ (format "  read 回来: count=%S (gethash \"a\")=%S test=%S\n"
                   (hash-table-count h2) (gethash "a" h2) (hash-table-test h2)))))
(let ((h (make-hash-table :test 'equal :weakness 'value)))
  (puthash "a" 1 h)
  (princ (format "  弱表会把 weakness 一起写进去: %S\n" (prin1-to-string h))))
(princ "  自定义 test 的表打印出来读不回去：\n")
(let ((h (make-hash-table :test 'demo-ci)))
  (puthash "Hello" 1 h)
  (princ (format "  prin1: %S\n" (prin1-to-string h))))
```

```
== 7) 打印与读回 ==
  prin1: "#s(hash-table test equal data (\"a\" 1 \"b\" 2))"
  read 回来: count=2 (gethash "a")=1 test=equal
  弱表会把 weakness 一起写进去: "#s(hash-table test equal weakness value data (\"a\" 1))"
  自定义 test 的表打印出来读不回去：
  prin1: "#s(hash-table test demo-ci data (\"Hello\" 1))"
```

打印形式是 `#s(hash-table …)`——`#s` 是「结构体」的读语法（[01 · 第一个程序](01-hello.md) 讲过 reader）。里面依次是 `test`、`weakness`（非 nil 时才写）、`data` 三段。`read` 能原样还原，连 `test` 一起恢复成 `equal`。

**坑在自定义 test**：`demo-ci` 那张表打印出来是 `#s(hash-table test demo-ci data ("Hello" 1))`，但这串字符串读回去时 `demo-ci` 这个测试函数符号**在你这次会话里未必已经注册**。也就是说：**带自定义 `:test` 的表不能直接 `prin1` 存盘**。要持久化就先转成 alist（或转成 `equal` 表）再存。

## 39.8 `copy-hash-table` 是浅拷贝

示例第 8 节：

```elisp
(let* ((val (list 1 2))
       (h (make-hash-table :test 'equal))
       (c (progn (puthash "k" val h) (copy-hash-table h))))
  (puthash "k" 'changed h)
  (puthash "new" 9 h)
  (princ (format "  原表改了 k: 原表=%S 副本=%S（不受影响）\n"
                 (gethash "k" h) (gethash "k" c)))
  (princ (format "  原表新增 \"new\"，副本里: %S\n" (gethash "new" c 'miss)))
  (princ (format "  副本 test=%S weakness=%S（测试函数和弱类型一起带过来）\n"
                 (hash-table-test c) (hash-table-weakness c)))
  (princ (format "  值本身还是同一个 cons: %S——只复制「映射关系」这一层\n"
                 (eq (gethash "k" c) val))))
```

```
== 8) copy-hash-table 是浅拷贝 ==
  原表改了 k: 原表=changed 副本=(1 2)（不受影响）
  原表新增 "new"，副本里: miss
  副本 test=equal weakness=nil（测试函数和弱类型一起带过来）
  值本身还是同一个 cons: t——只复制「映射关系」这一层
  自己 copy-tree 出来的「深」拷贝: 副本=(99 2) 原表=(1 2)
```

- 副本是**独立的映射表**：原表改 `k`、加 `new`，副本都不受影响。
- 但**键和值本身不复制**。副本里 `"k"` 对应的还是原来那个 cons（`eq` 为 `t`）。所以如果你改的是值对象内部（比如 `(setcar (gethash "k" c) 99)`），两张表会一起变。
- 副本会带上 `test` 和 `weakness`。

要「深拷贝」就得自己遍历重建：

```elisp
(let* ((h (make-hash-table :test 'equal))
       (deep (progn (puthash "k" (list 1 2) h)
                    (let ((d (make-hash-table :test (hash-table-test h))))
                      (maphash (lambda (k v)
                                 (puthash (copy-tree k) (copy-tree v) d))
                               h)
                      d))))
  (setcar (gethash "k" deep) 99)
  (princ (format "  自己 copy-tree 出来的「深」拷贝: 副本=%S 原表=%S\n"
                 (gethash "k" deep) (gethash "k" h))))
```

```
  自己 copy-tree 出来的「深」拷贝: 副本=(99 2) 原表=(1 2)
```

改副本的值对象内部，原表不受影响——这一层是真的分开了。

（`copy-tree` 递归复制 cons 结构，但**字符串和向量它不复制**——Elisp 没有通用的深拷贝，得按你的数据结构自己写。上面这版对字符串键其实只做到「半深」：键是字符串时 `copy-tree` 原样返回它。真要连键一起复制，得自己按类型分派。）

## 39.9 弱引用表

弱（weak）哈希表是这样一种表：**它自己对键/值的引用不算「有效引用」**。当某个键（或值）除了这张表以外没人引用它了，这一对就会被自动删掉。这是做「对象 → 附属数据」旁路表（side table）的标准工具：主对象没了，附属数据自动消失，不用手动清理，也不会内存泄漏。

示例第 9 节：

```elisp
(princ (format "  合法取值: %S %S %S %S %S（t 是 key-and-value 的别名）\n"
               (hash-table-weakness (make-hash-table :weakness 'key))
               (hash-table-weakness (make-hash-table :weakness 'value))
               (hash-table-weakness (make-hash-table :weakness 'key-or-value))
               (hash-table-weakness (make-hash-table :weakness 'key-and-value))
               (hash-table-weakness (make-hash-table :weakness t))))
(princ (format "  非法取值: %S\n"
               (condition-case err (make-hash-table :weakness 'bogus)
                 (error (error-message-string err)))))
(princ "  四种取值的语义，make-hash-table 的 docstring 是这么写的：\n")
(princ "    Key/value pairs are removed from a weak hash table when there\n")
(princ "    are no non-weak references pointing to their key, value, one\n")
(princ "    of key or value, or both key and value, depending on WEAK.\n")
(princ "  逐项对上就是：key / value / key-or-value / key-and-value。\n")
(let ((h (make-hash-table :test 'eq :weakness 'value :size 8)))
  (dotimes (i 100) (puthash i (list 'payload i) h))
  (princ (format "  value 弱表放 100 个: count=%S\n" (hash-table-count h)))
  (dotimes (_ 5) (garbage-collect))
  (princ (format "  这些值已经没人引用了，5 次 gc 后: count=%S\n"
                 (hash-table-count h))))
(let ((h (make-hash-table :test 'eq :weakness 'key :size 8)))
  (dotimes (i 100) (puthash (list 'k i) i h))
  (princ (format "  key 弱表放 100 个: count=%S\n" (hash-table-count h)))
  (dotimes (_ 5) (garbage-collect))
  (princ (format "  这些键已经没人引用了，5 次 gc 后: count=%S\n"
                 (hash-table-count h))))
(let ((h (make-hash-table :test 'eq :weakness 'value :size 8)))
  (dotimes (i 50) (puthash i (list 'payload i) h))
  (setq demo-keep (list 'i-am-kept))
  (puthash 'special demo-keep h)
  (princ (format "  50 个无人引用的 + 1 个被 demo-keep 引用着的: count=%S\n"
                 (hash-table-count h)))
  (dotimes (_ 5) (garbage-collect))
  (princ (format "  5 次 gc 后: count=%S  被引用着的那条=%S\n"
                 (hash-table-count h) (gethash 'special h 'gone)))
  (princ (format "  同期别的键: (gethash 0 h 'gone)=%S\n"
                 (gethash 0 h 'gone))))
```

```
== 9) 弱引用表 ==
  合法取值: key value key-or-value key-and-value key-and-value（t 是 key-and-value 的别名）
  非法取值: "Invalid hash table weakness: bogus"
  四种取值的语义，make-hash-table 的 docstring 是这么写的：
    Key/value pairs are removed from a weak hash table when there
    are no non-weak references pointing to their key, value, one
    of key or value, or both key and value, depending on WEAK.
  逐项对上就是：key / value / key-or-value / key-and-value。
  value 弱表放 100 个: count=100
  这些值已经没人引用了，5 次 gc 后: count=0
  key 弱表放 100 个: count=100
  这些键已经没人引用了，5 次 gc 后: count=0
  50 个无人引用的 + 1 个被 demo-keep 引用着的: count=51
  5 次 gc 后: count=1  被引用着的那条=(i-am-kept)
  同期别的键: (gethash 0 h 'gone)=gone
```

按 docstring 逐项对上四种取值：

| `:weakness` | 什么时候删掉这一对 |
|---|---|
| `key` | 键没有非弱引用时 |
| `value` | 值没有非弱引用时 |
| `key-or-value` | 键**或**值只要有一个没有非弱引用时 |
| `key-and-value` | 键**和**值都没有非弱引用时（写 `t` 等价） |

其余几点：

- 取值一共就这五个（含 `nil` 表示不弱），写别的立刻报 `Invalid hash table weakness: bogus`。
- 实测里 100 个「没人引用」的条目，`garbage-collect` 之后全被清掉（count 从 100 掉到 0）。
- 被全局变量 `demo-keep` 引用着的那一条**留下来了**（count=1，值还在），同期别的键都变 `gone`。这说明弱表只看「有没有非弱引用」，不看别的。
- 注意：**清理发生在 GC 时，不是 `puthash` 时**。所以在 GC 之前查，条目还在。写测试时如果依赖这个行为，记得显式 `garbage-collect`。

一个现实中的用法：给 buffer 挂一张「buffer → 解析结果」的表，`(make-hash-table :weakness 'key)`。buffer 被 kill 之后没人引用它了，缓存条目自动消失，不需要在 `kill-buffer-hook` 里手动清理。

## 39.10 `nil` 键与 `nil` 值

`nil` 在 Elisp 里既是空表又是「假」，在哈希表里它还能做键、能做值——于是就有了「查得到但看起来像没查到」的问题。示例第 10 节：

```elisp
(let ((h (make-hash-table :test 'equal)))
  (puthash nil 'the-nil-key h)
  (puthash "x" nil h)
  (princ (format "  nil 可以做键: (gethash nil h)=%S\n" (gethash nil h)))
  (princ (format "  nil 也可以做值: (gethash \"x\" h)=%S\n" (gethash "x" h)))
  (princ (format "  给默认值也没用: (gethash \"x\" h 'miss)=%S\n" (gethash "x" h 'miss)))
  (princ (format "  键不存在时才给默认值: (gethash \"y\" h 'miss)=%S\n"
                 (gethash "y" h 'miss)))
  (princ "  gethash 的默认值只区分「键不存在」，区分不了「值是 nil」。\n")
  (princ (format "  想确认键在不在，只能遍历: %S\n"
                 (let (found)
                   (maphash (lambda (k _v) (when (equal k "x") (setq found t))) h)
                   found))))
```

```
== 10) nil 键与 nil 值 ==
  nil 可以做键: (gethash nil h)=the-nil-key
  nil 也可以做值: (gethash "x" h)=nil
  给默认值也没用: (gethash "x" h 'miss)=nil
  键不存在时才给默认值: (gethash "y" h 'miss)=miss
  gethash 的默认值只区分「键不存在」，区分不了「值是 nil」。
  想确认键在不在，只能遍历: t
```

- **`nil` 可以当键**（`(gethash nil h)` 正常返回值），也可以当值。哈希表对 `nil` 没有特殊对待——它只是一个普通的 Lisp 对象。
- **但 `gethash` 的第三个参数救不了你**：键 `"x"` 存在、值是 `nil`，`(gethash "x" h 'miss)` 照样返回 `nil`，**不是** `miss`。因为默认值只在「键不存在」时生效。
- 于是**「键在不在」和「值是 nil」用 `gethash` 分不开**。两个办法：
  1. 别把 `nil` 当值存——用 `:false`、`0` 之类的哨兵。
  2. 真要区分就 `maphash` 遍历（O(n)，别放在热路径上）。

上面输出里最后一行 `想确认键在不在，只能遍历: t` 就是第二种办法。

## 39.11 alist 还是哈希表：实测查找代价

讲了这么多，最后一个问题：**什么时候该用 alist，什么时候该用哈希表？** 先看实测。示例第 11 节用一个会数比较次数的 `demo-assoc` 把 alist 的代价量化：

```elisp
(defvar demo-cmp-count 0
  "记录 DEMO-ASSOC 这一次查找做了几次比较。")

(defun demo-assoc (key alist)
  "在 ALIST 里线性查找 KEY，把比较次数记进 `demo-cmp-count'。"
  (setq demo-cmp-count 0)
  (catch 'demo-found
    (dolist (pair alist)
      (setq demo-cmp-count (1+ demo-cmp-count))
      (when (equal (car pair) key)
        (throw 'demo-found (cdr pair))))
    nil))

(let* ((n 1000)
       (al (mapcar (lambda (i) (cons (number-to-string i) i))
                   (number-sequence 0 (1- n)))))
  (princ (format "  alist 有 %S 项\n" (length al)))
  (princ (format "  查第 1 项    \"0\":   值=%S  比较 %S 次\n"
                 (demo-assoc "0" al) demo-cmp-count))
  (princ (format "  查最后一项  \"999\": 值=%S  比较 %S 次\n"
                 (demo-assoc "999" al) demo-cmp-count))
  (princ (format "  查不存在的  \"zzz\": 值=%S  比较 %S 次（必须扫完才知道没有）\n"
                 (demo-assoc "zzz" al) demo-cmp-count)))
(let ((h (make-hash-table :test 'equal)))
  (dotimes (i 1000) (puthash (number-to-string i) i h))
  (princ (format "  哈希表 1000 项: (gethash \"999\")=%S  (gethash \"zzz\")=%S，代价一样\n"
                 (gethash "999" h) (gethash "zzz" h 'miss))))
```

```
== 11) alist 还是哈希表 ==
  alist 有 1000 项
  查第 1 项    "0":   值=0  比较 1 次
  查最后一项  "999": 值=999  比较 1000 次
  查不存在的  "zzz": 值=nil  比较 1000 次（必须扫完才知道没有）
  哈希表 1000 项: (gethash "999")=999  (gethash "zzz")=miss，代价一样
```

差别一目了然：

- alist 是**线性查找**——查第 1 项要 1 次比较，查第 1000 项要 1000 次。**查不到的时候最惨**，必须扫完整张表才能确定「没有」。
- 哈希表查 `"999"` 和查不存在的 `"zzz"` 代价**一样**。这是散列表最本质的性质。

所以判据是：

| 情况 | 选择 |
|---|---|
| 元素少于几十个 | **alist**。构造简单、能 `prin1` 存盘、能 `dolist`、`let` 里随手写、还能带重复的键（做「查找表」很方便） |
| 元素成百上千，或者要频繁查 | **哈希表** |
| 需要保持插入 / 自定义顺序 | **alist**（哈希表顺序未定义） |
| 需要「查不到」也很快 | **哈希表**（alist 查不到最慢） |
| 要存盘 / 要放进 `defcustom` | **alist**（哈希表能 `prin1` 但自定义 test 读不回来，见 39.7） |
| 要挂在主对象上、随它一起消失 | **弱引用哈希表**（39.9） |

最后是两个惯用法。**词频统计**——`gethash` 带默认值 `0` 是最经典的写法：

```elisp
(let ((words '("the" "cat" "the" "dog" "a" "cat" "the" "bird" "cat"))
      (h (make-hash-table :test 'equal)))
  (dolist (w words)
    (puthash w (1+ (gethash w h 0)) h))
  (let (pairs)
    (maphash (lambda (k v) (push (cons k v) pairs)) h)
    (setq pairs (sort pairs
                      (lambda (a b)
                        (or (> (cdr a) (cdr b))
                            (and (= (cdr a) (cdr b))
                                 (string< (car a) (car b)))))))
    (princ (format "  词表: %S\n" words))
    (princ (format "  词频（次数降序、同次数按字典序）: %S\n" pairs))
    (princ (format "  Top 2: %S\n" (cl-subseq pairs 0 2)))))
```

```
  --- 实战：词频统计 ---
  词表: ("the" "cat" "the" "dog" "a" "cat" "the" "bird" "cat")
  词频（次数降序、同次数按字典序）: (("cat" . 3) ("the" . 3) ("a" . 1) ("bird" . 1) ("dog" . 1))
  Top 2: (("cat" . 3) ("the" . 3))
```

`(puthash w (1+ (gethash w h 0)) h)` 这一行把「没有就当 0」和「写回」合成一步——**前提是 0 不是你真正会存的值**，否则就撞上 39.10 的坑（`gethash` 分不出「不存在」和「值是 0」…… 不过这里 `1+` 之后写回的是 `1`，所以没问题；真正要小心的是「键存在但值是 0」和「键不存在」在你这里的语义是否要区分）。

排序那一步值得单独说一句：`maphash` 的顺序未定义，**所以要先收集成 alist 再 `sort`**。排序比较函数写的是「次数降序，同次数按字典序」——`or` 的短路顺序正好表达了这个优先级：先看次数，次数相等才比字符串。

**缓存**——哈希表当 memoize 容器：

```elisp
(let ((cache (make-hash-table :test 'equal))
      (calls 0))
  (cl-labels ((slow (x) (setq calls (1+ calls)) (* x x))
              (cached (x)
                (let ((hit (gethash x cache 'miss)))
                  (if (eq hit 'miss)
                      (puthash x (slow x) cache)
                    hit))))
    (princ (format "  第一次 (cached 7)=%S\n" (cached 7)))
    (princ (format "  第二次 (cached 7)=%S\n" (cached 7)))
    (princ (format "  第三次 (cached 7)=%S\n" (cached 7))))
  (princ (format "  底层 slow 实际只被调用了 %S 次\n" calls)))
```

```
  --- 用哈希表做缓存 ---
  第一次 (cached 7)=49
  第二次 (cached 7)=49
  第三次 (cached 7)=49
  底层 slow 实际只被调用了 1 次
```

这里用 `eq` 比 `'miss` 哨兵而不是用 `nil`：因为**缓存的值本身可能是 `nil`**，用 `nil` 当「没命中」的标志会每次都重新计算。选一个绝不会是真实值的符号当哨兵（这里用 `'miss`），是 Emacs 里写缓存的标准套路。

## 39.12 坑位清单

1. **默认 `:test` 是 `eql`，不是 `equal`** —— 字符串键 `puthash` 进去 `gethash` 取不出来，**而且不报错**。键是字符串/列表一律写 `:test 'equal`。
2. **`remhash` 也是按 `:test` 比对的** —— `eql` 表里的字符串键，只有同一个对象才删得掉。
3. **bignum 和浮点数在 `eq` 表里查不到** —— `eql` 才认。`1.0` 的 `eql` 行为是 Emacs 特有（Common Lisp 里 `eql` 不认浮点数）。
4. **`hash-table-keys` / `-values` / `-empty-p` / `-to-alist` 都不存在** —— 只有 `maphash`；判空用 `(zerop (hash-table-count h))`。
5. **哈希表不是序列** —— `length` / `dolist` / `seq-*` 全报 `Wrong type argument: sequencep`。
6. **`maphash` 顺序未定义** —— 看着有序只是巧合，要稳定输出自己 `sort`。
7. **遍历中新增键 = 死循环** —— 新键会被同一次遍历看到。改值、删当前键都安全，新增必须先收集键再改。
8. **`:rehash-size` / `:rehash-threshold` / `:purecopy` 已废弃** —— 传了不报错但完全无效；访问器恒为 `1.5` / `0.8125`。陌生的关键字仍然报错。
9. **`:size` 只是提示** —— 传小了不溢出，传大了不浪费。空表 `size=0`（惰性分配）。`clrhash` 只清元素不清容量。
10. **自定义 test 的表 `prin1` 出来读不回去** —— `#s(hash-table test demo-ci …)` 里的符号在下次会话未必注册。要存盘先转 alist。
11. **自定义 test 必须同时给哈希函数，且两者要配套** —— 「相等 ⇒ 哈希相同」不满足时症状是「有时查得到有时查不到」。
12. **`equal-including-properties` 不是内置 test** —— 直接当 `:test` 报 `Invalid hash table test`；`define-hash-table-test` 注册后可用。
13. **`copy-hash-table` 是浅拷贝** —— 只复制映射关系，键和值对象共用。
14. **`gethash` 的默认值区分不了「值是 `nil`」** —— 键存在但值是 `nil` 时照样返回 `nil`。要么别存 `nil`，要么 `maphash` 确认。
15. **弱表的清理发生在 GC 时** —— 不是 `puthash` 时；写测试要显式 `garbage-collect`。
16. **alist 查不到的代价最大** —— 必须扫完整张表。查不到也要快的场景只能用哈希表。

下一章继续第 10 部分：把「文本怎么被读成 Lisp 对象、Lisp 对象怎么被打印成文本」讲透——**读取与打印**（`read` / `print` / `prin1` / `princ` / `format` 的区别，以及 `print-length`、`print-level` 这些开关）。

上一章：[38 · 求值：quote、backquote 与 eval](38-evaluation.md)　｜　下一章：[40 · 读取与打印：read、prin1、princ 与那一堆 print-* 开关](40-reading-printing.md)　｜　返回：[Emacs 扩展开发指南](README.md)
