# 03 · 模式系统：基本模、MODE 自定义与强制转换

> 示例：[`examples/03_modes/03_modes.a68`](../examples/03_modes/03_modes.a68)
> 运行：`./run-all.sh 03`

Algol 68 把其他语言里的"类型"叫**模（mode）**。每个值、每个变量、每个运算符都有确定的模，
编译器据此做强类型检查。理解模系统就理解了 Algol 68 的一半——本章讲五个基本模、用 `MODE`
自定义模、强制转换（coercion）规则，以及值模与引用模的区别。

## 1. 五个基本模（外加 BITS）

```algol68
INT    n := 42;          # 整数 #
REAL   x := 3.5;         # 实数（双精度浮点） #
BOOL   flag := TRUE;     # 布尔：TRUE / FALSE #
CHAR   ch := "A";        # 单字符，用双引号 #
STRING txt := "Algol";   # 字符行，本质是 FLEX[1:0]CHAR #
BITS   bs := 2r1010;     # 位串，2r 前缀写二进制字面量 #
```

| 模 | 含义 | 字面量写法 | 直接 print 的样子 |
|---|---|---|---|
| `INT` | 整数（宽度随 a68g 构建而变：macOS 32 位 / Windows 64 位，见第 04 章 `max int`） | `42`、`-7` | 右对齐带符号宽格式，一般先 `whole(n, 0)` |
| `REAL` | 双精度浮点 | `3.5`、`1.0e-12` | 一般先 `fixed(x, 0, 2)` |
| `BOOL` | 布尔 | `TRUE` / `FALSE` | `T` / `F` |
| `CHAR` | 单字符，**用双引号**（没有单引号字符） | `"A"` | 原样 |
| `STRING` | 字符行，本质是 `FLEX[1:0]CHAR`（可伸缩 CHAR 行） | `"Algol"` | 原样，UTF-8 透传 |
| `BITS` | 位串 | `2r1010`（`2r` = 二进制前缀） | `ABS bs` 把位串当无符号整数再 `whole` |

注意：**字符和字符串都用双引号**，靠内容长度区分 `CHAR` 与 `STRING`——`"A"` 在 `CHAR`
声明位置就是 CHAR。

## 2. `:=` 是声明/赋值，`=` 只是比较

```algol68
# 坑：写 n = 7; 不是赋值，而是把 (n=7) 这个 BOOL 值「void 掉」，触发告警。 #
n := 7;
assert(n = 7, "赋值后 n 应为 7");
```

- `:=` 既用于"声明并初始化"（`INT n := 42;`）也用于后续赋值（`n := 7;`）。
- `=` 是**相等比较**，产出 BOOL。`n = 7;` 作为语句是把一个 BOOL 值丢弃，编译能过但触发
  告警——C/Java 背景的人最容易顺手写错这一处。

## 3. MODE 自定义模：给模起别名

```algol68
MODE CELSIUS = REAL;
MODE YEAR = INT;
CELSIUS body_temp := 36.6;
YEAR    born := 1990;
print(("body_temp = ", fixed(body_temp, 0, 1), "C, born = ", whole(born, 0), new line));
```

`MODE 新名 = 已有模;` 定义一个模别名，之后 `CELSIUS` 与 `REAL` 完全等价。这给代码带来
**语义标注**（温度、年份），也可以在此基础上造结构/联合（STRUCT/UNION，见第 11 章）。
注意别名不产生类型隔离：`CELSIUS` 值可以直接参与 `REAL` 运算，编译器不拦。

## 4. 强制转换（coercion）：强类型 + 有限的自动放行

Algol 68 是强类型语言，但在明确安全的位置允许**自动强制转换**：

```algol68
REAL   from_int := n;                 # INT → REAL 自动 #
INT    truncated := ENTIER(3.9);      # 向零截断 → 3 #
INT    rounded   := ROUND(3.5);       # 四舍五入 → 4 #
print(("from_int=", fixed(from_int,0,2), " ENTIER(3.9)=", whole(truncated,0),
       " ROUND(3.5)=", whole(rounded,0), new line));
assert(truncated = 3, "ENTIER 向零截断");
assert(rounded = 4, "ROUND 四舍五入");
```

- **INT → REAL 自动**（放宽方向）：`REAL from_int := n;` 不需要任何标注。
- **REAL → INT 不自动**（收窄方向）：必须显式调用 `ENTIER`（取整）或 `ROUND`（四舍五入）。
- 这里 `ENTIER(3.9) = 3` 对正数是"向零截断"；`ENTIER` 的精确语义其实是**向下取整
  （floor）**，`ENTIER(-3.7) = -4` 而非 `-3`——第 04 章有实测。

CHAR 与 INT 之间也有一对显式转换：

```algol68
print(("ABS ch = ", whole(ABS ch, 0), "  REPR 66 = ", REPR 66, new line));
assert(ABS ch = 65, "A 的码位是 65");
assert(REPR 66 = "B", "码位 66 是 B");
```

`ABS ch` 取字符码位（CHAR → INT），`REPR 66` 由码位造字符（INT → CHAR）。

## 5. 作用域：BEGIN/END 封闭子句就是作用域块

```algol68
INT counter := 1;
BEGIN
  INT local_val := counter + 100;     # 内层自己的变量，不遮蔽外层 #
  print(("inner block sees its own var = ", whole(local_val, 0), new line))
END;
# 外层 counter 不受内层影响 #
assert(counter = 1, "外层变量不被内层改动");
```

