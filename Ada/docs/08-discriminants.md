# 08 · 判别类型：变体、变长与判别私有

> 示例：[`examples/ch08_discriminants.adb`](../examples/ch08_discriminants.adb)
> 运行：`./run-all.sh 08`

第 7 章的记录把"一组相关数据"打包，但每个记录的结构在编译时就完全固定。
本章讲 Ada 把记录结构**参数化**的机制——**判别式（discriminant）**：
同一个记录类型可以随判别式的值呈现不同结构，数组分量的长度也可以由判别式决定。

老教材对照：何诚《ADA 语言程序设计教程》第 10 章"判别类型"、刘炳文《程序设计语言 Ada》
第 10 章，都把判别类型作为记录之后的自然延伸。老术语"判别类型"（discriminated type）
在现代资料里更常写作"带判别式的记录"（discriminated record / record with discriminants）。

---

## 08.1 为什么需要判别式

老教材用了一个汽车制造商的例子：轿车与货车要保存的信息**部分相同**（序号、型号、
漆色）、**部分不同**（轿车有车门数，货车有载容与载重）。拆成两个类型，则
"给定序号查型号"这类公共操作要写两遍；而判别式把两者合并成一个类型：

```ada
type Vehicle_Kind is (Car, Van);

type Vehicle (Kind : Vehicle_Kind := Car) is
   record
      Serial : Positive;          -- 公共分量
      Paint  : Paint_Color;
      case Kind is                -- 变体部分
         when Car =>
            Doors    : Positive;
         when Van =>
            Capacity : Integer;   -- 立方米
            Load     : Integer;   -- 吨
      end case;
   end record;
```

判别式 `Kind` 出现在类型名后的括号里，像记录的"类型级形参"。`case Kind` 引导的
**变体部分（variant part）**语法上与 case 语句神似，但语义完全不同：它是
**编译期的结构选择**——`Kind = Car` 的对象里根本没有 `Capacity` 这个分量。

## 08.2 变体部分的三条硬规则

1. **判别式必须是离散类型**（枚举或整数），且 case 必须覆盖它的**所有值**
   （可用 `others`，只能放最后一个变体）。
2. 某个变体不需要任何分量时，必须显式写 `null;`，不能留空。
3. **跨变体的分量名不能重复**——所有变体的分量同属一个记录类型，名字必须唯一
   （本例三角形的"高"因此叫 `Altitude` 而不是与矩形重复的 `Height`）。

```ada
case Kind is
   when Car  => null;             -- 空变体必须写 null
   when Van  => Capacity, Load : Integer;
end case;
```

## 08.3 判别式约束：把判别式钉死

不写约束的对象是"无约束"的（见下节）；写约束则把判别式固定成一个具体值：

```ada
Family : Vehicle (Car);           -- 直接约束：永远只能是轿车
V      : Van_Only;                -- 通过子类型约束（见下）

subtype Van_Only is Vehicle (Kind => Van);   -- 约束可以命名成子类型
```

约束可以按位置（`Vehicle (Van)`）或按名（`Vehicle (Kind => Van)`）给出，
与子程序实参的两种写法一致。约束后的对象：

- 变体随之固定，**访问其它变体的分量会在运行期抛 `Constraint_Error`**；
- 判别式**永远不能再变**——编译器按这个变体的大小精确分配存储。

## 08.4 默认判别式与无约束对象

类型定义里 `Kind : Vehicle_Kind := Car` 这个 `:= Car` 是**判别式默认值**。
有了它，才能声明**无约束对象**：

```ada
M : Vehicle;          -- 合法：Kind 取默认值 Car
```

无约束对象遵循老教材总结的规则（何诚 §10.4，至今未变）：

| 规则 | 内容 |
|------|------|
| 单独赋值禁止 | `M.Kind := Van;` **编译不过**——会让结构与数据不一致 |
| 整体赋值可变 | `M := (Kind => Van, ...);` 合法，整个记录连同结构一起换 |
| 受约束永不变 | `Vehicle (Car)` 的对象终身是 Car，整体赋值也只能赋 Car 值 |
| 嵌套依赖 | 内层判别记录的判别式，只能用**外层判别式单独**约束（见 08.7） |
| 默认值缺省 | 判别式没有默认值时，每个对象说明都必须带约束 |

```ada
M : Vehicle := (Kind => Car, Serial => 2001, Paint => Black, Doors => 2);
...
M := (Kind     => Van,        -- 变体切换：只能整条记录赋值
      Serial   => M.Serial,   -- 公共分量手工保留
      Paint    => M.Paint,
      Capacity => 12,
      Load     => 2);
```

## 08.5 `'Constrained`：问一个对象"你定形了吗"

