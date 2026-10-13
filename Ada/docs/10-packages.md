# 10 · 包与模块化编程

> 示例：[`ch10_math_lib.ads`](../examples/ch10_math_lib.ads)（包规范）/
> [`ch10_math_lib.adb`](../examples/ch10_math_lib.adb)（包体）/
> [`ch10_packages.adb`](../examples/ch10_packages.adb)（主程序）
> 运行：`./run-all.sh 10`

Ada 有四种程序单元：**子程序、程序包（package）、通用单元（泛型）、
任务**。其中程序包是"数据密封与信息隐藏的机构"——它把逻辑相关的
常量、类型、变量、子程序打包，向外界只暴露**接口**（规范），把
**实现**（体）完全藏起来。本章用一个功能完整的**分数运算包**把包
的每个机制走一遍：规范与体、私有类型、延迟常量、异常作为接口、
包体状态与加工语句；最后用老教材的**符号表**案例证明信息隐藏的
价值——换实现，客户代码一行不改。内容对应张丽芬《Ada 程序设计
导论》第五章（程序包）。

---

## 10.1 为什么需要包

没有包的世界里，"模块"靠自觉：类型定义和操作它的子程序散落各处，
调用方对数据结构内部想摸就摸。老教材 §5.1 的动机陈述至今成立：

> 程序包是一个数据密封和信息隐藏的机构……用户只能引用程序包说明
> 的可见部分中规定的实体……用户程序不能依赖于程序包的实现细节。

"不能依赖实现细节"是关键词——它意味着**实现可以换**（见 10.8 的
符号表实验）。包还有工程价值：规范与体是**两个编译单元**，可以
分开编译（第 26 章），改体不必重编客户。

## 10.2 包规范与包体

包规范（`.ads`）声明"对外提供什么"，包体（`.adb`）实现"怎么提供"。
本教程的示例包 `Ch10_Math_Lib` 提供一个分数类型与全套运算，规范
全文如下（讲解穿插其间）：

```ada
package Ch10_Math_Lib is

   -- 命名数字：无类型常量，任何数值类型均可采用
   Pi : constant := 3.14159_26535;

   -- 私有类型：外面只知道"有这个类型"，不知道它的结构
   type Fraction is private;

   -- 延迟常量：常量名现在可见，值推迟到私有部分给出
   Zero : constant Fraction;

   -- 构造与观察
   function Make (Num : Integer; Den : Integer) return Fraction;
   function Numerator   (X : Fraction) return Integer;
   function Denominator (X : Fraction) return Positive;

   -- 分数四则：运算符重载让分数运算保持数学写法
   function "+" (X, Y : Fraction) return Fraction;
   function "-" (X, Y : Fraction) return Fraction;
   function "*" (X, Y : Fraction) return Fraction;
   function "/" (X, Y : Fraction) return Fraction;

   -- 包接口的一部分：调用方要能捕获的异常在规范中声明
   Zero_Denominator : exception;

   -- 包体状态：统计已执行的运算次数
   function Op_Count return Natural;

private
   -- 私有部分：Fraction 的完整定义——包外不可见，包内（规范与体）可用
   type Fraction is
      record
         Num : Integer;    -- 分子（可负）
         Den : Positive;   -- 分母（化简后恒为正）
      end record;

   Zero : constant Fraction := (Num => 0, Den => 1);

end Ch10_Math_Lib;
```

规范分两段：

- **可见部分**（`is` 到 `private`）：客户能用的全部名字。注意这里
  的子程序只有**说明**（签名），没有体——老教材 §5.2 强调"过程体、
  程序包体、任务体必须放在程序包体中"。
- **私有部分**（`private` 到 `end`）：给编译器看的"内部图纸"。
  客户代码**看不到**这里的任何东西（不能直接访问 `F.Num`），
  但编译器需要它来给 `Fraction` 的对象分配空间。私有部分是
  "纯语言组织"的伟大折衷：类型安全要求编译器知道表示，信息隐藏
  要求客户不知道——于是只让编译器看。

