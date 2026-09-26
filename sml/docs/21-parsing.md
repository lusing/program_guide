# 21 · 解析：词法分析与递归下降

> 对应示例：`examples/19-parsing.sml`


**SML 标准库里没有正则表达式。** 没有 `String.split regex`，没有 `replaceAll`，连 `String.indexOf` 都不是每个实现都有（MLton 就没有）。这听起来像是个严重缺陷，但实际写下来会发现：**一个够用的解析器比想象中短得多**。

示例里从零写了一个完整的算术表达式解释器 —— 从字符串到 `token` 列表，再从 `token` 列表到求值结果，全程约 80 行。

## 21.1 词法分析：用 `datatype` 定义 token

```sml
datatype token =
    NUM of int
  | PLUS
  | MINUS
  | TIMES
  | DIV
  | LPAREN
  | RPAREN
```

**第一步是选对数据表示。** 用 `datatype` 而不是「字符串 + 标签」，好处在下游体现：

```sml
fun tokShow t =
    case t of
        NUM v => "NUM " ^ Int.toString v
      | PLUS => "+"
      | MINUS => "-"
      | TIMES => "*"
      | DIV => "/"
      | LPAREN => "("
      | RPAREN => ")"
```

**七个子句，一个都不能少。** 如果漏掉 `RPAREN`，编译器会报 `match nonexhaustive`。这就是第 9 章讲过的：**`datatype` 让编译器帮你检查「有没有情况漏掉」**。在 C 里用 `enum` + `switch` 也有类似效果，但 C 的 `switch` 漏掉分支只是个警告，而 SML 的穷尽性检查是**只要开了 `-C` 严格选项就是错误**。

更关键的是：**将来给 `token` 加一个 `POWER` 构造子，所有 `case` 都会立刻报非穷尽**。编译器会把「你还有哪些地方需要改」列成一张清单给你。这在解析器这种「token 种类 × 处理位置」的组合爆炸场景里，价值极大。

## 21.2 手写扫描器：三段式循环

```sml
fun tokenize (s : string) =
    let
        val n = String.size s

        fun skip i = if i < n andalso Char.isSpace (String.sub (s, i)) then skip (i + 1) else i

        fun digits (i, acc) =
            if i < n andalso Char.isDigit (String.sub (s, i))
            then digits (i + 1, acc ^ String.str (String.sub (s, i)))
            else (i, acc)

        fun go (i, acc) =
            let
                val i = skip i
            in
                if i >= n then rev acc
                else
                    let
                        val c = String.sub (s, i)
                    in
                        if Char.isDigit c then
                            let
                                val (j, ds) = digits (i, "")
                            in
                                go (j, NUM (valOf (Int.fromString ds)) :: acc)
                            end
                        else if c = #"+" then go (i + 1, PLUS :: acc)
                        ...
                        else raise Fail ("bad character at offset " ^ Int.toString i)
                    end
            end
    in
        go (0, [])
    end
```

结构拆开看：

| 函数 | 职责 | 返回 |
|---|---|---|
| `skip` | 跳过空白，返回第一个非空白的位置 | `int` |
| `digits` | 连续吃掉数字，返回（新位置，数字串） | `int * string` |
| `go` | 主循环，逐字符分派 | `token list`（逆序累积） |

**三个函数都是尾递归的**，状态全部走参数。这是第 11 章「累积器消递归」的手法在真实代码里的运用。

几个真实细节：

**（1）`#"+">` 是字符字面量**。`#` 后面跟一个双引号字符串，取它的第一个字符，得到 `char`。所以 `c = #"+"` 是 `char` 和 `char` 比较。写成 `c = "+"` 会类型错（`char` vs `string`）—— 这是从字符串处理语言过来的人第一天就会犯的错。

**（2）`~` 也当负号收下**：

```sml
(* SML 源码里取负号写作 ~，这里顺手也接受它 *)
else if c = #"~" then go (i + 1, MINUS :: acc)
```

