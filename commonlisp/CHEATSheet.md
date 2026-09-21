# Common Lisp CHEATSheet（双实现版）

配 [README.md](README.md) 与 [docs/](docs/) 使用：正文 27 章讲「为什么」，
本页只放「查」。所有条目都在 **SBCL 2.6.8 + GNU CLISP 2.49.95** 实测过
（标注差异的地方除外）。

## 0. 命令速查

| 事 | SBCL | CLISP |
|---|---|---|
| REPL | `sbcl` | `clisp -E UTF-8` |
| 跑脚本（可复现） | `sbcl --noinform --non-interactive --no-userinit --load f.lisp` | `clisp -q -q -norc -E UTF-8 f.lisp` |
| shebang | `#!/usr/bin/env sbcl --script` | `#!/usr/bin/env clisp` |
| 退出 | `(sb-ext:quit)` | `(ext:quit)` / `(exit)` |
| 脚本参数 | `(cdr (member "--" sb-ext:*posix-argv* :test #'string=))` | `ext:*args*` |
| 编译文件 | `(compile-file "f.lisp")` | 同（clisp -c f.lisp） |
| 本仓库回归 | `./run-all.sh`（或 `pwsh ./build.ps1 -All`）——SBCL+CLISP 双通道 | 同左 |

**统一封装**（02/22 章）：

```lisp
(defun program-arguments ()
  #+sbcl (cdr (member "--" sb-ext:*posix-argv* :test #'string=))
  #+clisp ext:*args*
  #-(or sbcl clisp) nil)
```

## 1. 数值（04 章）

```lisp
(expt 2 100)          ; 任意精度整数            (/ 10 4)   ; => 5/2 有理数
(float pi 1.0d0)      ; π 归一到双精度（跨实现一致！）
(floor -7 2)          ; => -4, 1   向下         (truncate -7 2) ; => -3, -1 向零
(mod -7 2) → 1        ; mod 跟除数               (rem -7 2) → -1  ; rem 跟被除数
(round 2.5) → 2       ; 银行家舍入（五取偶）      (isqrt 17) → 4
(logand 12 10) → 8    (ash 1 10) → 1024         (gcd 12 18) → 6
```

- 浮点字面量**默认单精度**，要双精度写 `1.5d0`；
- 浮点别用 `=` 比，用容差；
- CLISP 差异：`pi` 是长浮点 `L0`；`(sqrt -4)` 给精确复数；浮点传染默认非 ANSI。

## 2. 字符与字符串（05 章）

```lisp
#\a #\Space #\Newline          (char-code #\a) → 97   (code-char 20013) → #\中
(string= "a" "A") → NIL        (string-equal "a" "A") → T
(string< "abc" "abd") → 2      ; 返回差异下标（广义布尔），不是 T
(subseq "hello" 0 4) → "hell"  (search "lo" "hello") → 3
(string-trim " " "  hi ") → "hi"
(concatenate 'string "a" "b")  (format nil "~A-~A" 1 2) → "1-2"
(parse-integer "42")           (parse-integer "ff" :radix 16) → 255
(length "你好") → 2            ; 按字符，不按 UTF-8 字节
```

坑：字面量字符串不可改（先 `copy-seq`）；`(eq "a" "a")` 未规定；
`#\Space` 的 `~S` 打印两实现不同（用 `char-name`）。

## 3. 列表（07 章）

```lisp
(cons 1 2) → (1 . 2)           (list 1 2 3)     (append '(1) '(2)) → (1 2)
(first l) (nth 2 l) (last l)   ; last 给尾部子表 (3)，不是 3
(nthcdr 2 l) (butlast l)       (push x s) (pop s) (pushnew x s)
(member 3 '(1 2 3)) → (3 …)    (assoc 'b '((a . 1) (b . 2))) → (b . 2)
(getf '(:a 1) :a) → 1          (subst 'x 'b '(a b)) → (A X)
(reverse l) / (nreverse l)     ; n 版必须接返回值！
(copy-list l) / (copy-tree l)  ; 浅 / 深
```

五种相等：`eq`（同一对象）/ `eql`（+同类型数字字符）/ `equal`（+结构、字符串）/
`equalp`（+大小写、向量、数字跨类型）/ `=`（只数字）。**字符串内容用 `equal`，
数字用 `=`，别用 `eq`。**

## 4. 向量与序列（08 章）

