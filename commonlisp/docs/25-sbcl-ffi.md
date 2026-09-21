# 25 · SBCL 扩展 III：FFI（sb-alien）

> 配套示例：[`examples/25_sbcl_ffi/`](../examples/25_sbcl_ffi/main.lisp)（channel: sbcl）

`SB-ALIEN` 在核心里，不用 require，能直接调 C 函数（无需编译胶水代码）。

## 25.1 加载共享库

```lisp
#+win32 (sb-alien:load-shared-object "msvcrt.dll")
#+linux (sb-alien:load-shared-object "libc.so.6")
#+darwin (sb-alien:load-shared-object "libSystem.B.dylib")
```

**坑**：别用 MSVC 专有函数名。本示例最初用了 `strupr`——libSystem/glibc
里都没有，链接直接失败；换成标准的 `toupper` / `strcasecmp` 后三平台通吃。

## 25.2 声明与调用

```lisp
(sb-alien:define-alien-routine ("strlen" c-strlen) sb-alien:long
  (s sb-alien:c-string))

(c-strlen "hello")            ; => 5
```

第一个参数是 **C 世界的符号名**（字符串），第二个是 Lisp 侧的名字。
示例 25 的实测输出（节选）：

```
strlen("hello") = 5
abs(-42) = 42
sqrt(2.0) = 1.4142135623730951d0
toupper(#\a) = A
strcmp("abc", "abc") = 0
```

## 25.3 类型映射

| C 类型 | sb-alien 类型 | Lisp 类型 |
|---|---|---|
| `int` / `unsigned int` | `int` / `unsigned-int` | integer |
| `long` / `unsigned long` | `long` / `unsigned-long` | integer |
| `short` / `char` | `short` / `char`（及 unsigned 版） | integer |
| `float` / `double` | `single-float` / `double-float` | 同名 |
| `char*`（字符串语义） | `c-string` | string（自动转换） |
| `void*` | `system-area-pointer` | — |
| 自定义 | `(define-alien-type my-size-t unsigned-long)` | — |

实测样例：`labs(-123456789)` ; => `123456789`（`long` 版绝对值）。
数值塔在这儿也成立：C 的 `sqrt` 拿 double 返回 double，Lisp 侧看到
`1.4142135623730951d0`（04 章的 `d0` 又出现了）。

## 25.4 结构体、数组与指针

```lisp
(sb-alien:define-alien-type nil
  (struct point (x int) (y int)))

;; with-alien：栈上分配、离开作用域自动回收（还有 make-alien/free-alien 的堆版）
(sb-alien:with-alien ((p (struct point)))
  (setf (sb-alien:slot p 'x) 10)
  (sb-alien:slot p 'x))                        ; => 10

;; C 数组：deref 带下标
(sb-alien:with-alien ((arr (array int 10)))
  (dotimes (i 10) (setf (sb-alien:deref arr i) (* i i)))
  (sb-alien:deref arr 3))                      ; => 9

;; 已声明的函数也能用 alien-funcall 直接调
(sb-alien:alien-funcall (sb-alien:extern-alien "strlen" (function long c-string))
                        "hello")               ; => 5
```

## 25.5 回调：能不用就不用

SBCL 支持把 Lisp 函数暴露成 C 可调的指针（`define-alien-callback`），
典型用法是给 `qsort` 传比较函数。但回调是 FFI 里的深水区：
GC 可能移动对象、回调线程没有 Lisp 的线程上下文、错误穿过边界行为未定义。
优先「C 侧存结果、Lisp 侧轮询」或写一小段 C 胶水；真要回调时
`sb-alien` 手册的「Callbacks」一节逐条对照。

## 25.5 CFFI：可移植的正解

`sb-alien` 是 SBCL 专有；**CFFI** 是跨实现的事实标准（SBCL/CLISP/CCL/ECL…）：

```lisp
(ql:quickload :cffi)
(cffi:define-foreign-library libc
  (:unix "libc.so.6") (:darwin "libSystem.B.dylib"))
(cffi:use-foreign-library libc)
(cffi:defcfun "strlen" :int (s :string))
(cffi:foreign-funcall "strlen" :string "hello" :int)
```

正经集成 C 库别硬扛 sb-alien——CFFI 处理结构体、回调、内存管理的坑都趟过了。
sb-alien 的价值：零依赖、与 SBCL 编译器深度配合（26 章性能敏感的场景）。

## 25.6 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `The alien function "strupr" is undefined` | MSVC 专有函数 | 换标准 C 函数 |
| 调浮点函数结果离谱 | 声明成 int 了 | 类型声明写对（double） |
| 回调崩溃 | GC/线程上下文 | 避免 sb-alien 回调或极小心 |
| 共享库加载失败 | 库名/路径平台不同 | `#+` 分发（示例 25 的写法） |
| 换 CLISP 跑不了 | sb-alien 是 SBCL 专有 | CFFI |
