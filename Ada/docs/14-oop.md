# 14 · 面向对象编程：tagged 类型与动态分发

> 示例：[`examples/ch14_oop.adb`](../examples/ch14_oop.adb)
> 运行：`./run-all.sh 14`

Ada 83 没有"面向对象"这个说法，但它有变体记录（第 07、08 章）——
"一种类型、多种形态"的雏形。Ada 95 补上了正式的 OOP 三件套：
**继承**（tagged 记录的扩展）、**多态**（类范围类型 `'Class`）、
**动态分发**（按 tag 选实现），Ada 2012 又加入 `overriding` 标注
的强制化。本章用图形家族（Shape/Circle/Rectangle）把这套机制讲全：
抽象基类、扩展聚集、类范围参数、异构容器，以及 Ada 特有的
"语言级防护"。与第 07 章变体记录的关系本章末尾对照——那是老
教材时代与现在解决同一问题的两条路。

---

## 14.1 tagged 类型：可扩展的记录

普通 `record` 一旦定义就不能"加字段"；**tagged record** 可以：

```ada
type Shape is abstract tagged record
   Name : String (1 .. 12) := (others => ' ');
end record;
```

`tagged` 的字面含义：对象自带一个**运行期标签（tag）**——类型
身份标记。有了 tag，才能在运行期回答"这个对象到底是哪个类型"、
从而实现动态分发。

`abstract` 让 `Shape` 成为**抽象类型**：只许被继承、不许直接
说明对象（`S : Shape;` 编译错——形状的"纯粹共性"不该独立存在）。
抽象类型必须配至少一个抽象操作：

```ada
function Area (S : Shape) return Float is abstract;  -- 无体，必须被覆盖
procedure Print (S : Shape'Class);   -- 类范围参数：体内可分发调用 Area
```

`is abstract` 的函数**没有体**——它是"派生类的作业"。谁派生谁
交卷，不交编译不过。

**关键规则（本章示例的第一课）**：分发操作（原语操作）必须与
tagged 类型声明在**同一个包规范**里。所以示例把整个图形家族装在
嵌套包 `Shapes` 中：

```ada
package Shapes is
   type Shape is abstract tagged record ... end record;
   function Area (S : Shape) return Float is abstract;
   procedure Print (S : Shape'Class);
   type Circle is new Shape with ... end record;
   ...
end Shapes;
```

直接在过程体里声明 tagged 类型也能编译（带警告），但它的子程序
**不构成分发操作**——`Print (S : Shape'Class)` 会报
"class-wide argument not allowed here"。本示例开发时踩的就是
这个坑：把家族挪进嵌套包，分发立刻就通了。

## 14.2 派生与扩展：`is new ... with`

派生 = 继承全部分量与操作 + 追加新分量：

```ada
type Circle is new Shape with
   record
      Radius : Float;
   end record;

overriding                          -- 覆盖检查：签名错即编译错
function Area (C : Circle) return Float is
  (Ada.Numerics.Pi * C.Radius * C.Radius);

type Rectangle is new Shape with
   record
      Width, Height : Float;
   end record;

overriding
function Area (R : Rectangle) return Float is (R.Width * R.Height);
```

- `is new Shape with record ... end record`：Circle = Shape 的全部
  （Name）+ Radius。
- **`overriding` 标注**：声明"我要覆盖父类的 Area"。写上之后，
  签名不匹配（拼错函数名、参数类型不对）直接编译错；不写的话，
  想覆盖却写歪了会被静默当成**新**函数——运行期才发现"怎么分发
  到父类去了"。C++ 的虚函数覆盖写错签名只是"隐藏"，Ada 用
  `overriding` 把这类事故拦在编译期。
- 函数体用了**表达式函数**（Ada 2012）：`is (表达式)` 一行完事。

对象的构造用**扩展聚集（extension aggregate）**——祖先分量 +
新增分量一次写全：

```ada
C : Circle := (Name   => "圆",
               Radius => 5.0);
R : Rectangle := (Name   => "矩形",
                  Width  => 3.0,
                  Height => 4.0);
```

