# 32 · 坑清单

对应示例：本书全部 29 个示例里真实踩过的坑，按层次归类

这一章是全书最有留存价值的部分。**里面每一条都是写示例时真实报错、真实查出来的**，不是从文档里抄的。按「从底层到工程」的顺序排列，每条都给出**现象 → 原因 → 修法**。坑 1–38 来自前 24 章的编写现场；坑 39–47 是按 Harper/Myers 两本书扩充书本篇（第 25–31 章）时新撞出来的，集中在 32.9 节。

## 32.1 语法层：编译器说「语法错」的时候，通常是这一条

### 坑 1：`handle` 顶格换行 → `syntax error: inserting LET`

```sml
fun safeCalc s =
    (Int.toString (calc s))
handle Fail msg => "raised Fail / " ^ msg        (* ← 语法错 *)
```

**原因**：SML 的一个声明**在遇到顶格（第 1 列）的新行时终止**。`handle` 是表达式的一部分，顶格换行会把表达式截断。编译器看到孤零零的 `handle`，只能猜你想写 `let`。

**修法**：把 `handle` 缩进，或者给整个表达式加括号。

```sml
fun safeCalc s =
    (Int.toString (calc s))
    handle Fail msg => ...        (* ← 缩进一级 *)
```

**同一类坑还有 `;`**：声明层的 `;` 是「分隔两个声明」，表达式层的 `;` 是「顺序执行」。两者用同一个字符，靠**缩进 + 括号**区分。

### 坑 2：分号串联不加括号

```sml
val out = TextIO.openOut path
val _ = TextIO.output (out, text); TextIO.closeOut out      (* ← 只有第一个被赋给 _ *)
```

**原因**：`;` 在声明层终止一个 `val` 声明，于是 `TextIO.closeOut out` 变成一个**独立的裸表达式声明**（在 SML/NJ 的交互式下能跑，但在 `use` 的文件里通常是错误或者被忽略）。

**修法**：**表达式层用分号必须加括号。**

```sml
val _ = (TextIO.output (out, text); TextIO.closeOut out)
```

这个坑在本书里出现了 **5 次**（示例 17、19、20、21、22），每次都长得差不多。**记住它：分号 + 括号是连体的。**

### 坑 3：`fn x => e1; e2` 会被截断

```sml
val _ = List.app (fn xs => e1; e2; e3) cases       (* ← 危险 *)
```

**现象**：MLton 报 `Undefined variable: xs`。因为 `fn xs => e1` 之后的部分被当成独立的声明，看不见 `xs`。

**修法**：

```sml
val _ = List.app (fn xs => (e1; e2; e3)) cases
```

### 坑 4：嵌套注释必须配平

```sml
(* 外层 (* 内层 *) 还是外层？ *)     (* ← SML 的注释可以嵌套！ *)
```

**现象**：注释提前结束，后面一大段代码被当成注释。

**原因**：SML 的块注释是**嵌套的**（不像 C 是「第一个 `*/` 就结束」）。所以 `(*` 和 `*)` 必须严格配对。

**修法**：写注释时不要在注释里裸写 `(*` 或 `*)`。要写就用别的形式代替：

```sml
(* 用「左括号星号」而不是 (* 本身 *)
```

**这条在写文档/注释时特别容易踩**，因为你要解释注释的语法本身。

### 坑 5：`fun runThree (C : COUNTER)` —— 签名不是类型

```sml
fun runThree (C : COUNTER) = ...      (* ← Error: unbound type constructor: COUNTER *)
```

**原因**：`(x : T)` 的 `T` 必须是**类型**。`signature COUNTER` 是**签名**，不是类型。SML 里**没有「把一个 structure 当参数传」的函数形式** —— 唯一的办法是 `functor`。

**修法**：

```sml
functor RunThree (C : COUNTER) = struct
    val result = C.value (C.bump (C.bump (C.bump C.zero)))
end
```

**这条错误信息 `unbound type constructor: COUNTER` 完全没有提示你「应该用 functor」**，所以很值得记住。

## 32.2 类型推断：SML 会猜，猜错了你得告诉它

### 坑 6：`type` 别名不是约束

```sml
type point = real * real

fun makePoint (x, y) = (x, y)      (* 推断出 'a * 'b -> 'a * 'b，和 point 无关 *)
```

**原因**：`type` 只是给类型取个名字。它**不检查**右边的表达式是否符合这个名字。

**修法**：给返回值加标注。

```sml
fun makePoint (x, y) : point = (x, y)
```

**这条坑的变体是本教程里最隐蔽的一个**（示例 21 的 `makeChecker`）：返回的记录里某个函数字段带着自由类型变量 `'a`，而 `type checker` 里的声明写着 `(unit -> unit)` —— **别名不会帮你把 `'a` 钉成 `unit`**，于是每次使用这个记录都要重新实例化，报 `operator and operand do not agree`。

**通用规则：凡是「构造函数返回记录/函数」的地方，都给返回值加类型标注。** 别指望 `type` 别名做这件事。

### 坑 7：重载运算符在信息不足时怎么解析

```sml
signature NUM = sig
    type t
    val add : t * t -> t
end

structure RealNum : NUM = struct
    type t = real
    fun add (a, b) = a + b        (* ← `+` 是什么类型？ *)
end
```

**现象**（本教程实测）：

