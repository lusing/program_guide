# 25 · SBCL 扩展 III：FFI（sb-alien 全解）

> 配套示例：[`examples/25_sbcl_ffi/`](../examples/25_sbcl_ffi/main.lisp)（channel: sbcl）

FFI（Foreign Function Interface，外部函数接口）让 Lisp 直接调用 C 函数、
直接读写 C 的内存布局。SBCL 的 FFI 住在 `SB-ALIEN` 包里——「alien」（异质）
是 CMUCL 时代的老名字，指代那些不按 Lisp 对象格式存放的数据。
它在核心里，不用 require，也不需要编译任何 C 胶水代码。

## 25.1 FFI 是什么：三种通信思路

Lisp 对象有自己的内存表示（带类型标签、会被 GC 移动），C 期望的是裸布局。
两者要交换数据，历史上只有三条路：

1. **C 侧迁就 Lisp**：让 C 代码理解 Lisp 对象的内部表示。要写大量脆弱的
   胶水代码，且深度绑定具体实现的内部细节。
2. **自动转换**：Lisp 系统在边界上把对象来回转换。方便，但大而复杂的
   数据结构一转换就慢得不可接受。
3. **直接操纵**：Lisp 程序用扩展语法直接读写 C 布局的内存，不转换。

SBCL 走 **2 + 3 的混合路线**：简单标量（整数、浮点、字符串）自动转换；
复杂类型（结构体、数组、指针）以 C 的原始布局直接操纵。操纵不了、
不需要类型信息的地方，还有最低层的 SAP（System Area Pointer，系统区域
指针）提供无类型裸地址访问。

不能被自动转换的外部值，在 Lisp 侧统一表示为 `alien-value` 对象——
一个包着裸指针和类型信息的壳。因为 Lisp 是动态类型语言，连外部对象
也得带运行时类型，类型信息就存在这个壳里。

## 25.2 加载共享库

调 C 函数之前，先把装着它的共享库拉进进程：

```lisp
#+win32 (sb-alien:load-shared-object "msvcrt.dll")
#+linux (sb-alien:load-shared-object "libc.so.6")
#+darwin (sb-alien:load-shared-object "libSystem.B.dylib")
```

`load-shared-object` 就是 `dlopen(3)`（Windows 上是 `LoadLibrary`）
的 Lisp 封装，库找不到时按平台规则搜索（`LD_LIBRARY_PATH` 等）。
三个要点：

- **重复加载**：非 Windows 平台上，对同一路径再次调用会用新定义替换旧
  定义；若旧库里被引用过的符号在新版里消失则报错。
- **与 save-lisp-and-die 的交互**（配合 23 章看）：传 `:dont-save t`
  则保存核心时丢弃该库，核心启动时不自动重载——库在目标机器上位置不
  确定时用它；默认 `:dont-save nil`，核心启动时自动重新加载。
- **卸载**：`unload-shared-object` 可以卸载，但目前是实验性的。

**坑**：别用平台专有函数名。本教程示例最初用了 MSVC 专有的 `strupr`
——libSystem 和 glibc 里都没有，链接直接失败；换成标准 C 的 `toupper`
/`strcasecmp` 后三平台通吃。

## 25.3 外部类型系统

外部类型用嵌套列表描述，刻意模仿 C 的语法。C 的：

```c
struct foo {
    int a;
    struct foo *b[100];
};
```

对应的外部类型是：

```text
(struct foo
  (a int)
  (b (array (* (struct foo)) 100)))
```

类型说明符全集如下（都导出自 `sb-alien`；与 CL 同名的如 `single-float`
可以直接用 CL 符号）：

| 说明符 | 含义 | 边界上的转换 |
|---|---|---|
| `(* 类型)` | 指针；`(* t)` 相当于 `void *` | 不转换，包成 alien-value |
| `(array 类型 维度…)` | 定长数组；首维可为 `nil`（变长，仅 `make-alien`） | 不转换 |
| `(struct 名 (槽 类型)…)` | 结构体，偏移量按本机 C 编译器布局；槽可带 `:alignment` | 不转换 |
| `(union 名 (槽 类型)…)` | 联合，所有槽同偏移 | 不转换 |
| `(enum 名 (符号 \| (符号 值))…)` | 枚举，整数 ↔ 符号互转 | 自动 |
| `(signed 位数)` / `(integer 位数)` / `(unsigned 位数)` | 指定精度的整数，省略位数取机器字长 | 自动 |
| `(boolean 位数)` | C 的 0/1 ↔ Lisp 的 nil/t | 自动 |
| `single-float` / `double-float` | IEEE 单/双精度 | 自动 |
| `(function 返回 参数…)` | 函数类型（仅 `alien-funcall` 直接用；别处用 `(* (function …))`） | — |
| `system-area-pointer` | 无类型裸指针（SAP） | — |
| `void` | 只用于函数返回：无返回值（调它返回零个值） | — |
| `(c-string :external-format … :element-type … :not-null …)` | NUL 结尾的 C 字符串 | 自动 ↔ Lisp string；C 的 NULL ↔ nil（`:not-null t` 时遇 NULL 报 type-error） |

