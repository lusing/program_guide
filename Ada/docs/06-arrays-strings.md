# 06 · 数组与字符串

> 示例：[`examples/ch06_arrays.adb`](../examples/ch06_arrays.adb)
> 运行：`./run-all.sh 06`

数组是**同类型分量的集合**（记录则是可能不同类型分量的集合——下一章）。
Ada 的数组类型系统有三件别处少见的法宝：**界是类型的一部分**、
**非约束数组**把界推迟到对象说明、**属性**让你永远不必硬编码下标。
字符串不是特权类型——它就是预定义的非约束字符数组，所有数组知识
原样适用。本章对应该张丽芬《Ada 程序设计导论》§1.5 之一（数组），
Bounded_String 一节是现代 Ada（95 以后）的补充。

---

## 06.1 先声明类型，再说明数组

Ada 数组的正统写法是两步：先 `type` 后对象说明：

```ada
type Int_Array is array (1 .. 5) of Integer;
A : Int_Array := (10, 20, 30, 40, 50);
```

`array (1 .. 5) of Integer` 这个类型标记的含义：下标取 1..5、
分量是 Integer。**界写在类型里**——于是 `A'First` 永远是 1、
`A'Length` 永远是 5，这成为类型的**静态属性**，编译器据此检查
每一次下标访问。

Ada 也允许**一步到位**的匿名数组（上一章气泡分类已用过）：

```ada
A : array (1 .. 10) of Integer := (others => 0);
```

方便，但这个 A 的类型是匿名的——**不能再说明同类型的第二个数组**
（每个匿名说明都是新类型），也没法把它传给"这个类型"的形参。
示例代码用它是因为场合小；工程代码请老老实实先 `type`。

## 06.2 数组聚集：位置、指名与 others

给数组整体赋值的表达式叫**聚集（aggregate）**。三种记法：

```ada
type Int_Array is array (1 .. 5) of Integer;
A  : Int_Array := (10, 20, 30, 40, 50);        -- 位置聚集：按下标顺序
B  : Int_Array := (1 => 10, 3 => 30, 2 => 20,  -- 指名聚集：顺序任意
                   4 => 40, 5 => 50);
C  : Int_Array := (1 .. 3 => 7, others => 0);  -- 范围 + others
D  : Int_Array := (others => 1);               -- 全部同一值
```

示例验证 `A = B` 为 TRUE——两种记法殊途同归。规则要点：

- **聚集必须完整**：每个分量都得有值，漏一个编译错。这看似严苛，
  实则是 Ada 的大杀器——"忘记初始化某个元素"这类缺陷从根上绝迹。
- `others` 若出现**必须放最后**，代表"前面没点到的所有下标"。
- 下标可以是范围（`1 .. 3 => 7`）、单值、或竖线并列
  （`1 | 3 | 5 => 0`）。
- 当聚集的类型不能从上下文推断时，用**限定聚集**：
  `Int_Array'(1, 2, 3, 4, 5)`——类型名一锤定音。

## 06.3 非约束数组：界延迟决定

约束数组把界焊死在类型里；**非约束数组（unconstrained array）**
只固定下标的类型，把界留白：

```ada
type Vector is array (Integer range <>) of Float;
```

`<>` 读作"box"，意思是"界待定"。对象说明时必须补上界：

```ada
V1 : Vector (1 .. 3)  := (1.0, 2.0, 3.0);   -- 界在对象说明时给定
V2 : Vector (-2 .. 2) := (others => 0.0);   -- 下界可以任意，含负数
```

示例输出：

```text
  V1'First = 1  V1'Last = 3  V1'Length = 3
  V2'First =-2  V2'Length = 5
  同一类型，不同界——这就是子程序能接受任意长度数组的原因。
```

这正是 Ada 数组参数安全的根基：形参类型写 `Vector`，**实参的界
随实参传入**，体内用 `A'First`/`A'Last` 适配——下标越界在任何
调用组合下都逃不出检查。老教材 §1.5 专门强调：非约束数组类型
"只能用在类型说明和参数说明中"，对象说明必须给出界。

## 06.4 属性：永不硬编码下标

数组对象（和约束数组类型）的属性全家福：

