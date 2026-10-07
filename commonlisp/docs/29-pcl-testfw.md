# 29 · Practical：单元测试框架（书 9 章）

> 配套示例：[`examples/29_pcl_testfw/`](../examples/29_pcl_testfw/main.lisp)（channel: both）
>
> 《Practical Common Lisp》第 9 章：几十行写出一个"能用的"测试框架。

> **本章你将学会**：`~:[...~;...]` 双分支指令、`check`/`combine-results` 宏的返回值语义、动态变量做**测试名追踪**、**失败不中断**的条件 + 重启实战（18 章的落地应用）。
> **前置章节**：10（动态变量）、14（宏 I）、18（条件系统）。

## 29.1 报告结果：一条 format 打对钩叉

```lisp
(defparameter *test-name* nil)

(defun report-result (result form)
  ;; ~:[FAIL~;pass~]：条件为假取第一个子句，为真取第二个
  (format t "~:[FAIL~;pass~] ... ~a: ~a~%" result *test-name* form)
  result)
```

`~:[` 是 format 的布尔二选一指令——一个指令同时管 ✔/✘ 的排版，书里最津津乐道的一行。

## 29.2 check 宏：从返回值泄漏到 combine-results

naive 版能用，但整个 `check` 的返回值是**最后一个表达式的值**——调用方拿到半截信息：

```lisp
(defmacro check-naive (&body forms)
  `(progn
     ,@(loop for f in forms collect `(report-result ,f ',f))))
```

修法是把「有没有失败」收拢成单一布尔——`combine-results`：

```lisp
(defmacro combine-results (&body forms)
  (let ((result (gensym)))
    `(let ((,result t))
       ,@(loop for f in forms collect `(unless ,f (setf ,result nil)))
       ,result)))

(defmacro check (&body forms)
  `(combine-results
     ,@(loop for f in forms collect `(report-result ,f ',f))))
```

`(check (= 1 1) (= 1 2))` → 打两行报告，返回 `NIL`。gensym 防捕获（15 章）在这里就已经用上了。

## 29.3 deftest：动态变量串起嵌套全名

`*test-name*` 是**动态变量**——嵌套 deftest 时内层 `let` 暂时遮蔽、退出自动还原，全名用 `append` 链：

```lisp
(defmacro deftest (name parameters &body body)
  `(defun ,name ,parameters
     (let ((*test-name* (append *test-name* (list ',name))))
       ,@body)))
```

```lisp
(deftest test-+ () (check (= (+ 1 2) 3) (= (+ -1 -1) -2)))
(deftest test-arithmetic () (check (= 0 0)) (test-+))
```

`test-arithmetic` 里调 `test-+` 时，后者看到的 `*test-name*` 是 `(TEST-ARITHMETIC TEST-+)`——报告自带全路径。词法变量做不到这件事：内层根本看不见外层的运行期绑定。

## 29.4 失败不中断：18 章的重启落地

检测与策略分离（18 章的核心口号）在测试框架里的形态：

```lisp
(define-condition check-failure (error)
  ((failed-form :initarg :failed-form :reader failed-form)))

;; 检测方：失败就 signal，但把「继续跑」注册成重启点
(defun report-result (result form)
  (restart-case
      (progn
        (format t "~:[FAIL~;pass~] ... ~a: ~a~%" result *test-name* form)
        (unless result (error 'check-failure :failed-form form))
        t)
    (continue-check ()
      :report "Continue running tests."
      (format t "   （continue-check 重启：接着跑）~%")
      nil)))

;; 策略方：deftest 自动续跑
(defmacro deftest (name parameters &body body)
  `(progn
     (defun ,name ,parameters
       (let ((*test-name* (append *test-name* (list ',name))))
         (handler-bind
             ((check-failure
                (lambda (c) (invoke-restart 'continue-check))))
           ,@body)))
     (setf *tests* (append *tests* (list ',name)))
     ',name))
```

`report-result` **不关心**谁接、怎么接；deftest 的 `handler-bind` 决定「调用重启继续」。REPL 里手动跑时你还能在调试器里选 *Continue running tests.*——同一套检测，两种策略，零改动。

## 29.5 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| 中文串里写 ASCII 双引号 | 字符串提前闭合，后面成了代码 | 中文引号「」 |
| 报告里的表单两实现打印不一 | pretty printer 折行 | 打印前关 `*print-pretty*` |
| 二次 deftest/define-condition 报重定义 | 演化式代码在同一文件里重定义 | 同文件重定义两实现都沉默；跨文件才警告 |
| `compute-restarts` 直接全量打印 | 列表里混着实现自带的系统重启 | 只数自己注册的那个名字 |

## 自测

1. `~:[FAIL~;pass~]` 的两个子句分别在什么条件下取用？
2. `combine-results` 为什么必须 gensym？换成用户可写的名字会怎样？
3. 嵌套 deftest 的全名追踪为什么**必须**是动态变量？
4. `restart-case` 挂在 report-result 里、`handler-bind` 挂在 deftest 里——为什么不能反过来？

---

上一章：[28 简易 CD 数据库](28-pcl-db.md) · 下一章：[30 可移植路径名库](30-pcl-pathname.md)
