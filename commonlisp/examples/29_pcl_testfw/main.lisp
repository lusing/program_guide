;;;; ============================================================
;;;; examples/29_pcl_testfw/main.lisp — Practical: 单元测试框架
;;;; channel: both   （书 9 章：Building a Unit Test Framework）
;;;; ============================================================
;;;;
;;;; 本例程重演书里的框架演化：
;;;;   1. report-result + format 的 ~:[FAIL~;pass~] 双分支指令
;;;;   2. check 宏（naive 版 → combine-results 修返回值泄漏）
;;;;   3. deftest 宏 + 动态变量 *test-name*（嵌套测试的全名追踪）
;;;;   4. 失败不中断：restart-case 挂 continue-check + handler-bind 自动续跑
;;;;   5. 条件类型分层：check-failure / test-failure
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 报告一个结果：~:[假取第一个子句；真取第二个~]
;;; ----------------------------------------------------------

(defparameter *test-name* nil)

(defun report-result (result form)
  ;; ~:[FAIL~;pass~]：一个指令同时管"对钩叉"—学 format 指令配对的经典一课
  (format t "~:[FAIL~;pass~] ... ~a: ~a~%" result *test-name* form)
  result)

(format t "── 1. 手工调 report-result~%")
(report-result (= (+ 1 2) 3) '(= (+ 1 2) 3))
(report-result (= (+ 1 2) 4) '(= (+ 1 2) 4))

;;; ----------------------------------------------------------
;;; 2. check 宏：先 naive，再修返回值泄漏
;;; ----------------------------------------------------------

;; naive 版：直接 progn——能打印，但整个 check 的返回值是最后一个结果（泄漏）
(defmacro check-naive (&body forms)
  `(progn
     ,@(loop for f in forms collect `(report-result ,f ',f))))

(format t "~%── 2a. check-naive（四个全打，返回值是最后一个的 T/NIL 泄漏）~%")
(let ((r (check-naive (= (+ 1 2) 3) (= (+ 1 2) 4))))
  (format t "check-naive 返回值: ~S~%" r))

;; 修好版：combine-results 收集"有没有失败"，返回单一布尔
(defmacro combine-results (&body forms)
  (let ((result (gensym)))
    `(let ((,result t))
       ,@(loop for f in forms collect `(unless ,f (setf ,result nil)))
       ,result)))

(defmacro check (&body forms)
  `(combine-results
     ,@(loop for f in forms collect `(report-result ,f ',f))))

(format t "~%── 2b. check（同样的四条，返回值是「整组通过与否」）~%")
(let ((r (check (= (+ 1 2) 3) (= (+ 1 2) 4))))
  (format t "check 返回值: ~S~%" r))

;;; ----------------------------------------------------------
;;; 3. deftest 宏：动态变量 *test-name* + 嵌套全名
;;; ----------------------------------------------------------

;; 书里的关键洞察：*test-name* 是**动态变量**——嵌套 deftest 时内层
;; 的 let 会暂时遮蔽外层，退出后自动还原，全名用 append 链起来。
(defmacro deftest (name parameters &body body)
  `(defun ,name ,parameters
     (let ((*test-name* (append *test-name* (list ',name))))
       ,@body)))

(deftest test-+ ()
  (check (= (+ 1 2) 3)
         (= (+ -1 -1) -2)))

(deftest test-* ()
  (check (= (* 2 2) 4)
         (= (* 3 5) 15)))

;; 嵌套：test-arithmetic 跑自己的 check，再调用两个子测试
;; 子测试里的 *test-name* 自动带上父名前缀
(deftest test-arithmetic ()
  (check (= 0 0))               ; 自己也有一条
  (test-+)
  (test-*))

(format t "~%── 3. 嵌套 deftest：名字自动带全路径~%")
(test-arithmetic)

;;; ----------------------------------------------------------
;;; 4. 失败不中断：条件 + 重启的实战
;;; ----------------------------------------------------------

(define-condition check-failure (error)
  ((failed-form :initarg :failed-form :reader failed-form)))

(defparameter *tests* nil)

;; report-result 升级：失败时 signal check-failure，但把"继续跑"
;; 注册成重启点（不关心谁接、怎么接——检测与策略分离）
(defun report-result (result form)
  (restart-case
      (progn
        (format t "~:[FAIL~;pass~] ... ~a: ~a~%" result *test-name* form)
        (unless result
          (error 'check-failure :failed-form form))
        t)
    (continue-check ()
      :report "Continue running tests."
      (format t "   （continue-check 重启：接着跑）~%")
      nil)))

;; check 的 combine-results 会因 nil 而短路收尾——把 unless 换成不中断的写法
(defmacro check (&body forms)
  `(combine-results
     ,@(loop for f in forms collect `(report-result ,f ',f))))

;; deftest 升级：注册进 *tests*，body 外套 handler-bind——
;; **自动策略**：遇到 check-failure 就调用 continue-check 重启
(defmacro deftest (name parameters &body body)
  `(progn
     (defun ,name ,parameters
       (let ((*test-name* (append *test-name* (list ',name))))
         (handler-bind
             ((check-failure
                (lambda (c)
                  (format t "   [handler-bind 接住 ~a，调用重启]~%" (type-of c))
                  (invoke-restart 'continue-check))))
           ,@body)))
     (setf *tests* (append *tests* (list ',name)))
     ',name))

(defun run-tests ()
  (dolist (name *tests*)
    (format t "▶ 跑 ~a~%" name)
    (funcall (symbol-function name))))

;; 故意放两条会挂的：2b 里那条 (+ 1 2) 4 与 (* 2 3) 7
(deftest test-fail-demo ()
  (check (= (+ 1 2) 4)        ; ← 挂，但 continue-check 让后面的继续
         (= (+ 2 3) 5)))

(format t "~%── 4. 失败不中断：check-failure + continue-check~%")
(run-tests)

(format t "~%── 4b. 手动调用重启的长相（REPL 场景脑补）~%")
;; 重启点的存在可以用 compute-restarts 看到——不同实现在别的场合有
;; 额外的系统重启，所以只数我们注册的那个，保证输出可移植
(handler-bind ((check-failure (lambda (c) (declare (ignore c)) (invoke-restart 'continue-check))))
  (let ((n (count-if (lambda (r)
                       (string= "CONTINUE-CHECK" (string (restart-name r))))
                     (compute-restarts))))
    (format t "compute-restarts 里有 continue-check: ~A~%" (if (> n 0) "有（>0 个）" "无"))))

(format t "~%==== 29 结束 ====~%")
