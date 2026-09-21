# 09 · 哈希表与结构体

> 配套示例：[`examples/09_hash/`](../examples/09_hash/main.lisp)（channel: both）

## 9.1 哈希表基本操作

```lisp
(defvar *ht* (make-hash-table))
(setf (gethash :a *ht*) 1)                      ; setf gethash 就是「put」
(multiple-value-list (gethash :a *ht*))         ; => (1 T)
(multiple-value-list (gethash :missing *ht*))   ; => (NIL NIL)
(gethash :missing *ht* :default)                ; => :DEFAULT
(hash-table-count *ht*)                         ; => 1
(remhash :a *ht*)                               ; => T   删掉了；再删 => NIL
(clrhash *ht*)                                  ; 清空
```

**`gethash` 返回两个值**：值 + 「存不存在」。「存了 `nil`」和「没存」必须靠
第二个返回值区分——别写 `(if (gethash k h) ...)`。

计数的经典模式：`(incf (gethash w table 0))`（缺省给 0 再自增，示例 09 的词频统计）。

## 9.2 `:test` 选错就取不出数据

**最大的坑是 `:test` 默认 `eql`**：

```lisp
(let ((h (make-hash-table)))                        ; 默认 eql
  (setf (gethash "key" h) 1)
  (list (gethash "key" h) (gethash (copy-seq "key") h)))
; => (NIL NIL)      ← 连原本那个 "key" 都取不回来！
```

两个字面量 `"key"` 是**不同对象**，`eql` 比身份（07 章相等表）。换 `equal`：

```lisp
(let ((h (make-hash-table :test 'equal)))
  (setf (gethash "key" h) 1)
  (list (gethash "key" h) (gethash (copy-seq "key") h)))
; => (1 1)
```

| `:test` | 比较方式 | 适合的键 |
|---|---|---|
| `eq` | 对象身份 | 符号、关键字（最快） |
| `eql`（默认） | 身份或同类型同数值 | 符号、整数、字符 |
| `equal` | 结构相同 | **字符串**、列表 |
| `equalp` | 更宽松 | 忽略大小写的字符串 |

**实践规则：键用关键字配默认 `eql` 最快；字符串键必须 `:test 'equal`。**

`with-hash-table-iterator` 与 `sxhash` 是进阶面（sxhash 给 equal 键算哈希，
示例 09 演示 `(= (sxhash "abc") (sxhash (copy-seq "abc")))` ; => T）。

## 9.3 遍历顺序是不确定的

```lisp
(let ((h (make-hash-table)) (ks nil))
  (loop for k in '(:c :a :b) do (setf (gethash k h) 1))
  (maphash (lambda (k v) (push (cons k v) ks)) h)
  ks)
; 一次运行的结果 => ((:B . 1) (:A . 1) (:C . 1))   ← 顺序每次可能不同
```

**不要依赖遍历顺序**——它随实现、容量、插入历史变化（本教程双通道判定
「逐字节一致」逼着每个示例都先排序再输出）。确定性输出的标准姿势：

```lisp
;; 键排序后取值（示例 09 的 hash-keys-sorted）
(sort (loop for k being each hash-key of h collect k) #'string<
      :key (lambda (k) (format nil "~A" k)))
;; 汇总不排序也安全（顺序无关的运算）
(loop for v being the hash-values of h sum v)
```

`equalp` 能按内容比较两个哈希表（`:test 'equalp` 的）——
`(equalp h1 h2)` ; => T。

## 9.4 结构体：defstruct

一行生成「固定几个槽的轻量记录」+ 构造器 + 谓词 + 访问器 + 打印形式：

```lisp
(defstruct contact
  name
  (age 0)                          ; 带默认值
  (email "" :type string))         ; 带类型声明
(defparameter *c* (make-contact :name "张三" :age 30))
*c*   ; 打印成 #S(CONTACT :NAME "张三" :AGE 30 :EMAIL "") —— 固定的可读形式
(contact-name *c*)      ; => "张三"   读取
(setf (contact-age *c*) 31)         ; setf 位置
(contact-p *c*)          ; => T        谓词
(copy-contact *c*)        ; 浅拷贝
```

继承（`:include`）——子结构体获得全部父槽，谓词链也成立：

```lisp
(defstruct (student (:include contact))
  (school "未知")
  (grade 1))
(defparameter *s* (make-student :name "李四" :school "北大"))
(student-p *s*)      ; => T
(contact-p *s*)      ; => T    student 也是 contact
```

自定义构造器签名（按位置传参）：`(:constructor make-point3 (x y z))`。

**相等性**：结构体用 `equalp` 按槽内容比——这点与 CLOS 实例相反（19 章）：

```lisp
(equal  (make-contact :name "a") (make-contact :name "a"))    ; => NIL
(equalp (make-contact :name "a") (make-contact :name "a"))    ; => T
```

结构体 vs CLOS 类怎么选：

| | `defstruct` | `defclass`（19 章） |
|---|---|---|
| 定位 | 数据记录 | 完整对象系统 |
| 继承 | 单继承 `:include` | 多继承 |
| 方法 | 无（配普通函数） | 泛型函数 + 多分派 |
| 相等 | `equalp` 比内容 | 默认比身份 |
| 开销 | 小 | 略大 |

**经验法则**：「几个字段捆一起传」用 defstruct；要多态/多分派/钩子才上 CLOS。

## 9.5 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| 字符串键存取对不上 | 默认 `:test 'eql` | `:test 'equal` |
| 分不清「存了 nil」和「没存」 | 只用第一个返回值 | `gethash` 第二返回值 |
| 程序两次运行输出顺序不同 | 遍历顺序不确定（两实现也不同） | 输出前排序 |
| `(equal s1 s2)` 结构体是 NIL | equal 不比结构体内容 | `equalp` |
| 词频计数代码又长又乱 | 手工 gethash/setf | `(incf (gethash k ht 0))` 一行 |
