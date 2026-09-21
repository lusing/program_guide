# 12 · 控制流与迭代：从 if 到 loop 全姿势

> 配套示例：[`examples/12_control/`](../examples/12_control/main.lisp)（channel: both）

## 12.1 只有 `nil` 是假

```lisp
(if 0 :true :false)      ; => :TRUE      ← 0 是真！
(if "" :true :false)     ; => :TRUE      ← 空字符串是真！
(if '() :true :false)    ; => :FALSE     ← 空表就是 nil，才是假
(not 0)                  ; => NIL
(not '())                ; => T
```

**把 C 代码翻成 Lisp 时最容易漏的一处**：`if (n)` 常表示「n 非零」，
但 `(if n ...)` 对 `0` 是真。判断零用 `(zerop n)`。`not` 和 `null` 是同一个函数，
按可读性选用。

## 12.2 分支全家桶

```lisp
(if (> 1 2) :yes)                ; => NIL      ← 无 else 分支返回 NIL
(when (> 2 1) :a :b)             ; => :B       ← 多语句版 if-then
(unless (> 1 2) :a :b)           ; => :B

(cond ((> 95 90) :a) (t :f))     ; => :A       ← 从上往下第一个真
(cond (nil :a) (nil :b))         ; => NIL

(case 2 (1 :one) (2 :two) (otherwise :other))     ; => :TWO
(case 7 ((1 3 5 7) :odd) (t :other))              ; => :ODD   ← 多值写列表
(ecase 9 (1 :one))              ; 报错：9 fell through ECASE（比静默 NIL 安全）
```

**`case` 用 `eql`，字符串和浮点永远匹配不上**：

```lisp
(case "a" ("a" :hit) (otherwise :other))     ; => :OTHER   ← 不是 :HIT！
```

要按类型分支用 `typecase`（`etypecase` 是报错版）：

```lisp
(typecase "s" (integer :int) (string :str) (t :other))   ; => :STR
```

**多写 `ecase`/`etypecase` 比写 `case` 安全**——拼错的常量立刻暴露。

## 12.3 `and` / `or` 返回的是值

```lisp
(and 1 2 3)          ; => 3          ← 最后一个真值
(and 1 nil 3)        ; => NIL
(or nil nil :x)      ; => :X
(and)                ; => T
```

短路让 `and`/`or` 成为「先判断再取用」的标准姿势——等价其它语言的 `obj?.slot`：

```lisp
(let ((v nil)) (and v (length v)))       ; => NIL   ← v 是 nil 就不会调 length
(or 名字 "匿名")                          ; or 提供默认值
```

## 12.4 简单循环

```lisp
(dotimes (i 3) ...)                    ; i = 0,1,2
(dolist (x '(:a :b) :finished) x)      ; 遍历表；第三段是「正常跑完」的返回值
(dolist (x '(1 2 3)) (when (= x 2) (return x)))   ; => 2   return 提前退出
```

`return` 能用是因为这些宏的循环体被包在**隐式的 nil 块**里（12.6）。

## 12.5 `loop`：CL 里最实用的宏

简单形态像英语：

```lisp
(loop for i from 1 to 5 collect i)                  ; => (1 2 3 4 5)
(loop for i below 5 collect i)                      ; => (0 1 2 3 4)
(loop for i from 0 to 10 by 2 collect i)            ; => (0 2 4 6 8 10)
(loop for i downfrom 3 to 1 collect i)              ; => (3 2 1)
(loop for x in '(1 2 3) sum x)                      ; => 6
(loop for x in '(1 2 3) count (oddp x))             ; => 2
(loop for x in '(3 1 2) maximize x)                 ; => 3
(loop for x in '((1 2) (3 4)) append x)             ; => (1 2 3 4)
(loop repeat 3 collect :x)                          ; => (:X :X :X)
```

遍历各种容器：

