;;;; ============================================================
;;;; 07-packages.lisp — 包系统
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. defpackage 定义包
;;;;   2. in-package 切换包
;;;;   3. export / import 导出与导入
;;;;   4. use-package 使用包
;;;;   5. 符号可见性（内部/外部/继承）
;;;;   6. 包昵称与包锁
;;;;   7. 查找符号
;;;;   8. 实际项目中的包组织
;;;;
;;;; 运行方式：sbcl --script 07-packages.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. defpackage 定义包
;;; ----------------------------------------------------------

(format t "~%=== defpackage ===~%")

;; 定义一个简单的包
(defpackage #:my-app
  (:use #:cl)
  (:export #:main
           #:start-server
           #:*version*))

;; 定义一个工具包
(defpackage #:my-utils
  (:use #:cl)
  (:nicknames #:utils)
  (:export #:string-join
           #:string-split
           #:hash-keys
           #:hash-values))

;; 定义一个数据库包
(defpackage #:my-db
  (:use #:cl #:my-utils)
  (:export #:connect
           #:disconnect
           #:query))


;;; ----------------------------------------------------------
;;; 2. in-package 切换包
;;; ----------------------------------------------------------

(format t "~%=== in-package ===~%")

;; 在 my-utils 包中定义函数
(in-package #:my-utils)

(defun string-join (strings &optional (separator ""))
  "将字符串列表用分隔符连接。"
  (format nil (concatenate 'string "~{~A~^" separator "~}") strings))

(defun string-split (string &optional (delimiter #\Space))
  "按分隔符拆分字符串。"
  (loop with start = 0
        for pos = (position delimiter string :start start)
        collect (subseq string start (or pos (length string)))
        while pos
        do (setf start (1+ pos))))

(defun hash-keys (ht)
  "返回哈希表的所有键。"
  (loop for k being the hash-keys of ht collect k))

(defun hash-values (ht)
  "返回哈希表的所有值。"
  (loop for v being the hash-values of ht collect v))

(format t "string-join: ~A~%" (string-join '("a" "b" "c") "-"))
(format t "string-split: ~A~%" (string-split "hello world lisp"))


;;; ----------------------------------------------------------
;;; 3. 符号可见性
;;; ----------------------------------------------------------

(format t "~%=== 符号可见性 ===~%")

;; 外部符号（导出的）：用单冒号访问  package:symbol
;; 内部符号（未导出的）：用双冒号访问  package::symbol（不推荐）

;; 在 my-db 包中
(in-package #:my-db)

(defun connect (host port)
  (format t "连接到 ~A:~A~%" host port))

(defun disconnect ()
  (format t "断开连接~%"))

(defun query (sql)
  (format t "执行查询: ~A~%" sql)
  ;; 可以使用 my-utils 中导出的函数（因为 :use 了 my-utils）
  (format t "拆分: ~A~%" (string-split sql)))

;; 内部函数（不导出）
(defun internal-helper ()
  (format t "这是内部函数~%"))

(in-package #:cl-user)

;; 调用导出的函数
(my-db:connect "localhost" 5432)
(my-db:query "SELECT * FROM users")
(my-db:disconnect)

;; 调用未导出的函数（需要双冒号，不推荐在包外使用）
(my-db::internal-helper)

;; 使用导出的工具函数
(format t "join: ~A~%" (my-utils:string-join '("x" "y" "z") ", "))
(format t "join: ~A~%" (utils:string-join '("x" "y" "z") ", "))  ; 使用昵称


;;; ----------------------------------------------------------
;;; 4. use-package 与 import
;;; ----------------------------------------------------------

(format t "~%=== use-package ===~%")

(defpackage #:test-use
  (:use #:cl #:my-utils))

(in-package #:test-use)

;; use-package 后可以直接使用导出的符号，无需包前缀
(format t "直接使用: ~A~%" (string-join '("1" "2" "3") "+"))
(format t "直接使用: ~A~%" (string-split "a,b,c" #\,))

(in-package #:cl-user)

;; import — 导入特定符号到当前包
(import 'my-utils:string-join)
(format t "import 后: ~A~%" (my-utils:string-join '("imported" "works") " "))


;;; ----------------------------------------------------------
;;; 5. 查找符号
;;; ----------------------------------------------------------

(format t "~%=== 查找符号 ===~%")

;; find-symbol — 在包中查找符号
(multiple-value-bind (sym status) (find-symbol "STRING-JOIN" :my-utils)
  (format t "符号: ~A, 状态: ~A~%" sym status))

(multiple-value-bind (sym status) (find-symbol "INTERNAL-HELPER" :my-db)
  (format t "符号: ~A, 状态: ~A~%" sym status))

(multiple-value-bind (sym status) (find-symbol "NONEXISTENT" :my-utils)
  (format t "符号: ~A, 状态: ~A~%" sym status))

;; find-package — 查找包
(format t "查找包: ~A~%" (find-package :my-utils))
(format t "查找包(昵称): ~A~%" (find-package :utils))

;; package-name — 获取包名
(format t "包名: ~A~%" (package-name (find-package :my-utils)))

;; package-nicknames — 获取包昵称
(format t "昵称: ~A~%" (package-nicknames (find-package :my-utils)))

;; list-all-packages — 列出所有包
(format t "~%所有包（前10个）:~%")
(dolist (pkg (subseq (list-all-packages) 0 (min 10 (length (list-all-packages)))))
  (format t "  ~A~%" (package-name pkg)))

;; do-symbols — 遍历包中所有符号
(format t "~%my-utils 包的外部符号:~%")
(do-external-symbols (sym (find-package :my-utils))
  (format t "  ~A~%" sym))


;;; ----------------------------------------------------------
;;; 6. 包锁（SBCL 特有）
;;; ----------------------------------------------------------

(format t "~%=== 包锁 ===~%")

;; SBCL 默认锁定 CL 包，防止意外重定义
;; 尝试在 CL 包中定义函数会报错：
;; (defun cl:car (x) x)  ; 这会触发包锁错误

;; 查看包是否被锁定
(format t "CL 包锁定: ~A~%" (sb-ext:package-locked-p :cl))
(format t "MY-UTILS 包锁定: ~A~%" (sb-ext:package-locked-p :my-utils))

;; 可以锁定自己的包
(sb-ext:lock-package :my-utils)
(format t "锁定后 MY-UTILS: ~A~%" (sb-ext:package-locked-p :my-utils))

;; 解锁
(sb-ext:unlock-package :my-utils)
(format t "解锁后 MY-UTILS: ~A~%" (sb-ext:package-locked-p :my-utils))


;;; ----------------------------------------------------------
;;; 7. 实际项目中的包组织
;;; ----------------------------------------------------------

(format t "~%=== 实际项目包组织 ===~%")

;; 典型的项目包结构：
;;
;; my-project/
;;   my-project.asd        — 系统定义
;;   src/
;;     package.lisp        — 包定义
;;     utils.lisp          — 工具函数
;;     config.lisp         — 配置
;;     models.lisp         — 数据模型
;;     handlers.lisp       — 业务逻辑
;;     main.lisp           — 入口

;; package.lisp 示例：
(defpackage #:my-project
  (:use #:cl)
  (:export
   ;; 主要入口
   #:main
   #:start
   #:stop
   ;; 配置
   #:*config*
   #:load-config
   ;; 版本
   #:*version*))

(defpackage #:my-project.utils
  (:use #:cl)
  (:export
   #:log-info
   #:log-error
   #:ensure-directory
   #:read-file-string))

(defpackage #:my-project.models
  (:use #:cl)
  (:export
   #:user
   #:make-user
   #:user-name
   #:user-email))

(defpackage #:my-project.handlers
  (:use #:cl #:my-project.models #:my-project.utils)
  (:export
   #:handle-request
   #:route))

(format t "包组织示例已定义~%")

;; 查看包依赖关系
(format t "my-project.handlers 使用的包: ~A~%"
        (mapcar #'package-name
                (package-use-list (find-package :my-project.handlers))))

(format t "~%=== 例程 07 执行完毕 ===~%")
