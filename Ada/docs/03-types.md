# 03 · 基本数据类型与变量

> 示例：[`examples/ch03_types.adb`](../examples/ch03_types.adb)
> 运行：`./run-all.sh 03`

Ada 是**强类型**语言。这句话在别的语言教材里常常只是一句口号，在
Ada 里则是三条可以验证的事实：**每个类型 = 一组值 + 一组操作**；
**每个对象（变量/常量）必须先说明类型**；**类型的约束（比如取值范围）
由语言保证，违反时编译器拒绝、运行期检查兜底**。本章把标量类型——
整型、枚举、字符、布尔、实型——逐一讲透，并厘清 Ada 里两个最容易
混淆的概念：**子类型**与**派生类型**。内容对应张丽芬《Ada 程序设计
导论》§1.3–1.4（类型和目标说明、标量类型）与 §4.1–4.4（强类型、
子类型、派生类型、类型转换），模型数等实现层概念按现代 RM
（Ada Reference Manual）口径重述。

---

## 03.1 类型即"值集 + 操作"

老教材 §1.3 的第一句话值得原样记住：

> 一个类型描述一组数值以及可施加于这组数值的一组操作。

这个定义比"类型 = 存储宽度"深刻得多。`type Age is range 0 .. 150`
不只是"一个数"，而是：值集 {0, 1, …, 150}，操作集 {+、-、比较、
`'First`、`'Last`……}。类型说明的通用形式：

```ada
type 名字 is 类型定义;
```

类型定义引入一个**全新类型**——不是别名。这一点和 C 的 `typedef`
截然不同，是所有后续话题的根基：

```ada
type Age    is range 0 .. 150;                 -- 整型
type Color  is (White, Red, Yellow, Green, Blue);  -- 枚举
type Table  is array (1 .. 10) of Integer;     -- 数组（第 06 章）
```

有了类型，才能说明**对象**（object，老教材译"目标"）：

```ada
标识符表 : [constant] 类型标记 [:= 初值表达式];
```

对象说明的两种基本形态（`T` 是类型、`E` 是表达式）：

```ada
My_Age : Age := 30;            -- 变量
Pi     : constant := 3.14159;  -- 常量（命名数字，见 03.7）
Limit  : constant Integer := 999;  -- 类型化常量
```

**所有变量在用于表达式前都必须赋值**（显式初值或赋值语句）——
用未初始化的变量是错误，编译器会尽量静态发现（会给出警告），
运行期访问未初始化值在多数实现里也会被检查捕获。

## 03.2 整型：把范围写进类型

预定义的整型有三个层次。`Integer` 是必有的一种；`Natural` 和
`Positive` 是它的**子类型**（不是新类型）：

```ada
A : Integer := 42;
B : Natural := 100;          -- 0    .. Integer'Last
C : Positive := 1;           -- 1    .. Integer'Last
```

示例打印出的实际范围（GNAT 16，32 位 Integer）：

```text
  Integer'First  =-2147483648
  Natural 范围   = 0 .. 2147483647
  Positive 范围  = 1 .. 2147483647
```

`Natural`/`Positive` 的价值是**文档化意图**：计数器用 `Natural`、
下标用 `Positive`，读者立刻知道负值无意义。但如果 150 岁是业务
上限，预定义类型帮不了你——这时定义**自己的整型**：

```ada
type Age  is range 0 .. 150;    -- 自定义整型：范围写进类型
type Byte is range 0 .. 255;
My_Age : Age := 30;
T_Byte : Byte := 16#FF#;        -- 直接量与基于表示配合使用
```

范围检查是**语言保证的**。示例里故意做了一次越界：

```ada
-- 范围检查是语言保证的：越界赋值在运行期引发异常
-- （值从字符串运行期解析而来，编译器无法静态预判；
--   若直接写字面量 200，GNAT 在编译期就会警告甚至拒绝）
declare
   Bad : constant Integer := Integer'Value ("200");
begin
   My_Age := Age (Bad);         -- 200 超出 Age 的 0..150
   Put_Line ("  不应到达这里");
exception
   when Constraint_Error =>
      Put_Line ("  My_Age := Age (200) 引发 Constraint_Error（运行期范围检查）");
end;
```

运行输出：`My_Age := Age (200) 引发 Constraint_Error`。注意那个
`exception ... when Constraint_Error`——这是异常处理的预演，第 11
章专门讲。这里要看懂的行为是：**赋值没有悄悄截断、没有回绕，
而是立刻炸出可捕获的异常**。

