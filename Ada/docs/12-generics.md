# 12 · 泛型编程

> 示例：[`examples/ch12_generics.adb`](../examples/ch12_generics.adb)
> 运行：`./run-all.sh 12`

"写一次，到处实例化"——**通用单元（generic units，现代术语：泛型）**
是 Ada 的第四种程序单元。它是带**空白**的模板：类型、数值、甚至
子程序都可以是空白，由**实例化**（取例）时填入。一个泛型栈模板，
要 Integer 栈就填 Integer、要 Boolean 栈就填 Boolean——代码冗余
从根上消灭。本章讲泛型说明与实例化、**通用形参的种类**（类型/
数值/子程序）、并用老教材第 9 章的经典案例（通用栈、第 N 个后继、
带子程序参数的排序）落地。更深的花式形参与匹配规则在第 13 章。

---

## 12.1 为什么需要泛型：对称矩阵的教训

老教材 §9.1 的动机例子：一个**对称矩阵**包——只存下三角（100×100
只要 5050 个单元），提供 `Store (M, i, j, x)` 与 `Component (M, i, j)`
两个操作。用 Integer 写完，需求变了：元素要 String。于是整包重抄
一遍，只把 `Integer` 换成 `String`——**系统里从此有两份 99% 相同
的代码**，改一个 bug 要改两处。

泛型的解法：把"元素类型"做成形参——

```ada
generic
   Matrix_Size     : in Positive;          -- 数值空白
   type Component_Type is private;         -- 类型空白
package Symmetric_Matrix_Template is
   ...                                    -- 算法只写一遍，用 Component_Type
end Symmetric_Matrix_Template;

-- 实例化：填空白
package Sym_Int    is new Symmetric_Matrix_Template (100, Integer);
package Sym_String is new Symmetric_Matrix_Template (50, String);
```

老教材的比喻很形象：泛型像**信件的模板**——收发信人姓名地址留白，
写信一次，寄给谁就把空白填成谁。Ada 83 时代这是独步天下的设施
（比 C++ 模板早了整十年设计），标准库的 `Ada.Containers`（第 23 章）、
`Sequential_IO`/`Direct_IO`（第 18 章）全部建立在它上面。

## 12.2 泛型说明与实例化

泛型单元的骨架：`generic` 引出**通用形参**，跟着一个普通的
子程序或包说明；体与普通单元无异：

```ada
generic
   形参说明;
   形参说明;
procedure P (...);          -- 或 function / package
```

最小实例（示例第 1 节）——任何可赋值类型的交换：

```ada
generic
   type Element_Type is private;
procedure Swap (A, B : in out Element_Type);

procedure Swap (A, B : in out Element_Type) is
   Temp : constant Element_Type := A;
begin
   A := B;
   B := Temp;
end Swap;
```

**实例化**是一次编译期动作（不是运行期调用）：

```ada
procedure Swap_Int is new Swap (Element_Type => Integer);
```

从这句起，`Swap_Int` 是一个货真价实的 Integer 过程——生成了一份
针对 Integer 的代码。同一个模板想换 Float？再实例化一份。这与
C++ 的隐式模板实例化不同：**Ada 的实例化必须显式命名**，没有
"调用时自动推导"。显式有显式的好：每个实例有名字、可 with、可
重用、可控制代码膨胀。

```text
  Swap_Int 后 X = 20, Y = 10
  Max_Int (42, 17) = 42
  实例化是编译期动作：生成一份针对 Integer 的代码。
```

## 12.3 通用形参的种类：类型篇

泛型形参是"带类别约束的空白"。类型形参的**类别**决定了体内能对
它做什么：

| 形参说明 | 匹配什么类型 | 体内可用的操作 |
|----------|--------------|----------------|
| `type T is limited private` | 任何类型 | 仅参数传递 |
| `type T is private` | 任何可赋值类型 | 赋值、`=`/`/=` |
| `type T is (<>)` | 离散类型（整/枚举/字符） | 赋值、比较、`Succ/Pred/Val/Pos/First/Last` |
| `type T is range <>` | 整型 | 算术、比较 |
| `type T is digits <>` | 浮点 | 浮点算术 |
| `type T is delta <>` | 定点 | 定点算术 |
| `type T is array (I) of E` | 特定索引/分量的数组 | 数组操作、属性 |
| `type T is access X` | 访问类型 | 解引用 |

