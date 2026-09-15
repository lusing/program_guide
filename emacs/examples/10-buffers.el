;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 10 - 缓冲区：point、插入删除、save-excursion、narrowing
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "10-buffers.el")'
;;; 运行：emacs -Q --batch -l 10-buffers.el
;;; ============================================================

;;; 1) buffer 是 Emacs 的一等公民：文本并不「在文件里」，而是在 buffer 里，
;;;    文件只是 buffer 的保存目标。任何文本操作都先切到目标 buffer。
(princ (format "当前 buffer: %S，所有 buffer 数: %S\n"
               (buffer-name) (length (buffer-list))))

;;; 2) with-temp-buffer：造一个用完即焚的临时 buffer，扩展里最常用。
;;;    它内部把该 buffer 设为当前 buffer，退出时自动 kill。
(with-temp-buffer
  (insert "第一行\n第二行\n第三行\n")
  (princ (format "bufname=%S 内容=%S\n" (buffer-name) (buffer-string))))

;;; 3) point（光标位置）= 一个 1 开始的整数位置。
;;;    point-min / point-max 给出可视范围（narrowing 后会变）。
(with-temp-buffer
  (insert "abcdef")
  (princ (format "插入后 point = %S（停在新文本之后）\n" (point)))
  (goto-char (point-min))
  (princ (format "point-min = %S, point-max = %S, bobp = %S\n"
                 (point) (point-max) (bobp)))
  (goto-char (point-max))
  (princ (format "到末尾: point = %S, eobp = %S\n" (point) (eobp))))

;;; 4) 移动：goto-char 绝对位置，forward-char / forward-line 相对移动。
;;;    移动函数越界时通常会报错（forward-char）或返回 nil（forward-line 到文件尾）。
(with-temp-buffer
  (insert "aaa\nbbb\nccc")
  (goto-char (point-min))
  (forward-line 1)
  (princ (format "下移一行后 point = %S，当前行 = %S\n"
                 (point) (buffer-substring-no-properties
                          (line-beginning-position) (line-end-position)))))

;;; 5) 取内容：buffer-string 拿全部，buffer-substring 拿区间。
;;;    【坑】一定要用 -no-properties 版本。带文本属性的字符串在 equal 比较、
;;;    写入文件、插到别处时行为都和你想的不一样（见 11-text-properties.el）。
(with-temp-buffer
  (insert "hello world")
  (princ (format "buffer-substring 1..6 = %S\n"
                 (buffer-substring-no-properties 1 6))))

;;; 6) 查找替换：re-search-forward 把 point 移到匹配末尾，replace-match 替换
;;;    **刚刚那次匹配**的内容（同样依赖全局 match data）。
(with-temp-buffer
  (insert "keep-THIS-keep")
  (goto-char (point-min))
  (re-search-forward "THIS")
  (replace-match "that")
  (princ (format "replace-match 后: %S\n" (buffer-string))))

;;; 【坑】buffer 可能是只读的（dired、*Messages*、grep 结果都是）。
;;;    直接 insert 会报 buffer-read-only。标准做法是 let-bind
;;;    inhibit-read-only 为 t —— 这是「动态变量临时改写行为」的经典用法。
(with-temp-buffer
  (insert "readonly-content")
  (setq buffer-read-only t)
  (let ((inhibit-read-only t))
    (goto-char (point-max))
    (insert " + forced"))
  (princ (format "只读 buffer 里强制插入: %S\n" (buffer-string))))

;;; 7) 【核心】save-excursion：包裹起来的移动和 narrowing 在退出时自动还原。
;;;    写扩展时凡是「临时挪光标去看一眼」的地方都必须包它，否则用户的光标会跳。
(with-temp-buffer
  (insert "one two three")
  (goto-char 5)
  (save-excursion
    (goto-char (point-min))
    (insert ">> "))
  (princ (format "save-excursion 之后 point 还原到 %S，内容=%S\n"
                 (point) (buffer-string))))

;;; 8) narrowing：把 buffer 逻辑上「裁」成一段，之后 point-min/max 只看到这段。
;;;    配合 save-restriction 使用，退出时还原。很多 mode 用这招做「只处理当前函数」。
(with-temp-buffer
  (insert "A1\nA2\nB1\nB2\n")
  (goto-char (point-min))
  (save-excursion
    (save-restriction
      (search-forward "B1")
      (beginning-of-line)
      (narrow-to-region (point) (point-max))
      (princ (format "narrow 之后 point-min=%S point-max=%S 只看到=%S\n"
                     (point-min) (point-max) (buffer-string)))))
  (princ (format "还原之后又能看全: %S\n" (buffer-string))))

;;; 9) 在「另一个」buffer 里干活：with-current-buffer。
;;;    注意它**不**切换用户看到的窗口，只是把当前 buffer 临时换掉。
(let ((b (generate-new-buffer "demo-work")))
  (with-current-buffer b
    (insert "工作在别的 buffer")
    (princ (format "名字=%S 内容=%S\n" (buffer-name) (buffer-string))))
  (princ (format "回到主 buffer: %S，它还在吗: %S\n"
                 (buffer-name) (buffer-live-p b)))
  (kill-buffer b))

;;; 10) 按名字找 buffer：get-buffer 找不到返回 nil，get-buffer-create 会新建。
;;;    命名习惯：临时 buffer 用 *星号* 包起来，避免和用户文件重名。
(let ((b (get-buffer-create "*demo-scratch*")))
  (princ (format "新建 buffer: %S，再取一次同一个对象: %S\n"
                 (buffer-name b) (eq b (get-buffer-create "*demo-scratch*"))))
  (kill-buffer b))

;;; 11) 搜索：re-search-forward / re-search-backward / looking-at
(with-temp-buffer
  (insert "id=42 name=bob")
  (goto-char (point-min))
  (when (re-search-forward "id=\\([0-9]+\\)" nil t)
    (princ (format "re-search-forward 找到 id=%S，point 现在在 %S\n"
                   (match-string-no-properties 1) (point))))
  (goto-char (point-min))
  (princ (format "looking-at 从当前位置匹配: %S\n"
                 (looking-at "id=[0-9]+"))))

(princ "==== 10 结束 ====\n")
