# 35 · 超越 ANSI：SBCL 精选扩展（二）

> 第 23 章已经覆盖了 `sb-ext` 里最常用的扩展（`save-lisp-and-die`、`exit`、
> `*posix-argv*` 等），第 24/25/26 章分别讲了线程、FFI、性能。本章继续
> 挖掘手册第 7 章「Beyond the ANSI Standard」、第 12 章「Package Locks」
> 和第 14 章「Timers」里的干货：读取器扩展、包局部昵称、包锁、终结器与弱指针、
> 哈希表扩展、超时与截止时间、定时器、`run-program`、Unicode 支持、泛函分发
> 扩展，以及一批好用的杂项。
>
> 配套例程：[`examples/35_beyond_ansi/`](../examples/35_beyond_ansi/main.lisp)（channel: sbcl）
>
> 与前面各章一样，本章**自包含**：手册对应小节的核心内容全部在正文里
> 讲清楚，包括每个行为边界上实测得到的输出。

## 35.1 读取器扩展：包前缀、有理数十进制、Unicode 字符

SBCL 给读取器加了三个 ANSI 没有的便利语法。

**扩展包前缀**。`<包>::<形式>` 让读取器把形式里的符号 intern 到指定包，
而不是当前的 `*package*`：

```lisp
(equal 'sb-ext::(gc exit) '(sb-ext::gc sb-ext::exit)) ; => T
```

左边列表里的两个符号都被读进了 `sb-ext` 包——适合在宏展开或数据文件
里成批引用别的包的符号。注意读的过程中 `*package*` **不会**被重绑，
所以如果目标包有包锁（见 35.3），`foo::(bar)` 和 `foo::bar` 一样会
在读期违规。

**有理数十进制语法**。指数标记写成 `r` 或 `R` 时，带浮点语法外观的数
会被读成**精确有理数**而不是浮点数：

```lisp
(read-from-string "1.5r0") ; => 3/2
(let ((*read-default-float-format* 'rational))
  (read-from-string "1.25")) ; => 5/4
```

第二行把 `*read-default-float-format*` 绑成 `rational` 之后，连不带
指数标记的 `1.25` 也读成 `5/4`。这是做金融计算时避免二进制浮点误差
的一条捷径：数据文件原样读进来就是精确值。这个变量为 `rational` 时
浮点数打印会带上指数标记（保持可读回），有理数则照常用标准语法打印。

**Unicode 字符名与正规化**。字符字面量可以直接写码点：

```lisp
#\u00e1 ; => #\LATIN_SMALL_LETTER_A_WITH_ACUTE
```

`#\u` 后跟十六进制码点（`#\ue1`、`#\u+00e1` 也行）。另外在启用
Unicode 的构建里，读取器会把所有符号名正规化到 NFKC；
`sb-ext:readtable-normalization` 查询或关闭这个行为——用 `intern`
程序化创建的符号不受影响，但打印时未正规化的符号会被转义，保证
print-read 一致。

## 35.2 包局部昵称（package-local nicknames）

普通包昵称是全局的：两个库都想叫 `json` 就冲突了。SBCL 的**包局部
昵称**只在定义它的包内部有效——你可以在自己的包里把
`com.example.very-long-package-name` 简称成 `ex`，别的包完全看不见，
` *features*` 里有 `:package-local-nicknames` 表示支持。

`defpackage` 增加 `:local-nicknames` 选项，每项是
`(局部昵称 实际包)`。下面这个例子（手册原例）里，`:quux` 包内
`bar` 指的是 `foo` 包，而为了还能碰到真正的 `bar` 包，又给它加了
局部昵称 `b`：

```lisp
(defpackage :bar35 (:intern "X"))
(defpackage :foo35 (:intern "X"))
(defpackage :quux35 (:use :cl)
  (:local-nicknames (:bar :foo35) (:b :bar35)))
(let ((*package* (find-package :quux35)))
  (find-symbol "X" :bar)) ; => FOO35::X
(let ((*package* (find-package :quux35)))
  (find-symbol "X" :b)) ; => BAR35::X
```

断言值是 `find-symbol` 的主返回值（第二值是 `:internal`/`:external`
状态）。在 `:quux35` 包内，`find-package "bar"` 返回的是 `foo35`
包——包括**读取器**在 `bar:x` 语法里隐式做的 `find-package`，所以
源码里直接写 `bar:x` 也行；打印符号时也会用局部昵称做包前缀，保证
读回来还是同一个符号。

程序化 API 是这四个：

```text
(sb-ext:package-local-nicknames 包)         ; 查：返回 (昵称 . 包) 的 alist
(sb-ext:package-locally-nicknamed-by-list 包); 反查：哪些包给这个包起了昵称
(sb-ext:add-package-local-nickname 昵称 包 &optional 所在包)
(sb-ext:remove-package-local-nickname 昵称 &optional 所在包)
```

`add-package-local-nickname` 在昵称已被占用、是 `"CL"`/`"KEYWORD"`
这类保留名、或与所在包自身的全局名冲突时，signal 一个**可继续**的
错误。

