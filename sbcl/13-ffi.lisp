;;;; ============================================================
;;;; 13-ffi.lisp — FFI 外部函数接口（sb-alien）
;;;; ============================================================
;;;;
;;;; 本例程演示：
;;;;   1. sb-alien 基础
;;;;   2. 加载共享库
;;;;   3. 调用 C 函数
;;;;   4. C 类型映射
;;;;   5. 结构体与指针
;;;;   6. 回调函数
;;;;   7. 实用示例
;;;;   8. CFFI 简介（推荐的可移植方案）
;;;;
;;;; 注意：sb-alien 是 SBCL 特有的 FFI，
;;;;       跨实现推荐使用 CFFI 库。
;;;; 运行方式：sbcl --script 13-ffi.lisp
;;;; ============================================================


;;; ----------------------------------------------------------
;;; 1. sb-alien 基础
;;; ----------------------------------------------------------

(format t "~%=== sb-alien 基础 ===~%")

;; sb-alien 是 SBCL 的 FFI 包
;; 主要功能：
;;   sb-alien:load-shared-object  — 加载共享库
;;   sb-alien:define-alien-routine — 定义外部函数
;;   sb-alien:define-alien-type    — 定义外部类型
;;   sb-alien:alien-funcall        — 调用外部函数
;;   sb-alien:make-alien           — 分配外部内存
;;   sb-alien:free-alien           — 释放外部内存

;; C 类型与 Lisp 类型映射：
;;   C 类型          sb-alien 类型       Lisp 类型
;;   int             int                 integer
;;   unsigned int    unsigned-int        integer
;;   long            long                integer
;;   float           single-float        single-float
;;   double          double-float        double-float
;;   char*           c-string            string
;;   void*           system-area-pointer  —
;;   void            void                —


;;; ----------------------------------------------------------
;;; 2. 加载共享库
;;; ----------------------------------------------------------

(format t "~%=== 加载共享库 ===~%")

;; 加载 C 标准库
;; Windows: msvcrt.dll
;; Linux:   libc.so.6
;; macOS:   libSystem.B.dylib

#+win32
(progn
  (format t "加载 msvcrt.dll~%")
  (sb-alien:load-shared-object "msvcrt.dll"))

#+linux
(progn
  (format t "加载 libc.so.6~%")
  (sb-alien:load-shared-object "libc.so.6"))

#+darwin
(progn
  (format t "加载 libSystem.B.dylib~%")
  (sb-alien:load-shared-object "libSystem.B.dylib"))

;; 加载自定义库
;; (sb-alien:load-shared-object "/path/to/mylib.so")


;;; ----------------------------------------------------------
;;; 3. 调用 C 函数
;;; ----------------------------------------------------------

(format t "~%=== 调用 C 函数 ===~%")

;; 定义 C 函数接口
;; define-alien-routine 语法：
;;   (define-alien-routine lisp-name return-type
;;     (arg-name arg-type) ...)

;; strlen — 计算字符串长度
(sb-alien:define-alien-routine ("strlen" c-strlen) sb-alien:long
  (str sb-alien:c-string))

(format t "strlen(\"hello\") = ~A~%" (c-strlen "hello"))
(format t "strlen(\"SBCL FFI\") = ~A~%" (c-strlen "SBCL FFI"))

;; abs — 绝对值
(sb-alien:define-alien-routine ("abs" c-abs) sb-alien:int
  (n sb-alien:int))

(format t "abs(-42) = ~A~%" (c-abs -42))

;; rand / srand — 随机数
(sb-alien:define-alien-routine ("rand" c-rand) sb-alien:int)
(sb-alien:define-alien-routine ("srand" c-srand) sb-alien:void
  (seed sb-alien:unsigned-int))

(c-srand 42)
(format t "rand() = ~A~%" (c-rand))
(format t "rand() = ~A~%" (c-rand))

;; time — 获取时间
(sb-alien:define-alien-routine ("time" c-time) sb-alien:long
  (tloc sb-alien:long))

(format t "time(0) = ~A~%" (c-time 0))

;; getenv — 获取环境变量（环境变量名按平台不同，取到 NIL 是正常的）
(sb-alien:define-alien-routine ("getenv" c-getenv) sb-alien:c-string
  (name sb-alien:c-string))

(format t "getenv(\"HOME\") = ~A~%" (c-getenv "HOME"))

