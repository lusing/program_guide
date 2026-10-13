# 07 · 记录类型

> 示例：[`examples/ch07_records.adb`](../examples/ch07_records.adb)
> 运行：`./run-all.sh 07`

记录把**一组可能类型不同的分量**打包成一个对象——人（姓名+年龄）、
日期（日+月+年）、CPU 状态（优先级+标志组）。数组的每个分量类型
相同、靠下标区分；记录的分量各说各话、靠**名字**区分。本章讲记录
说明、两种聚集、缺省初值、嵌套与选择分量，最后向"变体记录"——
分量集可以在运行期随判别式变化的记录——探头（完整机制在第 08 章）。
内容对应张丽芬《Ada 程序设计导论》§1.5 之二（记录）。

---

## 07.1 记录说明：给每个分量一个名字和类型

记录说明的形式：

```ada
type 名字 is
   record
      分量说明;
      分量说明;
   end record;
```

最简单的例子：

```ada
type Person is
   record
      Name : String (1 .. 20);
      Age  : Integer;
   end record;
```

分量说明长得就是对象说明——名字 : 类型（可带约束、可带初值）。
老教材的 CPU 例子把"记录里还可以有记录"一并展示了，示例原样
收录：

```ada
type CPU_Flag is
   record
      Carry     : Boolean;
      Interrupt : Boolean;
      Negative  : Boolean;
      Zero      : Boolean;
   end record;

type CPU_State is
   record
      Priority : Integer range 0 .. 7;   -- 分量可以带范围约束
      Flag     : CPU_Flag;              -- 分量可以是另一个记录
   end record;
```

`Priority : Integer range 0 .. 7`——第 03 章的范围约束在分量上
原样生效：给 `PSW.Priority` 赋 8 就地引发 `Constraint_Error`。
记录是"约束的容器"，每个分量都带着自己的安全带。

对象说明与分量访问用**选择分量**记法（点记法）：

```ada
PSW : CPU_State;
PSW.Priority := 5;          -- 一层
PSW.Flag.Zero := True;      -- 嵌套：逐层点下去
```

## 07.2 记录聚集：位置与指名

给记录整体赋值的表达式叫**记录聚集**，与数组聚集同源：

```ada
P1 : Person := (Name => "Ada Lovelace        ", Age => 36);  -- 指名
P2 : Person := ("Charles Babbage     ", 44);                 -- 位置
```

规则：

- **指名法**：`分量名 => 值`，顺序任意、一目了然——分量多了以后的
  唯一选择。
- **位置法**：按分量说明顺序给值，紧凑——分量少、类型不易混淆时用。
- **必须完整**：与数组聚集一样，所有分量都要给值（**包括有缺省
  初值的分量**——老教材特别强调：显式聚集会覆盖缺省初值）。
- 类型不明时用限定聚集：`Date'(4, 7, 1987)`（见 07.6）。
- 嵌套记录的聚集自然嵌套：

```ada
PSW : CPU_State :=
  (Priority => 5,
   Flag     => (Carry     => False,
                Interrupt => True,
                Negative  => False,
                Zero      => False));
```

## 07.3 分量缺省初值

分量说明可以带初值——之后**不带初值的对象说明自动采用它**：

```ada
type Position is
   record
      X, Y : Float := 0.0;       -- 缺省初值：说明时不必显式初始化
   end record;

P1 : Position;                          -- 用缺省：(0.0, 0.0)
P2 : Position := (X => 3.0, Y => 4.0);  -- 显式初值取代缺省
```

示例输出：

```text
  P1 (缺省): X = 0.00000E+00, Y = 0.00000E+00
  P2 (显式): X = 3.00000E+00, Y = 4.00000E+00
```

这条机制的价值：**类型设计者决定"合理零值"**。坐标原点、空标志、
满额度的默认配置……对象说明处不用啰嗦就拿到安全初值。它是构造
"半初始化"大对象的起点——先 `P : Config;`（全缺省），再改一两个
分量，比每次写全量聚集清爽得多。

`others` 在记录聚集中也能用（对剩下所有分量赋同一值，要求它们
类型相容）：

```ada
PSW.Flag := (others => False);   -- 整个内层记录一次清零
```

## 07.4 记录赋值与相等：值语义

记录是**值**：赋值即全分量拷贝，相等即全分量相等：

```ada
A : Point := (X => 1.0, Y => 2.0);
B : Point;
...
B := A;                 -- 整体赋值：复制全部分量
B.X := 9.0;             -- 改 B 不影响 A
...
Boolean'Image (A = B)   -- FALSE
```

没有"引用语义"掺和——记录变量就是记录本身，不是指向记录的把手。
（想要把手，得显式用访问类型，第 09 章。）`=`/`/=` 对记录自动
可用（全分量比较）；其它运算符不会自动生成，要靠运算符重载自定义
——第 10 章的分数包就是这么给 `Fraction` 配齐 `+-*/` 的。

## 07.5 空记录

`null record` 表示没有分量的记录：

```ada
type Null_Record is null record;
```

示例打印 `Null_Record 占 0 位`（`'Size` 属性）。空记录的用途：
**占位**——泛型的实际参数（第 12 章常见 `type T is null record`
当最小类型用）、**标记**——作为 tagged 层次的最底层（第 14 章）、
将来扩展的锚点。