包体的骨架：

```ada
package body Ch10_Math_Lib is
   -- 包体私有的说明（变量、子程序）……
   -- 规范里声明的所有子程序的体……
begin
   -- 包体加工语句：包第一次被使用时执行一次（初始化段）
   Operations := 0;
end Ch10_Math_Lib;
```

包体**必须**给出规范中所有子程序的体；包体还可以有自己的私有
武器——外部不可见的变量与子程序。

## 10.3 私有类型：Fraction 的两面

`type Fraction is private;` 在可见部分声明了一个**私有类型**：
客户知道"存在类型 Fraction"、可以对它做**赋值、相等比较、作参数
传递**——但不知道它的结构，于是**不能**：

- 访问分量（`F.Num` 编译错——哪怕私有部分明明写着 Num）；
- 用聚集初始化（`F := (1, 2)` 编译错）；
- 定义它的数组、给它加字段。

想要值只能走正门：`Make (1, 2)` 构造、`Numerator (F)` 观察。
这就是**两面观点**——老教材的原话：

> 私有类型说明和相应的完全说明提供了对私有类型的两个不同观点，
> 即程序包外部观点和程序包内部观点。

客户视角的 Fraction 是"一个分数"；包体视角的 Fraction 是
`record Num : Integer; Den : Positive; end record`。

**受限私有类型（limited private）**——连赋值和比较都没有：

```ada
type File_Type is limited private;   -- 文件：复制句柄没有意义
```

客户只能作参数传递，不能 `:=`、不能 `=`。文件、锁、任务句柄这类
"身份型"对象该用 limited private——复制一个文件句柄造成的混乱
比好处多。老教材 §5.4 用它改造了 ORDERED_SET：第一版只能管一个
集合（集合数据是包体里的全局变量），第二版把集合本身做成
`type ORD_SET is limited private`，客户想有几个集合就说明几个
对象——**从"单例服务"到"类型工厂"**的跃迁只差一个私有类型。

## 10.4 延迟常量：先见名，后见值

```ada
Zero : constant Fraction;              -- 可见部分：只有名字和类型
...
private
   Zero : constant Fraction := (Num => 0, Den => 1);   -- 私有部分：给值
```

为什么拆开？因为常量的值 `(Num => 0, Den => 1)` 用到了 `Fraction`
的内部表示——而表示在私有部分才展开。延迟常量（deferred constant）
让**名字属于接口、值属于实现**。客户用起来毫无迟感：`A + Zero`
就是一个普通的常量表达式。老教材的 `MANAGER` 包（通行字管理，
`NULL_PASSWORD : constant PASSWORD;`）是这个机制的经典示范。

## 10.5 异常作为接口

```ada
Zero_Denominator : exception;
```

异常在包规范里声明，含义是：**这是本包可能发生、且希望客户处理的
情况**。体的实现：

```ada
function Make (Num : Integer; Den : Integer) return Fraction is
   F : Fraction;
begin
   Operations := Operations + 1;
   if Den = 0 then
      raise Zero_Denominator with "分母不能为零";
   end if;
   ...
end Make;
```

`raise ... with "消息"`（Ada 2005 引入）给异常附带诊断消息，客户
用 `Exception_Message` 取出（第 11 章）。把异常放规范而非体里，
客户才能写 `when Zero_Denominator =>`——异常名属于接口，与函数
名同等地位。标准库到处如此：`Ada.Text_IO` 的 `End_Error`、
`Name_Error`……都是"包的接口承诺"。

## 10.6 包体：私有子程序、包体状态与加工语句

包体藏着三类东西，示例各有演示：

**① 包体私有子程序**——外面包里看不见的内部工具：