另有 C 类型别名一整套：`char` `short` `int` `long` 及各自的
`unsigned-` 版，外加 `float` `double` `size-t` `off-t`。

`c-string` 值得多说两句，它是最常用的类型：

- Lisp 的 `base-string` 内部自带 NUL 结尾，外部格式是 `:ascii`、元素
  类型是 `base-char` 时**零拷贝**直接传指针；否则实现会替你拷贝一份。
- 默认外部格式由 `sb-ext:*default-c-string-external-format*` 决定，
  需要别的编码（如 `:utf-8`）就在类型说明符里显式写。
- 给 `c-string` 类型的槽/变量赋 Lisp 字符串，是把内容**拷进指针已指向
  的内存**；赋 nil 则写入 C 的 NULL。

外部类型还能当普通 Lisp 类型用：包一层 `alien` 说明符即可，
`(typep p '(alien (* int)))` 检查 p 是不是指向外部 int 的指针，
声明和 `typep`/`check-type` 都受 SBCL 精确类型检查约束。

```lisp
(let ((p (sb-alien:make-alien sb-alien:int)))
  (unwind-protect (typep p '(sb-alien:alien (* sb-alien:int)))
    (sb-alien:free-alien p)))                 ; => T
```

## 25.4 声明与调用外部函数

### define-alien-routine：一劳永逸的声明

```lisp
(sb-alien:define-alien-routine ("strlen" c-strlen) sb-alien:long
  (s sb-alien:c-string))

(c-strlen "hello")                            ; => 5
```

第一个参数是 **C 世界的符号名**（字符串），第二个是 Lisp 侧的函数名；
宏会顺便 declaim 好 ftype。名字可以只给一个，按规则互猜：
外部名转 Lisp 名 = 大写 + 下划线换连字符，反向则小写 + 连字符换下划线。
返回类型写 `void` 表示无返回值。

参数 `(名字 类型 &optional 风格)` 的**风格**是这把瑞士刀上最锋利的刀片
——把 C 的「传指针让你写」习惯翻译成 Lisp 的多返回值：

| 风格 | 语义 |
|---|---|
| `:in`（默认） | 按值传入，不产生额外返回值 |
| `:out` | 栈上分配一个该类型对象，传它的地址；函数返回后其内容作为 Lisp 侧的**附加返回值** |
| `:copy` | 值先拷到栈上，传栈地址（C 侧可写但改动丢不掉回来） |
| `:in-out` | `:copy` + `:out`：传入初值，返回时被 C 侧改过的值作为附加返回值 |

看实例。`time(2)` 的原型是 `time_t time(time_t *tloc)`——返回值和写出
的 `*tloc` 是同一个时间戳。用 `:out` 声明：

```lisp
(sb-alien:define-alien-routine ("time" c-time) sb-alien:long
  (tloc sb-alien:long :out))
```

Lisp 侧 `c-time` 零参数调用，返回**两个值**：C 返回值和 `*tloc`。
两者必然相等：

```lisp
(multiple-value-call #'= (c-time))            ; => T
```

一个假想但典型的混合例子（手册里的 `cfoo`）：C 函数
`void cfoo(char *str, char *a /* 读改 */, int *i /* 只写 */)` 声明为

```lisp
(sb-alien:define-alien-routine "cfoo" sb-alien:void
  (str sb-alien:c-string)
  (a sb-alien:char :in-out)
  (i sb-alien:int :out))
```

Lisp 侧的 `cfoo` 收两个参数（str 和 a），返回两个值（a 和 i）。
注意 `:out`/`:in-out` 不能用于指向数组、结构体或函数的指针。

**性能提示**：效率敏感的接口函数，在 `define-alien-routine` 之前加一句
`(declaim (inline lisp-name))`。内联展开不仅省掉 Lisp 调用开销，
还能让指针、字长整数、浮点用无箱（unboxed）表示传递，零 consing。

