# 05 · 子程序：过程与函数

> 示例：[`examples/ch05_subprograms.adb`](../examples/ch05_subprograms.adb)
> 运行：`./run-all.sh 05`

结构化程序设计把"一个完整的程序划分为若干个子程序"。Ada 的子程序
有两类：**过程（procedure）**——执行一个动作；**函数（function）**
——求一个值。每个子程序由**说明**（signature）与**体**（body）
组成，两者可以合写、也可以分离（分离到独立编译是第 26 章的主题）。
本章讲透四件事：**参数模式**的语义、**缺省参数与两种调用记法**、
**重载**（子程序重载与运算符重载）、**递归**；随后借牛顿法、汉诺塔、
最频值三个老教材经典案例把知识落到实处。内容对应张丽芬
《Ada 程序设计导论》第二章（子程序）。

---

## 05.1 子程序的说明与体

过程与函数的骨架（说明与体合写的形式）：

```ada
procedure 名字 (形参表) is
   说明部分
begin
   语句序列
[exception
   异常处理]
end 名字;

function 名字 (形参表) return 结果类型 is
   说明部分
begin
   语句序列
end 名字;
```

函数必须有 `return 结果类型`；过程没有。函数体内每个可能的出口
都必须执行 `return 表达式;`——漏了返回路径是编译错误（RM 保证：
"不返回的函数"不能通过编译，除非显式 `raise` 或无限循环）。

**说明与体分离**——先声明、后定义，供互相调用与库组织使用：

```ada
procedure Swap (A, B : in out Integer);   -- 说明：只有签名
procedure Swap (A, B : in out Integer) is -- 体：完整实现
   ...
end Swap;
```

本教程的示例把子程序写在主过程的说明部分里（嵌套子程序），
这是单文件示例的常态；工程代码里子程序更多放在**包**里独立编译
（第 10 章）。

## 05.2 参数模式：in / out / in out

每个形参必须标明传递方向，共三种模式：

| 模式 | 语义 | 形参在体内相当于 | 调用时实参要求 |
|------|------|------------------|----------------|
| `in` | 调用者 → 子程序 | **常量**（只读） | 表达式即可 |
| `out` | 子程序 → 调用者 | 未初始化变量（只写结果） | 必须是变量 |
| `in out` | 双向 | 变量（先读后写） | 必须是变量 |

示例的交换过程是 `in out` 的教科书演示：

```ada
procedure Swap (A, B : in out Integer) is
   Temp : constant Integer := A;   -- in 形参相当于常量，不可赋值
begin
   A := B;
   B := Temp;
end Swap;
```

读代码的要点：

- `in` 是**缺省模式**——不写模式就是 in。上例若写 `A, B : Integer`
  则两个都是只读的，`A := B` 直接编译错。
- `in` 形参"相当于常量"是字面意思：示例里 `Temp : constant Integer
  := A;` 顺带演示了"复制一份只读快照"的惯用法。
- **函数的形参只能全是 in**——函数是"求值"，不允许副作用写参数。
  这是 Ada 与 C++ 引用参数的重要区别。
- `out` 形参进入子程序时值**未定义**（读它是错误）；它的存在让
  "多返回值"不需要打包成记录或数组。

实参与形参的匹配可以是**位置记法**（按顺序）或**指名记法**
（`形参 => 实参`），也可以混用（前面的用位置、后面开始指名）：

```ada
Swap (X, Y);                          -- 位置记法
Sqrt_Newton (X, Eps => 1.0E-6)        -- X 位置 + Eps 指名
Print (Name => "Ada", Age => 30)      -- 全指名：顺序可任意
```

指名记法在参数多、有缺省值时是可读性的救星。

## 05.3 缺省参数：只有 in 可以缺省

`in` 模式的形参可以带缺省值，调用时不给实参就用缺省。示例的
牛顿法平方根函数（老教材 §2.1 的原例，改为现代写法）：

```ada
function Sqrt_Newton
  (X   : Float;
   Eps : Float := 0.000_1) return Float
is
   Old_Value : Float := 0.0;
   New_Value : Float := X / 2.0;
begin
   while abs (New_Value - Old_Value) > Eps loop
      Old_Value := New_Value;
      New_Value := 0.5 * (Old_Value + X / Old_Value);
   end loop;
   return New_Value;
end Sqrt_Newton;
```

算法是牛顿迭代：第 k+1 次近似 aₖ₊₁ = ½(aₖ + x/aₖ)，相邻两次近似
之差小于 `Eps` 即收敛。`Eps` 带缺省值 `0.000_1`，于是：

```ada
Sqrt_Newton (2.0)                     -- Eps 用缺省 0.0001
Sqrt_Newton (X, Eps => 1.0E-6)        -- 指名覆盖缺省，更严的精度
```

示例输出（与标准库对照验证）：

```text
  Sqrt_Newton (2.0)          =  1.414214
  Sqrt_Newton (2.0, 1.0E-6)  =  1.414214
  Sqrt (2.0)（标准库对照）  =  1.414214
```