;; 数学函数
#+win32
(sb-alien:load-shared-object "msvcrt.dll")

(sb-alien:define-alien-routine ("sqrt" c-sqrt) sb-alien:double-float
  (x sb-alien:double-float))

(sb-alien:define-alien-routine ("pow" c-pow) sb-alien:double-float
  (base sb-alien:double-float)
  (exp sb-alien:double-float))

(format t "sqrt(2.0) = ~A~%" (c-sqrt 2.0d0))
(format t "pow(2.0, 10.0) = ~A~%" (c-pow 2.0d0 10.0d0))

;; cos / sin
(sb-alien:define-alien-routine ("cos" c-cos) sb-alien:double-float
  (x sb-alien:double-float))
(sb-alien:define-alien-routine ("sin" c-sin) sb-alien:double-float
  (x sb-alien:double-float))

(format t "cos(0) = ~A~%" (c-cos 0.0d0))
(format t "sin(π/2) = ~A~%" (c-sin (/ pi 2)))


;;; ----------------------------------------------------------
;;; 4. C 类型映射详解
;;; ----------------------------------------------------------

(format t "~%=== 类型映射 ===~%")

;; 整数类型
(sb-alien:define-alien-routine ("abs" c-abs-int) sb-alien:int
  (n sb-alien:int))

;; 无符号类型
;; sb-alien:unsigned-int
;; sb-alien:unsigned-long
;; sb-alien:unsigned-char
;; sb-alien:unsigned-short

;; 浮点类型
;; sb-alien:single-float  — float
;; sb-alien:double-float  — double

;; 字符串类型
;; sb-alien:c-string      — char*（自动转换 Lisp string）

;; 指针类型
;; sb-alien:system-area-pointer — void*

;; 自定义类型
;; (sb-alien:define-alien-type my-size-t sb-alien:unsigned-long)

;; 示例：使用不同整数类型
(sb-alien:define-alien-routine ("labs" c-labs) sb-alien:long
  (n sb-alien:long))

(format t "labs(-123456789) = ~A~%" (c-labs -123456789))


;;; ----------------------------------------------------------
;;; 5. 结构体与指针
;;; ----------------------------------------------------------

(format t "~%=== 结构体与指针 ===~%")

;; 定义 C 结构体
;; (sb-alien:define-alien-type
;;     (struct point)
;;   (x sb-alien:int)
;;   (y sb-alien:int))

