# 09 · 过程（PROC）

> 示例：[`examples/09_procedures/09_procedures.a68`](../examples/09_procedures/09_procedures.a68)
> 运行：`./run-all.sh 09`

过程（PROC）是 Algol 68 的函数/子程序。它既能返回值，也能只做副作用；既能递归、
能把别的过程当参数传，也能通过 `REF` 形参就地改动调用方的变量。第 08 章说过"运算符
就是带符号名的过程"——本章把过程本身讲透。

## 1. 基本过程：`PROC 名 = (参数模) 结果模: 过程体`

```algol68
PROC sq = (INT x) INT: x * x;
print(("sq(6) = ", whole(sq(6), 0), new line));
assert(sq(6) = 36, "6 的平方");
```

拆开看这条声明的四个部件：

| 部件 | 例子中 | 作用 |
|---|---|---|
| `PROC 名` | `PROC sq` | 声明一个过程，名字是 `sq` |
| 参数表 `(参数模)` | `(INT x)` | 形参 `x`，模是 `INT`（按值传递，见 §5） |
| 结果模 | `INT` | 过程求值后产出一个 INT |
| 过程体（routine text） | `x * x` | 冒号后就是"折叠"进来的例程文本，最后一条单元的值即返回值 |

调用 `sq(6)`：把 6 绑到 `x`，求 `x * x` 得 36。**返回值不写 `return`**——过程体
最后一个单元的值就是结果。

## 2. 多值返回：用 STRUCT 打包

Algol 68 的过程只产出**一个**值，没有元组返回。要一次返回多个量，用 `STRUCT` 打包
（结构详见第 11 章）：

```algol68
PROC divmod = (INT a, b) STRUCT(INT q, r): (a OVER b, a MOD b);
print(("divmod(17,5) = q ", whole(q OF divmod(17, 5), 0),
       "  r ", whole(r OF divmod(17, 5), 0), new line));
```

结果模写成 `STRUCT(INT q, r)`，过程体返回一个并列子句 `(a OVER b, a MOD b)`。
调用后用 `q OF ...`、`r OF ...` 取字段。实测 `divmod(17,5) = q 3  r 2`。

## 3. 递归：过程体里调用自己

```algol68
PROC factorial = (INT n) INT: IF n <= 1 THEN 1 ELSE n * factorial(n - 1) FI;
PROC fib  = (INT n) INT: IF n < 2 THEN n ELSE fib(n - 1) + fib(n - 2) FI;
print(("factorial(6) = ", whole(factorial(6), 0), "   fib(10) = ", whole(fib(10), 0), new line));
```

实测 `factorial(6) = 720   fib(10) = 55`。过程名在自己的过程体里可见，直接写名字
即可递归。

> **坑（示例注释）**：别把阶乘过程命名为 `fact`——prelude 已有 `PROC(INT) REAL fact`，
> 遮蔽它会触发 notice。示例改用 `factorial` 避开。

## 4. 过程作参数（高阶）：形参写成一个 PROC 模

过程本身是"值"，可以当参数传。形参的模写成一个完整的 PROC 类型：

```algol68
PROC apply = (PROC(INT) INT f, INT x) INT: f(x);
print(("apply(sq, 5) = ", whole(apply(sq, 5), 0), new line));
assert(apply(sq, 5) = 25, "把 sq 当值传进 apply");
```

形参 `PROC(INT) INT f` 读作"一个吃 INT、吐 INT 的过程"。调用 `apply(sq, 5)` 把过程
`sq` 当值传进去，`apply` 体内再 `f(x)` 展开成 `sq(5)` = 25。

再进一步——把过程映射到行的每个元素：

```algol68
PROC map_row = (PROC(INT) INT f, [] INT xs) [] INT:
  ( [LWB xs : UPB xs] INT out;
    FOR k FROM LWB xs TO UPB xs DO out[k] := f(xs[k]) OD;
    out );
[1:4] INT nums := (1, 2, 3, 4);
[] INT squared = map_row(sq, nums);
```

