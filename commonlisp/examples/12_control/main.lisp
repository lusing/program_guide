;;;; ============================================================
;;;; examples/12_control/main.lisp — 控制流与迭代
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 分支：if / when / unless / cond / case / ecase / typecase
;;;;   2. and / or：短路 + 返回的是**值**
;;;;   3. 简单迭代：dolist / dotimes
;;;;   4. loop 全姿势：for 各形态 / collect / sum / 条件 / 提前退出
;;;;   5. do / do*：最古老的通用迭代
;;;;   6. block / return-from：命名出口
;;;;   7. tagbody / go：底层跳转（认得即可）
;;;;   8. catch / throw / unwind-protect：跨函数的非局部退出
;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 分支
;;; ----------------------------------------------------------

;; if 是特殊形式：两分支；条件里**只有 NIL 是假**
(format t "if: ~A~%" (if (> 3 2) :真 :假))
(format t "0 和空串都是真: ~A~%" (if 0 :零也是真 :假))

;; when / unless：单分支、可放多条语句
(when (> 3 2)
  (format t "when: 成立，可执行多条~%")
  (format t "when: 第二条~%"))
(unless (< 3 2)
  (format t "unless: 条件为假才执行~%"))

;; cond：多路分支，从上到下第一个命中的子句生效
(defun grade (score)
  (cond ((>= score 90) :优秀)
        ((>= score 80) :良好)
        ((>= score 60) :及格)
        (t             :不及格)))
(format t "cond: 95→~A 75→~A 30→~A~%"
        (grade 95) (grade 75) (grade 30))

;; case：按键值（不求值）分发，配 otherwise
(defun day-type (day)
  (case day
    ((:monday :tuesday :wednesday :thursday :friday) :工作日)
    ((:saturday :sunday) :周末)
    (otherwise :不知道)))
(format t "case: 周一→~A 周六→~A~%" (day-type :monday) (day-type :saturday))

;; ecase：没有 otherwise，没匹配上直接报错（比 case 更严）
;; 这里故意用 handler-case 抓住，展示「错题会被抓住」而不是让它外泄
(format t "ecase 没匹配 → 报错被抓住: ~A~%"
        (handler-case (ecase 5 ((1 2 3) :命中))
          (error () :type-error-如约而至)))

;; typecase：按类型分发
(defun kind-of (x)
  (typecase x
    (integer :整数)
    (string  :字符串)
    (list    :列表)
    (t       :其他)))