这是写示例时**真实踩过的坑**。`tokenize "(1+2)*~3"` 最初报 `bad character at offset 6`，因为扫描器只认 `-`。加上这一行之后，SML 源码里怎么写负号，输入串里就能怎么写，语言内外一致。

**（3）用 `rev acc` 而不是 `acc @ [t]`**。累积器是逆序的，最后统一 `rev` 一次。`@` 每次都复制整个列表，放在循环里就是 O(n²)；`rev` 是 O(n)。**这是「累积器逆序 + 最后翻转」模式的又一例**。

**（4）`valOf (Int.fromString ds)` 用得很克制**。`ds` 一定是一串数字（`digits` 保证了），所以 `Int.fromString` 一定返回 `SOME`。**在能证明不失败的地方用 `valOf` 是合理的**；换个场合（比如解析用户输入）就该老老实实处理 `NONE`。

输出：

```
1) tokenize "12 + 34 * 2" = [NUM 12 + NUM 34 * NUM 2]
   tokenize "(1+2)*~3"   = [( NUM 1 + NUM 2 ) * - NUM 3]
```

## 21.3 递归下降：三级文法，三个函数

```sml
fun eval (ts : token list) =
    let
        val pos = ref ts
        ...
        fun factor () = ...
        and term () = ...
        and expr () = ...
    in
        ...
    end
```

**文法（写在示例注释里）：**

```
expr   ::= term (("+" | "-") term)*
term   ::= factor (("*" | "/") factor)*
factor ::= NUM | "-" factor | "(" expr ")"
```

这个文法是**分层的**，每一层对应一个优先级：`expr` 管加减，`term` 管乘除，`factor` 管括号和负号。**递归下降的本质就是「优先级 = 嵌套层级」** —— 想让 `*` 比 `+` 紧，就让 `term` 嵌在 `expr` 里面。

三处实现要点：

**（1）`fun ... and ...` 是互递归**。`factor` 要调 `expr`，`expr` 要调 `term`，`term` 要调 `factor` —— 三个函数互相引用，所以必须用 `and` 串起来（第 9 章讲过）。**写成三个独立的 `fun` 会报 `unbound variable`**，因为 SML 是「先声明后使用」。

**（2）循环部分用内层 `loop` 加累积器**：

```sml
and term () =
    let
        val first = factor ()
        fun loop acc =
            case peek () of
                SOME TIMES => (advance (); loop (acc * factor ()))
              | SOME DIV => (advance (); loop (acc div factor ()))
              | _ => acc
    in
        loop first
    end
```

**注意 `(advance (); loop (...))` 那对括号** —— 又出现了。分号串两个 `unit`/表达式，必须包起来，否则会被当成声明层分隔符。

**（3）`expr` 用 `acc - term ()` 而不是 `acc + ~(term ())`**。看起来是小事，但**浮点场景下这两者的舍入不同**，而且 `acc - x` 在整数上是精确的。写解析器时保持运算符的原始形态，能让求值结果和手算一致。

输出：

```
2) "12 + 34 * 2"        = 80
   "(1 + 2) * (3 + 4)"  = 21
   "2 * (3 + 4) - 10 / 2" = 9
   "100 / 7"            = 14  (integer division)
```

`12 + 34 * 2 = 80` 说明优先级正确（不是 `92`）；`(1+2)*(3+4) = 21` 说明括号正确；`100 / 7 = 14` 说明用的是整数除法 `div`。

## 21.4 用 `ref` 当游标

```sml
val pos = ref ts

fun peek () =
    case !pos of
        [] => NONE
      | t :: _ => SOME t

fun advance () =
    case !pos of
        [] => ()
      | _ :: rest => pos := rest
```

**这是整个解析器里最「不函数式」的地方，也是必要的。** 用 `ref` 存「还没消费的 token 列表」：