### alien-funcall：不声明直接调

已存在的符号可以用 `extern-alien` 现场造出函数指针对象再调：

```lisp
(sb-alien:alien-funcall
 (sb-alien:extern-alien "strlen" (function sb-alien:long sb-alien:c-string))
 "hello")                                     ; => 5
```

类型信息不必在编译期可知，但只有编译期已知类型的调用才会被高效编译。
在 x86-64 和 ARM64 上，结构体可以**按值**传参和返回（遵循 System V
AMD64 / AAPCS64 调用约定）；按值返回大结构体时还可以用
`alien-funcall-into` 把结果直接写进你给的 SAP 缓冲区，它本身不返回值。

一批实测（都在加载 libSystem 之后）：

```lisp
(sb-alien:define-alien-routine ("sqrt" c-sqrt) sb-alien:double-float
  (x sb-alien:double-float))
(sb-alien:define-alien-routine ("labs" c-labs) sb-alien:long
  (x sb-alien:long))
(sb-alien:define-alien-routine ("toupper" c-toupper) sb-alien:int
  (ch sb-alien:int))
(sb-alien:define-alien-routine ("strcmp" c-strcmp) sb-alien:int
  (a sb-alien:c-string) (b sb-alien:c-string))

(c-sqrt 2.0d0)                                ; => 1.4142135623730951d0
(c-labs -123456789)                           ; => 123456789
(code-char (c-toupper (char-code #\a)))       ; => #\A
(c-strcmp "abc" "abc")                        ; => 0
```

`boolean` 返回类型把 C 的 0/非 0 翻成 nil/t：

```lisp
(sb-alien:define-alien-routine ("isatty" c-isatty) sb-alien:boolean
  (fd sb-alien:int))

(typep (c-isatty 0) '(member t nil))          ; => T
```

## 25.5 结构体、联合、枚举与数组

`define-alien-type` 给类型起全局名字（第一个参数是要缩写的类型，
这里给 `nil` 表示「定义结构体本身」）：

```lisp
(sb-alien:define-alien-type nil
  (struct point (x sb-alien:int) (y sb-alien:int)))
```

`with-alien` 在**栈上**分配外部对象，离开作用域自动回收；
`slot` 取槽（可 setf），结构体指针会被自动解引用：

```lisp
(sb-alien:with-alien ((p (struct point)))
  (setf (sb-alien:slot p 'x) 10 (sb-alien:slot p 'y) 20)
  (+ (sb-alien:slot p 'x) (sb-alien:slot p 'y)))   ; => 30
```

联合的所有槽共享同一块内存，哪个槽有效由你负责：

```lisp
(sb-alien:with-alien ((u (union number (i sb-alien:int) (f sb-alien:single-float))))
  (setf (sb-alien:slot u 'i) 42)
  (sb-alien:slot u 'i))                       ; => 42
```

枚举在整数和符号之间双向转换。`(:red 1)` 显式给值，不给的顺延 +1，
所以 `:green` 是 2、`:blue` 是 3：

```lisp
(sb-alien:with-alien ((c (enum nil (:red 1) :green :blue)))
  (setf c :green)
  (eq c :green))                              ; => T
```

数组用 `deref` 带下标访问（可 setf），按 C 的行主序存放。`with-alien`
能在栈上分配定长数组：

```lisp
(sb-alien:with-alien ((arr (array sb-alien:int 5)))
  (dotimes (i 5) (setf (sb-alien:deref arr i) (* i i)))
  (sb-alien:deref arr 3))                     ; => 9
```

`with-alien` 的完整绑定形式是
`VAR 类型 [ 分配方式 ] [ 初值 | 外部名 ]`，分配方式两种：

- `:local`（默认）：栈上分配，动态范围；
- `:extern`：不分配，把 VAR 绑成一个已存在外部符号的局部别名。

另外，`with-alien` 会捕获具名 struct/union 定义——在它词法作用域里写的
`(struct foo (…))` 是局部类型，同名全局定义不受影响。结构体也可以
在 with-alien 里用 `alien-funcall` 当「初值」直接接进栈槽位：
C 函数按值返回的 struct 落进栈上变量，连堆分配都省了（x86-64/ARM64）。

结构体套指针的链表操作看手册式翻译。C 侧：

```c
struct c_struct { short x, y; char a, b; int z; c_struct *n; };
extern struct c_struct *my_struct;
my_struct->x++;  my_struct->a = 5;  my_struct = my_struct->n;
```

