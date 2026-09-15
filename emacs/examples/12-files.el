;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 12 - 文件与目录：路径、读写、遍历、临时文件
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "12-files.el")'
;;; 运行：emacs -Q --batch -l 12-files.el
;;; ============================================================

;;; 0) 【坑】相对路径是相对 `default-directory` 解析的，而它是**每个 buffer 各一份**
;;;    的 buffer-local 变量 —— 不是进程的 cwd。写扩展时凡是要落盘的路径，
;;;    一律先 expand-file-name，别指望「当前目录」。
(princ (format "default-directory = %S\n" default-directory))

;;; 1) 路径拆分与拼接。file-name-* 家族全是纯字符串运算，不碰磁盘，
;;;    所以既快又安全（文件不存在也能算）。
(defvar demo-path "/tmp/emacs-demo/sub/report.tar.gz")
(princ (format "目录: %S\n" (file-name-directory demo-path)))
(princ (format "文件名: %S\n" (file-name-nondirectory demo-path)))
(princ (format "扩展名: %S，去掉扩展名: %S\n"
               (file-name-extension demo-path)
               (file-name-sans-extension demo-path)))
(princ (format "换扩展名: %S\n" (file-name-with-extension demo-path "zip")))
(princ (format "拼路径: %S\n" (expand-file-name "data.txt" "/tmp/emacs-demo")))
(princ (format "取相对路径: %S\n"
               (file-relative-name "/tmp/emacs-demo/a.txt" "/tmp/emacs-demo")))

;;; 2) 判断文件状态：exists-p / directory-p / regular-file-p / readable-p。
;;;    注意 file-exists-p 对「打不开的符号链接」也会返回 nil。
(princ (format "本文件存在: %S，/tmp 是目录: %S\n"
               (file-exists-p "/tmp") (file-directory-p "/tmp")))

;;; 3) 一次性写文件：with-temp-file。它会新建 buffer，执行 body，
;;;    然后把 buffer 内容写到指定路径。
(defvar demo-dir (make-temp-file "emacs-demo-" t))   ; t = 建目录
(defvar demo-file (expand-file-name "hello.txt" demo-dir))
(with-temp-file demo-file
  (insert "第一行\n")
  (insert (format "写于 Emacs %s\n" emacs-version)))
(princ (format "写入 %S，大小 %S 字节\n" demo-file (file-attribute-size
                                                    (file-attributes demo-file))))

;;; 4) 读文件：insert-file-contents 读进当前 buffer；
;;;    with-temp-buffer + insert-file-contents 是最常见的「读成字符串」写法。
(defvar demo-content
  (with-temp-buffer
    (insert-file-contents demo-file)
    (buffer-string)))
(princ (format "读回内容: %S\n" demo-content))

;;; 5) write-region 更底层，可以从指定位置写到文件；
;;;    【坑】它不会自动创建父目录，目录不存在就直接报错，要自己 make-directory。
(defvar demo-sub (expand-file-name "nested/deep/note.txt" demo-dir))
(make-directory (file-name-directory demo-sub) t)    ; t = 允许建多级
(write-region "嵌套目录里的内容\n" nil demo-sub)
(princ (format "嵌套写入成功: %S\n" (file-exists-p demo-sub)))

;;; 6) 遍历目录。directory-files 返回文件名列表（含 . 和 ..，默认不过滤），
;;;    加 t 返回绝对路径；directory-files-recursively 递归。
(princ (format "目录内容（含 . 和 ..）: %S\n" (directory-files demo-dir)))
(princ (format "只要 .txt（正则 + 不要 . ..）: %S\n"
               (directory-files demo-dir t "\\.txt\\'")))
(princ (format "递归全部文件: %S\n"
               (mapcar #'file-name-nondirectory
                       (directory-files-recursively demo-dir "" t))))

;;; 7) 追加写：write-region 的第五个参数传 t
(write-region "追加的一行\n" nil demo-file 'append)
(princ (format "追加后内容: %S\n"
               (with-temp-buffer (insert-file-contents demo-file) (buffer-string))))

;;; 8) 「访问文件」≠「读文件」。find-file-noselect 返回与该路径关联的 buffer，
;;;    这个 buffer 会被 Emacs 记住 —— 下次再访问同一路径拿到的是同一个 buffer。
;;;    批处理程序要记得 kill 掉，否则会越攒越多。
(let ((buf (find-file-noselect demo-file)))
  (princ (format "buffer 名 = %S，关联文件 = %S，已修改 = %S\n"
                 (buffer-name buf) (buffer-file-name buf) (buffer-modified-p buf)))
  (kill-buffer buf))

;;; 9) 复制、重命名、删除
(copy-file demo-file (expand-file-name "copy.txt" demo-dir))
(rename-file (expand-file-name "copy.txt" demo-dir)
             (expand-file-name "renamed.txt" demo-dir))
(princ (format "重命名后目录: %S\n"
               (directory-files demo-dir nil "\\.txt\\'")))
(delete-file (expand-file-name "renamed.txt" demo-dir))

;;; 10) 清理：示例自己造的临时文件必须自己删干净。
;;;     delete-directory 的第二个参数 t 表示「连内容一起删」。
(delete-directory demo-dir t)
(princ (format "清理后目录还在吗: %S\n" (file-exists-p demo-dir)))

;;; 11) 常用目录变量
(princ (format "temporary-file-directory = %S\n" temporary-file-directory))
(princ (format "user-emacs-directory = %S\n" user-emacs-directory))

(princ "==== 12 结束 ====\n")
