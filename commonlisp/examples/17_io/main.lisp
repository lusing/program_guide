;;;; ============================================================
;;;; examples/17_io/main.lisp — 流与文件 I/O
;;;; channel: both
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. with-open-file：读写与 :if-exists/:if-does-not-exist 全选项
;;;;   2. 三种读法：按行 / 按字符 / 按 S 表达式（read）
;;;;   3. 整文件读入：file-length 是**字节数**不是字符数（中文大坑）
;;;;   4. 二进制 I/O：:element-type '(unsigned-byte 8)
;;;;   5. 字符串流：with-output-to-string / with-input-from-string
;;;;   6. 路径名：pathname 家族与 merge-pathnames
;;;;   7. 目录操作：ensure-directories-exist / directory / rename-file 的坑
;;;;
;;;; 说明：本示例在 build/17_io.<通道>/ 下运行（验证脚本已切好工作目录），
;;;; 相对路径的读写都落在这里；示例自产自清，不留垃圾文件。
;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. with-open-file 基本读写
;;; ----------------------------------------------------------

(with-open-file (out "note.txt"
                     :direction :output
                     :if-exists :supersede   ; 已存在则替换
                     :if-does-not-exist :create)
  (format out "第一行：Common Lisp~%")
  (format out "第二行：中文与数字 ~D~%" 42)
  (prin1 '(1 2 3) out)                       ; 可读输出：写表
  (terpri out))

;; :if-exists 还有 :append / :overwrite / :error / nil 四种，
;; :if-does-not-exist 还有 :error / nil 两种——按需查表

(format t "已写入 note.txt~%")

;; 按行读
(with-open-file (in "note.txt")
  (loop for line = (read-line in nil :eof)
        until (eq line :eof)
        do (format t "  读到: ~A~%" line)))


;;; ----------------------------------------------------------
;;; 2. 按 S 表达式读
;;; ----------------------------------------------------------

;; read 是 Lisp 的「原生解析器」：把文本读回成数据
(with-open-file (in "note.txt")
  ;; 前两行不是合法表单，逐行跳过到最后一行再 read
  (read-line in nil)
  (read-line in nil)
  (format t "read 读回表单: ~S~%" (read in)))

;; read-from-string 同理（字符串版）；第二返回值告诉你读到哪儿停了。
;; 坑：这个「停在哪」的索引两实现差 1（SBCL 指向未读的首字符，
;; CLISP 指向已读的末字符）——别拿它做逻辑，跨实现仅供调试参考
(multiple-value-bind (form pos) (read-from-string "(a b) 剩下的")
  (declare (ignore pos))
  (format t "read-from-string 读到表单: ~S~%" form))


;;; ----------------------------------------------------------
;;; 3. 整文件读入：字节数 ≠ 字符数
;;; ----------------------------------------------------------

;; 大坑：file-length 返回**字节数**（UTF-8 的中文一个字 3 字节），
;; make-string 要的是**字符数**——直接拿去分配会过大，多余位置
;; 在 SBCL 上是 #\Nul，一打印就把 0 字节漏进输出流。
;; 正确姿势：接住 read-sequence 的返回值（实际填充长度）再截断
(defun read-file-string (filename)
  (with-open-file (in filename)
    (let* ((buf (make-string (file-length in)))
           (filled (read-sequence buf in)))
      (subseq buf 0 filled))))

(let ((text (read-file-string "note.txt")))
  (format t "整文件字符数: ~A（字节数更多，因为有中文）~%" (length text)))


;;; ----------------------------------------------------------
;;; 4. 二进制 I/O
;;; ----------------------------------------------------------

(with-open-file (out "data.bin"
                     :direction :output
                     :element-type '(unsigned-byte 8)  ; 字节流模式
                     :if-exists :supersede)
  (write-byte 16 out)
  (write-byte 32 out)
  (write-sequence #(1 2 3 4) out))

(with-open-file (in "data.bin" :element-type '(unsigned-byte 8))
  (let ((buf (make-array 6 :element-type '(unsigned-byte 8))))
    (let ((n (read-sequence buf in)))
      (format t "二进制 ~A 字节: ~S~%" n buf))
    (format t "file-position 重读第 0 字节: ~A~%"
            (progn (file-position in 0) (read-byte in)))))


;;; ----------------------------------------------------------
;;; 5. 字符串流
;;; ----------------------------------------------------------

;; 输出到字符串（拼串的正规军，比反复 concatenate 高效）
(let ((s (with-output-to-string (out)
           (format out "姓名:~A " "李雷")
           (format out "分数:~,1F" 92.5))))
  (format t "字符串流: ~S~%" s))

;; 从字符串读（配合 read 做「迷你解析器」很顺手）
(with-input-from-string (in "42 hello (1 2 3)")
  (format t "依次读: ~S ~S ~S~%" (read in) (read in) (read in)))


;;; ----------------------------------------------------------
;;; 6. 路径名
;;; ----------------------------------------------------------

;; 路径名对象 = 目录 + 名字 + 类型 + 版本，各取各的
(let ((p (make-pathname :name "report" :type "txt")))
  (format t "名字 ~S 类型 ~S 目录 ~S~%"
          (pathname-name p) (pathname-type p) (pathname-directory p)))

;; merge-pathnames：把「相对部分」合并到「默认基座」上
(let ((base (make-pathname :name nil :type nil :defaults "data/")))
  (format t "合并: ~S~%" (merge-pathnames "a.txt" base)))

;; namestring / file-namestring：路径对象 ↔ 字符串
(format t "file-namestring: ~S~%" (file-namestring #P"dir/sub/x.lisp"))
(format t "namestring:      ~S~%" (namestring #P"dir/sub/x.lisp"))

;; probe-file：存在则给真值（返回 truename），不存在给 NIL
;; 注意：返回的绝对路径随机器/目录变化，别打印它本身
(format t "note.txt 存在: ~A，幽灵文件存在: ~A~%"
          (not (null (probe-file "note.txt")))
          (not (null (probe-file "ghost.txt"))))


;;; ----------------------------------------------------------
;;; 7. 目录操作
;;; ----------------------------------------------------------

;; 建目录（递归）；返回两值：路径 + 是否新建
(multiple-value-bind (path created)
    (ensure-directories-exist "work/sub/")
  (declare (ignore path))
  (format t "目录新建: ~A~%" created))

(with-open-file (out "work/b.txt" :direction :output :if-exists :supersede)
  (format out "b"))
(with-open-file (out "work/a.txt" :direction :output :if-exists :supersede)
  (format out "a"))

;; directory 的通配在「是否匹配子目录」上两实现不同（SBCL 把
;; work/sub/ 也算进 *.* 的匹配、file-namestring 得 ""；CLISP 不算），
;; 所以要过滤掉没有名字成分的目录项。返回顺序也未规定——必须排序
(let ((files (sort (remove-if-not #'pathname-name (directory "work/*.*"))
                   #'string<
                   :key #'file-namestring)))
  (format t "排序后的目录: ~S~%" (mapcar #'file-namestring files)))

;; rename-file 大坑：第二个参数是「目标的默认路径成分」，不是完整目标！
;; 传带目录的相对路径会被再拼一次目录 → couldn't rename。
;; 正确姿势：纯文件名（沿用源目录），或与 truename 目录合并
(rename-file "work/b.txt"
             (merge-pathnames "renamed.txt" (truename "work/")))
(let ((files (sort (remove-if-not #'pathname-name (directory "work/*.*"))
                   #'string<
                   :key #'file-namestring)))
  (format t "重命名后: ~S~%" (mapcar #'file-namestring files)))

;; 清理自己产出的文件（目录本身留给实现：ANSI 没有可移植的删目录）
(dolist (f '("note.txt" "data.bin" "work/a.txt" "work/renamed.txt"))
  (when (probe-file f) (delete-file f)))
(format t "清理完成，note.txt 还在吗: ~A~%"
        (not (null (probe-file "note.txt"))))


(format t "==== 17 结束 ====~%")
