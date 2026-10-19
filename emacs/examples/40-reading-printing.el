;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 40 - 读取与打印：read、prin1、princ、format 与那一堆 print-* 开关
;;;   「对象 → 文本」（打印）和「文本 → 对象」（读取）是一对逆操作，
;;;   但两边都有一堆开关。本章把 prin1/princ/print/pp 的区别、
;;;   format 的转换符、六个 print-* 变量、以及「哪些对象能原样读回来」
;;;   逐个实测。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "40-reading-printing.el")'
;;; 运行：emacs -Q --batch -l 40-reading-printing.el
;;; ============================================================
(require 'cl-lib)
;;; pp-escape-newlines / pp-to-string 在 pp.el 里，先加载。
(require 'pp)

;;; ---------- 1) 打印四兄弟：prin1 / princ / print / pp ----------
(princ "== 1) 打印四兄弟 ==\n")
(dolist (obj (list "abc" 'sym 42 '(a "b")))
  (princ (format "  对象 %S\n" obj))
  (princ (format "    prin1 -> %S\n" (with-output-to-string (prin1 obj))))
  (princ (format "    princ -> %S\n" (with-output-to-string (princ obj))))
  (princ (format "    print -> %S\n" (with-output-to-string (print obj))))
  (princ (format "    pp    -> %S\n" (pp-to-string obj))))
(princ "  prin1 保留引号、princ 脱掉引号、print 前后各加一个换行、pp 末尾加换行。\n")
(let ((obj (list (cons 'k (number-sequence 1 40)))))
  (princ (format "  长结构 prin1 -> %S\n" (prin1-to-string obj)))
  (princ (format "  长结构 pp    -> %S\n" (pp-to-string obj)))
  (princ (format "  pp 按 fill-column=%S 折行\n" fill-column)))
(princ (format "  四个函数的返回值都是被打印的对象本身: %S %S\n"
               (with-output-to-string (prin1 'aaa))
               (with-output-to-string (princ 'bbb))))

;;; ---------- 2) format 的转换符 ----------
(princ "\n== 2) format 的转换符 ==\n")
(princ (format "  %%S 带引号: %S\n" (format "%S" "abc" )))
(princ (format "  %%s 脱引号: %s\n" (format "%s" "abc")))
(princ (format "  %%S 列表:   %S\n" (format "%S" '(a "b"))))
(princ (format "  %%s 列表:   %s\n" (format "%s" '(a "b"))))
(princ (format "  %%d=%S  %%o=%S  %%x=%S  %%X=%S\n"
               (format "%d" 42) (format "%o" 42)
               (format "%x" 42) (format "%X" 42)))
(princ (format "  %%c=%S  %%c 吃字符: %S\n"
               (format "%c" 65) (format "%c" ?A)))
(princ (format "  %%f=%S  %%e=%S  %%g=%S\n"
               (format "%f" 1.5) (format "%e" 1.5) (format "%g" 1.5)))
(princ (format "  %%5.2f=%S  （宽度 5、小数 2 位）\n" (format "%5.2f" 3.14159)))
(princ (format "  %%%% 才是字面百分号: %S\n" (format "%%")))
;;; 下面两行故意写错参数个数，用 with-no-warnings 挡住编译器的好心提醒。
(princ (format "  参数不够: %S\n"
               (with-no-warnings
                 (condition-case err (format "%s %s" 1)
                   (error (error-message-string err))))))
(princ (format "  参数多了: %S  （多余的直接忽略，不报错）\n"
               (with-no-warnings (format "%s" 1 2))))

;;; ---------- 3) print-length / print-level：截断 ----------
(princ "\n== 3) print-length / print-level ==\n")
(princ (format "  默认 print-length=%S print-level=%S（nil 就是不截断）\n"
               print-length print-level))
(let ((long (number-sequence 1 20)))
  (princ (format "  20 个元素的列表，默认: %S\n" (prin1-to-string long)))
  (princ (format "  print-length 3:         %S\n"
                 (let ((print-length 3)) (prin1-to-string long))))
  (princ (format "  print-length 对字符串无效: %S\n"
                 (let ((print-length 2)) (prin1-to-string "abcdef"))))
  (princ (format "  print-length 对向量有效: %S\n"
                 (let ((print-length 2)) (prin1-to-string [1 2 3 4])))))
(let ((deep '(1 (2 (3 (4 (5)))))))
  (princ (format "  五层嵌套，默认:      %S\n" (prin1-to-string deep)))
  (princ (format "  print-level 2:      %S\n"
                 (let ((print-level 2)) (prin1-to-string deep))))
  (princ (format "  print-level 1:      %S\n"
                 (let ((print-level 1)) (prin1-to-string deep)))))

;;; ---------- 4) print-circle：环与共享结构 ----------
(princ "\n== 4) print-circle ==\n")
(princ (format "  默认 print-circle=%S\n" print-circle))
(let* ((x (list 1 2))
       (circ (progn (setcdr (nthcdr 1 x) x) x)))
  (princ (format "  环形列表，默认打印: %S\n"
                 (let ((print-length 8)) (prin1-to-string circ))))
  (princ "  Emacs 不会无限循环，但那个 `#2` 读不回来。\n")
  (princ (format "  print-circle t:     %S\n"
                 (let ((print-circle t)) (prin1-to-string circ))))
  (let* ((str (let ((print-circle t)) (prin1-to-string circ)))
         (back (read str)))
    (princ (format "  读回来还是同一个环吗: %S（(nthcdr 2 r) eq r）\n"
                   (and (consp back) (eq (nthcdr 2 back) back))))))
(let* ((shared (list 9 9))
       (obj (list shared shared)))
  (princ (format "  两个位置共用同一个子表，默认: %S\n" (prin1-to-string obj)))
  (princ (format "  print-circle t:             %S\n"
                 (let ((print-circle t)) (prin1-to-string obj))))
  (let ((back (read (let ((print-circle t)) (prin1-to-string obj)))))
    (princ (format "  读回来还是共用吗: %S\n" (eq (nth 0 back) (nth 1 back)))))
  (princ (format "  不开 print-circle 就读回来: %S（变成两份拷贝）\n"
                 (eq (nth 0 (read (prin1-to-string obj)))
                     (nth 1 (read (prin1-to-string obj)))))))

;;; ---------- 5) print-quoted / print-gensym ----------
(princ "\n== 5) print-quoted / print-gensym ==\n")
(princ (format "  默认 print-quoted=%S\n" print-quoted))
(princ (format "  (prin1-to-string ''(a b))        = %S\n" (prin1-to-string ''(a b))))
(princ (format "  print-quoted nil 时:             = %S\n"
               (let ((print-quoted nil)) (prin1-to-string ''(a b)))))
(princ (format "  默认 print-gensym=%S\n" print-gensym))
(princ (format "  未 intern 的符号，默认:   %S\n" (prin1-to-string (make-symbol "foo"))))
(princ (format "  print-gensym t:           %S\n"
               (let ((print-gensym t)) (prin1-to-string (make-symbol "foo")))))
(let* ((str (let ((print-gensym t)) (prin1-to-string (make-symbol "foo"))))
       (back (read str)))
  (princ (format "  #:foo 读回来是未 intern 的符号: %S（obarray 里查不到 foo: %S）\n"
                 (symbolp back)
                 (null (intern-soft "foo")))))

;;; ---------- 6) 换行与非 ASCII ----------
(princ "\n== 6) 换行与非 ASCII ==\n")
(princ (format "  默认 print-escape-newlines=%S\n" print-escape-newlines))
(princ (format "  prin1 一个带换行的字符串: %S\n" (prin1-to-string "a\nb")))
(princ (format "  print-escape-newlines t:  %S\n"
               (let ((print-escape-newlines t)) (prin1-to-string "a\nb"))))
(princ (format "  princ 不受这个开关影响:   %S\n"
               (let ((print-escape-newlines t))
                 (with-output-to-string (princ "a\nb")))))
(princ (format "  pp 默认就把换行转义了（pp-escape-newlines=%S）: %S\n"
               pp-escape-newlines (pp-to-string "a\nb")))
(princ (format "  prin1 中文，默认:              %S\n" (prin1-to-string "中文")))
(princ (format "  print-escape-nonascii t:       %S（对 multibyte 没用）\n"
               (let ((print-escape-nonascii t)) (prin1-to-string "中文"))))
(princ (format "  print-escape-multibyte t:      %S\n"
               (let ((print-escape-multibyte t)) (prin1-to-string "中文"))))

;;; ---------- 7) float-output-format ----------
(princ "\n== 7) float-output-format ==\n")
(princ (format "  默认 float-output-format=%S\n" float-output-format))
(princ (format "  (prin1-to-string 1.0)=%S  (prin1-to-string 0.1)=%S\n"
               (prin1-to-string 1.0) (prin1-to-string 0.1)))
(princ (format "  设成 \"%%.2f\": %S\n"
               (let ((float-output-format "%.2f")) (prin1-to-string 3.14159))))
(princ (format "  设成 \"%%.3e\": %S\n"
               (let ((float-output-format "%.3e")) (prin1-to-string 3.14159))))
(princ (format "  format 的 %%s 走同一套: %S\n" (format "%s" 1.0)))

;;; ---------- 8) 输出到哪里：printcharfun ----------
(princ "\n== 8) 输出到哪里 ==\n")
(princ (format "  standard-output 默认=%S（nil 表示走标准输出 / echo 区）\n"
               standard-output))
(with-temp-buffer
  (prin1 '(a "b") (current-buffer))
  (princ (format "  prin1 到 buffer: %S\n" (buffer-string)))
  (erase-buffer)
  (princ "hi" (current-buffer))
  (princ (format "  princ 到 buffer: %S\n" (buffer-string)))
  (erase-buffer)
  (terpri (current-buffer))
  (princ (format "  terpri 到 buffer: %S\n" (buffer-string)))
  (erase-buffer)
  (write-char ?A (current-buffer))
  (princ (format "  write-char 到 buffer: %S\n" (buffer-string)))
  (erase-buffer)
  (insert "start")
  (prin1 '(1 2) (copy-marker (point-max)))
  (princ (format "  prin1 到 marker: %S（插在 marker 处）\n" (buffer-string))))
(princ (format "  with-output-to-string 把输出接成字符串: %S\n"
               (with-output-to-string (princ "x") (princ "y"))))

;;; ---------- 9) 读回来：read / read-from-string ----------
(princ "\n== 9) 读回来 ==\n")
(princ (format "  (read \"(+ 1 2)\")=%S\n" (read "(+ 1 2)")))
(princ (format "  (read-from-string \"(+ 1 2) rest\")=%S\n"
               (read-from-string "(+ 1 2) rest")))
(princ "  返回的是 (对象 . 结束位置)，所以能接着往下读。\n")
(princ (format "  (read-from-string \"42\")=%S\n" (read-from-string "42")))
(princ (format "  空串: %S\n"
               (condition-case err (read-from-string "")
                 (error (error-message-string err)))))
(princ (format "  没有 read-from-whole-string 这个函数: %S\n"
               (fboundp 'read-from-whole-string)))
(with-temp-buffer
  (insert "(+ 1 2)\n(* 3 4)\n")
  (goto-char (point-min))
  (princ (format "  从 buffer 读第一个: %S  point 现在=%S\n"
                 (read (current-buffer)) (point)))
  (princ (format "  再读第二个:         %S  point 现在=%S\n"
                 (read (current-buffer)) (point)))
  (princ "  read 会推进 point——这就是 `load' 能一段一段读下去的原因。\n"))

;;; ---------- 10) 什么能原样读回来 ----------
(princ "\n== 10) 什么能原样读回来 ==\n")
(princ "  --- 能 ---\n")
(let ((obj '(1 "two" three (4 . 5) [6 7] :kw)))
  (princ (format "  普通结构: %S -> %S\n"
                 (prin1-to-string obj)
                 (equal obj (read (prin1-to-string obj))))))
(let ((s (propertize "hello" 'face 'bold)))
  (princ (format "  带文本属性的字符串: %S\n" (prin1-to-string s)))
  (princ (format "  读回来属性还在: %S\n"
                 (equal (get-text-property 0 'face (read (prin1-to-string s)))
                        'bold))))
(cl-defstruct demo-pt x y)
(let ((pt (make-demo-pt :x 1 :y 2)))
  (princ (format "  cl-defstruct 结构: %S\n" (prin1-to-string pt)))
  (princ "  注意它只写值不写槽名——改了 defstruct 的定义，旧数据就读错位了。\n"))
(let ((h (make-hash-table :test 'equal)))
  (puthash "a" 1 h)
  (princ (format "  equal 哈希表: %S\n" (prin1-to-string h)))
  (princ (format "  读回来 test 还在: %S\n"
                 (eq (hash-table-test (read (prin1-to-string h))) 'equal))))
(let ((h (make-hash-table :test 'equal :weakness 'value)))
  (puthash "a" 1 h)
  (princ (format "  弱表的 weakness 也写进去了，读回来: %S\n"
                 (hash-table-weakness (read (prin1-to-string h))))))
(princ "  --- 不能 ---\n")
(let ((buf (get-buffer-create " *demo-tmp*")))
  (princ (format "  buffer 打印成: %S\n" (prin1-to-string buf)))
  (princ (format "  读回来: %S\n"
                 (condition-case err (read (prin1-to-string buf))
                   (error (error-message-string err)))))
  (kill-buffer buf))
(let ((uni (make-symbol "not-interned")))
  (princ (format "  未 intern 的符号打印成 %S，读回来是同一个吗: %S\n"
                 (prin1-to-string uni)
                 (eq (read (prin1-to-string uni)) uni)))
  (princ "  打印出来只有名字，读回去变成 obarray 里的同名符号——不是同一个对象。\n"))

;;; ---------- 11) read 不执行 + 文本属性会「粘」过来 ----------
(princ "\n== 11) read 不执行，以及属性粘连 ==\n")
(princ (format "  (read \"(kill-emacs)\")=%S —— 只是个列表，没被执行\n"
               (read "(kill-emacs)")))
(princ (format "  要执行得再 eval 一层: (eval (read \"(+ 1 2)\"))=%S\n"
               (eval (read "(+ 1 2)"))))
(let* ((bold (propertize "warn" 'face 'bold))
       (msg (format "value: %s" bold)))
  (princ (format "  (format \"value: %%s\" 带 face 的字符串)=%S\n" msg))
  (princ (format "  第 7 个字符的 face=%S（属性跟着一起粘进来了）\n"
                 (get-text-property 7 'face msg)))
  (princ (format "  第 0 个字符的 face=%S\n" (get-text-property 0 'face msg)))
  (let ((clean (substring-no-properties bold)))
    (princ (format "  先 substring-no-properties 再拼: %S  第7个=%S\n"
                   (format "value: %s" clean)
                   (get-text-property 7 'face (format "value: %s" clean))))))

;;; ---------- 12) 特殊读语法 ----------
(princ "\n== 12) 特殊读语法 ==\n")
(dolist (s '("?a" "?\\n" "#b101" "#o17" "#x1f" "1.5e3" "-0.0" "1/2"
             "'(a b)" "`(a ,b)" "#'(lambda (x) x)" "[1 2 3]" "(a . b)"))
  (princ (format "  %-20S -> %S\n" s
                 (condition-case err (car (read-from-string s))
                   (error (error-message-string err))))))
(princ (format "  1/2 其实是符号而不是分数: %S\n"
               (symbolp (car (read-from-string "1/2")))))

(princ "==== 40 结束 ====\n")
