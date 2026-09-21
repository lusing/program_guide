;;;; ============================================================
;;;; examples/13_types/main.lisp — 类型系统与声明
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. typep / subtypep：类型是**运行期的一等对象**
;;;;   2. 类型层级：number 家族与 fixnum/bignum 的关系
;;;;   3. 类型说明符的四种写法：名字 / 成员列表 / 满足谓词 / 组合
;;;;   4. deftype：定义自己的类型说明符（还带参数！）
;;;;   5. check-type / assert / ecase：三道防线
;;;;   6. the 与 declare：给编译器的**承诺**（错了后果自负）
;;;;   7. type-of：认得，但别拿它做逻辑（输出是实现细节）
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. typep / subtypep
;;; ----------------------------------------------------------

(format t "typep 42 integer: ~A~%" (typep 42 'integer))
(format t "typep 3.14 float: ~A~%" (typep 3.14 'float))
(format t "typep \"ab\" string: ~A~%" (typep "ab" 'string))
(format t "typep '(1) list: ~A~%" (typep '(1) 'list))

;; subtypep 返回两值：是否子类型 + 是否能判定（第二个为 NIL 表示「未知」）
(format t "fixnum ⊂ integer: ~A~%" (subtypep 'fixnum 'integer))
(format t "integer ⊂ number: ~A~%" (subtypep 'integer 'number))
(format t "string 与 number 不相交: ~A~%"
        (nth-value 0 (subtypep 'string 'number)))


;;; ----------------------------------------------------------
;;; 2. 类型层级速览
;;; ----------------------------------------------------------

;; 数字塔：integer ⊂ rational ⊂ real ⊂ number；float 与 rational 并列
(format t "1/3 是 rational: ~A，也是 real: ~A~%"
        (typep 1/3 'rational) (typep 1/3 'real))
(format t "单双精度都是 float: ~A ~A~%"
        (typep 1.0f0 'float) (typep 1.0d0 'float))
(format t "复数是 number 不是 real: ~A ~A~%"
        (typep #c(1 2) 'number) (typep #c(1 2) 'real))

;; fixnum/bignum：位宽是实现细节（SBCL 62 位 / CLISP 48 位），
;; 但「小整数是 fixnum、大整数自动升 bignum」这个事实跨实现成立
(format t "小的 100 是 fixnum: ~A~%" (typep 100 'fixnum))
(format t "2^100 只能是 bignum: ~A~%"
        (typep (expt 2 100) 'bignum))


;;; ----------------------------------------------------------
;;; 3. 类型说明符的四种写法
;;; ----------------------------------------------------------

;; ① 名字
(format t "① 名字: ~A~%" (typep 5 'integer))

;; ② 成员列表：(member ...)
(format t "② member: ~A ~A~%"
        (typep :north '(member :north :south)) (typep :west '(member :north :south)))

;; ③ 区间：(integer 起 止)
(format t "③ 区间: 3 在 [1,10] → ~A~%" (typep 3 '(integer 1 10)))
(format t "   闭开区间 (1 10]: ~A~%" (typep 1 '(integer (1) 10)))

;; ④ 满足谓词：(satisfies 谓词)
(format t "④ satisfies: 偶数谓词 → ~A~%"
        (typep 4 '(satisfies evenp)))

;; 组合：and / or / not
(format t "组合: 1..100 的偶数 → ~A~%"
        (typep 42 '(and (integer 1 100) (satisfies evenp))))
(format t "not: 不是 nil → ~A~%" (typep 0 '(not null)))


;;; ----------------------------------------------------------
;;; 4. deftype：自定义类型说明符
;;; ----------------------------------------------------------

;; deftype 像 defmacro 一样「编译期展开成类型说明符」，还能带参数。
;; 坑：`(list integer)` 这种「带元素类型的 list」**不是**合法类型说明符
;; （vector/array 可以带元素类型，list 不行——两个实现都直接报
;; bad thing to be a type specifier）。想要元素类型约束，用 satisfies
(defun integer-list-p (x)
  (and (listp x) (every #'integerp x)))

(deftype list-of-integer ()
  "全是整数的表。"
  `(satisfies integer-list-p))

(deftype int-at-least (n)
  "不小于 N 的整数（演示 deftype 带参数）。"
  `(and integer (integer ,n)))

(format t "deftype list-of-integer: ~A ~A~%"
        (typep '(1 2 3) 'list-of-integer)
        (typep '("a") 'list-of-integer))
(format t "deftype 带参数: (typep 5 '(int-at-least 3)) = ~A，2 → ~A~%"
        (typep 5 '(int-at-least 3)) (typep 2 '(int-at-least 3)))


;;; ----------------------------------------------------------
;;; 5. 三道防线：check-type / assert / ecase
;;; ----------------------------------------------------------

;; check-type：不满足就地报「可修正的类型错误」，错误信息带期望类型。
;; 通过的例子直接跑；失败的例子放函数参数后面——把值藏在参数里，
;; 编译器推导不出类型，check-type 才留到运行期报（写在 let 里
;; SBCL 会在**编译期**就发现 string 不是 integer，warning 打到 stderr）
(format t "check-type 通过的调用: ~A~%"
        (handler-case
            (let ((x 42))
              (check-type x integer)
              :x-是整数)
          (type-error (e)
            (list :被拦截 (type-of e) (type-error-expected-type e)))))

(defun check-thing (x)
  (handler-case
      (progn (check-type x integer) :x-是整数)
    (type-error (e)
      ;; 只打印我们控制的字段，别打印 e 本体——
      ;; 报错文本是实现细节，两个实现写得不一样
      (list :期望 (type-error-expected-type e)))))

(format t "check-type 失败被抓住: ~A~%" (check-thing "不是数"))

;; assert：可指定地点表达式与重试信息
(format t "assert 拦截: ~A~%"
        (handler-case
            (progn
              (assert (= 1 2) () "1 居然不等于 2")
              :不可能到这)
          (error (e) (declare (ignore e)) :断言失败被抓住)))

;; ecase：case 的严格版（12 章演示过，这里作为类型防线凑齐三件套）
(format t "ecase 拦截: ~A~%"
        (handler-case (ecase :blue ((:red) :红) ((:green) :绿))
          (error (e) (declare (ignore e)) :没有这个分支)))


;;; ----------------------------------------------------------
;;; 6. the 与 declare：给编译器的承诺
;;; ----------------------------------------------------------

;; the 不做任何检查，只是「承诺」：编译器据此生成更快的代码。
;; 承诺错了 → 未定义行为（SBCL 高速档下可能直接算错），别乱用
(defun fast-double (x)
  (declare (type integer x))
  (the integer (* x 2)))

(format t "声明的函数照常工作: ~A~%" (fast-double 21))

;; 与 check-type 的对照：check-type 是**检查**（错了报错），the 是**承诺**
;;（错了Undefined）。SBCL 里 (the fixnum ...) 配 (optimize (speed 3))
;; 才有肉眼可见的收益（26 章实测）；CLISP 主要是解释执行，声明的收益
;; 有限——这也是「性能代码看实现」的一部分


;;; ----------------------------------------------------------
;;; 7. type-of：认得即可
;;; ----------------------------------------------------------

;; type-of 返回「能唯一确定该值的最窄类型」，但**形态是实现自由**：
;;   (type-of "ab")  SBCL → (SIMPLE-ARRAY CHARACTER (2))
;;                   CLISP → (SIMPLE-BASE-STRING 2)
;; 所以：做类型判断用 typep，做逻辑别依赖 type-of 的具体输出
(format t "用 typep 判断字符串: ~A（而不是比对 type-of 的输出）~%"
        (typep "ab" 'string))
(format t "coerce 换类型: ~S ~S~%"
        (coerce "ab" 'list) (coerce '(#\a #\b) 'string))

(format t "~%==== 13 结束 ====~%")