(format t "typecase: 42→~A \"hi\"→~A (1 2)→~A~%"
        (kind-of 42) (kind-of "hi") (kind-of '(1 2)))


;;; ----------------------------------------------------------
;;; 2. and / or：返回的是值，不只是真假
;;; ----------------------------------------------------------

(format t "and 返回最后一个: ~A~%" (and 1 2 3))
(format t "and 短路遇到 NIL: ~S~%" (and 1 nil (error "不会执行")))
(format t "or 返回第一个真值: ~A~%" (or nil :第一个真的 :后面不看))
(format t "or 全空得 NIL: ~S~%" (or nil nil))

;; 惯用法：or 提供默认值；and 做「都成立才继续」
(let ((name nil))
  (format t "默认值: ~A~%" (or name "匿名")))


;;; ----------------------------------------------------------
;;; 3. 简单迭代
;;; ----------------------------------------------------------

(format t "dolist: ")
(dolist (item '(苹果 香蕉 樱桃))
  (format t "~A " item))
(terpri)

;; dolist 的第三个参数是「正常跑完」时的返回值
(let ((result (dolist (x '(1 2 3) :跑完了)
                (when (> x 2) (return :中途退出)))))
  (format t "dolist 返回: ~A~%" result))

(format t "dotimes: ")
(dotimes (i 5)
  (format t "~A " i))
(terpri)


;;; ----------------------------------------------------------
;;; 4. loop 全姿势
;;; ----------------------------------------------------------

;; for...in 遍历表 / for...on 遍历剩余子表
(format t "loop in: ~S~%" (loop for x in '(1 2 3) collect (* x 10)))
(format t "loop on: ~S~%" (loop for tail on '(a b c) collect (length tail)))

;; for...from/to/by 数值区间
(format t "loop from: ~S~%" (loop for i from 0 to 10 by 3 collect i))

;; 多个 for 并行推进（可带索引）
(format t "loop 并行: ~S~%"
        (loop for item in '(a b c)
              for i from 1
              collect (cons i item)))

;; collect / append / sum / count / maximize / minimize
(format t "collect 偶数: ~S~%" (loop for i from 1 to 10 when (evenp i) collect i))
(format t "sum 1..100: ~A~%" (loop for i from 1 to 100 sum i))
(format t "max/min: ~A ~A~%"
        (loop for x in '(3 1 4 1 5) maximize x)
        (loop for x in '(3 1 4 1 5) minimize x))
(format t "count: ~A~%" (loop for i from 1 to 20 count (zerop (mod i 3))))

;; always / never / thereis：三种「整表判定」
(format t "always 偶: ~A, never 偶: ~A, thereis 4: ~S~%"
        (loop for x in '(2 4 6) always (evenp x))
        (loop for x in '(1 3 5) never (evenp x))
        (loop for x in '(1 3 4) thereis (evenp x)))

;; while / until 提前结束 + finally 收尾
(format t "while: ")
(loop for i from 1
      while (< i 5)
      do (format t "~A " i)
      finally (format t "（停在 ~A）" i))
(terpri)

;; with = 循环内的一次性绑定；initially 只跑一次
(format t "with+initially: ~S~%"
        (loop with acc = 0
              initially (setf acc 100)
              for i from 1 to 3
              do (incf acc i)
              finally (return acc)))

;; 嵌套循环
(format t "嵌套: ~S~%"
        (loop for x from 1 to 3
              append (loop for y from 1 to x collect y)))


;;; ----------------------------------------------------------
;;; 5. do / do*
;;; ----------------------------------------------------------

;; do：(变量 初值 步进) 并行绑定；终止测试为真时执行结果形式
(do ((i 0 (1+ i))
     (sum 0 (+ sum i)))
    ((>= i 5) (format t "do: 1..4 之和 = ~A~%" sum)))

;; do*：顺序绑定，后面的初值/步进能看到前面的
(do* ((i 0 (1+ i))
      (square (* i i)))
     ((> i 3))
  (format t "do*: i=~A square=~A~%" i square))


;;; ----------------------------------------------------------
;;; 6. block / return-from：命名出口
;;; ----------------------------------------------------------

;; defun 自带与函数同名的隐式 block → (return-from 函数名 ...) 可退出
(defun find-first-even (lst)
  (dolist (x lst)
    (when (evenp x)
      (return-from find-first-even x)))
  :没有偶数)
(format t "命名出口: ~A / ~A~%"
        (find-first-even '(1 3 6 8))
        (find-first-even '(1 3 5)))

;; 显式 block 包住一段计算，从任意深度退出
(block search
  (dotimes (i 10)
    (when (> (* i i) 20)
      (return-from search i))))


;;; ----------------------------------------------------------
;;; 7. tagbody / go（认得即可）
;;; ----------------------------------------------------------

;; CL 的「底层 goto」：迭代宏（loop/do）就是拿它编译出来的；
;; 日常写代码用不着，但读展开后的代码会遇到
(let ((i 0))
  (tagbody
   top
     (incf i)
     (when (< i 3) (go top)))
  (format t "tagbody 循环 3 次: i=~A~%" i))


;;; ----------------------------------------------------------
;;; 8. catch / throw / unwind-protect
;;; ----------------------------------------------------------

;; catch 立桩，throw 把控制权（连同返回值）抛回最近的同名桩——
;; 可以**跨函数**非局部退出
(defun process-all (items)
  (catch :abort
    (dolist (item items)
      (when (eq item :stop)
        (throw :abort :被中止))
      (format t "  处理 ~A~%" item))
    :全部完成))
(format t "catch/throw: ~A~%" (process-all '(a b c)))
(format t "catch/throw: ~A~%" (process-all '(a :stop c)))

;; unwind-protect：无论怎么退出（正常/throw/错误），清理段必执行
(format t "unwind-protect: ~A~%"
        (catch 'exit
          (unwind-protect
               (progn
                 (format t "  [受保护段执行]~%")
                 (throw 'exit :中途抛出))
            (format t "  [清理段照样跑]~%"))))


(format t "~%==== 12 结束 ====~%")