| 实现 | 结果 |
|---|---|
| SML/NJ | **错**：推断出 `int * int -> int`，和签名的 `real * real -> real` 不符 |
| MLton | **错**：同上 |
| Poly/ML | **通过**：用签名里的期望类型反推 |

**原因**：`a + b` 里的 `+` 是重载的（`int` 加还是 `real` 加？）。SML/NJ 和 MLton 的默认策略是「信息不足就当 `int`」，而 Poly/ML 会拿签名里的 `add : real * real -> real` 反推。

**修法**：**显式标注。**

```sml
fun add (a : real, b : real) = a + b
```

**这个坑的教训比修法重要**：**同一个「类型信息不足」的根因，会在很多地方冒出来**（签名约束的结构、参数类型、记录字段的 `=`），三套实现的容错程度不同。**写要跨实现跑的代码时，凡是重载的地方都标的清清楚楚，就不依赖这些策略了。**

### 坑 8：`map #1 xs` → `unresolved flex record`

```sml
val keys = map #1 pairs        (* ← unresolved flex record (can't tell what fields there are besides #1) *)
```

**现象**：三套实现全部报错。

**原因**：`#1` 是一个「弹性记录选择子」—— 编译器需要知道记录**有哪些字段**才能确定这是不是合法的 `#1`。光看 `#1` 不知道记录长什么样。

**修法**：

```sml
val keys = map (fn (k, _) => k) pairs
```

**记忆点**：`#n` / `#label` **只在有完整类型信息的地方能用**。函数参数位置上是「无信息」的，所以要在 `fn` 里用元组模式代替。

### 坑 9：把 `int option` 塞进需要 `int` 的地方

```sml
val total = a + b      (* a, b 是 int option 时 → tycon mismatch *)
```

**原因**：`option` 不是 `int` 的隐式包装。`SOME 3 + SOME 4` 是类型错。

**修法**：先解包。

```sml
fun addOpt (SOME a, SOME b) = SOME (a + b)
  | addOpt _ = NONE
```

或者用 `Option.map` / `Option.join` 等组合子。

**这条坑的意义在正面**：`option` **不能**被当数字用，正是它的价值 —— **编译器强迫你处理 `NONE`**。第 24 章的项目就是靠这个机制保证缺失值不会被误算。

## 32.3 值限制与多态

### 坑 10：`ref` / `array` 的 `=` 比的是物理地址

```sml
val a = ref 1
val b = ref 1
val r = a = b            (* false！ *)
```

**实测**（三套实现一致）：

| 类型 | 相等类型？ | `=` 比什么 |
|---|---|---|
| `ref` | 是 | **物理地址** |
| `array` | 是（Basis 没保证） | **物理地址** |
| `vector` | 是 | **内容** |
| `list` | 是 | **内容** |

```sml
val a1 = Array.array (2, 0)
val a2 = a1
a1 = a2                                        (* true：同一块 *)
Array.array (2, 0) = Array.array (2, 0)        (* false：两块不同的 *)
Vector.fromList [1,2] = Vector.fromList [1,2]  (* true：内容相同 *)
[1,2] = [1,2]                                  (* true *)
```

**修法**：要比较内容就给 `ref`/`array` 写自己的比较函数。

```sml
fun refEq (r1, r2) = !r1 = !r2
fun arrayEq (a1, a2) =
    Array.length a1 = Array.length a2
    andalso (let
                 fun go k = k >= Array.length a1
                            orelse (Array.sub (a1, k) = Array.sub (a2, k) andalso go (k + 1))
             in
                 go 0
             end)
```

**另外提醒**：**Basis 并没有保证 `array` 一定是相等类型**。本机三套实现都接受、都按地址比，但换编译器之前建议实测一下。

### 坑 11：`polyEqual` 警告 —— 只在 SML/NJ 出现，但会毁掉逐字节比对

```sml
fun bump (w, tbl) =
    let
        fun ins [] = [(w, 1)]
          | ins ((k, v) :: rest) = if k = w then (k, v + 1) :: rest else (k, v) :: ins rest
    in
        ins tbl
    end

val counts = foldl bump [] words        (* ← 编译 bump 时还不知道 w 是 string *)
```

**现象**：SML/NJ 往 **stdout** 打一条：

```
Warning: calling polyEqual
```

**原因**：SML/NJ 是顺序编译的。编译 `bump` 时 `foldl bump [] words` 还没处理，所以 `w` 的类型未知，`k = w` 只能用**通用多态相等** `polyEqual`。**这个警告走 stdout**，逐字节比对立刻失败。

**修法**：加标注。

```sml
fun bump (w : string, tbl) = ...
```

**教训**：**「不影响运行的警告」在严格验证下是硬失败。** 本书的判定标准要求「stdout 里没有诊断信息」，所以任何编译器警告都必须消灭。这也是为什么 `run-all.sh` 会把 stderr 非空也判失败 —— 一个干净的构建应该是**零输出**的。

### 坑 12：`show` 风格函数与多态打印

SML 没有 `show` / `toString` 的类型类机制。打印任何类型都要**手写一个函数**：

```sml
fun showInt (n : int) = Int.toString n
fun showList (f : 'a -> string) (xs : 'a list) = "[" ^ String.concatWith "," (map f xs) ^ "]"
```

**注意 `showList` 需要两个参数**：**元素打印函数必须显式传进来**，因为 SML 没有「自动找到对应类型的 printer」这回事。这是和 Haskell 的 `Show` 类型类最大的体验差异。

