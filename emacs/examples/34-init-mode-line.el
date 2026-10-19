;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 34 - 初始化文件与 mode line
;;;   读完这本书，你写的代码总要有地方安放：这一章讲 init.el
;;;   的加载机制、配置的拆分与懒加载，最后拆开屏幕最下面那条
;;;   mode line，看它是一个怎样「每次重绘都重新求值」的模板。
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "34-init-mode-line.el")'
;;; 运行：emacs -Q --batch -l 34-init-mode-line.el
;;; ============================================================

;;; ---------- 1) 初始化文件在哪里 ----------
;;; Emacs 启动时按顺序找配置：先 early-init.el（很早，图形界面
;;; 还没起来就加载），再 user-emacs-directory 下的 init.el，
;;; 找不到才退回老式的 ~/.emacs。locate-user-emacs-file 负责把
;;; 文件名拼到你的用户目录下，缺哪个目录它会替你建。
(princ "== 1) 初始化文件在哪里 ==\n")
(princ (format "user-init-file = %S（-Q 不读 init，正常启动时指向它）\n"
               user-init-file))
(princ (format "user-emacs-directory = %S\n" user-emacs-directory))
(princ (format "init 文件  = %s\n" (locate-user-emacs-file "init.el")))
(princ (format "early-init = %s\n" (locate-user-emacs-file "early-init.el")))
(princ (format "custom 文件 = %s（M-x customize 的改动落在这里）\n"
               (locate-user-emacs-file "custom.el")))

