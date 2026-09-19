# 06 · 循环

> 示例：[`examples/06_loops/06_loops.a68`](../examples/06_loops/06_loops.a68)
> 运行：`./run-all.sh 06`

Algol 68 的循环核心是 `FOR ... DO ... OD`，它把"从几数到几、步长多少、什么条件提前停"
全部写进**循环头**，循环体用 `DO ... OD` 括起来（`OD` 是 `DO` 的回文）。本章讲 `FOR` 的各形态、
`WHILE`、嵌套循环、循环变量的作用域与只读性，以及"循环本身也是有值的单元"。

## 1. 循环头一览：FROM / BY / TO / DOWNTO / WHILE

完整的计数循环形态是：

```text
FOR k FROM a BY s TO b WHILE cond DO 循环体 OD
```

各部分都可选，组合出多种写法：

| 写法 | 含义 |
|---|---|
| `FOR k TO n` | 从 `1` 数到 `n`（默认起点 1、默认步长 1） |
| `FOR k FROM a TO b` | 从 `a` 数到 `b`（步长 1） |
| `FOR k FROM a BY s TO b` | 从 `a` 起、每次加 `s`，直到超过 `b` |
| `FOR k FROM a DOWNTO b` | **倒序**：从 `a` 递减到 `b`（步长 1） |
| `FOR k FROM a BY s DOWNTO b` | 倒序 + 指定步长（`s` 写**正数**，方向由 `DOWNTO` 定） |
| `... WHILE cond` | 附加提前退出条件：`cond` 为假时停止（见 §5） |

> `FOR` 循环头里的 `k` 叫**控制变量**，它只在循环体内可见，且**只读**——见 §4。

## 2. FOR k TO n：从 1 数到 n

```algol68
print(("FOR k TO 5: "));
FOR k TO 5 DO print((whole(k, 0), " ")) OD;
print((new line));
```

实测打印 `FOR k TO 5: 1 2 3 4 5`。`whole(k, 0)` 把整数 `k` 转成字符串，第二参数 `0` 表示
"用最小宽度、不补位"（关于 `whole` 的宽度语义见 §6 的乘法表）。

## 3. FROM / BY：指定起点与步长

```algol68
print(("FROM 3 TO 6: "));
FOR k FROM 3 TO 6 DO print((whole(k, 0), " ")) OD;      # 3 4 5 6 #
print((new line));

print(("FROM 2 BY 3 TO 11: "));
FOR k FROM 2 BY 3 TO 11 DO print((whole(k, 0), " ")) OD; # 2 5 8 11 #
print((new line));
```

`FROM 2 BY 3 TO 11` 依次取 `2, 5, 8, 11`——每次加 3，一旦超过上界 11 就停（11 恰好命中）。

## 4. 倒序 DOWNTO 与「控制变量只读 + 只在本循环可见」

倒序用 `DOWNTO`，**方向由关键字决定，步长仍写正数**：

```algol68
print(("FROM 10 DOWNTO 4: "));
FOR k FROM 10 DOWNTO 4 DO print((whole(k, 0), " ")) OD;      # 10 9 8 7 6 5 4 #

print(("FROM 10 BY 2 DOWNTO 4: "));
FOR k FROM 10 BY 2 DOWNTO 4 DO print((whole(k, 0), " ")) OD; # 10 8 6 4 #
```

> **坑（源码注释实测）**：配 `DOWNTO` 时若把步长写成负数 `BY -2`，即 `FROM 10 BY -2 DOWNTO 4`，
> **迭代 0 次**（负步长 + `DOWNTO` 直接不跑）。倒序只需 `DOWNTO`，步长恒为正。

关于控制变量 `k`，本机 a68g 3.13.3 实测两条硬规则：

- **只读**：循环体里写 `k := 9` 会编译报错 `INT secondary does not yield a name`——
  `k` 不是一个可赋值的"名字"，不能改它。
- **作用域仅限本循环**：循环外再引用 `k` 会报 `tag "k" has not been declared properly`。
  也就是说每层 `FOR` 的 `k` 都是独立的局部量，出了 `OD` 就消失。

## 5. WHILE：把退出条件写进循环头

`WHILE cond DO ... OD` 在每轮开始前判断 `cond`，为假就退出：

```algol68
INT n := 1;
print(("WHILE n<8 加倍: "));
WHILE n < 8 DO print((whole(n, 0), " ")); n *:= 2 OD;
print((new line));
```

实测打印 `1 2 4`：`n` 从 1 起每轮翻倍，当 `n` 变成 8（不再 `< 8`）时循环头判定为假、退出，
所以 8 不被打印。`n *:= 2` 是"乘等"简写（等价 `n := n * 2`）。

**Algol 68 没有 `break` / `continue`**。要提前退出，把退出条件写进 `WHILE` 头，或用一个布尔标志。
下面的例子找"第一个 >20 且能被 7 整除的数"，用标志 `found` 当退出条件：

```algol68
INT cand := 1; BOOL found := FALSE;
WHILE NOT found DO
  IF cand > 20 AND cand MOD 7 = 0 THEN found := TRUE
  ELSE cand +:= 1 FI
OD;
print(("第一个 >20 且被 7 整除的数 = ", whole(cand, 0), new line));   # 21 #
```

