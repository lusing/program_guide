;;;; 36 · 外部格式、路径名与自定义流
;; channel: sbcl
;;;; 运行：sbcl --noinform --non-interactive --load main.lisp

(defun hdr (s) (format t "~&---- ~A ----~%" s))
(defun ub8 (&rest xs)
  (make-array (length xs) :element-type '(unsigned-byte 8)
              :initial-contents xs))

;;; ============================================================
;;; 1. 外部格式基础
;;; ============================================================
(hdr "1 外部格式基础")
(format t "default: ~S~%" sb-ext:*default-external-format*)
(assert (eq sb-ext:*default-external-format* :utf-8))

;;; ============================================================
;;; 2. string-to-octets / octets-to-string
;;; ============================================================
(hdr "2 字符串 ↔ 字节向量")
;; 注意 equalp：string-to-octets 返回专用 (unsigned-byte 8) 向量，
;; 字面量 #(104 105) 的元素类型是 T，equal 因元素类型不同判 nil
(assert (equalp (sb-ext:string-to-octets "hi") #(104 105)))
(assert (equalp (sb-ext:string-to-octets "é") #(195 169)))        ; utf-8 两字节
(assert (string= (sb-ext:octets-to-string (ub8 195 169)) "é"))

;; null-terminate / :start / :end
(assert (equalp (sb-ext:string-to-octets "hi" :null-terminate t)
                 #(104 105 0)))
(assert (equalp (sb-ext:string-to-octets "abcde" :start 1 :end 3)
                #(98 99)))
(assert (string= (sb-ext:octets-to-string (ub8 104 105)
                                          :external-format :latin-1)
                 "hi"))

;;; ============================================================
;;; 3. 编解码错误与 :replacement
;;; ============================================================
(hdr "3 编解码错误")
(assert (eq (handler-case (sb-ext:string-to-octets "é" :external-format :ascii)
              (sb-int:character-encoding-error () :enc-err))
            :enc-err))
(assert (eq (handler-case (sb-ext:octets-to-string (ub8 195)
                                                   :external-format :utf-8)
              (sb-int:character-decoding-error () :dec-err))
            :dec-err))
;; :replacement —— 遇到坏字节原地替换，不报错
(assert (string= (sb-ext:octets-to-string (ub8 104 195 105)
                                          :external-format '(:utf-8 :replacement #\?))
                 "h?i"))

;;; ============================================================
;;; 4. 流上的外部格式 + :crlf 换行
;;; ============================================================
(hdr "4 流外部格式与换行")
(with-open-file (f "doc36-ef.txt" :direction :output :if-exists :supersede)
  (assert (eq (stream-external-format f) :utf-8)))
(delete-file "doc36-ef.txt")

;; :crlf 验证
(assert (equalp (sb-ext:string-to-octets
                  (coerce '(#\a #\newline) 'string)
                  :external-format '(:utf-8 :newline :crlf))
                #(97 13 10)))

(with-open-file (f "doc36-crlf.txt" :direction :output
                   :if-exists :supersede
                   :external-format '(:latin-1 :newline :crlf))
  (write-line "ab" f))
(let ((v (make-array 4 :element-type '(unsigned-byte 8))))
  (with-open-file (f "doc36-crlf.txt"
                     :element-type '(unsigned-byte 8))
    (read-sequence v f))
  (assert (equal (coerce v 'list) '(97 98 13 10))))
(delete-file "doc36-crlf.txt")

;;; ============================================================
;;; 5. 双价流
;;; ============================================================
(hdr "5 双价流")
(with-open-file (f "doc36-bi.bin" :direction :io
                   :if-exists :supersede
                   :element-type :default :external-format :utf-8)
  (write-char #\A f)
  (write-byte 200 f)
  (file-position f 0)
  (assert (char= (read-char f) #\A))
  (assert (= (read-byte f) 200)))
(delete-file "doc36-bi.bin")

;;; ============================================================
;;; 6. 路径名
;;; ============================================================
(hdr "6 路径名")
(assert (equal (pathname-directory #p"~/foo.txt")
               '(:absolute :home)))

;; /tmp/ vs /tmp 的语义区别
(assert (equal (list (pathname-directory #p"/tmp/") (pathname-name #p"/tmp/"))
               '((:absolute "tmp") nil)))
(assert (equal (list (pathname-directory #p"/tmp") (pathname-name #p"/tmp"))
               '((:absolute) "tmp")))

;; :as-directory / :as-file 强制统一
(assert (sb-ext:native-namestring
          (sb-ext:parse-native-namestring "/tmp" nil *default-pathname-defaults*
                                          :as-directory t)
          :as-file t))

;;; ============================================================
;;; 7. Gray 流：计数输入流
;;; ============================================================
(hdr "7 Gray 流")

;; --- 核心包 + 基类 ---
(defpackage :g36 (:use :cl :sb-gray))

;; 包装基类（双冒号前缀：g36 未 export 符号，单冒号引用「尚不存在」
;; 的新符号会在读取期报 package-error——双冒号才 intern）
(defclass g36::wrapped-stream (sb-gray:fundamental-stream)
  ((inner :initarg :stream :reader g36::inner-of)))
(defmethod stream-element-type ((s g36::wrapped-stream))
  (stream-element-type (g36::inner-of s)))
(defmethod close ((s g36::wrapped-stream) &key abort)
  (close (g36::inner-of s) :abort abort))

;; 字符输入包装层
(defclass g36::wrapped-char-in
    (g36::wrapped-stream sb-gray:fundamental-character-input-stream) ())
(defmethod sb-gray:stream-read-char ((s g36::wrapped-char-in))
  (read-char (g36::inner-of s) nil :eof))
(defmethod sb-gray:stream-unread-char ((s g36::wrapped-char-in) char)
  (unread-char char (g36::inner-of s)))

;; 计数器（:around 在基类之上叠加）
(defclass g36::counting-in (g36::wrapped-char-in)
  ((chars :initform 0 :accessor g36::chars-of)
   (lines :initform 1 :accessor g36::lines-of)
   (cols  :initform 0 :accessor g36::cols-of)))
(defmethod sb-gray:stream-read-char :around ((s g36::counting-in))
  (let ((c (call-next-method)))
    (unless (eql c :eof)
      (incf (g36::chars-of s))
      (if (char= c #\newline)
          (progn (incf (g36::lines-of s))
                 (setf (g36::cols-of s) 0))
          (incf (g36::cols-of s))))
    c))

(with-input-from-string (in "1 2
3 ")
  (let ((s (make-instance 'g36::counting-in :stream in)))
    (assert (equal (list (read s) (read s) (read s)) '(1 2 3)))
    ;; 空白也被计数：共 9 字符、2 次换行（行 1→3）、当前行 3 列
    (assert (equal (list (g36::chars-of s) (g36::lines-of s) (g36::cols-of s))
                   '(9 3 3)))))

;; --- 前缀输出流 ---
(defclass g36::wrapped-char-out
    (sb-gray:fundamental-character-output-stream)
  ((inner :initarg :stream :reader g36::out-inner-of)
   (col :initform 0 :accessor g36::col-of)))
(defmethod sb-gray:stream-line-column ((s g36::wrapped-char-out))
  (g36::col-of s))
(defmethod sb-gray:stream-write-char ((s g36::wrapped-char-out) char)
  (write-char char (g36::out-inner-of s))
  (if (char= char #\newline)
      (setf (g36::col-of s) 0)
      (incf (g36::col-of s)))
  char)

(defclass g36::prefixed-out (g36::wrapped-char-out)
  ((prefix :initarg :prefix :reader g36::prefix-of)))
(defmethod sb-gray:stream-write-char :around ((s g36::prefixed-out) char)
  (when (zerop (g36::col-of s))
    (write-string (g36::prefix-of s) (g36::out-inner-of s)))
  (call-next-method))

(let ((text (with-output-to-string (out)
              (let ((s (make-instance 'g36::prefixed-out
                         :stream out :prefix "[log] ")))
                (write-line "abc" s)
                (write-line "def" s)))))
  (assert (= (search "[log] abc" text) 0))
  (assert (= (search "[log] def" text) 10)))

(format t "~&==== 36 结束 ====~%")
