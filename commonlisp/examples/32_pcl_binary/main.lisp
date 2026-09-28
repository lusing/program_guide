;;;; ============================================================
;;;; examples/32_pcl_binary/main.lisp — Practical: 二进制读写 + ID3
;;;; channel: both   （书 24 章 Parsing Binary Files + 25 章 ID3 Parser）
;;;; ============================================================
;;;;
;;;; 书 24 章的核心抽象：把「从字节流读一个值」做成泛型函数，
;;;; 类型是 eql 特化的**列表** (type :length n)——类型即语法。
;;;; 书 25 章在其上解析 ID3v2（MP3 的元数据标签）。
;;;;
;;;; 本例程：
;;;;   1. read-value / write-value 框架：u1/u2/u4、定长 iso-8859-1 字符串
;;;;   2. syncsafe 整数（ID3v2 尺寸的 7bit/字节编码）
;;;;   3. 合成一个 ID3v2.3 标签写进临时文件，再解析回来对账
;;;;      （示例自包含：不需要真实 MP3，标签是现场造的）
;;;;   4. skip-value：跳过不感兴趣的段
;;;; ============================================================

;;; ----------------------------------------------------------
;;; 1. 二进制读写框架（书 24 章骨架）
;;; ----------------------------------------------------------

(defgeneric read-value (type stream &key)
  (:documentation "按类型说明从二进制流读一个值。type 是 eql 特化符号"))