原理：**形参类别 = 体内允许使用的操作集**。写 `is private` 意味着
"我只要赋值"，所以 Integer、String、你自定义的记录全都能填；
写 `is (<>)` 意味着"我要用 `'Succ`"，那实参就必须是离散类型——
实例化时检查，填 Float 直接编译错。

示例用到前两类。`Max` 用离散类：

```ada
generic
   type T is (<>);          -- 任何离散类型：整型/枚举/字符
function Max (A, B : T) return T;
```

体内用 `>` 比较——离散类型必有全序，比较合法。若把形参类别改成
`private`，`>` 就没有着落（private 承诺的只有赋值和判等），编译
失败。**类别是对模板作者的约束，也是对使用者的承诺**。

## 12.4 通用形参的种类：数值与子程序篇

**数值形参**——普通 `in` 参数，实例化时给编译期常量：

```ada
generic
   type Enum is (<>);
   N : Integer := 2;        -- 值形参可带缺省
function After_N (E : Enum) return Enum;
```

**子程序形参**——`with` 引出，把"操作"本身作为空白（这是老教材
§9.3 的重头，也是泛型最锋利的部分）：

```ada
generic
   type Index is (<>);                              -- 下标：离散类型
   type Elem  is private;                           -- 元素：可赋值即可
   type Arr   is array (Index range <>) of Elem;    -- 数组：非约束
   with function Lt (X, Y : Elem) return Boolean;   -- 注入比较
   with procedure Put_Elem (X : Elem);              -- 注入打印
package Sort_G is
   procedure Put (V : Arr);
   procedure Sort (V : in out Arr);
end Sort_G;
```

看 `Sort_G` 的排序体——插入分类，对任何 `Elem` 排序，"谁小"完全
由注入的 `Lt` 决定：

```ada
procedure Sort (V : in out Arr) is
   I, J : Index;
   M, T : Elem;
begin
   I := Index'Succ (V'First);
   while I <= V'Last loop
      M := V (I);
      J := I;
      while J > V'First and then Lt (M, V (Index'Pred (J))) loop
         V (J) := V (Index'Pred (J));
         J := Index'Pred (J);
      end loop;
      V (J) := M;
      I := Index'Succ (I);
   end loop;
end Sort;
```

注意两个泛型编程的纪律：下标推进用 `Index'Succ/Pred`（泛型离散
类型上 `+1` 不是通用操作——本章示例开发时就踩过 `V'First + 1`
编译错的坑）；比较用 `Lt` 而不是 `<`（Elem 是 private，没有 `<`）。

实例化时提供实参子程序：

```ada
function Lt_Ch (X, Y : Character) return Boolean is (X < Y);

package Ch_Sort is new Sort_G
  (Index     => Integer,
   Elem      => Character,
   Arr       => Chars,
   Lt        => Lt_Ch,
   Put_Elem  => Put_Ch);

Data : Chars (1 .. 8) := ('a', 'd', 'c', 'b', 'h', 'e', 'f', 'g');
...
Ch_Sort.Sort (Data);
```

```text
  排序前   [a, d, c, b, h, e, f, g]
  排序后   [a, b, c, d, e, f, g, h]
  换一种元素类型/比较规则，只要再实例化一份 Sort_G。
```

想把字符串按长度排？写个 `Lt_By_Length` 再实例化一份——排序逻辑
一行不动。老教材的 `GSORT`（通用插入分类）正是这个结构，还演示了
子程序形参的**缺省**：`with function Lt (X, Y : Elem) return
Boolean is <>;`——尖括号缺省的含义是"若实参处恰好有同签名同名
的 `Lt` 直接可见，可以省略不写"。（另有 `is 具体子程序名` 的
固定缺省。）

顺带一提：**运算符也能当实参**——`Lt => "<"` 直接把语言的操作符
填进空白（老教材 GSORT 主程序就这么干的）。

## 12.5 案例一：第 N 个后继（After_N）

老教材 §9.4 例一的函数——枚举值往后走 N 步，到头**环绕**：

```ada
generic
   type Enum is (<>);
   N : Integer := 2;
function After_N (E : Enum) return Enum;

function After_N (E : Enum) return Enum is
   G : Enum := E;
begin
   for I in 1 .. N loop
      if G = Enum'Last then
         G := Enum'First;      -- 到头环绕
      else
         G := Enum'Succ (G);
      end if;
   end loop;
   return G;
end After_N;
```

两个泛型知识点的合体：**属性 `'Succ` 在泛型离散形参上照常工作**
（类别 `(<>)` 承诺了它）；**数值形参与类型形参混用**。同一个模板
生成不同的"后继函数"：

