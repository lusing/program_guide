# 13 · 泛型进阶：类属形参全种类

> 示例：[`examples/ch13_generics_deep.adb`](../examples/ch13_generics_deep.adb)
> 运行：`./run-all.sh 13`

[12 章](12-generics.md)已经会用泛型了；本章回答一个更深的问题——
**泛型的形参到底能传什么**。老教材何诚第 14 章"类属程序单元"把答案
整理成三大类：**对象、类型、子程序**，这正是 Ada 泛型威力的全部来源
（Ada 95 之后又加了第四类：包）。理解了形参分类，标准库
`Ada.Containers` 的规范读起来就不再神秘。

老术语对照：**类属（generic）**= 泛型，**类属例化（generic instantiation）**
= 实例化，**类属单元** = 泛型单元。本章混用"泛型/类属形参"二词，
它们是同一个东西。

---

## 13.1 泛型是"编译期的子程序调用"

先建立正确的心智模型。普通子程序调用：**运行期**把实参值绑定到形参，
所以参数只能是值/引用（`in`/`out`/`in out`），**类型没法当参数传**——
运行期换类型的代价不可接受。

泛型实例化：**编译期**把实参绑定到形参，生成一份专门化的代码副本。
因为发生在编译期，**类型、子程序、甚至其它泛型实例都可以当实参**。
老教材的总结一针见血：

> 类属单元自身不能执行，它是创建实例的模型；
> 所有类属例化在编译时完成。

```ada
generic
   type Discrete is (<>);
function Cyclic_Next (X : Discrete) return Discrete;

function Next_Day is new Cyclic_Next (Day);     -- 编译期生成 Day 版本
function Next_Bool is new Cyclic_Next (Boolean);-- 再生成 Boolean 版本
```

两次实例化生成**两个独立的函数**，同名是合法的（走普通重载规则）。

## 13.2 第一类：对象形参（值）

```ada
generic
   Period : Positive;                 -- 隐含 in 模式：一个编译期常量
package Ring_Counter is ...
```

对象形参的规则与子程序参数几乎一致（可用 `in` / `in out`，禁 `out`），
区别在于它是在**实例化时**求值的常量：

```ada
package Mod6 is new Ring_Counter (Period => 6);
```

老教材的环形计数器案例：`Increment` 数到 `Period` 归零。对象形参最常见
的用途就是给泛型数据结构**传容量**——标准容器 `Vectors (Capacity)` 的
容量、本章 FIFO 的 `Size` 都是它。

## 13.3 第二类：类型形参（核心）

类型形参的关键设计：**你声明形参时承诺知道哪些操作，实参就必须提供哪些操作**。
承诺越多、实参受限越多；承诺越少、泛型体内能做的也越少。谱系如下：

| 形参写法 | 接受的实参 | 泛型体内可用的操作 |
|----------|-----------|-------------------|
| `type T is private` | 几乎任何非无限定类型 | `:=`、`=`、`/=`（赋值与判等） |
| `type T is limited private` | 任何类型 | **无**（连赋值都没有） |
| `type D is (<>)` | 任何**离散**类型（枚举/整数） | `First/Last/Succ/Pred/Image`、序数属性 |
| `type I is range <>` | 任何**整数**类型 | 离散属性 + `+ - * / mod rem` |
| `type F is digits <>` | 任何浮点类型 | 算术、`Digits` 属性 |
| `type F is delta <>` | 任何定点类型 | 算术、`Small`（见 [22 章](22-fixed-point.md)） |
| `type A is array (I range <>) of T` | 匹配的数组类型 | 下标、切片、`Range` 属性 |
| `type P is access T` | 匹配的访问类型 | `new`、解引用 |

**`(<>)` 里的尖括号读作 box**，意思是"此处的界/精度留空，实例化时填"。

三个层面的推论：

1. `private` 形参体内**只能**赋值和判等——想排序？比较操作必须另外传
   （13.4 的子程序形参就是干这个的）。
2. `(<>)` 比 `range <>` 弱：它包含所有整数类型但**不含算术**
   （枚举类型没有 `+`）。要 `I + 1` 就声明 `range <>`。
