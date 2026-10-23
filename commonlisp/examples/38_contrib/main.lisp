;;;; 38 · contrib 模块巡礼（docs/38-contrib.md 配套例程）
;; channel: sbcl
;;;; 运行：sbcl --noinform --non-interactive --no-userinit --load main.lisp
;;;; 判定：exit 0、stderr 为空、输出末尾出现「==== 38 结束 ====」

;;; 所有 require 放文件顶部顶层表单：contrib 包的限定符号在读取期就要
;;; 解析包名，LOAD 逐表单边读边执行，顶部 require 保证后面读到符号时
;;; 包已经存在（38.1 的读取期坑）。
(require :sb-md5)
(require :sb-rotate-byte)
(require :sb-concurrency)
(require :sb-introspect)
(require :sb-posix)
(require :sb-cltl2)
(require :sb-cover)
(require :sb-simd)

(defun hdr (s) (format t "~&---- ~A ----~%" s))

;;; ==================================================
;;; 38.1 加载机制：require + *modules*
;;; ==================================================
(hdr "38.1 require 与 *modules*")

(assert (member "SB-MD5" *modules* :test #'string=))

;;; ==================================================
;;; 38.2 sb-md5：返回 16 字节向量，hex 自己格式化
;;; ==================================================
(hdr "38.2 sb-md5")

(defun md5-hex (digest)
  (format nil "~(~{~2,'0X~}~)" (coerce digest 'list)))

(assert (string= (md5-hex (sb-md5:md5sum-string "abc"))
                 "900150983cd24fb0d6963f7d28e17f72"))
(assert (string= (md5-hex (sb-md5:md5sum-string ""))
                 "d41d8cd98f00b204e9800998ecf8427e"))
(assert (= (length (sb-md5:md5sum-string "abc")) 16))

;; md5sum-sequence 只收 (vector (unsigned-byte 8))
(assert (string= (md5-hex (sb-md5:md5sum-sequence
                           (make-array 3 :element-type '(unsigned-byte 8)
                                         :initial-contents '(97 98 99))))
                 "900150983cd24fb0d6963f7d28e17f72"))

;; md5sum-file
(with-open-file (s "/tmp/ex38-md5.txt" :direction :output :if-exists :supersede)
  (write-string "md5-file" s))
(assert (string= (md5-hex (sb-md5:md5sum-file "/tmp/ex38-md5.txt"))
                 "82c91807946785960beb35a49a73fdee"))
(delete-file "/tmp/ex38-md5.txt")

;;; ==================================================
;;; 38.3 sb-rotate-byte：bytespec 圈定位场，场外保留
;;; ==================================================
(hdr "38.3 sb-rotate-byte")

(assert (= (sb-rotate-byte:rotate-byte 2 (byte 8 0) #b00001111) 60))
(assert (= (sb-rotate-byte:rotate-byte -2 (byte 8 0) #b11000000) 48))
(assert (= (sb-rotate-byte:rotate-byte 4 (byte 8 0) #b10110000) 11))
(assert (= (sb-rotate-byte:rotate-byte 8 (byte 16 0) #x1234) 13330))
;; 场外保留：只有低 4 位参与旋转，高 4 位 1011 不动
(assert (= (sb-rotate-byte:rotate-byte 1 (byte 4 0) #b10110001) 178))

;;; ==================================================
;;; 38.4 sb-concurrency：queue / mailbox / gate / frlock
;;; ==================================================
(hdr "38.4 sb-concurrency")

(let ((q (sb-concurrency:make-queue :name "q38")))
  (sb-concurrency:enqueue 1 q)
  (sb-concurrency:enqueue 2 q)
  (assert (= (sb-concurrency:queue-count q) 2))
  (assert (= (sb-concurrency:dequeue q) 1))
  (assert (= (sb-concurrency:dequeue q) 2))
  (assert (sb-concurrency:queue-empty-p q))
  (assert (null (sb-concurrency:dequeue q)))          ; 空队出队得 NIL
  (sb-concurrency:enqueue :a q)
  (sb-concurrency:enqueue :b q)
  (assert (equal (sb-concurrency:list-queue-contents q) '(:a :b))))

(let ((mb (sb-concurrency:make-mailbox :name "mb38")))
  (sb-concurrency:send-message mb :hello)
  (assert (eq (sb-concurrency:receive-message mb :timeout 0.1) :hello))
  (assert (sb-concurrency:mailbox-empty-p mb))
  (assert (null (sb-concurrency:receive-message mb :timeout 0.1))) ; 超时 NIL
  (sb-concurrency:send-message mb 1)
  (sb-concurrency:send-message mb 2)
  (assert (equal (sb-concurrency:receive-pending-messages mb) '(1 2)))
  (assert (= (sb-concurrency:mailbox-count mb) 0)))

(let ((g (sb-concurrency:make-gate :open t)))
  (assert (sb-concurrency:wait-on-gate g :timeout 0.1)))
(let ((g (sb-concurrency:make-gate :open nil)))
  (assert (null (sb-concurrency:wait-on-gate g :timeout 0.1)))
  (assert (null (sb-concurrency:gate-open-p g)))
  (sb-concurrency:open-gate g)
  (assert (sb-concurrency:wait-on-gate g :timeout 0.1))
  (sb-concurrency:close-gate g)
  (assert (null (sb-concurrency:wait-on-gate g :timeout 0.1))))

;; frlock：读侧多 form，各取主值拼成多值
(defvar *fr-a* 0)
(defvar *fr-b* 0)
(defvar *fr-c* 0)
(defvar *fr-lk* (sb-concurrency:make-frlock :name "lk38"))

(defun fr-foo ()
  (sb-concurrency:frlock-read (*fr-lk*) *fr-a* *fr-b* *fr-c*))

(defun fr-bar (x y)
  (sb-concurrency:frlock-write (*fr-lk*)
    (setf *fr-a* x *fr-b* y *fr-c* (+ x y))))

(fr-bar 1 2)
(assert (equal (multiple-value-list (fr-foo)) '(1 2 3)))
;; 手册/实现出入：单个 (values ...) form 只保留主值
(assert (equal (multiple-value-list
                (sb-concurrency:frlock-read (*fr-lk*)
                  (values *fr-a* *fr-b* *fr-c*)))
               '(1)))

;;; ==================================================
;;; 38.5 sb-introspect：lambda list / 定义位置 / who-calls
;;; ==================================================
(hdr "38.5 sb-introspect")

(defun square38 (x &optional (scale 1)) (* x x scale))
(compile 'square38)
(assert (equal (sb-introspect:function-lambda-list #'square38)
               '(x &optional (scale 1))))
(assert (equal (sb-introspect:function-lambda-list #'car) '(list)))
(assert (typep (sb-introspect:find-definition-source #'square38)
               'sb-introspect:definition-source))

;; who-calls 数据来自编译器的交叉引用：先 compile
(defun area38 (r) (* pi r r))
(defun describe38 (r) (area38 r))
(compile 'area38)
(compile 'describe38)
(assert (member 'describe38 (sb-introspect:who-calls 'area38) :key #'car))

;;; ==================================================
;;; 38.6 sb-posix：系统调用，错误走 syscall-error
;;; ==================================================
(hdr "38.6 sb-posix")

(assert (stringp (sb-posix:getcwd)))
(assert (integerp (sb-posix:getpid)))

;; 幂等清场：防上次中断留下残骸
(ignore-errors (sb-posix:unlink "/tmp/ex38-link"))
(ignore-errors (sb-posix:rmdir "/tmp/ex38-dir"))
(sb-posix:mkdir "/tmp/ex38-dir" #o755)
(assert (probe-file "/tmp/ex38-dir"))
(sb-posix:symlink "/tmp/ex38-dir" "/tmp/ex38-link")
(assert (string= (sb-posix:readlink "/tmp/ex38-link") "/tmp/ex38-dir"))
(sb-posix:unlink "/tmp/ex38-link")
(sb-posix:rmdir "/tmp/ex38-dir")
(assert (null (probe-file "/tmp/ex38-dir")))

(let ((st (sb-posix:stat "/tmp")))
  (assert (typep st 'sb-posix:stat))
  (assert (sb-posix:s-isdir (sb-posix:stat-mode st))))

;; 打开不存在的文件：syscall-error，errno 2 = ENOENT
(assert (= (handler-case (sb-posix:open "/definitely/not/here" sb-posix:o-rdonly)
             (sb-posix:syscall-error (e) (sb-posix:syscall-errno e)))
           2))

;; read/write 的缓冲区要 SAP，不是 Lisp 向量：with-alien + alien-sap + deref
(let ((fd (sb-posix:open "/tmp/ex38-io.bin"
                         (logior sb-posix:o-wronly sb-posix:o-creat sb-posix:o-trunc)
                         #o644)))
  (assert (= (prog1
                 (sb-alien:with-alien ((buf (sb-alien:array sb-alien:unsigned-char 5)))
                   (dotimes (i 5)
                     (setf (sb-alien:deref buf i) (char-code (char "hello" i))))
                   (sb-posix:write fd (sb-alien:alien-sap buf) 5))
               (sb-posix:close fd))
             5)))
(let ((fd (sb-posix:open "/tmp/ex38-io.bin" sb-posix:o-rdonly)))
  (assert (equal
           (prog1
               (sb-alien:with-alien ((buf (sb-alien:array sb-alien:unsigned-char 5)))
                 (let ((n (sb-posix:read fd (sb-alien:alien-sap buf) 5)))
                   (list n (map 'string (lambda (i) (code-char (sb-alien:deref buf i)))
                                '(0 1 2 3 4)))))
             (sb-posix:close fd)
             (delete-file "/tmp/ex38-io.bin"))
           '(5 "hello"))))

;;; ==================================================
;;; 38.7 sb-cltl2：编译期环境查询
;;; ==================================================
(hdr "38.7 sb-cltl2")

(defvar *answer38* 42)
(assert (equal (multiple-value-list (sb-cltl2:variable-information '*answer38*))
               '(:special nil nil)))
(assert (equal (multiple-value-list (sb-cltl2:variable-information 'pi))
               '(:constant nil nil)))
(assert (eq (sb-cltl2:function-information 'car) :function))
(assert (= (cadr (assoc 'speed (sb-cltl2:declaration-information 'optimize))) 1))

;;; ==================================================
;;; 38.8 sb-cover：插桩编译 + 运行 + HTML 报告
;;; ==================================================
(hdr "38.8 sb-cover")

(ensure-directories-exist "/tmp/ex38-cover/")
(with-open-file (s "/tmp/ex38-cover-src.lisp" :direction :output
                   :if-exists :supersede)
  (write-string "(declaim (optimize (sb-cover:store-coverage-data 3)))
(defun cover-fn (x) (if (plusp x) :pos :neg))
" s))
(sb-cover:clear-coverage)
(compile-file "/tmp/ex38-cover-src.lisp" :verbose nil :print nil)
(load "/tmp/ex38-cover-src.fasl" :verbose nil)
(assert (eq (cover-fn 1) :pos))
(assert (eq (cover-fn -1) :neg))
(sb-cover:report "/tmp/ex38-cover/")
(assert (probe-file "/tmp/ex38-cover/cover-index.html"))
(sb-cover:reset-coverage)
(sb-cover:clear-coverage)
(delete-file "/tmp/ex38-cover-src.lisp")
(delete-file "/tmp/ex38-cover-src.fasl")

;;; ==================================================
;;; 38.9 sb-simd：每指令集一包，掩码与无分支选择
;;; ==================================================
(hdr "38.9 sb-simd")

(assert (equal (multiple-value-list
                (sb-simd-sse2:f32.4-values
                 (sb-simd-sse2:f32.4+ (sb-simd-sse2:make-f32.4 1.0 2.0 3.0 4.0)
                                      (sb-simd-sse2:make-f32.4 10.0 20.0 30.0 40.0))))
               '(11.0 22.0 33.0 44.0)))

;; aref 整段装载/存储，标量自动广播
(let ((arr (make-array 4 :element-type 'single-float
                         :initial-contents '(1.0 2.0 3.0 4.0))))
  (setf (sb-simd-sse2:f32.4-aref arr 0)
        (sb-simd-sse2:f32.4+ (sb-simd-sse2:f32.4-aref arr 0) 1.0))
  (assert (equal (coerce arr 'list) '(2.0 3.0 4.0 5.0))))

;; 比较返回掩码包：全 1 = 4294967295，全 0 = 0
(assert (equal (multiple-value-list
                (sb-simd-sse2:u32.4-values
                 (sb-simd-sse2:f32.4= (sb-simd-sse2:make-f32.4 1.0 2.0 3.0 4.0)
                                      (sb-simd-sse2:make-f32.4 1.0 0.0 3.0 0.0))))
               '(4294967295 0 4294967295 0)))

;; f32.4-if 要 SSE4.1 起（硬件 blendv）：掩码为真取前者、为假取后者
(let* ((a (sb-simd-sse4.1:make-f32.4 1.0 2.0 3.0 4.0))
       (b (sb-simd-sse4.1:make-f32.4 10.0 20.0 30.0 40.0))
       (mask (sb-simd-sse4.1:f32.4> a 2.5)))
  (assert (equal (multiple-value-list
                  (sb-simd-sse4.1:f32.4-values
                   (sb-simd-sse4.1:f32.4-if mask a b)))
                 '(10.0 20.0 3.0 4.0))))

;; 标量版 x-op：与 SIMD 版逐位一致，当参照实现
(assert (= (sb-simd-sse2:f32+ 1.5 2.5) 4.0))

(format t "~&==== 38 结束 ====~%")
