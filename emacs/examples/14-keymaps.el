;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 14 - Keymap：按键绑定的数据结构与优先级
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "14-keymaps.el")'
;;; 运行：emacs -Q --batch -l 14-keymaps.el
;;; ============================================================

;;; 1) kbd 把「人类写法」的按键描述编译成 Emacs 内部用的键序列。
;;;    它是宏，参数必须是**编译期已知的字符串常量**。
;;;
;;;    【坑】键序列里可能含原始控制字符（C-c 就是字节 0x03），
;;;    直接 %S 打印会把裸控制字符写进输出。要显示给人看，
;;;    一律先过一遍 key-description。
(princ (format "kbd \"C-c x\"   = %S（内部是 %S 个元素的序列）\n"
               (key-description (kbd "C-c x")) (length (kbd "C-c x"))))
(princ (format "kbd \"M-x\"     = %S\n" (key-description (kbd "M-x"))))
(princ (format "kbd \"C-<tab>\" = %S\n" (key-description (kbd "C-<tab>"))))
(princ (format "kbd \"RET\"     = %S\n" (key-description (kbd "RET"))))
(princ (format "kbd \"C-M-s\"   = %S\n" (key-description (kbd "C-M-s"))))
(princ (format "kbd \"<f5>\"    = %S\n" (key-description (kbd "<f5>"))))

;;; 2) keymap 本体就是一个 list，car 是符号 keymap，后面是绑定条目。
;;;    make-sparse-keymap 造「只装你显式绑定的键」的 map（绝大多数场合用它）；
;;;    make-keymap        造「带完整字符表」的 map（要用 suppress-keymap 全接管时才用）。
(defvar demo-map (make-sparse-keymap))
(princ (format "空 keymap: %S\n" demo-map))

;;; 3) define-key 绑定，lookup-key 查询。
;;;    第二个参数必须是键序列（用 kbd 生成），别手写 [?\C-c ?x] 这种。
;;;    【坑】绑定的命令必须先定义好，否则字节编译器会警告
;;;    "not known to be defined" —— 所以 defun 要写在 define-key 前面。
(defun demo-do-a () "命令 A。" (interactive))
(defun demo-do-b () "命令 B。" (interactive))
(define-key demo-map (kbd "C-c a") #'demo-do-a)
(define-key demo-map (kbd "C-c b") #'demo-do-b)
(princ (format "绑定后: %S\n" demo-map))
(princ (format "lookup \"C-c a\" = %S，\"C-c z\" = %S\n"
               (lookup-key demo-map (kbd "C-c a"))
               (lookup-key demo-map (kbd "C-c z"))))

;;; 4) 前缀键：一个键下面挂一整棵子 keymap。C-c 就是最常用的用户前缀。
(define-key demo-map (kbd "C-c m") (make-sparse-keymap))
(define-key demo-map (kbd "C-c m s") #'demo-do-a)
(define-key demo-map (kbd "C-c m t") #'demo-do-b)
(princ (format "前缀下的绑定: %S / %S\n"
               (lookup-key demo-map (kbd "C-c m s"))
               (lookup-key demo-map (kbd "C-c m t"))))
;;;    等价的便捷写法：define-prefix-command 会顺手定义一个具名命令
(define-prefix-command 'demo-prefix-map)
(define-key demo-map (kbd "C-c p") 'demo-prefix-map)
(define-key demo-map (kbd "C-c p f") #'find-file)
(princ (format "define-prefix-command: %S\n"
               (lookup-key demo-map (kbd "C-c p f"))))

;;; 5) keymap-parent：让一个 keymap 继承另一个，改动父 map 子 map 立刻可见。
;;;    minor mode 的 keymap 就是靠这个机制叠加到全局 map 上的。
(defvar demo-child (make-sparse-keymap))
(set-keymap-parent demo-child demo-map)
(princ (format "子 map 继承来的绑定: %S\n" (lookup-key demo-child (kbd "C-c a"))))

;;; 6) 【重点】一次按键到底触发谁，按这个顺序查找：
;;;      overriding-terminal-local-map（极少用）
;;;    → overriding-local-map（极少用）
;;;    → 当前 buffer 的 keymap 文本属性 / point 处的 overlay keymap
;;;    → minor mode 的 keymap（按 minor-mode-map-alist 顺序，越靠前越优先）
;;;    → 当前 buffer 的 local map（major mode 的 keymap）
;;;    → global-map
;;;    所以「major mode 的键被 minor mode 挡住」是正常现象，不是 bug。
(princ (format "global-map 里 C-x C-f 绑的是: %S\n"
               (lookup-key global-map (kbd "C-x C-f"))))

;;; 7) 绑定进 global-map / 当前 buffer 的 local map
(global-set-key (kbd "C-c d") #'demo-do-a)
(princ (format "global-set-key 之后: %S\n" (lookup-key global-map (kbd "C-c d"))))
(with-temp-buffer
  (use-local-map demo-map)
  (princ (format "local map 生效: %S\n" (lookup-key (current-local-map) (kbd "C-c b"))))
  ;; local-set-key 等价于 define-key (current-local-map)
  (local-set-key (kbd "C-c l") #'demo-do-b)
  (princ (format "local-set-key 之后: %S\n"
                 (lookup-key (current-local-map) (kbd "C-c l")))))

;;; 8) 解除绑定：define-key 到 nil；要「屏蔽」某个键则绑到 #'undefined，
;;;    区别在于前者会让外层 keymap 继续处理，后者会明确吃掉这次按键。
(define-key demo-map (kbd "C-c a") nil)
(princ (format "解绑后 lookup = %S\n" (lookup-key demo-map (kbd "C-c a"))))

;;; 9) 【坑】C-c <字母>（单个字母，不加修饰）是**保留给用户**的，
;;;    扩展必须用 C-c 后跟两个字符（如 C-c m s）或 C-c 加标点/控制字符。
;;;    同理 M-x 保留、C-x 保留给 Emacs 自己。
;;;    【坑】还有一条：绑定会**直接覆盖**，define-key 不警告。
;;;    想知道某个键有没有被占，先 lookup-key 或按 C-h k 看。

;;; 10) key-binding 问的是「在当前 buffer 的上下文里，这个键最终会执行什么」，
;;;     与 lookup-key（只查单个 map）不同。
(princ (format "key-binding C-x C-f = %S\n" (key-binding (kbd "C-x C-f"))))
;;;    【坑】substitute-command-keys 返回的字符串**带文本属性**，
;;;    直接拿去做字符串比较或拼进别的字符串会踩坑（见 11-text-properties.el）。
(princ (format "substitute-command-keys（带属性）: %S\n"
               (substitute-command-keys "\\[find-file]")))
(princ (format "去掉属性之后: %S\n"
               (substring-no-properties (substitute-command-keys "\\[find-file]"))))

;;; 11) 用 which-key / 描述来给用户提示：命令必须有 docstring，
;;;     因为 C-h k、which-key 的提示都取自它。
(princ (format "命令的 docstring: %S\n" (documentation #'demo-do-a)))

(princ "==== 14 结束 ====\n")