**实践建议**：示例里到处是这些函数，写成 `show`/`sshow`/`showL` 等短名字，避免噪声。

## 32.4 相等性的坑

### 坑 13：`real` 不是相等类型

```sml
val same = (0.1 + 0.2) = 0.3        (* ← 类型错 *)
```

**现象**：`operator and operand don't agree`。

**原因**：`real` **不是**相等类型（Basis 没把它放进 `eqtype`）。因为浮点比较有 `NaN` 这种反例，标准选择了不给它 `=`。

**修法**：

```sml
Real.== (a, b)                       (* IEEE 精确比较，不推荐做业务判断 *)
Real.compare (a, b)                  (* 返回 order *)
abs (a - b) < 1.0E~9                 (* 容差比较，推荐 *)
```

### 坑 14：抽象类型不是相等类型

```sml
signature KEY = sig
    type t                  (* ← 不是 eqtype *)
    val ofInt : int -> t
end

structure A : KEY = struct
    type t = int
    val ofInt = fn n => n
end

val _ = A.ofInt 1 = A.ofInt 1        (* ← 三套实现全部拒绝 *)
```

**三套实现的报错文本（几乎一样）：**

```
SML/NJ : operator and operand don't agree [equality type required]
Poly/ML: Type error: ... is not an equality type
MLton  : Type error: equality type required
```

**原因**：签名里写 `type t` 表示「这是一个抽象类型，不保证支持 `=`」。**即使实际实现是 `int`**，约束之后外界也不知道这一点。

**修法**：签名里写 `eqtype t`。

```sml
signature KEYEQ = sig
    eqtype t
    val ofInt : int -> t
end
```

或者导出一个比较函数（不想暴露相等性时）。

```sml
signature KEYNOEQ = sig
    type t
    val ofInt : int -> t
    val eqKey : t * t -> bool
end
```

### 坑 15：`option` 里套抽象类型，`=` 也不可用

```sml
type queue        (* 抽象类型 *)
val q : queue option = ...
val _ = (q = NONE)          (* ← 类型错 *)
```

**原因**：`option` 的相等性**依赖于元素类型的相等性**。元素不是相等类型，`option` 就不是。

**修法**：用 `case` 判断。

```sml
case q of
    NONE => ...
  | SOME v => ...
```

**`case` 判断 `option` 比 `=` 更通用，而且更符合意图** —— 它在所有情况下都能用（不管元素是不是相等类型）。**建议一律用 `case`。**

## 32.5 字符串与字面量

### 坑 16：字符串字面量里的中文 —— 只有 SML/NJ 接受

```sml
val _ = print "中文\n"        (* SML/NJ 通过；Poly/ML 与 MLton 编译失败 *)
```

**现象**：

```
Poly/ML: line 1: unprintable character \231 found in string
MLton  : Error: file.sml 1.1. Extended text constants ... disallowed
```

**原因**：SML'97 规定源码字符集是 ASCII，字符串字面量的字符必须在可打印 ASCII 范围内。SML/NJ 放宽了这条（当作扩展），另两家严格遵守。

**修法**：**字符串字面量只写 ASCII**；中文放到注释里（注释不受这个限制）。

```sml
(* 中文注释完全没问题 *)
val _ = print "Chinese text in comments only\n"
```

**要输出中文**，用十进制转义写 UTF-8 字节：

```sml
val _ = say "==== 22 \231\187\147\230\157\159 ===="     (* 结束 *)
```

`\231\187\147\230\157\159` 就是「结束」两个字的 UTF-8 字节序列。**三套实现解码出的字节完全一致**，所以这个写法是可移植的。

**本书的 `check-literals.py` 就是专门检查这条规则的** —— 它在编译之前扫一遍所有 `.sml`，有非 ASCII 字符串就拦住：

```
$ ./run-all.sh
  字面量检查通过：29 个文件里没有非 ASCII 字符串
```

**这条规则不要靠人盯。** 写成脚本，每次运行都查。

### 坑 17：`#"+">` 是字符，`"+"` 是字符串

```sml
val c = String.sub (s, i)
val _ = if c = "+" then ...        (* ← char 和 string 比较，类型错 *)
val _ = if c = #"+" then ...       (* 正确 *)
```

**`#` 后面跟字符串取第一个字符**，得到 `char`。这是 SML 里唯一的字符字面量语法。

### 坑 18：`"\\n"` 是两个字符，`"\n"` 是一个

```sml
val _ = print "\n"          (* 一个换行符 *)
val _ = print "\\n"         (* 反斜杠 + n，两个字符 *)
```

**转义规则**：

| 写法 | 含义 |
|---|---|
| `\n` `\t` `\r` | 换行 / 制表 / 回车 |
| `\\` | 一个反斜杠 |
| `\"` | 一个双引号 |
| `\ddd` | 十进制 `ddd` 对应的字节（**UTF-8 字节就靠它**） |
| `\^C` | 控制字符（`^` + 大写字母） |

**这个坑在「显示转义后的内容」时最要命**：`escape` 函数就是要把真实的 `#"\n"` 变成可见的 `\n` 两个字符，所以写 `"\\n"`。搞混了会把一行输出拆成好几行，破坏比对。

### 坑 19：`String.tokens` 会吞掉空字段