## 35.3 包锁：防止误改的护栏

`common-lisp` 包和 SBCL 内部包（含 `sb-ext`）默认**上锁**：你不能在
外面重定义它们的符号、往里面 intern 新符号。SBCL 把这套机制开放给
用户包——手册明确定位它不是安全机制，而是「防手滑」护栏：`defpackage`
加 `(:lock t)`，或用 `sb-ext:lock-package` / `sb-ext:unlock-package`
开关，`sb-ext:package-locked-p` 查询。

违规分两类，报的条件类型不同（都是 `sb-ext:package-lock-violation`
的子类，而它是 `package-error` 的子类）：

- **包级操作**（shadow/import/unintern/export/rename/delete-package、
  增删局部昵称、**intern 新符号**……）→ `sb-ext:package-locked-error`；
- **符号级操作**（defun/defvar 重定义、设为方法组合类型、
  `(setf find-class)`、`define-hash-table-test`……）→
  `sb-ext:symbol-package-locked-error`，用
  `sb-ext:package-locked-error-symbol` 取出涉事符号。

```lisp
(defpackage :lock35 (:use) (:export "FOO") (:lock t))
(sb-ext:package-locked-p :lock35) ; => T
(handler-case (intern "NEW" :lock35)
  (sb-ext:package-locked-error () :PKG-LOCKED)) ; => :PKG-LOCKED
(handler-case (eval '(defun lock35:foo () 1))
  (sb-ext:symbol-package-locked-error (e)
    (sb-ext:package-locked-error-symbol e))) ; => LOCK35:FOO
```

第二个断言顺手演示了一个细节：包锁错误是**可继续**的
（continuable），交互式调试器里有一个「Ignore the package lock」
restart——库作者故意要 patch 别人的包时点它就行。

合法的修改通道有两条。其一是**实现包**（implementation packages）：
锁包只能被它的实现包修改；默认每个包是自己的唯一实现包，所以把
`*package*` 切进锁包内部再改是合法的。库作者可以用
`sb-ext:add-implementation-package` 把 `foo-impl` 之类的包加进
`foo` 的实现包列表（`defpackage` 的 `(:implement ...)` 选项等价），
把「公开接口锁死、内部包可改」落成结构。其二是动态绕过：

```lisp
(sb-ext:with-unlocked-packages (:lock35)
  (intern "NEW" :lock35)) ; => LOCK35::NEW
(sb-ext:without-package-locks
  (eval '(defun lock35:foo () 1))) ; => LOCK35:FOO
```

`with-unlocked-packages` 在动态范围内解锁指定包；
`without-package-locks` 无视运行期的一切包锁违规（`defun` 返回符号
名，所以断言值是 `LOCK35:FOO`）。

还有一对编译期开关：词法绑定/声明（`let`、`flet`、`labels`、
`macrolet`、`symbol-macrolet`、`declare`）撞上包锁时是**编译期警告 +
运行期 `program-error`**，可以用声明
`(declare (sb-ext:disable-package-locks locked:foo))` 在词法范围内
关掉、`sb-ext:enable-package-locks` 再打开——手册给的典型场景是宏
展开里要临时 `flet` 一个锁包符号。

最后注意编译代码的语义：编译时和运行/加载时包锁状态不一致，行为
未指定（实践中只要不真违规就没有性能损失）；但加载含 interned
符号的 fasl 不会因为缺符号而误报违规。

## 35.4 终结器、弱指针与 GC 内省

SBCL 的分代 GC 提供了一组 ANSI 之外的管理接口。

**手动 GC 与钩子**：`(sb-ext:gc)` 触发新生代（nursery）收集，
`(sb-ext:gc :full t)` 全代收集；`sb-ext:*after-gc-hooks*` 里的函数
在每次 GC 后被调用（线程退出触发的 GC 除外；多线程下钩子可能在
任意线程跑）。

**终结器**（finalizer）：对象被回收后执行一段代码，典型用途是释放
Lisp 对象关联的外部资源（如 FFI 句柄）。

```lisp
(defvar *fin35* nil)
(defun fin35 ()
  ;; 创建收进函数：返回后对象彻底失去引用，GC 才可能认定它死亡
  (sb-ext:finalize (list :temp) (lambda () (setf *fin35* :RAN)))
  t)
(progn (fin35)
       (sb-ext:gc :full t)
       (sb-ext:wait-for (eq *fin35* :RAN)
                        :timeout 5)) ; => T
```

这里必须用 `sb-ext:wait-for` 轮询（详见 35.6）而不是 GC 后立刻检查，
原因正是终结器最重要的语义：**它的执行是异步的**。手册原话——多线程
环境下 function **可能在任意线程**、任意动态作用域被调用；SBCL 用一条
专门的终结器线程跑它们。于是：

- 终结器**不在**发现死亡的那次 GC 里同步执行；
- 从 `gc` 返回到终结器落地之间没有任何顺序保证——「GC 后马上读
  变量还没变」这类断言是竞态，同一份代码时灵时不灵；
- 测试/演示只能等它落地（轮询 + 超时），或断言「取消后永远不跑」。

