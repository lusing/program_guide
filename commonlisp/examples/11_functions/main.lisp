;;;; ============================================================
;;;; examples/11_functions/main.lisp — 函数、参数模型与多值
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 参数列表四件套：&optional / &rest / &key / &aux
;;;;      以及 supplied-p 变量、&allow-other-keys
;;;;   2. lambda / funcall / apply / #' 与 '
;;;;   3. 闭包三连：计数器 / 银行账户 / 记忆化
;;;;   4. 多值：values / multiple-value-bind / nth-value
;;;;   5. flet vs labels（互相递归只有 labels 行）
;;;;   6. 高阶函数：组合 / 柯里化
;;;;   7. 递归与尾调用（实测说明）
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 参数列表四件套
;;; ----------------------------------------------------------

(defun add (a b)
  "最普通的两个必需参数。docstring 写在参数表后面。"
  (+ a b))
(format t "add 3 4 = ~A~%" (add 3 4))

;; --- &optional：可省略，可带默认值，还能知道「有没有被传」---
(defun greet (name &optional (title "同学" title-supplied-p))
  (format nil "~A~A（title 由调用方给: ~A）"
          name
          (if title-supplied-p (format nil "-~A" title) "")
          title-supplied-p))
(format t "~A~%" (greet "张三"))
(format t "~A~%" (greet "李四" "博士"))

