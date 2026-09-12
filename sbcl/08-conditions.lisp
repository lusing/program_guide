;;;; ============================================================
;;;; 08-conditions.lisp — 条件系统（异常处理）
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. handler-case — 类似 try/catch
;;;;   2. handler-bind — 底层条件处理
;;;;   3. define-condition — 自定义条件
;;;;   4. restart-case — 重启机制（Lisp 独有）
;;;;   5. signal / warn / error
;;;;   6. ignore-errors
;;;;   7. 条件系统的实际应用
;;;;
;;;; Common Lisp 的条件系统是其最强大的特性之一，
;;;; 它将"错误检测"与"错误处理策略"分离，
;;;; 允许在不展开栈的情况下恢复执行。
;;;;
;;;; 运行方式：sbcl --script 08-conditions.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. handler-case — 基本错误处理
;;; ----------------------------------------------------------

(format t "~%=== handler-case ===~%")

;; 基本用法：捕获特定类型的错误
(handler-case
    (progn
      (format t "尝试除法...~%")
      (/ 1 0))
  (division-by-zero (e)
    (format t "捕获到除零错误: ~A~%" e)))

;; 捕获多种错误类型
(handler-case
    (progn
      (parse-integer "not-a-number"))
  (simple-error (e)
    (format t "解析错误: ~A~%" e))
  (error (e)
    (format t "一般错误: ~A~%" e)))

;; 带返回值
(let ((result (handler-case
                  (/ 10 2)
                (error () -1))))
  (format t "结果: ~A~%" result))

(let ((result (handler-case
                  (/ 10 0)
                (error () -1))))
  (format t "错误时结果: ~A~%" result))

;; :no-error 子句
(handler-case
    (parse-integer "42")
  (error () (format t "解析失败~%"))
  (:no-error (value)
    (format t "解析成功: ~A~%" value)))


;;; ----------------------------------------------------------
;;; 2. define-condition — 自定义条件
;;; ----------------------------------------------------------

(format t "~%=== define-condition ===~%")

;; 定义自定义条件类型
(define-condition validation-error (error)
  ((field    :initarg :field    :reader validation-error-field)
   (value    :initarg :value    :reader validation-error-value)
   (message  :initarg :message  :reader validation-error-message
             :initform "验证失败"))
  (:report (lambda (condition stream)
             (format stream "验证错误: 字段 '~A' 的值 '~A' 无效。~A"
                     (validation-error-field condition)
                     (validation-error-value condition)
                     (validation-error-message condition))))
  (:documentation "数据验证错误"))

;; 定义更具体的条件
(define-condition age-validation-error (validation-error)
  ()
  (:documentation "年龄验证错误"))

(define-condition email-validation-error (validation-error)
  ()
  (:documentation "邮箱验证错误"))