3. 数组形参匹配规则：维数相同、下标/分量类型相同、约束状态一致
   （形参无约束则实参必须无约束）。`array (Index range <>) of Item`
   里的 `Index`、`Item` 通常也是前面的类型形参。

**属性在类型形参上照样用**——`Discrete'Last`、`Discrete'Succ (X)`，
老教材的循环后继函数是最佳入门：

```ada
generic
   type Discrete is (<>);
function Cyclic_Next (X : Discrete) return Discrete;

function Cyclic_Next (X : Discrete) return Discrete is
begin
   if X = Discrete'Last then
      return Discrete'First;
   else
      return Discrete'Succ (X);
   end if;
end Cyclic_Next;
```

`Next_Day (Sun)` 回到 `Mon`，`Next_Bool (True)` 回到 `False`——
一个泛型体，通吃所有离散类型。注意 `'Image` / `'Value` 在 `(<>)`
形参上**不可用**（老教材特意标注），要打印就让实参处自己转。

## 13.4 第三类：子程序形参与默认 `is <>`

`private` 类型没有 `<`，泛型排序就"卡"在比较这一步。子程序形参补上缺口：

```ada
generic
   type Item  is private;
   type Index is (<>);
   type Vector is array (Index range <>) of Item;
   with function "<" (X, Y : Item) return Boolean is <>;
procedure Generic_Sort (V : in out Vector);
```

`with function ... is <>` 这个 **box 默认值**的含义：实例化时如果现场
恰好有一个与形参同签名（这里就是可视的 `"<"`）的子程序，就自动用它，
实参可以省略：

```ada
procedure Char_Sort is new Generic_Sort
  (Item => Character, Index => Positive, Vector => String);
                                    -- 省略 "<"：用标准 Character 版 "<"

function Older (A, B : Person) return Boolean is (A.Age < B.Age);
procedure Age_Sort is new Generic_Sort
  (Item => Person, Index => Positive,
   Vector => Person_Array, "<" => Older);   -- 显式提供比较函数
```

默认值还可以写成**指名子程序**（`is Older` 那样的 `is 名字` 形式，
老教材讲的两种默认：box 默认与名字默认）。匹配要求：参数个数、顺序、
类型、模式一致；参数名**不必**相同。

这套机制是标准库的地基：`Ada.Containers.Vectors` 的 `Generic_Sort`、
`Generic_Merge` 全部以子程序形参接收比较逻辑——你传 `<` 它就是升序，
传 `>` 它就是降序，泛型体一行不改。

## 13.5 案例：任务通信的类属 FIFO（何诚 §14.5）

老教材压轴案例：容量和分量类型双参数化的环形 FIFO——
生产者-消费者任务的"中间仓库"。完整模式四件套：

```ada
generic
   Size   : Positive := 100;        -- ① 对象形参带默认值
   type Object is private;          -- ② 类型形参
package Fifo is
   type Buffer is limited private;  -- ③ limited：禁止赋值，防止绕过状态机
   procedure Store    (B : in out Buffer; X : Object);
   procedure Retrieve (B : in out Buffer; X : out Object);
   function Empty (B : Buffer) return Boolean;
   function Full  (B : Buffer) return Boolean;
   Overflow  : exception;           -- ④ 异常也是规范的一部分
   Underflow : exception;
private
   type Object_Array is array (1 .. Size) of Object;  -- 记录分量必须命名类型
   type Buffer is
      record
         Data : Object_Array;
         Inx  : Positive range 1 .. Size := 1;
         Outx : Positive range 1 .. Size := 1;
         Used : Natural  range 0 .. Size := 0;
      end record;
end Fifo;
```

实现就是环形数组：`Inx mod Size + 1` 前进，满则 `raise Overflow`。
三个值得咀嚼的设计点：

1. **`Size` 带默认值**——`new Fifo (Size => 4, Object => Character)`
   或 `new Fifo (Object => Integer)`（容量 100）都合法。
2. **`limited private`**——用户拿不到 `:=`，只能走 `Store/Retrieve`，
   缓冲区的读指针写指针永远一致。这正是 [08 章](08-discriminants.md)
   老教材 `TEXT_HANDLING` 用 `limited private` 的同一个理由。