**out / in out 形参不允许缺省**——缺省值意味着"调用者可以不给"，
而这两类模式的实参（变量）是必须的，语义上无从缺省。缺省值表达式
在**子程序说明加工时**求值（不是每次调用都算）。

## 05.4 运算符重载：给类型定义算术

Ada 允许用函数给运算符赋予新含义——函数名写成带双引号的运算符
字符串：

```ada
type Vector is array (Integer range <>) of Float;
function "+" (X, Y : Vector) return Vector is
   Sum : Vector (X'Range);
begin
   for I in X'Range loop
      Sum (I) := X (I) + Y (I);
   end loop;
   return Sum;
end "+";
```

定义之后，向量加法就是"天然的"数学写法：

```ada
V3 := V1 + V2;                    -- 调用我们定义的 "+"
```

（老教材的矩阵加法例子里写 `Z := "+"(X, Y);`——函数式调用也合法，
但运算符写法才是存在的意义。）

可重载的运算符：`+ - * / ** abs not &` 与全部比较运算符；
**不可重载**的只有成员测试 `in`/`not in` 与短路形式 `and then`/
`or else`（它们是控制形式，不是操作符）。注意参数个数要匹配运算符
的元数（一目/二目）。老教材用这个机制定义了完整的矩阵算术
（`"+"`、`"*"`）与第 10 章的分数类型——运算符重载 + 强类型 = 数学
域类型自然落进语言。

## 05.5 子程序重载：同名不同参

几个子程序共用一个名字，编译器按**实参类型**选择——这在标准库里
无处不在（`Put` 有十几个版本）。示例给 `Swap` 又定义了一个 Float
版本：

```ada
procedure Swap (A, B : in out Integer) is ... end Swap;
procedure Swap (A, B : in out Float)   is ... end Swap;
```

```ada
Swap (X, Y);   -- Integer 版
Swap (P, Q);   -- Float 版：编译器按类型自动选择
```

老教材 §2.3 的 `PUT` 家族是最佳示例：为 `Integer`、`Float`、
`Color`、`Light` 各定义一个 `PUT`，调用处 `PUT (365)`、
`PUT (4.62)`、`PUT (Blue)` 各得其所。当实参无法消歧时（重载的
枚举直接量），用**限定表达式**点明类型：

```ada
PUT (Blue);            -- 二义：Blue 在哪个类型里？
PUT (Color'(Blue));    -- 限定后无二义
```

这解释了第 03 章"重载直接量"为什么需要限定——重载解析是跨
"子程序 × 类型"两层联动的。

## 05.6 递归：汉诺塔

递归子程序直接或间接调用自己。老教材 §2.6 的汉诺塔是标准案例：
把 N 盘从 X 挪到 Y（Z 作中转），算法 P 的数学归纳表述——
N=0 时显然成立；设 N=k-1 成立，则"先挪 k-1 盘到 Z、挪第 k 盘到
Y、再挪 k-1 盘到 Y"正确。直译成 Ada：

```ada
procedure Hanoi (N : Natural; X, Y, Z : Character) is
begin
   if N /= 0 then
      Hanoi (N - 1, X, Z, Y);
      Put_Line ("  盘" & Integer'Image (N) & " : " & X & " → " & Y);
      Hanoi (N - 1, Z, Y, X);
   end if;
end Hanoi;
```

调用 `Hanoi (3, 'X', 'Y', 'Z')` 的输出：

```text
  盘 1 : X → Y
  盘 2 : X → Z
  盘 1 : Y → Z
  盘 3 : X → Y
  盘 1 : Z → X
  盘 2 : Z → Y
  盘 1 : X → Y
```

7 步——2³-1，理论最少步数，递归解即最优解。注意参数 `X, Y, Z`
在递归调用里**换位**（`X, Z, Y` 与 `Z, Y, X`）：子问题重排了
"源/目标/中转"的角色。递归三要素在这个 9 行函数里齐全：**基例**
（N=0 什么都不做）、**规模递减**（N-1）、**角色重排**。

老教材同节的另外两个递归案例值得知道：**快速分类**（QUICKSORT，
对数组片递归——数组片第 06 章讲）与**八皇后**（回溯法，用三个
布尔数组标记行/两条对角线）。它们的精神与汉诺塔一致：把问题
交给更小的自己。

## 05.7 非约束数组形参与 out 模式：最频值

子程序形参可以用**非约束数组类型**——界由实参带进来，函数体内
用属性适配。这是 Ada 数组参数的精髓（第 06 章展开类型层面），这里
先用老教材 §2.6 的"最频值"算法感受它：

