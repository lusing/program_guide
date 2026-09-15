;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 01 - 第一个 Elisp 程序
;;;   输出、格式化、注释、quote，以及 batch 模式下输出去向的坑
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "01-hello.el")'
;;; 运行：emacs -Q --batch -l 01-hello.el
;;; ============================================================

;;; 1) 最小程序。princ 把字符串「原样」写到 stdout，不引号、不换行，
;;;    所以换行要自己写 \n。
(princ "Hello, Emacs!\n")

;;; 2) 所有输出都靠 (princ (format ...)) 这一个组合。
;;;    %s 字符串 / %d 整数 / %S 保留 Lisp 语法 / %.2f 定点小数
(princ (format "1 + 1 = %d，列表 = %S，字符串 = %s，pi = %.2f\n"
               (+ 1 1) '(1 2 3) "abc" float-pi))

;;; 3) 【坑】message 不是 stdout 的输出工具。
;;;    交互模式下它显示在 echo area，但 batch 模式下它写的是 **stderr**。
;;;    本示例全部用 princ，目的就是让「stderr 必须为空」能成为一条硬判定 ——
;;;    一旦某处误用 message，或者字节编译冒出警告，验证脚本立刻失败。
(princ (format "先把文本格式化好再输出：%s\n"
               (format "elisp-%d.%d" emacs-major-version emacs-minor-version)))

;;; 4) quote：'x 阻止求值，拿到符号或列表本身；不 quote 就会被当函数调用。
;;;    (1 2 3) 会被当成「调用名为 1 的函数」，报错；'(1 2 3) 才是三元素列表。
(princ (format "quote 后：%S\n" (quote (1 2 3))))
(princ (format "等价写法：%S\n" '(1 2 3)))
(princ (format "符号本身：%S，符号的名字：%S\n" 'foo (symbol-name 'foo)))

;;; 5) 注释的三种惯例：
;;;    ;;; 三个分号 —— 文件头、分节标题（左边界）
;;;    ;;  两个分号 —— 普通注释（跟代码缩进对齐），本文件用的就是这种
;;;    ;   一个分号 —— 行尾简短说明
(princ (format "求值 (+ 1 2 3) = %S\n" (+ 1 2 3)))

;;; 6) prin1-to-string 生成「可以被 read 回来」的形式，调试时比 princ 好用
(princ (format "prin1 形式：%s\n" (prin1-to-string "带\"引号\"的字符串")))

(princ "==== 01 结束 ====\n")