3. **两个实例完全独立**——字符版和整数版各有自己的 `Overflow` 异常、
   自己的 `Buffer` 类型，类型系统保证不会串。

老教材接着展示的用法：把 FIFO 装进任务体，配上 `select ... when`
条件接受，就是教科书级的生产者-消费者（完整任务版见
[17 章](17-select-family.md)）。Ada 95 之后更常见的做法是
`protected` 对象 + 泛型缓冲，见 [16 章](16-protected-objects.md)。

## 13.6 第四类：包形参（Ada 95 增补）

老教材成书时还没有这一类：**实例化出来的包本身可以再当形参**——

```ada
with package Any_Fifo is new Fifo (<>);   -- 接受任何 Fifo 实例
package Stats is ...                      -- 体内可用 Any_Fifo.Buffer 等
```

`new Fifo (<>)` 里的 box 表示"实参只要是个 Fifo 实例就行，具体参数不挑"。
标准库到处用这招把"一个容器实例"传进"操作该容器的泛型"
（容器迭代器 `Generic_Keys` 系列都靠它）。本章点到为止，读懂容器
规范时再回来看。

## 13.7 常见坑

1. **`(<>)` 上做算术**：`type D is (<>)` 里写 `X + 1` 编译不过
   ——box 离散不含算术，改 `range <>`。
2. **`'Image` on `(<>)`**：不可用。需要打印就传个
   `with function Image (X : D) return String` 形参，
   或在实例化处调用 `实参类型'Image`。
3. **匿名数组做分量**：泛型包私有部分里 `Data : array (1 .. Size)
   of Object;` 编译不过——记录分量必须用命名数组类型。
4. **字面量歧义**：形参是 `private` 类型时，`for C in 'a' .. 'd'`
   无法判定字符类型（可能是 `Wide_Character`...），写
   `for C in Character range 'a' .. 'd'`。
5. **实例化位置**：泛型库单元要先 `with` 再实例化；嵌套泛型
   （体内再实例化）注意实参必须在该处可见。
6. **泛型任务不存在**：老教材明确"不允许类属任务"——要参数化的
   任务行为，用泛型**包**把任务类型装进去（任务类型可以作包内类型）。

## 13.8 小结

| 形参种类 | 关键字/形式 | 典型用途 |
|----------|------------|---------|
| 对象 | `N : Positive := 100` | 容量、精度、配置常量 |
| 类型 private | `type T is private` | 元素类型（只用赋值/判等） |
| 类型离散 | `type D is (<>)` | 遍历、序数、集合 |
| 类型整数 | `type I is range <>` | 数值算法 |
| 类型数组 | `array (I range <>) of T` | 通用数组算法 |
| 子程序 | `with function "<" is <>` | 比较器、工厂、回调 |
| 包 | `with package F is new Gen (<>)` | 组合容器实例 |

**选型口诀**：形参承诺**最少**的操作，泛型就**最通用**；
只在体内真正需要时，才收紧形参（`private` → `(<>)` → `range <>`）。

---

### 习题（改编自何诚第 14 章）

1. 把 `Generic_Sort` 的比较形参换成 `with function Key (X : Item)
   return Integer`（键函数），实现"按键排序"，并用
   `Key => 年龄` 给 `Person_Array` 排序。
2. 何诚 §14.4 的 `ARRAY_SEARCH`：泛型"在一维数组中找第一个等于
   给定值的分量"，类型形参用 `private` + 离散下标 + 数组形参实现，
   分别用 `String` 与 `Person_Array` 实例化。
3. 给 `Fifo` 加 `function Size_Used (B : Buffer) return Natural` 与
   `procedure Clear (B : in out Buffer)`，再把 `Char_Fifo` 的
   容量改成类属默认值 100 测试默认实参。
4. 泛型包 `Ring_Counter` 加一个 `with function Label (C : Natural)
   return String is <>` 形参，打印时用中文序数标签。

---
上一章：[12 泛型编程](12-generics.md) ｜ 下一章：[14 面向对象编程](14-oop.md) ｜ 返回：[README](../README.md)
