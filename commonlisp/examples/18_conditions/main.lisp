;;;; ============================================================
;;;; examples/18_conditions/main.lisp — 条件系统与重启
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 三档发信：signal < warn < error
;;;;   2. handler-case：像 try/catch（栈已展开）
;;;;   3. handler-bind：处理时栈**没**展开 → 能选择重启继续跑
;;;;   4. define-condition：带数据、带 :report 的自定义条件
;;;;   5. restart-case / invoke-restart：报错之后还能接着干
;;;;   6. muffle-warning / ignore-errors / with-simple-restart
;;;;
;;;; 输出约定：内置条件的报错文本是实现细节（SBCL/CLISP 措辞不同），
;;;; 本示例只打印自己写的文本与 (type-of 条件)，保证跨实现一致。
;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 三档发信
;;; ----------------------------------------------------------

;; signal：发一个「条件」，没人处理就静默返回
(handler-bind ((warning (lambda (w)
                          (format t "  [handler 看见警告] 类型 ~A~%" (type-of w))
                          (muffle-warning w))))
  (warn "这条警告会被 handler 吃掉（不落到 stderr）"))
(format t "signal/warn 之后程序继续~%")

;; warn 默认把文本打到 *error-output*（= stderr）；想要它进 stdout，
;; 把 *error-output* 动态绑到 *standard-output* 即可（动态作用域的用处）
(let ((*error-output* *standard-output*))
  (warn "这条警告改道 stdout"))
(format t "上两行中间那条 WARNING 就是 warn 的默认输出格式~%")

;; error：没人处理就进调试器（脚本模式 = 直接退出）——下面全部接住
(format t "error 被接住: ~A~%"
        (handler-case (error "故意的")
          (error (e) (declare (ignore e)) :捕获成功)))


;;; ----------------------------------------------------------
;;; 2. handler-case：展开栈再处理
;;; ----------------------------------------------------------

;; 类似 try/catch：匹配条件类型，进入子句时调用栈已经展开。
;; 顺带见识 SBCL 的静态检查：把除零写成**字面量** (/ 1 0) 它在编译期
;; 就发 warning 到 stderr——所以这里走函数参数，把检查留到运行期
(defun div-by (n d) (/ n d))

(handler-case
    (progn
      (format t "  里层开始~%")
      (div-by 1 0))                     ; 内置条件：除零
  (division-by-zero ()
    (format t "handler-case 除零: 捕获 division-by-zero~%")))

;; 多个子句按顺序匹配；no-error 子句：没出错时走这里。
;; 坑：no-error 的形参表要接住身体的**全部返回值**——parse-integer
;; 返回两值 (整数 位置)，只写 (v) 在 CLISP 上直接报
;; too many arguments given to :LAMBDA（SBCL 宽容），加 &rest 才跨实现
(handler-case
    (parse-integer "42")
  (error () :失败)
  (:no-error (v &rest rest)
    (format t "handler-case 解析成功: ~A（其余返回值 ~S）~%" v rest)))

;; 返回值：命中的子句的值就是整个表达式的值
(format t "兜底默认值: ~A~%"
        (handler-case (parse-integer "abc")
          (parse-error () -1)))


;;; ----------------------------------------------------------
;;; 3. define-condition：自定义条件带数据
;;; ----------------------------------------------------------

(define-condition validation-error (error)
  ((field :initarg :field :reader validation-error-field)
   (value :initarg :value :reader validation-error-value)
   (hint  :initarg :hint  :initform "" :reader validation-error-hint))
  (:report (lambda (c stream)
             ;; :report 决定 (format "~A" c) 的样子——自己写，跨实现一致
             (format stream "字段 ~S 的值 ~S 无效~@[（~A）~]"
                     (validation-error-field c)
                     (validation-error-value c)
                     (validation-error-hint c)))))