内层 `BEGIN ... END` 是一个新的封闭子句：内层声明只在块内可见，块结束即消失；内层可以
**读**外层的 `counter`（`local_val := counter + 100`），但示例里内层用的是自己新声明的
`local_val`，没有同名遮蔽，所以外层的 `counter` 保持 1 不变——这正是断言钉死的性质。

## 6. 值模 vs 引用模（REF）

到目前为止声明的都是**值**：`INT n := 42` 里 `n` 每次出现都取那个 42 的副本参与运算，
`a := b` 是整值复制。Algol 68 同时有**引用模**——`REF INT`、`REF REAL` 等，引用由
`LOC`（栈上）或 `HEAP`（堆上）生成器创建，代表"某个存储位置的名字"。

示例代码没有用到 REF（本教程后面章节的结构/文件处理才真正需要），这里用两段本机实测的
小探针说明其行为：

```algol68
BEGIN
  REF INT r := LOC INT := 5;          # LOC 造一个新 INT 并初始化为 5，r 指向它 #
  PROC bump = (REF INT x) VOID: x := x + 1;
  bump(r);                            # 经 REF 形参修改被指对象 #
  print((whole(r, 0), new line))      # 打出 6：r 读到的是被改后的值 #
END
```

实测（a68g 3.13.3）三条要点：

1. **引用只能来自生成器**：`REF INT r := i;`（让 r 指向已有变量 i）会被拒——
   `error: INT cannot be coerced to REF INT`。Algol 68 没有"取地址"运算符。
2. **未初始化的 LOC 读了就炸**：`REF INT r := LOC INT;` 之后直接 print `r`，运行时报
   `attempt to use an uninitialised INT value`——a68g 不默默给 0。
3. **经 PROC 的 REF 形参可原地修改**（上面探针打出 6），这是 Algol 68 实现"传引用改值"的
   正道。

## 7. 字符串长度：没有 LENG，用 UPB - LWB + 1

```algol68
STRING cn := "世界";
print(("UPB txt = ", whole(UPB txt, 0), "  bytes(cn) = ",
       whole(UPB cn - LWB cn + 1, 0), new line));
assert(UPB txt = 5, "Algol 5 字节");
assert(UPB cn - LWB cn + 1 = 6, "世界 6 字节");
```

STRING 本质是 `FLEX[1:0]CHAR`——下界 `LWB` 为 1 的可伸缩 CHAR 行，`UPB` 是上界。长度 =
`UPB s - LWB s + 1`，**按字节计**：`"Algol"` 是 5，`"世界"` 是 6（UTF-8 每汉字 3 字节），
不是 2。想要"字符数"得自己解码 UTF-8，语言层面不提供。

## 8. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 03` 中 check 通道的真实 stdout（release 通道逐字节一致）：

```text
INT   n = 42
REAL  x = 3.50
BOOL  flag = T
CHAR  ch = A
STRING txt = Algol
BITS  bs = 10
body_temp = 36.6C, born = 1990
from_int=7.00 ENTIER(3.9)=3 ROUND(3.5)=4
inner block sees its own var = 101
ABS ch = 65  REPR 66 = B
UPB txt = 5  bytes(cn) = 6
==== 03 结束 ====
自检全部通过
```

逐行解释（挑要紧的）：

| 输出 | 为什么长这样 |
|---|---|
| `REAL  x = 3.50` | `fixed(x, 0, 2)` 定点 2 位小数——REAL 直接 print 会是宽格式，永远先格式化 |
| `BOOL  flag = T` | BOOL 打成 `T`/`F` 单字母 |
| `BITS  bs = 10` | `2r1010` 是二进制字面量（十进制 10）；`ABS bs` 把位串当无符号整数取出 |
| `body_temp = 36.6C` | `CELSIUS` 只是 `REAL` 的别名，用 `fixed(...,0,1)` 格式化；`C` 是行列里手写的普通字符 |
| `from_int=7.00` | 第 2 节里 `n := 7` 之后，INT 7 自动升 REAL 存进 `from_int` |
| `inner block sees its own var = 101` | 内层块的 `local_val = counter + 100 = 1 + 100` |
| `ABS ch = 65  REPR 66 = B` | CHAR↔INT 显式转换：`A` 码位 65；码位 66 是 `B` |
| `bytes(cn) = 6` | `世界` 按 UTF-8 字节数长度是 6，不是字符数 2 |

## 9. 坑位清单（实测）

1. **`=` 不是赋值**：`n = 7;` 是把比较结果 BOOL 丢弃，触发告警；赋值用 `:=`。
2. **CHAR 也用双引号**：Algol 68 没有单引号字符字面量，`"A"` 按上下文是 CHAR 或 STRING。
3. **STRING 没有可用的 `LENG`**（a68g 3.13.3）：长度用 `UPB s - LWB s + 1`，且按字节——
   `世界` = 6。
4. **ENTIER 不是"向零截断"**：对正数是（`ENTIER(3.9) = 3`），对负数向下取整
   （`ENTIER(-3.7) = -4`，第 04 章实测）；四舍五入用 `ROUND`。
5. **REF 不能指向已有变量**：`REF INT r := i;` 报 `INT cannot be coerced to REF INT`；
   引用只能由 `LOC`/`HEAP` 生成。
6. **未初始化的 LOC 一读就运行时错误**：`attempt to use an uninitialised INT value`，
   没有默认 0 值。
7. **MODE 别名不做类型隔离**：`CELSIUS` 与 `REAL` 完全互通，别指望编译器拦住"温度 + 年份"
   这类语义错误。

---
上一章：[02 第一个程序](02-hello.md) ｜ 下一章：[04 数值与运算](04-numeric.md) ｜ 返回：[README](../README.md)