| 属性 | 含义 | 例 |
|------|------|-----|
| `A'First` / `A'Last` | 第一维下界/上界 | `A'First` = 1 |
| `A'First (N)` / `A'Last (N)` | 第 N 维的下界/上界 | `M'First (1)` |
| `A'Length` | 第一维元素个数 | = `A'Last - A'First + 1` |
| `A'Length (N)` | 第 N 维元素个数 | `M'Length (2)` |
| `A'Range` | 第一维范围 | 相当于 `A'First .. A'Last` |
| `A'Range (N)` | 第 N 维范围 | `M'Range (2)` |

多维数组的用法（示例第 3 节）：

```ada
type Matrix is array (1 .. 3, 1 .. 3) of Integer;
M : Matrix := ((1, 2, 3),
               (4, 5, 6),
               (7, 8, 9));
...
for I in M'Range (1) loop
   for J in M'Range (2) loop
      Put (M (I, J), Width => 3);
   end loop;
   New_Line;
end loop;
```

注意二维聚集的形状：外层括号里**每行一个内层聚集**——嵌套结构与
维度一一对应。`for I in M'Range (1)` 是遍历的标准姿势；写死
`for I in 1 .. 3` 在界变化时就是 bug 温床。

## 06.5 分片：窗口，不是副本

**分片（slice）**是数组中一段连续分量：

```ada
A (1 .. 3) := A (8 .. 10);        -- 分片整体赋值：尾部三个 → 头部三个
A (2 .. 3) := (0, 0);             -- 分片也可以用聚集赋值
```

老教材讲分片时强调的性质：**分片操作不产生元素副本**。分片作为
`in out` 实参传给子程序时，子程序里改分片元素就是改原数组元素。
示例演示了整体赋值与聚集赋值；"窗口"语义在快速排序（对 `A (L .. J)`
递归）这类算法里是性能与语义的双重基石。

分片的要求：**只能切一维数组**（多维数组无分片）、起止下标必须
落在数组界内（越界即 `Constraint_Error`）、`A (4 .. 2)` 这样的
空分片合法（长度 0）。

## 06.6 非约束形参与 Sum 函数

老教材 §1.5 的两个范例函数之一——求和（另一个是字符串连接 "&" 的
实现），示例完整收录：

```ada
type Int_Vector is array (Integer range <>) of Integer;

function Sum (A : Int_Vector) return Integer is
   Total : Integer := 0;
begin
   for I in A'Range loop            -- 不写 1..N，写 A'Range
      Total := Total + A (I);
   end loop;
   return Total;
end Sum;
```

调用端：

```ada
X : Int_Vector (1 .. 4) := (5, 10, 15, 20);
Y : Int_Vector (0 .. 2) := (100, 200, 300);   -- 下界 0 也无妨
...
Put_Line ("  Sum (X) =" & Integer'Image (Sum (X)));   -- 50
Put_Line ("  Sum (Y) =" & Integer'Image (Sum (Y)));   -- 600
```

同一个 `Sum` 吃下界 1 和下界 0 的两种实参，全靠 `A'Range` 适配。
这个模式请刻进肌肉记忆：**写数组循环永远用 `'Range`，写数组长度
永远用 `'Length`**。

顺带一提：老教材展示的字符串连接函数——`function "&" (X, Y : String)
return String`，结果串长度 `X'Length + Y'Length`、两段赋值拼装——
正是标准库 `&` 操作符的原理。Ada 的 `&` 不是特权，是普通重载
操作符。

## 06.7 字符串：预定义的非约束数组

String 的定义只有一行：

```ada
type String is array (Positive range <>) of Character;
```

所以字符串 = 非约束一维字符数组。全部推论随之而来：

- **定长**。`S1 : String (1 .. 12)` 必须恰好 12 字符，赋短串、长串
  都编译错/运行错。文字必须补空格（`"Ada Lovelace        "`）。
- **常量串的长度由初值决定**：`S3 : constant String := "Hello" & " "
  & "Ada";`——`&` 拼接在常量说明里完成，长度静态可知。
- 切片、比较、`'Length`、`'Range` 全套适用：

