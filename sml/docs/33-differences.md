# 33 · 三实现差异清单与可移植写法

对应示例：全部 29 个示例的三通道比对结果

上一章讲的是 **SML 语言本身的坑**（换个实现也一样）。这一章讲的是另一类问题：**同一个语言标准，三套实现的自由度有多大。**

这些差异不是 bug。SML'97 是一个**「有些地方故意没定死」**的标准：小数打印几位、`int` 多少位、错误消息写什么、目录按什么顺序列 —— 它把这些留给实现。**所以「跨实现的 SML 代码」和「单实现的 SML 代码」写作要求是不一样的。**

本教程用三条通道，就是为了把这批「自由度」全部找出来，并且**每一条都给出可移植的写法**。

## 33.1 三条通道是怎么搭起来的

| 通道 | 实现 | 版本 | 角色 |
|---|---|---|---|
| 主 | **SML/NJ** | 110.99.9 | 生态最全、报错友好、编译最快；macOS 在 `/opt/local/bin/sml`，Linux 在 `/usr/lib/smlnj/bin/sml`（PATH 里有 `sml` 即可） |
| 对照 | **Poly/ML** | 5.9.2 | 报错文本与 SML/NJ 完全不同，能暴露方言依赖；macOS 在 `/opt/local/bin/poly`，Linux 在 `/usr/bin/poly` |
| 最严 | **MLton** | 20241230 | 整体优化编译器，标准符合性最好，也最挑剔 |

**运行方式各不相同**（`quiet.<后缀>` 的后缀取 `sml @SMLsuffix`：macOS 是 `amd64-darwin`，Linux 是 `amd64-linux`）：

```bash
# SML/NJ：交互式，从 stdin 读 use 命令
printf 'use "19-parsing.sml";\n' | sml @SMLquiet "@SMLload=quiet.amd64-linux"

# Poly/ML：脚本模式
poly -q --script 19-parsing.sml </dev/null

# MLton：先编译成原生可执行文件，再运行
mlton -output 19-parsing 19-parsing.sml && ./19-parsing
```

**四个「必须记得」的调用细节：**

1. **SML/NJ 必须配静音堆**（见 33.6），否则顶层回显会污染 stdout。
2. **Poly/ML 必须加 `</dev/null`**。它的选项解析出错时会**回退到读 stdin**，然后**挂在那儿等输入**（实测被 SIGTERM 杀掉，退出码 137）。`poly --version` 不加重定向都会挂。
3. **macOS 上，MLton 编译时会刷 ld 警告**。本机的 MLton 二进制是给 macOS 13 编的，系统是 12.7，所以每次链接都有约 169 行：

   ```
   ld: warning: object file (...) was built for newer macOS version (13.0) than being linked (12.7)
   ```

   退出码是 **0**，警告在 **stderr**。验证脚本会把这类行过滤掉（`grep -v 'was built for newer macOS'`），并且**编译成功就删掉日志文件**，否则 `build/` 会被撑爆。**Linux 上无此问题**（发行版包与系统配套）。
4. **Linux（Arch）上，SML/NJ 的 `exportML` 会被打包 bug 绊倒**（坑 38：openIn 一个不存在的 `/build/...` 路径）。`run-all.sh` 会自动建符号链接修复；手工搭环境时照坑 38 的修法处理。

**三条通道的输出逐字节比对。** 比对的不是「看起来一样」，是 `cmp` 级别的完全相同。

## 33.2 完整的差异清单（17 条，全部实测）