每个判别类型的对象都有布尔属性 `'Constrained`：

```ada
Family'Constrained   -- TRUE ：带约束说明
M'Constrained        -- FALSE：无约束（默认判别式）
```

写库代码时（比如要决定能否给形参整体赋值）经常需要它。对无约束的
**形式参数**还有一条重要规则：`in` 参数按实参是否受约束决定，而 `in out` /
`out` 参数若无约束说明，**调用时取实参的约束状态**——库代码里用
`Param'Constrained` 探测是标准手法。

## 08.6 变长数组分量

判别式的第二个用途：给记录里的**数组分量定界**。老教材的 `TEXT` 类型
（变长正文）是经典案例，也是后来标准库 `Ada.Strings.Bounded` 的雏形：

```ada
subtype Length_Range is Integer range 0 .. 40;

type Text (Max_Len : Length_Range := 20) is
   record
      Len  : Length_Range := 0;
      Data : String (1 .. Max_Len);    -- 界由判别式给出
   end record;

T1 : Text (10);                        -- 容量 10，受约束
T2 : Text;                             -- 无约束：容量取默认 20
```

**三条配套规则**：

1. **判别式必须"单独出现"**：`String (1 .. Max_Len)` 合法；
   `String (1 .. Max_Len + 1)` **非法**——判别式不能出现在表达式里。
2. **definite / indefinite**：判别式**有**默认值的类型是 definite 的，
   可以做数组元素、记录分量；**没有**默认值则是 indefinite 的，
   `array (1 .. 3) of Shape` 这样的说明直接编译报错
   （示例里 `Shape` 因此写了 `:= Circle_S` 默认值）。
3. **存储真相**：无约束对象的变长数组**总是按判别式类型的最大值分配**——
   `T2 : Text` 实际占 40 个字符的空间，与 `Max_Len` 当前值无关
   （否则切换判别式时存储就不够了）。老教材由此给出的忠告依然成立：
   *如果只是想要"定长数组 + 一个长度字段"，用普通记录更直接；
   判别式的真正价值在于与私有类型结合（08.9）与作为形参传递。*

## 08.7 嵌套判别：内层依赖外层

判别记录的分量本身又是判别记录时，**内层的判别式只能用外层判别式单独约束**：

```ada
type Payload (Size : Size_Range) is
   record
      Bytes : String (1 .. Size);
   end record;

type Packet (Kind : Packet_Kind; Size : Size_Range) is
   record
      Seq : Natural;
      case Kind is
         when Ctrl   => Code : Natural;
         when Data_P => Data : Payload (Size);   -- 合法：Size 是外层判别式
      end case;
   end record;
```

写 `Payload (Size - 1)` 或让内层依赖某个普通分量 `P.Size` 都不合法——
那会让"结构依赖数据"，编译器无法保证判别式与结构一致。代价是 `Size`
作为判别式必须出现在**所有**变体里（即使 Ctrl 用不到），
这是为安全付出的冗余。

## 08.8 运行期保护：访问不存在的分量

访问当前变体之外的分量是**运行期检查**（不是编译期）：

```ada
M : Vehicle := (Kind => Van, Serial => 3001, Paint => Red,
                Capacity => 8, Load => 3);
...
Put_Line (Positive'Image (M.Doors));   -- 编译通过，运行抛 Constraint_Error
```

示例第 3 节演示了捕获这个错误。同样，把容量 30 的 `Text` 整体赋给
容量 10 的 `T1` 也会抛 `Constraint_Error`（30 个字符装不进 10 个）。
这些检查默认开启（`-gnato` 行为），是"把错误消灭在离成因最近处"的又一例。

## 08.9 案例：几何图形面积（变体记录 + case 分发）

张丽芬《Ada 程序设计导论》用变体记录统一处理多种几何图形。现代写法：

```ada
type Shape_Kind is (Circle_S, Rectangle_S, Triangle_S);

type Shape (Kind : Shape_Kind := Circle_S) is
   record
      case Kind is
         when Circle_S    => Radius              : Float;
         when Rectangle_S => Width, Height       : Float;
         when Triangle_S  => Base, Altitude      : Float;
      end case;
   end record;

function Area (S : Shape) return Float is
begin
   case S.Kind is
      when Circle_S    => return 3.14159_26535_89793 * S.Radius ** 2;
      when Rectangle_S => return S.Width * S.Height;
      when Triangle_S  => return 0.5 * S.Base * S.Altitude;
   end case;
end Area;
```

实跑输出（`./run-all.sh 08`）：

```text
--- 6. 案例：变体记录几何面积 ---
  圆     r=2.0  面积=12.57
  矩形   w=3.0 h=4.0  面积=12.00
  三角形 b=6.0 h=5.0  面积=15.00
```