`map_row` 造一个与 `xs` 同界的输出行，逐元素套用 `f`，最后返回 `out`。实测
`map sq over [1,2,3,4]` 得到 1、4、9、16。

> **坑（示例注释）**：接收 `map_row` 返回的多行必须用 `=` 声明（`[] INT squared = ...`），
> 用 `:=` 会报 `actual bounds expected`——`:=` 要求左侧已有确定边界，而这里的行界是
> 运行时才由返回值定的。

## 5. 参数传值 vs REF 传引用（本章核心）

**默认按值传递**：形参是实参的一份拷贝，过程里改形参不影响调用方。要在过程内
就地改动实参，形参模写成 `REF`：

```algol68
PROC inc = (REF INT r) VOID: r +:= 1;
PROC swap = (REF INT a, b) VOID: (INT t := a; a := b; b := t);
INT c := 10; inc(c);
print(("inc 后 c = ", whole(c, 0), new line));     # 实测 11
INT p := 1, qq := 2; swap(p, qq);
print(("swap 后 p=", whole(p, 0), " q=", whole(qq, 0), new line));   # 实测 2 1
```

| | 传值（默认） | 传引用 `REF` |
|---|---|---|
| 形参写法 | `(INT x)` | `(REF INT r)` |
| 过程拿到的 | 实参的拷贝 | 实参本身（别名） |
| 过程里改形参 | 不影响调用方 | **就地改到调用方变量** |
| 典型用途 | 纯计算、输入 | 出参、`swap`、累加计数 |

`inc` 里 `r +:= 1` 通过 `REF` 直接加到外部的 `c`，实测 `c` 从 10 变 11；`swap`
借一个局部 `INT t` 交换两个 `REF INT`，实测 `p=2 q=1`。示例第 5 行的断言计数器
`fails +:= 1` 也依赖这种"就地改"的语义（`fails` 被过程体捕获改动）。

## 6. VOID 过程与无参过程

```algol68
PROC greet = (STRING name) VOID: print(("  hello, ", name, "!", new line));
greet("world");                          # 只做副作用，无返回值
PROC answer = INT: 42;                   # 无参：调用时不写括号
print(("answer = ", whole(answer, 0), new line));
```

- **VOID 过程**：结果模写 `VOID`，表示"不返回值，只做事"。`greet("world")` 实测
  打印 `  hello, world!`。
- **无参过程（单元）**：参数表整个省略，写成 `PROC answer = INT: 42`。**调用时直接
  写名字 `answer`，不加括号**——实测 `whole(answer, 0)` 得 42。

## 7. 过程名可以带空格（upper-stropping 下的合法写法）

Algol 68 允许标识符由多个词组成。实测下面都能编译运行：

```algol68
PROC my proc = INT: 1;                # 实测：my proc 求值得 1
PROC add two = (INT a, b) INT: a + b; # 实测：add two(3, 4) = 7
```

调用时把整串名字连同空格一起写：`add two(3, 4)`。注意**运算符名不能带空格**
（第 08 章 §6：`OP PLUS AB` 报错）——这是过程名与运算符名的一处不对称。

## 8. 运算符自定义（OP）：过程的一种特殊外观

第 08 章已详述：`OP DOTP = (INT a, b) INT: dot_impl(a, b);` 这样的运算符声明，
本质就是给一个过程起了符号名。示例的 `assert` 也是一个 `PROC`：

```algol68
PROC assert = (BOOL cond, STRING msg) VOID:
  IF NOT cond THEN put(stand error, ("FAIL: ", msg, new line)); fails +:= 1 FI;
```

它吃一个 `BOOL` 和一段 `STRING`，条件为假时把失败信息打到 stderr 并让 `fails +:= 1`。
全章的自检都靠它——这是"过程 + REF 捕获外部计数器"的实战范例。