还有一层更妙的：注释里说的"若直接写字面量 200，GNAT 在编译期就会
警告甚至拒绝"——因为字面量是静态已知的，编译器做**静态范围检查**
能提前把错误拦在运行之前。我们在开发这个示例时就亲身踩到：
`Color'Succ (Blue)`（Blue 恰是枚举末位）直接被编译器判为静态
表达式越界，编译都不通过。**编译期拦一道、运行期兜一道**，这就是
"强类型"在整型上的全部含义。

老教材提到的 `SHORT_INTEGER`/`LONG_INTEGER` 一族在现代 Ada 里
扩展为 `Short_Short_Integer`、`Short_Integer`、`Integer`、
`Long_Integer`、`Long_Long_Integer`（宽度由实现决定，GNAT 在
64 位平台分别是 8/16/32/64/64 位），加上 `System.Max_Int` 这类
实现常量，覆盖了全部嵌入式的整数宽度需求。

## 03.3 枚举类型：自己发明值域

枚举把值**逐个列出来**，第一个值的位置号是 0，依次递增：

```ada
type Color is (White, Red, Yellow, Green, Blue);
type Level is (Low, Medium, Urgent);
My_Color : Color := Green;
```

枚举不只是"整数常量的语法糖"。`Color` 是独立类型，与 `Level`
互不相容；每个枚举类型自带全套属性：

```ada
Put_Line ("  My_Color          = " & Color'Image (My_Color));
Put_Line ("  Color'First       = " & Color'Image (Color'First));
Put_Line ("  Color'Last        = " & Color'Image (Color'Last));
Put_Line ("  Color'Pos (Blue)  =" & Integer'Image (Color'Pos (Blue)));
Put_Line ("  Color'Val (2)     = " & Color'Image (Color'Val (2)));
Put_Line ("  Color'Succ (Green) = " & Color'Image (Color'Succ (Green)));
Put_Line ("  Color'Pred (Green) = " & Color'Image (Color'Pred (Green)));
```

| 属性 | 含义 | 示例值 |
|------|------|--------|
| `T'First` / `T'Last` | 首/末值 | White / Blue |
| `T'Image (X)` | 值 → 字符串 | `"GREEN"` |
| `T'Value ("...")` | 字符串 → 值 | `Color'Value ("Blue")` |
| `T'Pos (X)` | 值 → 位置号 | `Color'Pos (Blue)` = 4 |
| `T'Val (N)` | 位置号 → 值 | `Color'Val (2)` = Yellow |
| `T'Succ (X)` / `T'Pred (X)` | 后继/前驱 | `Succ (Green)` = Blue |
| `T'Range` | `T'First .. T'Last` 的缩写 | 用于循环/子类型约束 |

属性越界同样受保护：

```ada
declare
   Last_One : Color := Color'Value ("Blue");
begin
   Put_Line ("  Color'Succ (Last_One) = " & Color'Image (Color'Succ (Last_One)));
exception
   when Constraint_Error =>
      Put_Line ("  对 Color'Last 求 Succ 引发 Constraint_Error（已到尽头）");
end;
```

（这里用 `Color'Value` 从字符串取值而不是直接写 `Color'Last`，
是为了让检查发生在运行期——静态可判的越界 GNAT 会直接拒绝编译。）

**重载与限定**。两个枚举类型可以有同名的值——这叫直接量的**重载**：

```ada
type Color is (White, Red, Yellow, Green, Blue);
type Light is (Red, Amber, Green);        -- Red/Green 与 Color 重载
```

`Red` 单独出现时编译器无法定类型，用**限定表达式**消歧：

```ada
Put_Line ("  Color'(Red) = " & Color'Image (Color'(Red)));
Put_Line ("  Light'(Red) = " & Light'Image (Light'(Red)));
```

`类型'(表达式)` 这个记号后面还会在数组聚集、记录聚集中反复出现，
一次学会终身受用。

## 03.4 布尔与字符：预定义的枚举

`Boolean` 和 `Character` 不是特权类型，就是两个预定义枚举：

```ada
type Boolean   is (False, True);         -- False < True
type Character is (…256 个 Latin-1 字符…);
```

因为是枚举，全套属性照用：

```ada
Put_Line ("  Boolean 是 (False, True) 枚举：Flag = " & Boolean'Image (Flag));
Put_Line ("  Boolean'Pos (True) =" & Integer'Image (Boolean'Pos (True)));
Put_Line ("  Character 也是枚举：Ch = " & Character'Image (Ch));
Put_Line ("  Character'Val (97) = " & Character'Image (Character'Val (97)));
```

`Character'Val (97)` = `'a'`——字符与 ASCII 码的互转就是 `Val`/`Pos`，
不需要记任何库函数。`Wide_Character`/`Wide_Wide_Character`
（UTF-16/UTF-32）是现代扩展，处理中文时用。