```ada
-- 欧几里得算法求最大公约数（老教材 FRACTION_PACKAGE 的私有子程序）
function GCD (A : Natural; B : Positive) return Positive is
   X : Natural  := A;
   Y : Positive := B;
   Old_Y : Positive;
begin
   while X /= 0 loop
      Old_Y := Y;
      Y := X;
      X := Old_Y mod X;
   end loop;
   return Y;
end GCD;

-- 约分：分子分母同除以最大公约数（私有过程，外部无法调用）
procedure Reduce (F : in out Fraction) is
   G : constant Positive := GCD (abs F.Num, F.Den);
begin
   F.Num := F.Num / G;
   F.Den := F.Den / G;
end Reduce;
```

客户永远调不到 `Reduce`——分数永远以最简形式存在这一**不变量**，
靠私有子程序维持。这正是老教材分数包（`FRACTION_PACKAGE`）的
结构：`GREATEST_COMMON_DIVISOR` 与 `REDUCE` 藏在体里，四则运算
先算后约分。

**② 包体状态**——包自己的"全局变量"：

```ada
Operations : Natural := 0;    -- 只在包内可见，外部只能通过 Op_Count 读
```

每次运算自增（`Operations := Operations + 1;` 在四个运算符与
Make 里都有），外部通过 `function Op_Count return Natural` 读数。
运行示例：`Op_Count（含 1 次失败的除法）= 12`。包体状态 = 对象的
私有心跳；利用它可实现缓存、计数、统计，客户毫无感知。

**③ 包体加工语句**——`begin ... end` 包体尾部那段：

```ada
begin
   Operations := 0;
end Ch10_Math_Lib;
```

包被第一次使用（加工 elaboration）时执行**一次**。复杂的初始化
（读配置、建表、握手）放这里；失败可以 raise，异常沿依赖链传播
（第 11 章 11.5 讲规则）。纯初始化的包可以完全省略这段。

## 10.7 使用包：三种可见性层级

主程序一瞥：

```ada
with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Exceptions;
with Ch10_Math_Lib; use Ch10_Math_Lib;
```

- **`with Ch10_Math_Lib`**——让包名可见。此后可以写全限定名：
  `Ch10_Math_Lib.Make (1, 2)`。
- **`use Ch10_Math_Lib`**——让包内**直接可见**：`Make (1, 2)`、
  `A + B`、`Zero` 不带前缀。
- 点记法永远可用：`Ch10_Math_Lib.Pi`。名字冲突时（比如两个包都有
  `Make`），回到全限定即可消歧——第 05 章讲过的选择可见性。

示例的运算演示：

```ada
A : constant Fraction := Make (1, 2);
B : constant Fraction := Make (1, 3);
...
Put_Line ("  1/2 + 1/3 = " & Img (A + B));   -- 5/6
Put_Line ("  1/2 / 1/3 = " & Img (A / B));   -- 3/2
```

注意 `Img` 是主程序里的局部函数——它只能通过 `Numerator`/
`Denominator` 取值，摸不到 `F.Num`。私有性立得住。

## 10.8 信息隐藏的证明：符号表案例

老教材 §5.5 的第一个大例子是**符号表管理程序包**——编译器的
核心部件。它的接口（规范）如下：

```ada
package Symbol_Table_Manager is
   N        : constant := 200;
   Item_Size : constant := 20;
   type Item is new String (1 .. Item_Size);
   type Item_Type is (Var, Fun, Proc, Keywd, Label);

   procedure Add (X : in Item; I : in Item_Type);
   function In_Table (X : in Item) return Boolean;
   function Get (X : in Item) return Item_Type;
   function Full return Boolean;
   procedure Clear;
end Symbol_Table_Manager;
```

五种操作：插入、查在不在、查信息、查满、清空。老教材给出**两个
实现**：

**实现一：数组 + 顺序检索**——包体里一个 `ST : array (1 .. N)
of Item_Info;` 与游标 `Last`，`In_Table` 线性扫。