| # | 项目 | SML/NJ | Poly/ML | MLton |
|---|---|---|---|---|
| 1 | 默认 `int` 位宽 | 63 位 | 63 位 | **32 位** |
| 2 | 字符串里的原始 UTF-8 | 接受 | **拒绝** | **拒绝** |
| 3 | `Real.toString 1.0` | `1` | `1.0` | `1` |
| 4 | `Real.fmt (GEN (SOME 6)) 1.0` | `1` | `1.0` | `1` |
| 5 | `Real.fmt (FIX (SOME 0)) 3.5` | `3` | `4` | `4` |
| 6 | `Real.fmt (FIX (SOME 17)) 0.3` | `0.30000000000000000` | `0.29999999999999999` | `0.29999999999999999` |
| 7 | `General.exnMessage Div` | `divide by zero` | `Div` | — |
| 8 | `String.index` | 有 | 有 | **没有** |
| 9 | `Int64` 结构 | 有 | `--script` 下**没有** | 有 |
| 10 | `OS.FileSys.fileSize` 返回类型 | `Int64.int` | `Position.int` | `Position.int` |
| 11 | `OS.Process.status` | 恰好是 `int` | 抽象类型 | 抽象类型 |
| 12 | 柯里化 functor `functor F (A:S1) (B:S2)` | 接受 | 语法错 | 语法错 |
| 13 | 无约束重载运算符的解析 | 默认 `int` | 用签名期望类型反推 | 默认 `int` |
| 14 | 编译警告的去向 | stdout | stdout | **stderr** |
| 15 | `Warning: calling polyEqual` | 会有 | 没有 | 没有 |
| 16 | 出错时的退出码 | 直接跑是 1；经静音堆变 0 | 实测有时仍是 0 | 1 |
| 17 | SML/NJ 的标准外扩展：`Option.isNone`、`List.foldli` | **有** | 没有 | 没有 |

**每一条都对应本书某个示例或某次实测。** 下面逐条说清楚。

## 33.3 逐条拆解

### 差异 1：`int` 位宽 —— 最容易被忽视的一条

```sml
val _ = say (Int.toString (Int.maxInt))
```

| 实现 | `Int.maxInt` |
|---|---|
| SML/NJ | `4611686018427387903`（$2^{62}-1$，63 位） |
| Poly/ML | `4611686018427387903` |
| MLton | `2147483647`（$2^{31}-1$，**32 位**） |

**MLton 的默认 `int` 是 32 位。** 这是本清单里唯一会让**计算结果本身出错**的差异：

```sml
fun lcm (a, b) = a * b div gcd (a, b)      (* 先乘后除：MLton 上会溢出 *)
fun lcm (a, b) = a div gcd (a, b) * b      (* 正确：先除后乘 *)
```

SML/NJ 和 Poly/ML 的 63 位 `int` 能装下 $a \times b$，所以「先乘」的版本在那两家上跑得好好的；**MLton 上同样的代码会溢出**。

**可移植写法**：

- **需要 64 位就用 `Int64`**（但要先确认 Poly/ML 的 `--script` 模式里有没有它 —— 差异 9）。
- **算中间结果时先除后乘**，别让中间值超过 $2^{31}$。
- **从 `Int.maxInt` 反推能存多大的值**，不要硬编码。

**这条差异直接导致 `02-types.sml` 被登记进已知差异表** —— 那个示例刻意打印了 `Int.maxInt`。

### 差异 2：字符串里的非 ASCII —— 本教程的「头号敌人」

```sml
val _ = print "中文\n"
```

| 实现 | 结果 |
|---|---|
| SML/NJ | 通过 |
| Poly/ML | `unprintable character \231 found in string` |
| MLton | `Extended text constants ... disallowed` |

**这是本教程投入最多精力的一条。** 因为它不是「输出格式不同」，而是**根本编译不过**。

**可移植写法（本书全书的做法）：**

1. **所有字符串字面量只写 ASCII**
2. **中文只出现在注释里**（注释不受限制）
3. **需要输出非 ASCII 字节时用十进制转义**

```sml
val _ = say "==== 22 \231\187\147\230\157\159 ===="     (* 「结束」两个字的 UTF-8 字节 *)
```

**配套动作：`check-literals.py`。**

这是一个 Python 脚本，在编译**之前**扫一遍所有 `.sml`：

```bash
if ! python3 "$ROOT/check-literals.py" "$EXDIR"/*.sml; then
    echo "字面量预检查未通过，先改好再编译。" >&2
    exit 2
fi
```

它的工作：

- 词法扫描，跳过**嵌套**的 `(* *)` 注释
- 处理 `\` 转义和 `#"x"` 字符字面量
- 报告任何含 `ord > 127` 字符的字符串字面量
- **顺便检查注释深度是否配平**（没配平说明有嵌套注释写错了）

正常输出：

```
字面量检查通过：29 个文件里没有非 ASCII 字符串
```