## 03.5 实型：digits 与 delta

Ada 的实型分**浮点**与**定点**两支，精度说明一个顶格关键词：

```ada
type Coef is digits 7;                      -- 浮点：至少 7 位十进制有效数字
type Volt is delta 0.125 range 0.0 .. 255.0;  -- 定点：绝对误差 ≤ 0.125
```

- **浮点**（`digits`）——误差相对于量级，适合科学计算。预定义
  `Float`、`Long_Float`、`Long_Long_Float`（GNAT 对应 32/64/64 位
  IEEE 754）。
- **定点**（`delta` + `range`）——误差绝对、表示精确，适合没有
  FPU 的嵌入式控制器和不容许舍入的货币计算。

示例演示浮点说明与精度属性：

```ada
declare
   Pi : Float := 3.14159;
   D  : Long_Float := 2.718281828;
   type Coef is digits 7;              -- 至少 7 位十进制精度
   K  : Coef := 1.0 / 3.0;
begin
   Put ("  K (Coef 1.0/3.0) = ");  Put (Float (K), Fore => 0, Aft => 9, Exp => 0);
```

输出 `K (Coef 1.0/3.0) = 0.333333343`——第 8 位开始失真，符合
"7 位精度"的承诺。`Coef'Digits` 属性返回要求的精度（7）。

老教材 §1.4 用了大量篇幅讲**模型数（model number）与安全数
（safe number）**——它们是"一个浮点类型到底能精确表示哪些实数"
的形式化答案：`digits D` 的类型保证 `D'Small` 到 `D'Large` 区间内
的模型数二进制精确可表示。现代 RM 把这套理论保留在
`Ada.Numerics` 与 RM §3.5.7（浮点属性 `'Machine_Mantissa`、
`'Machine_Overflows` 等）里，日常编程用不到，但要知道：**Ada 的
浮点是"带精度契约的浮点"**，你的 `digits 7` 是可以拿去跟实现
打官司的，不是注释。

定点类型的完整体系（普通定点、十进制定点、`'Small`/`'Size` 控制）
在第 22 章用滤波器的实战案例展开——那是老教材内容的现代重演，
本章记住 `delta = 绝对误差上限` 即可。

## 03.6 子类型与派生类型：两种"缩小范围"

想给 `Integer` 加个范围限制，有两条路，语义完全不同——这是本章
最重要的辨析，也是 Ada 面试的经典题。

**路线一：子类型（subtype）——同一种类型，加约束。**

```ada
subtype Small_Int is Integer range -100 .. 100;
S : Small_Int := 50;
N : Integer   := 60;
...
S := N;              -- 子类型与基类型直接赋值（带运行期范围检查）
```

`Small_Int` 与 `Integer` 是**同一个类型**，值域被收窄到 -100..100。
两者之间赋值自由互通，越界时（比如 N=500 赋给 S）运行期引发
`Constraint_Error`。`Natural`、`Positive` 就是标准库里的子类型。

**路线二：派生类型（derived type）——全新的类型。**

```ada
type Age is new Natural range 0 .. 150;
A : Age := 30;
N : Integer := 60;
...
-- A := N;          -- 编译错！Age 与 Integer 类型不同
A := Age (N);       -- 派生类型之间必须显式转换
```

`type Age is new ...` 创造**新类型**：继承原类型的全部操作
（+、-、比较……），但与原类型**互不相容**——赋值必须显式转换，
转换时照做范围检查。示例输出：

```text
  S := N 合法：Small_Int 与 Integer 是同一类型，S = 60
  A := Age (N) 显式转换后 A = 60
```

什么时候用哪个？经验法则：

| 需求 | 选择 | 理由 |
|------|------|------|
| 只想收窄范围、仍与 Integer 混算 | `subtype` | 少写转换，约束照查 |
| 防止"单位/语义"混用（年龄≠编号） | 派生类型 | 编译期隔离，混用即报错 |
| 给记录/数组类型起变体 | 派生类型 | 子类型不能改结构 |

安全攸关代码（SPARK，第 25 章）倾向后者：让编译器当门卫。

**`'Base` 属性**——剥掉所有约束后的"基类型"视图：

```ada
Put_Line ("  Small_Int'Base'First =" & Integer'Image (Small_Int'Base'First));
Put_Line ("  Small_Int'First      =" & Integer'Image (Small_Int'First));
```

