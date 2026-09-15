;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 26 - 实战：从零写一个能用的 mini todo 扩展
;;;   把前面 25 章的东西拼起来：defcustom + 数据模型 + 持久化
;;;   + major mode + keymap + interactive 命令 + font-lock + ERT 测试
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "26-todo-demo.el")'
;;; 运行：emacs -Q --batch -l 26-todo-demo.el
;;; ============================================================

(require 'cl-lib)
(require 'seq)
(require 'ert)

;;; ------------------------------------------------------------
;;; 第 0 步：把命令的 message 转到 stdout
;;; （batch 模式下 message 写 stderr，理由同 13-interactive.el）
;;; ------------------------------------------------------------
(defun demo-call (cmd &rest args)
  "调用命令 CMD，把它内部 message 的输出转到 stdout。"
  (cl-letf (((symbol-function 'message)
             (lambda (fmt &rest xs)
               (princ "    -> ")
               (princ (apply #'format fmt xs))
               (terpri)
               nil)))
    (apply cmd args)))

;;; ------------------------------------------------------------
;;; 第 1 步：配置（defgroup + defcustom）
;;; ------------------------------------------------------------
(defgroup demo-todo nil
  "mini todo 扩展的配置。"
  :group 'emacs
  :prefix "demo-todo-")

(defcustom demo-todo-file
  (expand-file-name "demo-todo.eld" temporary-file-directory)
  "待办数据的保存位置。"
  :type 'file
  :group 'demo-todo)

(defcustom demo-todo-archive-done nil
  "刷新时是否把已完成的条目移到列表末尾。"
  :type 'boolean
  :group 'demo-todo)

;;; ------------------------------------------------------------
;;; 第 2 步：数据模型
;;; 用 plist 表示一条待办：(:title "..." :done nil :created <float>)
;;; ------------------------------------------------------------
(defun demo-todo-make (title)
  "造一条标题为 TITLE 的待办。"
  (list :title title :done nil :created (float-time)))

(defun demo-todo-title (item) "取标题。" (plist-get item :title))
(defun demo-todo-done-p (item) "是否已完成。" (plist-get item :done))

(defun demo-todo-set-done (item done)
  "设置 ITEM 的完成状态，返回**新的** item。

【坑】plist-put 是破坏性的，但「修改第一个 key」时它可能返回一个
新的 list，所以必须接住返回值，不能指望原对象被就地改好。"
  (plist-put item :done done))

(defvar demo-todo-items nil
  "当前内存里的待办列表。")

;;; ------------------------------------------------------------
;;; 第 3 步：增删改查
;;; ------------------------------------------------------------
(defun demo-todo-add (title)
  "添加一条标题为 TITLE 的待办。"
  (interactive "s待办内容: ")
  (push (demo-todo-make title) demo-todo-items)
  (message "已添加：%s" title)
  title)

(defun demo-todo-count ()
  "返回待办总数。"
  (length demo-todo-items))

(defun demo-todo-pending-count ()
  "返回未完成的待办数。"
  (seq-count (lambda (it) (not (demo-todo-done-p it))) demo-todo-items))

(defun demo-todo-toggle-at (index)
  "切换第 INDEX 条（0 起）的完成状态。"
  (let ((item (nth index demo-todo-items)))
    (unless item
      (user-error "没有第 %d 条待办" (1+ index)))
    ;; 【坑】改完要写回列表，plist-put 的返回值必须接住
    (setf (nth index demo-todo-items)
          (demo-todo-set-done item (not (demo-todo-done-p item))))
    (message "%s：%s"
             (if (demo-todo-done-p (nth index demo-todo-items)) "完成" "重新打开")
             (demo-todo-title item))))

(defun demo-todo-delete-at (index)
  "删除第 INDEX 条待办。"
  (let ((item (nth index demo-todo-items)))
    (unless item
      (user-error "没有第 %d 条待办" (1+ index)))
    (setq demo-todo-items (append (seq-take demo-todo-items index)
                                  (seq-drop demo-todo-items (1+ index))))
    (message "已删除：%s" (demo-todo-title item))))

(defun demo-todo-clear-done ()
  "清掉所有已完成的条目，返回清掉的数量。"
  (interactive)
  (let ((before (length demo-todo-items)))
    (setq demo-todo-items
          (seq-remove #'demo-todo-done-p demo-todo-items))
    (let ((removed (- before (length demo-todo-items))))
      (message "清掉了 %d 条已完成" removed)
      removed)))

;;; ------------------------------------------------------------
;;; 第 4 步：持久化
;;; 用 prin1 写、read 读，比手写解析省事得多。
;;; ------------------------------------------------------------
(defun demo-todo-save ()
  "把待办写到 demo-todo-file，返回写入的条数。"
  (interactive)
  (with-temp-file demo-todo-file
    ;; 【坑】prin1 默认会受 print-length / print-level 限制，
    ;; 长列表会被截断成 "..." —— 写文件前必须把它们关掉。
    (let ((print-length nil)
          (print-level nil))
      (prin1 demo-todo-items (current-buffer))))
  (message "已保存 %d 条到 %s" (length demo-todo-items)
           (file-name-nondirectory demo-todo-file))
  (length demo-todo-items))

(defun demo-todo-load ()
  "从 demo-todo-file 读回待办，返回读到的条数。"
  (interactive)
  (setq demo-todo-items
        (if (file-exists-p demo-todo-file)
            (with-temp-buffer
              (insert-file-contents demo-todo-file)
              (goto-char (point-min))
              ;; 【安全】read 只解析数据结构、不执行代码，
              ;; 但读进来的东西仍然应当校验（这里只简单检查是不是 list）。
              (let ((data (read (current-buffer))))
                (if (listp data) data nil)))
          nil))
  (message "已读取 %d 条" (length demo-todo-items))
  (length demo-todo-items))

;;; ------------------------------------------------------------
;;; 第 5 步：major mode —— 待办列表的展示界面
;;; parent 用 special-mode：自带只读、q 退出、g 刷新等一大堆便利。
;;; ------------------------------------------------------------
(defvar demo-todo-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "a") #'demo-todo-add)
    (define-key map (kbd "RET") #'demo-todo-toggle-at-point)
    (define-key map (kbd "SPC") #'demo-todo-toggle-at-point)
    (define-key map (kbd "d") #'demo-todo-delete-at-point)
    (define-key map (kbd "g") #'demo-todo-refresh)
    map)
  "demo-todo-mode 的按键表。")

(defvar demo-todo-font-lock-keywords
  '(("^\\[x\\] \\(.*\\)$" 1 'font-lock-comment-face)   ; 已完成 -> 灰掉
    ("^\\[ \\] \\(.*\\)$" 1 'font-lock-string-face))   ; 未完成 -> 正常高亮
  "demo-todo-mode 的高亮规则。")

(define-derived-mode demo-todo-mode special-mode "Demo-Todo"
  "待办列表的主模式。"
  ;; 【坑】special-mode 不会自动打开 font-lock，要自己开。
  ;; （很多 mode 的 parent 是 text-mode / prog-mode，那边是自动开的）
  (setq font-lock-defaults '(demo-todo-font-lock-keywords t))
  (font-lock-mode 1)
  (setq-local revert-buffer-function (lambda (_ignore-auto _noconfirm)
                                       (demo-todo-refresh))))

(defun demo-todo--index-at-point ()
  "返回光标所在行的待办下标，不在待办行上则返回 nil。"
  (get-text-property (line-beginning-position) 'demo-todo-index))

(defun demo-todo-render ()
  "把 demo-todo-items 渲染进当前 buffer。"
  (let ((inhibit-read-only t))        ; special-mode 的 buffer 是只读的
    (erase-buffer)
    (if (null demo-todo-items)
        (insert "（还没有待办，按 a 添加）\n")
      (seq-do-indexed
       (lambda (item idx)
         ;; 【技巧】把下标存成文本属性，比「数行号」稳健得多：
         ;; 加个表头、排个序都不会错位。
         (insert (propertize
                  (format "[%s] %s\n"
                          (if (demo-todo-done-p item) "x" " ")
                          (demo-todo-title item))
                  'demo-todo-index idx)))
       demo-todo-items))
    (goto-char (point-min)))
  (font-lock-ensure))

(defun demo-todo-refresh ()
  "重画待办列表。"
  (interactive)
  (when demo-todo-archive-done
    (setq demo-todo-items
          (append (seq-remove #'demo-todo-done-p demo-todo-items)
                  (seq-filter #'demo-todo-done-p demo-todo-items))))
  (demo-todo-render)
  (message "共 %d 条，未完成 %d 条"
           (demo-todo-count) (demo-todo-pending-count)))

(defun demo-todo-toggle-at-point ()
  "切换光标所在行的完成状态。"
  (interactive)
  (let ((idx (demo-todo--index-at-point)))
    (unless idx
      (user-error "光标不在待办行上"))
    (demo-todo-toggle-at idx)
    (demo-todo-refresh)
    (forward-line 0)))

(defun demo-todo-delete-at-point ()
  "删除光标所在行的待办。"
  (interactive)
  (let ((idx (demo-todo--index-at-point)))
    (unless idx
      (user-error "光标不在待办行上"))
    (demo-todo-delete-at idx)
    (demo-todo-refresh)))

;;; M-x demo-todo 是入口；它复用同一个 buffer，反复调用不会越开越多。
(defun demo-todo ()
  "打开待办列表。"
  (interactive)
  (demo-todo-load)
  (let ((buf (get-buffer-create "*Demo Todo*")))
    (pop-to-buffer buf)
    (unless (derived-mode-p 'demo-todo-mode)
      (demo-todo-mode))
    (demo-todo-refresh)))

;;; ------------------------------------------------------------
;;; 第 6 步：在 batch 里跑一遍完整流程
;;; ------------------------------------------------------------
(princ "=== 完整流程演示 ===\n")

;;; 用一个临时文件，别污染用户目录。
;;; demo-todo-file 是 defcustom（special 变量），let 能临时改写它。
(defvar demo-todo-temp-file (make-temp-file "demo-todo-" nil ".eld"))

(let ((demo-todo-file demo-todo-temp-file))
  (setq demo-todo-items nil)

  (princ "1) 添加三条待办：\n")
  (demo-call #'demo-todo-add "写 Emacs 教程")
  (demo-call #'demo-todo-add "买咖啡")
  (demo-call #'demo-todo-add "回复邮件")
  (princ (format "   总数 = %S，未完成 = %S\n"
                 (demo-todo-count) (demo-todo-pending-count)))

  (princ "2) 把第 2 条（买咖啡）标记完成：\n")
  (demo-call #'demo-todo-toggle-at 1)
  (princ (format "   未完成 = %S\n" (demo-todo-pending-count)))

  (princ "3) 存盘后清空内存，再读回来：\n")
  (demo-call #'demo-todo-save)
  (setq demo-todo-items nil)
  (princ (format "   清空后总数 = %S\n" (demo-todo-count)))
  (demo-call #'demo-todo-load)
  (princ (format "   读回后总数 = %S，未完成 = %S\n"
                 (demo-todo-count) (demo-todo-pending-count)))
  (princ (format "   标题顺序 = %S\n"
                 (mapcar #'demo-todo-title demo-todo-items)))

  (princ "4) 渲染成 buffer 并检查高亮：\n")
  (with-temp-buffer
    (demo-todo-mode)
    (demo-todo-render)
    (princ "   buffer 内容:\n")
    (princ (buffer-string))
    ;; face 加在**标题**上（正则的第 1 组），不是行首，
    ;; 所以要跳到第 5 列（"[ ] " 是 4 个字符）去取。
    (goto-char (point-min))
    (princ (format "   第 1 行（未完成的回复邮件）标题的 face = %S\n"
                   (get-text-property (+ (line-beginning-position) 4) 'face)))
    (forward-line 1)
    (princ (format "   第 2 行（已完成的买咖啡）标题的 face = %S\n"
                   (get-text-property (+ (line-beginning-position) 4) 'face)))
    (princ (format "   第 2 行的下标属性 = %S\n" (demo-todo--index-at-point))))

  (princ "5) 在列表 buffer 里用键盘命令操作：\n")
  (with-temp-buffer
    (demo-todo-mode)
    (demo-todo-render)
    (goto-char (point-min))
    (forward-line 2)                        ; 跳到第 3 行「写 Emacs 教程」
    (demo-call #'demo-todo-toggle-at-point) ; 标记完成
    (princ (format "   切换后未完成 = %S\n" (demo-todo-pending-count)))
    (goto-char (point-min))                 ; 回到第 1 行「回复邮件」
    (demo-call #'demo-todo-delete-at-point) ; 删掉它
    (princ (format "   删除后总数 = %S，剩下的 = %S\n"
                   (demo-todo-count)
                   (mapcar #'demo-todo-title demo-todo-items))))

  (princ "6) 清理已完成：\n")
  (demo-call #'demo-todo-clear-done)
  (princ (format "   清理后总数 = %S\n" (demo-todo-count))))

;;; ------------------------------------------------------------
;;; 第 7 步：单元测试（静默运行，理由见 25-tests.el）
;;; ------------------------------------------------------------
(ert-deftest demo-todo-test-add-and-count ()
  (let ((demo-todo-items nil))
    (demo-todo-add "a")
    (demo-todo-add "b")
    (should (= 2 (demo-todo-count)))
    (should (= 2 (demo-todo-pending-count)))))

(ert-deftest demo-todo-test-toggle ()
  (let ((demo-todo-items (list (demo-todo-make "x"))))
    (should-not (demo-todo-done-p (nth 0 demo-todo-items)))
    (demo-todo-toggle-at 0)
    ;; 【坑】这里必须重新 nth 一次去取 —— plist-put 返回的是新对象
    (should (demo-todo-done-p (nth 0 demo-todo-items)))
    (should (= 0 (demo-todo-pending-count)))))

(ert-deftest demo-todo-test-delete ()
  (let ((demo-todo-items (list (demo-todo-make "a")
                               (demo-todo-make "b"))))
    (demo-todo-delete-at 0)
    (should (= 1 (demo-todo-count)))
    (should (equal "b" (demo-todo-title (nth 0 demo-todo-items))))))

(ert-deftest demo-todo-test-save-load-roundtrip ()
  (let ((demo-todo-file (make-temp-file "demo-todo-test-" nil ".eld"))
        (demo-todo-items (list (demo-todo-make "持久化测试"))))
    (unwind-protect
        (progn
          (demo-todo-save)
          (setq demo-todo-items nil)
          (demo-todo-load)
          (should (= 1 (demo-todo-count)))
          (should (equal "持久化测试" (demo-todo-title (nth 0 demo-todo-items)))))
      (when (file-exists-p demo-todo-file)
        (delete-file demo-todo-file)))))

;;; 【坑】测试用例是**直接**调用函数的，不走 demo-call，
;;;    所以函数里的 message 会漏到 stderr。跑测试时要把 message 静音。
(let* ((stats (cl-letf (((symbol-function 'message) (lambda (&rest _args) nil)))
                (ert-run-tests "demo-todo-test" (lambda (&rest _args) nil))))
       (total (ert-stats-total stats))
       (bad (ert-stats-completed-unexpected stats)))
  (princ (format "7) 单元测试：共 %S 个用例，失败 %S 个\n" total bad)))

;;; ------------------------------------------------------------
;;; 第 8 步：这个扩展还差什么（真实发布的清单）
;;;   - 文件头：;;; demo-todo.el --- 一句话简介 -*- lexical-binding: t; -*-
;;;   - 结尾：(provide 'demo-todo) 和 ;;; demo-todo.el ends here
;;;   - M-x checkdoc：逐条检查 docstring 和文件头
;;;   - M-x package-lint：检查命名、依赖、autoload cookie
;;;   - 一个 README 和一份 NEWS
;;;   - 版本号 + Package-Requires: ((emacs "29.1"))
;;; ------------------------------------------------------------

(delete-file demo-todo-temp-file)
(princ (format "8) 临时数据文件已清理: %S\n"
               (not (file-exists-p demo-todo-temp-file))))

(princ "==== 26 结束 ====\n")