**为什么值得专门写个脚本？** 因为这条规则的违反是**静默的**（在 SML/NJ 上完全正常），而代价是**另两个通道全灭**。**靠人盯不住，靠脚本才能守住。**

**这是本书最值得带走的一条工程实践**：**如果一个规则会在某个通道上静默通过、在另一个通道上炸掉，就把它变成运行前的自动检查。**

### 差异 3–6：实数格式化

```sml
val _ = say ("10) Real.toString 1.0            = " ^ Real.toString 1.0)
val _ = say ("    Real.fmt (GEN (SOME 6)) 1.0  = " ^ Real.fmt (StringCvt.GEN (SOME 6)) 1.0)
val _ = say ("    Real.fmt (FIX (SOME 0)) 3.5  = " ^ Real.fmt (StringCvt.FIX (SOME 0)) 3.5)
val _ = say ("    Real.fmt (FIX (SOME 17)) 0.3 = " ^ Real.fmt (StringCvt.FIX (SOME 17)) 0.3)
```

| 表达式 | SML/NJ | Poly/ML | MLton | 成因 |
|---|---|---|---|---|
| `Real.toString 1.0` | `1` | `1.0` | `1` | 整值实数带不带 `.0` |
| `GEN (SOME 6) 1.0` | `1` | `1.0` | `1` | 同上 |
| `FIX (SOME 0) 3.5` | `3` | `4` | `4` | `.5` 平局的舍入方向 |
| `FIX (SOME 17) 0.3` | `0.30000000000000000` | `0.29999999999999999` | 同 Poly/ML | 末位十进制舍入算法 |

**三类成因：**

- **整值实数的形态**（差异 3、4）：`1.0` 打印成 `1` 还是 `1.0`，Basis 没有规定。
- **`.5` 平局**（差异 5）：`3.5` 保留 0 位小数时往上还是往下，Basis 没有规定。Poly/ML / MLton 选 half-to-even（→ `4`），SML/NJ 选向下（→ `3`）。
- **第 17 位的精度**（差异 6）：这里 SML/NJ 反而是**更对**的那个 —— `0.3` 的二进制真值略小于 0.3，正确舍入到 17 位有效数字是 `0.30000000000000000`，SML/NJ 给对了，另两家给的是截断值。

**可移植写法（第 20 章总结过）：**

```sml
fun fx (r : real) = Real.fmt (StringCvt.FIX (SOME 6)) r
```

1. **用 `FIX` 或 `SCI`，不用 `GEN`，不用 `Real.toString`**
2. **小数位数 ≤ 16**（17 位进入末位分叉区）
3. **避开 `.5` 平局**（要四舍五入就自己 `Real.floor (x + 0.5)`）

**这就是 `18-numeric.sml` 第 10 节存在的理由**：它**故意**打印这四行，让差异暴露出来，证明 `run-all.sh` 的差异检测真的在工作。**它是本书唯一一个「故意制造差异」的示例。**

### 差异 7：`exnMessage` 的文本

```sml
val _ = say (General.exnMessage Div)
```

| 实现 | 输出 |
|---|---|
| SML/NJ | `divide by zero` |
| Poly/ML | `Div` |
| MLton | —（未测到稳定值） |

**可移植写法**：**永远不用 `exnMessage` 做逻辑判断或断言**，改用 `exnName`。

```sml
val _ = say (exnName Div)        (* 三家都给 "Div"，可移植 *)
```

`exnName` 返回**构造子的名字**，这是标准规定的；`exnMessage` 返回**给人看的描述**，各家自由发挥。第 23 章的测试框架就用 `exnName` 做断言。

### 差异 8：`String.index` 不是必须有的

Basis **没有**要求实现提供 `String.index`（找字符首次出现的位置）。MLton 就没有。

**可移植写法**：自己写一个。

```sml
fun indexOf (target : char) (s : string) =
    let
        val n = String.size s
        fun go i = if i >= n then NONE
                   else if String.sub (s, i) = target then SOME i
                   else go (i + 1)
    in
        go 0
    end
```

或者用 `Substring.position`（这个是标准要求的）间接实现。

**通用规则：`String` 结构里的函数不是全都「必须有」。** Basis 把函数分成「必需」和「可选」两档，`String.index`、`String.substring` 的部分重载都属于后者。**要用之前先确认它在三个实现上都在**（最省事的办法就是三通道编译一遍）。