输出 `-2147483648` 与 `-100`：`Small_Int` 受约束的 `First` 是 -100，
但它的**基类型**仍是完整 Integer。属性运算（如 `abs`、中间计算）
按基类型执行，只在落回受约束对象时再查范围——这解释了为什么
`(S1 + S2) / 2` 不会因为中间值暂时越界而误报。

**类型转换的边界**：同族类型（整数↔整数、实数↔实数、派生↔父类型）
直接 `T (X)`；整数↔实数之间也用 `T (X)` 但语义是**取整/舍入**
（`Integer (3.7)` = 4，四舍五入）；不同族之间（比如把 `Integer`
当 `Float` 的位模式）不存在合法转换，要动 `Unchecked_Conversion`
（第 21 章）那种逃生舱。

## 03.7 常量与命名数字

Ada 的常量分两档：

```ada
Max_Value  : constant Integer := 999;   -- 类型化常量
Dozen      : constant := 12;            -- 命名数字：类型由上下文决定
Max_Count  : constant := Max_Value * 2; -- 常量表达式，编译期求值
```

**命名数字**（named number）没有固定类型，属于"通用整数/通用实数"
——用在哪就按哪的类型理解。`Dozen` 既可以当 `Integer` 用也可以当
`Duration` 用。它是定义"维度无关常数"（比如 `Pi : constant := 3.14159...`）
的正统写法：任何数值类型都能直接采用，无需为每个类型各定义一份。

常量的初值必须是**编译期或加工期可求值**的表达式；对命名数字而言
必须静态可求值（`Max_Value * 2` 合法）。运行期才能确定的"只读量"
不是常量，是 `constant` 对象——`X : constant Integer := F;`
（F 是函数调用）在块/子程序内合法，此时它是"加工期定值的只读变量"。

## 03.8 本章示例的完整输出

```text
=== Ada 基本数据类型与变量 ===

--- 1. 整型 ---
  Integer'First  =-2147483648
  Natural 范围   = 0 .. 2147483647
  Positive 范围  = 1 .. 2147483647
  My_Age (Age 0..150)   = 30
  T_Byte (Byte 0..255)  = 255
  My_Age := Age (200) 引发 Constraint_Error（运行期范围检查）

--- 2. 枚举类型 ---
  My_Color          = GREEN
  Color'First       = WHITE
  Color'Last        = BLUE
  Color'Pos (Blue)  = 4
  Color'Val (2)     = YELLOW
  Color'Succ (Green) = BLUE
  Color'Pred (Green) = YELLOW
  Color'(Red) = RED
  Light'(Red) = RED
  对 Color'Last 求 Succ 引发 Constraint_Error（已到尽头）

--- 3. 实型 ---
  Pi (Float)       = 3.141590
  D (Long_Float)   = 2.718281746
  Coef'Digits      = 7
  K (Coef 1.0/3.0) = 0.333333343
  定点类型 delta 在第 22 章专门讨论（嵌入式/货币场景）。

--- 4. 布尔与字符 ---
  Boolean 是 (False, True) 枚举：Flag = TRUE
  Boolean'Pos (True) = 1
  Character 也是枚举：Ch = 'A'
  Character'Val (97) = 'a'

--- 5. 子类型 vs 派生类型 ---
  S := N 合法：Small_Int 与 Integer 是同一类型，S = 60
  A := Age (N) 显式转换后 A = 60
  Small_Int'Base'First =-2147483648
  Small_Int'First      =-100

--- 6. 常量与命名数字 ---
  Max_Value : constant Integer := 999  → 999
  Dozen     : constant := 12          → 12
  Max_Count : constant := Max_Value*2 → 1998
```

## 03.9 小结

| 概念 | 要点 |
|------|------|
| 类型 | 值集 + 操作集；`type T is 定义` 引入全新类型 |
| 范围检查 | 静态可判→编译期拒绝；运行期越界→`Constraint_Error` |
| 枚举属性 | `Pos/Val/Succ/Pred/First/Last/Image/Value/Range` 全套 |
| 重载直接量 | `Color'(Red)` 限定表达式消歧 |
| 实型 | `digits` 浮点（相对精度）、`delta` 定点（绝对精度） |
| `subtype` | 同类型加约束，与基类型自由互通 |
| 派生类型 | `type T is new ...`，新类型，互通须显式转换 |
| `'Base` | 剥掉约束的基类型视图 |
| 命名数字 | `constant :=` 无类型常量，通用整数/实数 |

下一章讲控制结构——if/case/循环看似与类型无关，但 Ada 的 for 循环
变量类型、case 的离散性要求，处处都在吃本章类型的红利。

---
上一章：[02 Hello World](02-hello.md) ｜ 下一章：[04 控制结构](04-control.md) ｜ 返回：[README](../README.md)