```lisp
#(1 2 3)                       (vector 1 2 3)
(make-array 5 :initial-element 0)
(make-array 0 :adjustable t :fill-pointer 0)   ; 动态向量
(vector-push-extend x v) (vector-pop v)
(aref v 1) (elt s 1)           ; elt 通吃序列，aref 只吃数组
(map 'vector #'1+ #(1 2))      (mapcar #'1+ '(1 2))
(sort (copy-list l) #'< :key #'name)   ; 破坏性！先拷贝再接返回值
(remove 2 l) / (delete 2 l)    ; n 版接返回值；delete 向量实现定义！
(reduce #'+ l) (find-if #'p l) (count-if #'p l)
(every #'p l) (some #'p l) (mismatch a b) (search sub seq)
(coerce '(1 2) 'vector)        ; 形态互转
```

坑：`remove-duplicates` 默认留**最后**一个（`:from-end t` 留第一个）；
`(reduce #'- '())` 报错（带 `:initial-value`）；多序列 map 取最短。

## 5. 哈希表与结构体（09 章）

```lisp
(setf (gethash k ht) v)
(multiple-value-bind (v found) (gethash k ht) ...)   ; found 区分「存了 nil」
(incf (gethash w table 0))     ; 计数模式
(remhash k ht) (clrhash ht) (hash-table-count ht)
(make-hash-table :test 'equal) ; 字符串键必须！默认 eql
```

**遍历顺序不确定**——输出前排序：

```lisp
(sort (loop for k being each hash-key of ht collect k) #'string<
      :key (lambda (k) (format nil "~A" k)))
```

```lisp
(defstruct person name (age 0))
(make-person :name "a") (person-name p) (setf (person-age p) 1)
(person-p p) (copy-person p)     ; 打印 #S(PERSON …)；equalp 按内容比
(defstruct (student (:include person)) school)
```

## 6. 变量与作用域（10 章）

```lisp
(defparameter *x* 1)   ; 重载重置    (defvar *x* 1)   ; 重载保留
(defconstant +x+ 1)    ; 不可 setf
(let ((a 1) (b 2)) …)  ; 并行绑定（可交换）  (let* ((a 1) (b (+ a 1))) …)  ; 顺序
(let ((*print-case* :downcase)) …)   ; 动态重绑配置（特殊变量 *耳罩*）
(setf x 1) (incf x) (push x l) (rotatef a b) (shiftf a b c)
```

词法闭包：`(let ((n 0)) (lambda () (incf n)))`；特殊变量沿**调用链**生效。

## 7. 函数（11 章）

```lisp
(defun f (a &optional (b 1 b-p) &rest r &key (k 2) &allow-other-keys) …)
(funcall f 1) (apply f 1 '(2))     ; apply 尾参必须是列表！
#'car ≡ (function car)             ; 变量存函数调用必须 funcall
(values 1 2) (multiple-value-bind (a b) … ) (nth-value 1 …)
(multiple-value-list (floor 7 2)) → (3 1)
(labels ((f …)) …)   ; 可递归互调    (flet ((f …)) …)  ; 互相不可见，遮蔽用
```

坑：`&optional` 与 `&key` 混用被 SBCL 劝退；深递归改 loop（CLISP ≈5000 层爆栈）。

## 8. 控制流（12 章）

```lisp
(if c a b) (when c …) (unless c …)
(cond (test …) (t …))
(case k ((1 2) :small) (otherwise :big))   ; eql——字符串匹配不上！
(ecase …) (etypecase …)                    ; 无匹配报错（比静默 NIL 安全）
(and 1 2) → 2    (or nil 3) → 3            ; 返回值，不只真假
(dotimes (i 5) …) (dolist (x l :done) …)
(loop for i from 1 to 10 by 2
      for x in '(a b)
      when (evenp i) collect i into evens
      sum i into total
      finally (return (list evens total)))
(block name (return-from name v))   ; defun 自带同名块
(catch 'tag (throw 'tag v))         ; 跨函数跳
(unwind-protect body cleanup)       ; try/finally
```

## 9. 类型（13 章）

