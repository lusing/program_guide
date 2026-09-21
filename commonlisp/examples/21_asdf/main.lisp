;;;; ============================================================
;;;; examples/21_asdf/main.lisp — 工程化：ASDF、测试与部署
;; channel: sbcl   （ASDF 随 SBCL 内置；CLISP 需自装，见 docs/21 章）
;;;; ============================================================
;;;;
;;;; 本例程演示（全部真实执行，不是纯注释）：
;;;;   1. 在运行期生成一个迷你 ASDF 系统（.asd + src/）
;;;;   2. 注册到 *central-registry* 并 load-system
;;;;   3. 调用系统导出的函数
;;;;   4. 手写一个 30 行的迷你测试框架（assert 风格，零依赖）
;;;;   5. Quicklisp 的角色与安装方式（离线环境只做检测）
;;;;   6. 部署三件套：入口函数 / save-lisp-and-die / 退出码约定
;;; ============================================================

(require :asdf)

(format t "ASDF 版本: ~A~%" (asdf:asdf-version))


;;; ----------------------------------------------------------
;;; 1. 生成迷你系统
;;; ----------------------------------------------------------

;; 真实项目的 .asd 长这样；这里程序化生成同样的内容
(with-open-file (out "mathkit.asd" :direction :output :if-exists :supersede)
  (format out "(cl:in-package #:asdf-user)~%")
  (format out "(defsystem \"mathkit\"~%")
  (format out "  :description \"迷你数学库（教程演示用）\"~%")
  (format out "  :serial t~%")
  (format out "  :components ((:file \"package\")~%")
  (format out "               (:file \"main\")))~%"))

(with-open-file (out "package.lisp" :direction :output :if-exists :supersede)
  (format out "(defpackage #:mathkit~%")
  (format out "  (:use #:cl)~%")
  (format out "  (:export #:mean #:variance))~%"))

(with-open-file (out "main.lisp" :direction :output :if-exists :supersede)
  (format out "(in-package #:mathkit)~%")
  (format out "(defun mean (xs) (/ (reduce #'+ xs) (length xs)))~%")
  (format out "(defun variance (xs)~%")
  (format out "  (let ((m (mean xs)))~%")
  (format out "    (mean (mapcar (lambda (x) (* (- x m) (- x m))) xs))))~%"))

(format t "已生成 mathkit.asd + package.lisp + main.lisp~%")


;;; ----------------------------------------------------------
;;; 2. 注册 + 加载系统
;;; ----------------------------------------------------------

;; *central-registry* 是最简单的注册方式（现代项目更推荐 .asd 源注册表，
;; 思路相同：告诉 ASDF 去哪儿找 .asd）
(push (truename ".") asdf:*central-registry*)

;; 真正走一遍 编译→加载 流程
(asdf:load-system "mathkit" :verbose nil)

;; 调用系统导出的函数
(format t "mathkit:mean (1 2 3 4) = ~A~%" (mathkit:mean '(1 2 3 4)))
(format t "mathkit:variance (2 4 4 4 5 5 7 9) = ~A~%" (mathkit:variance '(2 4 4 4 5 5 7 9)))


;;; ----------------------------------------------------------
;;; 3. 迷你测试框架（零依赖，assert 风格）
;;; ----------------------------------------------------------

;; 五十行以内做出「够用」的测试框架——宏让这件事很轻松
(defparameter *tests* '())
(defparameter *failures* 0)

(defmacro define-test (name &body body)
  `(progn
     (push ',name *tests*)
     (defun ,name ()
       (format t "  测试 ~A … " ',name)
       (handler-case
           (progn ,@body (format t "通过~%"))
         (error (e)
           (incf *failures*)
           (format t "失败: ~A~%" e))))))

(defmacro expect (form)
  `(assert ,form))

;; 五个am测试用例：正常、批量、预期报错各来一个
(define-test mean-basic
  (expect (= 2.5 (mathkit:mean '(1 2 3 4)))))
(define-test mean-single
  (expect (= 7 (mathkit:mean '(7)))))
(define-test variance-basic
  (expect (= 4 (mathkit:variance '(2 4 4 4 5 5 7 9)))))
(define-test mean-empty-errors
  (expect (handler-case (progn (mathkit:mean '()) nil)
            (division-by-zero () t))))
(define-test mean-type-error
  (expect (handler-case (progn (mathkit:mean '("a")) nil)
            (type-error () t))))

(defun run-all-tests ()
  (setf *failures* 0)
  (dolist (test (reverse *tests*))
    (funcall (symbol-function test)))
  (format t "结果: ~A 个测试，~A 个失败~%"
          (length *tests*) *failures*)
  (zerop *failures*))

(format t "迷你测试框架:~%")
(run-all-tests)

;; 五个am断言的报错路径说明：mean 在空表上触发 division-by-zero 是
;; ANSI 定义的（整数除零），不是碰运气；字符串求和是 type-error


;;; ----------------------------------------------------------
;;; 4. Quicklisp（离线环境的正确姿势）
;;; ----------------------------------------------------------

;; Quicklisp 是事实标准包管理器：ql:quickload :xxx 自动下载编译安装。
;; 安装（一次性）：
;;   curl -O https://beta.quicklisp.org/quicklisp.lisp
;;   sbcl --load quicklisp.lisp --eval '(quicklisp-quickstart:install)' \
;;        --eval '(ql:add-to-init-file)'
;; 本机是否装了它只能现场检测（离线仓库不赌网络）：
(format t "Quicklisp 已安装: ~A~%"
        (if (find-package :ql) "是" "否（按上面两步安装）"))
;; 常用命令速记：
;;   (ql:quickload :alexandria)   拉库
;;   (ql:system-apropos "json")   搜库
;;   (ql:update-dist "quicklisp") 更新发行版
;; 把自己的项目放进 ~/quicklisp/local-projects/ 即可直接 quickload


;;; ----------------------------------------------------------
;;; 5. 部署：入口函数与退出码
;;; ----------------------------------------------------------

(defun app-main ()
  "真实应用的入口：读参数 → 干活 → 返回退出码。"
  (format t "mathkit 演示应用启动~%")
  (format t "计算结果: ~A~%" (mathkit:mean '(10 20 30)))
  0)  ; 返回码（入口约定：0 成功 / 非 0 失败）

(format t "入口函数返回码: ~A~%" (app-main))

;; 生成独立可执行文件（REPL 里执行；save-lisp-and-die 会**结束当前会话**，
;; 所以示例只打印命令不真调）：
;;   (sb-ext:save-lisp-and-die "mathapp"
;;                             :toplevel #'app-main
;;                             :executable t)
;; Windows 产物习惯 mathapp.exe，macOS/Linux 是无扩展名的 mathapp。
;; 产物体积 ≈ SBCL 运行时（几十 MB 起步）；嫌大可用 :compression t（需
;; SBCL 编译时带 zlib 支持）或改用 CLISP 的 clisp -M 映像（更小但更慢）


;;; ----------------------------------------------------------
;;; 6. 清理
;;; ----------------------------------------------------------

(dolist (f '("mathkit.asd" "package.lisp" "main.lisp"))
  (when (probe-file f) (delete-file f)))
(dolist (suffix '("fasl" "cfsl"))
  (let ((p (merge-pathnames (format nil "mathkit.~A" suffix) (truename "."))))
    (when (probe-file p) (delete-file p))))
(format t "已清理生成的项目文件~%")

(format t "==== 21 结束 ====~%")