### 差异 9–11：`OS` 相关的抽象类型

三条放在一起看，根因相同：**Basis 把「可能超出 `int` 范围」的类型故意留成抽象的。**

| 项目 | SML/NJ | Poly/ML | MLton |
|---|---|---|---|
| `Int64` 结构 | 有 | `--script` 下没有 | 有 |
| `fileSize` 返回类型 | `Int64.int` | `Position.int` | `Position.int` |
| `OS.Process.status` | 恰好是 `int` | 抽象类型 | 抽象类型 |

**可移植写法**：

```sml
Position.toInt (OS.FileSys.fileSize path)         (* 文件大小 *)
OS.Process.isSuccess st                           (* 进程状态，只有这一个判断函数 *)
```

**注意 10 和 11 的「危险程度」不一样：**

- **`fileSize` 会很干脆地类型错** —— 三家都编译不过，所以立刻会发现。
- **`OS.Process.status` 在 SML/NJ 上能编译**（因为它恰好实现成 `int`）—— **单实现开发永远发现不了。** 这就是 33.1 说的「三通道的价值在这里体现得最直接」。

**通用规则：遇到 `OS.` 或 `Time.` 相关的类型不匹配，先查 Basis 是不是把它定义成抽象类型了，而不是硬转。**

### 差异 12：柯里化 functor 只有 SML/NJ 认

```sml
functor F (A : S1) (B : S2) = struct ... end        (* 柯里化形式 *)
```

| 实现 | 结果 |
|---|---|
| SML/NJ | 接受 |
| Poly/ML | 语法错 |
| MLton | 语法错 |

**标准形式是「spec 形式」：**

```sml
functor F (structure A : S1 structure B : S2) = struct ... end
```

**可移植写法**：**一律用 spec 形式**，哪怕只有一个参数。

```sml
functor Times10 (structure N : NUM) = struct ... end        (* 可移植 *)
functor Times10 (N : NUM) = struct ... end                  (* 只在 SML/NJ 上能编译 *)
```

**这条差异值得注意的地方在于：柯里化 functor 是很自然的写法**（尤其来自 OCaml 的人），而它在两家上直接语法错。**SML/NJ 接受它是因为它的方言实现更宽松**，不是因为标准允许。

（顺带：SML'97 标准里**根本没有**这一节的开头那个表格 —— 实际上这个差异不是「SML'97 标准内的差异」，而是**SML/NJ 提供的标准之外的扩展**。同类扩展还有一些，比如 `Vector.fromList` 的某些重载。**用之前先想想「这是标准还是 SML/NJ 方言」。**）

### 差异 13：无约束重载运算符的解析

```sml
signature NUM = sig
    type t
    val add : t * t -> t
end

structure RealNum : NUM = struct
    type t = real
    fun add (a, b) = a + b        (* a、b 的类型从哪来？ *)
end
```

| 实现 | 结果 |
|---|---|
| SML/NJ | 错：推成 `int * int -> int` |
| Poly/ML | 通过：用签名里的 `real * real -> real` 反推 |
| MLton | 错：同 SML/NJ |

**可移植写法**：**显式标注。**

```sml
fun add (a : real, b : real) = a + b
```

**这条差异的波及面比看起来大。** 「因为类型信息不足而需要默认某一侧」的情况在 SML 里到处都是：

- 签名约束的结构里的重载运算符（上面这个）
- `fun makeChecker () = {...}` 返回记录时函数字段里的自由类型变量（第 23 章）
- `Int.fromString` / `Real.fromString` 的重载解析

**统一对策：凡是涉及重载或类型变量的地方，主动加标注。** 标注永远不会有坏处，而不加标注的代码在三家之间的行为差异是**不可预测的**。

### 差异 14–16：编译器消息与退出码

| 项目 | SML/NJ | Poly/ML | MLton |
|---|---|---|---|
| 编译警告的去向 | **stdout** | **stdout** | **stderr** |
| `Warning: calling polyEqual` | 会有 | 没有 | 没有 |
| 出错时的退出码 | 直接跑是 1；经静音堆变 0 | 实测有时仍是 0 | 1 |

**这三条是「工程层面」的差异，处理方式不写在 SML 代码里，而是写在验证脚本里：**