对比另外两种「弱」设施，时序恰好排成谱系：

- **弱指针**（下文）：在发现死亡的**当轮 GC** 即失效——确定性；
- **终结器**：死亡被发现后**异步**执行，任意线程——时点无保证；
- **弱哈希条目**（35.5）：GC 移除死条目，但要一次表访问 + 再一轮
  GC 才观察得到。

还有一个隐含前提：「发现死亡」要求对象真正失去所有引用——编译
代码的栈帧和寄存器可能残留最后一个引用，所以上面把创建收进
`fin35`，函数返回后再 GC。另外两个 API：`sb-ext:cancel-finalization`
取消对象的全部终结器（返回是否曾有终结器）；`finalize` 的
`:dont-save t` 让终结器在 `save-lisp-and-die` 时注销（释放系统内存的
终结器必须加，否则新镜像启动后会拿着旧镜像的地址乱调）。取消是
立刻生效的——被取消的终结器永远不跑，这个「负断言」反而是确定性
的，可以放心写进测试：

```lisp
(defvar *cfin35* nil)
(defun cfin35 ()
  (let ((obj (list :temp)))
    (sb-ext:finalize obj (lambda () (setf *cfin35* :RAN)))
    obj))
(let ((obj (cfin35)))
  (sb-ext:cancel-finalization obj)          ; 曾有终结器
  (progn (sb-ext:gc :full t)
         (sb-ext:wait-for (eq *cfin35* :RAN)
                          :timeout 0.2))) ; => NIL
```

终结器有两个经典坑，手册用了三个例子反复强调（这里自包含复述）：

```text
;;; 好：闭包只引用 handle，不引用 object 本身
(let* ((handle (get-handle))
       (object (make-object handle)))
  (finalize object (lambda () (release-handle handle)))
  object)

;;; 坏：闭包引用了 object —— 终结器自己把对象拴住了，永远不回收！
(finalize object (lambda () (release-handle (object-handle object))))

;;; 坏：终结器不可重入。它可能在任何线程、任何动态作用域里跑；
;;; 它抛的错误会被接住并降级成一个 warning。
```

**弱指针**：`sb-ext:make-weak-pointer` 建立的引用不阻止对象被回收，
`sb-ext:weak-pointer-value` 返回两值——对象还活着是 `(对象 T)`，
已回收是 `(NIL NIL)`：

```lisp
(let ((wp (sb-ext:make-weak-pointer (list :temp))))
  (multiple-value-list (sb-ext:weak-pointer-value wp))) ; => ((:TEMP) T)
(defun wp35 () (sb-ext:make-weak-pointer (list :temp)))
(let ((wp (wp35)))
  (sb-ext:gc :full t)
  (multiple-value-list (sb-ext:weak-pointer-value wp))) ; => (NIL NIL)
```

对比终结器可以看到：弱指针在发现死亡的**当轮** GC 就失效（弱引用
检查是标记阶段的一部分），终结器则是异步跑、时点无保证。弱指针是
手写缓存的基础，不过多数情况下直接用 35.5 的弱哈希表更方便。

**GC 内省与调参**（全部 `sb-ext`）：`*gc-run-time*` /
`*gc-real-time*` 是 GC 累计耗费的 CPU / 墙钟时间（可以绑零来测量
某段代码的 GC 开销）；`get-bytes-consed` 返回启动以来的总分配字节数；
`bytes-consed-between-gcs` 是新生代大小（可 `setf` 调大减少 GC
频率，默认动态空间的 5%，save core 后不保留）；`dynamic-space-size`
返回动态空间总字节数。GENCGC 各代的 `generation-average-age`、
`generation-number-of-gcs-before-promotion` 等调参旋钮都是实验性
接口，常规调优只动新生代大小就够了。还有一个专家级的
`sb-ext:search-roots`：给它一组弱指针，它反向搜索引用链，报告
「是谁把对象拴在内存里」——排查内存泄漏的最后一招，接口同样是
实验性的。

```lisp
(integerp (sb-ext:get-bytes-consed)) ; => T
(integerp (sb-ext:dynamic-space-size)) ; => T
```

## 35.5 哈希表扩展：弱条目、自定义测试、同步

`make-hash-table` 在 SBCL 里多收三个关键字：`:weakness`、
`:hash-function`、`:synchronized`。

**:weakness** 让 GC 可以清除条目，取值语义（手册原文，一字不差地
自包含复述）：`:key` —— 键活着才保证条目保留；`:value` —— 值活着
才保留；`:key-and-value` —— 两者都活着才保留；`:key-or-value` ——
任一方活着就保留；`nil`（默认）—— 永远保留。做「对象 → 附加信息」
的关联表时用 `:weakness :key`，对象死了条目自动消失，不会泄漏：

