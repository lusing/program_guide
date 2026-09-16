# Common Lisp 编程指南

## 目录

- [简介](#简介)
- [语法基础](#语法基础)
- [函数式编程](#函数式编程)
- [面向对象编程](#面向对象编程)
- [宏和元编程](#宏和元编程)
- [SBCL 实战章节索引（已运行验证）](#sbcl-实战章节索引已运行验证)
- [标准库参考](#标准库参考)
- [最佳实践](#最佳实践)
- [macOS 实测修正与坑清单（2026-09，SBCL 2.6.7）](#macos-实测修正与坑清单2026-09sbcl-267)

---

## 简介

Common Lisp 是一门历史悠久的函数式编程语言，属于Lisp家族。它具有动态类型、交互式开发环境、强大的宏系统和面向对象编程能力。

### 特点

- **动态类型**：运行时类型检查
- **交互式开发**：REPL（读取-求值-打印循环）
- **多 paradigms**：支持函数式、面向对象、过程式编程
- **宏系统**：强大的代码生成和转换能力
- **标准库丰富**：ANSI X3.226-1994 标准

### 常用实现

| 实现 | 特点 |
|------|------|
| SBCL | 快速的编译器，原生线程支持 |
| CLISP | 可移植性好，支持Windows |
| CCL | macOS原生支持 |
| ABCL | 运行在JVM上 |
| ECL | 可编译为C代码 |

## SBCL 实战章节索引（已运行验证）

下面这些配套源码文件已在本目录**实际运行**验证（不是只编译）：

```bash
./run-all.sh                  # macOS / Linux
pwsh ./build.ps1 -All         # PowerShell，三平台通用
```

判定四条：退出码 0 + stderr 为空 + stdout 无多余控制字符 + 有结束标记 `==== NN 结束 ====`。

1. `01-hello-world.lisp`：基础输出、命令行参数、脚本入口
2. `02-data-types.lisp`：数字、字符串、列表、向量与结构体
3. `03-control-structures.lisp`：分支、循环、多值、非局部退出
4. `04-functions.lisp`：参数模型、闭包、局部函数、递归
5. `05-macros.lisp`：宏定义、展开与常见防坑（`gensym`）
6. `06-clos.lisp`：CLOS 类、方法、多分派
7. `07-packages.lisp`：包定义、导出与命名隔离
8. `08-conditions.lisp`：条件系统、重启与错误恢复
9. `09-file-io.lisp`：文本/二进制读写
10. `10-format.lisp`：格式化输出
11. `11-sbcl-extensions.lisp`：实现相关扩展
12. `12-threads.lisp`：线程、互斥锁、条件变量、信号量、屏障、原子操作、线程池（含线程安全打印）
13. `13-ffi.lisp`：外部函数接口
14. `14-performance.lisp`：类型声明与性能基准
15. `15-asdf-quicklisp.lisp`：工程管理与依赖
16. `16-sequences-hash-tables.lisp`：序列处理与词频统计
17. `17-testing-and-deployment.lisp`：断言测试与发布入口模式

统一验证命令：

```powershell
cd sbcl
pwsh ./build.ps1 -All
```

```bash
cd sbcl
./run-all.sh
```

两个入口的判定逻辑一致，实测均为 `通过 17   失败 0`（macOS + SBCL 2.6.7）。

---

## 语法基础

### 1. 基本形式

Lisp代码由**S表达式**（Symbolic Expression）组成，格式为：`(+ 1 2)`

```lisp
; 注释以分号开始
(+ 1 2)        ; => 3
(* 3 4)        ; => 12
(- 10 3)       ; => 7
(/ 20 4)       ; => 5
```

### 2. 变量与赋值

```lisp
; 定义常量
(defconstant pi 3.14159)

; 定义变量（动态变量）
(defvar *counter* 0)

; 局部变量
(let ((x 10)
      (y 20))
  (+ x y))     ; => 30

; 赋值
(setf x 100)
(incf x)       ; => 101 (自增1)
(decf x 5)     ; => 96  (自减5)
```

### 3. 数据类型

```lisp
; 数字类型
42            ; 整数
3.14          ; 浮点数
1/3           ; 有理数
#C(3 4)       ; 复数

; 字符串
"Hello, World!"
"包含\"转义\"字符"

; 符号
'hello        ; 符号（quote）
'True         ; 符号（在Lisp中，非nil为真）

; 列表
'(1 2 3)
'(a b c)

; 向量（固定长度数组）
#(1 2 3)

; 数组
(make-array 5)                    ; 一维数组
(make-array '(2 3))               ; 二维数组 2x3

; 结构体
(defstruct person
  name
  age)

(make-person :name "Alice" :age 25)
```

### 4. 控制流

```lisp
; 条件判断
(if (> x 0)
    "positive"
    "non-positive")

; 多条件分支
(cond ((> x 10) "greater than 10")
      ((> x 5) "greater than 5")
      (t "5 or less"))  ; t 表示默认情况

; 逻辑运算
(and (> x 0) (< x 10))
(or (< x 0) (> x 10))
(not (equal x 0))

; 循环
; dotimes - 限定次数循环
(dotimes (i 5)
  (print i))  ; => 0 1 2 3 4

; dolist - 遍历列表
(dolist (item '(a b c))
  (print item))

; loop - 强大的循环宏
(loop for i from 1 to 10
      collect i)              ; => (1 2 3 4 5 6 7 8 9 10)

(loop for x in '(1 2 3)
      sum x)                  ; => 6

(loop with result = 0
      for i from 1 to 100
      do (incf result i)
      finally (return result)) ; => 5050
```

### 5. 函数定义

```lisp
; 基本函数
(defun greet (name)
  (format nil "Hello, ~a!" name))

(greet "World")  ; => "Hello, World!"

; 可选参数
(defun greet-with-title (name &optional (title "Mr."))
  (format nil "~a ~a" title name))

(greet-with-title "Smith")        ; => "Mr. Smith"
(greet-with-title "Smith" "Dr.")  ; => "Dr. Smith"

; 关键字参数
(defun create-point (&key (x 0) (y 0))
  (cons x y))

(create-point :x 10 :y 20)  ; => (10 . 20)

; 批量参数
(defun sum (&rest numbers)
  (apply #'+ numbers))

(sum 1 2 3 4 5)  ; => 15

; 匿名函数
(mapcar (lambda (x) (* x x)) '(1 2 3))  ; => (1 4 9)
```

### 6. 列表操作

```lisp
; 创建列表
(list 1 2 3)              ; => (1 2 3)
(cons 0 '(1 2 3))          ; => (0 1 2 3)

; 访问元素
(car '(1 2 3))             ; => 1
(cdr '(1 2 3))             ; => (2 3)
(nth 1 '(a b c))           ; => B
(first '(1 2 3))           ; => 1
(rest '(1 2 3))            ; => (2 3)

; 列表操作
(append '(1 2) '(3 4))    ; => (1 2 3 4)
(reverse '(1 2 3))         ; => (3 2 1)
(length '(a b c))          ; => 3
(mapcar #'sqrt '(1 2 3))   ; => (1.0 1.4142135 1.7320508)
(remove-if #'oddp '(1 2 3 4)) ; => (2 4)
```

---

## 函数式编程

### 1. 递归

```lisp
; 阶乘
(defun factorial (n)
  (if (<= n 1)
      1
      (* n (factorial (1- n)))))

; 尾递归版本
(defun factorial-tail (n &optional (acc 1))
  (if (<= n 1)
      acc
      (factorial-tail (1- n) (* n acc))))

; 斐波那契
(defun fibonacci (n)
  (if (<= n 1)
      n
      (+ (fibonacci (1- n)) (fibonacci (- n 2)))))

; 尾递归版本
(defun fibonacci-tail (n &optional (a 0) (b 1))
  (if (<= n 0)
      a
      (fibonacci-tail (1- n) b (+ a b))))
```

### 2. 高阶函数

```lisp
; mapcar - 映射列表
(mapcar #'1+ '(1 2 3))              ; => (2 3 4)
(mapcar #'+ '(1 2 3) '(4 5 6))      ; => (5 7 9)

; reduce - 归约
(reduce #'+ '(1 2 3 4))             ; => 10
(reduce #'+ '(1 2 3 4) :initial-value 10) ; => 20
(reduce #'cons '((a) (b) (c)) :from-end t) ; => (A B C)

; filter (remove-if not)
(remove-if #'oddp '(1 2 3 4 5))     ; => (2 4)
(remove-if-not #'evenp '(1 2 3 4 5)) ; => (2 4)

; sort
(sort (list 3 1 4 1 5) #'<)         ; => (1 1 3 4 5)

; find
(find 3 '(1 2 3 4 5))               ; => 3
(find-if #'evenp '(1 3 5 6 7))      ; => 6
```

### 3. 闭包

```lisp
; 返回函数的函数
(defun make-counter ()
  (let ((count 0))
    (lambda ()
      (incf count))))

(let ((counter (make-counter)))
  (counter)  ; => 1
  (counter)  ; => 2
  (counter)) ; => 3

; 偏函数应用
(defun partial (fn &rest args)
  (lambda (&rest more-args)
    (apply fn (append args more-args))))

(defun add (x y) (+ x y))
(let ((add10 (partial #'+ 10)))
  (add10 5)) ; => 15
```

### 4. 序列操作

```lisp
; 序列是列表、向量等的泛化
(loop for i in (alexandria:iota 10)  ; 生成0-9
      do (print i))

; 序列操作函数
(subseq "Hello World" 0 5)  ; => "Hello"
(elt #(a b c) 1)           ; => B
(length #(1 2 3))          ; => 3

; 序列谓词
(every #'evenp '(2 4 6))    ; => T
(some #'oddp '(2 4 5))      ; => T
(notany #'oddp '(2 4 6))    ; => T
(map 'list #'+ '(1 2) '(3 4)) ; => (4 6)
```

### 5. 副作用与惰性求值

```lisp
; 使用 dolist 处理副作用
(dolist (file files)
  (delete-file file))

; 惰性序列（使用生成器）
(defun make-range (start end)
  (labels ((range ()
             (when (< start end)
               (cons start
                     (progn (incf start)
                            (range))))))
    (make-sequence-indicator #'range)))

; 使用形成器（generator）
(defmacro defgenerator (name args &body body)
  `(defun ,name ,args
     (block nil
       ,@body
       (return (lambda () nil)))))

(defun naturals ()
  (let ((n 0))
    (lambda ()
      (prog1 n (incf n)))))

(let ((gen (naturals)))
  (funcall gen) ; => 0
  (funcall gen) ; => 1
  (funcall gen)) ; => 2
```

---

## 面向对象编程

Common Lisp 的面向对象编程通过 **CLOS** (Common Lisp Object System) 实现。

### 1. 类定义

```lisp
; 定义类
(defclass person ()
  ((name :type string :initarg :name :accessor name)
   (age :type integer :initarg :age :accessor age)))

; 创建实例
(make-instance 'person :name "Alice" :age 25)
(make 'person :name "Bob" :age 30)

; 定义带方法的类
(defclass animal ()
  ((name :initarg :name :accessor name))
  (:documentation "基本动物类"))

(defclass mammal (animal)
  ((warm-blooded :initform t :reader warm-bloodedp))
  (:documentation "哺乳动物"))

(defclass dog (mammal)
  ((breed :initarg :breed :accessor breed)))
```

### 2. 方法与泛型函数

```lisp
; 定义类
(defclass shape ()
  ())

(defclass square (shape)
  ((side :initarg :side :accessor side)))

(defclass circle (shape)
  ((radius :initarg :radius :accessor radius)))

; 定义泛型函数
(defgeneric area (shape)
  (:documentation "计算形状的面积"))

; 为不同类定义方法
(defmethod area ((sq square))
  (* (side sq) (side sq)))

(defmethod area ((c circle))
  (* pi (expt (radius c) 2)))

; 使用 :before, :after, :around 修饰符
(defclass counter ()
  ((value :initform 0 :accessor value)))

(defmethod (setf value) :before ((new-value integer) (c counter))
  (format t "Setting value to ~a~%" new-value))

(defmethod (setf value) :after ((new-value integer) (c counter))
  (format t "Value set~%"))
```

### 3. 方法特化

```lisp
; 参数特化（使用 EQL 特化器）
(defclass point ()
  ((x :initarg :x :accessor x)
   (y :initarg :y :accessor y)))

(defmethod print-object ((p point) stream)
  (print-unreadable-object (p stream :type t)
    (format stream "~a, ~a" (x p) (y p))))

; 使用 eql 特化
(defmethod handle-status ((code integer))
  (format t "Status: ~a~%" code))

(defmethod handle-status ((code (eql 200)))
  (format t "Success~%"))

(defmethod handle-status ((code (eql 404)))
  (format t "Not found~%"))

; 多重特化
(defmethod distance ((p1 point) (p2 point))
  (sqrt (+ (expt (- (x p2) (x p1)) 2)
           (expt (- (y p2) (y p1)) 2))))
```

### 4. 元类与 Metaclass

```lisp
; 自定义元类
(defclass my-class (standard-class)
  ())

(defmethod validate-superclass ((class my-class) (superclass standard-class))
  t)

; 使用 :metaclass
(defclass my-slotted-class ()
  ((slot1 :initarg :slot1 :accessor slot1))
  (:metaclass standard-class))
```

---

## 宏和元编程

宏是Lisp最强大的特性之一，允许你在编译时生成和转换代码。

### 1. 基本宏

```lisp
; 定义宏
(defmacro square (x)
  `(* ,x ,x))

(square 5)  ; => 25

; 宏与函数的区别
(defmacro unless (condition &body body)
  `(if (not ,condition)
       (progn ,@body)))

(unless (> 1 2)
  (print "This will print"))

; &body 和 &rest 的区别
; &body: 专门用于宏体，支持缩进
; &rest: 通用批量参数
```

### 2. 宏生成代码

```lisp
; 展开查看宏生成的代码
(macroexpand-1 '(unless (> 1 2)
                  (print "hello")))

; => (IF (NOT (> 1 2)) (PROGN (PRINT "hello")))

; 一个实用的宏
(defmacro with-open-file* ((var filename &rest opts) &body body)
  `(with-open-file (,var ,filename ,@opts)
     ,@body))

; 定义域宏（anaphoric if）
(defmacro aif (test then &optional else)
  `(let ((it ,test))
     (if it ,then ,else)))

; 引用（quote）
'list         ; => LIST (符号，不是列表)
`(1 2 3)      ; => (1 2 3) (列表)
`(1 ,x 3)     ; => (1 2 3) (如果 x = 2)
`(1 ,@list 3) ; => (1 a b 3) (如果 list = (a b))

; 宏中的常见模式
(defmacro when-bind ((var test) &body body)
  `(let ((,var ,test))
     (when ,var
       ,@body)))
```

### 4. 代码变换

```lisp
; 使用 coerce 进行类型转换
(coerce '(1 2 3) 'vector)  ; => #(1 2 3)
(coerce "abc" 'list)       ; => (#\a #\b #\c)

; 使用 eval 动态执行
(eval '(+ 1 2))  ; => 3

; 宏产生宏
(defmacro defconst (name value)
  `(defconstant ,name ,value))

(defconst +max-size+ 100)
```

### 5. 宏安全与歧义

```lisp
; 使用 gensym 避免变量捕获
(defmacro incf-and-print (var)
  (let ((temp (gensym "TEMP")))
    `(let ((,temp (1+ ,var)))
       (setf ,var ,temp)
       (print ,temp)
       ,temp)))

; better: 使用 &environment
(defmacro cons-if (x y &environment env)
  (if (constantp x env)
      `(cons ,x ,y)
      `(cons ,x ,y)))

; 编译时计算示例
(eval-when (:compile-toplevel)
  (format t "Compiling...~%"))
```

### 6. 宏应用实例

```lisp
; DNS查询宏（需要 usocket 库）
(defmacro with-dns-lookup ((var host) &body body)
  `(let ((,var (sb-bsd-sockets:get-host-by-name ,host)))
     ,@body))

; 时间测量宏
(defmacro timing (&body body)
  `(let ((start (get-internal-real-time)))
     (prog1 (progn ,@body)
       (format t "Elapsed time: ~a seconds~%"
               (/ (- (get-internal-real-time) start)
                  internal-time-units-per-second)))))

; 条件绑定宏
(defmacro when-let ((var expr) &body body)
  `(let ((,var ,expr))
     (when ,var
       ,@body)))

; 资源清理宏
(defmacro with-resource ((var creator destroyer) &body body)
  `(let ((,var ,creator))
     (unwind-protect
          (progn ,@body)
       (,destroyer ,var))))
```

---

## SBCL 专用指南

### 1. SBCL 简介

SBCL (Steel Bank Common Lisp) 是 Common Lisp 的高性能实现，具有：
- 快速的本机代码编译器
- 先进的垃圾回收器
- 原生线程支持
- Windows、Linux、macOS 跨平台支持

#### 安装检查

```lisp
; 检查 SBCL 版本
; 注意：SB-EXT 里**没有** implementation-type / implementation-version
; （那是 CMUCL 时代的接口），用 CL 标准函数即可：
(lisp-implementation-type)      ; => "SBCL"
(lisp-implementation-version)   ; => "2.6.7"

; 检查特性
*features*
```

### 2. 线程与并发

```lisp
; 创建线程
(sb-thread:join-thread
  (sb-thread:make-thread
    (lambda ()
      (print "Hello from thread!"))))

; 互斥锁
(defparameter *mutex* (sb-thread:make-mutex))
(sb-thread:with-mutex (*mutex*)
  (print "Critical section"))

; 信号量
(defparameter *semaphore* (sb-thread:make-semaphore :count 5))
(sb-thread:signal-semaphore *semaphore*)       ; 传变量本身，不要写成 (*semaphore*)
(sb-thread:wait-on-semaphore *semaphore*)

; 条件变量
; 注意：SBCL 里没有 make-condition-variable，它叫 make-waitqueue
(defparameter *waitqueue* (sb-thread:make-waitqueue))
(sb-thread:with-mutex (*mutex*)
  (sb-thread:condition-wait *waitqueue* *mutex*))
(sb-thread:condition-notify *waitqueue*)

; parallel-map 示例
; ⚠ 两个坑：
;   ① 必须 join。原片段靠 "结果非空就算完" 判断，主线程根本没等，
;      函数返回时数组可能还只填了一部分。
;   ② 多线程用 (setf (nth i results) ...) 并发写**同一个列表**不是安全做法
;      （列表的槽位是 cons 单元，写的过程可能被别的线程看到半成品）。
;      改写成定长数组，每个线程只写自己那个下标。
(defun pmap (fn list)
  (let* ((n (length list))
         (results (make-array n :initial-element nil))
         (threads '()))
    (loop for item in list
          for i from 0
          do (push (sb-thread:make-thread
                    (let ((index i) (value item))
                      (lambda () (setf (aref results index) (funcall fn value)))))
                   threads))
    (dolist (th threads) (sb-thread:join-thread th))
    (coerce results 'list)))

; 多线程打印必须自己加锁。一次 FORMAT 会被拆成多次写，别的线程能插进来，
; 甚至把一个多字节汉字拆成两半 → stdout 里出现**非法 UTF-8**。
; 所有输出（含主线程）都走 say，并且要 finish-output。
(defvar *print-lock* (sb-thread:make-mutex :name "print-lock"))
(defun say (fmt &rest args)
  (sb-thread:with-mutex (*print-lock*)
    (apply #'format t fmt args)
    (finish-output)))
```

### 3. 系统交互 (SBCL 扩展)

```lisp
; 进程管理
(sb-ext:run-program "/bin/ls" '("-l" "/tmp")
                    :output t
                    :error :output)
; 注意：program 若给裸名字（如 "ls"）必须补 :search t，
; 否则 SBCL 直接 execvp，报 Couldn't execute "ls": No such file or directory。
; 另外 :output 不接受 :string，要拿字符串结果请用 :stream 自己 read-line
; （或直接用 UIOP 的 uiop:run-program … :output :string）。

; 环境变量
; ⚠ SB-POSIX 是 contrib 模块，必须先 require，否则包根本不存在，
;   这一整段连读都读不进去（reader error: Package SB-POSIX does not exist）。
(require :sb-posix)
(sb-posix:getenv "HOME")
(sb-posix:setenv "MY_VAR" "value" 1)
(sb-posix:unsetenv "MY_VAR")

; 不 require 也能用的等价写法（POSIX-GETENV 在核心里）：
(sb-ext:posix-getenv "HOME")
```

### 4. 网络编程 (SBCL + Sockets)

```lisp
; 加载 socket 库
(require :sb-bsd-sockets)

; TCP 服务器
(defclass tcp-server ()
  ((socket :init nil)
   (host :initarg :host)
   (port :initarg :port)))

(defmethod start-server ((server tcp-server))
  (setf (slot-value server 'socket)
        (make-instance 'inet-socket
                       :type :stream
                       :protocol :tcp))
  (let ((address (make-inet-address (slot-value server 'host))))
    (bind (slot-value server 'socket) address (slot-value server 'port)))
  (listen (slot-value server 'socket) 5))

; TCP 客户端
(defun connect-to-server (host port)
  (let ((socket (make-instance 'inet-socket
                               :type :stream
                               :protocol :tcp)))
    (connect socket (make-inet-address host) port)
    socket))

; 简单的 HTTP 请求 (使用 socket)
(defun http-get (host path)
  (let* ((socket (make-instance 'inet-socket
                                :type :stream
                                :protocol :tcp))
         (address (host-ent-address (get-host-by-name host))))
    (connect socket address 80)
    (with-open-stream (stream (socket-make-stream socket
                                                   :input t
                                                   :output t
                                                   :close t))
      (format stream "GET ~a HTTP/1.1~aHost: ~a~a~a"
              path #\cr #\cr host #\cr #\lf)
      (force-output stream)
      (loop for line = (read-line stream nil)
            while line
            collect line))))
```

### 5. 系统命令扩展

```lisp
; 使用 SB-POSIX 进行系统调用
; ⚠ 记得先 (require :sb-posix)
(require :sb-posix)

; mkdir 的第二个参数是**整数** mode，写成 #o755 八进制。
; 别写 8.rwxrwxrwx —— 那不是合法数字字面量，读入后只是一个名叫
; 8.RWXRWXRWX 的符号，传进去必然报类型错。
(sb-posix:mkdir "/tmp/test" #o755)
(sb-posix:chdir "/tmp")
(sb-posix:getcwd)

; 进程信息
(sb-posix:getpid)
(sb-posix:getppid)
(sb-posix:kill (sb-posix:getpid) sb-posix:SIGTERM)

; 文件操作
; 常量名字带连字符：r-ok / w-ok / x-ok / f-ok，不是 r_ok
(sb-posix:access "/etc/passwd" sb-posix:r-ok)
(sb-posix:stat "/etc/passwd")
(sb-posix:lstat "/etc/passwd")

; 管道
(multiple-value-bind (in out pid)
    (sb-ext:run-program "/bin/cat" '("file.txt")
                        :output :stream
                        :input :stream)
  (write-line "Hello" out)
  (finish-output out)
  (close out)
  (loop for line = (read-line in nil)
        while line
        do (format t "~a~%" line))
  (close in))
```

### 6. 内部时间和计时

```lisp
; 获取各种时间
(get-internal-real-time)     ; 实际时间（毫秒）
(get-internal-run-time)      ; 进程运行时间
(get-internal-time-rate)     ; 时间单位频率

; 时间与 CPU 占用
; 注意：sb-ext 里没有 cpu-time-run / cpu-time-used，别照抄
(get-internal-run-time)             ; CL 标准：进程自身运行时间
(get-internal-real-time)            ; CL 标准：墙钟时间
internal-time-units-per-second      ; CL 标准：上面两个的单位（本机 1000000）
sb-ext:*gc-run-time*                ; SBCL：GC 累计占用
(sb-ext:get-time-of-day)            ; SBCL：Unix 时间戳

; 性能分析
(sb-profile:profile)
(sb-profile:unprofile)
(sb-profile:report)
(sb-profile:reset)

; 简单的基准测试宏
(defmacro bench (title &body body)
  `(let ((start (get-internal-run-time)))
     (progn ,@body)
     (format t "~a: ~a ms~%" ,title
             (/ (- (get-internal-run-time) start)
                internal-time-units-per-second))))

; 更精确的基准测试
(defmacro precise-bench (title iterations &body body)
  `(progn
     ;; 预热
     (loop repeat 10 do (progn ,@body))
     ;; 实际测量
     (let ((total 0))
       (loop repeat ,iterations
             do (let ((start (get-internal-run-time)))
                  (progn ,@body)
                  (incf total (- (get-internal-run-time) start))))
       (format t "~a: ~,3f ms/iter~%" ,title
               (/ total ,iterations 1000.0)))))

; GC 统计
; 注意：gc-message 是 CMUCL 时代的接口，SBCL 里没有这个函数
(sb-ext:gc :full t)
(sb-ext:get-bytes-consed)             ; 至今累计分配的字节数
(sb-ext:bytes-consed-between-gcs)     ; 触发 GC 的阈值

; 内存使用：SBCL 里没有 describe-room，直接用 CL 的 room
(room)    ; 完整报告
(room t)  ; 只报关键项
```

### 7. 编译器优化与声明

```lisp
; SBCL 特定的优化优势
(declaim (optimize (speed 3) (safety 0) (debug 0)))

; 数组优化声明
(declaim (inline fast-sum))
(defun fast-sum (arr)
  (declare (type (simple-array (unsigned-byte 32) (*)) arr))
  (declare (optimize speed))
  (let ((sum 0))
    (declare (type (unsigned-byte 32) sum))
    (dotimes (i (length arr) sum)
      (declare (type fixnum i))
      (incf sum (aref arr i)))))

; 类型推断验证
(defun verify-type (x)
  (declare (type (and fixnum (not (satisfies minusp))) x))
  (the (and fixnum (not (satisfies minusp))) x))

; 函数内联
(declaim (inline my-add))
(defun my-add (a b)
  (+ a b))

; 证明编译器优化
(sb-ext: Grill (lambda (x)
                 (declare (type fixnum x))
                 (declare (optimize speed))
                 (1+ x)))
```

### 8. SBCL 特定功能

```lisp
; 多精度整数
(let ((big (expt 2 1000)))
  (integer-length big)  ; 位长度
  (logcount big))       ; 1 的数量

; 浮点特异性
(let ((x 1.0d0))  ; 双精度
  (float-sign x)
  (float-digits x)
  (float-precision x))

; 复数
(let ((c #C(3 4)))
  (/ c)           ; 倒数
  (conjugate c)  ; 共轭
  (abs c))       ; 模

; 矢量操作优化
(let ((vec (make-array 1000000 :element-type 'double-float
                               :initial-element 0.0d0)))
  (declare (type (simple-array double-float (*)) vec))
  (declare (optimize speed))
  (loop for i below (length vec)
        do (setf (aref vec i) (float i 1.0d0))))

; 编译器状态
; 注意：enable-obsolete-feedback / disable-obsolete-feedback
; 在本版 SBCL 上**根本不存在**（实测 find-symbol 为 nil），不要照抄。
; 想看编译过程的信息，用 CL 标准变量：
(setf *compile-verbose* t)
(setf *compile-print* t)
```

### 9. 调试与诊断

```lisp
; backtrace
(sb-debug:backtrace)

; 查看变量
(sb-debug:info 'my-variable)

; 条件回溯
(handler-case
    (error "Test error")
  (error (e)
    (sb-debug:backtrace)))

; 打开调试器
(sb-debug:enable-debugger)
(sb-debug:disable-debugger)

; 堆栈检查
; 注意：SB-DI 是 SBCL 的**内部**接口，不保证跨版本稳定。
; find-frame-location / current-frame 都不存在，可用的是这些：
(sb-di:top-frame)
(sb-di:frame-number (sb-di:top-frame))
(sb-di:frame-up (sb-di:top-frame))

; 性能剖析（sb-sprof 是 contrib 模块，必须先 require）
; 没有 prof / profile / visualize 这些名字，正确的是：
(require :sb-sprof)
(sb-sprof:start-profiling)
;; ...运行要分析的代码...
(sb-sprof:stop-profiling)
(sb-sprof:report)                 ; 缺省 :flat，也可 (sb-sprof:report :type :graph)
(sb-sprof:reset)
sb-sprof:*sample-interval*        ; 采样间隔是**变量**，不是函数
```

### 10. SBCL 最佳实践

```lisp
; 1. 使用_SB-EXT:MATCH-LOCAL-PARENT 对于快速局部性能
(defun sum-list (lst)
  (declare (optimize speed))
  (loop for x in lst sum x))

; 2. 避免不必要的分配
(defun increment-vector (vec)
  (declare (type (simple-array fixnum (*)) vec))
  (declare (optimize speed))
  (dotimes (i (length vec))
    (declare (type fixnum i))
    (incf (aref vec i))))

; 3. 使用 with-array-data 进行数组优化
(defun fast-vector-sum (vec)
  (declare (type vector vec))
  (declare (optimize speed))
  (aref vec 0))

; 4. 使用 sb-alien 进行 C 交互
; 注意：没有 coerce-to-alien 这个宏。要拿 C 函数指针用 extern-alien，
; 再用 alien-funcall 调用：
(sb-alien:alien-funcall
  (sb-alien:extern-alien "getpid" (function sb-alien:int)))

; 5. 使用 sb-bsd-sockets 进行网络操作
; 见前面的网络编程部分

; 6. 使用 sb-posix 进行 POSIX 系统调用
; 见前面的系统交互部分

; 7. 编译时优化
; compile-file 是 CL 标准函数（sb-ext:compile-file 只是它的别名），
; 它**没有** :speed / :safety / :debug 参数——优化级别得用 declaim 声明：
(declaim (optimize (speed 3) (safety 0) (debug 0)))
(compile-file "my-program.lisp")

; 8. 运行时优化
(declaim (optimize (speed 3) (safety 0) (debug 0)))
```

---

## 标准库参考

### 1. 字符串处理

```lisp
; 创建字符串
(make-string 5 :initial-element #\x)  ; => "xxxxx"
(format nil "~a" 'hello)  ; => "HELLO"
(string-upcase "hello")   ; => "HELLO"
(string-downcase "HELLO") ; => "hello"
(string-capitalize "hello world") ; => "Hello World"

; 字符串比较
(string= "abc" "abc")     ; => T
(string-equal "ABC" "abc"); => T (case-insensitive)
(string< "a" "b")         ; => 0 (索引，nil表示不小于)

; 字符串搜索
(search "world" "hello world") ; => 6
(find #\o "hello")             ; => #\o
(position #\l "hello")         ; => 2

; 字符串分割（需要 split-sequence 库）
(split-sequence:split-sequence #\, "a,b,c")   ; => ("a" "b" "c")
```

### 2. 系统交互

```lisp
; 执行命令（SBCL）
(sb-ext:run-program "ls" '() :output :string)

; 环境变量（SBCL）
(sb-posix:getenv "PATH")

; 文件操作
(with-open-file (in "file.txt" :direction :input)
  (loop for line = (read-line in nil)
        while line
        do (print line)))

(with-open-file (out "output.txt" :direction :output :if-exists :supersede)
  (write-line "Hello" out))

; 文件存在检查
(probe-file "file.txt")  ; => pathname 或 nil
```

### 3. 时间日期

```lisp
; 获取当前时间
(get-universal-time)
(multiple-value-bind (sec min hour day month year)
    (decode-universal-time (get-universal-time))
  (list year month day))

; 时间差
(let ((start (get-internal-real-time)))
  (sleep 1)
  (format t "Elapsed: ~a seconds~%"
          (/ (- (get-internal-real-time) start)
             internal-time-units-per-second)))
```

### 4. 序列操作扩展

```lisp
; 删除元素
(remove 1 '(1 2 1 3 1))    ; => (2 3)
(remove 1 '(1 2 1 3 1) :count 1) ; => (2 1 3 1)

; 位置查找
(position 3 '(1 2 3 4)) ; => 2
(find-if #'evenp '(1 3 5 6)) ; => 6
(remove-if #'oddp '(1 2 3 4)) ; => (2 4)

; 子序列
(subseq "hello world" 0 5) ; => "hello"
(subseq '(a b c d) 1 3)    ; => (B C)
```

---

## 最佳实践

### 1. 命名约定

```lisp
; 函数和变量 - 中划线分隔
(defun calculate-sum ()
  (let ((total-count 0))
    ...))

; 常量 - 星号包裹
(defconstant *pi* 3.14159)

; 全局变量 - 星号包裹
(defvar *debug-mode* nil)

; 类名 - 大写字母开头
(defclass person () ...)

; 谓词函数 - 问号或 p 结尾
(defun valid-p (n) ...)
(defun listp (x) ...)
```

### 2. 错误处理

```lisp
; 条件系统
(error "An error occurred: ~a" value)

; 定义条件类型
(define-condition my-error (error)
  ((message :initarg :message :accessor message)))

; 签入
(check-type x integer "must be an integer")

; 信号和处理
(when (not (integerp x))
  (error 'type-error :datum x :expected-type 'integer))

; handler-case
(handler-case (read-from-string "123")
  (parse-error (e)
    (format *error-output* "Parse error: ~a~%" e)))

; ignore-errors
(multiple-value-bind (result error)
    (ignore-errors (/ 10 x))
  (if error
      (format t "Error: ~a~%" error)
      (format t "Result: ~a~%" result)))
```

### 3. 性能优化

```lisp
; 声明类型
(defun sum-list (lst)
  (declare (type list lst))
  (declare (optimize (speed 3) (safety 0)))
  (reduce #'+ lst))

; 使用 the 声明
(defun compute (x)
  (declare (type fixnum x))
  (the fixnum (+ x 1)))

; 数组访问优化
(defun sum-array (arr)
  (declare (type (simple-array fixnum (*)) arr))
  (declare (optimize (speed 3) (safety 0)))
  (let ((sum 0))
    (declare (type fixnum sum))
    (dotimes (i (length arr))
      (incf sum (aref arr i)))
    sum))
```

### 4. 调试技巧

```lisp
; trace 调试
(trace factorial)
(untrace factorial)

; inspect
(inspect variable)

; step
(step (factorial 5))

; 调试宏展开
(macroexpand-1 '(when (> x 0) (print x)))
(macroexpand '(when (> x 0) (print x)))

; pprint 宏展开（需要 alexandria 库）
(alexandria:macroexpand-all '(when (> x 0)
                               (print x)
                               (incf x)))
```

### 5. 代码风格

```lisp
; 好的风格
(defun find-max (list)
  (when list
    (reduce (lambda (a b) (if (> a b) a b)) list)))

; 避免深层嵌套
(defun process-data (data)
  (when (and data (listp data))
    (mapcar #'identity data)))

; 使用 when/unless 代替单分支 if
(unless (plusp x)
  (return-from function-name nil))

; 命名中间结果
(let ((sorted-items (sort items #'<)))
  (let ((first-item (first sorted-items)))
    first-item))
```

---

## Emacs 中的 Common Lisp 支持

### 1. Emacs Lisp 开发环境简介

Emacs 是 Common Lisp 开发的首选 IDE，通过 **SLIME** (Superior Lisp Interaction Mode for Emacs) 提供强大的交互式开发环境。

#### 安装 SLIME

```elisp
;; 使用 MELPA 安装
;; M-x package-install [RET] slime [RET]

;; 或在 init.el 中配置
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

(unless (package-installed-p 'slime)
  (package-install 'slime))

;; 加载 SLIME
(require 'slime)
(slime-setup)
```

#### 基本配置

```elisp
;; init.el 配置示例
(setq slime-net-coding-system 'utf-8-unix)
(setq slime-default-classifier 'ignore)
(setq slime-中途-a-问题'自动完成t)

;; 配置 SBCL 作为默认 Lisp
(setq inferior-lisp-program "sbcl")

;; 启动 SLIME
;; M-x slime [RET]
```

---

### 2. SLIME 核心功能

#### 启动与连接

```elisp
;; 启动 SLIME
M-x slime                    ;; 启动新的 Lisp 进程
M-x slime-connect           ;; 连接到远程 Lisp 服务器
M-x slime-reset             ;; 重置 SLIME
M-x slime-interrupt         ;; 中断长时间运行的命令
```

#### 交互式开发

```lisp
;; 在 SLIME REPL 中
(+ 1 2)                      ;; 求值并显示结果
M-.
(name 'function-name)        ;; 跳转到函数定义
M-?                         ;; 列出所有匹配的符号

;; 求值区
M-:                         ;; 求值单行表达式
M-e                         ;; 求值前一个表达式
C-c C-c                     ;; 求值当前缓冲区
```

---

### 3. SLIME 编辑功能

#### 代码导航

| 命令 | 功能 |
|------|------|
| `M-.` | 跳转到定义 |
| `M-,` | 返回上一个位置 |
| `M-?` | 显示符号信息 |
| `C-c M-j` | 跳转到最近的错误 |
| `C-c C-p` | 显示包信息 |

#### 代码检查

```elisp
;; 编译时检查
C-c C-c                     ;; 编译当前缓冲区
C-c C-m                     ;; 宏展开
C-c C-w button              ;; 查看警告

;; 类型检查
C-c C-t                     ;; 类型检查表达式
```

#### 宏展开

```lisp
;; 宏展开显示
(defmacro my-if (condition then &optional else)
  `(if ,condition
       (progn ,then)
       (progn ,else)))

;; 查看展开结果
M-x slime-macroexpand-1
M-x slime-macroexpand-all
C-c C-m                     ;; 当前表达式宏展开
```

---

### 4. SLIME 调试功能

#### 条件系统

```elisp
;; 中断调试器
(debug)                     ;; 插入调试点
(break)                     ;; 强制中断
(error "error message")     ;; 触发错误

;; 调试命令
()?.                      ;; 显示可用调试命令
:help                      ;; 显示帮助
:break                     ;; 中断执行
:continue                  ;; 继续执行
:abort                     ;; 中止
:retrieve N                ;; 检索第 N 个中断
```

#### backtrace

```
;; 调试器中的 backtrace
:b                          ;; 显示 backtrace
:b full                     ;; 显示完整 backtrace
:b N                        ;; 显示第 N 帧
:frame N                    ;; 选择第 N 帧
```

#### 变量检查

```
;; 调试器中检查变量
:v                          ;; 显示局部变量
: BOB                       ;; 显示绑定的变量
:eval expr                  ;; 求值表达式
:print expr                 ;; 打印表达式
```

---

### 5. SLIME 跟踪功能

```lisp
;; 跟踪函数
(trace factorial)            ;; 跟踪函数调用
(untrace factorial)          ;; 取消跟踪
(trace all)                  ;; 跟踪所有函数

;; 跟踪显示
:trace-depth                ;; 设置跟踪深度
:trace-format               ;; 设置跟踪格式

;; 跟踪输出示例
(=Factorial 3= Entering
  (=Factorial 2= Entering
    (=Factorial 1= Entering
      (=Factorial 0= Entering
        (=Factorial 0= Returning 1)
      =Factorial 1= Returning 1)
    =Factorial 2= Returning 2)
  =Factorial 3= Returning 6)
```

---

### 6. SLIME 测试与性能分析

#### 性能分析

```lisp
;; SBCL 性能分析（sb-sprof 是 contrib 模块）
(require :sb-sprof)
(sb-sprof:start-profiling)      ; 不是 start-profiler
;; 运行代码
(sb-sprof:stop-profiling)
(sb-sprof:report)
(sb-sprof:reset)

;; 内置 profiler
C-c C-d p                   ;; 启动性能分析
C-c C-d r                   ;; 报告性能
```

#### 代码覆盖

```
;; 使用 sb-cover 进行代码覆盖
(require :sb-cover)
;; 收集覆盖率要在**编译期**声明（sb-cover 的用法与别的 profiler 不同）
(declaim (optimize sb-cover:store-coverage-data))
(sb-cover:report "/path/to/coverage-dir/")
(sb-cover:reset-coverage)       ; 是 reset-coverage，不是 reset
```

---

### 7. Emacs Lisp 配置示例

#### 完整配置

```elisp
;; ~/.emacs.d/init.el - Common Lisp 开发配置
(setq user-init-dir
      (or (bound-and-true-p doom-init-dir)
          (getenv "HOME")))

;; 包管理器配置
(use-package slime
  :ensure t
  :config
  (setq
   ;; 通用设置
   slime-net-coding-system 'utf-8-unix
   slime-maximum-plet-m.LENGTH 1000
   slime-complete-symbol*-fancy t

   ;; SBCL 配置
   inferior-lisp-program "sbcl"

   ;; UI 设置
   slime-ui-overlap nil
   slime-highlight-(sassy t
   slime-fuzzy-complete-symbol t)

   ;; 自动格式化
   (add-hook 'lisp-mode-hook
             (lambda ()
               (slime-mode t)
               (smartparens-mode t)
               (rainbow-delimiters-mode t)))

   ;; 导航增强
   (define-key slime-mode-map (kbd "C-c C-d") 'slime-description)
   (define-key slime-mode-map (kbd "C-c C-d d") 'slime-describe-symbol)
   (define-key slime-mode-map (kbd "C-c C-d e") 'slime-extend)

   ;; 键绑定简写
   (define-key slime-mode-map (kbd "C-c C-b") 'slime-interrupt)
   (define-key slime-mode-map (kbd "C-c C-k") 'slime-repl-reset)
   (define-key slime-mode-map (kbd "C-c C-l") 'slime-load-file)
   (define-key slime-mode-map (kbd "C-c C-r") 'slime-compile-and-load-file)

   ;; 宏展开快捷键
   (define-key slime-mode-map (kbd "C-c C-m") 'slime-macroexpand-1)
   (define-key slime-mode-map (kbd "C-c M-m") 'slime-macroexpand-all)

   ;; 调试快捷键
   (define-key slime-mode-map (kbd "C-c C-t") 'slime-compile-and-load-file)
   (define-key slime-mode-map (kbd "C-c C-f") 'slime-compile-file)

   ;; REPL 快捷键
   (define-key slime-repl-mode-map (kbd "C-c C-b") 'slime-interrupt)
   (define-key slime-repl-mode-map (kbd "C-c C-k") 'slime-repl-reset)
   (define-key slime-repl-mode-map (kbd "C-c C-l") 'slime-load-file)
   (define-key slime-repl-mode-map (kbd "C-c C-r") 'slime-compile-and-load-file)))
```

#### 推荐的 SLIME 扩展

```elisp
;; SLIME 扩展包
(use-package slime-repl
  :ensure slime
  :config
  (slime-repl-set-style 'colon-initialized))

;; slime-fancy - 增强功能
(use-package slime-fancy
  :ensure t
  :after slime
  :config
  (slime-fancy))

;; slime-c-c-c-c - 自动补全
(use-package slide-c-c-c-c
  :ensure t)

;; slime-unicode - Unicode 支持
(use-package slime-unicode
  :ensure t)
```

---

### 8. Slime REPL 功能

#### REPL 基本操作

```
;; REPL 提示符说明
CL-USER>                    ;; 普通输入
CL-USER:1>                  ;; 递归调试级别
CL-USER[1]>                 ;; 递归调试级别 (不同风格)

;; REPL 命令
:help                      ;; 显示帮助
:history                   ;; 显示命令历史
:history n                 ;; 显示最近 n 条命令
:reset                     ;; 重置 REPL
:clear                     ;; 清空屏幕
:quit                      ;; 退出 REPL
:slime                     ;; 返回 SLIME
```

#### 历史与回溯

```
;; 历史导航
M-p                        ;; 上一个命令

```

---

## 教程扩充：两个可落地实战片段

以下片段来自新增示例文件，均已通过编译验证。

### 1) 序列 + 哈希表统计（`16-sequences-hash-tables.lisp`）

```lisp
(defun word-frequency (words)
  (let ((table (make-hash-table :test 'equal)))
    (dolist (w words table)
      (incf (gethash w table 0)))))

(let* ((words '("lisp" "sbcl" "lisp" "macro" "sbcl" "lisp"))
       (freq (word-frequency words)))
  (maphash (lambda (k v)
             (format t "~A => ~A~%" k v))
           freq))
```

### 2) 断言测试 + 发布入口（`17-testing-and-deployment.lisp`）

```lisp
(defun safe-average (numbers)
  (assert (and (listp numbers) numbers) () "numbers 必须是非空列表")
  (/ (reduce #'+ numbers) (length numbers)))

(handler-case
    (safe-average '())
  (error (e)
    (format t "捕获到预期错误: ~A~%" e)))

(defun app-main ()
  (format t "App started.~%")
  (format t "Args: ~S~%" sb-ext:*posix-argv*)
  (sb-ext:quit :unix-status 0))
```

```
M-n                        ;; 下一个命令
C-c C-p                    ;; 上一个表达式
C-c C-n                    ;; 下一个表达式

;; 输出历史
:output n                  ;; 显示第 n 个输出
:output *                  ;; 显示所有输出
```

---

### 9. SLIME 与 SBCL 集成

#### SBCL 特定配置

```elisp
;; SBCL 配置
(setq inferior-lisp-program "sbcl --noinform --no-signal-handlers")

;; SBCL + SLIME 最佳实践
;; 在 ~/.sbclrc 中添加
#+sbcl
(sb-ext:disable-debugger)
```

#### 调试器集成

```
;; SLIME 调试器命令
:backtrace                 ;; backtrace
:frames                    ;; 列出所有帧
:frame n                   ;; 选择帧 n
:locals                    ;; 显示局部变量
:args                      ;; 显示参数
:source                    ;; 显示源代码
:source sym                ;; 显示符号源码
:quit                      ;; 退出调试器
:continue                  ;; 继续执行
:abort                     ;; 中止
:回去                      ;; 返回上一级
```

---

### 10. 开发工作流

#### 典型开发循环

```
1. 启动 SLIME: M-x slime
2. 编辑代码在编辑缓冲区
3. 求值代码: C-c C-c (编译缓冲区)
4. 测试在 REPL 中
5. 出错时使用调试器
6. 修复并重复
```

#### 常用命令速查

| 操作 | 命令 |
|------|------|
| 启动 SLIME | `M-x slime` |
| 求值缓冲区 | `C-c C-c` |
| 编译文件 | `C-c C-f` |
| 加载文件 | `C-c C-l` |
| 宏展开 | `C-c C-m` |
| 表达式类型 | `C-c C-t` |
| 描述符号 | `C-c C-d d` |
| 跳转定义 | `M-.` |
| 返回位置 | `M-,` |
| 中断执行 | `C-c C-b` |
| 进入 REPL | `C-c C-j` |

---

### 11. 推荐的编辑辅助工具

#### Paredit 模式

```elisp
;; Paredit - 结构化编辑
(use-package paredit
  :ensure t
  :hook (lisp-mode . paredit-mode))

;; Paredit 基本操作
C-SPC                      ;; 读取 S-表达式
C-UP / C-DOWN              ;; 提升/降低 S-表达式
C-K                        ;; 使用 Paredit 删除
M-S-LEFT / M-S-RIGHT       ;; 移动 S-表达式
M-R                        ;; 旋转 S-表达式
```

#### Rainbow Delimiters

```elisp
;; 彩虹括号
(use-package rainbow-delimiters
  :ensure t
  :hook (lisp-mode . rainbow-delimiters-mode))
```

---

### 12. 常见问题与故障排除

#### SLIME 连接问题

```
;; 如果 SLIME 无法启动
1. 检查 inferior-lisp-program 设置
2. 确认 Lisp 已安装
3. 查看 *-messages* 缓冲区

;; 重新启动 SLIME
M-x slime shutdown
M-x slime
```

#### 调试器不显示

```
;; 启用调试器
(slime-enable-debugger)

;; 检查设置
(slime-getenv "SLIME_DEBUGGER")
```

---

## Common Lisp 与 Emacs Lisp 的区别

Common Lisp 和 Emacs Lisp 都属于 Lisp 家族，但它们是**不同的语言方言**，设计目标和使用场景都有显著差异。

---

### 1. 语言标准与历史

| 特性 | Common Lisp | Emacs Lisp |
|------|-------------|------------|
| 标准 | ANSI X3.226-1994 | 无正式标准 |
| 首次发布 | 1984 (Lisp Machine) | 1985 (GNU Emacs) |
| 设计目标 | 通用编程语言 | Emacs 扩展与脚本 |
| 实现 | 多种 (SBCL, CLISP, CCL, ABCL, ECL) | GNU Emacs 内置 |

```lisp
; Common Lisp 有正式标准
; Emacs Lisp 随 Emacs 版本进化
```

---

### 2. 变量绑定

#### Common Lisp

```lisp
; 动态绑定 (dynamic binding)
(defparameter *debug-mode* nil)
; 参数名通常用星号包裹表示动态变量

; lexial 绑定 (lexical binding)
(let ((x 10))
  (declare (special x))  ; 声明为动态变量
  ...)

; 默认是 lexical binding (v1.0+)
```

#### Emacs Lisp

```elisp
; 默认是 dynamic binding
(defvar debug-mode nil)
(let ((x 10))
  (let ((x 20))  ; 动态绑定
    x))          ; => 20

; Emacs 24+ 支持 lexical binding
;; -*- lexical-binding: t -*-
(let ((x 10))
  (let ((x 20))
    x))  ; => 20 (lexical)
```

---

### 3. 命名约定

#### Common Lisp

```lisp
; 函数和变量 - 中划线分隔 (kebab-case)
(defun calculate-sum (list)
  (reduce #'+ list))

; 常量 - 星号包裹
(defconstant *pi* 3.14159)

; 全局变量 - 星号包裹
(defvar *default-directory*)

; 类名 - 大写字母开头
(defclass person () ...)

; 谓词函数 - p 结尾
(defun valid-p (x) ...)
```

#### Emacs Lisp

```elisp
; 函数和变量 - 中划线分隔
(defun calculate-sum (list)
  (reduce #'+ list))

; 全局变量 - 星号包裹（约定，非强制）
(defvar debug-mode nil)

; 函数名通常有前缀
(defcustom my-mode-enable t
  "Enable my mode.")

; 谓词函数 - p 结尾
(defun listp (x) ...)
```

---

### 4. 包系统 (Packages)

#### Common Lisp

```lisp
; 严格的包系统
(defpackage :my-app
  (:use :cl)
  (:export :function1 :function2))

(in-package :my-app)

; 符号解析严格执行
(cl:format t "Hello~%")  ; 使用 CL 包
(my-app:function1)       ; 使用 my-app 包
```

#### Emacs Lisp

```elisp
; 简化的包系统
; 所有符号在 same symbol table 中

; 通过前缀避免冲突
(defcustom my-mode-enable t
  "Enable my mode.")

(defun my-function ()
  "My function.")

; 没有 CL 那样严格的包隔离
```

---

### 5. 宏系统

#### Common Lisp

```lisp
; 强大的宏系统
(defmacro when (condition &body body)
  `(if ,condition
       (progn ,@body)))

; 宏展开
(macroexpand '(when (> x 0) (print x)))
; => (IF (> X 0) (PROGN (PRINT X)))

; 完全扩展
(macroexpand-all '(when (> x 0)
                    (print x)
                    (incf x)))
```

#### Emacs Lisp

```elisp
; 类似的宏系统
(defmacro when (condition &rest body)
  (list 'if condition
        (cons 'progn body)))

; 宏展开
(macroexpand '(when (> x 0) (print x)))
; => (IF (> X 0) (PROGN (PRINT X)))

; 语法略有不同，但概念相同
```

---

### 6. 对应关系表

| 功能 | Common Lisp | Emacs Lisp |
|------|-------------|------------|
| 定义函数 | `defun` | `defun` |
| 定义常量 | `defconstant` | `defconst` |
| 定义变量 | `defvar` | `defvar` |
| 定义宏 | `defmacro` | `defmacro` |
| 条件分支 | `if`, `cond` | `if`, `cond` |
| 循环 | `loop`, `dotimes`, `dolist` | `while`, `dolist`, `dotimes` |
| 高阶函数 | `mapcar`, `reduce` | `mapcar`, `reduce` |
| 匿名函数 | `lambda` | `lambda` |
| 异常处理 | `condition`, `handler-case` | `condition-case`, `signal`, `error` |
| 结构体 | `defstruct` | `defstruct` |
| 类 | `defclass` (CLOS) | 无正式 CLOS 支持 |
| 调试器 | 详细调试器 | `debug` 函数 |
| 时间 | `get-internal-real-time` | `current-time`, `float-time` |
| 系统交互 | `sb-ext:run-program` | `call-process`, `start-process` |
| 网络 | `sb-bsd-sockets` | `network-stream`, `open-network-stream` |

---

### 7. 代码示例对比

#### 递归阶乘

```lisp
;; Common Lisp
(defun factorial (n)
  (if (<= n 1)
      1
      (* n (factorial (1- n)))))

;; Emacs Lisp
(defun factorial (n)
  (if (<= n 1)
      1
      (* n (factorial (1- n)))))
```
> **相同**：语法几乎一样

#### 文件操作

```lisp
;; Common Lisp
(with-open-file (in "file.txt" :direction :input)
  (loop for line = (read-line in nil)
        while line
        do (print line)))

;; Emacs Lisp
(with-current-buffer (find-file-noselect "file.txt")
  (goto-char (point-min))
  (while (not (eobp))
    (print (buffer-substring-no-properties
            (point) (line-end-position)))
    (forward-line 1)))
```
> **不同**：Emacs Lisp 操作缓冲区，CL 操作文件流

#### 错误处理

```lisp
;; Common Lisp
(handler-case (read-from-string "123")
  (parse-error (e)
    (format *error-output* "Parse error: ~a~%" e)))

;; Emacs Lisp
(condition-case err
    (read-from-string "123")
  (error (format标准-output* "Error: %s\n" err)))
```

#### 命令行参数

```lisp
;; Common Lisp
(dolist (arg sb-ext:*posix-argv*)
  (print arg))

;; Emacs Lisp
(dolist (arg command-line-args)
  (print arg))
```

---

### 8. 何时使用哪种语言

#### 使用 Common Lisp

- 开发独立应用程序
- 需要高性能计算
- 跨平台项目
- 大型代码库（包系统优势）
- 需要标准化保证

#### 使用 Emacs Lisp

- 扩展和定制 Emacs
- 编写 Emacs 插件
- 快速的脚本任务
- 与 Emacs 生态系统集成

---

### 9. 迁移注意事项

如果在 Emacs 中使用 Common Lisp 代码：

```elisp
;; 使用 cl-lib 避免冲突
(require 'cl-lib)

;; cl-lib 版本的循环
(cl-loop for i from 1 to 10
         collect i)

;; 而不是 CL 的 loop
;; (loop for i from 1 to 10 collect i)  ; 可能冲突
```

```lisp
;; Common Lisp 代码迁移到 Elisp
;; 1. 替换包前缀
(cl:format -> format

;; 2. 替换特殊函数
(push item list)  ; CL's push 在 Elisp 中需要 cl-pushnew
(incf var)        ; 改为 (setq var (1+ var))

;; 3. 替换系统调用
(sb-ext:run-program -> call-process
(sb-posix:getenv -> getenv
```

---

## macOS 实测修正与坑清单（2026-09，SBCL 2.6.7）

本章的内容**全部来自实机运行**，不是转述文档。核查方式：把正文里出现的每一个
`sb-*:符号` 抽出来写成一个探针程序逐个 `find-symbol`，谁不存在就是文档写错了；
示例则逐个真跑，按「退出码 0 + stderr 为空 + stdout 无控制字符 + 结束标记」四条判定。

### 0. 最重要的一条：编译通过 ≠ 能跑

原验证脚本只做 `compile-file`。实测：17 个示例里有 **8 个一跑就崩**，
而 `compile-file` 对**全部 17 个**都返回成功——因为崩的地方
（`format` 指令、`rename-file`、`run-program`、重定义 CL 函数）都发生在**运行期**。
所以本目录现在一律**真跑**，并用结束标记兜住「中途崩了但退出码仍是 0」的情况。

### 1. 平台专有写法（Windows 上能跑，macOS 必挂）

| 现象 | 原因 | 修法 |
|---|---|---|
| `Couldn't execute "cmd"` | 硬编码 `cmd /c`，POSIX 没有 `cmd` | `#+win32` / `#-win32` 分发到 `/bin/sh -c` |
| `USERPROFILE` / `OS` 取到 NIL | 这两个是 Windows 专有变量名 | 改用 `HOME` / `SHELL` |
| `The alien function "strupr" is undefined` | `strupr` 是 MSVC 专有函数，libSystem 没有，**也不是标准 C** | 换 `toupper` / `strcasecmp` |
| `save-lisp-and-die "x.exe"` | 只有 Windows 才加 `.exe` | macOS/Linux 上产物无扩展名 |

### 2. 版本专有（与操作系统无关）

- **`(require :sb-profile)` 会失败。** `SB-PROFILE` 已经在**核心里**，没有同名 contrib
  模块可 require，写了直接报 `Don't know how to REQUIRE :SB-PROFILE.` 并终止文件。
  直接调用 `sb-profile:profile/report/unprofile/reset` 即可。
  **对比**：`SB-SPROF` / `SB-POSIX` / `SB-COVER` / `SB-BSD-SOCKETS` 确实是 contrib，必须 require。
- **contrib 包在 require 之前「包不存在」。** `(sb-posix:getenv "HOME")` 写在
  `(require :sb-posix)` 之前，报的是 **reader error**（`Package SB-POSIX does not exist.`）——
  因为 Lisp 是**先读入整个 form 再求值**，包必须在读的时候就已经存在。
  同理，用 `sbcl --eval '(progn (require :sb-posix) (sb-posix:...))'` 这样一行写也是不行的。

### 3. 语言与实现层面的坑（跨平台通病）

#### 3.1 `defgeneric` 不能占用 CL 已有的名字

```lisp
(defgeneric describe (obj))   ; ✗ DESCRIBE 已经是 CL 的普通函数
;; => DESCRIBE already names an ordinary function or a macro.
```

`DEFGENERIC` 要求该名字尚不是普通函数或宏。这个错在 `--non-interactive` 下**直接终止整个文件**，
不是警告。自定义泛型请起别的名字（`describe-thing` 之类）。

顺带一个更隐蔽的：**`CL-USER` 默认 `use-package` 了 `SB-EXT` / `SB-ALIEN` / `SB-DEBUG` /
`SB-GRAY` / `SB-PROFILE`**，所以 `report`、`reset`、`profile` 这些名字
既不能 `defun`，也不能当 `flet`/`labels`/`let` 的局部名，否则报包锁冲突：

```text
Lock on package SB-PROFILE violated when binding RESET as a local function
```

#### 3.2 `rename-file` 的第二个参数是「目标路径的默认值」

```lisp
(rename-file "test-dir/file2.txt" "test-dir/renamed.txt")   ; ✗
;; 实际去 rename 到 test-dir/test-dir/renamed.txt（相对目录被再拼一次）→ 报错
```

第二个参数若是**相对目录**，会与源文件所在目录再合并一次。只给纯文件名（`"renamed.txt"`）
反而没问题，因为它没有目录部分。稳妥写法是把目录先绝对化：

```lisp
(rename-file "test-dir/file2.txt"
             (merge-pathnames "renamed.txt" (truename "test-dir/")))
```

#### 3.3 `format`：`~-10D` 不是左对齐，`~|` 不是表格竖线

```lisp
(format t "~-10D" 42)
;; => error in FORMAT: The value of mincol is -10, should be a non-negative integer
```

`mincol` 必须是非负整数。**`~A` 与 `~D` 的补空格方向正好相反**（实测）：

| 写法 | 结果 |
|---|---|
| `~10D` | `"        42"`（左补空格，右对齐） |
| `~10A` | `"42        "`（右补空格，**左对齐**） |
| `~10@A` | `"        42"` |

而 `~|` 是 CL 的**换页指令**（Tilde Vertical-Bar: Page），输出的是换页字符 `#\Page`（0x0C）。
拿它当列分隔符，stdout 里就会混进控制字符。排对齐的列用宽度参数 `~20A` 就行。

#### 3.4 整文件读成字符串：`file-length` 是**字节数**

```lisp
(with-open-file (in "test.txt")
  (let ((s (make-string (file-length in))))   ; ✗ file-length 给的是字节数
    (read-sequence s in)
    s))
```

`make-string` 要的是**字符数**。文件里有中文（UTF-8 一个汉字 3 字节）时字符串会分配过大，
而 `make-string` 不给 `:initial-element` 时初值由实现自定，**SBCL 用 `#\Nul` 填**——
多出来的位置全成了 NUL 字符，一打印就把原始 0 字节漏进 stdout。
退出码、stderr、结束标记全都正常，肉眼翻不出来（本目录 09 号示例就这样漏了 42 个 NUL）。
正确做法是接住 `read-sequence` 的返回值再截断：

```lisp
(let* ((s (make-string (file-length in)))
       (n (read-sequence s in)))     ; n = 第一个未被覆盖的下标
  (subseq s 0 n))
```

#### 3.5 `grab-mutex` 不可重入，试探性加锁不是返回 NIL

```lisp
(sb-thread:grab-mutex lock)
(sb-thread:grab-mutex lock :waitp nil)
;; => Recursive lock attempt #<SB-THREAD:MUTEX owner: ... main thread ...>
```

同一个线程再次加锁是**报错**（并终止文件），不是返回 NIL。
要判断持有情况用 `sb-thread:holding-mutex-p` / `sb-thread:mutex-owner`。

#### 3.6 `warn` 写的是 stderr

`warn` 的输出走 `*error-output*`，不是 `*standard-output*`。
演示脚本想让警告和别的输出落在一起，就临时绑一下：

```lisp
(let ((*error-output* *standard-output*))
  (warn "这条会打到 stdout"))
```

### 4. `sbcl` 命令行的坑

- **`--script` 与 `--non-interactive` 不能连用。**
  `sbcl --non-interactive --script x.lisp` 不会执行 `x.lisp`——`--script` 之后的参数
  会被当成**运行时参数**，结果是只打一行 banner、退出码 0，看起来"跑过了"其实啥也没干。
  本目录统一用 `--noinform --non-interactive --no-userinit --load <file>`。
- **`run-program` 给裸程序名要加 `:search t`**，否则直接 `execvp`，
  报 `Couldn't execute "echo": No such file or directory`；给绝对路径则不需要。
- **`run-program` 的 `:output` 不接受 `:string`**（报 `invalid option: :STRING`）。
  想拿字符串结果用 `:stream` 自己读，或用 UIOP 的 `uiop:run-program ... :output :string`。

- **`--load` 与 `--script` 的输出去向可能不同，别以为两者等价。** 实测同一个
  `14-performance.lisp`：`sb-profile:report` 打的那行 `measuring PROFILE overhead..done`
  在 `--load` 下**绕过 stdout/stderr 直接写控制终端**（重定向抓不到），
  在 `--script` 下却**落到 stderr**。把 `*trace-output*` / `*error-output*`
  绑成广播流都压不掉它（已实测）。本目录因此统一按 `--load` 跑，
  写验证脚本时也别默认两种调用模式行为一致。

### 5. 本次修正的正文断言一览

以下名字在本版 SBCL 上**不存在**，正文已就地改掉：

| 原文写的 | 实际情况 | 正确写法 |
|---|---|---|
| `sb-ext:implementation-type/version` | 不存在（CMUCL 时代接口） | `lisp-implementation-type/version`（CL 标准） |
| `sb-thread:make-condition-variable` | 不存在 | `sb-thread:make-waitqueue` |
| `sb-ext:cpu-time-run` / `cpu-time-used` | 不存在 | `get-internal-run-time` / `sb-ext:*gc-run-time*` / `sb-ext:get-time-of-day` |
| `sb-ext:gc-message` | 不存在 | `(room)`、`sb-ext:get-bytes-consed` |
| `sb-ext:describe-room` | 不存在 | `(room)` / `(room t)`（CL 标准） |
| `sb-ext:enable/disable-obsolete-feedback` | 不存在 | 用 `*compile-verbose*` / `*compile-print*` |
| `sb-di:find-frame-location` / `current-frame` | 不存在（且 sb-di 是内部接口） | `sb-di:top-frame` / `frame-up` / `frame-number` |
| `sb-sprof:prof` / `start-profiler` | 不存在 | `sb-sprof:start-profiling` / `stop-profiling` |
| `sb-sprof:sample-interval`（当函数用） | 是**变量** | `sb-sprof:*sample-interval*` |
| `sb-sprof:visualize` | 不存在 | `(sb-sprof:report :type :graph)` |
| `sb-alien:coerce-to-alien` | 不存在 | `sb-alien:extern-alien` + `alien-funcall` |
| `sb-cover:reset` | 不存在 | `sb-cover:reset-coverage` |
| `sb-posix:r_ok` | 名字带连字符 | `sb-posix:r-ok`（`w-ok` / `x-ok` / `f-ok` 同理） |
| `(sb-posix:mkdir "/tmp/x" 8.rwxrwxrwx)` | `8.rwxrwxrwx` 不是数字字面量，读入后只是个符号 | `#o755` |
| `(sb-ext:compile-file "x" :speed 3 ...)` | `compile-file` 没有这些参数 | `(declaim (optimize ...))` + `(compile-file "x")` |

其余 50 处 `sb-*:符号` 引用经探针逐个核对**全部成立**（`find-symbol` + `fboundp`）。

### 6. 并发与验证脚本的坑（本轮新增）

#### 6.1 多线程直接 `format` 会产出**非法 UTF-8**

一次 `format` 不是原子操作，它按格式指令拆成**多次写**：

```lisp
;; 线程 A 和 B 同时执行这一句
(format t "  任务 ~A 在线程 ~A 执行~%" id name)
;; 实际可能写出：
;;   任务   任务 2 在线程 在线程 pool-worker-0 执行pool-worker-1 执行
```

更麻烦的是多字节字符：SBCL 往 fd-stream 写汉字时会分块，两个线程各写走一半，
stdout 里就出现**非法 UTF-8 序列**。后果不只是"难看"——UTF-8 locale 下
toybox 的 `tr` 碰到非法序列会报 `tr: Illegal byte sequence` 并**截断输入**，
后面的判定全部落空（详见 6.3）。

正确做法：一把全局打印锁 + `finish-output`，所有输出（**包括主线程**，否则主线程
仍可能与 worker 的 `say` 穿插）都走它：

```lisp
(defvar *print-lock* (sb-thread:make-mutex :name "print-lock"))

(defun say (fmt &rest args)
  (sb-thread:with-mutex (*print-lock*)
    (apply #'format t fmt args)
    (finish-output)))     ; 只加锁不 flush 还不够：共享缓冲区仍可能被并发 flush 撕开
```

锁序不会死锁的前提是：`say` 里只持有打印锁、不再去拿别的锁。
所以其它锁 → 打印锁 的顺序是单向的，可以放心在持锁时打印。

另外，**别把线程对象直接 `~A` 出去**。`#<THREAD tid=4099 "worker-1" waiting on:
#<MUTEX "print-lock" ...>>` 里的 `tid` 每次运行都不同，线程此刻阻塞在哪个锁上也随时在变，
输出就不可重复了。要展示对象就取稳定的部分，比如 `(type-of thread)`。

#### 6.2 线程池：`shutdown` 不能只看标志位就退出

原版 worker 的循环是"看到 `shutdown` 就 `return`"。这样一旦 `shutdown` 置位，
**队列里还没跑的任务会被直接丢掉**（原代码靠 `(sleep 1)` 赌它们跑完了，慢机器上会少跑）。
正确写法是先取任务、取不到才退出：

```lisp
(loop
  (let ((task nil))
    (sb-thread:with-mutex ((thread-pool-lock pool))
      (loop while (and (null (thread-pool-task-queue pool))
                       (not (thread-pool-shutdown pool)))
            do (sb-thread:condition-wait (thread-pool-not-empty pool)
                                         (thread-pool-lock pool)))
      (setf task (pop (thread-pool-task-queue pool))))   ; 可能是 NIL
    (if task (funcall task) (return))))                  ; 没任务才退出
```

这样 `shutdown` 里直接 `join` 每个 worker 就够，**不需要 sleep**，
"提交 10 个 = 执行 10 个"也变成了确定的事实。

#### 6.3 判定脚本自己的 locale 坑（会**误报**，最难查）

用 `tr -d '\000'` 剔 NUL 再匹配结束标记时，`LC_ALL=C` **不能省**：

```bash
# 有 bug 的写法
text=$(tr -d '\000' < "$out")
# 正确写法
text=$(LC_ALL=C tr -d '\000' < "$out")
```

UTF-8 locale 下 `tr` 会做多字节校验，遇到非法 UTF-8 就报
`tr: Illegal byte sequence` 并**在那里截断输入**；结束标记若在截断点之后就查不到，
判定脚本会报"缺少结束标记"，于是同一个示例在不同入口下结论相反
（PowerShell 的 `UTF8.GetString(...).Contains(...)` 不受影响，它把非法字节变成替换字符）。

**教训**：判定脚本的健壮性和示例本身一样重要。用非 ASCII 模式做匹配、
用会做编码校验的工具处理待验证的输出时，先假定输入是"任意字节"。
`fortran/` 尤其要注意——触发格式重现时落盘的就是原始整数字节。

#### 6.4 括号总数平衡 ≠ 嵌套正确

改示例时漏一个 `)`、又在别处多一个 `)`，两处会互相抵消：数括号、看总数都正常，
但嵌套位置已经错了，表现为 `Error while parsing arguments to DEFMACRO PUSH:
too few elements in (...)` 这种莫名其妙的错。静态兜底：

```bash
sbcl --noinform --non-interactive --no-userinit \
  --eval '(compile-file "12-threads.lisp" :output-file "/tmp/c.fasl" :print nil :verbose nil)'
```

`compile-file` 会做宏展开，这类结构错位当场就报出来（而且信息比真跑时集中）。
注意它**不能替代真跑**——见本章第 0 节。

---

## 学习资源

### 书籍

- **Common Lisp: A Gentle Introduction to Symbolic Computation** - David S. Touretzky
- **Practical Common Lisp** - Peter Seibel
- **Land of Lisp** - Conrad Barski
- **Structure and Interpretation of Computer Programs** (使用 Scheme)

### 在线资源

- [CLHS (Common Lisp Hyperspec)](http://www.lispworks.com/documentation/HyperSpec/)
- [Lisp-lang.org](https://lisp-lang.org/)
- [Rosetta Code - Lisp](https://rosettacode.org/wiki/Category:Lisp)

### 社区

- #lisp on Libera Chat
- Reddit: r/lisp
- Stack Overflow: common-lisp tag

---

## 总结

Common Lisp 是一门功能强大且优雅的编程语言。它的核心特性包括：

1. **S表达式** - 简洁一致的语法
2. **宏系统** - 强大的元编程能力
3. **CLOS** - 功能完整的面向对象系统
4. **条件系统** - 先进的错误处理机制
5. **交互式开发** - REPL 驱动的开发体验

掌握Common Lisp不仅能够提升编程技能，更能深入理解编程语言的本质。