Lisp 侧逐行对应（`define-alien-variable` 见 25.7）：

```lisp
(sb-alien:define-alien-type nil
  (struct c-struct
    (x sb-alien:short) (y sb-alien:short)
    (a sb-alien:char) (b sb-alien:char)
    (z sb-alien:int)
    (n (* (struct c-struct)))))
;; (incf (slot my-struct 'x))
;; (setf (slot my-struct 'a) 5)
;; (setq my-struct (slot my-struct 'n))
```

注意 `n` 槽写的是 `(* (struct c-struct))` 而不是 `(* c-struct)`：alien
类型名空间和 CL 的完全独立，**引用具名 struct 必须带 `(struct 名)` 前缀**，
裸名字不是合法类型说明符（会在宏展开期报 `unknown alien type`）。定义体
内部写 `(struct c-struct)` 就是自引用——具名 struct/union 允许这样递归
（引用延迟到使用时解析），匿名（名 `nil`）的不行。

## 25.6 外部内存的分配与指针操作

### 堆上分配：make-alien 三件套

`make-alien` 用 `malloc(3)` 在外部堆上分配，返回指针。**内存不初始化**，
里面是垃圾。因为用的就是 C 的分配器，C 代码 `free(3)` 它和 Lisp
`free-alien` 它都合法，反之亦然——谁分配谁释放的纪律跨语言通用。
配套的 `make-alien-string` 把 Lisp 字符串编码拷进新分配的外部内存，
返回两个值：指针和字节数（含 NUL）。

```lisp
(let ((a (sb-alien:make-alien sb-alien:int 4)))   ; 连续 4 个 int
  (unwind-protect
       (progn (dotimes (i 4) (setf (sb-alien:deref a i) (* i i)))
              (sb-alien:deref a 3))
    (sb-alien:free-alien a)))                 ; => 9
```

`deref` 对指针带下标就是 C 的指针算术（按指向类型的大小缩放），
不带下标就是解引用：

```lisp
(let ((p (sb-alien:make-alien sb-alien:int 3)))
  (unwind-protect
       (progn (dotimes (i 3) (setf (sb-alien:deref p i) (+ 10 i)))
              (+ (sb-alien:deref p) (sb-alien:deref p 2)))   ; p[0]+p[2]
    (sb-alien:free-alien p)))                 ; => 22
```

`make-alien-string` 与 `cast` 配合可以做字符串往返：造出来的指针是
`(* char)`，`cast` 成 `c-string` 再读就按 NUL 结尾翻回 Lisp 字符串。

```lisp
(let ((p (sb-alien:make-alien-string "hello")))
  (unwind-protect (sb-alien:cast p sb-alien:c-string)
    (sb-alien:free-alien p)))                 ; => "hello"

(nth-value 1 (sb-alien:make-alien-string "hi"))  ; => 3（h、i、NUL）
```

再给一个实用例：`memset` 填 3 个 `'x'` 再补 NUL，读回字符串：

```lisp
(sb-alien:define-alien-routine ("memset" c-memset) sb-alien:system-area-pointer
  (dst sb-alien:system-area-pointer) (val sb-alien:int) (n sb-alien:unsigned-long))

(let ((p (sb-alien:make-alien sb-alien:char 4)))
  (unwind-protect
       (progn (c-memset (sb-alien:alien-sap p) (char-code #\x) 3)
              (setf (sb-alien:deref p 3) 0)
              (sb-alien:cast p sb-alien:c-string))
    (sb-alien:free-alien p)))                 ; => "xxx"
```

### 指针工具族

- `addr expr`：取外部变量/`deref`/`slot` 表达式的地址，得到指针；
- `cast alien 类型`：换个类型看同一块内存（新 alien-value 对象，
  地址相同，与原对象不 eq）；
- `alien-sap alien` / `sap-alien sap 类型`：类型化指针 ↔ 无类型 SAP；
- `sb-sys:int-sap 整数`：裸虚拟地址 → SAP；
- `sb-sys:sap-ref-32 sap 偏移` 等同族函数：按字节偏移直接读写
  （8/16/32/64 位各有版本），可 setf；
- `sb-sys:sap=`：两个 SAP 地址相等判断；
- `null-alien`：空指针判断。

```lisp
(sb-alien:null-alien
 (sb-alien:sap-alien (sb-sys:int-sap 0) (* sb-alien:int)))   ; => T
```