（示例里 Name 的实参是补齐函数 `Nm ("圆")`——把任意长字符串
右侧补空格到 12 字符，免得手工数字符数。定长字符串分量的常规
配套。）

## 14.3 类范围类型：Shape'Class

`Shape` 是**特定类型**（specific type）——只指 Shape 自己；
`Shape'Class` 是**类范围类型（class-wide type）**——Shape 与它
的**全部派生**的并集：

```ada
procedure Report (S : Shape'Class) is
begin
   Put ("  [类范围参数] ");
   Print (S);                    -- 运行期按 S 的实际 tag 分发
end Report;

C : Circle     := (Name => "小圆", Radius => 1.0);
R : Rectangle  := (Name => "长方形", Width => 6.0, Height => 2.0);
...
Report (C);     -- 打印 小圆 面积 3.14（Circle.Area）
Report (R);     -- 打印 长方形 面积 12.00（Rectangle.Area）
```

三条理解：

1. `Shape'Class` 像"家族通行证"：任何成员都能传，家族新增成员
   （比如明天加个 Triangle）**老代码自动兼容**——这就是开闭原则
   的语言级实现。
2. 类范围类型的值**自带 tag**——`Print (S)` 里的分发调用，运行期
   查 S 的 tag 选 `Area` 的实现。
3. **特定类型是编译期确定的**：`Print (C)` 里 C 是 Circle（特定），
   调用静态绑定到 `Circle.Area`；`Print (S)` 里 S 是 `Shape'Class`
   （带 tag），才动态分发。同一个 `Area` 名字，两种绑定。

`Print` 自己的形参就是 `Shape'Class`（见 14.1 的声明）——这样它
体内对 `Area (S)` 的调用才是分发性的。若形参写成特定类型
`Shape`，体内调用抽象函数 `Area` 会直接编译错（"call to abstract
function must be dispatching"——本示例的第二个真实坑）。

## 14.4 异构容器：全家族一屋

类范围类型的访问值（指针，第 09 章）可以指向家族任何成员——
于是数组能装下"圆+矩形"的混合：

```ada
type Shape_Access is access all Shape'Class;

type Shape_List is array (1 .. 4) of Shape_Access;
List : constant Shape_List :=
  (new Circle'(Name => "圆A", Radius => 2.0),
   new Rectangle'(Name => "矩形A", Width => 1.5, Height => 3.0),
   new Circle'(Name => "圆B", Radius => 10.0),
   new Rectangle'(Name => "矩形B", Width => 5.0, Height => 5.0));

Total : Float := 0.0;
...
for K in List'Range loop
   Print (List (K).all);         -- .all 解引用后分发
   Total := Total + Area (List (K).all);
end loop;
```

输出：

```text
  圆A          面积 = 12.57
  矩形A       面积 =  4.50
  圆B          面积 = 314.16
  矩形B       面积 = 25.00
  四个图形总面积 = 356.23
```

四个要点：

- `new Circle'(...)` 在堆上造对象、返回 `Shape'Class` 的访问值
  ——注意 `Circle'(...)` 前的**限定**：单写 `(Name => ..., Radius
  => ...)` 编译器无法从 `new` 的上下文确定类型（它只知道要的是
  Shape'Class 的某个成员）。
- 数组元素的**静态类型**是 `Shape_Access`，**所指对象的实际
  类型**各不相同——异构性由此而来。
- `List (K).all` 解引用得到 `Shape'Class` 视图，之后的 `Print`/
  `Area` 都是分发调用。
- `Total := Total + Area (...)` 里的 `Area` 也在循环里分发——
  "同一个调用点、四种行为"贯穿全循环。

这是 OOP 的招牌场景：图形编辑器、GUI 控件树、游戏实体表——
"一堆行为各异的东西，用统一接口遍历"。

## 14.5 与变体记录对照：两代方案

第 07 章的变体记录解决过同一个问题：

```ada
type Shape (Kind : Shape_Kind) is record
   case Kind is
      when Circle    => Radius : Float;
      when Rectangle => Width, Height : Float;
   end case;
end record;
```