这套写法的杀手锏是**完备性保护**：给 `Shape_Kind` 增加新字面量（比如
`Square_S`）的瞬间，`Area` 里的 case 因为不再覆盖所有值而**编译失败**，
编译器会把你可能漏掉的每一处分发点都揪出来。与 OOP 的动态分发
（[14 章](14-oop.md)，加子类不影响既有代码，但也没有"强制补分支"的检查）
是两种互补的策略：

| 维度 | 变体记录 + case | tagged 类型 + 动态分发 |
|------|----------------|----------------------|
| 加一个新形状 | 改类型定义 + 编译器揪出所有分发点 | 新增派生类型，旧代码不动 |
| 加一个新操作 | 新函数，旧代码不动 | 要动每个类型的声明（或用类级过程） |
| 存储 | 单一类型、变体共享空间 | 每个对象带标签、通常经访问类型引用 |
| 检查时机 | case 完备性编译期保证 | 分发运行期查表 |

经验法则：**封闭集合 + 频繁加操作 → 变体记录；开放集合 + 稳定操作集 → tagged**。

## 08.10 判别私有类型（预告）

何诚 §10.5 的正文处理程序包 `TEXT_HANDLING` 是判别式的点睛应用：包规范里
声明 `type Text (Max_Len : Length_Range) is limited private;`——用户看得见
判别式（能声明 `T : Text (80)`），看不见内部结构。标准库的
`Ada.Strings.Bounded.Generic_Bounded_Length`、`Ada.Containers` 里的
`Vector (Capacity)` 都是这一模式。变量数组的判别式主要就是为此服务的：
用户拿到的是"按需定容、类型系统保证容量足够"的对象。完整案例见
[10 章](10-packages.md) 与 [13 章](13-generics-deep.md) 的泛型有界缓冲。

## 08.11 常见坑

1. **判别式单独赋值**：`M.Kind := Van;` —— 编译错误。必须整体赋值。
2. **跨变体重名**：不同变体里同名分量（即便类型相同）—— 编译错误
   （Ada 2022 起允许跨变体同名同类型分量，GNAT 16 需 `-gnat2022` 开启；
   教程示例保持默认标准，主动改名避开）。
3. **indefinite 数组元素**：判别式无默认值的类型做数组元素 / 记录分量 ——
   编译错误。要么给判别式默认值，要么在元素位置写约束。
4. **判别式进表达式**：`String (1 .. N + 1)` 用判别式 N —— 编译错误。
   需要偏移就加一个辅助判别式，或改普通分量。
5. **误以为变长数组省内存**：无约束对象按判别式类型的**最大值**分配。
   想真省内存，用受约束子类型分桶，或等 [09 章](09-access-types.md) 的动态分配。
6. **`out`/`in out` 形参的约束**：无约束形参被实参"传染"约束状态，
   函数体里整体赋值换变体前先看 `Param'Constrained`。

## 08.12 小结

| 概念 | 语法 | 一句话 |
|------|------|--------|
| 判别式 | `(Kind : T := 默认)` | 记录的类型级形参 |
| 变体部分 | `case Kind is ... end case;` | 结构随判别式选择，编译期定形 |
| 判别式约束 | `Vehicle (Van)` / 子类型 | 钉死判别式，永不再变 |
| 默认判别式 | `:= Car` | 允许无约束对象；类型变 definite |
| `'Constrained` | `X'Constrained` | 运行期问对象是否受约束 |
| 变长数组 | `String (1 .. Max_Len)` | 界由判别式单独给出 |
| 嵌套判别 | `Payload (Size)` | 内层判别式 = 外层判别式 |

下一章把"结构参数化"推向数据本身的大小：**访问类型**与堆上的动态数据结构。

---

### 习题（改编自何诚第 10 章习题）

1. 定义一个可变记录 `Point`，按判别式要么存一对直角坐标
   `(X, Y)`，要么存一对极坐标 `(R, Theta)`；再写函数
   `To_Cartesian (P : Point) return Point` 完成极坐标到直角坐标的
   整记录转换（提示：只能整体赋值）。
2. 政府人员记录：每人有姓名、性别、出生日期；本国侨民记录出生地；
   外国人记录国籍与入境日期；外国人中的临时居民还要记录工作许可证
   （是否颁发、编号、有效期）。设计嵌套变体记录并给出对象说明。
3. 在 08.9 的 `Shape` 上增加 `Square_S`（只存边长），体会 case 完备性
   如何逼你补全 `Area` 与 `Put_Area`。

---
上一章：[07 记录类型](07-records.md) ｜ 下一章：[09 访问类型](09-access-types.md) ｜ 返回：[README](../README.md)