SAP 是无类型的最后手段——用它能轻易踩穿 Lisp 堆，非必要不碰。

## 25.7 外部变量与 errno

C 的全局变量用 `define-alien-variable` 绑成 Lisp 侧的「全局符号宏」：
读它就是读 C 变量，`setf`/`incf` 它就是写 C 变量。符号解析是惰性的，
定义时不会去找符号，第一次访问才解析。

```lisp
(sb-alien:define-alien-variable "some_c_counter" sb-alien:int)
;; 之后 (print some-c-counter)、(incf some-c-counter) 直接读写 C 变量
```

`errno` 是例外：现代 C 库里它根本不是变量，而是线程局部的宏伪装品，
**不能**用上面的机制，要用专用函数 `get-errno`。典型套路：调一个可能
出错的 C 函数，检查返回值，再取 `errno` 看原因码。用 `fopen` 打开一个
不存在的路径演示（返回 NULL 指针，`errno` 被置为 2 即 ENOENT）：

```lisp
(sb-alien:define-alien-routine ("fopen" c-fopen) sb-alien:system-area-pointer
  (path sb-alien:c-string) (mode sb-alien:c-string))

(sb-sys:sap= (c-fopen "/no/such/file/exists" "r") (sb-sys:int-sap 0))
                                                  ; => T
(sb-alien:get-errno)                              ; => 2
```

`getenv` 演示 `c-string` 返回值的两种结局：存在的变量给字符串，
不存在的给 nil（C 的 NULL 指针自动翻成 nil）：

```lisp
(sb-alien:define-alien-routine ("getenv" c-getenv) sb-alien:c-string
  (name sb-alien:c-string))

(stringp (c-getenv "HOME"))                   ; => T
(c-getenv "DEFINITELY_NOT_SET_VAR_12345")     ; => NIL
```

## 25.8 回调：让 C 调用 Lisp

前面的方向都是 Lisp 调 C。反方向——C 拿着函数指针调回 Lisp——才是
FFI 的深水区：`qsort` 要比较函数、GUI 库要事件处理器、C 库要错误
回调。SBCL 用 `define-alien-callable` 把一段 Lisp 代码包成 C 调用约定
的函数指针。

### define-alien-callable 三要素

```lisp
(sb-alien:define-alien-callable lisp-double sb-alien:int ((x sb-alien:int))
  (* 2 x))
```

名字、返回类型、带类型的参数表——body 就是普通 Lisp 代码。
`alien-callable-function` 取出对应的函数指针对象。先做个不用 C 库的
自检：把这个指针当外部函数用 `alien-funcall` 调一圈（Lisp → C 调用约定
→ 回到 Lisp）：

```lisp
(sb-alien:alien-callable-function 'lisp-double) ; 一个 alien-value 函数指针
(sb-alien:alien-funcall
 (sb-alien:alien-callable-function 'lisp-double) 21)   ; => 42
```

重复定义同名 callable 时，只要新旧类型兼容，已发出去的函数指针**保持
有效**，只是指向新的 Lisp 定义——REPL 里可以边跑边改回调体，这就是
文档说的「增量重定义」。

### 实战：给 qsort 传比较函数

C 标准库的 `qsort` 原型：

```c
void qsort(void *base, size_t nmemb, size_t size,
           int (*compar)(const void *, const void *));
```

比较函数收到的是指向两个元素的**指针**，按惯例返回负/零/正。
先定义回调（解引用两个 int 指针做减法）：

```lisp
(sb-alien:define-alien-callable cmp-int sb-alien:int
    ((a (* sb-alien:int)) (b (* sb-alien:int)))
  (- (sb-alien:deref a) (sb-alien:deref b)))
```

再声明 qsort。元素指针和函数指针都按 SAP 传——SAP 就是裸地址，
qsort 不挑食：

```lisp
(sb-alien:define-alien-routine ("qsort" c-qsort) sb-alien:void
  (base sb-alien:system-area-pointer)
  (nmemb sb-alien:unsigned-long)
  (size sb-alien:unsigned-long)
  (compar sb-alien:system-area-pointer))
```

栈上开一个 5 元素 int 数组，填成 4 3 2 1 0，排序，读回：

```lisp
(sb-alien:with-alien ((arr (array sb-alien:int 5)))
  (dotimes (i 5) (setf (sb-alien:deref arr i) (- 4 i)))
  (c-qsort (sb-alien:alien-sap (sb-alien:addr arr)) 5 4
           (sb-alien:alien-sap (sb-alien:alien-callable-function 'cmp-int)))
  (loop for i below 5 collect (sb-alien:deref arr i)))   ; => (0 1 2 3 4)
```

