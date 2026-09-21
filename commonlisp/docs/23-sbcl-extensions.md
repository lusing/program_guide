# 23 · SBCL 扩展 I：进程、环境、GC、编译器与映像

> 配套示例：[`examples/23_sbcl_ext/`](../examples/23_sbcl_ext/main.lisp)（channel: sbcl）
>
> 从本章起是 **SBCL 专属**部分（22 章讲了 CLISP 对应接口与可移植替代）。

## 23.1 用 `SB-*` 之前先想清楚

`SB-` 开头的包是 SBCL 的实现扩展，标准里没有：换实现就跑不了。
业务代码建议把 `SB-*` 的使用收进一个小适配层，或直接用可移植库
（bordeaux-threads / cffi / uiop）。

## 23.2 哪些包在核心里、哪些要 require

核心里就有的包**不需要 require**，require 它们反而报错（实测）：

| 包 | 位置 |
|---|---|
| `SB-EXT`（getenv / run-program / gc / quit） | **核心** |
| `SB-ALIEN`（FFI，25 章） | **核心** |
| `SB-THREAD`（线程，24 章） | **核心** |
| `SB-PROFILE`（性能分析，26 章） | **核心** |
| `SB-POSIX` / `SB-SPROF` / `SB-COVER` / `SB-BSD-SOCKETS` | contrib，**要 require** |

```lisp
(require :sb-posix)      ; => ("SB-POSIX")
(require :sb-profile)    ; 报错：Don't know how to REQUIRE SB-PROFILE
```

后一个错误容易误解——不是「没这功能」，是「它在核心里，没有同名 contrib」。
直接用即可。另外 `require` 与 `pkg:sym` **不能写在同一个顶层形式**（03 章：
读入先于求值）。

## 23.3 实现信息与环境变量

```lisp
(lisp-implementation-type)      ; => "SBCL"
(lisp-implementation-version)   ; => "2.6.8"
(sb-ext:posix-getenv "HOME")    ; => "/root"（不存在的变量返回 NIL）
```

**跨平台要小心变量名**：`USERPROFILE`/`OS` 是 Windows 专有，POSIX 上得 NIL；
用 `HOME`/`SHELL`/`PATH` 这类通用变量（或 `#+win32` 分发）。

## 23.4 run-program：跑外部命令

三个实测坑：

```lisp
;; ① 裸程序名必须 :search t，否则报 Couldn't execute "echo"
(sb-ext:run-program "echo" '("hi") :output t :search t)

;; ② :output 不接受 :string
(sb-ext:run-program "echo" '("hi") :output :string)   ; 报 invalid option

;; ③ 拿输出字符串：给一个流（with-output-to-string 或 :stream 自己读）
(with-output-to-string (s)
  (sb-ext:run-program "echo" '("hi") :output s :search t))    ; => "hi\n"
```

一行 shell 命令要按平台选解释器（读取期分发）：

```lisp
(defun shell-command (command)
  #+win32 (list "cmd" (list "/c" command))
  #-win32 (list "/bin/sh" (list "-c" command)))
```

进程管理三件套：`process-wait`、`process-exit-code`、`process-pid`/
`process-alive-p`（异步场景用，示例 23 演示了捕获输出与退出码）。

## 23.5 GC 与内存

```lisp
(sb-ext:gc)                     ; 手动完全 GC
(sb-ext:get-bytes-consed)       ; 累计分配字节数（算 GC 压力的口径）
(room t)                        ; 内存报告；(room nil) 静默
```

gen GC 参数调优（`sb-ext:generation-parameters`…）在长驻服务里才需要，
教程不展开。

## 23.6 编译控制：compile / declaim / disassemble

```lisp
(defun to-be-compiled (x) (+ x 1))
(compile 'to-be-compiled)               ; 单函数编译
(compiled-function-p #'to-be-compiled)  ; => T

(declaim (optimize (speed 3) (safety 1) (debug 1)))   ; 全局优化策略
(defun fixnum-add (a b)
  (declare (type fixnum a b)
           (optimize (speed 3) (safety 0)))
  (the fixnum (+ a b)))
(disassemble #'fixnum-add)              ; 看真机器码（26 章）
```

SBCL 是「始终编译」的实现——`--load` 也走编译器，所以**类型声明在日常代码里
就有效果**；代价是 style-warning 会被打出来（这也是好事：警告即线索）。

## 23.7 save-lisp-and-die：整世界打包

```lisp
(defun my-app-main () (format t "启动！~%") (sb-ext:quit))
;; 真打包时执行（注意：它不返回——保存完就退出进程，只能放最后）：
;; (sb-ext:save-lisp-and-die "my-app" :toplevel #'my-app-main :executable t)
;; 产物 ./my-app 可直接运行
```

- 把当前 Lisp 映像（含已加载的全部代码）dump 成可执行文件；
- **调用即退出**（"and die" 是字面意思），只能放最后；
- `:executable nil` 只存核心 `.core`：`sbcl --core xxx.core` 恢复，体积小得多；
- Windows 产物加 `.exe`；`:compression t` 需 SBCL 编译时带 zlib。

对比 CLISP 的 `ext:saveinitmem`：映像更小但不带运行时（21 章）。

## 23.8 原子操作与 CAS

```lisp
(defstruct counter (value 0 :type (unsigned-byte 64)))
(sb-ext:atomic-incf (counter-value c))       ; 原子自增
(sb-ext:cas (car cell) 0 42)                  ; 旧值对得上才换
```

CAS 返回**旧值**——判断成败靠比较返回值与期望值（示例 23 演示成功与失败两例）。
这是 24 章无锁结构的地基。

## 23.9 *features* 与实现自检

`*features*` 含 `:sbcl`、`:sb-thread`、`:little-endian`、`:unix` 等——
`#+` 的数据源。跨实现时是分发依据（22 章）。

## 23.10 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `Don't know how to REQUIRE SB-THREAD` | 它在核心里 | 直接用，别 require |
| require 后同形式里用 `pkg:sym` 读不到 | 读入先于求值 | 分两个顶层形式 |
| `Couldn't execute "echo"` | 没加 `:search t` | 加上，或给绝对路径 |
| `:output :string` 报错 | 不支持 | 给流（with-output-to-string） |
| POSIX 上跑 `cmd /c` | 平台写死 | `#+win32` 分发 |
| save-lisp-and-die 后代码没执行 | 它不返回 | 放最后一条 |