;; --- &rest：吃掉剩余的全部实参，捆成列表 ---
(defun sum-all (&rest numbers)
  (reduce #'+ numbers :initial-value 0))
(format t "sum-all 1..5 = ~A，空参 = ~A~%" (sum-all 1 2 3 4 5) (sum-all))

;; --- &key：按名字传参，顺序无关 ---
(defun make-person (name &key (age 0) (active t))
  (format nil "~A/年龄~A/活跃~A" name age active))
(format t "~A~%" (make-person "王五" :age 30))
(format t "~A~%" (make-person "赵六" :active nil :age 18))

;; --- 混合：必需 → &rest → &key（按这个顺序写）---
;; &allow-other-keys：容忍不认识的关键字。注意规则：只要写了 &key，
;; 多出来的「像关键字的参数」就必须被 &allow-other-keys 放行，否则报
;; illegal keyword——哪怕它们本来是想进 &rest 的。
;; （SBCL 对 &optional 与 &key 混用会发 style-warning，别这么写）
(defun kitchen (meal size &rest extras &key (spicy :没说)
                &allow-other-keys)
  (format nil "主餐~A 尺寸~A 加料~S 辣~A" meal size extras spicy))
(format t "~A~%" (kitchen :面 :大 :加蛋 :加葱 :spicy :微辣))

;; 转发模式：收下一切（纯 &rest），再挑出下游认识的键传过去。
;; &allow-other-keys 用在 kitchen 那种「自己声明 &key 又想容忍多余键」
;; 的场合；纯转发的写法根本不声明 &key，最省心
(defun forwarder (&rest args)
  ;; args = ("钱七" :age 40 :whatever 1)，用 getf 挑键，其余丢弃。
  ;; （若继续转发就用 apply，但 apply 的最后一个参数必须是**列表**：
  ;;   (apply #'make-person name :age age nil)  ← 别忘了结尾的 nil）
  (make-person (first args) :age (getf (rest args) :age 0)))
(format t "转发不认识的关键字也不报错: ~A~%"
        (forwarder "钱七" :age 40 :whatever 1))

;; --- &aux：纯局部变量（不如 let 清晰，认得即可）---
(defun area (r &aux (r2 (* r r)))
  (* 3.14d0 r2))
(format t "&aux 算半径 2 的面积: ~A~%" (area 2.0d0))


;;; ----------------------------------------------------------
;;; 2. lambda / funcall / apply / #'
;;; ----------------------------------------------------------

;; lambda 造匿名函数；用 funcall 直接调用
(format t "funcall lambda: ~A~%" (funcall (lambda (x) (* x x)) 6))

;; apply 把「最后一个列表参数」展开成实参
(format t "apply: ~A~%" (apply #'+ 1 2 '(3 4 5)))

;; #' 是 (function ...) 的缩写：取函数对象；' 只是 quote（拿到符号）
(format t "#'car 是函数: ~A~%" (functionp #'car))
(format t "'car 是符号不是函数: ~A~%" (symbolp 'car))


;;; ----------------------------------------------------------
;;; 3. 闭包三连
;;; ----------------------------------------------------------

;; ① 计数器：每个实例独立
(defun make-counter ()
  (let ((count 0))
    (lambda () (incf count))))
(let ((c1 (make-counter)) (c2 (make-counter)))
  (funcall c1) (funcall c1) (funcall c1)
  (format t "闭包计数: c1 → ~A, c2 → ~A（互不干扰）~%"
          (funcall c1) (funcall c2)))

;; ② 银行账户：闭包即对象（消息风格）
(defun make-account (balance)
  (lambda (op &optional amount)
    (case op
      (:deposit  (incf balance amount))
      (:withdraw (if (>= balance amount)
                     (decf balance amount)
                     :余额不足))
      (:balance  balance))))
(let ((acc (make-account 100)))
  (format t "开户 100，存 50 → ~A~%" (funcall acc :deposit 50))
  (format t "取 30 → ~A，余额 → ~A~%"
          (funcall acc :withdraw 30) (funcall acc :balance))
  (format t "取 999 → ~A~%" (funcall acc :withdraw 999)))

;; ③ 记忆化：哈希表藏在闭包里
(defun memoize (fn)
  (let ((cache (make-hash-table)))
    (lambda (x)
      (multiple-value-bind (hit found) (gethash x cache)
        (if found
            hit
            (setf (gethash x cache) (funcall fn x)))))))
(let ((slow (memoize (lambda (x)
                       (format t "    [真的算了 ~A 一次]~%" x)
                       (* x x)))))
  (format t "第一次: ~A~%" (funcall slow 9))
  (format t "第二次: ~A（命中缓存，没有重算）~%" (funcall slow 9)))


;;; ----------------------------------------------------------
;;; 4. 多值
;;; ----------------------------------------------------------

;; values 返回多个值；接收方按需取
(defun divmod (a b)
  (values (floor a b) (mod a b)))

(multiple-value-bind (q r) (divmod 17 5)
  (format t "17÷5 → 商 ~A 余 ~A~%" q r))
(format t "只要第二个: ~A~%" (nth-value 1 (divmod 17 5)))
(format t "全部收成表: ~S~%" (multiple-value-list (divmod 17 5)))

;; 「没接住」的多值被丢弃——只保留第一个值
(format t "当普通实参用: ~A（余数被丢掉）~%" (1+ (divmod 17 5)))


;;; ----------------------------------------------------------
;;; 5. flet vs labels
;;; ----------------------------------------------------------

;; flet：各玩各的——兄弟函数**互相看不见**。它的正当用途是「临时
;; 替换/遮蔽」：在一段代码里把某个已有函数换成自己的版本。
;; 注意只能遮蔽自己包里的函数——SBCL 对 COMMON-LISP 包上了锁，
;; 连 flet 绑定 1+ 这种「局部遮蔽」都会被拦（CLISP 则放行），这是
;; 两实现的差异之一，跨实现代码别碰 CL 包的名字
(defun scale-2x (x) (* x 2))
(flet ((scale-2x (x) (* x 100)))       ; 临时换成 ×100 版
  (format t "flet 遮蔽: (scale-2x 3) = ~A~%" (scale-2x 3)))
(format t "出了 flet 恢复: (scale-2x 3) = ~A~%" (scale-2x 3))

;; 想让局部函数互相调用/递归，必须用 labels（下一节）；
;; 在 flet 里引用兄弟函数等于引用外层的同名函数（没有就是未定义）

;; labels：彼此可见，可递归、可互调
(labels ((my-even-p (n) (if (zerop n) t (my-odd-p (1- n))))
         (my-odd-p  (n) (if (zerop n) nil (my-even-p (1- n)))))
  (format t "labels 互调: even 10 → ~A, odd 7 → ~A~%"
          (my-even-p 10) (my-odd-p 7)))


;;; ----------------------------------------------------------
;;; 6. 高阶函数
;;; ----------------------------------------------------------

;; 组合：把两个函数串成一个
(defun compose (f g)
  (lambda (&rest args) (funcall f (apply g args))))
(let ((inc-then-double (compose (lambda (x) (* 2 x)) #'1+)))
  (format t "compose: (2×(x+1))(5) = ~A~%" (funcall inc-then-double 5)))

;; 柯里化：返回「带配置的新函数」
(defun make-adder (n)
  (lambda (x) (+ x n)))
(let ((add-10 (make-adder 10)))
  (format t "柯里化 add-10(32) = ~A~%" (funcall add-10 32)))


;;; ----------------------------------------------------------
;;; 7. 递归与尾调用
;;; ----------------------------------------------------------

(defun factorial (n)
  (if (<= n 1) 1 (* n (factorial (1- n)))))
(format t "10! = ~A~%" (factorial 10))

;; 尾递归形式（累加器版本）
(defun sum-to (n &optional (acc 0))
  (if (zerop n) acc (sum-to (1- n) (+ acc n))))
(format t "sum-to 1000（尾位置自调用）= ~A~%" (sum-to 1000))
;; 深度实测（坑）：SBCL 对尾调用做优化，100000 层不炸栈；
;; CLISP 的尾调用优化有限——实测约 5000 层就 Lisp stack overflow。
;; 跨实现的深递归请改写成 loop（12 章），别赌尾调用


(format t "~%==== 11 结束 ====~%")
