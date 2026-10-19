;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 30 - kill ring：剪切与粘贴的实现
;;;   读真实源码，再亲手把 kill ring 转起来
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "30-kill-ring.el")'
;;; 运行：emacs -Q --batch -l 30-kill-ring.el
;;; ============================================================
(require 'jka-compr)

;;; ---------- 工具：从一个函数名找到它的源码（同第 29 章） ----------
(defun my-source-file (sym)
  "返回 SYM 的定义所在源码文件的路径；找不到返回 nil。"
  (let* ((compiled (symbol-file sym 'defun))
         (base (and compiled
                    (if (string-match-p "\\.elc\\'" compiled)
                        (substring compiled 0 -1)
                      compiled))))
    (cond ((null base) nil)
          ((file-exists-p base) base)
          ((file-exists-p (concat base ".gz")) (concat base ".gz"))
          (t nil))))

(defun my-defun-source (sym)
  "抓出 SYM 的 defun 原文；抓不到返回 nil。"
  (let ((file (my-source-file sym)))
    (when file
      (with-temp-buffer
        (let ((jka-compr-verbose nil))
          (insert-file-contents file))
        (goto-char (point-min))
        (when (re-search-forward
               (concat "^(def\\(?:un\\|macro\\|subst\\)[ \t\n]+"
                       (regexp-quote (symbol-name sym)) "[ \t\n]")
               nil t)
          (beginning-of-line)
          (let ((start (point)))
            (condition-case nil
                (forward-sexp)
              (error (goto-char (point-max))))
            (buffer-substring-no-properties start (point))))))))

(defun my-print-source (sym)
  "打印 SYM 的定义位置和源码。"
  (princ (format "\n----- %S -----\n" sym))
  (princ (format "定义在：%s\n" (or (my-source-file sym) "（找不到）")))
  (let ((src (my-defun-source sym)))
    (if src
        (princ (concat src "\n"))
      (princ "找不到源码原文\n"))))

;;; ---------- 1) 读源码 ----------
(princ "== 1) 读源码：kill ring 的三个核心函数 ==\n")
(my-print-source 'zap-to-char)
(my-print-source 'kill-append)
(my-print-source 'current-kill)

;;; ---------- 工具：看指针在环里的位置 ----------
(defun my-yank-pos ()
  "返回 kill-ring-yank-pointer 相对于 kill-ring 头的偏移（0 = 最新）。"
  (- (length kill-ring) (length kill-ring-yank-pointer)))

;;; 后面几节都会动全局的 kill-ring，先存起来，最后还回去。
(let ((saved kill-ring)
      (saved-ptr kill-ring-yank-pointer))

  ;;; ---------- 2) 建立 kill ring：两次「剪切」 ----------
  (princ "\n== 2) 建立 kill ring ==\n")
  (setq kill-ring nil kill-ring-yank-pointer nil last-command nil)
  (dolist (word '("alpha" "beta"))
    (with-temp-buffer
      (insert word)
      ;; kill-region 从「当前缓冲区」里删掉 [beg, end) 并压入环
      (kill-region (point-min) (point-max))))
  (princ (format "剪了 alpha、beta 之后：%S\n" kill-ring))
  (princ (format "指针指向第 %S 个（0 = 最新）\n" (my-yank-pos)))

  ;;; ---------- 3) kill-append：并到最近一次上 ----------
  (princ "\n== 3) kill-append 把新文本粘到环头 ==\n")
  (kill-append "gamma" nil)
  (princ (format "kill-append \"gamma\"（接在后面）：%S\n" kill-ring))
  (kill-append "pre-" t)
  (princ (format "kill-append \"pre-\"（接在前面）  ：%S\n" kill-ring))

  ;;; ---------- 4) current-kill：相对旋转 ----------
  (princ "\n== 4) current-kill 是「相对移动」，不是绝对下标 ==\n")
  (setq kill-ring '("a" "b" "c") kill-ring-yank-pointer kill-ring)
  (dolist (n '(0 1 1 1))
    (let ((got (current-kill n)))
      (princ (format "current-kill %S -> %S（指针现在在第 %S 个）\n"
                     n got (my-yank-pos)))))

  ;;; ---------- 5) zap-to-char：搜索 + 剪切一步到位 ----------
  (princ "\n== 5) zap-to-char：搜索 + 剪切一步到位 ==\n")
  (with-temp-buffer
    (insert "one two three")
    (goto-char (point-min))
    ;; 杀掉到下一个空格（含空格）为止
    (zap-to-char 1 ?\s)
    (princ (format "缓冲区剩下 = %S\n" (buffer-string)))
    (princ (format "环头是        = %S\n" (car kill-ring))))

  ;;; ---------- 6) yank：把环里的文本取回来 ----------
  (princ "\n== 6) yank 从环里取文本 ==\n")
  (setq kill-ring '("hello" "world") kill-ring-yank-pointer kill-ring)
  ;; 手写一遍 yank 的核心动作
  (with-temp-buffer
    (insert "→ ")
    (insert-for-yank (current-kill 0))
    (princ (format "手写核心：[%S]\n" (buffer-string))))
  ;; 再真的调用一次 yank（push-mark 的 "Mark set" 用 inhibit-message 静音）
  (with-temp-buffer
    (let ((inhibit-message t))
      (yank)
      (princ (format "调用 yank：文本 = %S，point = %S，mark = %S\n"
                     (buffer-string) (point) (mark t)))))

  (setq kill-ring saved kill-ring-yank-pointer saved-ptr))

(princ "==== 30 结束 ====\n")
