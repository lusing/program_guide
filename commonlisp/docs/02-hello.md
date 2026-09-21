# 02 · 第一个程序：REPL、脚本与双实现跑法

> 配套示例：[`examples/02_hello/`](../examples/02_hello/main.lisp)（channel: both）

## 2.1 两种运行方式

**交互式 REPL** —— 学语言、试想法、看报错用这个：

```bash
$ sbcl
* (+ 1 2)

3
* (quit)
```

`*` 是提示符。你输入一个表达式，SBCL 编译它、执行它、把返回值打印出来。这个循环就是
**R**ead-**E**val-**P**rint **L**oop。CLISP 同理（提示符 `>` / `[1]>`）：

```bash
$ clisp -E UTF-8
[1]> (+ 1 2)
3
[2]> (exit)
```

**脚本方式** —— 写正式代码、进 CI 用这个：

```bash
# SBCL：四个参数各有用意
$ sbcl --noinform --non-interactive --no-userinit --load hello.lisp

# CLISP：-q -q 安静两次，-norc 不加载用户初始化，-E UTF-8 钉死编码
$ clisp -q -q -norc -E UTF-8 hello.lisp
```

SBCL 四个参数：

| 参数 | 作用 |
|---|---|
| `--noinform` | 不打印启动 banner（那行版本信息会污染 stdout） |
| `--non-interactive` | 出错不当场进调试器，直接退出 |
| `--no-userinit` | 不加载 `~/.sbclrc`，保证结果**可复现** |
| `--load FILE` | 加载并执行文件 |

`--no-userinit`（CLISP 的 `-norc`）最容易被忽略又最要命：你的初始化文件里如果改了
`*read-default-float-format*` 或者装了 Quicklisp，同一个脚本在别人机器上结果就不一样。

> **⚠️ 一个会骗过验证的组合**：SBCL 的 `--script` 与 `--non-interactive` **不能连用**。
> 连用会把文件名当成运行期参数，脚本根本不执行，只打一行 banner、退出码 0——看起来「跑过了」。
> 本仓库的验证入口统一用 `--load`。

**shebang 直跑**（可执行脚本）：

```lisp
#!/usr/bin/env sbcl --script      ; SBCL：--script 隐含非交互、不加载 rc
#!/usr/bin/env clisp              ; CLISP：记得环境里 UTF-8 locale 或改用 -E
```

## 2.2 五种输出与两个流

| 写法 | 去哪里 | 说明 |
|---|---|---|
| `(format t ...)` / `(print x)` / `(princ x)` | **stdout** | `t` 是 `*standard-output*` 的简写 |
| `(format *error-output* ...)` / `(warn ...)` | **stderr** | `warn` 天生写 stderr（18 章） |
| SBCL 编译器的警告与回显 | **stderr** | CLISP 的告警也走 stderr |

`(print x)`、`(princ x)` 省掉第一个参数其实是在打 `*standard-output*`。要写 stderr
必须显式：

```lisp
(format *error-output* "这条是 stderr~%")
```

五种基本输出一张表记牢（示例 `02_hello` 全部演示）：

| 函数 | 视角 | 字符串 | 适合 |
|---|---|---|---|
| `format ~A` / `princ` | 人类 | 不带引号 | 日志、界面文字 |
| `format ~S` / `prin1` | 机器 | 带引号 | 可被 `read` 读回 |
| `print` | 机器 | 带引号+前置换行 | REPL 检查 |
| `terpri` | — | — | 单独输出换行 |
| `write` | 全参数版 | 可控 | 定制打印 |

## 2.3 第一个函数

```lisp
(defun greet (name)
  "向 NAME 打招呼。文档字符串写在参数列表之后。"
  (format t "你好，~A！~%" name))

(greet "世界")            ; => NIL   ← 打印「你好，世界！」是副作用，返回值是 NIL
```

docstring 可以取回：`(documentation 'greet 'function)` ; => "向 NAME 打招呼。……"。
函数体最后一个表达式的值就是返回值——`(format t ...)` 返回 NIL，
所以 greet 的返回值是 NIL（打印是副作用）。

**顶层表达式按顺序求值**：`load` 一个 .lisp 文件 = 把文件里的顶层形式从头到尾逐个求值，
后面的形式能看到前面 `defun` 的结果。这个「文件即程序」的模型贯穿全教程。

## 2.4 命令行参数：第一个 #+/#- 实战

两个实现的参数接口不同：SBCL 用 `sb-ext:*posix-argv*`（含程序自身与 `--` 之后的参数），
CLISP 用 `ext:*args*`（只有脚本参数）。统一封装：

```lisp
(defun program-arguments ()
  #+sbcl (cdr (member "--" sb-ext:*posix-argv* :test #'string=))
  #+clisp ext:*args*
  #-(or sbcl clisp) nil)
```

三个要点：

1. **读取期分发**：`sb-ext:*posix-argv*` 这个符号在 CLISP 里根本读不出来
   （SB-EXT 包不存在，read 直接报错），所以必须用 `#+sbcl` 在**读取器**层面挡掉，
   换成运行期 `if` 是不行的。
2. **变量不是函数**：`ext:*args*` 是个变量，写成 `(ext:*args*)` 就变成函数调用了
   （报 undefined function *ARGS*——本教程实测踩过）。
3. **SBCL 的 `--`**：`sbcl --load f.lisp -- a b` 里，`--` 之后的才是用户参数，
   且 `*posix-argv*` 会包含 `"--"` 本身，所以取 `(cdr (member "--" ...))`。

## 2.5 验证怎么跑（本仓库约定）

```bash
cd commonlisp
./run-all.sh              # 全部 26 个示例：SBCL + CLISP 双通道
./run-all.sh 02           # 只跑 02
```

每个通道四条判定（退出码 0 / stderr 空 / 无控制字符 / 结束标记），
双通道示例加第 5 条 **SBCL 与 CLISP 的 stdout 逐字节一致**。
示例文件头部的 `;; channel: both` / `;; channel: sbcl` 声明通道。

结束标记的写法：

```lisp
(format t "==== 02 结束 ====~%")
```

## 2.6 坑位清单

1. **`--script` ≠ 万能**：它隐含 `--no-userinit`/非交互，但和 `--non-interactive`
   连用会让脚本根本不执行（见 2.1 的警告框）。
2. **CLISP 忘 `-E UTF-8`**：中文直接 `Invalid byte #xE4` 退出码 1；本仓库脚本已内置该参数。
3. **`(quit)` 在 SBCL 里已让位给 `(sb-ext:quit)`/`(sb-ext:exit)`**，CLISP 用 `(ext:quit)`
   或 `(exit)`——可移植封装见 22 章（读取期分发 + portable-quit）。
4. **banner 污染 stdout**：忘了 `--noinform`（SBCL）/ `-q -q`（CLISP），
   第一行就是版本信息，逐字节比对必挂。
5. **SBCL 的 style-warning 也算 stderr 非空**：哪怕程序逻辑对，编译警告（未用变量、
   未定义函数引用）都会让「stderr 为空」判定失败——示例代码必须干净到零警告
   （这条逼出来的好习惯，21 章细讲）。