```lisp
(defun wh35 ()
  (let ((ht (make-hash-table :weakness :key :test #'eq)))
    (setf (gethash (cons nil nil) ht) :v)   ; 键除了表没人引用
    ht))
(let ((ht (wh35)))
  (sb-ext:gc :full t)            ; 第一轮：键死亡被发现
  (gethash (cons nil nil) ht)    ; 中间夹一次表访问
  (sb-ext:gc :full t)            ; 第二轮：条目被清掉
  (hash-table-count ht)) ; => 0
(sb-ext:hash-table-weakness (make-hash-table :weakness :value)) ; => :VALUE
```

手册的承诺很简单——GC 自动移除死条目；但**什么时候在你眼前可见**受
两件事影响，写测试前必须知道（上面三明治式的 gc → 访问 → gc 正是为
此）：

- **对象要真死**。SBCL 对栈和寄存器的扫描是保守式的：创建对象的
  调用留下的残留比特会被当成活引用，把对象钉住——背靠背多轮 GC
  也清不掉，键/值一直活着。把创建收进函数、中间做一次别的调用，
  都是在冲掉这些残留。
- **表的清理有延迟**。条目从「值死了」到「count 降下来」通常要
  一次表访问加一轮 GC 才观察得到；GC 后立刻读 count 常常还是旧值。

对比弱指针就省心得多：没有这些观察陷阱，键值真死后当轮 GC 即失效。

**:hash-function** 与**自定义测试**。`:test` 除了标准的
`eq/eql/equal/equalp`，还接受任何用 `sb-ext:define-hash-table-test`
注册过的两参数等价谓词；如果连谓词都是临时的，就得同时显式给
`:hash-function`。手册自带的经典例子是让哈希表按**数值相等**比较
键（`1` 和 `1.0` 是同一个键，`equal`/`equalp` 都做不到前者）：

```lisp
(defun ==35 (x y) (= x y))
(sb-ext:define-hash-table-test ==35
  (lambda (x)
    ;; 哈希码必须与测试一致：(= 1 1.0) 成立，
    ;; 所以不能 (sxhash x) —— 1 和 1.0 的 sxhash 不同
    (sxhash (coerce x 'double-float))))
(let ((ht (make-hash-table :test '==35)))
  (setf (gethash 1 ht) :one)
  (gethash 1.0 ht)) ; => :ONE
(hash-table-test (make-hash-table :test '==35)) ; => ==35
```

注释里那条约束是硬性的：**凡是被测试判等的对象，哈希函数必须给出
相同哈希码**，且对同一对象的多次调用必须稳定（例子里不处理复数和
超大 bignum，生产代码要补）。

**:synchronized** 见第 24 章——`make-hash-table :synchronized t`
让所有并发访问安全；`sb-ext:with-locked-hash-table` 把一段 body
里的复合操作（查-改-写）包成原子；`sb-ext:hash-table-synchronized-p`
查询。

## 35.6 超时与截止时间

SBCL 提供三种限制执行时间的方式，强度递增、安全性递减。

**超时参数**：线程同步原语（`join-thread`、`grab-mutex`、
`condition-wait`、`wait-on-semaphore`……）都收 `:timeout`，到期
要么正常返回超时标志（如 `join-thread` 第二值 `:timeout`），要么
signal 专门条件。还有一个通用的等待宏：

```lisp
(sb-ext:wait-for nil :timeout 0.1) ; => NIL
```

`sb-ext:wait-for` 反复求值测试式直到为真并返回其主值；给
`:timeout` 就最多等这么久返回 `nil`（实验性接口）。

**截止时间**（synchronous timeout / deadline）：`sb-sys:with-deadline`
给一段动态范围设死线，范围内所有「尊重死线的阻塞操作」（`sleep`、
阻塞 IO、`get-mutex`、`condition-wait`、`run-program` 的等待……）
到期时 signal `sb-sys:deadline-timeout`——它不是粗暴打断，而是在
下一个阻塞点以普通条件的方式出现，所以是安全的：

```lisp
(handler-case (sb-sys:with-deadline (:seconds 0.2) (sleep 5) :done)
  (sb-sys:deadline-timeout () :DEADLINE)) ; => :DEADLINE
```

handler 里可以用两个 restart 恢复被中断的操作：
`sb-sys:defer-deadline` 把死线顺延若干秒，`sb-sys:cancel-deadline`
直接取消——两者都接受可选的条件参数并返回是否找到了对应 restart：

```lisp
(handler-case
    (sb-sys:with-deadline (:seconds 0.1)
      (handler-bind ((sb-sys:deadline-timeout
                       (lambda (c) (sb-sys:defer-deadline 0.5 c))))
        (sleep 0.2)   ; 0.1 秒时到期，被顺延 0.5 秒，睡满 0.2 正常结束
        :slept))
  (sb-sys:deadline-timeout () :DEADLINE)) ; => :SLEPT
```

嵌套 `with-deadline` 生效的是**最先到期**的那个；除非内层给
`:override t`，否则内层只能收紧不能放宽。死线是**每线程**的，
子线程不受父线程死线影响。线程在调试器里时死线超时会被推迟到
退出调试器后再 signal。

**异步超时**：`sb-ext:with-timeout` 到点就以异步条件
`sb-ext:timeout` 打断 body，几乎任何位置都可能被中断——最强也最
危险：

