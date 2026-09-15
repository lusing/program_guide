;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 17 - Hook：Emacs 的扩展点总纲
;;;   add-hook / remove-hook / run-hooks / 顺序控制 / 局部 hook
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "17-hooks.el")'
;;; 运行：emacs -Q --batch -l 17-hooks.el
;;; ============================================================

;;; 1) hook 就是一个「函数列表」变量，约定以 -hook 结尾。
;;;    add-hook 往里加，remove-hook 往外删，run-hooks 依次调用。
(defvar demo-hook nil "演示用的普通 hook。")

(defun demo-first () "第一个。" (princ "    [first] 执行\n"))
(defun demo-second () "第二个。" (princ "    [second] 执行\n"))

(add-hook 'demo-hook #'demo-first)
(add-hook 'demo-hook #'demo-second)
(princ "1) 按加入顺序（默认插在最前面，所以后加的先跑）：\n")
(run-hooks 'demo-hook)

;;; 2) 【坑】默认 add-hook 是**插到最前面**（prepend），
;;;    所以后加入的函数先执行。想让后加的后跑，第三个参数传 t。
(setq demo-hook nil)
(add-hook 'demo-hook #'demo-first)
(add-hook 'demo-hook #'demo-second t)          ; t = append
(princ "2) 传 t 之后（后加的后跑）：\n")
(run-hooks 'demo-hook)

;;; 3) add-hook 是幂等的：同一个函数不会加两次。
(setq demo-hook nil)
(add-hook 'demo-hook #'demo-first)
(add-hook 'demo-hook #'demo-first)
(princ (format "3) 加了两次，hook 里只有 %S 个函数\n" (length demo-hook)))

;;; 4) 【坑】永远不要把 lambda 直接加进 hook。
;;;    理由有两条：一是 (remove-hook 'h (lambda ...)) 删不掉
;;;    （每次求值 lambda 都是新对象）；二是用户 C-h v 看 hook 时
;;;    满屏 #<compiled-function> 完全没法读。
;;;    正确做法：defun 一个具名函数再加进去，本示例的 demo-first 就是这么写的。
(princ (format "4) hook 里装的是符号: %S\n" demo-hook))

;;; 5) 带参数的 hook（abnormal hook）。普通 hook 的函数不接收参数，
;;;    带参数的要用 run-hook-with-args 系列。
(defvar demo-args-hook nil "演示用的带参 hook。")
(defun demo-on-save (file)
  "文件 FILE 保存时调用。"
  (princ (format "    [on-save] 保存了 %S\n" file)))
(add-hook 'demo-args-hook #'demo-on-save)
(run-hook-with-args 'demo-args-hook "/tmp/a.txt")

;;; 6) 「直到成功 / 直到失败」两种变体，适合做「谁来负责处理」的分派：
;;;      run-hook-with-args-until-success —— 第一个返回非 nil 就停
;;;      run-hook-with-args-until-failure —— 第一个返回 nil 就停
(defvar demo-chain nil "演示用的链式 hook。")
(defun demo-try-a (x) "处理 A。" (if (eq x 'a) "A 接下了" nil))
(defun demo-try-b (x) "处理 B。" (if (eq x 'b) "B 接下了" nil))
(add-hook 'demo-chain #'demo-try-a)
(add-hook 'demo-chain #'demo-try-b)
(princ (format "6) until-success 传 'b: %S\n"
               (run-hook-with-args-until-success 'demo-chain 'b)))
(princ (format "   until-failure 传 'b: %S\n"
               (run-hook-with-args-until-failure 'demo-chain 'b)))

;;; 7) 精确控制顺序：add-hook 的第三个参数可以是整数 DEPTH（-100..100）。
;;;    数值越小越先执行，默认 0。这是「我的函数必须在某个内置函数之后跑」的正解。
(setq demo-hook nil)
(add-hook 'demo-hook #'demo-first 10)
(add-hook 'demo-hook #'demo-second -10)
(princ (format "7) 按 depth 排序后: %S\n" demo-hook))

;;; 8) buffer 局部 hook：add-hook 的第四个参数传 t（LOCAL）。
;;;    它只影响当前 buffer —— 写 major/minor mode 时这是默认行为。
(let ((a (generate-new-buffer "demo-hook-a"))
      (b (generate-new-buffer "demo-hook-b")))
  (with-current-buffer a
    (add-hook 'demo-hook #'demo-first nil t)
    (princ (format "8) buffer A 里的 hook: %S\n" demo-hook)))
  (with-current-buffer b
    (princ (format "   buffer B 里的 hook: %S（不受影响）\n" demo-hook)))
  (kill-buffer a)
  (kill-buffer b))

;;; 9) 「一次性」hook：用 let 动态绑定 hook 变量，退出自动恢复。
;;;    因为 hook 变量是 defvar 出来的（special），let 能临时改写它。
(setq demo-hook (list #'demo-first))
(princ "9) 临时替换 hook：\n")
(let ((demo-hook (list (lambda () (princ "    [临时] 只跑这一次\n")))))
  (run-hooks 'demo-hook))
(princ (format "   退出 let 后恢复为: %S\n" demo-hook))

;;; 10) 常用内置 hook 一览（写扩展时最常挂的几个）：
;;;     emacs-startup-hook    启动完成后
;;;     find-file-hook        打开文件后（注意：此时 point 在开头）
;;;     after-save-hook       保存之后
;;;     before-save-hook      保存之前（想自动格式化就挂这）
;;;     kill-buffer-hook      关 buffer 之前
;;;     post-command-hook     每条命令之后（别放重活，会卡）
;;;     pre-command-hook      每条命令之前
;;;     change-major-mode-hook  切换 major mode 时
;;;     <mode>-hook           某个 mode 启用后
;;;     after-change-functions  文本被修改后（abnormal，带三个参数）
(princ (format "10) find-file-hook 里现在有 %S 个函数\n" (length find-file-hook)))

;;; 11) 【坑】post-command-hook 和 after-change-functions 每次击键都会跑，
;;;     里面做重活会让 Emacs 明显卡顿。要么做缓存，要么挂到 idle timer 上
;;;     （见 21-timers.el）。

(princ "==== 17 结束 ====\n")