`cand MOD 7` 是取余；`cand > 20 AND cand MOD 7 = 0` 里关系运算比 `AND` 结合更紧（第 05 章 §6）。
命中 21 时把 `found` 置真，下一轮循环头 `NOT found` 为假即退出。

> `WHILE` 也能作为 `FOR` 的附加子句，写成 `FOR i TO m WHILE cond DO ... OD`，用于"边计数边看条件"。
> 第 07 章的 `index_of` 就用了 `FOR i TO h - nd + 1 WHILE pos = 0 DO ...`——一旦找到（`pos` 非 0）就停。

## 6. 累加与嵌套循环

循环体里可以修改外层变量，这是累加的常规做法：

```algol68
INT total := 0;
FOR k TO 100 DO total +:= k OD;      # 高斯求和 = 5050 #
```

嵌套循环就是把 `FOR ... OD` 放进另一个 `FOR` 的循环体。下面是九九乘法表的一角：

```algol68
print(("乘法表 1..3:", new line));
FOR i TO 3 DO
  FOR j TO 3 DO print((whole(i * j, 3), " ")) OD;
  print((new line))
OD;
```

注意这里用 `whole(i * j, 3)`——第二参数是**宽度 3**（不是 0）。实测每格输出形如 ` +1`、` +6`、` +9`：
在 3 列里右对齐，**正数带一个前导 `+` 号**，不足 3 列用空格左补。这就是 `whole(x, w)` 与
`whole(x, 0)` 的区别：`w=0` 用最小宽度、无补位、无 `+`；`w>0` 定宽右对齐并带符号。

## 7. 循环是「单元」：FOR...OD 整体也有值

和 `IF` 一样，循环也是封闭子句、也是一个单元，可以放在表达式位置（其值通常是 `VOID`）。
更常见的用法是让它累计结果到外层变量：

```algol68
INT squares := 0;
squares := 0; FOR k TO 5 DO squares +:= k * k OD;
print(("1^2+...+5^2 = ", whole(squares, 0), new line));   # 55 #
```

源码注释点明：可以把循环塞进表达式位置，但实践中多用"循环 + 外层累加变量"的模式。

## 8. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 06` 中 check 通道的真实 stdout（release 通道 `-O2` 逐字节一致，即验证保证）：

```text
FOR k TO 5: 1 2 3 4 5 
FROM 3 TO 6: 3 4 5 6 
FROM 2 BY 3 TO 11: 2 5 8 11 
FROM 10 DOWNTO 4: 10 9 8 7 6 5 4 
FROM 10 BY 2 DOWNTO 4: 10 8 6 4 
WHILE n<8 加倍: 1 2 4 
1+2+...+100 = 5050
乘法表 1..3:
 +1  +2  +3 
 +2  +4  +6 
 +3  +6  +9 
第一个 >20 且被 7 整除的数 = 21
1^2+...+5^2 = 55
==== 06 结束 ====
自检全部通过
```

逐行要点：

| 输出 | 为什么长这样 |
|---|---|
| `1 2 3 4 5 `（末尾有空格） | 每格 `print((whole(k,0), " "))` 都跟一个空格，最后一个是尾随空格 |
| `2 5 8 11 ` | `FROM 2 BY 3 TO 11`：起点 2、步长 3，11 恰好命中上界 |
| `10 9 8 7 6 5 4 ` | `DOWNTO` 倒序，含端点 4 |
| `10 8 6 4 ` | `BY 2 DOWNTO 4`：倒序步长 2（步长写正数） |
| `1 2 4 ` | `WHILE n<8` 翻倍，停在 8 之前，故不含 8 |
| ` +1  +2  +3 ` | `whole(i*j, 3)`：宽 3 右对齐，正数带前导 `+`，空格左补 |
| `第一个 ... = 21` | 用 `found` 标志替代 `break`，21 是第一个 >20 且被 7 整除的数 |
| `自检全部通过` | 所有 `assert` 未累加 `fails`，退出码 0 |

## 9. 坑位清单（实测）

1. **控制变量只读**：循环体里 `k := 9` 报错 `INT secondary does not yield a name`；不能改 `k`。
2. **控制变量作用域仅限本循环**：`OD` 之后再引用 `k` 报 `tag "k" has not been declared`。
3. **`DOWNTO` 的步长写正数**：`FROM 10 BY -2 DOWNTO 4` 实测**迭代 0 次**；倒序方向由 `DOWNTO` 决定。
4. **没有 `break` / `continue`**：提前退出靠 `WHILE` 条件或布尔标志（§5）。
5. **`WHILE` 在每轮开头判定**：`WHILE n<8` 翻倍时，8 不满足条件即退出、不被处理。
6. **`whole(x, 0)` 与 `whole(x, w)` 不同**：`0` 是最小宽度无补位无符号；`w>0` 定宽右对齐、
   正数带前导 `+`、空格左补（乘法表的 ` +1` 即由此而来）。
7. **累加要声明外层变量**：循环体内改的是外层 `INT`（如 `total +:= k`），控制变量本身改不了。

---
上一章：[05 条件与控制流](05-control.md) ｜ 下一章：[07 字符串处理](07-strings.md) ｜ 返回：[README](../README.md)
