;;;; ============================================================
;;;; 09-file-io.lisp — 文件与流 I/O
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. with-open-file 读写文件
;;;;   2. 读取文件内容（按行、按字符、全部）
;;;;   3. 写入文件
;;;;   4. 二进制文件操作
;;;;   5. 字符串流
;;;;   6. 路径名操作
;;;;   7. 目录操作
;;;;   8. SBCL 特有的文件操作
;;;;
;;;; 运行方式：sbcl --script 09-file-io.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. with-open-file 读写文件
;;; ----------------------------------------------------------

(format t "~%=== 基本文件读写 ===~%")

;; 写入文件
(with-open-file (out "test-output.txt"
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
  (format out "第一行~%")
  (format out "第二行~%")
  (format out "数字: ~A~%" 42)
  (prin1 '(1 2 3) out)
  (terpri out))

(format t "文件已写入~%")

;; 读取文件
(with-open-file (in "test-output.txt" :direction :input)
  (loop for line = (read-line in nil :eof)
        until (eq line :eof)
        do (format t "读取: ~A~%" line)))

;; :if-exists 选项：
;;   :supersede  — 替换现有文件
;;   :append     — 追加到文件末尾
;;   :overwrite  — 覆盖（保留文件大小）
;;   :error      — 报错
;;   :rename     — 重命名旧文件
;;   nil         — 返回 nil

;; :if-does-not-exist 选项：
;;   :create     — 创建新文件
;;   :error      — 报错
;;   nil         — 返回 nil


;;; ----------------------------------------------------------
;;; 2. 读取文件内容
;;; ----------------------------------------------------------

(format t "~%=== 读取文件 ===~%")

;; 按行读取
(defun read-file-lines (filename)
  "读取文件所有行，返回字符串列表。"
  (with-open-file (in filename)
    (loop for line = (read-line in nil :eof)
          until (eq line :eof)
          collect line)))

(format t "所有行: ~A~%" (read-file-lines "test-output.txt"))

;; 读取整个文件为字符串
(defun read-file-string (filename)
  "读取整个文件内容为一个字符串。"
  (with-open-file (in filename)
    (let ((content (make-string (file-length in))))
      (read-sequence content in)
      content)))

(format t "文件内容:~%~A~%" (read-file-string "test-output.txt"))

;; 按字符读取
(with-open-file (in "test-output.txt")
  (loop for ch = (read-char in nil :eof)
        until (eq ch :eof)
        count ch into total
        finally (format t "总字符数: ~A~%" total)))

;; 读取 Lisp 表单
(with-open-file (out "test-forms.lisp"
                     :direction :output
                     :if-exists :supersede)
  (prin1 '(defun hello () (print "world")) out)
  (terpri out)
  (prin1 '(hello) out)
  (terpri out))

(with-open-file (in "test-forms.lisp")
  (loop for form = (read in nil :eof)
        until (eq form :eof)
        do (format t "表单: ~S~%" form)))


;;; ----------------------------------------------------------
;;; 3. 写入文件
;;; ----------------------------------------------------------

(format t "~%=== 写入文件 ===~%")

;; 追加模式
(with-open-file (out "test-output.txt"
                     :direction :output
                     :if-exists :append)
  (format out "追加的一行~%"))

(format t "追加后内容:~%~A~%" (read-file-string "test-output.txt"))

;; 写入 Lisp 数据（可读的）
(let ((data '((:name "张三" :age 30)
              (:name "李四" :age 25))))
  (with-open-file (out "test-data.lisp"
                       :direction :output
                       :if-exists :supersede)
    (with-standard-io-syntax
      (print data out))))

;; 读回 Lisp 数据
(with-open-file (in "test-data.lisp")
  (let ((data (read in)))
    (format t "读回数据: ~A~%" data)))


;;; ----------------------------------------------------------
;;; 4. 二进制文件操作
;;; ----------------------------------------------------------

(format t "~%=== 二进制文件 ===~%")

;; 写入二进制数据
(with-open-file (out "test-binary.bin"
                     :direction :output
                     :element-type '(unsigned-byte 8)
                     :if-exists :supersede)
  (dotimes (i 256)
    (write-byte i out)))

;; 读取二进制数据
(with-open-file (in "test-binary.bin"
                    :element-type '(unsigned-byte 8))
  (let ((bytes (make-array 10 :element-type '(unsigned-byte 8))))
    (read-sequence bytes in)
    (format t "前10字节: ~A~%" bytes)))

;; 读取整个二进制文件
(defun read-binary-file (filename)
  (with-open-file (in filename :element-type '(unsigned-byte 8))
    (let ((data (make-array (file-length in)
                            :element-type '(unsigned-byte 8))))
      (read-sequence data in)
      data)))

(format t "二进制文件大小: ~A 字节~%"
        (length (read-binary-file "test-binary.bin")))


;;; ----------------------------------------------------------
;;; 5. 字符串流
;;; ----------------------------------------------------------

(format t "~%=== 字符串流 ===~%")

;; 输出到字符串
(let ((str (with-output-to-string (s)
             (format s "姓名: ~A~%" "张三")
             (format s "年龄: ~A~%" 30)
             (format s "列表: ~A~%" '(1 2 3)))))
  (format t "字符串流输出:~%~A~%" str))

;; 从字符串读取
(with-input-from-string (in "42 hello (1 2 3)")
  (format t "读取数字: ~A~%" (read in))
  (format t "读取符号: ~A~%" (read in))
  (format t "读取列表: ~A~%" (read in)))

;; make-string-output-stream / get-output-stream-string
(let ((s (make-string-output-stream)))
  (format s "Hello, ")
  (format s "World!")
  (format t "流内容: ~A~%" (get-output-stream-string s)))


;;; ----------------------------------------------------------
;;; 6. 路径名操作
;;; ----------------------------------------------------------

(format t "~%=== 路径名 ===~%")

;; 创建路径名
(let ((p (make-pathname :name "test" :type "txt" :defaults #p"/tmp/")))
  (format t "路径名: ~A~%" p)
  (format t "名称: ~A~%" (pathname-name p))
  (format t "类型: ~A~%" (pathname-type p))
  (format t "目录: ~A~%" (pathname-directory p)))

;; 合并路径
(format t "合并: ~A~%" (merge-pathnames "subdir/file.txt" #p"/home/user/"))

;; 文件名字符串
(format t "namestring: ~A~%" (namestring #p"/tmp/test.txt"))

;; 检查文件是否存在
(format t "文件存在: ~A~%" (probe-file "test-output.txt"))
(format t "文件不存在: ~A~%" (probe-file "nonexistent.txt"))

;; 确保目录存在（SBCL）
(ensure-directories-exist "test-dir/subdir/")
(format t "目录已创建~%")

;; 获取文件信息
(let ((path (probe-file "test-output.txt")))
  (when path
    (format t "文件大小: ~A 字节~%" (file-length (open path)))
    (format t "写入时间: ~A~%" (file-write-date path))
    ;; 将通用时间转为可读格式
    (multiple-value-bind (sec min hour day month year)
        (decode-universal-time (file-write-date path))
      (format t "修改时间: ~A-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D~%"
              year month day hour min sec))))


;;; ----------------------------------------------------------
;;; 7. 目录操作
;;; ----------------------------------------------------------

(format t "~%=== 目录操作 ===~%")

;; 列出目录内容（SBCL 特有）
(format t "当前目录文件:~%")
(dolist (f (directory (merge-pathnames "*.lisp"
                                       (truename "."))))
  (format t "  ~A~%" (file-namestring f)))

;; 创建一些测试文件
(with-open-file (out "test-dir/file1.txt" :direction :output
                     :if-exists :supersede)
  (format out "test1"))
(with-open-file (out "test-dir/file2.txt" :direction :output
                     :if-exists :supersede)
  (format out "test2"))

;; 列出目录
(format t "~%test-dir 内容:~%")
(dolist (f (directory "test-dir/*.*"))
  (format t "  ~A~%" f))

;; 删除文件
(delete-file "test-dir/file1.txt")
(format t "删除 file1.txt 后:~%")
(dolist (f (directory "test-dir/*.*"))
  (format t "  ~A~%" f))

;; 重命名文件
(rename-file "test-dir/file2.txt" "test-dir/renamed.txt")
(format t "重命名后:~%")
(dolist (f (directory "test-dir/*.*"))
  (format t "  ~A~%" f))


;;; ----------------------------------------------------------
;;; 8. SBCL 特有的文件操作
;;; ----------------------------------------------------------

(format t "~%=== SBCL 特有 ===~%")

;; 获取当前工作目录
(format t "当前目录: ~A~%" (sb-ext:posix-getenv "PWD"))
(format t "当前目录(truename): ~A~%" (truename "."))

;; 运行外部程序
;; (sb-ext:run-program "ls" '("-la") :output *standard-output*)

;; 获取环境变量
(format t "PATH 前50字符: ~A...~%"
        (subseq (or (sb-ext:posix-getenv "PATH") "") 0
                (min 50 (length (or (sb-ext:posix-getenv "PATH") "")))))

;; 临时文件
(let* ((tmp-name (format nil "sbcl-test-~D.tmp" (get-universal-time)))
       (tmp-path (merge-pathnames tmp-name (truename "."))))
  (with-open-file (out tmp-path :direction :output :if-exists :supersede)
    (write-line "temporary data" out))
  (format t "临时文件: ~A~%" tmp-path)
  (when (probe-file tmp-path)
    (delete-file tmp-path)))

;; 清理测试文件
(dolist (f '("test-output.txt" "test-forms.lisp" "test-data.lisp"
             "test-binary.bin" "test-dir/renamed.txt"))
  (when (probe-file f)
    (delete-file f)
    (format t "清理: ~A~%" f)))

(format t "~%=== 例程 09 执行完毕 ===~%")
