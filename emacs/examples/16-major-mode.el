;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 16 - Major mode：语法表、字体锁、派生关系
;;;   以一个简单的「笔记格式」mode 为例，走完一遍完整的定义流程
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "16-major-mode.el")'
;;; 运行：emacs -Q --batch -l 16-major-mode.el
;;; ============================================================

;;; ------------------------------------------------------------
;;; 要定义的格式：一种极简的笔记文件
;;;
;;;   # 标题
;;;   * TODO 待办条目
;;;   * DONE 已完成条目
;;;   ; 这是注释
;;;
;;; 目标：TODO / DONE 着色，冒号引导的标签着色，`;` 行是注释。
;;; ------------------------------------------------------------

;;; 1) 语法表（syntax table）：告诉 Emacs 哪些字符是注释、引号、分隔符。
;;;    它决定了 C-M-f、M-;、自动缩进、正则里的 \\sw 等一大堆行为，
;;;    是 major mode 里最容易忽略、但影响最大的一块。
(defvar demo-note-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; ";" 行注释，且第二字符也是 ";"（Emacs 用 ". 12" 表示注释起始+第二字符）
    (modify-syntax-entry ?\; ". 12" st)
    ;; 换行符结束注释
    (modify-syntax-entry ?\n ">" st)
    ;; 连字符"-"、下划线"_"、冒号":"算作单词组成字符，
    ;; 这样 M-f 移动和正则 \\sw 匹配就会把 my-tag 当成一个整体
    (modify-syntax-entry ?- "w" st)
    (modify-syntax-entry ?_ "w" st)
    st)
  "demo-note-mode 的语法表。")