```lisp
(typep x 'integer)  (typep x '(integer 0 100))  (typep x '(satisfies evenp))
(subtypep 'fixnum 'integer) → T
(check-type x integer)   ; 运行期检查（报 type-error）
(the fixnum e)           ; 编译期承诺（错了自担）
(deftype name-list () `(satisfies pred))   ; (list integer) 不合法！
```

## 10. 宏（14/15 章）

```lisp
(defmacro m (arg &body body) `(let ((x ,arg)) ,@body))
(macroexpand-1 '(m 1))          ; 调试第一工具（只展开自己的宏）
(gensym "TMP")                  ; 卫生临时符号（编号别进输出）
(my-with-gensyms (tmp) …)       ; 手写；实用直接用 alexandria:with-gensyms
(symbol-macrolet ((x (gethash k ht))) (incf x))
```

写宏三查：展开对不对 / 用户表达式算几次（once-only）/ 临时名撞不撞（gensym）。

## 11. format（16 章）

```lisp
(format nil "~A ~S" "s" "s")   ; s "s"     nil=拼串
~D ~B ~O ~X ~R ~:R ~@R         ; 十进制…罗马（~R 只收整数）
~,2F ~E ~$ ~3$                 ; 小数/科学/货币（跨实现用 d0 输入）
~10D（右对齐）~10A（左对齐）~10,'0D（补零）  ; 方向相反！
~% 换行  ~& 需要才换行  ~T 跳列  ~~ 波浪号
~{~A~^, ~}                     ; 列表逗号分隔（万能）
~[a~;b~:;else~] ~:[假~;真~]    ; 条件
~* 跳参 ~:* 回退   ~(全小写~) ~@(每词首大~) ~:(句式~) ~:@(全大写~)
```

三大坑：`~|` 是**换页**不是竖线；想打 `~A` 要写 `~~A`；`~-10D` 非法（mincol≥0）。

## 12. 文件与流（17 章）

```lisp
(with-open-file (out "f" :direction :output :if-exists :supersede) (format out …))
(with-open-file (in "f") (loop for line = (read-line in nil :eof)
                                until (eq line :eof) collect line))
(with-output-to-string (s) …)    (with-input-from-string (s "1 2") (read s))
(with-open-file (i "f" :element-type '(unsigned-byte 8)) (read-byte i))
(read-sequence buf in)           ; 接返回值截断（file-length 是字节数！）
(pathname-name p) (namestring p) (merge-pathnames "a.txt" base)
(probe-file f) (ensure-directories-exist "d/") (directory "d/*.*")
(rename-file old "newname")      ; 第二参只给文件名！（带目录会被拼两遍）
```

## 13. 条件系统（18 章）

```lisp
(error "…") (error 'type-error :datum x :expected-type 'list)
(warn "…")                        ; → stderr；绑 *error-output* 改道
(handler-case body (type (e) …) (:no-error (v &rest r) …))
(handler-bind ((type (lambda (e) (invoke-restart 'use-default))))
  body)                           ; 栈不展开，能选 restart 继续
(define-condition my (error) ((x :reader my-x)) (:report (c s) …))
(restart-case body (skip () …) (retry (v) :interactive (lambda () (list v)) …))
(ignore-errors body)              ; 两值：结果/条件
(check-type …) (assert …) (cerror "继续" "…")
```

坑：handler-bind 的处理器**返回值不算处理**；报错文本是实现细节（打印
`symbol-name`/`type-error-expected-type` 这类结构化字段）；带参 restart
配 `:interactive`（CLISP 强制）。

## 14. CLOS（19/20 章）

```lisp
(defclass c () ((x :initarg :x :initform 0 :accessor c-x :reader c-r)))
(make-instance 'c :x 1) (slot-value o 'x) (with-slots (x) o …)
(defgeneric f (a)) (defmethod f ((a c)) …)
(defmethod f :before / :after / :around ((a c)) (call-next-method))
(defmethod f ((m (eql :admin)) r) …)            ; 按值分派
(defgeneric g (x) (:method-combination +))      ; +/and/or/list/max…
(defmethod print-object ((o c) stream) (print-unreadable-object (o stream :type t) …))
(defmethod initialize-instance :after ((o c) &key) …)
(class-of o) (find-class 'c nil) (typep o 'c)
```

顺序：around → before（具体→泛）→ primary（最具体）→ after（泛→具体）。

## 15. SBCL 专属（23–26 章）

```lisp
(sb-ext:posix-getenv "HOME")      (sb-ext:gc) (sb-ext:get-bytes-consed)
(sb-ext:run-program "/bin/sh" '("-c" cmd) :output :stream :search nil)
(sb-ext:save-lisp-and-die "app" :toplevel #'main :executable t)  ; 不返回！
(sb-thread:make-thread (lambda () …)) (sb-thread:join-thread th)
(sb-thread:with-mutex (lock) …)   (sb-ext:atomic-incf slot)
(sb-alien:define-alien-routine ("strlen" c-strlen) long (s c-string))
(declaim (optimize (speed 3) (safety 1)))   (disassemble #'f)
```

核心 vs contrib：`SB-EXT/SB-THREAD/SB-ALIEN/SB-PROFILE` 在核心（require 反而报错）；
`SB-POSIX/SB-SPROF/SB-BSD-SOCKETS` 要 require。

## 16. 双实现差异总账（22 章详表，速查版）

| # | 差异 | 抹平写法 |
|---|---|---|
| 1 | fixnum 62 vs 48 位 | 不依赖位宽 |
| 2 | pi `d0` vs `L0` | `(float pi 1.0d0)` |
| 3 | 浮点传染 ANSI vs 非 ANSI | 显式后缀/float 归一 |
| 4 | `(sqrt -4)` 浮点 vs 精确 | 浮点输入 |
| 5 | `#\Space` 打印 | `(char-name #\Space)` |
| 6 | `type-of` 字符串形态 | 用 `typep` |
| 7 | 内置宏展开形态 | 只展开自己的宏 |
| 8 | `''x` 打印与 pretty | 打印代码统一绑 pretty |
| 9 | `~E` 指数标记 | `d0` 输入 |
| 10 | `~T` CJK 列宽 | ASCII / `~A` 定宽 |
| 11 | `~A` 含换行字符串断行 | 换行显式 `~%` |
| 12 | `delete` 定长向量 | remove / fill-pointer |
| 13 | read-from-string 第二值差 1 | 不做逻辑 |
| 14 | TCO 完整 vs ≈5000 层 | 深递归改 loop |
| 15 | 广义布尔（fboundp 返回函数） | `(if x t nil)` 归一 |
| 16 | 条件类名包前缀 | `(symbol-name …)` |
| 17 | 报错文本 | 结构化字段/自己写文案 |
| 18 | CL 包锁严 vs 松 | 别碰 CL 名字 |
| 19 | 追加方法到已调用泛型 | 定义先于调用 |
| 20 | 带参 restart 要 :interactive | 都配上 |
| 21 | :no-error 要接全部返回值 | `(v &rest r)` |
| 22 | find-class 未知类行为 | `(find-class x nil)` |
| 23 | directory 匹配子目录 | `remove-if-not #'pathname-name` |
| 24 | 编译期诊断强度 | 代码零警告 |
| 25 | ASDF 内置 vs 不带 | SBCL 演示/CLISP 自装 |
| 26 | 启动参数 | 速查表第 0 节 |
| 27 | 默认编码 | CLISP 加 `-E UTF-8` |

## 17. 报错速查（症状 → 原因 → 章）

| 报错/症状 | 原因 | 章 |
|---|---|---|
| `The variable A is unbound` | let 并行绑定引用同层 | 10 |
| `undefined function: COMMON-LISP-USER::FOO` | 拼错/前向引用/函数格未定义 | 03 |
| `X is not of type LIST` | car/cdr 收到非表 | 03 |
| `Package FOO does not exist` | 读到了不存在的包（读取期！） | 06 |
| `Lock on package COMMON-LISP violated` | 重定义/flet 遮蔽 CL 名 | 06 |
| `DESCRIBE already names an ordinary function` | defgeneric 标准函数名 | 19 |
| `division by zero`（编译期警告） | 字面量除零被 SBCL 静态发现 | 18 |
| `The assertion (…) failed` | assert | 18 |
| `junk in string` | parse-integer 非数字 | 05 |
| `Too few arguments to FORMAT` | 格式串指令多于实参（或想打 `~A` 没转义） | 16 |
| `The value of mincol is -10` | `~-10D` 非法 | 16 |
| `end of file on stream` | read-line/read 没给 EOF 参数 | 17 |
| `couldn't rename … 目录/目录/…` | rename-file 第二参带了相对目录 | 17 |
| `There is no applicable method` | 泛型没匹配参数类型 | 19 |
| `Recursive lock attempt` | grab-mutex 不可重入 | 24 |
| `Control stack exhausted` | 深递归超栈（CLISP 更早） | 11 |
| `Heap exhausted, game over` | 无界 loop（**不可捕获**，进程死） | 12 |
| `Invalid byte #xE4 in CHARSET:ASCII` | CLISP 没加 `-E UTF-8` | 01 |
| `dotted argument list given to …` | apply 尾参不是列表 | 11 |
| `The macro X was found as the argument to FUNCTION` | 宏不能 funcall | 14 |
| `#\Page`/控制字符混进输出 | `~\|` 当竖线用了 | 16 |
| NUL 字节漏进输出 | file-length 按字节分配字符串 | 17 |
| 非法 UTF-8 混进输出 | 多线程无锁 format | 24 |
| `&OPTIONAL and &KEY found in the same lambda list` | SBCL 劝退混用 | 11 |
| `illegal keyword/value pair` | 有 &key 就校验多余键 | 11 |
| LOOP: FOR clauses should occur before main body | CLISP 对 loop 子句顺序 | 12 |

## 18. 常用库速查（21 章）

alexandria（工具）、serapeum（更多工具）、bordeaux-threads（可移植线程）、
cffi（可移植 FFI）、cl-ppcre（正则）、split-sequence（切割）、iterate（迭代）、
trivia（模式匹配）、fiveam（测试）、hunchentoot/clack（Web）、drakma（HTTP）、
cl-json/yason（JSON）、postmodern（PostgreSQL）、local-time（时间）、
uiop（随 ASDF，跨实现平台操作）。