| 维度 | 变体记录 | tagged + 分发 |
|------|----------|---------------|
| 形态集合 | 写类型时**封闭**（case 列全） | **开放**（随时派生新类型） |
| 新增形态 | 改类型定义 + 重编所有客户 | 加一个派生类型即可 |
| 行为分支 | `case Kind is` 散落各处 | 各类型自带 Area，集中一处 |
| 内存 | 单对象，无堆 | 异构容器需访问类型（堆） |
| 出身 | Ada 83 就有（老教材 §4.6） | Ada 95 引入 |

经验法则：**形态封闭、数据为主**（协议帧、固定指令集）用变体
记录——编译期完备检查；**形态开放、行为为主**（插件、图形对象）
用 tagged——开放扩展。两代方案都在你的工具箱里，按问题选。

老教材的"用变体记录计算几何图形面积"例（§4.7）与本章的 tagged
版恰好构成一组对照——同一道题，1992 年的解法与今天的解法。

## 14.6 语言级防护清单

本章示例的第四节专门列了四条防护，这里展开成表：

| 防护 | 编译错时机 | 替代方案（其他语言）的后果 |
|------|-----------|---------------------------|
| `abstract` 类型 | 直接说明抽象对象 | C++ 同样有纯虚类；但忘了 `=0` 就是普通类 |
| `is abstract` 操作 | 派生类未覆盖 | C++ 链接期才报 missing vtable |
| `overriding` 标注 | 签名不匹配 | C++/Java 静默隐藏，运行期行为错乱 |
| 原语须在包规范 | 过程体内声明不构成分发 | ——（Ada 特有约束） |

这些检查的共同主题：**把 OOP 的常见事故从运行期拖到编译期**。
SPARK（第 25 章）在这之上再加数学证明。

## 14.7 本章示例的完整输出

```text
=== Ada 面向对象编程 ===

--- 1. 对象与扩展聚集 ---
  圆           面积 = 78.54
  矩形        面积 = 12.00
  扩展聚集 = 祖先分量(名) + 派生分量(半径/宽高)。

--- 2. 类范围与动态分发 ---
  [类范围参数]   小圆        面积 =  3.14
  [类范围参数]   长方形     面积 = 12.00
  同一个 Print 调用点，两种行为——这就是动态分发。

--- 3. 异构容器 ---
  圆A          面积 = 12.57
  矩形A       面积 =  4.50
  圆B          面积 = 314.16
  矩形B       面积 = 25.00
  四个图形总面积 = 356.23
  数组元素是 Shape'Class 的访问值：圆和矩形同住一屋。

--- 4. 语言级防护 ---
  Shape 是 abstract：直接说明 Shape 对象会编译错；
  Area 是 abstract 函数：派生类不覆盖它就编译错；
  overriding 标注：拼错函数名/签名不匹配会编译错；
  分发操作必须与 tagged 类型同在包规范中——
  这就是本示例把图形家族装进嵌套包 Shapes 的原因。
```

## 14.8 小结

| 概念 | 要点 |
|------|------|
| tagged | 自带运行期 tag 的记录；可被扩展 |
| abstract | 抽象类型不可实例化；抽象操作必须被覆盖 |
| `is new ... with` | 派生：继承 + 扩展分量 |
| 扩展聚集 | 祖先分量 + 新增分量一次写全 |
| `overriding` | 覆盖声明；签名错编译期拦截 |
| `'Class` | 类范围类型：家族并集；值带 tag |
| 动态分发 | 类范围实参上调用原语 → 运行期按 tag 选实现 |
| 异构容器 | `access Shape'Class` 数组：全家族一屋 |
| 原语在包规范 | 分发操作的硬性前提（本示例实测坑） |
| 与变体记录 | 封闭 vs 开放；数据为主 vs 行为主 |

单线程的世界到此已经完整。接下来进入 Ada 的招牌领域——并发：
任务与会合（第 15 章）、受保护对象（第 16 章）、select 家族
（第 17 章）。

---
上一章：[13 泛型进阶](13-generics-deep.md) ｜ 下一章：[15 Tasking](15-tasking.md) ｜ 返回：[README](../README.md)