;;; ---------- 2) setq 与 setq-default ----------
;;; init.el 里最常见的错误：对 buffer-local 变量直接 setq。
;;; setq 只改「当前缓冲区」里的局部值；要改所有缓冲区的默认值，
;;; 得用 setq-default。
(princ "\n== 2) setq 与 setq-default ==\n")
(defvar my-tabs 'default-value "演示用：带 buffer-local 的选项。")
(make-variable-buffer-local 'my-tabs)

(with-temp-buffer
  (setq my-tabs 'only-in-A)                    ; 只在 A 这个缓冲区里生效
  (princ (format "缓冲区 A：setq 后值 = %S，local-variable-p = %S\n"
                 my-tabs (local-variable-p 'my-tabs))))
(with-temp-buffer
  (princ (format "缓冲区 B：值 = %S（回落到默认），local-variable-p = %S\n"
                 my-tabs (local-variable-p 'my-tabs))))
(setq-default my-tabs 'new-default)            ; 改的是「默认值」
(princ (format "setq-default 后：default-value = %S\n" (default-value 'my-tabs)))
(with-temp-buffer
  (princ (format "缓冲区 C：值 = %S（用上了新默认）\n" my-tabs)))

;;; ---------- 3) 拆分配置：provide / require / with-eval-after-load ----------
;;; init.el 长了就要拆文件。约定是：每个文件末尾 (provide '特性名)，
;;; 使用方 (require '特性名)。with-eval-after-load 登记「这个特性
;;; 装载完成之后要做的事」，哪怕装载发生在很久以后也会补上。
(princ "\n== 3) 拆分配置：provide / require / with-eval-after-load ==\n")
(declare-function my-init-extra-greet "my-init-extra") ; 告诉编译器：这函数在别的文件里

;; 模拟拆出去的第二个配置文件（真实场景放在 ~/.emacs.d/lisp/ 之类的目录）
(let ((dir (make-temp-file "myinit" t)))
  (with-temp-file (expand-file-name "my-init-extra.el" dir)
    (insert ";;; -*- lexical-binding: t; -*-\n"
            "(defun my-init-extra-greet (name)\n"
            "  (format \"你好，%s！——来自 my-init-extra\" name))\n"
            "(provide 'my-init-extra)\n"))
  (let ((load-path (cons dir load-path)))
    (with-eval-after-load 'my-init-extra
      (princ ">> 钩子触发：my-init-extra 刚刚装载完成\n"))
    (require 'my-init-extra)
    (princ (format "require 之后调用： %s\n" (my-init-extra-greet "读者")))))

;;; ---------- 4) autoload：用到才加载 ----------
;;; require 是「现在就装载」；autoload 是「先登记，第一次调用时
;;; 才去装载」。Emacs 自带几千个命令，全靠这一招做到秒开。
(princ "\n== 4) autoload：用到才加载 ==\n")
(autoload 'my-lazy-fn "my-lazy-lib")
(princ (format "登记后：fboundp = %S，函数体 = %S（只是一张欠条）\n"
               (fboundp 'my-lazy-fn) (symbol-function 'my-lazy-fn)))
(let ((dir (make-temp-file "mylibs" t)))
  (with-temp-file (expand-file-name "my-lazy-lib.el" dir)
    (insert ";;; -*- lexical-binding: t; -*-\n"
            "(provide 'my-lazy-lib)\n"
            "(defun my-lazy-fn () (+ 1 2))\n"))
  (let ((load-path (cons dir load-path)))
    (princ (format "第一次调用 my-lazy-fn = %S\n" (my-lazy-fn)))
    (princ (format "调用后函数体 = %S（欠条换成了真函数）\n"
                   (symbol-function 'my-lazy-fn)))))

;;; ---------- 5) 常用开关：模式、文件类型、快捷键 ----------
;;; init.el 里高频出现的四件套。--batch 下没有图形界面，
;;; 但变量的翻转照常发生，正好看清它们本质只是改变量。
(princ "\n== 5) 常用开关：模式、文件类型、快捷键 ==\n")
(menu-bar-mode -1)
(princ (format "(menu-bar-mode -1) 后变量 = %S（nil = 关）\n" menu-bar-mode))
(global-auto-revert-mode 1)
(princ (format "(global-auto-revert-mode 1) 后变量 = %S（t = 开）\n"
               global-auto-revert-mode))
(add-to-list 'auto-mode-alist '("\\.myext\\'" . text-mode))
(princ (format "auto-mode-alist 新增：%S\n" (assoc "\\.myext\\'" auto-mode-alist)))

(defun my-open-config ()
  "跳到 init 文件（教学用占位命令）。"
  (interactive)
  nil)
;; 交互式里惯用 (kbd "C-c t")；--batch 下 read-kbd-macro 不可靠，
;; 这里直接写按键向量的字面量，两者是同一个按键序列。
(global-set-key [(control c) ?t] 'my-open-config)
(let ((keys (car (where-is-internal 'my-open-config))))
  (princ (format "C-c t 绑定情况： 向量 = %S，人话 = %s\n"
                 keys (key-description keys))))

;;; ---------- 6) mode line：mode-line-format 的结构与渲染 ----------
;;; 屏幕最下面那条 mode line 由变量 mode-line-format 描述：
;;; 一个模板列表，每个元素是一个「片段」，Emacs 每次重绘都把
;;; 整个列表重新求值一遍。片段有五种：字符串（内含 %-构造）、
;;; 符号（解引用成另一段模板）、(:eval 表达式)、(:propertize 文字 …)
;;; 和 (变量 非空时内容) 这样的条件片段。
(princ "\n== 6) mode line：mode-line-format 的结构 ==\n")
(princ "默认 mode-line-format 的顶层元素：\n")
(let ((i 0))
  (dolist (elt mode-line-format)
    (princ (format "  [%2d] %S\n" i elt))
    (setq i (1+ i))))

;; 教学用小渲染器：只实现上述五种片段，替 Emacs 把模板渲染成字符串。
(defun my-fill-percent (s)
  "把字符串 S 里的 %-构造替换成实际内容（只支持常用的一小撮）。"
  (let ((out "") (i 0) (n (length s)))
    (while (< i n)
      (let ((ch (aref s i)))
        (if (and (eq ch ?%) (< (1+ i) n))
            (let ((c (aref s (1+ i))))
              (setq out (concat out
                                (cond
                                 ((eq c ?b) (buffer-name))
                                 ((eq c ?f) (or (buffer-file-name) "(无文件)"))
                                 ((eq c ?l) (number-to-string (line-number-at-pos)))
                                 ((eq c ?c) (number-to-string (current-column)))
                                 ((eq c ?n) (if (buffer-narrowed-p) "Narrow " ""))
                                 ((eq c ?p) (number-to-string
                                             (if (<= (point-max) (point-min)) 100
                                               (/ (* 100 (- (point) (point-min)))
                                                  (- (point-max) (point-min))))))
                                 ((eq c ?-) "-")
                                 ((eq c ?%) "%")
                                 (t (format "%%%c" c))))
                    i (+ i 2)))
          (setq out (concat out (char-to-string ch)) i (1+ i)))))
    out))

(defun my-render-mode-line (fmt)
  "把 mode-line 模板 FMT 渲染成字符串（教学用简化版）。"
  (cond
   ((or (null fmt) (eq fmt t)) "")
   ((stringp fmt) (my-fill-percent fmt))
   ((symbolp fmt) (my-render-mode-line (symbol-value fmt)))
   ((consp fmt)
    (cond
     ((eq (car fmt) :eval) (my-render-mode-line (eval (cadr fmt) t)))
     ((eq (car fmt) :propertize) (my-render-mode-line (cadr fmt)))
     ((symbolp (car fmt))                    ; (变量 非空时 空时) 条件片段
      (if (and (boundp (car fmt)) (symbol-value (car fmt)))
          (my-render-mode-line (cadr fmt))
        (my-render-mode-line (caddr fmt))))  ; 第三段可省略（省略时是 nil）
     (t (mapconcat #'my-render-mode-line fmt ""))))))

(defvar my-mode-name "示例模式" "演示用：mode line 里的符号片段。")
(defvar my-flag nil "演示用：条件片段的开关。")

(with-temp-buffer
  (insert "第一行\n第二行\n第三行\n")
  (goto-char (point-min))
  (forward-line 2)
  (let ((mode-line-format
         (list "-" 'my-mode-name "：" "%b" "  行%l 列%c %p%%"
               '(my-flag " [旗]")
               " "
               '(:eval (format "«%d 字符»" (- (point-max) (point-min))))
               " "
               '(:propertize "只读" face bold))))
    (princ (format "渲染（my-flag = nil）  = %s\n"
                   (my-render-mode-line mode-line-format)))
    (let ((my-flag t))
      (princ (format "渲染（my-flag = t）    = %s\n"
                     (my-render-mode-line mode-line-format))))))

(princ "==== 34 结束 ====\n")