```lisp
(handler-case (sb-ext:with-timeout 0.2 (sleep 5) :done)
  (sb-ext:timeout () :TIMED-OUT)) ; => :TIMED-OUT
```

危险在哪？手册给的例子值得背下来（自包含复述）：异步条件下
**没有任何 unwind 是安全的**——

```text
(defun call-with-foo (function)
  (let (foo)
    (unwind-protect
         (progn
           (setf foo (get-foo))
           (funcall function foo))
      (when foo
        (release-foo foo)))))
```

如果超时正好打在 `get-foo` 执行完、`setf` 还没赋值之间，
`release-foo` 就永远错过了。单个这样的点可以防御，但 unwind 路径
上的每一帧（包括 SBCL 内部代码）都得防御，实际上等于把整个系统
变成不可中断。结论：**优先用超时参数和死线；`with-timeout` 只包住
你自己完全掌控、不持有外部资源的纯计算**。

## 35.7 定时器：`make-timer` 与 `schedule-timer`

SBCL 内置了一个系统级事件调度器（底层用 `setitimer(2)`），不需要单独
的调度线程，也能在线程环境里正常工作。三个核心函数（全在 `sb-ext`
包）：

- `make-timer` 创建定时器；
- `schedule-timer` 安排触发时刻；
- `unschedule-timer` 取消。

**创建**。`make-timer` 的第一个参数是触发时调用的函数，关键字 `:name`
给定时器起名（调试用），`:thread` 控制在哪个线程里跑回调：

```lisp
(sb-ext:make-timer (lambda () (format t "叮~%")) :name "闹钟")
```

`:thread` 三档取值：

| 值 | 行为 |
|---|---|
| `sb-thread:*current-thread*`（默认） | 在创建定时器的那个线程里跑回调 |
| `t` | 每次触发时新建一个线程跑 |
| `nil` | 在一个未指定的线程里跑（适合不关心上下文的后台任务） |

**调度**。`schedule-timer` 的第二个参数是时间——默认是「从现在起多少
秒」（浮点数或整数都行），加 `:absolute-p t` 就变成 universal time
（`get-universal-time` 那种绝对时间戳）：

```lisp
(let ((timer (sb-ext:make-timer (lambda () (setf *ran* t)))))
  (sb-ext:schedule-timer timer 0.5)    ; 0.5 秒后触发
  (sb-ext:timer-scheduled-p timer))    ; => T（还没触发）
```

`:repeat-interval` 让定时器周期性触发——一次 schedule、反复运行：

```lisp
(let ((timer (sb-ext:make-timer (lambda () nil))))
  (sb-ext:schedule-timer timer 1.0 :repeat-interval 0.5) ; 1 秒后首次，之后每 0.5 秒
  (prog1 (sb-ext:timer-scheduled-p timer)
    (sb-ext:unschedule-timer timer)))  ; => T
```

周期定时器还有个 `:catch-up` 参数：系统挂起恢复后如果错过了若干次
触发，`catch-up t` 会立刻连续补跑（不加延迟），`nil`（默认）就跳过
错过的那些。

**查询与取消**。`timer-scheduled-p` 查定时器是否还在等待触发（给
`:delta` 秒数就查「从现在起 delta 秒后是否还会触发」——对周期定时器
恒返回真）；`unschedule-timer` 取消定时器，**返回后保证不会再触发、
也没有未完成的回调**；`list-all-timers` 列出系统里全部定时器；
`timer-name` 取名字。

```lisp
(let ((timer (sb-ext:make-timer (lambda () nil) :name "t1")))
  (sb-ext:schedule-timer timer 10)
  (list (sb-ext:timer-name timer)
        (sb-ext:timer-scheduled-p timer)
        (progn (sb-ext:unschedule-timer timer)
               (sb-ext:timer-scheduled-p timer)))) ; => ("t1" T NIL)
```

**回调函数的动态环境不可靠**。这是手册反复强调的坑：定时器回调跑在
哪个动态作用域里，取决于触发那一刻恰好轮到谁——动态变量绑定、持有
的锁、`*default-pathname-defaults*` 之类的上下文全是随机的。下面
这段手册原例（自包含复述）演示了陷阱：

```lisp
(defvar *foo* nil)
(defun show-foo ()
  (format t "~&foo=~S~%" *foo*)
  (force-output t))
(defun demo ()
  (schedule-timer (make-timer #'show-foo) 0.5)
  (schedule-timer (make-timer #'show-foo) 1.5)
  (let ((*foo* t))      (sleep 1.0))   ; 第一次触发时 *foo* 可能是 t
  (let ((*foo* :surprise!)) (sleep 2.0)) ; 第二次触发时 *foo* 可能是 :surprise!
  )
```

两次 `show-foo` 打印出来的 `*foo*` 值**不确定**——取决于调度器恰好
在哪个 `let` 绑定里触发。结论：**定时器回调必须是自包含的**，不依赖
外部动态变量、不假设持有任何锁。需要上下文就把它封进闭包的词法变量
里，别指望动态绑定。