;;; 2) 字体锁关键字。每条是 (正则 . face) 或 (正则 (子组 face ...))。
;;;    写正则推荐用 rx（见 08-strings-regexp.el），这里为了紧凑用字符串。
(defvar demo-note-font-lock-keywords
  '(("^#\\s-+\\(.*\\)$"                 1 'bold)          ; 标题
    ("^\\*\\s-+\\(TODO\\)\\s-"          1 'warning t)     ; TODO
    ("^\\*\\s-+\\(DONE\\)\\s-"          1 'success t)     ; DONE
    ("\\(@[a-zA-Z0-9_-]+\\)"            1 'italic t))     ; @标签
  "demo-note-mode 的高亮规则。")

;;; 3) define-derived-mode 一次生成：
;;;      - mode 命令 demo-note-mode
;;;      - demo-note-mode-hook / -map / -syntax-table / -abbrev-table
;;;      - 自动调用 kill-all-local-variables、设置 major-mode 和 mode-name
;;;      - 退出前自动 run-hooks demo-note-mode-hook
;;;    parent 选 text-mode：就继承了文本类的缩进、填充、段落命令。
(define-derived-mode demo-note-mode text-mode "Note"
  "极简笔记格式的 major mode。"
  ;; 注释相关（M-; 依赖这些）
  (setq-local comment-start "; ")
  (setq-local comment-end "")
  ;; 字体锁：font-lock-defaults 的第二个参数表示「是否关掉语法阶段着色」
  (setq font-lock-defaults '(demo-note-font-lock-keywords nil t))
  ;; 缩进：简单起见让 Tab 走 indent-relative
  (setq-local indent-line-function #'indent-relative))

;;; 4) 派生关系怎么查。
;;;    【坑一】当 parent 是 fundamental-mode 时，derived-mode-parent **是 nil**
;;;           （它是根，define-derived-mode 不为它记录父关系）。
;;;    【坑二】(derived-mode-p 'fundamental-mode) **永远是 nil**，
;;;           因为派生链上就没有 fundamental-mode 这一环 ——
;;;           想判断「是不是最原始的 mode」，要判 major-mode 本身而不是 derived-mode-p。
;;;    所以：判断派生关系一律用 derived-mode-p，别去读 derived-mode-parent 属性。
(princ (format "4) 派生关系: parent 属性 = %S\n"
               (get 'demo-note-mode 'derived-mode-parent)))
(with-temp-buffer
  (demo-note-mode)
  (princ (format "   derived-mode-p: text=%S prog=%S fundamental=%S\n"
                 (derived-mode-p 'text-mode)
                 (derived-mode-p 'prog-mode)
                 (derived-mode-p 'fundamental-mode)))
  (princ (format "   major-mode 本身 = %S\n" major-mode)))

;;; 5) 语法表生效后的效果：char-syntax 返回字符的语法类别
(with-temp-buffer
  (demo-note-mode)
  (princ (format "5) ';' 的语法类别 = %S（'< ' 表示注释起始）\n"
                 (char-to-string (char-syntax ?\;))))
  (princ (format "   '-' 的语法类别 = %S（'w' 表示单词组成）\n"
                 (char-to-string (char-syntax ?-)))))

;;; 6) 字体锁实际着色效果。font-lock-ensure 强制把整个 buffer 着色一遍
;;;    （交互模式下它是按需、延迟触发的，batch 下要手动调用）。
(with-temp-buffer
  (demo-note-mode)
  (insert "# 我的笔记\n")
  (insert "* TODO 买咖啡\n")
  (insert "* DONE 写教程 @emacs\n")
  (font-lock-mode 1)
  (font-lock-ensure)
  ;; 【坑】search-forward 结束后 point 停在匹配的**末尾**，
  ;; 而属性区间是左闭右开的，所以要在 (match-beginning 0) 处取属性。
  (goto-char (point-min))
  (search-forward "TODO")
  (princ (format "6) TODO 处被着上的 face = %S\n"
                 (get-text-property (match-beginning 0) 'face)))
  (goto-char (point-min))
  (search-forward "DONE")
  (princ (format "   DONE 处被着上的 face = %S\n"
                 (get-text-property (match-beginning 0) 'face)))
  (goto-char (point-min))
  (search-forward "咖啡")
  (princ (format "   普通正文的 face = %S\n"
                 (get-text-property (match-beginning 0) 'face))))

;;; 7) mode 的 hook 在 mode 函数**末尾**被 run，所以 body 里的设置在 hook 之前生效。
(princ "7) hook 触发顺序：\n")
(let ((log nil))
  (with-temp-buffer
    (let ((demo-note-mode-hook (list (lambda () (push "hook 跑了" log)))))
      (demo-note-mode))
    (princ (format "   %S，当前 mode = %S，mode-name = %S\n"
                   (car log) major-mode mode-name))))

;;; 8) 自动把文件后缀关联到 mode：改 auto-mode-alist。
;;;    注意正则要匹配**完整路径**，末尾用 \\' 锚定，别用 $。
(princ (format "8) auto-mode-alist 新增前是否已有关联: %S\n"
               (rassq 'demo-note-mode auto-mode-alist)))
(add-to-list 'auto-mode-alist '("\\.note\\'" . demo-note-mode))
(princ (format "   加完之后: %S\n" (rassq 'demo-note-mode auto-mode-alist)))

;;; 9) 【坑】major mode 的命名必须以 -mode 结尾，且是全局唯一的；
;;;    变量、keymap、hook 都靠这个名字派生，改名的成本很高，一开始就取好。

;;; 10) 一个 mode 该提供什么（checklist）：
;;;     - 语法表            —— 影响移动、注释、缩进
;;;     - font-lock-defaults —— 高亮
;;;     - comment-start 等  —— M-; 能用
;;;     - indent-line-function —— Tab 能用
;;;     - 若干命令 + keymap —— 用户能操作
;;;     - 一个 hook         —— 用户能扩展
(princ (format "10) keymap 名 = %S，hook 名 = %S\n"
               'demo-note-mode-map 'demo-note-mode-hook))

(princ "==== 16 结束 ====\n")
