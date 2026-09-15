;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 13 - 交互式命令：interactive 声明与参数描述符
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "13-interactive.el")'
;;; 运行：emacs -Q --batch -l 13-interactive.el
;;; ============================================================

(require 'cl-lib)

;;; ------------------------------------------------------------
;;; 关于本示例的输出方式（很重要，建议先读完再往下看）
;;;
;;; 命令（command）的惯例是用 message 给用户反馈。但 batch 模式下
;;; message 写的是 **stderr**，本仓库的判定标准要求 stderr 为空，
;;; 所以下面用一个 cl-letf 把 message 临时接到 stdout 上，再调用命令。
;;; 「把函数的定义临时换掉」这件事在写测试时非常有用，见 09-sequences.el 第 10 节。
;;;
;;; 另外：batch 模式下没有 minibuffer，也没有用户输入，
;;; 所以这里**直接传参调用命令函数**（interactive 声明被跳过）。
;;; interactive 只在 M-x 调用、按键触发、call-interactively 时才起作用。
;;; ------------------------------------------------------------

(defun demo-call (cmd &rest args)
  "调用命令 CMD，把它内部 message 的输出转到 stdout，返回 CMD 的返回值。"
  (cl-letf (((symbol-function 'message)
             (lambda (fmt &rest xs)
               (princ "    -> ")
               (princ (apply #'format fmt xs))
               (terpri)
               nil)))
    (apply cmd args)))

;;; 1) 最简单的命令：无参数。
;;;    有了 (interactive) 之后，它才能出现在 M-x 列表里、才能绑到按键上。
(defun demo-say-hello ()
  "说一句 hello。"
  (interactive)
  (message "Hello, Emacs!"))
(princ "1) 无参命令：\n")
(demo-call #'demo-say-hello)
(princ (format "   是命令吗：%S\n" (commandp #'demo-say-hello)))

;;; 2) "s" —— 提示输入字符串。注意 Emacs 的提示串约定以冒号+空格结尾。
(defun demo-greet (name)
  "问候 NAME。"
  (interactive "s你的名字: ")
  (message "你好, %s!" name))
(princ "2) \"s\" 字符串参数：\n")
(demo-call #'demo-greet "Emacs")

;;; 3) "n" —— 提示输入数字，Emacs 会保证传进来的是 number。
(defun demo-double (n)
  "打印 N 的两倍。"
  (interactive "n输入一个数字: ")
  (message "%d * 2 = %d" n (* n 2)))
(princ "3) \"n\" 数字参数：\n")
(demo-call #'demo-double 21)

;;; 4) 【重点】"p" 与 "P" —— 前缀参数（C-u）。
;;;    "p" 拿到的是「转成数字后的前缀」，没有按 C-u 时是 1；
;;;    "P" 拿到的是**原始**前缀，能区分「没按 C-u」(nil) 和「按了 C-u」(4)。
;;;    想让 C-u 改变行为（而不是只改重复次数），就必须用 "P"。
(defun demo-repeat-p (n)
  "用 \"p\" 接收前缀参数。"
  (interactive "p")
  (message "p 收到: %S（没按 C-u 时是 1）" n))
(defun demo-repeat-P (arg)
  "用 \"P\" 接收原始前缀参数。"
  (interactive "P")
  (message "P 收到: %S，转成数字是 %S" arg (prefix-numeric-value arg)))
(princ "4) \"p\" / \"P\" 前缀参数：\n")
(demo-call #'demo-repeat-p 1)
(demo-call #'demo-repeat-p 4)
(demo-call #'demo-repeat-P nil)
(demo-call #'demo-repeat-P '(4))

;;; 5) "r" —— 当前选区（region）的起止位置。
;;;    命令会被传入 (region-beginning) 和 (region-end) 两个整数。
;;;    【坑】没有激活选区时交互调用会报错，所以真正用的时候常配 use-region-p 判断。
(defun demo-count-region (beg end)
  "统计选区 BEG..END 的字符数。"
  (interactive "r")
  (message "选区 [%d, %d) 共 %d 个字符" beg end (- end beg)))
(princ "5) \"r\" 选区参数：\n")
(with-temp-buffer
  (insert "hello world")
  (demo-call #'demo-count-region 1 6))

;;; 6) "f" 已存在的文件、"F" 可能是新文件、"D" 目录、"b" 已存在的 buffer。
;;;    这些描述符自带补全，比自己 (interactive "s") 再校验友好得多。
(defun demo-show-file (file)
  "显示 FILE 的大小。"
  (interactive "f选择文件: ")
  (message "文件 %s 存在: %s" file (file-exists-p file)))
(princ "6) \"f\" 文件参数：\n")
(demo-call #'demo-show-file "/tmp")

;;; 7) (interactive (list ...)) —— 用代码算参数，最灵活的形式。
;;;    下面这个命令：有选区就用选区，否则用当前行。
(defun demo-upcase-thing (beg end)
  "把 BEG..END 之间的文本转成大写。"
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (list (line-beginning-position) (line-end-position))))
  (upcase-region beg end)
  (message "已转换 %d 个字符" (- end beg)))
(princ "7) 自定义参数计算：\n")
(with-temp-buffer
  (insert "hello emacs")
  (demo-call #'demo-upcase-thing 1 12)
  (princ (format "    buffer 现在是: %S\n" (buffer-string))))

;;; 8) interactive-form 能取出命令的 interactive 声明，元编程时用得上。
;;;    不是命令的函数返回 nil。
(princ (format "8) interactive-form: %S\n" (interactive-form #'demo-greet)))
(princ (format "   普通函数: %S\n" (interactive-form #'car)))

;;; 9) called-interactively-p：区分「被 M-x 调用」和「被别的 Lisp 调用」。
;;;    典型用途是「从 Lisp 调用时不要弹提示」。
(defun demo-maybe-verbose (x)
  "演示 called-interactively-p。"
  (interactive "sX: ")
  (if (called-interactively-p 'any)
      (message "交互调用，X = %s" x)
    (message "被 Lisp 调用，X = %s" x)))
(demo-call #'demo-maybe-verbose "abc")

;;; 10) 【坑】忘记写 interactive 的话，函数能正常 (defun) 也能正常调用，
;;;     但 M-x 找不到它、global-set-key 绑上去会报 "not a command"。
(princ (format "10) 没写 interactive 的函数：commandp = %S\n"
               (commandp (lambda () "没有 interactive" 42))))

(princ "==== 13 结束 ====\n")
