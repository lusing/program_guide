;;;; ============================================================
;;;; examples/02_hello/main.lisp — 第一个程序
;;;; channel: both   （SBCL 与 CLISP 都要跑，输出逐字节一致）
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. 五种基本输出：format / print / princ / prin1 / terpri
;;;;   2. 定义函数并调用（docstring 写在哪）
;;;;   3. 顶层表达式按顺序求值
;;;;   4. 用 #+/#- 读取器条件写「跨实现」的命令行参数访问器
;;;;   5. 脚本方式运行（shebang）说明
;;;;
;;;; 运行方式：
;;;;   sbcl --noinform --non-interactive --no-userinit --load main.lisp
;;;;   clisp -q -q -norc -E UTF-8 main.lisp
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 五种输出
;;; ----------------------------------------------------------

;; format 是 CL 里最常用的输出函数；t = *standard-output*，~% = 换行
(format t "Hello, World!~%")

;; print：输出可读表示 + 换行，返回值本身（字符串带引号）
(print "Hello from print")

;; princ：面向「人类」的输出，字符串不带引号（不可读回）
(princ "Hello from princ")
(terpri)  ; terpri = terminate print，输出一个换行

;; prin1：面向「机器」的输出，字符串带引号（可被 read 原样读回）
(prin1 "Hello from prin1")
(terpri)

;; format 的 ~A（人类视角）/ ~S（机器视角）与上面同理
(format t "~A 与 ~S 的区别~%" "princ 风格" "prin1 风格")


;;; ----------------------------------------------------------
;;; 2. 定义函数并调用
;;; ----------------------------------------------------------

(defun greet (name)
  "向 NAME 打招呼。文档字符串（docstring）写在参数列表之后。"
  (format t "你好，~A！欢迎来到 Common Lisp。~%" name))

(greet "Lisper")
(greet "世界")

;; documentation 取回 docstring
(format t "greet 的文档: ~A~%" (documentation 'greet 'function))


;;; ----------------------------------------------------------
;;; 3. 顶层表达式按顺序求值
;;; ----------------------------------------------------------

;; load 一个 .lisp 文件 = 把文件里的顶层表达式**从头到尾**逐个求值。
;; 所以后面的表达式能看到前面 defun 的结果。
(let ((x 10)
      (y 20))
  (format t "x + y = ~A~%" (+ x y)))


;;; ----------------------------------------------------------
;;; 4. 命令行参数：SBCL 与 CLISP 的接口不同，用 #+/#- 统一
;;; ----------------------------------------------------------

;; 读取器条件（feature expression）：
;;   #+sbcl (...)   仅当 *features* 里有 :SBCL 时才被读入
;;   #+clisp (...)  仅当是 CLISP 时才被读入
;;   #-(or sbcl clisp) nil  其余实现兜底
;; 注意：包名 SB-EXT / EXT 只有在对应实现里才存在，所以必须在**读入期**
;; 就用 #+ 挡掉——换成运行期 if 是不行的（读不到那个包的符号）。
(defun program-arguments ()
  #+sbcl (cdr (member "--" sb-ext:*posix-argv* :test #'string=))
  #+clisp ext:*args*
  #-(or sbcl clisp) nil)

;; 没传参数时两个实现都得到空表（本例由验证脚本无参调用）
(format t "脚本参数: ~S~%" (program-arguments))

;; 传参方式（注释备查）：
;;   sbcl --script main.lisp a.txt b.txt   ; *posix-argv* 含 ("--" 之后的部分)
;;   clisp main.lisp a.txt b.txt           ; ext:*args* = ("a.txt" "b.txt")


;;; ----------------------------------------------------------
;;; 5. 脚本方式运行（说明）
;;; ----------------------------------------------------------
;;;;
;;;; 给文件加一行 shebang 即可 ./main.lisp 直接运行：
;;;;
;;;;   #!/usr/bin/env sbcl --script        (SBCL)
;;;;   #!/usr/bin/env clisp                (CLISP)
;;;;
;;;; --script 模式不进 REPL、不加载用户初始化文件，跑完即退。
;;;; 注意：--script 与 --non-interactive 不能连用（SBCL 会把文件名
;;;; 当成运行时参数，脚本根本不执行）。本仓库的验证入口统一用
;;;; --load 方式加载。


(format t "~%==== 02 结束 ====~%")
