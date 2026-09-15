;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 15 - Minor mode：可开关的局部增强
;;;   define-minor-mode、lighter、自带 keymap、全局 / buffer 局部
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "15-minor-mode.el")'
;;; 运行：emacs -Q --batch -l 15-minor-mode.el
;;; ============================================================

;;; 0) 【坑】define-minor-mode 在 :global t 时会把开关变量定义成一个
;;;    defcustom（因为它对所有 buffer 生效，属于「用户选项」）。
;;;    defcustom 必须指定 :group，否则字节编译器会报
;;;    "fails to specify containing group"。所以先建一个 group。
(defgroup demo-lint nil
  "演示用 minor mode 的配置组。"
  :group 'emacs)

;;; 1) define-minor-mode 一次生成四样东西：
;;;      - 一个开关变量 demo-lint-mode
;;;      - 一个同名命令（M-x demo-lint-mode 可切换）
;;;      - 一个 keymap 变量 demo-lint-mode-map
;;;      - 一个 hook 变量 demo-lint-mode-hook
;;;    另外 :lighter 是显示在 mode-line 上的字符串（要以空格开头）。
(defvar demo-lint-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c l n") #'demo-lint-next)
    (define-key map (kbd "C-c l r") #'demo-lint-run)
    map)
  "demo-lint-mode 的按键表。")

(defun demo-lint-next ()
  "跳到下一个问题。"
  (interactive))
(defun demo-lint-run ()
  "跑一次检查。"
  (interactive))

(define-minor-mode demo-lint-mode
  "演示用的 minor mode：给当前 buffer 加上检查功能。"
  :lighter " Lint"
  :keymap demo-lint-mode-map
  :global nil          ; nil = 只对当前 buffer 生效（默认），t = 全局生效
  :init-value nil      ; 默认关
  (if demo-lint-mode
      ;; 【注意】body 在开关状态**改变之后**执行，
      ;; 变量 demo-lint-mode 此时已经是新值（t 或 nil）。
      (princ (format "  demo-lint-mode 已打开，buffer = %S\n" (buffer-name)))
    (princ (format "  demo-lint-mode 已关闭，buffer = %S\n" (buffer-name)))))

;;; 2) minor mode 是 buffer-local 的：在一个 buffer 里打开，不影响别的 buffer。
(let ((a (generate-new-buffer "demo-a"))
      (b (generate-new-buffer "demo-b")))
  (with-current-buffer a
    (demo-lint-mode 1)
    (princ (format "A 里: %S，keymap 命中: %S\n"
                   demo-lint-mode
                   (lookup-key (current-local-map) (kbd "C-c l n")))))
  (with-current-buffer b
    (princ (format "B 里: %S（不受影响）\n" demo-lint-mode)))
  (kill-buffer a)
  (kill-buffer b))

;;; 3) 开关变量本身就是状态，别再用额外的布尔量去记。
;;;    传给 mode 函数的参数语义：
;;;      1 / t  打开
;;;      0 / nil 关闭
;;;      -1     强制关闭（即使是全局 mode）
;;;      省略   取反（toggle）
(with-temp-buffer
  (demo-lint-mode 1)
  (princ (format "打开后: %S\n" demo-lint-mode))
  (demo-lint-mode -1)
  (princ (format "关闭后: %S\n" demo-lint-mode)))

;;; 4) minor mode 的 keymap 通过 minor-mode-map-alist 生效，
;;;    优先级**高于** major mode 的 keymap —— 这是设计使然。
;;;    想确认自己的 mode 有没有挂上去，查这个 alist。
(princ (format "minor-mode-map-alist 里有没有 demo-lint-mode: %S\n"
               (assq 'demo-lint-mode minor-mode-map-alist)))
(princ (format "minor-mode-alist（mode-line 显示）: %S\n"
               (assq 'demo-lint-mode minor-mode-alist)))

;;; 5) :global t 的全局 minor mode。它只有一个开关，对所有 buffer 同时生效，
;;;    body 里通常要自己遍历 buffer 做设置。适合「整个编辑器的功能」。
(defvar demo-global-count 0)
(define-minor-mode demo-global-mode
  "演示用的全局 minor mode。"
  :global t
  :group 'demo-lint
  :init-value nil
  (setq demo-global-count (if demo-global-mode 1 0))
  (princ (format "  全局 mode 现在是: %S\n" demo-global-mode)))
(demo-global-mode 1)
(princ (format "全局开关: %S, 计数 = %S\n" demo-global-mode demo-global-count))
(demo-global-mode -1)

;;; 6) 【坑】mode 的 keymap 变量名必须严格是 `<mode 名>-map`，
;;;    define-minor-mode 才会自动认领它。写错了键就不生效，而且不报错。
;;;    （本示例里因为显式写了 :keymap 所以没这个问题，但靠命名约定时会有。）

;;; 7) 【坑】body 里不要写 (message ...)：mode 会在每个 buffer 里各跑一次，
;;;    打开一个 mode 刷屏几十行是常见的体验灾难。真要提示用 (run-with-idle-timer ...)。

;;; 8) 更轻量的选择：如果只是想给几个键加绑定，不一定要写 mode，
;;;    可以直接在某 mode 的 hook 里用 local-set-key；
;;;    但要做成「用户能开关 + mode-line 有提示 + 能进 hook」就必须是 minor mode。

;;; 9) 手动查询：minor-mode-list 是所有已定义的 minor mode
(princ (format "已定义的 minor mode 里含 demo-lint-mode: %S\n"
               (and (memq 'demo-lint-mode minor-mode-list) t)))

;;; 10) 关掉时清理：body 里 if 的 else 分支就是清理的地方。
;;;     典型要清的东西：overlay、process、timer、advice、buffer-local 变量。
(princ (format "kill-all-local-variables 会连 minor mode 一起关掉\n"))

(princ "==== 15 结束 ====\n")
