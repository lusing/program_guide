;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 11 - 文本属性与 overlay：给文字加「元数据」的两种方式
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "11-text-properties.el")'
;;; 运行：emacs -Q --batch -l 11-text-properties.el
;;; ============================================================

;;; 1) 文本属性（text property）是「粘在字符上」的 (key . value) 对。
;;;    propertize 造一个带属性的字符串，是最省事的写法。
(defvar demo-s (propertize "重要" 'face 'bold))
(princ (format "带属性字符串: %S\n" demo-s))
(princ (format "取属性 face = %S，取不存在的 = %S\n"
               (get-text-property 0 'face demo-s)
               (get-text-property 0 'nope demo-s)))

;;; 2) 在 buffer 里加属性：put-text-property / add-text-properties
(with-temp-buffer
  (insert "normal KEYWORD normal")
  (goto-char (point-min))
  (re-search-forward "KEYWORD")
  (put-text-property (match-beginning 0) (match-end 0) 'face 'error)
  ;; 注意：buffer 位置从 1 开始，字符串下标从 0 开始，
  ;; 所以 buffer 位置 8（KEYWORD 的 K）对应字符串下标 7。
  (princ (format "KEYWORD 首字符的 face = %S，普通字符的 face = %S\n"
                 (get-text-property 7 'face (buffer-string))
                 (get-text-property 2 'face (buffer-string))))
  ;; 找出属性变化的位置
  (princ (format "属性变化点: %S\n"
                 (next-property-change 1 (buffer-string)))))

;;; 3) 【坑】equal 忽略文本属性，equal-including-properties 不忽略。
;;;    结果就是：两个看起来一模一样的字符串，equal 为真但行为不同。
(princ (format "equal = %S，equal-including-properties = %S\n"
               (equal "abc" (propertize "abc" 'face 'bold))
               (equal-including-properties "abc" (propertize "abc" 'face 'bold))))

;;; 4) 【关键区别一】文本属性跟着字符走：复制粘贴会带着走，
;;;    插入相邻文本时属性会「粘」上来（stickiness）。
(with-temp-buffer
  (insert (propertize "AAA" 'face 'bold))
  (goto-char (point-max))
  (insert "BBB")                        ; 紧贴着插入
  (princ (format "后面紧插的文本继承了属性: face@3 = %S\n"
                 (get-text-property 3 'face (buffer-string)))))

;;; 5) 去除属性：substring-no-properties / remove-text-properties /
;;;    set-text-properties（把整个区间的属性全替换掉）
(princ (format "去掉属性后: %S，equal-including-properties = %S\n"
               (substring-no-properties demo-s)
               (equal-including-properties "重要" (substring-no-properties demo-s))))

;;; 6) 【关键区别二】overlay 是「位置区间」上的对象，不跟着字符走。
;;;    在 overlay 起点插入文本，overlay 不会覆盖新文本（默认前开后闭的推进规则）。
(with-temp-buffer
  (insert "0123456789")
  (let ((ov (make-overlay 3 6)))
    (overlay-put ov 'face 'highlight)
    (princ (format "overlay 范围 = %S..%S，face = %S\n"
                   (overlay-start ov) (overlay-end ov) (overlay-get ov 'face)))
    ;; 移动 overlay，而不是移动文本
    (move-overlay ov 1 3)
    (princ (format "move 之后 = %S..%S\n" (overlay-start ov) (overlay-end ov)))
    (princ (format "查询 buffer 位置 2 上的 overlay: %S 个\n"
                   (length (overlays-at 2))))
    (delete-overlay ov)
    (princ (format "删除后 overlays-at 2: %S 个\n" (length (overlays-at 2))))))

;;; 7) 什么时候用哪个？
;;;    文本属性 —— 内容本身的属性（语法高亮、链接、按钮），要跟着文本复制粘贴；
;;;    overlay   —— 临时性的视觉标记（当前行高亮、lint 波浪线、搜索命中），
;;;                 不该被复制进 kill-ring，且频繁增删时开销更小。
;;;    经验法则：**字体锁（font-lock）用文本属性，临时提示用 overlay。**

;;; 8) 常用属性名（都是内置约定）：
;;;    face            —— 显示样式，font-lock 就靠它
;;;    font-lock-face  —— 同 face，但不会被 font-lock 清掉
;;;    help-echo       —— 鼠标悬停提示
;;;    keymap          —— 该段文字上生效的局部按键
;;;    mouse-face      —— 鼠标移上去的样式
;;;    invisible      —— 隐藏文本（注意：只是不显示，length 仍然算它）
;;;    read-only      —— 该段只读
(with-temp-buffer
  (insert (propertize "可点" 'help-echo "点我" 'mouse-face 'highlight))
  (princ (format "help-echo = %S\n"
                 (get-text-property 0 'help-echo (buffer-string)))))

;;; 9) 【坑】invisible 属性只是不显示，字符串长度照算，
;;;    做文本处理时容易「看到的内容和实际内容对不上」。
(princ (format "长度不受显示影响: %S\n"
               (length (propertize "abc" 'invisible t))))

(princ "==== 11 结束 ====\n")