```ada
type Int_Vector is array (Integer range <>) of Integer;
procedure Mode (A : Int_Vector; MF : out Integer; MV : out Integer) is
   L : constant Integer := A'First;
   U : constant Integer := A'Last;
   I : Integer;
begin
   MV := A (L);          -- 最频值
   MF := 1;              -- 最频值的频率
   I := L + 1;
   while I <= U loop
      if A (I) = A (I - MF) then
         MF := MF + 1;
         MV := A (I);
      end if;
      I := I + 1;
   end loop;
end Mode;
```

算法基于 Griffiths 的观察：对**已排序**数组，`A (I) = A (I - MF)`
成立当且仅当位置 I 把"当前最频值的游程"又延长了一格。线性时间、
单趟扫描。两个 out 参数（`MF` 频率、`MV` 值）展示了"多返回值"
不需要记录打包的 Ada 写法。示例数据：

```ada
Data : constant Int_Vector (1 .. 10) := (1, 1, 2, 3, 3, 3, 3, 8, 8, 9);
Mode (Data, MF, MV);   -- → MV = 3, MF = 4
```

输出：`已排序数组中出现最多的是 3，共 4 次`。

形参 `A : Int_Vector` 没有写界——任何界的 `Int_Vector` 实参都能
传进来，`A'First`/`A'Last` 在体内取到实参的真实界。与之对照，
**约束数组形参**（`A : Int_Vector (1 .. 10)`）则要求实参界严格
一致——前者通用，后者精确，各有用场。

## 05.8 作用域、可见性与 renames

嵌套子程序的内层看得见外层的全部说明。老教材 §2.4 的可见性规则
浓缩成三条：

1. **作用域**：实体的作用域从说明点延伸到包含它的子程序/块/包/任务
   的 `end`。
2. **直接可见**：作用域内用简单名引用；内层同名说明**遮蔽**外层。
3. **选择可见**：程序包/任务的成员、记录分量必须带前缀
   （`Pack.Proc`、`Rec.Field`），`use` 子句可把包成员提升为直接可见。

**renames（换名）**——给已有实体起个别名，不产生新代码、不开新
作用域。对子程序：

```ada
procedure Say (S : String) renames Ada.Text_IO.Put_Line;
```

示例末尾用它打印了一句自我介绍。renames 的用途：缩短深层嵌套包的
长名字（老教材的 `MATH_LIBRARY.TRIG_FUNCTION.Cos` → 换名后
`TRIG.Cos`）、给运算符函数一个可读名（`function Matrix_Sum ...
renames "+"`）、在派生类型上"继承"一个换名版本。注意 renames
的**签名必须唯一匹配**——`Put_Line` 是重载家族，所以要写全
`(S : String)` 剖面来消歧（示例开发时踩过的真实坑）。

## 05.9 本章示例的完整输出

```text
=== Ada 子程序 ===

--- 1. 过程 Swap (in out) ---
  交换前: X = 10, Y = 20
  交换后: X = 20, Y = 10

--- 2. 函数 Sqrt_Newton ---
  Sqrt_Newton (2.0)          =  1.414214
  Sqrt_Newton (2.0, 1.0E-6)  =  1.414214
  Sqrt (2.0)（标准库对照）  =  1.414214

--- 3. 运算符重载 "+" ---
  (1,2,3) + (4,5,6) = ( 5.0,  7.0,  9.0)

--- 4. 递归：汉诺塔 N=3 ---
  盘 1 : X → Y
  盘 2 : X → Z
  盘 1 : Y → Z
  盘 3 : X → Y
  盘 1 : Z → X
  盘 2 : Z → Y
  盘 1 : X → Y

--- 5. 最频值（Griffiths 算法） ---
  已排序数组中出现最多的是 3，共 4 次

--- 6. 重载与 renames ---
  Swap (Float) 后: P = 4.50000E+00, Q = 1.50000E+00
  Say 是 Ada.Text_IO.Put_Line 的换名（renames）。
```

## 05.10 小结

| 概念 | 要点 |
|------|------|
| 说明 vs 体 | 签名可先声明后定义；分离编译见第 26 章 |
| `in` / `out` / `in out` | 只读常量 / 只写结果 / 读写变量；函数形参只能 in |
| 缺省参数 | 仅 in 模式；说明加工期求值 |
| 位置/指名调用 | 可混用；指名从首个缺省处开始最常见 |
| 运算符重载 | `"+"` 记法；`in`/短路形式不可重载 |
| 子程序重载 | 按实参类型解析；二义时 `T'(X)` 限定 |
| 递归 | 基例 + 规模递减 + 角色重排（汉诺塔三要素） |
| 非约束数组形参 | `A'First/A'Last` 适配实参的界 |
| renames | 别名不产生新代码；签名须唯一匹配 |

单一子程序的力量有限——把相关的类型、常量、子程序**打包**起来
对外只暴露接口，就是下一章的主角：**程序包（package）**……之前，
还得先补齐两种组合数据类型。下一章讲数组与字符串。

---
上一章：[04 控制结构](04-control.md) ｜ 下一章：[06 数组与字符串](06-arrays-strings.md) ｜ 返回：[README](../README.md)
