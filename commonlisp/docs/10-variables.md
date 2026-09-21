# 10 · 变量与作用域：词法还是动态

> 配套示例：[`examples/10_variables/`](../examples/10_variables/main.lisp)（channel: both）

这一章是 CL 与几乎所有主流语言差别最大的地方，也是 Lisp 的「宏」能成立的原因。

## 10.1 defvar / defparameter / defconstant：重载语义各不同

| 形式 | 重复加载时 | 适合 |
|---|---|---|
| `(defvar *x* v)` | **不覆盖**已存在的值 | 配置、可选状态 |
| `(defparameter *x* v)` | **覆盖**，每次加载都重置 | 必须重置的参数 |
| `(defconstant +x+ v)` | 不许再改 | 真常量 |

「重复加载」的差别值得亲手跑一遍（示例 10 用 `eval` 复现了「再次求值定义形式」）：

```lisp
(defparameter *param-val* 1)
(defvar *var-val* 1)
(eval '(defparameter *param-val* 100))   ; 重新赋成 100
(setf *var-val* 100)
(eval '(defvar *var-val* 999))           ; 已有值 → 保持 100
*param-val*    ; => 100
*var-val*      ; => 100
```

**这就是「改完代码重新加载」时调试状态有时保留、有时被冲掉的原因**。
「每次都要回初值」的变量写 `defparameter` 是更好的默认。

两个实测细节：

```lisp
(defvar *v* 1)
(defvar *v* 999)
*v*                    ; => 1        ← 第二次 defvar 不生效
(defvar *u*)           ; 只声明，不绑定
(boundp '*u*)          ; => NIL      ← 没有初值就没有绑定！
```

常量被赋值是**编译期错误**（示例 10 的注释里有实测记录：SBCL 直接
`+C+ is a constant and thus can't be set`，整文件编译不过；包进 eval 才变成
运行期可捕获——但 stderr 仍会有诊断。结论：常量就别 setf）。

**命名约定**：全局特殊变量用「耳罩」`*name*`，常量用 `+name+`。
耳罩不只是风格——它告诉读者「这可能是动态绑定」。

## 10.2 let 并行绑定，let* 顺序绑定

初学 CL 最常见的运行期错误：

```lisp
(let ((a 1) (b (+ a 1))) b)
; 报错：The variable A is unbound.
```

`let` 的所有初值在**外层环境**求值，`b` 的初值看不到同层刚绑的 `a`：

```lisp
(let* ((a 1) (b (+ a 1))) b)     ; => 2
```

「并行」的用处是**交换**（初值都看到旧值，示例 10 实测）：

```lisp
(let ((a 1) (b 2))
  (let ((x b) (y a)) (list x y)))     ; => (2 1)   ← 交换成功
(let ((b 2))
  (let* ((x b) (y x)) (list x y)))    ; => (2 2)   ← let* 顺序：y 看到新 x
```

**实践建议**：顺序依赖用 `let*`，刻意并行（交换、互不干扰）用 `let`。

## 10.3 词法作用域 vs 动态作用域（重头戏）

CL 默认**词法作用域**：函数体只看得到自己**定义处**能看到的变量：

```lisp
(defun callee () *lexical-x*)
(defun caller () (let ((*lexical-x* :from-caller)) (callee)))
(caller)     ; 报错：The variable *LEXICAL-X* is unbound.（那个 let 只是词法绑定）
```

但如果变量被 `defvar`/`defparameter` 声明成**特殊变量**，绑定变成**动态作用域**——
跟着调用链走：

```lisp
(defvar *dyn-x* :global)
(defun dcallee () *dyn-x*)
(defun dcaller () (let ((*dyn-x* :from-caller)) (dcallee)))
(dcaller)     ; => :FROM-CALLER
*dyn-x*       ; => :GLOBAL      ← 退出 let 自动恢复（栈式绑定）
```

动态绑定天然适合「临时改变配置」——标准库自己就这么干：

```lisp
(let ((*print-case* :downcase)) (format t "~S~%" 'Hello-Up))   ; 打印 hello-up
```

`*print-base*`、`*package*`、`*standard-output*`、`*error-output*` 全是动态变量
（02 章 warn 改道 stderr 就是这么做的）。只想临时声明 special：

```lisp
(let ((x 1)) (declare (special x)) ...)   ; 这个 x 是动态的
```

> **为什么两套并存？** 动态作用域「跟着调用链走」恰好是「临时改全局配置」
> 需要的行为——别的语言用线程局部变量/依赖注入模拟的东西，CL 一个 `let` 搞定。
> 代价是易误用，所以用 `*耳罩*` 命名区分。`symbol-value` 看到的也是
> 当前动态绑定（示例 10 实测）。

## 10.4 闭包：捕获变量，不是值的快照

```lisp
(defun make-adder (n) (lambda (x) (+ x n)))
(funcall (make-adder 3) 4)          ; => 7
```

捕获的是**变量本身**，所以状态可以累积（11 章的计数器/账户/记忆化三连
是完整版），每个闭包实例互相独立。`defun` 写在 `let` 里也是合法的顶层定义，
它会把词法变量封进函数：

```lisp
(let ((acc 0))
  (defun push-acc (v) (incf acc v))
  (push-acc 5)
  (push-acc 5)
  acc)                              ; => 10
```

## 10.5 setf 家族：作用在「位置」上

`setf` 的第一个参数是**位置表达式**（place）：变量、数组下标 `(aref v i)`、
结构体字段 `(person-age p)`、哈希键 `(gethash k ht)`、`(car l)` 都行：

```lisp
(incf x)          ; x ← (+ x 1)
(decf x 10)       ; x ← (- x 10)
(rotatef a b)     ; 交换
(shiftf a b c 99) ; 左移：a←b←c←99
(push v (gethash k ht nil))   ; 往哈希里的表压元素（位置嵌套位置）
```

`push`/`pop`/`pushnew` 同理。**(setf list) is undefined** 类报错 = 你把「临时值」
当成了位置（07 章）。

没 `defvar` 过的名字直接 `setf`，SBCL 会隐式建立全局绑定但给编译警告——
别依赖它，声明过的变量在编译优化上完全是另一回事。

## 10.6 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `(let ((a 1) (b (+ a 1))))` 报 unbound | `let` 并行绑定 | 顺序依赖用 `let*` |
| `(defvar *x*)` 后还是 unbound | 无初值不创建绑定 | 给初值 |
| 重新加载后变量回初值（或没回） | defparameter 重置 / defvar 保留 | 按需选 |
| 函数读不到调用者的局部变量 | 默认词法作用域 | 动态变量（defvar 声明） |
| `(setf +常量+ x)` 整个文件编译不过 | 常量 setf 是编译期错误 | 别改常量 |
| 全局变量忘了 defvar | 隐式绑定 + SBCL 警告进 stderr | 显式声明（验证判定会抓） |