**实现二：有序二叉树**——符号数量大后顺序检索太慢，包体改为：

```ada
package body Symbol_Table_Manager is
   type Item_Info;
   type Next_Element is access Item_Info;      -- 访问类型（第 09 章）
   type Item_Info is
      record
         ID    : Item;
         T     : Item_Type;
         Left  : Next_Element;
         Right : Next_Element;
      end record;
   Root : Next_Element;
   Num_Elements : Integer range 0 .. N := 0;

   procedure Add (X : in Item; I : in Item_Type) is
      procedure Insert (X : in Item; I : in Item_Type;
                        R : in out Next_Element) is
      begin
         if R = null then
            R := new Item_Info'(X, I, null, null);
         elsif X < R.ID then
            Insert (X, I, R.Left);
         else
            Insert (X, I, R.Right);
         end if;
      end Insert;
   begin
      Insert (X, I, Root);
      Num_Elements := Num_Elements + 1;
   end Add;
   -- In_Table/Get 同样改为沿树查找，平均检索从 O(N) 降到 O(log N)
```

关键结论（老教材原话）：**"由于不需要改变程序包
SYMBOL_TABLE_MANAGER 的说明，故调用程序包的程序单元就不必修改"**。
数组版与二叉树版对客户完全等价——这就是信息隐藏的兑现时刻：
接口稳定，实现演进。没有私有类型的语言里做同样的事，客户代码里
满地的 `ST (i).ID` 全得跟着改。

（老教材同节的第二个大例子是**优先级队列管理包**——操作系统作业
调度用，同样"接口不变、内部从简单数组换堆"的思路，加上第 09 章
的 ORDERED_SET 配合可做最短作业优先调度——第 17 章的任务版会
重访它。）

## 10.9 本章示例的完整输出

```text
=== Ada 包 (Package)：分数运算 ===

--- 1. 构造与约分 ---
  Make (1, 2)  = 1/2
  Make (2, 4)  = 1/2   （自动约分）
  Make (2, -4) = -1/2  （负分母规范化）

--- 2. 四则运算 ---
  1/2 + 1/3 = 5/6
  1/2 - 1/3 = 1/6
  1/2 * 1/3 = 1/6
  1/2 / 1/3 = 3/2
  Zero 是规范里的延迟常量：A + Zero = 1/2

--- 3. 异常接口 ---
  准备用 1/2 除以 Zero ...
  捕获 Zero_Denominator：除以零分数

--- 4. 包体状态 ---
  Op_Count（含 1 次失败的除法）= 12
  Operations 变量本身在包体里，外部不可见。

--- 5. 命名数字 ---
  Pi (Float)      =  3.14159E+00
  Pi * 2 (实数字面量可直接乘) =  6.28319E+00
```

## 10.10 小结

| 概念 | 要点 |
|------|------|
| 包规范/体 | 接口与实现分离；体必须补齐规范声明的所有子程序 |
| 可见/私有部分 | 客户用前者；后者给编译器的"内部图纸" |
| 私有类型 | 赋值/比较可用，结构不可见；构造走函数正门 |
| limited private | 连赋值比较都没有；"身份型"对象用 |
| 延迟常量 | 名字在可见部分、值在私有部分 |
| 异常即接口 | 客户要捕获的异常声明在规范里 |
| 包体私有子程序 | 维持不变量的内部工具（GCD/Reduce） |
| 包体状态/加工语句 | 私有心跳；begin 段一次性初始化 |
| 信息隐藏 | 符号表数组版↔二叉树版，客户零改动 |

包把"一个类型 + 它的操作"封成模块。下一类问题包解决不了：
**运行期出错的报告与恢复**——那是异常机制（第 11 章）的领地。

---
上一章：[09 访问类型](09-access-types.md) ｜ 下一章：[11 异常](11-exceptions.md) ｜ 返回：[README](../README.md)