`:thread` 不是 `t` 时，底层用 `sb-thread:interrupt-thread` 把回调
注入目标线程——回调跑的时候目标线程的中断是关的（但允许 `with-interrupts`），
所以排序保证跟 `interrupt-thread` 一致。

## 35.8 运行外部程序：run-program

`sb-ext:run-program` 直接 `exec` 外部程序——**不经过 shell**，所以
参数列表里的字符串是原样传递的，不需要也不应该做 shell 转义
（惯例上 argv[0] 自动是程序路径，args 里不要再放）：

```text
(sb-ext:run-program 程序 参数列表
  &key :wait :search :input :output :error :env :environment
       :if-input-does-not-exist :if-output-exists :if-error-exists
       :status-hook :external-format :directory :pty :preserve-fds)
```

常用键的自包含速查：

- `:wait` —— 默认 `t` 等进程结束；`nil` 立即返回 process 对象；
- `:search t` —— 在子进程 `$PATH` 里找程序，否则要求绝对路径；
- `:input` / `:output` —— `t` 继承本进程的标准流、`nil`（默认）接
  `/dev/null`、路径名重定向到文件、流对象转发，或 `:stream` 让
  process 对象带上一个 Lisp 流槽；
- `:error` —— 同 `:output`，还可以是 `:output` 与 stdout 合并
  （默认就是 `:output`）；写文件时 `:if-output-exists` 控制
  `:error`/`:supersede`/`:append`；
- `:environment` —— `"NAME=value"` 字符串列表，**默认复制**当前
  进程环境；`:env` 是 CMUCL 遗留的旧格式，二者不能同时给；
- `:directory` —— 子进程工作目录；
- `:status-hook` —— 进程状态变化时调的函数。

`:wait nil` 返回的 process 对象配一组 API：`process-input` /
`process-output` / `process-error` 取流，`process-alive-p`、
`process-status`（`:running`/`:stopped`/`:exited`/`:signaled`）、
`process-wait`（等退出）、`process-exit-code`（退出码）、
`process-kill`（发信号，`:whom :process-group` 发给整个进程组）、
`process-close`（关流——之后 exit-code 等信息可能是陈旧的，别再用）。

```lisp
(let ((p (sb-ext:run-program "/bin/echo" '("hello-run-program")
                             :output :stream :wait nil)))
  (sb-ext:process-wait p)
  (prog1 (list (read-line (sb-ext:process-output p))
               (sb-ext:process-exit-code p))
    (sb-ext:process-close p))) ; => ("hello-run-program" 0)
(sb-ext:process-exit-code
 (sb-ext:run-program "/usr/bin/true" nil)) ; => 0
```

注意子进程的输出流要**及时读**：管道缓冲写满而父进程还在
`process-wait` 就干等，是经典的死锁。输入输出量都大时
`:output :stream` + 边跑边读，或者干脆重定向到临时文件。

## 35.9 Unicode 支持

`sb-unicode` 包提供码点属性查询、Unicode 感知的大小写变换、排序
和断句。字符属性函数一览（返回类型括号注明）：

```text
general-category   通用类别，keyword（:#\a → :Ll，汉字 → :Lo）
script             文字系统，keyword（:#\中 → :Han）
char-block         Unicode 区块，keyword
decimal-value      十进制数字值或 nil（:#\4 → 4）
digit-value        数字值（无 0 的计数系统也有）
numeric-value      最一般的数值（有理数或 nil）
age                字符引入的 Unicode 版本（两值：主.次）
east-asian-width   :n/:a/:h/:w/:f/:na
bidi-class / mirrored-p / bidi-mirroring-glyph   双向文本
uppercase-p / lowercase-p / alphabetic-p / ideographic-p / math-p /
whitespace-p / hex-digit-p …                     布尔谓词
```

大小写变换按 Unicode 标准做**全串**映射——结果可能比输入长：

```lisp
(sb-unicode:uppercase "straße") ; => "STRASSE"
(sb-unicode:casefold "Straße") ; => "strasse"
```

`ß` 大写成 `SS`，这是 ANSI 的 `string-upcase`（逐字符、等长）给不
出的正确答案。`uppercase`/`lowercase`/`titlecase` 都收 `:locale`
（两字母国家码 keyword，或 `t` 用当前 locale）；`casefold` 去大小写
信息，专供大小写不敏感比较。

比较与排序走 Unicode Collation Algorithm：

```lisp
(sb-unicode:unicode< "apple" "banana") ; => T
(sb-unicode:unicode= "é" "é") ; => T
```

第二行是 `unicode=` 的拿手戏：左边是单码点 U+00E9，右边是
`e` + 组合音符 U+0301 两个码点——**规范等价**（canonically
equivalent）所以相等；给 `:strict nil` 改判兼容等价；
`unicode-equal` 是忽略大小写版本。另有 `unicode<=/>/>=` 和检测
「视觉易混淆串」的 `confusable-p`（IDNA 混淆表）。

断词断句按 UAX #29 / UAX #14：

```lisp
(sb-unicode:graphemes "a家族b") ; => ("a" "家" "族" "b")
(sb-unicode:words "hello, world 你好") ; => ("hello" "," " " "world" " " "你" "好")
```