;; 分配 C 内存
;; (let ((p (sb-alien:make-alien (struct point))))
;;   (setf (sb-alien:slot p 'x) 10)
;;   (setf (sb-alien:slot p 'y) 20)
;;   (format t "point: (~A, ~A)~%"
;;           (sb-alien:slot p 'x)
;;           (sb-alien:slot p 'y))
;;   (sb-alien:free-alien p))

;; 分配 C 数组
;; (let ((arr (sb-alien:make-alien sb-alien:int 10)))
;;   (dotimes (i 10)
;;     (setf (sb-alien:deref arr i) (* i i)))
;;   (dotimes (i 10)
;;     (format t "~A " (sb-alien:deref arr i)))
;;   (sb-alien:free-alien arr))

;; 使用 alien-funcall 调用函数指针
;; (sb-alien:alien-funcall function-pointer arg1 arg2 ...)

(format t "结构体与指针示例见注释~%")


;;; ----------------------------------------------------------
;;; 6. 回调函数
;;; ----------------------------------------------------------

(format t "~%=== 回调函数 ===~%")

;; SBCL 可以将 Lisp 函数作为回调传给 C 代码
;; 使用 sb-alien::alien-callback 或 define-alien-callable

;; 示例（需要支持回调的 C 库）：
;;
;; (sb-alien:define-alien-callable my-callback sb-alien:int
;;     ((x sb-alien:int))
;;   (* x 2))
;;
;; 然后将 #'my-callback 传给 C 函数

;; qsort 示例（使用 C 标准库的排序函数）
;; 注意：回调在不同平台上可能有差异

(format t "回调函数示例见注释~%")


;;; ----------------------------------------------------------
;;; 7. 实用示例
;;; ----------------------------------------------------------

(format t "~%=== 实用示例 ===~%")

;; 示例 1：获取系统信息
#+win32
(progn
  (sb-alien:load-shared-object "kernel32.dll")

  ;; GetTickCount — 获取系统运行时间（毫秒）
  (sb-alien:define-alien-routine ("GetTickCount" get-tick-count)
      sb-alien:unsigned-long)

  (format t "系统运行时间: ~A ms~%" (get-tick-count))

  ;; GetCurrentProcessId — 获取进程 ID
  (sb-alien:define-alien-routine ("GetCurrentProcessId" get-pid)
      sb-alien:unsigned-long)

  (format t "进程 ID: ~A~%" (get-pid)))

;; 示例 2：内存操作
(sb-alien:define-alien-routine ("memcpy" c-memcpy) sb-alien:system-area-pointer
  (dest sb-alien:system-area-pointer)
  (src sb-alien:system-area-pointer)
  (n sb-alien:unsigned-long))

(sb-alien:define-alien-routine ("memset" c-memset) sb-alien:system-area-pointer
  (dest sb-alien:system-area-pointer)
  (c sb-alien:int)
  (n sb-alien:unsigned-long))

(format t "memcpy/memset 已定义~%")

;; 示例 3：字符串操作
(sb-alien:define-alien-routine ("strcpy" c-strcpy) sb-alien:c-string
  (dest sb-alien:c-string)
  (src sb-alien:c-string))

(sb-alien:define-alien-routine ("strcat" c-strcat) sb-alien:c-string
  (dest sb-alien:c-string)
  (src sb-alien:c-string))

(sb-alien:define-alien-routine ("strcmp" c-strcmp) sb-alien:int
  (s1 sb-alien:c-string)
  (s2 sb-alien:c-string))

(format t "strcmp(\"abc\", \"abc\") = ~A~%" (c-strcmp "abc" "abc"))
(format t "strcmp(\"abc\", \"abd\") = ~A~%" (c-strcmp "abc" "abd"))
(format t "strcmp(\"abd\", \"abc\") = ~A~%" (c-strcmp "abd" "abc"))

;; strupr 是 MSVC/Windows 的专有函数，libSystem（macOS）/glibc 里都没有，
;; 直接用会得到 Unhandled UNDEFINED-ALIEN-FUNCTION-ERROR: "strupr"。
;; 注意：它不是标准 C 的一部分，就算在 Windows 上也建议改用 toupper。
;; 这里换成两边都有的 toupper。
(sb-alien:define-alien-routine ("toupper" c-toupper) sb-alien:int
  (c sb-alien:int))

(format t "toupper(#\\a) = ~A~%"
        (code-char (c-toupper (char-code #\a))))
(format t "toupper(#\\A) = ~A~%"
        (code-char (c-toupper (char-code #\A))))

;; strcasecmp 也是 POSIX 标准里就有的（libSystem / glibc 均有）
(sb-alien:define-alien-routine ("strcasecmp" c-strcasecmp) sb-alien:int
  (s1 sb-alien:c-string)
  (s2 sb-alien:c-string))

(format t "strcasecmp(\"ABC\", \"abc\") = ~A~%" (c-strcasecmp "ABC" "abc"))


;;; ----------------------------------------------------------
;;; 8. CFFI 简介（推荐的可移植方案）
;;; ----------------------------------------------------------

(format t "~%=== CFFI 简介 ===~%")

;; CFFI（Common Foreign Function Interface）是跨实现的 FFI 库
;; 支持 SBCL、CCL、ECL、CLISP 等
;;
;; 安装：(ql:quickload :cffi)
;;
;; 基本用法：
;;
;; (cffi:define-foreign-library libc
;;   (:unix "libc.so.6")
;;   (:windows "msvcrt.dll"))
;;
;; (cffi:use-foreign-library libc)
;;
;; (cffi:defcfun "strlen" :long
;;   (str :string))
;;
;; (strlen "hello")  ; => 5
;;
;; CFFI 类型映射：
;;   :int, :unsigned-int, :long, :unsigned-long
;;   :float, :double
;;   :string, :pointer, :void
;;   :boolean
;;
;; CFFI 结构体：
;;   (cffi:defcstruct point
;;     (x :int)
;;     (y :int))
;;
;; CFFI 回调：
;;   (cffi:defcallback my-callback :int ((x :int))
;;     (* x 2))

(format t "CFFI 示例见注释~%")
(format t "推荐使用 CFFI 而非 sb-alien，因为 CFFI 可移植~%")

(format t "~%==== 13 结束 ====~%")