```lisp
(loop for x across #(1 2 3) collect (* x x))          ; => (1 4 9)      向量
(loop for x on '(1 2 3) collect x)                     ; => ((1 2 3) (2 3) (3))  尾巴！
(loop for (k . v) in '((:a . 1)) collect v)            ; => (1)          解构
(loop for x in '(a b c) for i from 1 collect (cons i x))   ; 多 for 并行
```

**`for x on` 给的是「每一段尾巴」**，取元素要 `(car x)`——和 `in` 别混。

哈希表遍历（顺序不定！09 章）：

```lisp
(loop for k being the hash-keys of ht using (hash-value v) ...)
```

条件与提前结束：

```lisp
(loop for x in '(1 2 3 4) when (evenp x) collect x)          ; => (2 4)
(loop for i from 1 while (< i 4) collect i)                  ; => (1 2 3)
(loop for x in '(1 2 3) thereis (> x 2))                     ; => T    找到就停
(loop for x in '(1 2 3) always (integerp x))                 ; => T    全真
(loop for x in '(1 2 3) never (minusp x))                    ; => T
```

`with`（一次性绑定）、`initially`/`finally`（首尾钩子）、`return`（退出）：

```lisp
(loop with acc = 100
      for i from 1 to 3
      do (incf acc i)
      finally (return acc))                    ; => 106
```

嵌套 loop 的 collect 是「表的表」，需要平铺用 `append`（示例 12 演示）。

## 12.6 非局部退出：四种机制

**`block` / `return-from`**——命名出口（`defun` 自带与函数同名的隐式块，
所以函数体里随时 `(return-from 函数名 值)`）：

```lisp
(block b (return-from b :done) :never)      ; => :DONE
(block nil (return 42))                     ; => 42   return = return-from nil
```

**`catch` / `throw`**——按标签的动态出口，可穿越深层调用栈（示例 12 演示
「从 dolist 里跳出到函数边界」）：

```lisp
(catch 'tag (throw 'tag :caught))           ; => :CAUGHT
(catch 'tag :no-throw)                      ; => :NO-THROW
```

**`unwind-protect`**——无论怎么退出都执行清理（try/finally 的对应物，
`with-open-file` 内部就是它）。**注意顺序：清理段先执行完才转移控制权**。

**`tagbody` / `go`**——最底层的跳转；loop/do 就是拿它编译出来的，
日常不用手写，读展开时会遇到。

顺手记：`(prog1 a b c)` 返回**第一个**值（先取旧值再改的场景），
`prog2` 返回第二个。

## 12.7 do 与 do*

```lisp
(do ((i 1 (1+ i)) (a 0 b) (b 1 (+ a b)))
    ((= i 10) a))                        ; => 34   斐波那契（并行步进的紧凑写法）
```

`(a 0 b)` = 初值 0、下一轮取 b。**结束判断在每轮循环体之前**；
`do*` 是顺序绑定版。会读即可，写代码优先 loop。

## 12.8 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `(if 0 ...)` 走了真分支 | 只有 nil 是假 | `(zerop x)` 显式判断 |
| `case` 匹配字符串总失败 | case 用 eql | `cond` / `typecase` / `string-case` 自己写 |
| 忘了 otherwise 静默得 NIL | case 无匹配返回 NIL | 用 `ecase` |
| `for x on` 拿到子表 | on 给尾巴 | 用 `in` 或 `(car x)` |
| **`downfrom` 不写 `to` 吃爆内存** | 无上界死循环 | 必写终止条件 |
| 嵌套 loop 结果多一层 | 各自 collect | 平铺用 `append` |
| CLISP 提示 `LOOP: FOR clauses should occur before the loop's main body` | `until`/`while` 混在两个 for 之间 | FOR 子句放最前（27 章实测） |

> **死循环的真实代价（实测）**：漏写 `to` 的 `(loop for i downfrom 3 collect i)`
> 在 SBCL 上以**进程级致命错误**收场：`Heap exhausted, game over`——
> 这**不是**可捕获的 condition，handler-case 拦不住，进程直接没了。