- `peek ()` 看一眼下一个 token 但**不消费** —— 前瞻是递归下降必需的
- `advance ()` 把它丢掉

**`peek`/`advance` 的分离是递归下降的关键抽象。** 有了这两个动作，后面的代码读起来就和文法一一对应了：看到 `*` 就 `advance` 然后继续乘。

**`peek` 返回 `token option`**：空表示到末尾了。`case` 的两个分支一个返回 `NONE`、一个返回 `SOME t`，调用方必须处理两种情况。**这就是「用类型表达失败」**，比 C 里用「返回 NULL / 返回哨兵值」清楚。

**`fun peek () = ...` 里的 `()` 不能省**。`peek` 是 `unit -> token option`，不是 `token list -> token option` —— 它读的是闭包里的 `pos`，不需要参数。所以调用时写 `peek ()`，那两个括号是**真的传了个 `unit` 值**，不是 C 风格的「空参数列表」。SML 没有「零参数函数」这个概念。

## 21.5 错误处理：抛异常 + 调用方 `handle`

```sml
fun factor () =
    case peek () of
        SOME (NUM _) =>
            (case !pos of
                 NUM v :: rest => (pos := rest; v)
               | _ => raise Fail "unreachable")
      | SOME MINUS => (advance (); ~ (factor ()))
      | SOME LPAREN =>
            (advance ();
             let
                 val v = expr ()
                 val _ =
                     case peek () of
                         SOME RPAREN => advance ()
                       | _ => raise Fail "missing closing parenthesis"
             in
                 v
             end)
      | _ => raise Fail "expected a number or ("
```

**注意 `SOME (NUM _)` 那个分支里的 `case !pos of ... | _ => raise Fail "unreachable"`** —— 看着啰嗦，但这是有原因的：

外层 `case peek ()` 只告诉了我们「下一个是 `NUM`」，没把里面的值**绑出来**。要从 `ref` 里取出值并同时推进，必须**再检查一次**。这个 `"unreachable"` 分支永远不会执行，但**写它是必要的** —— 否则编译器报非穷尽匹配，而且这个 `case` 就是一个合法的「断言」。

更好的写法是把 `ref` 换成「返回（值，新状态）」的纯函数式风格，但那样三个函数都得来回传状态，代码会长很多。**解析器是「局部可变状态」最能接受的场景之一** —— 因为状态被完全关在 `eval` 的 `let` 里，外面看不见。这和 Windows 里「第 18 章闭包封状态」是同一个思路。

`safeCalc` 把异常转成文本：

```sml
fun safeCalc s =
    (Int.toString (calc s))
    handle Fail msg => "raised Fail / " ^ msg
```

```
3) "1 + "      -> raised Fail / expected a number or (
   "1 + $2"    -> raised Fail / bad character at offset 4
   "1 2"       -> raised Fail / trailing tokens after expression
   "(1 + 2"    -> raised Fail / missing closing parenthesis
```

**四种错误，四条消息，都是给用户看的。** 注意 `handle` 的写法：

```sml
fun safeCalc s =
    (Int.toString (calc s))
    handle Fail msg => ...
```

`handle` **不能顶格**！如果写成：

```sml
fun safeCalc s =
    (Int.toString (calc s))
handle Fail msg => ...        (* 语法错：inserting LET *)
```

就会报 `syntax error: inserting LET`。原因是第 3 章讲过的规则：**一个声明在「顶格换行」处结束**，而 `handle` 是表达式的一部分，必须缩进在同一个表达式里。

**`Fail msg` 这个模式把异常携带的字符串绑出来**。`Fail` 是标准异常，携带 `string`。自定义异常也可以携带值（第 12 章讲过参数化异常）。

**另一条自我约束**（示例注释里专门写了）：`run-all.sh` 的 `has_diag` 会把 stdout 里出现 `error:` / `warning:` / `Error:` / `Warning:` / `unhandled exception` / `Exception- ` 的行判成编译器诊断。所以**示例自己打印的文案不能带上这些字样**，否则会被自己的验证脚本误判。这里的消息用 `raised Fail / ...` 的形式，纯是为了可读性。

