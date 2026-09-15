;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 19 - Advice：在不改源码的前提下修改已有函数的行为
;;;   :before / :after / :around / :override / :filter-args / :filter-return
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "19-advice.el")'
;;; 运行：emacs -Q --batch -l 19-advice.el
;;; ============================================================

;;; 被「增强」的目标函数。假设它来自别人写的包，你不想（也不能）改它。
(defun demo-save (key value)
  "把 VALUE 存到 KEY 下。"
  (format "saved %s=%s" key value))

;;; 1) :before —— 在原函数**之前**跑，拿到的参数和原函数一样。
;;;    原函数的返回值不受影响（advice 的返回值被丢弃）。
(defun demo-log-before (&rest args)
  "打印调用参数。"
  (princ (format "    [before] 参数 = %S\n" args)))
(advice-add #'demo-save :before #'demo-log-before)
(princ (format "1) :before 之后调用: %S\n" (demo-save "a" 1)))

;;; 2) :after —— 在原函数**之后**跑。参数同样和原函数一致，
;;;    注意它拿不到原函数的返回值（要返回值用 :filter-return）。
(defun demo-log-after (&rest args)
  "打印调用结束。"
  (princ (format "    [after] 参数 = %S\n" args)))
(advice-add #'demo-save :after #'demo-log-after)
(princ (format "2) 再加 :after: %S\n" (demo-save "b" 2)))

;;; 3) :filter-args —— 修改**传给**原函数的参数。
;;;    它接收 (原参数列表)，返回新的参数列表。
(defun demo-upcase-key (args)
  "把第一个参数（key）转成大写。"
  (cons (upcase (car args)) (cdr args)))
(advice-add #'demo-save :filter-args #'demo-upcase-key)
(princ (format "3) 加 :filter-args 后传 \"c\": %S\n" (demo-save "c" 3)))

;;; 4) :filter-return —— 修改原函数的**返回值**。
(defun demo-add-suffix (result)
  "给返回值加个后缀。"
  (concat result " [advised]"))
(advice-add #'demo-save :filter-return #'demo-add-suffix)
(princ (format "4) 加 :filter-return: %S\n" (demo-save "d" 4)))

;;; 5) 【重点】：around —— 最强大的一个，把原函数**包起来**。
;;;    advice 收到的参数是「原函数」+ 原参数列表，它自己决定
;;;    要不要调用原函数、调用几次、传什么参数、返回什么。
;;;    【坑】参数顺序是 (原函数 . 原参数)，别写反。
(defun demo-timing (orig-fun &rest args)
  "统计 ORIG-FUN 的运行时间。"
  (let ((t0 (current-time)))
    (let ((result (apply orig-fun args)))
      (princ (format "    [around] 耗时 %.6f 秒，返回值 %S\n"
                     (float-time (time-subtract (current-time) t0)) result))
      result)))
(advice-add #'demo-save :around #'demo-timing)
(princ (format "5) 加 :around: %S\n" (demo-save "e" 5)))

;;; 6) 执行顺序（同一个函数上好几个 advice 时）：
;;;    :around 最外层 → :before → :filter-args → 原函数
;;;    → :filter-return → :after
;;;    多个同类 advice 之间，**后添加的在外层**（和 add-hook 一致）。
(princ "6) 现在一次调用会依次触发：\n")
(demo-save "f" 6)
(princ "\n")

;;; 7) :override —— 整个替换掉原函数。原函数不再被调用
;;;    （除非你自己 (apply orig-fun args)）。
;;;    这是**最危险**的一个：两个包都 override 同一个函数就会互相打架。
;;;    能不用就不用，优先选 :around。
(defun demo-override (_orig-fun &rest _args)
  "直接返回固定值。"
  "被 override 了")
(advice-add #'demo-save :override #'demo-override)
(princ (format "7) :override 之后: %S（其它 advice 全被短路）\n" (demo-save "g" 7)))

;;; 8) 移除 advice：advice-remove（单个）/ advice-remove-all？没有后者，
;;;    要全清就逐个 remove。查询用 advice-member-p。
;;;    【坑】advice-member-p 返回的不是 t，而是整个 advice 对象
;;;    （里面含字节码，%S 打印出来会带裸控制字符），要用得先转布尔。
(princ (format "8) demo-log-before 还挂着吗: %S\n"
               (and (advice-member-p #'demo-log-before #'demo-save) t)))
(advice-remove #'demo-save #'demo-override)
(advice-remove #'demo-save #'demo-timing)
(advice-remove #'demo-save #'demo-add-suffix)
(advice-remove #'demo-save #'demo-upcase-key)
(advice-remove #'demo-save #'demo-log-after)
(advice-remove #'demo-save #'demo-log-before)
(princ (format "   全部移除后: %S，还挂着吗: %S\n"
               (demo-save "h" 8)
               (and (advice-member-p #'demo-log-before #'demo-save) t)))

;;; 9) 【坑】advice 是全局的、看不见的改动。三条纪律：
;;;      a) advice 函数必须 defun 具名函数（和 hook 同理，为了能 remove）；
;;;      b) 配套提供一个「开关命令」，让用户能一键卸载你的 advice；
;;;      c) 优先用 hook / :around，别用 :override。
;;;    另外 C-h f 某个函数时，如果有 advice，帮助里会显示 "This function has :around advice"。

;;; 10) 「临时挂一会儿、用完就摘」的正规写法：具名函数 + unwind-protect。
;;;     （unwind-protect 见 22-errors.el，作用是「无论是否出错都执行清理」）
(defun demo-temp-suffix (result)
  "临时给返回值加后缀。"
  (concat result " [临时]"))
(unwind-protect
    (progn
      (advice-add #'demo-save :filter-return #'demo-temp-suffix)
      (princ (format "10) 临时 advice: %S\n" (demo-save "i" 9))))
  (advice-remove #'demo-save #'demo-temp-suffix))
(princ (format "   摘掉后: %S，还挂着吗: %S\n"
               (demo-save "j" 10)
               (and (advice-member-p #'demo-temp-suffix #'demo-save) t)))

;;; 11) 【坑】把第 10 节的具名函数换成 lambda 就摘不掉了：
;;;     advice-remove 用 eq 比较函数对象，而每次求值 lambda 都是新对象。
;;;     remove 看起来执行了，实际什么也没删掉，还会越挂越多。
;;;     下面这两行就是铁证 —— 调用结果里仍然带着 [幽灵]。
(advice-add #'demo-save :filter-return (lambda (r) (concat r " [幽灵]")))
(advice-remove #'demo-save (lambda (r) (concat r " [幽灵]")))
(princ (format "11) lambda advice 摘不掉，调用结果: %S\n" (demo-save "k" 11)))
(princ (format "   结论：advice 一律用具名函数\n"))

(princ "==== 19 结束 ====\n")