```sml
String.tokens (fn c => c = #",") "a,,c"      (* ["a","c"]      —— 两个！*)
String.fields (fn c => c = #",") "a,,c"      (* ["a","","c"]   —— 三个 *)
```

**解析 CSV 必须用 `fields`。** 用 `tokens` 的话，`"bob,72,"` 只剩两个字段，缺失值会变成「列数不对」的错误。反过来，**分词要用 `tokens`**，`fields` 会切出一堆空串。

### 坑 20：`Int.fromString` 接受前缀和空白

```sml
Int.fromString "42abc"      (* SOME 42   —— 不报错！ *)
Int.fromString " 42"        (* SOME 42   —— 接受前导空白 *)
Int.fromString ""           (* NONE      —— 这个才有用（空字段 → NONE） *)
```

**修法**：要严格校验就自己检查。

```sml
fun strictInt (s : string) =
    case Int.fromString s of
        NONE => NONE
      | SOME v => if Int.toString v = s then SOME v else NONE
```

注意往返校验会把 `"0042"` 判错（`Int.toString 42 = "42" ≠ "0042"`），所以只适合格式严格的输入。**要更严谨就用 `Substring` + `Int.scan` 判断「剩下的部分是不是空的」。**

### 坑 21：`Real.fromString` 是重载的

```sml
val opt = Real.fromString "3.5"        (* ← 在没有上下文的地方报 unresolved type variable *)
```

**修法**：标注类型。

```sml
val opt = (Real.fromString "3.5" : real option)
```

## 32.6 模块系统

### 坑 22：`include` 不能在 `structure` 里用

```sml
structure S = struct
    include Other          (* ← 三套实现全部语法错 *)
end
```

**报错**：`end expected but include was found`。

**原因**：`include` **是签名层（spec）的构造**，只能出现在 `signature` 里，用来做「签名继承」。它在结构层没有对应物。

**修法**：

```sml
signature VERSIONED = sig
    include BASE           (* 合法：签名里继承 *)
    val version : string
end

structure S = struct
    open Other             (* 结构里用 open 达到类似效果 *)
    val version = "1.0"
end
```

**区别**：`open` 是**值层**的引入（把字段搬进来，可能被后来的声明遮蔽）；`include` 是**签名层**的合并（保证两个签名的字段都在）。**别把两者当同一个东西。**

### 坑 23：`open` 会遮蔽，而且是静默的

```sml
val x = 1
structure A = struct val x = 2 end
open A
val _ = print (Int.toString x)      (* 打印 2 —— 原来的 x 被盖掉了 *)
```

**SML 对遮蔽没有任何警告。** 这在 `open` 多个结构时非常危险。

**修法**：尽量少 `open`，用限定名。

```sml
A.x
```

**或者在 `let` 里局部 `open`**，把遮蔽限制在小范围内：

```sml
let
    open A
in
    ...
end
```

### 坑 24：签名不匹配时，报错信息只说「哪个字段开始不对」

```sml
structure S : SIG = struct
    val f = fn x => x + 1        (* SIG 里声明的是 f : real -> real *)
end
```

**报错**：`Parameter type mismatch: ...` 或者 `value f does not match signature`。

**原因**：可能是 `+` 的重载解析问题（见坑 7），可能是返回值类型不对，也可能是名字拼错。**报错信息往往只指向第一个不匹配的字段**，后面的错误要修完再编译才能看到。

**修法**：**一次修一个，反复编译。** 这正是 SML/NJ 的 REPL 最方便的地方 —— 它有 `use` 和增量编译，改完立刻知道对不对。

## 32.7 I/O 与运行环境

### 坑 25：`OS.FileSys.fileSize` 的返回类型是实现相关的

```sml
Int.toString (OS.FileSys.fileSize path)      (* ← 三家都类型错 *)
```

**实测**：

| 实现 | 返回类型 |
|---|---|
| SML/NJ | `Int64.int` |
| Poly/ML | `Position.int` |
| MLton | `Position.int` |

**修法**：过 `Position`。

```sml
Int.toString (Position.toInt (OS.FileSys.fileSize path))
Position.toString (OS.FileSys.fileSize path)      (* 更安全，不经过 int *)
```

**`Int64` 也别用**：Poly/ML 的 `--script` 模式下根本没加载这个结构（`unbound structure: Int64`）。

### 坑 26：`OS.Process.status` 是抽象类型，但 SML/NJ 恰好实现成 `int`

```sml
Int.toString OS.Process.success        (* SML/NJ 能编译！Poly/ML/MLton 报类型错 *)
```

**现象**：

```
Poly/ML: Type mismatch: expects: [int] but got: [OS.Process.status]
```

**修法**：

```sml
OS.Process.isSuccess OS.Process.success      (* bool *)
not (OS.Process.isSuccess st)                (* 判断「失败」只能这么写：Basis 没有 isFailure *)
```

**这个坑的阴险之处在于「SML/NJ 上能编译」**，所以单实现开发的人永远发现不了。**三通道比对的价值在这里体现得最直接。**

### 坑 27：`inputLine` 带着 `\n`

```sml
SOME line => ...          (* line = "alpha\n"，不是 "alpha" *)
```

**修法**：自己 `chomp`。

```sml
fun chomp (s : string) =
    let
        val n = String.size s
    in
        if n > 0 andalso String.sub (s, n - 1) = #"\n"
        then String.substring (s, 0, n - 1)
        else s
    end
```

