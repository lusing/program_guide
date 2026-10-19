;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 08 - 字符串与正则表达式
;;;   format / 拼接 / 切分 / string-match / match-string / rx
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "08-strings-regexp.el")'
;;; 运行：emacs -Q --batch -l 08-strings-regexp.el
;;; ============================================================

;;; rx 是宏，字节编译时必须可见；subr-x 提供 string-join / string-trim / string-pad
(require 'rx)
(require 'subr-x)

;;; 1) format 的控制符：%s 字符串、%d 整数、%f 浮点、%S Lisp 语法、
;;;    %s 遇到非字符串会转成字符串；%% 输出一个百分号。
(princ (format "%s=%d (%.1f%%) [%S]\n" "进度" 42 99.95 '(1 2)))

;;; 2) 拼接与切分。concat 接字符串，mapconcat 在元素间插分隔符。
(princ (format "concat: %S\n" (concat "foo" "-" "bar")))
(princ (format "mapconcat: %S\n" (mapconcat #'identity '("a" "b" "c") ", ")))
(princ (format "string-join 等价写法: %S\n" (string-join '("a" "b" "c") ", ")))

;;; 3) 【坑】split-string 的默认分隔符是「空白」（split-string-default-separators），
;;;    而且默认丢掉空串（OMIT-EMPTY 为 t）。
;;;    给了显式分隔符时，OMIT-EMPTY 默认 nil —— 空串被保留，这正是解析 CSV 要的。
;;;    想显式丢掉空串才传第三个参数 t；想保留就传 nil。
(princ (format "默认（按空白、去空）: %S\n" (split-string "  a  b   c ")))
(princ (format "按逗号切（保留空串）: %S\n" (split-string "a,,b,c" ",")))
(princ (format "按逗号切且丢掉空串: %S\n" (split-string "a,,b,c" "," t)))

;;; 4) 取子串与裁剪。substring 的下标从 0 开始，越界会被截断而不是报错。
(princ (format "substring: %S\n" (substring "hello world" 0 5)))
(princ (format "string-trim: %S\n" (string-trim "  hi  ")))
(princ (format "string-pad 补到 8 位: %S\n" (string-pad "hi" 8)))

;;; 5) Emacs 的正则默认是「POSIX-ish 但用 \\( \\) 分组」的方言：
;;;    分组 \\( \\)、交替 \\|、字符类 [[:digit:]]。
;;;    注意在 Elisp 字符串里反斜杠要写成两个。
(princ (format "replace-regexp-in-string: %S\n"
               (replace-regexp-in-string "[0-9]+" "#" "a1 bb22 ccc333")))

;;; 6) string-match：在第 2 个参数里搜第 1 个参数，返回起始下标或 nil。
;;;    匹配成功后用 match-string / match-beginning / match-end 取结果。
(defvar demo-text "version 31.1 build 2026")
(when (string-match "version \\([0-9]+\\)\\.\\([0-9]+\\)" demo-text)
  (princ (format "整串匹配: %S\n" (match-string 0 demo-text)))
  (princ (format "第 1 组: %S，第 2 组: %S\n"
                 (match-string 1 demo-text) (match-string 2 demo-text)))
  (princ (format "位置: %S..%S\n"
                 (match-beginning 0) (match-end 0))))
;;;    第 4 个参数可以指定「从哪个位置开始往后搜」，用于循环找所有匹配。

;;; 7) 循环找所有匹配：靠 match-end 推进起点
(let ((pos 0) (hits nil))
  (while (string-match "[0-9]+" demo-text pos)
    (push (match-string 0 demo-text) hits)
    (setq pos (match-end 0)))
  (princ (format "所有数字: %S\n" (nreverse hits))))

;;; 8) 【坑】match-string 用的是「最后一次匹配」的全局状态。
;;;    两个反直觉点：
;;;    a) 匹配**失败**（返回 nil）并不会清理 match data —— 上一次的结果还在，
;;;       所以忽略 nil 返回值就会读到脏数据；
;;;    b) 字符串匹配之后 match-string 必须传字符串，不传会报错
;;;       （它默认去当前 buffer 里取，而字符串匹配的位置是 0 开始的）。
(let ((s1 "aaa"))
  (string-match "a" s1)
  (princ (format "   先成功匹配: %S\n" (match-string 0 s1)))
  (princ (format "   失败匹配返回: %S\n" (string-match "zzz" s1)))
  (princ (format "   失败后 match-string 还在: %S\n" (match-string 0 s1)))
  (princ (format "   不传字符串会怎样: %S\n"
                 (condition-case err (match-string 0) (error err)))))

;;; 9) rx 宏：用 S-表达式写正则，可读性远胜字符串，强烈推荐。
(princ (format "rx 生成: %S\n" (rx "v" (one-or-more digit))))
(princ (format "rx 复杂例子: %S\n"
               (rx line-start (group (one-or-more (any "a-z")))
                   "=" (group (one-or-more digit)) line-end)))
(princ (format "rx 匹配: %S\n"
               (string-match (rx "version " (group (one-or-more digit))) demo-text)))
(princ (format "rx 取组: %S\n" (match-string 1 demo-text)))

;;; 10) 字符与字符串互转
(princ (format "string-to-list: %S\n" (string-to-list "ab")))
(princ (format "string-to-number: %S，number-to-string: %S\n"
               (string-to-number "0x1f") (number-to-string 31)))
(princ (format "实际写代码里更常用 (format \"%%d\" 31) = %S\n" (format "%d" 31)))

;;; 11) 字面量查找/替换的现代函数（不用写正则）：string-search / string-replace
(princ (format "string-search: %S\n" (string-search "lo" "hello")))
(princ (format "string-replace: %S\n" (string-replace "a" "X" "banana")))

(princ "==== 08 结束 ====\n")