(defmethod read-value ((type (eql 'u1)) stream &key)
  (read-byte stream))

(defmethod read-value ((type (eql 'u2)) stream &key)
  ;; 大端：高字节在前
  (+ (* 256 (read-byte stream)) (read-byte stream)))

(defmethod read-value ((type (eql 'u4)) stream &key)
  (let ((v 0))
    (dotimes (i 4 v)
      (setf v (+ (* 256 v) (read-byte stream))))))

(defmethod read-value ((type (eql 'iso-8859-1-string)) stream &key length)
  ;; 定长字符串：一字节一字符（latin-1）
  (let ((buf (make-array length :element-type 'character)))
    (dotimes (i length buf)
      (setf (char buf i) (code-char (read-byte stream))))))

(defgeneric write-value (type stream value &key)
  (:documentation "read-value 的镜像：把值按类型写进二进制流"))

(defmethod write-value ((type (eql 'u1)) stream value &key)
  (write-byte value stream))

(defmethod write-value ((type (eql 'u2)) stream value &key)
  (write-byte (floor value 256) stream)
  (write-byte (mod value 256) stream))

(defmethod write-value ((type (eql 'u4)) stream value &key)
  (let ((bytes nil))
    (dotimes (i 4)
      (push (mod value 256) bytes)
      (setf value (floor value 256)))
    (dolist (b bytes)
      (write-byte b stream))))

(defmethod write-value ((type (eql 'iso-8859-1-string)) stream value &key)
  (loop for ch across value
     do (write-byte (char-code ch) stream)))

(format t "── 1. 读写框架往返（临时文件当字节流——向量不能当流，两实现都拒绝）~%")
(with-open-file (out "probe.bin"
                     :direction :output :if-exists :supersede
                     :element-type '(unsigned-byte 8))
  (write-value 'u4 out #x00ff10a2)
  (write-value 'u2 out #x1234)
  (write-value 'u1 out 7)
  (write-value 'iso-8859-1-string out "ID3"))
(with-open-file (in "probe.bin" :element-type '(unsigned-byte 8))
  (let ((bytes (loop for b = (read-byte in nil nil) while b collect b)))
    (format t "写出的字节序列（大端）: ~S~%" bytes)
    ;; 原样读回验证
    (with-open-file (in2 "probe.bin" :element-type '(unsigned-byte 8))
      (format t "读回 u4=#x~X u2=#x~X u1=~A str=~S~%"
              (read-value 'u4 in2)
              (read-value 'u2 in2)
              (read-value 'u1 in2)
              (read-value 'iso-8859-1-string in2 :length 3)))))

;;; ----------------------------------------------------------
;;; 2. syncsafe 整数：ID3v2 的尺寸编码（每字节只用低 7 位）
;;; ----------------------------------------------------------

(defun write-syncsafe (stream value)
  (let ((bytes (list (mod value 128))))
    (setf value (floor value 128))
    (dotimes (i 3)
      (push (mod value 128) bytes)
      (setf value (floor value 128)))
    (dolist (b bytes)
      (write-byte b stream))))

(defun read-syncsafe (stream)
  (let ((value 0))
    (dotimes (i 4)
      (setf value (+ (* 128 value) (read-byte stream))))
    value))

(format t "~%── 2. syncsafe 编码往返~%")
(with-open-file (out "probe.bin"
                     :direction :output :if-exists :supersede
                     :element-type '(unsigned-byte 8))
  (write-syncsafe out 1024))
(with-open-file (in "probe.bin" :element-type '(unsigned-byte 8))
  (let ((bytes (loop for b = (read-byte in nil nil) while b collect b)))
    (format t "1024 → 字节 ~S（每个最高位都是 0）~%" bytes))
  ;; 换个流重新从头读（演示 read-syncsafe 本体）
  (with-open-file (in2 "probe.bin" :element-type '(unsigned-byte 8))
    (format t "read-syncsafe 读回: ~A~%" (read-syncsafe in2))))

;;; ----------------------------------------------------------
;;; 3. ID3v2.3：结构 + 合成 + 解析
;;; ----------------------------------------------------------

(defstruct id3-tag
  identifier major-version revision flags size frames)

(defstruct id3-frame
  id size data)

(defun write-id3-file (file)
  "现场造一个 ID3v2.3 标签：一个 TIT2（标题）+ 一个 TPE1（艺术家）帧"
  (with-open-file (out file
                       :direction :output
                       :if-exists :supersede
                       :element-type '(unsigned-byte 8))
    ;; 头 10 字节："ID3" + 主/次版本 + 标志 + syncsafe 尺寸
    (write-value 'iso-8859-1-string out "ID3")
    (write-value 'u1 out 3) (write-value 'u1 out 0)   ; v2.3.0
    (write-value 'u1 out 0)                            ; flags
    ;; 帧区总长：TIT2 = 10(帧头) + 1(编码字节) + 7("My Song")   = 18
    ;;           TPE1 = 10 + 1 + 10("The Artist")              = 21
    (write-syncsafe out (+ 18 21))
    ;; TIT2：帧 id 4 + 尺寸 u4 + 标志 u2 + 内容（0 号编码 = iso-8859-1）
    (write-value 'iso-8859-1-string out "TIT2")
    (write-value 'u4 out 8)
    (write-value 'u2 out 0)
    (write-value 'iso-8859-1-string out (concatenate 'string '(#\Null) "My Song"))
    ;; TPE1
    (write-value 'iso-8859-1-string out "TPE1")
    (write-value 'u4 out 11)
    (write-value 'u2 out 0)
    (write-value 'iso-8859-1-string out (concatenate 'string '(#\Null) "The Artist"))))

(defun read-id3-file (file)
  (with-open-file (in file
                      :direction :input
                      :element-type '(unsigned-byte 8))
    (let ((tag (make-id3-tag)))
      (setf (id3-tag-identifier tag) (read-value 'iso-8859-1-string in :length 3)
            (id3-tag-major-version tag) (read-value 'u1 in)
            (id3-tag-revision tag) (read-value 'u1 in)
            (id3-tag-flags tag) (read-value 'u1 in)
            (id3-tag-size tag) (read-syncsafe in))
      ;; 尺寸是帧区字节数——读满为止（帧头 10 + 内容 fsize）
      (let ((remaining (id3-tag-size tag))
            (frames nil))
        (loop while (> remaining 0)
           do (let* ((id (read-value 'iso-8859-1-string in :length 4))
                     (fsize (read-value 'u4 in))
                     (fflags (read-value 'u2 in))
                     (data (make-array fsize :element-type '(unsigned-byte 8))))
                (declare (ignore fflags))
                (dotimes (i fsize)
                  (setf (aref data i) (read-byte in)))
                (push (make-id3-frame :id id :size fsize :data data) frames)
                (decf remaining (+ 10 fsize))))
        (setf (id3-tag-frames tag) (nreverse frames)))
      tag)))

(format t "~%── 3. 合成 ID3 写盘 → 读回对账~%")
(write-id3-file "synthetic.id3")
(let ((tag (read-id3-file "synthetic.id3")))
  (format t "identifier:     ~S~%" (id3-tag-identifier tag))
  (format t "major-version:  ~A~%" (id3-tag-major-version tag))
  (format t "revision:       ~A~%" (id3-tag-revision tag))
  (format t "size(syncsafe): ~A~%" (id3-tag-size tag))
  (dolist (f (id3-tag-frames tag))
    ;; 内容首字节是编码标记（0=latin-1），正文跳过它
    (let ((text (map 'string #'code-char (subseq (id3-frame-data f) 1))))
      (format t "frame ~A size=~A text=~S~%"
              (id3-frame-id f) (id3-frame-size f) text))))

;;; ----------------------------------------------------------
;;; 4. 原始字节看一眼 + 清理
;;; ----------------------------------------------------------

(with-open-file (in "synthetic.id3" :element-type '(unsigned-byte 8))
  (let ((first10 nil))
    (dotimes (i 10)
      (push (read-byte in) first10))
    (format t "~%── 4. 文件前 10 字节（头）：~S~%" (reverse first10))))

(delete-file "synthetic.id3")
(delete-file "probe.bin")
(format t "清理完成~%")

(format t "==== 32 结束 ====~%")