`n > 0` 的判断不能省（空串会让 `String.sub (s, ~1)` 抛 `Subscript`）。

**循环终止条件必须是 `NONE`**，不能是「读到空串就停」—— 后者会漏掉文件末尾的空行，或者死循环。

### 坑 28：`openOut` 会截断

```sml
val out = TextIO.openOut path        (* 原有内容全没了 *)
```

**要追加用 `openAppend`。** 关的时候都是 `closeOut`。

### 坑 29：`val o = TextIO.openOut path` —— 不能叫 `o`

**报错**：

```
Error: expression or pattern begins with infix identifier "o"
```

**原因**：`o` 是**函数组合运算符**（infix）。

**修法**：改名（`out`）。

**会撞上的中缀标识符（当变量名会报错）：**

| 名字 | 含义 |
|---|---|
| `o` | 函数组合 `f o g` |
| `div` / `mod` | 整数除/余 |
| `before` | 顺序执行 |
| `quot` / `rem` | **不是**关键字/中缀，是普通函数（`Int.quot`），但有些实现把它当中缀 |

**这个坑在本书里踩了两次**（示例 03 和示例 20），因为 `o` 作为 "output" 的缩写太自然了。

## 32.8 工程与验证层面的坑

### 坑 30：编译器消息走 stdout，会毁掉比对

**三个实现的表现不同**：

| 实现 | 顶层回显 / 警告去哪 |
|---|---|
| SML/NJ | **stdout**（`Control.Print.out`） |
| Poly/ML | **stdout**（`--script` 模式下错误和警告都在 stdout） |
| MLton | **stderr** |

**修法（SML/NJ）**：静音堆。

```sml
val _ = Control.Print.out := { say = fn (_ : string) => (), flush = fn () => () }
val _ = SMLofNJ.exportML "quiet"
```

**关键**：`exportML` **必须是最后一句**。因为堆被加载后，程序从 `exportML` 的下一行继续执行 —— 后面还有语句就会被执行到（比如一个 `OS.Process.exit` 会让每次加载立刻退出）。

**关键**：**`print` 不经过 `Control.Print.out`**，所以静音之后用户程序的输出还在。

**代价**：静音之后编译错误也不打印了，而且 SML/NJ 的退出码会变成 `0`。**所以真正的把关者是「结束标记」**（见坑 31）。

### 坑 31：退出码 0 不代表成功

示例 12 曾经在三通道上**全部退出码 0**，但实际错误是 `unbound type constructor: COUNTER`。**静音堆把错误信息吃掉了。**

**修法**：让程序自己声明「我跑完了」——**每个示例的最后一行打印结束标记**。

```sml
val _ = say "==== 12 \231\187\147\230\157\159 ===="
```

跑不到这一行就说明中途出错了。**这是在「退出码不可靠」的环境下重建可靠性的标准做法。**

**配套做法**：判定失败时，**不带静音堆重跑一遍**，把真实错误暴露给用户。

### 坑 32：示例自己打印的文案不能带 `error:` / `warning:`

**判定标准里有一条「stdout 里没有编译器诊断」**，用的是这个模式：

```bash
grep -qE 'Error:|error:|Warning:|warning:|Static Errors|unhandled exception|Exception- |Matches are not exhaustive'
```

**所以示例自己的 `print` 文案里不能出现这些字样**（比如「no error, no warning:」这种说明性文字），否则会被自己的验证脚本误判成编译失败。

示例 15 就踩过这个坑：输出和另两个通道逐字节一致，但因为这行文案里有 `no error, no warning:`，判定失败。

**修法**：换一种说法。

```sml
(* 原来：*) say "open is plain shadowing: no error, no warning"
(* 改成：*) say "open is plain shadowing: the compiler says nothing"
```

### 坑 33：示例必须把自己擦干净

`run-all.sh` 会把工作目录切到 `build/`，29 个示例 × 3 通道 = 87 次运行。任何一个示例留下临时文件：

- `build/` 不断膨胀
- **目录遍历的个数会变**（示例 20 的 `countEntries`），输出不一致 → 比对失败

**修法**：每个造文件的示例最后都删干净，并且**把删除结果打印出来当断言**。

```sml
val _ = OS.FileSys.remove tmpFile
val _ = say ("cleanup ok -> tmpFile exists = " ^ Bool.toString (OS.FileSys.access (tmpFile, [])))
```

**顺序**：先删文件，再删目录（`rmDir` 只能删空目录）。

### 坑 34：环境里的 `grep` / `sed` 可能是假的（编写机的环境问题）

编写机（macOS + macports）的 PATH 前缀里有一个 shim，会**遮蔽 `grep`/`sed`/`wc`/`head`/`tail`**，偶尔报：

```
Brokered program policy check unavailable
toybox 0.8.13
```

**现象**：脚本里明明该匹配到的行，`grep` 返回空；`sed -i '' 's/a/b/; s/c/d/'` 把脚本当成文件名。

**修法**：在脚本开头把 PATH 钉死。

```bash
PATH="/usr/bin:/bin:$PATH"
```

`awk`、`tr`、`cmp`、`diff`、`sort`、`od` 是真实程序，可以放心用。

### 坑 35：PowerShell 里的两个陷阱（写等价脚本时）

**（1）`-split "[char]10"` 不是换行。**