`graphemes` 按**字素簇**切（组合字符序列不会从中间断开），
`words`/`sentences`/`lines`（`:margin` 控制折行宽度，默认 80）同理。
处理用户可见文本时，数「字符数」应该用 `(length (graphemes s))`
而不是 `(length s)`。

## 35.10 泛函分发与槽访问扩展

**`sb-pcl:no-primary-method`**。ANSI 只有 `no-applicable-method`
（没有任何 applicable 方法时调用）。SBCL 补上了另一半：applicable
方法集合非空（比如有 `:around`、`:before`）但**没有 primary 方法**
时，调用 `sb-pcl:no-primary-method`，默认方法 signal 错误；你可以
像普通泛函一样给它加方法：

```lisp
(defgeneric gf35 (x))
(defmethod gf35 :around (x)
  (declare (ignore x))
  (call-next-method))
(sb-ext:without-package-locks
  (defmethod sb-pcl:no-primary-method ((gf (eql #'gf35)) &rest args)
    (declare (ignore gf args))
    :no-primary))
(gf35 42) ; => :NO-PRIMARY
```

两个细节：触发条件是「有 `:around` 但没 primary」——**零方法**走
的仍是 ANSI 的 `no-applicable-method`；给 `sb-pcl` 的泛函加方法
属于符号级包锁违规（35.3），所以示例外面包了
`without-package-locks`。另外别忘了 `no-applicable-method` 本身是
个**泛函**——没有可用方法时 SBCL 直接调用它，而不是 signal 条件，
想定制就得给它加方法（用 `eql` 特化到具体泛函），`handler-case`
捕不到它。

**扩展槽访问**。`slot-value`、`(setf slot-value)`、`slot-boundp`、
`slot-makunbound` 在 SBCL 里不仅作用于标准对象，还作用于
**条件**（metaclass `condition-class`）和——带一些限制——
**结构**（metaclass `structure-class`）：

```lisp
(defstruct pt35 x y)
(let ((p (make-pt35 :x 1 :y 2)))
  (list (slot-value p 'x) (slot-boundp p 'y))) ; => (1 T)
(define-condition cond35 () ((msg :initarg :msg :reader cond35-msg)))
(slot-value (make-condition 'cond35 :msg "hi") 'msg) ; => "hi"
```

结构上的限制：槽名就是 `defstruct` 里写的符号；未绑槽的
`slot-value` 会走 `slot-unbound`；`(setf slot-value)` 会做类型检查；
`slot-makunbound` 只对「BOA 构造器里无默认值的 `&aux` 槽」有效，
其余情况 signal 错误；访问不存在的槽名走 `slot-missing`。
这套扩展让调试/序列化代码可以对三种对象用同一套槽访问 API，
不必为 `defstruct` 单写一套访问器。

**MOP 兼容性**（`sb-mop`）：SBCL 的 MOP 目标是与 AMOP 兼容，手册
列了一页有意偏离——多数非常边角，值得知道的两条：
`compute-effective-method` 只返回一个值（AMOP 写两个，但没人知道
第二值是什么）；`funcallable-standard-class` 的类必须在 superclass
里有 `function`、`standard-class` 的类必须没有，class finalization
时强制检查——想造「可调用对象」类就照这个模式：

```text
(defclass mixin () ((slot :initarg :slot)))
(defclass funcallable-object (funcallable-standard-object mixin)
  ()
  (:metaclass funcallable-standard-class))
```

**可扩展序列**（`sb-sequence`）：用户定义的类只要继承
`standard-object` 和 `sequence`，并给五个核心泛函
（`sb-sequence:length`、`elt`、`(setf elt)`、`adjust-sequence`、
`make-sequence-like`）写上方法，`subseq`、`map`、`reduce`、`find`
等整套序列函数就自动可用（`cl:map`/`concatenate`/`merge` 的第一个
参数在泛函版本里是**原型实例**而不是类型指示符）。只实现部分协议
的类在用到缺失操作时 signal
`sb-sequence:protocol-unimplemented`。追求性能还要再实现迭代器
协议（`sb-sequence:make-sequence-iterator` 一族），否则通用实现
逐元素走 `elt` 会很慢。

## 35.11 杂项精选

**确定性随机数**。SBCL 每次启动的 `*random-state*` 初始值相同，
所以标准功能就能得到可复现序列；`sb-ext:seed-random-state` 更进一步，
接受整数或 `(unsigned-byte 8)` 向量做种子（超过 256 bit 的信息量
意义不大，底层是 MT19937）：

```lisp
(let ((rs1 (sb-ext:seed-random-state 42))
      (rs2 (sb-ext:seed-random-state 42)))
  (equal (let ((*random-state* rs1)) (loop repeat 3 collect (random 100)))
         (let ((*random-state* rs2)) (loop repeat 3 collect (random 100)))))
  ; => T
```

要不可复现的随机性用 `(make-random-state t)`（操作系统熵源）。
注意可复现性只保到「同 SBCL 版本 + 同平台 + 同代码」——手册明确
说编译方式不同序列就可能不同，别把它当跨版本的数据生成格式。