;; 抛出自定义条件
(defun validate-user (name age email)
  (when (or (null name) (string= name ""))
    (error 'validation-error
           :field "name" :value name
           :message "姓名不能为空"))
  (when (or (< age 0) (> age 150))
    (error 'age-validation-error
           :field "age" :value age
           :message "年龄必须在 0-150 之间"))
  (when (not (find #\@ email))
    (error 'email-validation-error
           :field "email" :value email
           :message "邮箱格式不正确"))
  (format t "验证通过: ~A~%" name))

;; 捕获自定义条件
(handler-case
    (validate-user "张三" 25 "zhang@example.com")
  (validation-error (e)
    (format t "~A~%" e)))

(handler-case
    (validate-user "" 25 "zhang@example.com")
  (validation-error (e)
    (format t "~A~%" e)))

(handler-case
    (validate-user "李四" -5 "li@example.com")
  (age-validation-error (e)
    (format t "年龄错误: ~A~%" e))
  (validation-error (e)
    (format t "验证错误: ~A~%" e)))

(handler-case
    (validate-user "王五" 30 "invalid-email")
  (email-validation-error (e)
    (format t "邮箱错误: ~A~%" e)))


;;; ----------------------------------------------------------
;;; 3. signal / warn / error
;;; ----------------------------------------------------------

(format t "~%=== signal / warn / error ===~%")

;; error — 不可继续的错误（进入调试器或终止）
;; (error "这是一个错误")

;; warn — 发出警告（默认打印到 *error-output*，继续执行）
(define-condition custom-warning (warning)
  ((message :initarg :message :reader warning-message))
  (:report (lambda (c s) (format s "自定义警告: ~A" (warning-message c)))))

(warn 'custom-warning :message "这是一个警告")

;; signal — 发送条件信号（不进入调试器，除非有 handler）
(define-condition info-condition (condition)
  ((message :initarg :message :reader info-message)))

(handler-bind ((info-condition
                (lambda (c)
                  (format t "收到信号: ~A~%" (info-message c)))))
  (signal 'info-condition :message "这是一条信息"))

;; cerror — 可继续的错误
(defun safe-divide (a b)
  (if (zerop b)
      (cerror "返回 0 继续" "除数为 0")
      (/ a b)))

;; 在脚本中，cerror 会自动选择 continue restart
(format t "safe-divide(10, 2) = ~A~%" (safe-divide 10 2))


;;; ----------------------------------------------------------
;;; 4. restart-case — 重启机制
;;; ----------------------------------------------------------

(format t "~%=== restart-case ===~%")

;; restart-case 定义恢复策略
(defun read-config-file (filename)
  (restart-case
      (if (probe-file filename)
          (format t "读取配置文件: ~A~%" filename)
          (error "配置文件不存在: ~A" filename))
    ;; 定义重启选项
    (use-default-config ()
      :report "使用默认配置"
      (format t "使用默认配置~%"))
    (create-config-file ()
      :report "创建新配置文件"
      (format t "创建配置文件: ~A~%" filename))
    (use-alternative-file (alt-file)
      :report "使用替代配置文件"
      :interactive (lambda ()
                     (format t "输入替代文件路径: ")
                     (list (read-line)))
      (format t "使用替代文件: ~A~%" alt-file))))

;; 在 handler-bind 中选择重启
(handler-bind ((error (lambda (e)
                        (format t "错误: ~A~%" e)
                        (let ((restart (find-restart 'use-default-config)))
                          (when restart
                            (invoke-restart restart))))))
  (read-config-file "/nonexistent/config.ini"))

;; 更复杂的重启示例
(defun process-data (data)
  (restart-case
      (cond ((null data)
             (error "数据为空"))
            ((not (listp data))
             (error "数据不是列表: ~A" data))
            (t
             (format t "处理 ~A 个元素~%" (length data))
             (mapcar #'1+ data)))
    (use-empty-list ()
      :report "使用空列表"
      nil)
    (use-sample-data ()
      :report "使用示例数据"
      '(1 2 3 4 5))
    (retry-with (new-data)
      :report "用新数据重试"
      :interactive (lambda ()
                     (format t "输入新数据: ")
                     (list (read)))
      (process-data new-data))))

(handler-bind ((error (lambda (e)
                        (format t "错误: ~A~%" e)
                        (invoke-restart 'use-sample-data))))
  (format t "结果: ~A~%" (process-data nil)))

;; invoke-restart-interactively
(defun divide-with-restart (a b)
  (restart-case
      (if (zerop b)
          (error "除数为零")
          (/ a b))
    (return-zero ()
      :report "返回 0"
      0)
    (return-one ()
      :report "返回 1"
      1)
    (set-divisor (new-b)
      :report "设置新的除数"
      :interactive (lambda ()
                     (format t "新除数: ")
                     (list (read)))
      (/ a new-b))))

(handler-bind ((error (lambda (e)
                        (declare (ignore e))
                        (invoke-restart 'return-zero))))
  (format t "10/0 = ~A~%" (divide-with-restart 10 0)))


;;; ----------------------------------------------------------
;;; 5. handler-bind — 底层条件处理
;;; ----------------------------------------------------------

(format t "~%=== handler-bind ===~%")

;; handler-bind 在条件产生时就被调用（栈未展开）
;; handler-case 在条件未被处理时才被调用（栈已展开）

;; handler-bind 可以处理 warning 等不会进入调试器的条件
(handler-bind ((warning (lambda (w)
                          (format t "处理警告: ~A~%" w)
                          (muffle-warning w))))
  (warn "第一个警告")
  (warn "第二个警告")
  (format t "警告后继续执行~%"))

;; handler-bind 处理多个条件类型
(handler-bind ((error (lambda (e)
                        (format t "handler-bind 捕获错误: ~A~%" e)
                        ;; 不阻止错误传播，只是记录
                        ))
               (warning (lambda (w)
                          (format t "handler-bind 捕获警告: ~A~%" w)
                          (muffle-warning w))))
  (warn "测试警告")
  (format t "正常执行~%"))


;;; ----------------------------------------------------------
;;; 6. ignore-errors
;;; ----------------------------------------------------------

(format t "~%=== ignore-errors ===~%")

;; ignore-errors 忽略所有错误，返回 nil
(format t "ignore-errors: ~A~%"
        (ignore-errors (/ 1 0)))

;; 带错误信息
(multiple-value-bind (result condition)
    (ignore-errors (parse-integer "abc"))
  (format t "结果: ~A, 条件: ~A~%" result condition))

;; 实用场景：尝试读取文件
(defun try-read-file (filename)
  (or (ignore-errors
        (with-open-file (in filename)
          (read-line in)))
      "默认内容"))

(format t "~A~%" (try-read-file "/nonexistent.txt"))


;;; ----------------------------------------------------------
;;; 7. 实际应用：健壮的文件处理
;;; ----------------------------------------------------------

(format t "~%=== 实际应用 ===~%")

(define-condition file-processing-error (error)
  ((filename :initarg :filename :reader error-filename)
   (reason   :initarg :reason   :reader error-reason))
  (:report (lambda (c s)
             (format s "处理文件 ~A 时出错: ~A"
                     (error-filename c) (error-reason c)))))

(defun process-file (filename)
  (restart-case
      (handler-case
          (progn
            (unless (probe-file filename)
              (error 'file-processing-error
                     :filename filename
                     :reason "文件不存在"))
            (format t "成功处理: ~A~%" filename))
        (file-processing-error (e)
          (error e)))
    (skip-file ()
      :report "跳过此文件"
      (format t "跳过: ~A~%" filename))
    (retry-file ()
      :report "重试"
      (process-file filename))))

(defun process-all-files (filenames)
  (dolist (f filenames)
    (handler-bind ((file-processing-error
                    (lambda (e)
                      (format t "  错误: ~A~%" e)
                      (invoke-restart 'skip-file))))
      (process-file f))))

(process-all-files '("/tmp/a.txt" "/nonexistent/b.txt" "/tmp/c.txt"))

(format t "~%=== 例程 08 执行完毕 ===~%")