```powershell
$text -split "[char]10"      # ← 错！被当成正则字符类，匹配 c/h/a/r/1/0 里任意一个字符
```

**修法**：

```powershell
function Split-Lines {
    param([string]$Text)
    if ($null -eq $Text -or $Text -eq "") { return @() }
    return ($Text -split ([string][char]10))
}
```

**（2）`$env:USERPROFILE` 在 macOS 上是空的**，`Get-ChildItem -Path $null` 会退化成「列当前目录」—— 结果真的可能把 `build.ps1` 自己当成 MLton 的二进制文件。

**修法**：退回 `$env:HOME`，并且**判断 pattern 非空再调 `Get-ChildItem`**。

```powershell
$homeDir = $env:USERPROFILE
if (-not $homeDir) { $homeDir = $env:HOME }
```

**（3）控制字符的正则一律写 `\xNN`，不要用反引号转义。**

```powershell
[regex]::Replace($out, '[\x00-\x08\x0B\x0C\x0E-\x1F]', '')
```

反引号转义（`` `10 ``）会被拆成 `1` 和 `0`。

### 坑 36：`OS.Process.isFailure` 不存在（连标准里都没有）

```sml
val ok = OS.Process.isFailure st        (* ← unbound variable or constructor: isFailure *)
```

**现象**：三套实现全部报 `unbound`。

**原因**：**Basis 从来没定义过这个函数。** `OS.Process` 只有 `success` / `failure` 两个**值**和 `isSuccess` 一个判断函数：

```sml
type status
val success   : status
val failure   : status
val isSuccess : status -> bool
val system    : string -> status
val exit      : status -> 'a
val terminate : status -> 'a
val getEnv    : string -> string option
val sleep     : Time.time -> unit
```

**修法**：

```sml
fun isFailure (st : OS.Process.status) = not (OS.Process.isSuccess st)
```

**这条坑的教训不是「名字记错了」，而是「凭印象写文档很危险」**。写这一章时我先写下了 `OS.Process.isFailure`，因为它看起来太对称、太应该存在了。实测 + 查官方文档（`smlfamily.github.io/Basis/os-process.html`）才发现两边都没有。

**「名字看起来应该存在」不是证据。** 涉及标准库 API 的断言，要么实测，要么查文档 —— 别凭语感。

### 坑 37：`Option.isNone` / `List.foldli` 是 SML/NJ 的扩展，另两家没有

```sml
val empty = Option.isNone opt                            (* SML/NJ 通过；另两家报未声明 *)
val sums  = List.foldli (fn (i, v, acc) => acc + i + v) 0 [10, 20]
```

**现象**：

```
Poly/ML: Value or constructor (isNone) has not been declared in structure Option
         Value or constructor (foldli) has not been declared in structure List
MLton  : Undefined variable: Option.isNone.
         Undefined variable: List.foldli.
SML/NJ : 正常
```

**原因**：**Basis 的 `Option` 和 `List` 里都没有这两个函数**（官方文档确认过）。SML/NJ 自己加了它们当便利扩展，另两家严格按标准实现，所以没有。

**修法**：

```sml
fun isNone opt = not (Option.isSome opt)
(* 或者直接模式匹配，这个最通用 *)
case opt of NONE => ... | SOME v => ...

(* 带下标的 foldl 自己写 *)
fun foldli f init xs =
    let
        fun go (_, [], acc) = acc
          | go (i, x :: rest, acc) = go (i + 1, rest, f (i, x, acc))
    in
        go (0, xs, init)
    end
```

**这条和「柯里化 functor 只有 SML/NJ 认」是同一类问题：SML/NJ 提供了标准之外的扩展。**
它的危险在于**反向的**：在 SML/NJ 上写出的、用到了扩展的代码，在另两家上编译不过。**用任何「便利函数」之前，先确认它是标准还是方言。**

### 坑 38：Linux（Arch）的 `smlnj` 包让 `exportML` 直接崩（打包路径残留）

在 Arch Linux 上装官方 `smlnj` 包（`pacman -S smlnj`），跑 2.2 节的静音堆构建：

```bash
$ sml @SMLquiet quiet.sml </dev/null
[autoloading]
unexpected exception (bug?) in SML/NJ: Io [Io: openIn failed on
  "/build/smlnj/src/sml.boot.amd64-unix/smlnj/basis/.cm/amd64-unix/basis.cm",
  No such file or directory]