**（1）警告的去向不同** → 判定时**要求 stderr 为空**，同时**过滤 stdout 里的诊断模式**：

```bash
# stderr 非空就是失败
if [ -s "$err" ]; then reasons+=("stderr 非空"); fi

# stdout 里出现这些字样也是失败
grep -qE 'Error:|error:|Warning:|warning:|Static Errors|unhandled exception|Exception- |Matches are not exhaustive' "$out"
```

前面一条抓住 MLton 的警告，后面一条抓住 SML/NJ / Poly/ML 的。**两边都要。**

**（2）`polyEqual` 只在 SML/NJ 出现** → 加类型标注消灭它（第 21 章、坑 11）。**这类「只有一个实现会报的警告」是必须主动消灭的**，因为它会让比对失败，而另两个通道完全看不出问题。

**（3）退出码不可靠** → 用**结束标记**把关（第 22 章、坑 31）。

```sml
val _ = say "==== 22 \231\187\147\230\157\159 ===="
```

示例 12 就是靠这一条被抓住的 —— 三通道退出码全是 0，只有「缺少结束标记」把真实错误暴露了出来。

### 差异 17：SML/NJ 的标准外扩展（`Option.isNone`、`List.foldli`）

```sml
val empty = Option.isNone (SOME 1)                          (* SML/NJ: false；另两家: 未声明 *)
val sums  = List.foldli (fn (i, v, acc) => acc + i + v) 0 [10, 20]
```

| 实现 | `Option.isNone` | `List.foldli` |
|---|---|---|
| SML/NJ | **有**（`isNone (SOME 1) = false`，`isNone NONE = true`） | **有** |
| Poly/ML | 没有 | 没有（`Value or constructor (foldli) has not been declared in structure List`） |
| MLton | 没有 | 没有（`Undefined variable: List.foldli.`） |

**Basis 里这两个都没有**（官方文档确认过 `Option` 只有 `isSome`；`List` 没有 `foldli`）。SML/NJ 自己加了它们当便利函数。

**可移植写法**：