**目录与文件**。`sb-ext:delete-directory` 删目录并返回其 truename；
默认要求空目录，`:recursive t` 先清空内容（符号链接只删链接本身，
不追进去）：

```lisp
(progn (ensure-directories-exist "probe35-dir/sub/")
       (sb-ext:delete-directory "probe35-dir/" :recursive t)
       (probe-file "probe35-dir/")) ; => NIL
```

（建目录用 ANSI 的 `ensure-directories-exist`；SBCL 的 CL 包里没有
`make-directory`，这是新手上路最常撞的未定义函数。）

**数组底层向量**。`sb-ext:array-storage-vector` 返回数组的底层
存储向量——simple 一维数组就是它自己（断言用 `eq` 验证）：

```lisp
(let ((v (vector 1 2 3)))
  (eq (sb-ext:array-storage-vector v) v)) ; => T
```

多维、带 fill pointer、可调整的数组才有独立的存储向量。和 FFI
（第 25 章）配合时它能拿到真正的数据地址，但手册警告这是实现
细节，随时可能取消。

**重定义哲学三件套**。SBCL 对「合法但可疑」的代码发 style
warning——同一符号多处 defun、特殊变量不叫 `*foo*` 之类；手册特别
提醒要读作「这种写法让编译器没法帮你查错」而不是「审美警告」。
想安静就绑 `sb-ext:*muffled-warnings*`（一个类型，命中的 warning
没人处理就被压掉，默认是「无趣的重定义」那类）。`defconstant` 重
定义到不 `eql` 的新值会 signal `sb-ext:defconstant-uneql`（可
continue/abort）；想要「重复加载不炸的常量」，手册给的配方是：

```text
(defmacro define-constant (name value &optional doc)
  `(defconstant ,name (if (boundp ',name) (symbol-value ',name) ,value)
     ,@(when doc (list doc))))
```

`defpackage` 重定义与现状不一致时由
`sb-ext:*on-package-variance*` 控制：默认 `(:warn t)` 尽量保留包
状态并发 full warning；`(:error t)` 直接报错并提供 restart。

**`exit` 的两个参数**（补第 23 章）：`:abort t` 直接 `_exit(2)`，
不回卷栈、不跑 exit hook（`exit` 递归调用时自动视同 `:abort`）；
`:timeout` 控制等其他线程终止的秒数（默认
`sb-ext:*exit-timeout*` = 60，`nil` 无限等）——超时只针对
`join-thread`，不限制 exit hook；想要有序同步关闭，正确做法是
在 exit hook 里自己关，而不是依赖隐式的 `terminate-thread`。

**名字冲突的程序化处理**。包操作撞名时，调试器里会逐个问；程序里
则调用 `sb-ext:resolve-conflict` restart，参数从条件访问器
`sb-ext:name-conflict-symbols` 返回的列表里选。

## 小结

- 读取器三扩展：`pkg::(a b c)` 批量 intern、`1.5r0` 读精确有理数、
  `#\u00e1` 写码点；`*read-default-float-format*` 绑 `rational` 让
  普通小数也读成有理数。
- 包局部昵称只在包内有效，根治昵称冲突；`(:local-nicknames ...)` +
  四个 `sb-ext` 函数。
- 包锁防手滑：包级违规报 `package-locked-error`、符号级报
  `symbol-package-locked-error`；合法通道 = 实现包、
  `with-unlocked-packages`、`without-package-locks`。
- 终结器**异步**执行（终结器线程、任意线程、无时点保证），测试用
  `wait-for` 轮询或断言「取消后永不跑」；弱指针真死后当轮 GC 即失效；
  弱哈希条目要「表访问 + 再一轮 GC」才观察得到，且对象得真死
  （保守式扫描会钉住残留引用）；终结器闭包千万别引用对象本身，
  且必须可重入。
- 哈希表：`:weakness` 四档语义、`:synchronized`、`define-hash-table-test`
  自定义等价（哈希码必须与测试一致）。
- 限时三件套：` :timeout` 参数最安全、`with-deadline` 阻塞点安全
  signal（`defer`/`cancel-deadline` 可恢复）、`with-timeout` 异步
  打断最危险。
- 定时器：`make-timer` 建、`schedule-timer` 排（`:repeat-interval`
  周期触发、`:absolute-p` 绝对时间）、`unschedule-timer` 取消；回调
  的动态环境不可靠，必须自包含。
- `run-program` 不走 shell；`:output :stream` + `process-*` 一族
  管进程；记得及时读子进程输出防管道死锁。
- Unicode：全串大小写（`ß→SS`）、规范等价比较、UAX #29 断词断句。
- `no-primary-method` 补全泛函分发的另一半；`slot-value` 通吃
  标准对象、条件、结构。
- 杂项：`seed-random-state` 定种子、`delete-directory :recursive`、
  `array-storage-vector`、`*muffled-warnings*`、`defconstant-uneql`、
  `*on-package-variance*`、`exit :abort/:timeout`。
