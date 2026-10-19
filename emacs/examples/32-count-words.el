;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 32 - 词频统计：从 count-words 到一个完整的扩展
;;;   同一个问题（数词）用 迭代 / 递归 / 正则 三种写法解决，
;;;   再把它扩成一个「词频统计」工具
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "32-count-words.el")'
;;; 运行：emacs -Q --batch -l 32-count-words.el
;;; ============================================================
(require 'jka-compr)

;;; ---------- 工具：从符号找到它的源码 ----------
(defun my-source-file (sym)
  "返回 SYM 的定义所在源码文件的路径；找不到返回 nil。"
  (let* ((compiled (or (symbol-file sym 'defvar) (symbol-file sym 'defun)))
         (base (and compiled
                    (if (string-match-p "\\.elc\\'" compiled)
                        (substring compiled 0 -1)
                      compiled))))
    (cond ((null base) nil)
          ((file-exists-p base) base)
          ((file-exists-p (concat base ".gz")) (concat base ".gz"))
          (t nil))))

(defun my-defun-source (sym)
  "抓出 SYM 的定义原文（defun/defmacro/defcustom/defvar 都行）。"
  (let ((file (my-source-file sym)))
    (when file
      (with-temp-buffer
        (let ((jka-compr-verbose nil))
          (insert-file-contents file))
        (goto-char (point-min))
        (when (re-search-forward
               (concat "^(def\\(?:un\\|macro\\|subst\\|custom\\|var\\(?:-local\\)?\\)"
                       "[ \t\n]+" (regexp-quote (symbol-name sym)) "[ \t\n]")
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
    (if src (princ (concat src "\n")) (princ "找不到源码原文\n"))))

;;; ---------- 1) 读源码：Emacs 自己怎么数词 ----------
(princ "== 1) 读源码：count-words 与它的两个帮手 ==\n")
(my-print-source 'count-words)
(my-print-source 'count-words--format)
(my-print-source 'forward-word-strictly)

;;; ---------- 2) 三种算法，同一个答案 ----------
(defconst my-text
  (concat "We hold these truths to be self-evident, that all men are created equal,"
          " that they are endowed by their Creator with certain unalienable Rights,"
          " that among these are Life, Liberty and the pursuit of Happiness.")
  "用来数词的样本文本。")

;; (a) 迭代版：forward-word 一步一个词，配一个计数器。
(defun my-count-iter (start end)
  "数 START 到 END 之间的词数（迭代版）。"
  (let ((words 0))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (while (forward-word 1)
          (setq words (1+ words)))))
    words))

;; (b) 递归版：把「还有词吗」当成循环条件（eintr 第 13 章的写法）。
(defun my-count-recursive (region-end)
  "point 到 REGION-END 之间的词数（递归）。"
  (if (and (< (point) region-end)
           (re-search-forward "\\w+\\W*" region-end t))
      (1+ (my-count-recursive region-end))
    0))

(defun my-count-recur (start end)
  "数 START 到 END 之间的词数（递归版的入口）。"
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (my-count-recursive (point-max)))))

;; (c) 一次性正则：re-search-forward 循环，只遍历不计数中间态。
(defun my-count-regexp (start end)
  "数 START 到 END 之间的词数（正则版）。"
  (let ((n 0))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (while (re-search-forward "\\w+" nil t)
          (setq n (1+ n)))))
    n))

(princ "\n== 2) 三种算法对比 ==\n")
(with-temp-buffer
  (insert my-text)
  (princ (format "文本共 %d 个字符\n" (buffer-size)))
  (princ (format "真实 count-words   = %d\n" (count-words (point-min) (point-max))))
  (princ (format "我的迭代版         = %d\n" (my-count-iter (point-min) (point-max))))
  (princ (format "我的递归版         = %d\n" (my-count-recur (point-min) (point-max))))
  (princ (format "我的一次正则版     = %d\n" (my-count-regexp (point-min) (point-max)))))

;;; ---------- 3) 一整套统计：行、句、词、字符 ----------
(princ "\n== 3) count-words--format：一次报四样 ==\n")
(with-temp-buffer
  (insert my-text)
  (insert "\n第二段。\n")
  (princ (format "%s\n" (count-words--format "Buffer" (point-min) (point-max)))))

;;; ---------- 4) 只数某一个 defun 里的词 ----------
;;; eintr 第 14 章的做法：先界定 defun 的范围，再数里面的词。
(defun my-count-words-in-defun ()
  "数「光标所在 defun」里的词数。"
  (save-excursion
    (let ((start (progn (beginning-of-defun) (point)))
          (end (progn (end-of-defun) (point))))
      (my-count-iter start end))))

(princ "\n== 4) 只数一个 defun 里的词 ==\n")
(with-temp-buffer
  (insert "(defun square (x)\n  \"Return X squared.\"\n  (* x x))\n")
  (goto-char (point-min))
  (princ (format "这个 defun 里有 %d 个词\n" (my-count-words-in-defun))))

;;; ---------- 5) 从计数到词频：哈希表 ----------
(defun my-word-frequency (text)
  "返回 TEXT 里每个词的次数，按次数从多到少排成 alist。"
  (let ((table (make-hash-table :test 'equal)))
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (while (re-search-forward "\\w+" nil t)
        (let ((word (downcase (match-string-no-properties 0))))
          (puthash word (1+ (gethash word table 0)) table))))
    ;; 把哈希表倒出来，再排序
    (let (pairs)
      (maphash (lambda (k v) (push (cons k v) pairs)) table)
      (sort pairs (lambda (a b)
                    (if (= (cdr a) (cdr b))
                        (string< (car a) (car b))   ; 次数相同按字母排，结果稳定
                      (> (cdr a) (cdr b))))))))

(defun my-print-freq (freq &optional limit)
  "打印词频 FREQ，最多打印 LIMIT 行。"
  (let ((n 0))
    (while (and freq (or (null limit) (< n limit)))
      (princ (format "  %-12s %d\n" (caar freq) (cdar freq)))
      (setq freq (cdr freq)
            n (1+ n)))))

(princ "\n== 5) 词频统计（前 6 名）==\n")
(my-print-freq (my-word-frequency my-text) 6)
(princ (format "  不同词数 = %d\n" (length (my-word-frequency my-text))))

;;; ---------- 6) 把它包成一个交互命令 ----------
(defun my-word-frequency-buffer (&optional limit)
  "统计当前缓冲区（或激活的选区）里的词频，打印前 LIMIT 名。
交互调用时，用前缀参数指定要打印多少名。"
  (interactive "P")
  (let* ((limit (or limit 10))
         (freq (if (use-region-p)
                   (my-word-frequency
                    (buffer-substring-no-properties
                     (region-beginning) (region-end)))
                 (my-word-frequency
                  (buffer-substring-no-properties (point-min) (point-max))))))
    (with-temp-buffer
      (insert (format "词频（前 %d 名）：\n" limit))
      (let ((n 0))
        (while (and freq (< n limit))
          (insert (format "%4d  %s\n" (cdar freq) (caar freq)))
          (setq freq (cdr freq) n (1+ n))))
      (message "%s" (buffer-string)))))

(princ "\n== 6) 交互命令也已定义 ==\n")
(princ (format "命令 my-word-frequency-buffer 可用，文档：%s\n"
               (documentation 'my-word-frequency-buffer t)))

(princ "==== 32 结束 ====\n")
