;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 31 - 正则驱动的文本推进：forward-sentence 与 forward-paragraph
;;;   用正则把「句子」「段落」这类自然语言结构翻译成可计算的边界
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "31-forward-sentence.el")'
;;; 运行：emacs -Q --batch -l 31-forward-sentence.el
;;; ============================================================
(require 'jka-compr)

;;; ---------- 工具：从一个符号找到它的源码（函数或变量） ----------
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

;;; ---------- 工具：把字符串里的控制字符变成可见的转义写法 ----------
;;; 正则里常常含有 TAB、换行这样的字符，直接打印会破坏版面。
(defun my-visible (s)
  "把字符串 S 里的控制字符和「看不见的空格」换成可见的转义写法。
TAB、换行这类控制字符会破坏版面，不换行空格（NBSP）在终端里和普通空格
长得一模一样，两者都要转义之后才看得出来。"
  (let ((out ""))
    (dolist (ch (string-to-list s))
      (setq out
            (concat out
                    (cond ((= ch ?\t) "\\t")
                          ((= ch ?\n) "\\n")
                          ((= ch ?\f) "\\f")
                          ((= ch ?\r) "\\r")
                          ((= ch ?\\) "\\\\")
                          ((= ch ?\") "\\\"")
                          ;; 不换行空格：Emacs 31 的 (sentence-end) 认它当空格
                          ((= ch ?\u00a0) "\\u00a0")
                          ((< ch 32) (format "\\x%02x" ch))
                          (t (char-to-string ch))))))
    out))

;;; ---------- 1) 读源码 ----------
(princ "== 1) 读源码：句子与段落的推进函数 ==\n")
(my-print-source 'forward-sentence)
(my-print-source 'forward-sentence-default-function)
(my-print-source 'sentence-end-base)
(my-print-source 'paragraph-start)
(my-print-source 'paragraph-separate)
(my-print-source 'forward-paragraph)
(my-print-source 'start-of-paragraph-text)
(my-print-source 'end-of-paragraph-text)

;;; ---------- 2) 句子边界就是一个正则 ----------
(princ "\n== 2) sentence-end 是算出来的正则 ==\n")
(princ (format "sentence-end 变量（没设过，所以是 nil） = %S\n" sentence-end))
(princ (format "调用 (sentence-end) 算出来的正则：\n  \"%s\"\n"
               (my-visible (sentence-end))))

(defun my-collect-forward (fn text)
  "在 TEXT 里用 FN 一步步往前走，返回每次停下时覆盖的片段列表。
FN 走不动或报错（例如已到最后一个句尾）就停下。"
  (let ((acc nil))
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (let ((start (point))
            (guard 0)
            (done nil))
        (while (and (not done) (< (point) (point-max)))
          (setq guard (1+ guard))
          (let ((before (point)))
            (condition-case nil
                (funcall fn 1)
              (error (setq done t)))
            (if (= (point) before)
                (setq done t)            ; 走不动了，退出
              (push (buffer-substring-no-properties start (point)) acc)
              (setq start (point))))
          (when (> guard 100) (setq done t)))   ; 防挂死的安全阀
        ;; 收尾：把剩下的文本作为最后一段
        (when (< start (point-max))
          (push (buffer-substring-no-properties start (point-max)) acc)))
      (nreverse acc))))

(princ "\n== 3) sentence-end-double-space：句尾要不要留两个空格 ==\n")
;; 在 -Q --batch 下这个变量默认是 t：句号后面必须跟「两个」空格才算一个句尾，
;; 所以 "One sentence. Two" 这样只留一个空格的写法不会被切开。
(princ (format "默认值 = %S\n" sentence-end-double-space))
(let ((text "One sentence. Two sentences! Three? Four.\n"))
  (dolist (flag '(t nil))
    (let ((sentence-end-double-space flag))
      (princ (format "sentence-end-double-space = %S：\n" flag))
      (dolist (piece (my-collect-forward #'forward-sentence text))
        (princ (format "  [\"%s\"]\n" (my-visible piece)))))))

;;; ---------- 4) 换一个 sentence-end：让「END」当句号 ----------
(princ "\n== 4) 自定义 sentence-end ==\n")
(let ((sentence-end "END[ \t\n]*")
      (text "第一句END第二句END第三句"))
  (princ (format "sentence-end 设为 \"%s\"\n" (my-visible sentence-end)))
  (dolist (piece (my-collect-forward #'forward-sentence text))
    (princ (format "  [\"%s\"]\n" (my-visible piece)))))

;;; ---------- 5) 段落：paragraph-start / paragraph-separate ----------
(princ "\n== 5) 用 forward-paragraph 走一遍 ==\n")
(defun my-walk-paragraphs (text)
  "从开头逐段前进，打印每次停下的行号和位置。"
  (with-temp-buffer
    (insert text)
    (goto-char (point-min))
    (princ (format "  起点：第 %S 行（point=%S）\n"
                   (line-number-at-pos) (point)))
    (let ((guard 0))
      (while (and (< (point) (point-max)) (< guard 100))
        (setq guard (1+ guard))
        (forward-paragraph 1)
        (princ (format "  前进后：第 %S 行（point=%S）\n"
                       (line-number-at-pos) (point)))))
    (princ (format "  收尾：第 %S 行（point-max=%S）\n"
                   (line-number-at-pos) (point-max)))))

(my-walk-paragraphs
 "Para one line one.\nPara one line two.\n\nPara two.\n\n\nPara three.\n")

;;; ---------- 6) 改 paragraph-start：把 * 开头的行当作段首 ----------
(princ "\n== 6) 自定义 paragraph-start ==\n")
(let ((paragraph-start "^\\*"))
  (princ (format "paragraph-start 设为 %S（forward-paragraph 会去掉开头的 ^）\n"
                 paragraph-start))
  (my-walk-paragraphs "* 标题一\n正文一。\n* 标题二\n正文二。\n"))

;;; ---------- 7) 两个配套函数 ----------
(princ "\n== 7) 段落的起点与终点 ==\n")
(with-temp-buffer
  (insert "Para one.\n\nPara two line one.\nPara two line two.\n\nPara three.\n")
  (goto-char (point-min))
  (forward-paragraph 1)                 ; 先走到第二段
  (end-of-paragraph-text)
  (princ (format "走到第二段末尾：point=%S，前面那个字符是 %S\n"
                 (point) (char-to-string (char-before))))
  (start-of-paragraph-text)
  (princ (format "回到第二段开头：point=%S，接下来是 %S\n"
                 (point) (buffer-substring-no-properties
                          (point) (min (+ (point) 8) (point-max))))))

(princ "==== 31 结束 ====\n")