## 21.6 `String.tokens` vs `String.fields`：空字段的手感差异

```sml
val _ = say ("4) String.tokens \",\" \"a,,c\" = "
             ^ sshow (String.tokens (fn c => c = #",") "a,,c"))
val _ = say ("   String.fields \",\" \"a,,c\" = "
             ^ sshow (String.fields (fn c => c = #",") "a,,c"))
```

```
4) String.tokens "," "a,,c" = ["a","c"]
   String.fields "," "a,,c" = ["a","","c"]
   tokens on "  a  b  "     = ["a","b"]
```

**这两个函数的区别是 CSV 解析里最经典的坑：**

| 函数 | 连续分隔符 | 首尾分隔符 | 适合 |
|---|---|---|---|
| `String.tokens` | 合并成一个 | 忽略 | 空白分词（`"  a  b  "` → `["a","b"]`） |
| `String.fields` | **各产生一个空字段** | **产生空字段** | CSV（`"a,,c"` → `["a","","c"]`） |

**解析 CSV 一定要用 `fields`。** 用 `tokens` 的话，`"bob,72,"` 会被切成 `["bob","72"]` 两个字段，而实际上是三个（第三列是空的）—— **缺失值会变成「列数不对」的错误**。第 24 章的综合项目里，`parseStudent` 就靠 `fields` 才能正确识别空字段。

反过来说，**分词用 `tokens` 才对**。`String.tokens Char.isSpace "  a  b  "` 优雅地忽略多余空白；用 `fields` 会切出一堆空串。

## 21.7 `Substring.position`：不切整个串就找到分隔符

```sml
fun splitKV (line : string) =
    let
        val (key, rest) = Substring.position "=" (Substring.full line)
    in
        if Substring.isEmpty rest then NONE
        else SOME (Substring.string key, Substring.string (Substring.triml 1 rest))
    end
```

**`Substring` 是「字符串的一段视图」，不复制内容。** `Substring.position sep ss` 返回一对 `(分割点之前, 从分隔符开始)` —— 返回值本身就是子串，共享底层字符串。

```
5) splitKV "host=localhost" = "host" -> "localhost"
   splitKV "a=b=c"         = "a" -> "b=c"
   splitKV "nokey"         = NONE (no separator)
```

三个行为都值得注意：

- **`"a=b=c"` 切成 `"a"` 和 `"b=c"`**：只按**第一个** `=` 切。这正是 key=value 场景想要的（value 里可以有 `=`）。
- **没有分隔符返回 `NONE`**：用 `Substring.isEmpty rest` 判断。`position` 找不到时就返回 `(整个串, 空子串)`，所以「剩下的部分为空」＝「没找到」。
- **`Substring.triml 1 rest` 丢掉那个 `=` 本身**。`triml n` 从左边裁掉 n 个字符，就是把分隔符扔掉。

**为什么用 `Substring` 而不是先 `String.tokens` 再拼回来？** 因为 tokens 会把 `"a=b=c"` 切成三段，再拼回 `"b=c"` 要额外分配。`Substring` 从头到尾没复制过中间结果。**处理大文件时这个差别是实打实的。**

**注意最后要 `Substring.string` 转回普通 `string`**，因为返回值类型是 `string * string`。子串是「借来的」视图，不能逃出原串的生命周期 —— SML 用 GC 管理，所以安全，但接口类型是分开的。

## 21.8 数字解析的两个坑

```sml
val _ = say ("6) Int.fromString \"42\"     = " ^ intShow (Int.fromString "42"))
val _ = say ("   Int.fromString \"42abc\"  = " ^ intShow (Int.fromString "42abc") ^ "  (prefix!)")
val _ = say ("   Int.fromString \"abc\"    = " ^ intShow (Int.fromString "abc"))
val _ = say ("   Int.fromString \" 42\"     = " ^ intShow (Int.fromString " 42"))

val realOpt = (Real.fromString "3.5" : real option)
```