```

**现象**：普通 `sml` 交互、跑 `use` 全都正常，**一调 `SMLofNJ.exportML` 就崩**。报错里的路径 `/build/smlnj/src/...` 在本机根本不存在。

**原因**：发行版打包时，编译器堆把**打包机（chroot）里的绝对路径**烤进了 `basis.cm` 的引用。REPL 日常用到的库都预载了，所以平时无感；`exportML` 会触发一次完整的自动加载，按烤死的路径去 openIn，立刻炸。

**修法**（任选其一）：

1. `run-all.sh` 已内置自愈：检测到这类日志后，把缺失路径符号链接到真实库目录再重试：

   ```bash
   sudo mkdir -p /build/smlnj/src
   sudo ln -s /usr/lib/smlnj/lib /build/smlnj/src/sml.boot.amd64-unix
   ```

   （真实库目录 = `sml` 二进制所在目录的 `../lib`。）

2. 不用 `exportML` 的方案（换环境时备用）：改用「过滤回显」跑 SML/NJ，或者干脆只在 SML/NJ 通道接受回显噪声、只比对 Poly/ML 与 MLton。代价是放弃 SML/NJ 通道的字节级比对，本书不取。

**这条坑的教训**：**「包管理器装的编译器」不等于「能用的编译器」**。发行版重打包很容易引入这类只在冷门路径上发作的 bug —— 日常交互没问题，一用到高级特性（导出堆、交叉编译、某些优化）就露馅。所以本书的三通道验证脚本必须能在**干净的新机器**上一键跑通，并且把这类环境问题显式报出来，而不是静默跳过。

## 32.9 书本篇扩充的新坑（39–47，全部实测）

2026-09 按《Programming in Standard ML》（Harper）与《Programming with Standard ML》（Myers/Clack/Poon）扩充第 25–31 章时踩的坑，同样全部来自真实报错。

### 坑 39：流的 `take` 惯用写法会多 force 一格（第 25 章）

**现象**：埋在流第三格的 `100 div 0`，明明只 `stake (2, s)` 也会炸出 `Div`。

**原因**：直觉写法 `fun stake (n, Cons (x, rest)) = x :: stake (n-1, force rest)` 在严格语言里，递归调用的实参 `force rest` **在进入函数体、检查 n 之前就被求值**——取前 n 个必然强制第 n+1 格。

**修法**：把「检查 n」与「force」拆成两层（`stake`/`stakeS` 互递归），n 归零就不碰挂起。凡是「惰性工具 + 边界条件」的组合都要这样写。

### 坑 40：`memoize` 包一层，递归调用根本不走表（第 26 章）

**现象**：`memoize fibNaive 25` 的调用计数与朴素版一模一样（242785 次），缓存里只有一条记录。

**原因**：包装函数自己查表，但 `fibNaive` **内部的递归调用直连原函数**。记忆化必须接管递归路径上的每一次调用，外包装碰不到函数体内部。

**修法**：开递归——`fibBody recf n` 把递归点参数化，`memoRec` 提供「查表版的自己」；或者直接上第 25 章的惰性流（流格子就是缓存条目）。

### 坑 41：`val rec` 只收 `fn`，循环数据打不了结（第 26 章）

**现象**：想定义自引用的流 `val ones = Cons (1, delay (fn () => ones))`——`ones` 未绑定就使用，报 `unbound variable`（SML/NJ 的 `val rec lazy` 是私有扩展）。

**修法**：两条路。浅层用 `fun` 打函数结：`fun ones () = Cons (1, delay ones)`；真·共享的循环结构用 **ref 占位 + 回填**：先 `val cell = delay (fn () => raise Fail "unfilled")`，定义完生成器后 `cell := Delayed gen` 回填。

### 坑 42：无参绑定写成 `fun`，三家都拒（第 27 章）

**现象**：`fun empty : 'a queue = Q ([], [])` 报 `function clause with no arguments`（MLton）/ `can't find function arguments`（SML/NJ）。

**原因**：`fun` 是带子句的函数定义，后面必须有参数模式；无参的值只能 `val`。

**修法**：`val empty : 'a queue = Q ([], [])`。构造子作用在值上仍是语法值，多态不受影响。

### 坑 43：想 `handle e => e` 拿到异常本身，类型不过（第 27 章）

**现象**：`qhead empty handle e => e`——被包表达式是 `int`，handler 返回 `exn`，`expression and handler do not agree`。

**原因**：`handle` 的体必须与被包表达式**同类型**。这条老坑在「捕获异常再打 `exnName`」这个新场景里必然触发。

**修法**：用 `exn option ref` 中转：handler 里 `caught := SOME e`（unit），之后从 ref 里取异常。

### 坑 44：`Star` 的不动点方程直译成匹配器，死循环（第 29 章）

**现象**：按 `L* = 1 + L·L*` 直译的 `match (Star r) = k cs orelse match (Times (r, Star r), ...)`，碰到 `Star One`、`(1|a)*`、`(a*)*` 这类**内层可匹配空串**的表达式时挂死。

**原因**：内层匹配空串 ⇒ 递归调用拿到与出发时**完全相同的输入**——原地踏步。数学方程成立靠的是「最小不动点 + 每轮迭代有进展」，直译丢掉了进展条件。

**修法**：成功续延里加进展检查：`if length rest < length cs then 继续循环 else false`。这是 Harper 第 27 章「由证明指导调试」的标准产出。

### 坑 45：Basis 没有随机数；IntInf 的乘法别赌重载（第 30 章）

**现象**：想要随机测试数据——`Random` 结构不存在；写了 `48271 * s`（s 是 `IntInf.int`），重载解析并不总是如你所愿；就算解析成 IntInf，Lehmer 乘积约 10¹⁴ 在 MLton 的 32 位 `int` 上必炸。

**修法**：确定性 LCG（种子固定，三通道才有逐字节一致），中间量走 IntInf 且乘法**显式点开** `IntInf.* (48271, s)`，出口 `IntInf.toInt` 收窄。

### 坑 46：穷尽性逼出来的「死分支」（第 31 章）

**现象**：`splitMin` 这类函数在结构上保证不会收到 `E`，但模式匹配不写 `E` 分支就报 `match non-exhaustive`——而本目录把非穷尽匹配当失败（第 33 章判定 5）。