```sml
fun isNone opt = not (Option.isSome opt)
(* 或者直接模式匹配 —— 最通用 *)
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

**这一条和差异 12（柯里化 functor）是同一类：SML/NJ 提供标准之外的扩展。** 它的危险是**反向的** —— 在 SML/NJ 上写出的代码用到了扩展，在另两家上直接编译不过。**用任何「看起来很自然」的便利函数之前，先确认它是标准还是方言。**

**顺带说一件同类的事**：**`OS.Process.isFailure` 连标准里都没有。** 三家实测全部报 `unbound`，因为 Basis 只定义了 `isSuccess`。
**「名字看起来应该存在」不是证据** —— 涉及标准库 API 的断言要么实测、要么查文档。反过来也一样：第 19 章初稿里曾写「`List.take`/`List.drop` 不存在」，实测三家都有，那句话同样站不住。

## 33.4 三套实现完全一致的地方（可以放心用）

差异清单列了 17 条，但**SML 的绝大部分是三家一致的**。下面这些是本书验证过的「可以放心依赖」的部分：

**语言核心：**

- 类型推断的结果（除了差异 13 涉及的重载场景）
- 模式匹配的语义、穷尽性检查的报错
- `datatype`、`option`、异常的定义与使用
- 递归、尾递归、闭包
- `structure` / `signature` / `functor` / `:>` 的语义
- `where type`、`sharing type`、`include`（在签名里）
- `open` / `local` 的作用域规则
- `ref` / `array` / `vector` 的**相等性语义**（`ref`/`array` 比地址、`vector`/`list` 比内容）
- `val rec` / `fun ... and ...` 的互递归
- `Real.round` 的平局行为（三家都是 half-to-even）
- `div`/`mod` 向下取整、`Int.quot`/`Int.rem` 向零截断（三家完全一致）
- `exnName` 的返回值（`Div` / `Subscript` / `Empty` / 自定义异常名）

**标准库：**

- `List` 全家（`map`/`filter`/`foldl`/`foldr`/`mapPartial`/`partition`/`app`/`tabulate`/`take`/`drop`/`last`/`nth`/`concat`/`find`/`exists`/`all`/`revAppend`）—— **没有 `foldli`**
- `Array` / `Vector` 全家
- `String` 的 `substring`/`concat`/`concatWith`/`implode`/`explode`/`tokens`/`fields`/`translate`/`size`/`sub`
- `Char` 的 `isDigit`/`isAlpha`/`isSpace`/`toLower`/`toUpper`
- `Int` 的 `toString`/`fromString`/`min`/`max`/`compare`/`fmt`
- `Real` 的 `fromInt`/`toInt`/`floor`/`ceil`/`round`/`trunc`/`abs`/`==`/`compare`/`fmt`
- `Math` 全家（`sqrt`/`pow`/`sin`/`cos`/`pi`）
- `StringCvt` 的 `padLeft`/`padRight`/`FIX`/`GEN`/`SCI`/`HEX`/`BIN`/`OCT`
- `Option` 的 `isSome`/`valOf`/`map`/`join`/`filter`（**没有 `isNone`**；注意 `filter : ('a -> bool) -> 'a -> 'a option` 是「谓词成立才包成 SOME」，不是「过滤一个 option」）
- `Bool` 的 `toString`/`fromString`
- `TextIO` 的 `openIn`/`openOut`/`openAppend`/`inputAll`/`inputLine`/`output`/`closeIn`/`closeOut`/`stdOut`
- `Substring` 的 `full`/`position`/`string`/`isEmpty`/`triml`/`trimr`
- `OS.Path` 的 `concat`/`file`/`dir`
- `OS.FileSys` 的 `access`/`mkDir`/`rmDir`/`openDir`/`readDir`/`closeDir`/`remove`
- `OS.Process` 的 `getEnv`/`isSuccess`/`success`/`failure`/`exit`/`system`/`terminate`/`sleep`（**没有 `isFailure`**，也没有 `streams`）
- `ListPair` 的 `map`/`zip`/`unzip`/`foldl`

**语法糖：**

- `#label` / `#n` 选择子（**在有完整类型信息的地方**）
- `...` 记录通配（`case p of {x, ...} => ...`）
- `op +` 把中缀变前缀
- `o` 函数组合
- 字符串的十进制转义 `\ddd`
- 嵌套注释

**「三家一致」这个结论本身就是三通道验证的产出。** 单实现开发时你不可能知道哪些能依赖、哪些不能 —— 你只知道「在我的机器上能跑」。

## 33.5 可移植写法手册

把前面的结论压缩成一份可以贴在墙上的清单。

**一、字面量与输出**

1. **字符串字面量只写 ASCII**，中文进注释。要输出非 ASCII 字节就用 `\ddd`。
2. **打印浮点用 `Real.fmt (FIX (SOME n))`，n ≤ 16**。不用 `Real.toString`，不用 `GEN`。
3. **避开 `.5` 平局**（自己 `Real.floor (x + 0.5)`）。
4. **要严格输出格式就自己拼字符串**，别指望标准库的默认形态。
5. **输出的顺序必须确定**：目录遍历先 `List.sort String.compare`，关联表用有序列表而不是哈希表。

**二、类型与数值**

6. **凡是重载运算符、类型变量、记录返回值的地方都加类型标注。** 标注永远没坏处。
7. **中间结果别超过 $2^{31}$**（MLton 的 `int` 是 32 位）。要 64 位用 `Int64`，但要先确认它在 `--script` 模式下存在。
8. **`OS.`/`Time.` 相关的大数值过 `Position` 或对应的转换函数**，别硬转。
9. **`OS.Process.status` 只用 `isSuccess` 判断**（Basis 没有 `isFailure`，要判失败写 `not (isSuccess st)`），别 `Int.toString`。
10. **浮点别用 `=`**，用 `Real.==`（精确）或容差比较（业务）。

**三、标准库用法**

11. **CSV 用 `String.fields`，分词用 `String.tokens`。**
12. **`Int.fromString` / `Real.fromString` 不能用来校验格式**（接受前缀和空白），要严格就自己扫。
13. **`Real.fromString` 要标注目标类型。**
14. **断言异常用 `exnName`，永远不用 `exnMessage`。**
15. **可选函数和方言扩展不要用**（`String.index` 是可选，`Option.isNone` / `List.foldli` 是 SML/NJ 扩展），自己写十几行更快；用之前先确认它是标准还是方言。
16. **`#n` / `#label` 只在有完整类型信息的地方用**；函数参数位置改用元组模式。

**四、模块系统**

17. **functor 一律用 spec 形式**（`functor F (structure A : S) = ...`），不用柯里化形式。
18. **`include` 只在 `signature` 里用**；结构里用 `open`。
19. **签名里需要相等性就写 `eqtype`**，别写 `type`。
20. **少 `open`**，用限定名；要 `open` 就限制在 `let` 里。

**五、语法**

21. **分号串联表达式必须加括号。**
22. **`handle` 不能顶格换行。**
23. **别把变量命名为中缀标识符**（`o`、`div`、`mod`、`before`）。
24. **嵌套注释要配平。**

**六、工程**

25. **每次运行前先做静态检查**（本教程的 `check-literals.py`）。
26. **用结束标记声明「跑完了」**，不信任退出码。
27. **自己的输出文案别包含编译器的诊断字样**（`error:` / `warning:`）。
28. **示例/测试必须自己擦干净临时文件。**
29. **警告也是错误**（stdout 和 stderr 都要干净）。
30. **脚本的 PATH 里钉上 `/usr/bin:/bin`**（避开被遮蔽的 `grep`/`sed`）。

**这 30 条没有一条是「SML 的高级特性」，全部是「让代码在三个实现上跑出同一个结果」的实践。** 它们同样适用于任何「有多个实现的语言」—— C 的三大编译器、Lisp 的各种方言、Markdown 的各种渲染器，道理都一样。

## 33.6 验证脚本的两个关键设计

差异清单里有一部分（14–16）没法在 SML 代码里解决，只能在验证脚本里解决。所以把脚本的两个设计单独讲一遍。

### 设计一：静音堆

**问题**：SML/NJ 的 REPL 把每个声明的类型回显到 stdout：

```
val say = fn : string -> unit
val p = fn : int * int -> unit
val it = () : unit
```

**这些内容留在 stdout 里，和 Poly/ML 的输出永远不可能逐字节一致。**

**解法**：构造一个「静音堆」，把编译器的消息流替换成空操作。

```sml
val _ = Control.Print.out := { say = fn (_ : string) => (), flush = fn () => () }
val _ = SMLofNJ.exportML "quiet"
```

**两条必须记住的事：**

**（1）`exportML` 必须是最后一句。** 堆被加载后，程序从 `exportML` 的**下一行**继续执行。如果后面还有语句（比如一句 `OS.Process.exit`），那么每次加载堆都会立刻执行它 —— 示例一个字节都不会输出就退出了。**这个 bug 真实发生过。**

**（2）`print` 不经过 `Control.Print.out`。** 编译器消息走 `Control.Print.out`，用户程序的 `print` 直接写 OS 的 stdout。所以静音之后：**回显没了，程序输出还在。**

**加载方式**：

```bash
printf 'use "19-parsing.sml";\n' | sml @SMLquiet "@SMLload=quiet.amd64-linux"
```

`@SMLsuffix` 能查到后缀名（macOS 上是 `amd64-darwin`，Linux 上是 `amd64-linux`）：

```bash
suffix=$(sml @SMLsuffix 2>/dev/null | tr -d '[:space:]')
```

**堆只需要构造一次**（脚本里判断文件存在就跳过），后面 29 个示例复用同一个。

**代价**：编译错误也不打印了，退出码变成 0。→ 见设计二。

### 设计二：结束标记 + 诊断重跑

**问题**：静音之后，**一个编译失败的示例会「静默地成功」**（退出码 0、stdout 为空、stderr 为空）。

**解法**：**让每个示例在最后一行打印自己的结束标记。**

```sml
val _ = say "==== 19 \231\187\147\230\157\159 ===="
```

判定条件因此变成五条（第 22 章讲过）：

1. **退出码为 0**
2. **stderr 为空**
3. **stdout 里没有多余的控制字符**（0..31 除 TAB/LF/CR）
4. **stdout 里有结束标记**
5. **stdout 里没有编译器诊断**

第 4 条是真正的把关者。**跑不到最后一行，就说明中途出错了。**

**诊断重跑**：判定失败时，脚本会**不带静音堆**再跑一遍，把真实错误过滤出来给用户看：

```bash
# 重跑时过滤掉 REPL 的回显噪声
grep -v -E '^\[(opening|autoloading|library'
```

不然满屏的 `[opening ...]` 会把真正的错误埋掉。

**这套设计的意义超过 SML 本身**：**当环境不能可靠地告诉你「成功还是失败」时，让程序自己声明「我跑完了」。** 这个思路适用于任何「退出码不可信」的场景 —— 后台任务、容器里的长任务、被包装过多次的构建流程。

## 33.7 已知差异登记表

`run-all.sh` 里有一张表，登记「确实无法逐字节一致」的示例：

```bash
diff_reason() {
    case "$1" in
        02-types)   echo "MLton 默认的 int 是 32 位，SML/NJ 与 Poly/ML 是 63 位" ;;
        18-numeric) echo "第 10 节刻意打印实数格式化的分叉点：Real.toString/GEN 对整值实数、FIX 0 的 .5 进位、FIX 17 的末位（详见 README）" ;;
        *)          echo "" ;;
    esac
}
```

**登记在案的示例会打印 `[diff] 已知差异：<原因>`，不计入告警。**

**这张表为什么必须只有两条？** 因为**它的存在本身是个诱惑** —— 遇到不一致时，最省事的做法是「把它登记进已知差异表」。**如果表里有二十条，这张表就变成了「放弃比对」的借口。**

**本教程的纪律：**

- **能修的一定要修**。29 个示例里有 27 个做到三通道逐字节一致。
- **只有「标准明确允许实现自由发挥」的差异才允许登记**，而且**必须写清原因**。
- **故意制造差异的示例（`18-numeric`）也要登记**，否则它会一直报警。

**最终结果**：

```
通过 22  失败 0  输出差异 0
[same] 20 个示例三通道输出完全一致
[diff] 2 个示例已登记的已知差异
```

**这就是「三通道验证」的完整闭环**：不是「保证输出一样」（不可能），而是**「每一处不一样都有明确的原因，并且记在案上」**。

## 33.8 结语：为什么要三个

回头看，三通道验证抓到的真问题有：

| 抓到的问题 | 是谁发现的 |
|---|---|
| 字符串字面量不能有中文 | **Poly/ML + MLton**（SML/NJ 完全正常） |
| `int` 是 32 位会溢出 | **MLton**（另两家 63 位，永远不溢出） |
| 柯里化 functor 不是标准 | **Poly/ML + MLton**（SML/NJ 是扩展） |
| 重载运算符的解析不同 | **SML/NJ + MLton**（Poly/ML 更宽松） |
| `fileSize` / `OS.Process.status` 类型 | **Poly/ML + MLton**（SML/NJ 恰好是 `int`） |
| `polyEqual` 警告污染 stdout | **SML/NJ**（另两家没这个警告） |
| 实测数字：`Int.maxInt`、`Real.round` 平局、`div`/`mod` 的负数行为 | **三者互证** |

**注意「是谁发现的」这一列。** 如果用单实现开发：

- **只用 SML/NJ**：中文没问题、柯里化 functor 没问题、`OS.Process.status` 没问题 —— **到换编译器的那天才知道全有问题**。
- **只用 MLton**：会写出到处是 `Position` 转换的代码，永远享受不到 SML/NJ 的交互式调试速度。
- **只用 Poly/ML**：会以为重载运算符总是能用期望类型反推。

**每一条差异都不是「某一家错了」，而是「标准把这件事留给实现」了。** 三通道的价值在于**把标准的自由度可视化**：哪些是保证，哪些是自由发挥，一目了然。

**最后一条：三条通道的角色分工，本身就是「多实现语言」的最佳实践。**

| 场景 | 用哪个 |
|---|---|
| 交互式开发、试代码片段 | **SML/NJ**（REPL 最成熟） |
| 检查标准符合性 | **MLton**（最严格，而且优化最好） |
| 检查方言依赖 | **Poly/ML**（报错风格完全不同） |
| 发布独立可执行文件 | **MLton**（原生静态二进制） |
| 嵌入到别的程序里当脚本引擎 | **Poly/ML**（C 接口最好） |

**「用哪个」不是选一个信仰，而是按场景换工具。** 前提是你知道它们之间的差异在哪 —— 这就是这一章的全部意义。