## 9. 坑（实测）：别返回捕获了栈上局部量的过程

示例 9.7 记录了一个真实运行时崩溃：

```algol68
# 实测 PROC twice = (PROC(INT)INT f) PROC(INT)INT: (INT x)INT: f(f(x));
# 调用 twice(sq)(3) 直接 runtime error: PROC value exported out of its scope。
# 要返回闭包，必须把捕获的量放到 HEAP 上——第 13 章详解。
```

`twice` 想返回一个"套用两次 f"的新过程，但那个内层 `(INT x) INT: f(f(x))` 捕获了
外层的形参 `f`——`f` 活在 `twice` 的调用栈帧上，`twice` 一返回栈帧就没了，再调用
导出的过程即触发 `PROC value exported out of its scope`。要造闭包必须把被捕获的量
放到 `HEAP` 上（第 13 章）。

## 10. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 09` 双通道运行：check 通道 `a68g --warnings --notices`（解释器，全
运行时检查），release 通道 `a68g -O2`（编译到 C 后端），两通道 stdout 要求**逐字节
一致**，且退出码 0、stderr 为空、含结束标记。check 通道真实 stdout：

```text
sq(6) = 36
divmod(17,5) = q 3  r 2
factorial(6) = 720   fib(10) = 55
apply(sq, 5) = 25
map sq over [1,2,3,4] =          +1          +4          +9         +16
  hello, world!
answer = 42
inc 后 c = 11
swap 后 p=2 q=1
提示：返回捕获栈局部量的过程会作用域违例，需 HEAP 捕获（13 章）
==== 09 结束 ====
自检全部通过
```

| 输出行 | 为什么长这样 |
|---|---|
| `sq(6) = 36` | §1 基本过程，`6*6` |
| `divmod(17,5) = q 3  r 2` | §2 STRUCT 多值返回：`17 OVER 5`=3、`17 MOD 5`=2 |
| `factorial(6) = 720   fib(10) = 55` | §3 递归 |
| `apply(sq, 5) = 25` | §4 过程当参数，`sq(5)` |
| `map sq over ... +1  +4  +9  +16` | §4 逐元素平方；数字带 `+` 号且右对齐占宽，因为直接 print INT 是**宽格式**（第 10 章详述），这里没套 `whole(...,0)` |
| `hello, world!` | §6 VOID 过程 `greet` 的副作用 |
| `answer = 42` | §6 无参过程，不写括号 |
| `inc 后 c = 11` | §5 `REF INT` 就地 +1 |
| `swap 后 p=2 q=1` | §5 `REF` 交换生效 |
| `自检全部通过` | `fails = 0`；有失败会打到 stderr 并非 0 退出 |

## 11. 坑位清单（实测）

1. **接收过程返回的多行用 `=` 不用 `:=`**：`:=` 报 `actual bounds expected`（§4）。
2. **默认传值**：想改调用方的变量必须写 `REF INT` 形参，否则只是改拷贝（§5）。
3. **无参过程调用不加括号**：写 `answer`，不是 `answer()`（§6）。
4. **别用 `fact` 当过程名**：遮蔽 prelude 的 `PROC(INT) REAL fact` 会触发 notice（§3）。
5. **别返回捕获栈局部量的过程**：`twice(sq)(3)` 触发 `PROC value exported out of its
   scope`；闭包要 `HEAP` 捕获（§9，第 13 章）。
6. **过程名可含空格，运算符名不可**：`add two(3,4)` 合法，`OP PLUS AB` 报错（§7、08 章）。
7. **直接 print INT（含行元素）是宽格式带 `+` 号**：要紧凑输出套 `whole(x, 0)`
   （见 §10 的 `map` 行，第 10 章详述）。

---
上一章：[08 运算符](08-operators.md) ｜ 下一章：[10 数组与行](10-arrays.md) ｜ 返回：[README](../README.md)
