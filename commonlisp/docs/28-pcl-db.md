# 28 · Practical：简易 CD 数据库（书 3 章）

> 配套示例：[`examples/28_pcl_db/`](../examples/28_pcl_db/main.lisp)（channel: both）
>
> 《Practical Common Lisp》第 3 章的重演：一个 CD 数据库从 plist 玩到家。

> **本章你将学会**：用 plist 当记录、`print`/`read` 的免费序列化、**同一个查询需求下宏为什么碾压函数**（where 三代演化）、`setf` + `getf` 原地更新。
> **前置章节**：07（列表）、14（宏 I）。

## 28.1 记录与表：plist 一把梭

一章数据库不建类不建表：plist 当行（`(:title "Roses" :artist "Kathy Mattea" :rating 8 :ripped t)`），列表当表，`push` 当插入。

```lisp
(defparameter *db* nil)

(defun add-record (cd) (push cd *db*) cd)

(defun dump-db ()
  (dolist (cd *db*)
    ;; ~{...~} 迭代 plist；~10t 制表对齐
    (format t "~{~a:~10t~a~%~}~%" cd)))
```

注意 `push` 是头插——dump 出来是**倒序**，教学示例里 `(setf *db* (reverse *db*))` 转回插入序。

## 28.2 序列化是免费的

`print` 出去的，`read` 读得回来——Lisp 数据即文本：

```lisp
(defun save-db (filename)
  (with-open-file (out filename :direction :output :if-exists :supersede)
    (with-standard-io-syntax
      (print *db* out))))

(defun load-db (filename)
  (with-open-file (in filename)
    (setf *db* (with-standard-io-syntax (read in)))))
```

`with-standard-io-syntax` 把 `*print-readably*` 等一大票打印变量钉在标准档位——不包它，实现特定的打印开关可能写出读不回来的东西（17 章展开过）。

## 28.3 查询三代：函数 → 宏

**一代**，写死字段的闭包选择器：

```lisp
(defun select-by-artist (artist)
  (remove-if-not
   (lambda (cd) (equal (getf cd :artist) artist))
   *db*))
```

**二代**，字段名参数化——但每次调用都在运行期现造闭包：

```lisp
(defun artist-selector (artist)
  (lambda (cd) (equal (getf cd :artist) artist)))
```

**三代**，`where` **宏**：宏展开期就把比较式拼成 lambda 源码交给编译器——书里管这叫 *winning big*：

```lisp
(defun make-comparison-expr (field value)
  `(equal (getf cd ,field) ,value))

(defun make-comparisons-list (fields)
  (loop while fields
     collecting (make-comparison-expr (pop fields) (pop fields))))

(defmacro where (&rest clauses)
  `(lambda (cd) (and ,@(make-comparisons-list clauses))))
```

在 REPL 里看一眼展开（示例 main.lisp 里打印了完整形态）：
没传的字段**根本不出现在生成的代码里**——不是运行期判空，是编译期就没有。查询与更新共用同一把钥匙：

```lisp
(defun select (selector-fn) (remove-if-not selector-fn *db*))

(defun update (selector-fn &key title artist rating (ripped nil ripped-p))
  (setf *db*
        (mapcar
         (lambda (row)
           (when (funcall selector-fn row)
             (when title  (setf (getf row :title)  title))
             (when artist (setf (getf row :artist) artist))
             (when rating (setf (getf row :rating) rating))
             (when ripped-p (setf (getf row :ripped) ripped)))
           row)
         *db*)))

(defun delete-rows (selector-fn)
  (setf *db* (remove-if selector-fn *db*)))
```

`(setf (getf …))` 是广义赋值（10 章）在 plist 上的投影；`ripped-p` 是 supplied-p 参数（11 章）——`ripped` 的合法值包含 NIL，只有靠它分清「没传」和「传了 NIL」。

## 28.4 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| 空 `(where)` 触发 SBCL style-warning | 展开成 `(lambda (cd) (and))`，cd 未用 | 生产版给 lambda 加 `(declare (ignore cd))` |
| 展开形态两实现打印不一样 | pretty printer 换行策略不同 | 打印 macroexpand 结果前 `(let ((*print-pretty* nil)) …)` |
| dump 出来顺序是反的 | push 头插 | reverse 一次或用 `append` |
| 中文串里写 ASCII 双引号 | 字符串提前闭合，后面的字成了代码 | 用中文引号「」或 `\"` 转义 |

## 自测

1. `where` 宏比 `artist-selector` 函数赢在哪一层？（展开期 vs 运行期）
2. `(setf (getf row :rating) 11)` 为什么能改到 plist？底层是谁提供的 setf 展开？
3. `update` 的 `(ripped nil ripped-p)` 为什么要第三个名字？
4. save/load 往返靠哪两个函数对咬？`with-standard-io-syntax` 包的是哪一侧？

---
上一章：[27 迷你 Lisp 解释器](27-minilisp.md) ｜ 下一章：[29 单元测试框架](29-pcl-testfw.md)