**修法**：死分支写 `raise Fail "unreachable"`。它兼作文档：读者一眼看出「这个分支在结构上不可达」。别用通配符 `_ => ...` 假装处理了它。

### 坑 47：签名与实现的参数形状必须逐字符一致（第 31 章）

**现象**：签名写 `val insert : 'a dict -> key -> 'a -> 'a dict`（柯里），实现写 `fun insert (d, k, v)`（元组）——`:>` 匹配检查直接拒绝：`value type in structure does not match signature spec`。

**修法**：统一风格。本目录统一元组（与全书示例一致）。另一个同族坑：泛型 functor（参数是 `DICTIONARY`）里对抽象 key 用 `Int.toString`——抽象类型没有打印函数；测试要打印键，先用 `where type key = int` 把签名细化再实例化。

## 32.10 一张速查表

最后把所有坑压缩成一张表，贴在显示器边上用：

| # | 现象 | 一句话修法 |
|---|---|---|
| 1 | `syntax error: inserting LET` | `handle` 别顶格 |
| 2 | 分号后面的语句没执行 | 表达式层用 `;` 必须加括号 |
| 3 | `Undefined variable: xs` | `fn xs => (e1; e2)` 加括号 |
| 4 | 注释提前结束 | 注释可嵌套，`(*` / `*)` 要配平 |
| 5 | `unbound type constructor: SIG` | 签名不是类型，要用 `functor` |
| 6 | `operator and operand do not agree` | `type` 别名不是约束，加`: 返回类型` |
| 7 | 签名不匹配但代码看着没问题 | 重载运算符加标注 |
| 8 | `unresolved flex record` | `map #1` 改成 `map (fn (k,_) => k)` |
| 9 | `Warning: calling polyEqual` | 给函数参数加类型标注 |
| 10 | `ref 1 = ref 1` 是 `false` | `ref`/`array` 比地址，自己写比较 |
| 11 | `real` 不能 `=` | 用 `Real.==` 或容差比较 |
| 12 | `equality type required` | 签名里写 `eqtype` |
| 13 | 中文编译失败 | 字符串只用 ASCII，中文进注释 |
| 14 | `char` 和 `string` 比较 | 字符写 `#"+">` |
| 15 | 输出多出空行 | `"\n"` vs `"\\n"` 分清楚 |
| 16 | CSV 列数不对 | 用 `String.fields` 不用 `tokens` |
| 17 | `Int.fromString "42abc"` 返回 `SOME 42` | 自己校验，别信 `fromString` |
| 18 | `include` 语法错 | `include` 只能用在 `signature` 里 |
| 19 | 值被静默覆盖 | `open` 会遮蔽，用限定名 |
| 20 | `fileSize` 类型不匹配 | 过 `Position.toInt` |
| 21 | `OS.Process.status` 类型不匹配 | 用 `isSuccess` |
| 22 | 每行都多个换行 | `inputLine` 带 `\n`，要 `chomp` |
| 23 | 文件被清空 | 追加用 `openAppend` |
| 24 | `infix identifier "o"` | 别把变量叫 `o` |
| 25 | 输出里有类型回显 | 用静音堆（`Control.Print.out`） |
| 26 | 退出码 0 但示例是错的 | 用结束标记把关 |
| 27 | 判定说「stdout 里有编译器诊断」 | 自己的文案别写 `error:`/`warning:` |
| 28 | `build/` 越来越胖 | 示例自己擦干净 |
| 29 | `grep` 返回空 | PATH 里钉上 `/usr/bin:/bin` |
| 30 | `OS.Process.isFailure` 未声明 | 标准里就没有，自己写 `not (isSuccess st)` |
| 31 | `Option.isNone` / `List.foldli` 在另两家未声明 | 都是 SML/NJ 扩展，自己写 `not o isSome` / `foldli` |
| 32 | Arch 上 `exportML` 报 `openIn failed on "/build/..."` | 打包路径残留；把缺失前缀符号链接到真实 `../lib`（`run-all.sh` 自动修，坑 38） |
| 39 | 取流前 n 个却把第 n+1 格也强制了 | 边界检查先于 force，拆成 `stake`/`stakeS` 两层 |
| 40 | `memoize` 包装后调用数没降 | 递归不走表；改开递归 `memoRec` 或惰性流 |
| 41 | 自引用流 `val` 递归报未绑定 | `val rec` 只收 `fn`；用 `fun` 结或 ref 回填 |
| 42 | `fun empty = ...` 报无参函数子句 | 无参绑定用 `val` |
| 43 | `handle e => e` 类型不合 | 体须同型；`exn option ref` 中转再 `exnName` |
| 44 | `Star` 直译 `1 + L·L*` 死循环 | 内层可空则原地踏步；续延里加 `length` 进展检查 |
| 45 | 要随机数据 / IntInf 乘法重载翻车 | Basis 无 Random；写确定性 LCG，`IntInf.*` 显式点开 |
| 46 | 不可达分支被非穷尽匹配卡住 | `raise Fail "unreachable"` 占位，别用 `_` 装样子 |
| 47 | `:>` 报签名不匹配 / 抽象 key 没法打印 | 参数形状（元组 vs 柯里）逐字符对齐；打印先 `where type` 钉住 |

**这张表里的每一条都对应本书某个示例里的一行注释。** 真正写代码时会遇到的大概是其中的五到八条 —— 但不知道是哪五到八条，所以值得通读一遍。
