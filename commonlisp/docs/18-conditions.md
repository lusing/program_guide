# 18 · 条件系统与重启：CL 最独特的部分

> 配套示例：[`examples/18_conditions/`](../examples/18_conditions/main.lisp)（channel: both）

其它语言的异常是「跳出去」，CL 的条件系统是「**发通知、然后由外层的处理器决定怎么办**」。
多出来的那一层（restart）让「出错后还能接着修」成为可能——这是 CL 交互式开发体验的核心。

## 18.1 三档：signal < warn < error

```lisp
(error "出问题了")       ; 一路向上，没人接就进调试器（脚本模式=退出）
(warn "注意一下")        ; 打印 WARNING 后**继续执行**
(signal 'some-condition) ; 通知一下，没人管就返回 NIL
```

`warn` 的内容走 **stderr**（02 章）。想让它进 stdout 就动态重绑 `*error-output*`；
想静音就接到广播空流：`(make-broadcast-stream)`。

`signal` 有个**容易忽视的分支**：条件类型若是 `error` 的子类，`signal` 的行为
**和 `error` 一样**（进调试器）。所以：**想当错误用就继承 `error`，
只想通知就继承 `condition`**。

## 18.2 自定义条件：带上数据，写好报告

条件就是**类实例**（CLOS 的近亲，`define-condition`），可以带槽、定义打印：

```lisp
(define-condition insufficient-funds (error)
  ((balance :initarg :balance :reader insufficient-funds-balance)
   (amount  :initarg :amount  :reader insufficient-funds-amount))
  (:report (lambda (c stream)
             (format stream "余额 ~A 不足，需要 ~A"
                     (insufficient-funds-balance c)
                     (insufficient-funds-amount c)))))

(handler-case (error 'insufficient-funds :balance 10 :amount 99)
  (error (e) (format nil "~A" e)))
; => "余额 10 不足，需要 99"
```

类型层次自动搭好——`(typep e 'insufficient-funds)`/`(typep e 'error)`/
`(typep e 'condition)`/`(typep e 'serious-condition)` 全是 T，
既可以用最具体的类型接，也可以用 `error` 一把接住。

**读数据用访问器，不要解析消息字符串**（报错文本是实现细节，SBCL/CLISP 措辞不同）：

```lisp
(handler-case (car 5)
  (type-error (e) (list (type-error-datum e)      ; => 5    非法值
                        (type-error-expected-type e))))  ; => LIST  期望类型
```

**可移植捕法**：SBCL 的数组越界具体类型是实现专有的
`SB-INT:INVALID-ARRAY-INDEX-ERROR`，但它**属于 `type-error`**——
捕标准父类（`type-error`/`error`），别捕 `SB-INT:`/`SYSTEM::` 开头的类；
打印条件类名用 `(symbol-name (type-of e))`（去掉实现包前缀，06 章）。

## 18.3 handler-case 与 handler-bind：一个展开栈，一个不展开

这是条件系统里最重要的区别：

- **`handler-case`**：「捕获并放弃现场」——先**展开栈**（unwind）再执行处理代码，
  处理代码里看不到出错时的调用栈。就是 try/catch。
- **`handler-bind`**：「就地介入」——处理函数在**出错的那个栈帧上**运行，
  栈没展开，能看到现场、能调用 restart 让程序**继续跑**。

**handler-bind 的关键细节**：处理函数正常返回**不算处理**——错误继续传播。
必须**转走控制流**（`invoke-restart`/`throw`/`return-from`）才算数。
这和「try/catch 里 return 就没事了」的直觉相反。

实用组合：`handler-bind` 记录（保现场）+ `handler-case` 收尾（示例 18 的嵌套演示）。

## 18.4 restart：报错之后还能接着干

restart 是「出错时提供的**可选出路**」。**检测与策略分离**是灵魂：
低层函数只管报错 + 提供出路，高层决定挑哪条：

```lisp
(define-condition validation-error (error)
  ((field :initarg :field :reader validation-error-field)
   (value :initarg :value :reader validation-error-value))
  (:report (lambda (c s) (format s "字段 ~S 的值 ~S 无效"
                                  (validation-error-field c)
                                  (validation-error-value c)))))

(defun parse-config (raw)
  (restart-case
      (if (stringp raw) (list :config raw)
          (error 'validation-error :field "config" :value raw))
    (use-empty () :report "改用空配置" (list :config :empty))
    (treat-as-string (s) :report "把值转成字符串"
      :interactive (lambda () (list "默认串"))
      (list :config (format nil "~A" s)))))
```

没有外层干预时 `restart-case` **完全不改变行为**；外层挑一条出路，
程序**从 restart-case 的位置继续**：

```lisp
(handler-bind ((validation-error
                (lambda (e) (invoke-restart 'use-empty))))
  (parse-config 42))                      ; => (:CONFIG :EMPTY)

(handler-bind ((validation-error
                (lambda (e)
                  (invoke-restart 'treat-as-string (validation-error-value e)))))
  (parse-config 42))                      ; => (:CONFIG "42")
```

同一份低层代码，换一个 handler-bind 就换一种恢复方式。
REPL 里报错时 SBCL/CLISP 会把 restart 列成菜单，敲数字就能选——
交互式开发「修一下接着跑」就是这么来的。

快捷件：`with-simple-restart`（只挂一个出路）、`cerror`（可继续错误 +
自动提供 continue restart）、`ignore-errors`（两值：结果/条件）。

**⚠️ 双实现差异（实测）**：带参数的 restart 在 CLISP 上**必须**给 `:interactive`
（调试器选中时收集参数用），否则加载时就发 WARNING 到 stderr；SBCL 无此要求。
跨实现代码给每个带参 restart 都配上。

## 18.5 assert 与 check-type

写测试和前置条件用它们俩（13 章类型防线的运行版）：

```lisp
(assert (> 3 2))          ; => NIL   通过
(let ((x 5)) (check-type x integer) x)    ; => 5
(let ((x "s")) (check-type x integer))
; 报错：The value of X is "s", which is not of type INTEGER.
```

`assert` 自定义消息的语法要小心——`(x)` 是「可重新绑定的变量列表」，
消息占位符靠**额外实参**填：

```lisp
(assert (> 2 x) (x) "自定义消息：x=~A" x)
```

三个（含 `ecase`）都是 restart-case 的包装：REPL 里报错时可以「改值重试」。

**⚠️ 编译期陷阱（实测）**：SBCL 连**字面量**错误都能在编译期发现——
文件里直接写 `(/ 1 0)` 或 `(let ((x "s")) (check-type x integer))`，
warning 就进 stderr（验证判定失败）。要演示运行期报错，把值藏进函数参数。

## 18.6 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| 示例「stderr 非空」判定失败 | warn 写 stderr / 编译期警告 | 绑 `*error-output*`；运行期演示走函数参数 |
| handler-bind 处理器返回了错误还炸 | 正常返回不算处理 | `invoke-restart`/`throw` 转走控制流 |
| 自定义条件 `~A` 打出 `#<...>` | 没写 `:report` | 加 `:report` |
| 捕不到某错误 | 捕了实现专有类 | 捕 `type-error`/`error` 标准父类 |
| `(signal 'my-error)` 进调试器 | 它继承自 error | 只通知就继承 condition |
| CLISP 加载时告警 restart 缺 :interactive | 带参 restart 必须配 | 加 `:interactive` |
| no-error 子句 CLISP 上报 too many arguments | 身体的全部返回值都要接 | `(:no-error (v &rest rest))` |