```ada
S1 : String (1 .. 12) := "Hello, World";
...
Put_Line ("  S1 (1..5) = " & S1 (1 .. 5));     -- 切片：Hello
Put_Line ("  S1 (8..12) = " & S1 (8 .. 12));   -- World
```

中文字符串要小心：`String` 每分量 8 位（Latin-1），一个 UTF-8 汉字
占 3 个分量；`"Ada编程"` 的 `'Length` 是 3+6=9。显示没问题（字节
原样透传），但按"字符数"切片会切出半个汉字。需要真正的宽字符时
用 `Wide_String`（UTF-16）。

## 06.8 变长字符串：Bounded 与 Unbounded

定长 String 在"运行期长度可变"的场景很笨拙——拼接一下就得重新
声明。标准库 `Ada.Strings` 给出两套方案：

```ada
package BS is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 64);
use BS;
B : Bounded_String := To_Bounded_String ("Hello");
...
B := B & To_Bounded_String (" Ada!");  -- 拼接
Put_Line ("  Bounded_String = " & To_String (B));
Put_Line ("  Length =" & Integer'Image (Length (B))
          & " / Max = 64（超限会异常，但无堆分配）");
```

- **Bounded_String**：编译期上限、栈上存储、零堆分配——实时/嵌入式
  的选择。`Generic_Bounded_Length` 是泛型（第 12 章），Max 作为
  参数传进去。
- **Unbounded_String**（`Ada.Strings.Unbounded`）：无显式上限，
  内部堆分配，用起来最像其他语言的 String——应用层的选择。

经验法则：接口与协议报文用 `String`（定长、可预测），算法内部
攒文本用 `Bounded`（安全）或 `Unbounded`（方便）。

## 06.9 本章示例的完整输出

```text
=== Ada 数组与字符串 ===

--- 1. 约束数组与聚集 ---
  A (位置) = [10, 20, 30, 40, 50]
  B (指名) 与 A 相同：TRUE
  C (others) = [7, 7, 7, 0, 0]
  D (others=>1) = [ 1,...]
  聚集必须完整：所有分量都要有值，缺一个即编译错。

--- 2. 非约束数组 ---
  V1'First = 1  V1'Last = 3  V1'Length = 3
  V2'First =-2  V2'Length = 5
  同一类型，不同界——这就是子程序能接受任意长度数组的原因。

--- 3. 多维数组 ---
  3x3 矩阵（嵌套聚集，外层每行一个括号）:
      1  2  3
      4  5  6
      7  8  9
  M'First (1) = 1  M'Last (2) = 3

--- 4. 数组分片 ---
  赋值后 A (1..10) = 8 9 10 4 5 6 7 8 9 10
  A (2..3) := (0,0) 后 A (2) = 0，A (3) = 0
  分片作为 in out 实参传递时是"窗口"而非副本——
  在子程序里改分片元素，就是改原数组元素（无拷贝）。

--- 5. 非约束数组形参 ---
  Sum (X) = 50
  Sum (Y) = 600
  同一个 Sum 适配任意界的实参：靠 A'Range 属性。

--- 6. 字符串 ---
  S1 = Hello, World
  S3 = Hello Ada（& 拼接出的常量串，长度自动确定）
  S1'Length = 12
  S1 (1..5) = Hello
  S1 (8..12) = World

--- 7. 有界字符串 (Bounded) ---
  Bounded_String = Hello Ada!
  Length = 10 / Max = 64（超限会异常，但无堆分配）
```

## 06.10 小结

| 概念 | 要点 |
|------|------|
| 数组类型 | 界属于类型；先 `type` 后说明是正统 |
| 聚集 | 位置/指名/范围/`others`；必须完整 |
| 非约束数组 | `range <>` 界留白；对象说明补界 |
| 属性 | `'First/'Last/'Length/'Range (N)`；循环必用 `'Range` |
| 分片 | 一维连续段；窗口非副本；可作 in out 实参 |
| String | 预定义非约束字符数组；定长；UTF-8 汉字占 3 分量 |
| Bounded/Unbounded | 编译期上限零堆分配 / 无上限堆分配 |

数组解决"同质集合"，异质集合交给下一章的**记录**。

---
上一章：[05 子程序](05-subprograms.md) ｜ 下一章：[07 记录](07-records.md) ｜ 返回：[README](../README.md)