```
6) Int.fromString "42"     = SOME 42
   Int.fromString "42abc"  = SOME 42  (prefix!)
   Int.fromString "abc"    = NONE
   Int.fromString " 42"     = SOME 42
   Real.fromString "3.5"    = SOME 3.50
```

**坑一：`Int.fromString` 接受前缀。** `"42abc"` 返回 `SOME 42`，不报错。这是 Basis 明确规定的行为（返回「最长有效前缀」），但和大多数人的直觉相反。**所以校验用户输入不能只判 `SOME`/`NONE`，还要确认消费完了**：

```sml
fun strictInt (s : string) =
    case Int.fromString s of
        NONE => NONE
      | SOME v => if Int.toString v = s then SOME v else NONE    (* 往返校验 *)
```

或者更省事的办法是用 `Substring` + `Int.scan` 拿到「停在哪」，再判断剩下的部分是不是空的。往返校验的写法有个缺点：前导零和 `+` 号会被判错（`Int.toString 42 = "42" ≠ "0042"`），所以只适合「格式严格的输入」。

**坑二：`Real.fromString` 是重载的。** 它属于 `StringCvt` 的扫描函数族，同时可以解析出 `real` 和各种整数类型。所以在没有上下文的地方要**显式标注类型**：

```sml
val realOpt = (Real.fromString "3.5" : real option)
```

不标注的话，在 `case` 或 `let` 里会报 `unresolved type variable`。

**坑三：`Int.fromString " 42" = SOME 42`** —— **前导空白被接受了**。所以「用 `fromString` 做严格校验」这件事，从各个角度看都不成立。要严格就自己扫。

## 21.9 词频统计：一趟 `foldl` + 一个必须的类型标注

```sml
fun wordCount (text : string) =
    let
        val words = String.tokens Char.isSpace (String.translate (fn c => String.str (Char.toLower c)) text)

        (* w 必须标注类型！否则 SML/NJ 在编译这条 fun 时还不知道 w 是 string
           （foldl 的调用在它之后），此时 k = w 会被判成多态相等，
           于是往 stdout 打一条 "Warning: calling polyEqual"，
           直接把逐字节比对搞坏。 *)
        fun bump (w : string, tbl) =
            let
                fun ins [] = [(w, 1)]
                  | ins ((k, v) :: rest) =
                        if k = w then (k, v + 1) :: rest else (k, v) :: ins rest
            in
                ins tbl
            end
    in
        foldl bump [] words
    end
```

**这段注释记录了一个真实的、非常隐蔽的坑。** 展开说：

SML/NJ 在编译 `bump` 的时候，`foldl bump [] words` 这个调用还**没被处理**（SML 是顺序编译的），所以编译器**不知道 `w` 是 `string`**。于是 `k = w` 里的 `=` 无法确定是「整数相等」还是「字符串相等」还是别的，编译器就生成一个**通用的多态相等函数** `polyEqual`，并往 stdout 打一条警告：

```
Warning: calling polyEqual
```

**这条警告进了 stdout，逐字节比对立刻失败。** 在单实现开发里这是「不影响运行的警告」，但在本教程的判定标准下它是硬失败。

**修法就是加一个类型标注：`fun bump (w : string, tbl)`。** 标注之后编译器立刻知道 `w` 是 `string`，于是用 `String.=` 而不是 `polyEqual`，警告消失。

**注意 MLton 和 Poly/ML 没有这个问题** —— 它们能看到整个文件再编译，或者用不同的多态相等实现方式。所以这个坑**只在 SML/NJ 上出现**，是「三通道比对发现单实现问题」的又一个实例。