`addr arr` 取数组地址，`alien-sap` 转成无类型指针；回调指针同样过一道
`alien-sap`。排序期间 C 侧多次调回 `cmp-int`，全程在本机实测通过。

### with-alien-callable：能闭包的回调

`define-alien-callable` 定义的是全局回调。要给 C 传一个**捕获词法变量**
的回调（比如把比较阈值闭包进去），用 `with-alien-callable`：名字在它的
词法作用域里绑成局部外部函数，动态范围有效：

```lisp
(let ((base 100))
  (sb-alien:with-alien-callable ((add-base sb-alien:int ((x sb-alien:int))
                                  (+ base x)))
    (sb-alien:alien-funcall add-base 5)))     ; => 105
```

### 回调的三条安全纪律

1. **别让错误逃逸出回调**。Lisp 条件穿过 C 帧往外抛，行为未定义。
   回调体里包 `handler-case`，把错误码通过返回值或全局变量送回来。
2. **GC 会移动对象**。C 侧若持有指向 Lisp 对象的引用，GC 一搬就成
   悬垂指针。三副药：`sb-ext:purify` 把所有活对象搬进永不移动的静态
   区（一次性，适合交付前）；`sb-sys:with-pinned-objects` 在动态范围
   内钉住指定对象；`sb-ext:without-gcing` 直接关 GC（粗粒度）。
   上面 qsort 例子里回调只碰 C 侧内存，天然安全。
3. **C 代码别动 Lisp 的环境**。被 Lisp 调用的 C 函数不应安装/修改信号
   处理器——SBCL 运行时的 GC、线程都依赖自己那套带特殊标志的信号
   处理设置。

顺带一提：这套机制还能把整个 Lisp 变成 C 可调用的共享库——
`save-lisp-and-die` 传 `:callable-exports`，C 程序通过 `initialize_lisp`
符号初始化运行时后直接调你导出的 callable（注意目前没有办法从 C 侧
优雅地执行退出钩子）。

## 25.9 CFFI：可移植的正解

`sb-alien` 是 SBCL 专有；**CFFI** 是跨实现的事实标准
（SBCL/CLISP/CCL/ECL……），用 Quicklisp 装上 `(ql:quickload :cffi)` 后，
API 思想一一对应：

```common-lisp
(cffi:define-foreign-library libc
  (:unix "libc.so.6") (:darwin "libSystem.B.dylib"))
(cffi:use-foreign-library libc)
(cffi:defcfun "strlen" :int (s :string))
(cffi:foreign-funcall "strlen" :string "hello" :int)
```

正经集成一个 C 库（结构体嵌套、回调、内存管理全套）别硬扛
sb-alien——CFFI 把这些坑都趟过了。sb-alien 的价值：零依赖、与 SBCL
编译器深度配合（26 章性能敏感的场景，`declaim inline` 的无箱传递）。

## 25.10 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `The alien function "strupr" is undefined` | 平台专有函数（MSVC） | 换标准 C 函数 |
| 调浮点函数结果离谱 | 返回类型声明成了 int | 类型声明写对（double-float） |
| 回调偶发崩溃/悬垂指针 | GC 移动了 C 侧引用的对象 | purify / with-pinned-objects / without-gcing |
| 回调里抛错直接挂 | Lisp 条件逃逸进 C 帧 | 回调体包 handler-case |
| 结构体偏移对不上 | 布局按本机 C 编译器猜的，特殊情况不符 | 槽加 `:alignment` 显式指定 |
| `c-string` 中文乱码 | 默认外部格式不是 utf-8 | 类型里写 `:external-format :utf-8` |
| 把 NULL 当字符串用崩了 | c-string 遇 NULL 返回 nil | 判 nil，或 `:not-null t` 让它报 type-error |
| `free-alien` 后还用指针 | 悬垂指针 | unwind-protect 管好生命周期 |
| C 库一加载 Lisp 就行为怪异 | C 代码动了信号处理器 | 别让 C 侧装信号处理 |
| 保存核心后库找不到 | 目标机器库路径不同 | `load-shared-object` 传 `:dont-save t` |
| 换 CLISP/CCL 跑不了 | sb-alien 是 SBCL 专有 | CFFI |

---

上一章：[24 SBCL 扩展 II：线程](24-sbcl-threads.md) · 下一章：[26 性能优化](26-performance.md)