## 07.6 限定聚集：类型名一锤定音

第 03 章的限定表达式 `T'(X)` 用在聚集上：

```ada
type Date is
   record
      Day   : Integer range 1 .. 31;
      Month : Integer range 1 .. 12;
      Year  : Integer range 1901 .. 2099;
   end record;

D : Date := Date'(4, 7, 1987);   -- 限定聚集：类型名 ' (聚集)
```

什么时候需要限定？当聚集的类型无法从上下文唯一确定时——重载
函数的实参、`case` 表达式（Ada 2012）的分支、嵌套在另一个聚集里。
老教材的写法 `DAY_OF_YEAR'(4, JULY, 1987)` 与今天的 `Date'(4, 7,
1987)` 完全同构。顺带注意：限定聚集**绕过缺省初值**——它必须完整
给出每个分量的值。

## 07.7 变体记录：判别式初探

实际数据常有"按种类不同的分量"：图形要么是圆（半径）要么是矩形
（宽高）；设备要么是打印机（分辨率）要么是调制解调器（波特率）。
Ada 的答案是把"种类"做成**判别式（discriminant）**，用 `case`
让分量集随判别式变化：

```ada
type Shape_Kind is (Circle, Rectangle);
type Shape (Kind : Shape_Kind) is          -- Kind 是判别式
   record
      case Kind is
         when Circle =>
            Radius : Float;
         when Rectangle =>
            Width, Height : Float;
      end case;
   end record;

C : Shape (Circle)    := (Kind => Circle, Radius => 5.0);
R : Shape (Rectangle) := (Kind => Rectangle, Width => 3.0, Height => 4.0);
```

示例验证了核心性质：

```text
  C.Kind =CIRCLE，C.Radius = 5.00000E+00
  R.Kind =RECTANGLE，R.Width = 3.00000E+00，R.Height = 4.00000E+00
  C.Radius 合法、C.Width 不存在——分量集由判别式决定。
```

**`C.Width` 不是"值为垃圾"，是语法上根本不存在**——访问不存在的
变体分量直接编译错；在判别式可变的对象上访问"当前变体之外"的
分量则引发 `Constraint_Error`。这与 C 的 union 有本质区别：union
选错成员读到的是无类型垃圾，Ada 变体记录连问都不让你问。

老教材把这块放在 §4.6（带有判别式的记录类型、变体记录），配套的
经典案例是"用变体记录计算几何图形面积"与"打印二叉树的值"。完整
机制——判别式约束、无默认判别式的 indefinite 性质、判别式关联
`new Shape'(Kind => ...)`——是第 08 章的全部内容，这里先记住
语法骨架即可。

## 07.8 本章示例的完整输出

```text
=== Ada 记录类型 ===

--- 1. 简单记录与聚集 ---
  P1.Name = Ada Lovelace
  P1.Age  = 36
  P2.Name = Charles Babbage
  P2.Age  = 44
  两种聚集等价；指名法顺序任意，位置法必须按分量顺序。

--- 2. 分量缺省初值 ---
  P1 (缺省): X = 0.00000E+00, Y = 0.00000E+00
  P2 (显式): X = 3.00000E+00, Y = 4.00000E+00

--- 3. 嵌套记录 ---
  PSW.Priority = 5
  PSW.Flag.Interrupt = TRUE
  PSW.Flag.Zero := True 后 = TRUE
  PSW.Flag := (others => False) 后 Interrupt = FALSE

--- 4. 记录赋值与相等 ---
  A.X = 1.00000E+00（未被 B 的修改波及）
  B.X = 9.00000E+00
  A = B 的结果 = FALSE

--- 5. 变体记录（判别式） ---
  C.Kind =CIRCLE，C.Radius = 5.00000E+00
  R.Kind =RECTANGLE，R.Width = 3.00000E+00，R.Height = 4.00000E+00
  C.Radius 合法、C.Width 不存在——分量集由判别式决定。
  判别式的完整机制（变体记录/约束/越界检查）见下一章。

--- 6. 空记录与限定聚集 ---
  Null_Record 占 0 位
  D =  4/ 7/ 1987
  Date'(...) 限定让聚集类型一锤定音，消除上下文二义。
```

## 07.9 小结

| 概念 | 要点 |
|------|------|
| 记录说明 | 分量带名字、类型、可选约束与缺省初值 |
| 聚集 | 指名（任意序）/位置（说明序）；必须完整；`others` 可用 |
| 缺省初值 | 类型设计者定"零值"；显式聚集覆盖之 |
| 嵌套与点记法 | `PSW.Flag.Zero` 逐层选择；嵌套聚集自然嵌套 |
| 值语义 | 赋值=全拷贝；`=`/`/=` 自动可用 |
| null record | 占位/标记；`'Size` = 0 |
| 限定聚集 | `T'(...)` 消除类型二义 |
| 变体记录 | 判别式决定分量集；不存在的分量访问即错（详见第 08 章） |

记录解决"打包"，但包在类型层面还是透明的——谁都能看见 `Person`
里有个 `Age`。下一章讲判别式与变体记录的完整机制；再下一章（包）
则会把类型的**内部表示彻底藏起来**。

---
上一章：[06 数组与字符串](06-arrays-strings.md) ｜ 下一章：[08 判别类型](08-discriminants.md) ｜ 返回：[README](../README.md)