`ins` 用关联表（`(string * int) list`）实现：新词追加在表尾，所以**输出顺序就是「首次出现顺序」，完全确定**：

```
7) word counts -> the:3 quick:1 brown:1 fox:2 jumps:1 over:1 lazy:1 dog:1
   most frequent -> the (3)
```

**输出的确定性是刻意设计的。** 如果改用哈希表（SML 没有标准哈希表，但 `SML/NJ` 的 `HashTable` 有），遍历顺序就依赖哈希函数，三通道必然不同。**示例代码为了「可逐字节比对」，主动放弃了 O(1) 查找，选了 O(n) 的有序关联表。** 这个取舍在写可验证的代码时是常态。

「找出现次数最多的词」那个 `foldl` 值得一提：

```sml
(fn (w, c) => w ^ " (" ^ Int.toString c ^ ")")
    (foldl (fn ((w, c), (bw, bc)) => if c > bc then (w, c) else (bw, bc))
           ("", 0) tbl)
```

累积器的类型是 `string * int`，初值 `("", 0)`。**注意 `(fn ...)` 外面那对括号**：`(fn x => ...) arg` 里的括号是必要的，否则 `fn` 的函数体会一直吃到行尾。

## 21.10 回文：`String.translate` 当过滤器

```sml
fun normalize (s : string) =
    String.translate (fn c => if Char.isAlpha c then String.str (Char.toLower c) else "") s

fun isPalindrome (s : string) =
    let
        val t = normalize s
    in
        t = String.implode (rev (String.explode t))
    end
```

```
8) "A man, a plan, a canal: Panama" -> true
   "hello world" -> false
```

**`String.translate` 是 SML 里最被低估的函数。** 它的签名是 `(char -> string) -> string -> string` —— **每个字符映射到任意字符串**。这一个函数同时能当：

- **映射**：`fn c => String.str (Char.toUpper c)` 转大写
- **过滤**：`fn c => ""` 直接丢掉（映射成空串）
- **展开**：`fn c => String.str c ^ String.str c` 每个字符重复两遍

比 `String.map`（只能 `char -> char`）强得多。**任何「逐字符处理字符串」的需求，先想 `translate` 能不能干。**

`isPalindrome` 的两步：先 `normalize`（只留字母、转小写），再和反转比较。`String.explode` / `String.implode` 在 `string` 和 `char list` 之间往返，中间用 `rev` 反转。

**`t = String.implode (rev (String.explode t))` 里最后那个 `=` 是字符串相等** —— 这里类型是确定的（`t` 来自 `normalize` 的返回值），所以不会有 21.9 那个 `polyEqual` 问题。

## 21.11 本章小结：解析器的 SML 形状

写完整这一章，几个模式值得单独记住：

| 需求 | SML 写法 |
|---|---|
| 表示「一种 token」 | `datatype` + 穷尽性检查 |
| 逐字符扫描 | 尾递归 + `String.sub` + 下标累积器 |
| 累积结果 | 逆序累积 + 最后 `rev` |
| 前瞻与消费 | `ref` 游标 + `peek`/`advance` 两个动作 |
| 优先级分层 | 互递归的 `fun ... and ...`，每层一个函数 |
| 报错 | `raise Fail "..."`，调用方 `handle` |
| 切分字符串 | 分词用 `tokens`，CSV 用 `fields` |
| 定位分隔符 | `Substring.position`（不复制） |
| 逐字符变换 | `String.translate`（映射/过滤/展开三合一） |
| 严格校验数字 | 别用 `fromString` 判成功，它接受前缀和空白 |

**核心结论：没有正则不等于不能做解析。** 递归下降 + `datatype` + 模式匹配这套组合，在**文法明确**的场景下比正则更好读、更能给出好错误、更能被编译器检查。正则真正不可替代的地方是「一次性提取」（日志字段、日期格式），而那种场景用 `Substring` + `String.translate` 手写也就十几行。

---
