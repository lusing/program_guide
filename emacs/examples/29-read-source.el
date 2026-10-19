;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 29 - 读懂真实函数：三个 buffer 命令的走查
;;;   把本机 Emacs 的源码抓出来读，再动手验证它的行为
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "29-read-source.el")'
;;; 运行：emacs -Q --batch -l 29-read-source.el
;;; ============================================================
(require 'jka-compr)

;;; ---------- 1) 工具：从一个函数名找到它的源码 ----------
;;; symbol-file 告诉你「这个函数编译自哪个文件」；
;;; 源码通常是同名 .el（本机是压缩过的 .el.gz）。
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
        ;; jka-compr-verbose 置 nil，读 .el.gz 时不打印「正在解压」的提示
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

(princ "== 1) 从符号名找到源码 ==\n")
(my-print-source 'beginning-of-buffer)
(my-print-source 'mark-whole-buffer)
(my-print-source 'append-to-buffer)

;;; ---------- 2) 验证 beginning-of-buffer 的「N/10」语义 ----------
;;; 造一个 10 行、每行 10 个字符的缓冲区，共 110 个字符。
(defun my-line-of (pos)
  "返回 POS 所在的行号（从 1 开始）。"
  (save-excursion
    (goto-char pos)
    (line-number-at-pos)))

(defun my-demo-buffer ()
  "造一个 10 行 x 10 列的演示缓冲区。"
  (let ((buf (get-buffer-create " *demo-29*")))
    (with-current-buffer buf
      (erase-buffer)
      (dotimes (_ 10)
        (insert "0123456789\n")))
    buf))

(princ "\n== 2) beginning-of-buffer 的 N/10 语义 ==\n")
(with-current-buffer (my-demo-buffer)
  ;; push-mark 会往 stderr 打印 "Mark set"，这里静音
  (let ((inhibit-message t))
    (goto-char (point-max))
    ;; 【注意】beginning-of-buffer 带 (declare (interactive-only ...))，
    ;; 直接调用会被字节编译器警告。with-no-warnings 明确表示「我知情」。
    (with-no-warnings (beginning-of-buffer))
    (princ (format "无参数：point=%S，在第 %S 行（point-min=%S point-max=%S）\n"
                   (point) (my-line-of (point)) (point-min) (point-max)))
    (goto-char (point-max))
    (with-no-warnings (beginning-of-buffer 5))
    (princ (format "参数 5：point=%S，在第 %S 行   <- 走到 5/10 处再下移一行\n"
                   (point) (my-line-of (point))))))

;;; ---------- 3) 验证 mark-whole-buffer：point 与 mark 各归各位 ----------
(princ "\n== 3) mark-whole-buffer ==\n")
(with-current-buffer (my-demo-buffer)
  (goto-char 30)
  (let ((inhibit-message t))
    (with-no-warnings (mark-whole-buffer))
    (princ (format "point=%S（在开头），mark=%S（在末尾），use-region-p -> %S\n"
                   (point) (mark) (use-region-p)))
    (princ (format "region 里的字符数 = %S\n"
                   (- (mark) (point))))))

;;; ---------- 4) 验证 append-to-buffer：把 region 追加到另一个缓冲区 ----------
(princ "\n== 4) append-to-buffer ==\n")
(let ((target " *demo-29-target*"))
  (when (get-buffer target) (kill-buffer target))
  (with-temp-buffer
    (insert "alpha beta gamma\n")
    ;; 取前 6 个字符 "alpha " 追加过去
    (append-to-buffer target (point-min) (+ (point-min) 6))
    ;; 再追加一次：因为插入点停在末尾，所以内容会接在后面
    (append-to-buffer target (point-min) (+ (point-min) 5)))
  (princ (format "目标缓冲区内容 = %S\n"
                 (with-current-buffer target (buffer-string))))
  (kill-buffer target))

;;; ---------- 5) 手写一遍 append-to-buffer 的核心动作 ----------
;;; 它搬 region 靠的是三件事：
;;;   get-buffer-create        拿到（必要时新建）目标缓冲区
;;;   with-current-buffer      临时把「当前缓冲区」切到目标上
;;;   insert-buffer-substring  从指定缓冲区取一段文本插进来
(princ "\n== 5) 手写 append-to-buffer 的核心动作 ==\n")
(let ((target " *demo-29-keys*")
      (src " *demo-29-src*"))
  (dolist (b (list target src))
    (when (get-buffer b) (kill-buffer b)))
  (with-current-buffer (get-buffer-create src)
    (insert "papertrail\n"))
  (with-current-buffer (get-buffer-create target)
    (insert "前缀：")
    ;; 从 src 的第 1 到第 6 个字符取出来（即 "paper"）
    (insert-buffer-substring src 1 6))
  (princ (format "结果 = %S\n"
                 (with-current-buffer target (buffer-string))))
  (kill-buffer target)
  (kill-buffer src))

(princ "==== 29 结束 ====\n")