(defun validate-age (age)
  (unless (and (integerp age) (<= 0 age 150))
    (error 'validation-error :field "age" :value age :hint "0 到 150"))
  :通过)

(handler-case (validate-age 30)
  (validation-error () :不该到这))
(handler-case (validate-age 999)
  (validation-error (e)
    (format t "自定义条件报告: ~A~%" e)
    (format t "取字段: ~S = ~S~%"
            (validation-error-field e) (validation-error-value e))))


;;; ----------------------------------------------------------
;;; 4. handler-bind + 重启：不展开栈的恢复
;;; ----------------------------------------------------------

;; 低层函数只管「出事了」+ 提供恢复策略（重启），
;; 高层决定**选哪个策略**——职责分离是条件系统的灵魂。
;; 注意：带参数的重启在 CLISP 上必须给 :interactive（调试器里选中时
;; 用它收集参数），否则加载时就发 warning 到 stderr；SBCL 则无所谓
(defun parse-config (raw)
  (restart-case
      (if (stringp raw)
          (list :config raw)
          (error 'validation-error :field "config" :value raw))
    (use-empty () :report "改用空配置" (list :config :empty))
    (treat-as-string (s) :report "把值转成字符串"
      :interactive (lambda () (list "默认串"))
      (list :config (format nil "~A" s)))))

;; 高层 1：选「用空配置」
(handler-bind ((validation-error
                (lambda (e)
                  (declare (ignore e))
                  (invoke-restart 'use-empty))))
  (format t "策略-空配置: ~S~%" (parse-config 42)))

;; 高层 2：同一份低层代码，选另一个重启（传参版）
(handler-bind ((validation-error
                (lambda (e)
                  (invoke-restart 'treat-as-string
                                  (validation-error-value e)))))
  (format t "策略-转字符串: ~S~%" (parse-config 42)))

;; 这就是「检测与策略分离」：parse-config 从不知道谁在调它，
;; 换一个 handler-bind 就换一种恢复方式


;;; ----------------------------------------------------------
;;; 5. 重启的交互式用法（说明）与 with-simple-restart
;;; ----------------------------------------------------------
;;;;
;;;; restart-case 的 :interactive 给「调试器里按回车后收集重启参数」的
;;;; 函数——交互式开发时，SBCL/CLISP 的调试器会把所有重启列成菜单，
;;;; 光标选一个就能从错误点继续。脚本模式下没有调试器，我们用
;;;; handler-bind + invoke-restart 程序化选择（上面那样）。

;; with-simple-restart：只挂一个「直接重试/跳过」的简单重启
(format t "简单重启: ~A~%"
        (handler-bind ((error (lambda (e)
                                (declare (ignore e))
                                (invoke-restart 'just-skip))))
          (with-simple-restart (just-skip "跳过这段")
            (error "又出事了")
            :不会执行)))


;;; ----------------------------------------------------------
;;; 6. ignore-errors 与实用小件
;;; ----------------------------------------------------------

;; ignore-errors：两值 = 结果 / 条件（出错时结果为 NIL）。
;; 条件的具体类名可能带实现私有包前缀（SBCL 的 SB-INT:SIMPLE-PARSE-ERROR
;; / CLISP 的 SYSTEM::SIMPLE-PARSE-ERROR）——打印 symbol-name 才一致
(multiple-value-bind (v c) (ignore-errors (parse-integer "x"))
  (format t "ignore-errors: 结果 ~S 条件名 ~S~%"
          v (and c (symbol-name (type-of c)))))

;; 实用三件套：or + ignore-errors 给默认值；handler-case 转换错误
(format t "带默认值: ~A~%"
        (or (ignore-errors (parse-integer "108")) 0))

;; 嵌套 handler：内层转换、外层兜底
(handler-case
    (handler-case (error 'validation-error :field "x" :value 1)
      (validation-error (e) (error "内层转译: ~A" e)))
  (error (e) (format t "外层收到转译: ~A~%" e)))


;;; ----------------------------------------------------------
;;; 7. check-type / assert 快查（13 章详讲）
;;; ----------------------------------------------------------

(format t "check-type 通过: ~A~%"
        (handler-case (let ((n 5))
                        (check-type n (integer 0 9))
                        :范围内)
          (error () :范围外)))


(format t "==== 18 结束 ====~%")