```ada
type Day is (Mon, Tue, Wed, Thu, Fri, Sat, Sun);
function Next2 is new After_N (Day, 2);    -- N = 2
function Next5 is new After_N (Day, 5);    -- N = 5
```

```text
  Next2 (Fri) = SUN
  Next2 (Sat) = MON
  Next5 (Thu) = TUE
```

`Next2 (Sat)` 越过 `Sun` 环绕回 `Mon`——第 03 章 `'Succ` 越界
会炸，这里函数体自己做了环绕分支，两全。

## 12.6 案例二：通用栈（Stack_G）

老教材 §9.4 例二的泛型包——容量与元素类型都留白：

```ada
generic
   Size : Positive;                 -- 值形参
   type Elem is private;            -- 类型形参
package Stack_G is
   procedure Push (E : in Elem);
   procedure Pop  (E : out Elem);
   function Is_Empty return Boolean;
   Stack_Overflow, Stack_Underflow : exception;   -- 异常也是接口
end Stack_G;

package body Stack_G is
   Space : array (1 .. Size) of Elem;
   Index : Integer range 0 .. Size := 0;

   procedure Push (E : in Elem) is
   begin
      if Index = Size then
         raise Stack_Overflow;
      end if;
      Index := Index + 1;
      Space (Index) := E;
   end Push;

   procedure Pop (E : out Elem) is
   begin
      if Index = 0 then
         raise Stack_Underflow;
      end if;
      E := Space (Index);
      Index := Index - 1;
   end Pop;

   function Is_Empty return Boolean is (Index = 0);
end Stack_G;
```

细看包体：`Space` 的大小是 `Size`（形参）、元素类型是 `Elem`
（形参）、`Index` 的范围 0..Size 也是。**一个模板，整套逻辑**。
两次实例化：

```ada
package Int_Stack  is new Stack_G (Size => 10, Elem => Integer);
package Bool_Stack is new Stack_G (Size => 4,  Elem => Boolean);
```

```text
  Int_Stack.Pop  → 300
  Bool_Stack.Pop → TRUE
  同一模板生成两套独立代码：容量、元素类型都不同。
```

要点：两个实例**完全独立**——`Int_Stack` 满了不影响 `Bool_Stack`；
每个实例还各自带一份 `Stack_Overflow` 异常（`Int_Stack.Stack_Overflow`
与 `Bool_Stack.Stack_Overflow` 是两个不同的异常）。这正是第 10 章
"包体状态"在泛型下的自然推广：实例 = 包的一次"编译期调用"。

## 12.7 本章示例的完整输出

```text
=== Ada 泛型编程 ===

--- 1. 实例化 ---
  Swap_Int 后 X = 20, Y = 10
  Max_Int (42, 17) = 42
  实例化是编译期动作：生成一份针对 Integer 的代码。

--- 2. 第 N 个后继 ---
  Next2 (Fri) = SUN
  Next2 (Sat) = MON
  Next5 (Thu) = TUE

--- 3. 泛型栈 ---
  Int_Stack.Pop  → 300
  Bool_Stack.Pop → TRUE
  同一模板生成两套独立代码：容量、元素类型都不同。

--- 4. 子程序形参排序 ---
  排序前   [a, d, c, b, h, e, f, g]
  排序后   [a, b, c, d, e, f, g, h]
  换一种元素类型/比较规则，只要再实例化一份 Sort_G。
```

## 12.8 小结

| 概念 | 要点 |
|------|------|
| 泛型模板 | `generic` 形参表 + 普通/包说明；体照常写 |
| 实例化 | `is new` 显式命名；编译期生成代码 |
| 类型形参类别 | `limited private`/`private`/`(<>)`/`range <>`/… = 操作承诺 |
| 数值形参 | 编译期常量；可带缺省 |
| 子程序形参 | `with` 引出；`is <>` 缺省；运算符可作实参 |
| 泛型纪律 | 离散下标用 `'Succ/'Pred`；private 上只用赋值与判等 |
| 实例独立性 | 各自的包体状态、各自的异常 |

本章的形参都是"入门款"——形式对象、形参的输入输出、泛型内访问
全局的规矩、泛型互相嵌套等深水区在第 13 章。

---
上一章：[11 异常](11-exceptions.md) ｜ 下一章：[13 泛型进阶](13-generics-deep.md) ｜ 返回：[README](../README.md)
