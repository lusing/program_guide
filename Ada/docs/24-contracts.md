# 24 · 契约式编程（Ada 2012）

> 示例：[`examples/ch24_contracts.adb`](../examples/ch24_contracts.adb)
> 运行：`./run-all.sh 17`（需 `-gnata`，脚本已内置）

> **本章是 Ada 2012 最具革命性的特性。**  
> Ada 2012 把"契约式编程"（Contract-Based Programming）提升为**语言一等公民**——开发者可以在源码中直接声明前置条件、后置条件、类型不变式和循环不变式，编译器和运行时共同保证它们的成立。这是 Ada 优于绝大多数主流语言的核心能力之一，也是通往形式化验证（SPARK）的桥梁。

## 24.1 什么是契约式编程

**契约式编程**（Design by Contract, DbC）由 Bertrand Meyer 于 1986 年在 Eiffel 语言中首次提出，其核心思想借鉴自商业合同：

- **前置条件（Precondition）** — 调用方对被调用方做出的承诺："我会给你合法的输入"。
- **后置条件（Postcondition）** — 被调用方对调用方做出的承诺："只要你给我合法的输入，我保证返回这样的输出"。
- **不变式（Invariant）** — 在对象整个生命周期中，永远成立的属性。

**与"防御式编程"（Defensive Programming）的区别：**

| 思想 | 防御式编程 | 契约式编程 |
|------|------------|------------|
| **错误责任** | 调用方与被调用方都做检查 | 明确划分责任 |
| **运行成本** | 多处重复检查，始终生效 | 单点检查，可关闭 |
| **失败处理** | 静默返回默认值 | 抛出异常，快速失败 |
| **可证明性** | 无法数学验证 | 可被 SPARK 形式化证明 |
| **文档价值** | 检查逻辑藏在实现里 | 契约出现在接口里 |

**Ada 2012 提供的六类契约：**

| 契约 | 应用对象 | 关键字/Aspect |
|------|----------|--------------|
| 前置条件 | 子程序 | `Pre` |
| 后置条件 | 子程序 | `Post` |
| 类型不变式 | 私有类型 | `Type_Invariant` |
| 动态谓词 | 子类型/记录 | `Dynamic_Predicate` |
| 静态谓词 | 子类型 | `Static_Predicate` |
| 循环不变式 | 循环 | `pragma Loop_Invariant` |

此外还有一组**断言 pragma**：`Assert`、`Assert_And_Cut`、`Assume`、`Assert_Exception`。

---

## 24.2 前置条件 Pre

`Pre` 声明调用子程序前必须成立的条件。条件在子程序入口处求值，若为 `False`，则抛出 `Assertion_Error`。

**语法：**

```ada
procedure Some_Proc (X : Integer)
  with Pre => X > 0;
```

**示例 — 安全除法：**

```ada
function Safe_Divide (X, Y : Integer) return Integer is
  (X / Y)
with
  Pre  => Y /= 0,                                  --  除数不能为零
  Post => Safe_Divide'Result * Y = X;              --  商 * 除数 = 被除数
```

调用 `Safe_Divide (10, 0)` 时，`Pre` 不成立，运行时立即抛出：

```
failed precondition from ch24_contracts.adb:27
```

**关键要点：**

- `Pre` 中可以引用子程序的**所有参数**（包括 `out`、`in out`），但不能引用子程序内声明的局部变量。
- 多个条件可以用 `and then` / `or else` 组合。
- 子程序被重写（override）时，派生类的 `Pre` 可以**弱化**父类的 `Pre`（行为子类型 Liskov 原则）。

---

## 24.3 后置条件 Post 与 'Result、'Old

`Post` 声明子程序返回时必须成立的条件。它支持两个特殊前缀属性：

| 属性 | 含义 | 示例 |
|------|------|------|
| `'Result` | 函数的返回值（仅函数） | `Safe_Divide'Result * Y = X` |
| `'Old` | 参数在子程序**入口时**的值（仅 `in out`/`out`） | `N = N'Old + 1` |

**示例 — Increment：**

```ada
procedure Increment (N : in out Integer)
  with Post => N = N'Old + 1
is
begin
   N := N + 1;
end Increment;
```

调用：

```ada
declare
   N : Integer := 41;
begin
   Increment (N);   --  Post 自动验证：41 + 1 = 42
   -- N 现在为 42
end;
```

**关键要点：**

- `'Old` 仅对**标量、记录、数组**有效；对 `access`（指针）类型，`'Old` 仍然指向原对象。
- `Post` 在子程序**每次返回**时求值——无论是通过 `return`、走到末尾，还是通过异常传播。
- 派生类的 `Post` 可以**强化**父类的 `Post`（与 `Pre` 相反）。

---

## 24.4 类型不变式 Type_Invariant

`Type_Invariant` 用于**私有类型**（`private` 或 `task`/`protected`）：每当类型实例"穿越包的可见性边界"时（即返回给外部、被外部访问），运行时自动验证不变式是否成立。

**示例 — 永远非负的计数器：**

```ada
package Safe_Counter is
   type Counter is private
     with Type_Invariant => Is_Valid (Counter);   --  类型不变式

   function  Is_Valid (C : Counter) return Boolean;
   procedure Init   (C : out Counter);
   procedure Bump   (C : in out Counter);
   procedure Reset  (C : in out Counter);
   function  Get    (C : Counter) return Integer;
private
   type Counter is record
      Value : Integer := 0;
   end record;
end Safe_Counter;
```

**关键要点：**

- `Type_Invariant` 只能用于**私有类型**（partial view），不能直接用于 record。
- 因为在外部不可见 `Counter.Value` 字段，所以不变式必须通过**外部可见的函数**（如 `Is_Valid`）实现。
- 检查时机：在 `procedure`/`function` 返回 `Counter` 类型的值时自动检查。
- 如果不变式违反，抛出 `Assertion_Error`。

---

## 24.5 动态谓词 Dynamic_Predicate

如果希望对**非私有类型**（如普通 record、subtype）施加约束，使用 `Dynamic_Predicate`。

**示例 — 只能取偶数的子类型：**

```ada
subtype Even_Integer is Integer
  with Dynamic_Predicate => Even_Integer mod 2 = 0;
```

赋值：

```ada
declare
   Bad : Even_Integer := 7;   --  奇数，违反谓词
begin
   ...
exception
   when Assertion_Error =>
      Put_Line ("Dynamic_Predicate failed!");
end;
```

**示例 — 不溢出的栈（记录类型）：**

```ada
Capacity : constant := 5;
type Stack_Array is array (1 .. Capacity) of Integer;

type Stack is record
   Data : Stack_Array;
   Top  : Natural := 0;
end record
  with Dynamic_Predicate => Stack.Top <= Capacity;
```

**关键要点：**

- `Dynamic_Predicate` 在每次对变量赋值后求值。
- 与 `subtype S is Integer range 1 .. 10` 的区别：**range 仅做范围检查**；谓词可表达任意布尔表达式（如"必须为素数"、"必须为偶数"、"必须非空"）。
- `Static_Predicate` 仅接受**编译期可求值**的条件（如枚举子集），开销更低。
- 谓词失败抛出 `Assertion_Error`，并给出文件名和行号。

---

## 24.6 循环不变式 Loop_Invariant 与 Loop_Variant

循环不变式用于证明循环的正确性——它必须在**循环入口**和**每次迭代后**都成立。

**示例 — 求数组元素之和：**

```ada
function Sum (A : Int_Array) return Integer is
   Result : Integer := 0;
begin
   for I in A'Range loop
      Result := Result + A (I);

      pragma Loop_Invariant (Result >= 0);   --  循环不变式
      pragma Loop_Variant   (Increases => I); --  循环变体
   end loop;

   pragma Assert (Result >= 0);   --  循环出口断言
   return Result;
end Sum;
```

**两类循环 pragma：**

| pragma | 含义 | 常用方向 |
|--------|------|----------|
| `Loop_Invariant` | 每次迭代后必须成立的布尔表达式 | 任意 |
| `Loop_Variant`   | 每次迭代必须**单调变化**的表达式，用于证明循环必然终止 | `Increases =>` / `Decreases =>` |

**关键要点：**

- `Loop_Invariant` 在循环**第一次执行到 pragma 行**、以及**每次后续迭代结束时**求值。
- `Loop_Variant` 用于证明循环**不会无限运行**——SPARK 工具会用它做终止性证明。
- 配合 `for` 循环时，循环变量 `I` 自动被视为 `Loop_Variant` 的候选。

---

## 24.7 表达式函数 Expression Functions

Ada 2012 引入了一种极简的函数语法——**表达式函数**（Expression Function）。它没有 `begin/end`，函数体只是一个括号包裹的表达式：

```ada
function Safe_Divide (X, Y : Integer) return Integer is
  (X / Y);
```

**与契约的天然搭配：**

```ada
function Is_Even (N : Integer) return Boolean is
  (N mod 2 = 0)
with Pre => N >= 0;
```

**关键要点：**

- 表达式函数可以放在**包的规格说明**（.ads）中——此时编译器把它视为"承诺"，SPARK 可以直接证明，无需查看实现。
- 表达式函数在包体内可以用作**契约的辅助函数**，例如 `Type_Invariant => Is_Valid (Counter)` 中调用的 `Is_Valid` 可以是表达式函数。
- 复杂逻辑仍然建议使用普通 `function ... is ... begin ... end`。

---

## 24.8 pragma Assert / Assert_And_Cut / Assume

这组 pragma 用于在代码中**任意位置**插入断言：

| pragma | 语义 | SPARK 的处理 |
|--------|------|--------------|
| `Assert (C)` | 此处 C 必须为真；否则抛出 `Assertion_Error` | **证明** C 成立 |
| `Assert_And_Cut (C)` | 同 Assert，但作为**证明的边界**——后续证明假设 C 成立，不回溯 | 切断证明路径 |
| `Assume (C)` | 不检查，仅告诉验证器"你可以假设 C 成立" | 仅做假设，不验证 |

**示例：**

```ada
pragma Assert (Result >= 0);           --  此处必须成立
pragma Assert_And_Cut (Sorted (A));    --  从此处起，认为 A 已排序
pragma Assume (External_Data_Valid);   --  信任外部数据
```

**典型使用场景：**

- `Assert` — 调试阶段的"运行期 assert"，与 C 的 `assert()` 类似，但可被 SPARK 升级为证明。
- `Assert_And_Cut` — 用于打破循环依赖：证明到这里"切断"，避免组合爆炸。
- `Assume` — 用于包装不可证明的外部调用（如 C 函数）。

---

## 24.9 契约违反与异常处理

所有契约（`Pre`/`Post`/`Type_Invariant`/`Dynamic_Predicate`/`Assert`）违反时，都会抛出**预定义异常**：

```ada
Ada.Assertions.Assertion_Error : exception;
```

可用普通的 `exception` 块捕获：

```ada
begin
   V := Safe_Divide (10, 0);
exception
   when E : Assertion_Error =>
      Put_Line ("违反 Pre: " & Exception_Message (E));
      --  输出：failed precondition from ch24_contracts.adb:27
end;
```

**异常消息约定（GNAT 实现）：**

| 契约类型 | 异常消息格式 |
|----------|---------------|
| `Pre` / `Post` | `failed precondition from file.adb:LINE` 或 `failed postcondition from file.adb:LINE` |
| `Type_Invariant` | `failed invariant from file.adb:LINE` |
| `Dynamic_Predicate` | `Dynamic_Predicate failed at file.adb:LINE` |
| `Assert` | `failed assertion from file.adb:LINE` |

**关键要点：**

- 异常消息**包含源文件路径和行号**，定位 bug 极快。
- 默认情况下契约违反是**致命错误**（如果未捕获，程序终止）。
- 契约违反**不应**作为正常的控制流手段——它代表逻辑 bug，而非预期情况。

---

## 24.10 GNAT 编译选项

契约的启用/关闭由编译选项控制：

```bash
# 启用所有断言（Pre/Post/Predicate/Assert/Invariant）
gnatmake -gnata source.adb

# 关闭所有断言（默认即如此，仅 Pre/Post 仍会检查）
gnatmake source.adb

# 启用断言 + 调试 + 全部警告
gnatmake -gnata -g -gnatwa source.adb

# 仅做语法检查（不生成可执行文件）
gnatmake -gnatc -gnata source.adb
```

**关键编译开关表：**

| 开关 | 含义 |
|------|------|
| `-gnata` | 启用所有断言语句（pragma Assert / Pre / Post / Predicate 等） |
| `-gnatA` | 关闭所有断言 |
| `-gnato??` | 数值溢出检查模式（`/`, `=`, `%` 等） |
| `-gnatE` | 启用运行时检查（默认开启；仅关闭时需配合 `-gnatp`） |
| `-gnatp` | 抑制所有运行时检查（不推荐） |

**生产部署策略：**

- **调试阶段**：`-gnata -g -gnatwa`，捕获所有契约违反。
- **测试阶段**：`-gnata -O2`，开启优化但保留断言。
- **生产阶段（高安全系统）**：保留 `-gnata`——契约检查的开销通常 < 5%，但能在错误扩散前立即发现。
- **性能极致**：关闭 `-gnata`（仅保留 `Pre` / `Post`，因为 GNAT 默认仍会生成这两个检查）。

---

## 24.11 完整示例说明

完整代码见 [examples/ch24_contracts.adb](../examples/ch24_contracts.adb)，演示以下场景：

1. **Safe_Divide** — 带 `Pre` 与 `Post` 的表达式函数，验证数学关系。
2. **Increment** — 带 `Post` 与 `'Old` 的过程，验证状态变化。
3. **Even_Integer** — 带 `Dynamic_Predicate` 的子类型。
4. **Safe_Counter.Counter** — 带 `Type_Invariant` 的私有类型。
5. **Stack** — 带 `Dynamic_Predicate` 的记录，配合 `Push`/`Pop` 的 `Pre`/`Post`。
6. **Sum** — 带 `Loop_Invariant` / `Loop_Variant` / `Assert` 的函数。
7. **故意违反契约** — 三种违反场景被 `Assertion_Error` 捕获。

**编译与运行：**

```powershell
# Windows
$env:PATH = "G:\scoop\apps\msys2\current\ucrt64\bin;" + $env:PATH
gnatmake -gnata -o examples\ch24_contracts.exe examples\ch24_contracts.adb
.\examples\ch24_contracts.exe
```

```bash
# Linux / macOS
gnatmake -gnata -o ch24_contracts examples/ch24_contracts.adb
./ch24_contracts
```

**典型输出：**

```
==============================================
  Ada 2012 契约式编程 示例 (GNAT 16.1.0)
==============================================
[1] Safe_Divide (100, 5) =  20
    Post 条件：5 * Result = 100 (已自动验证)
[2] Increment 后 N =  42  (Post: N = N'Old + 1)
[3] Even_Integer E =  10
    赋值 20 后 E =  20
[4] Counter 值 =  2  (Type_Invariant: Value >= 0)
[5] 栈 Pop 结果 =  200  (Pre/Post: Top +/-1)
[6] 数组和 Sum =  150  (Loop_Invariant/Variant 通过)

[7] 故意违反契约，演示异常捕获：
    7a. 违反 Pre (Y /= 0) 被捕获: failed precondition from ch24_contracts.adb:27
    7b. 违反 Dynamic_Predicate 被捕获: Dynamic_Predicate failed at ch24_contracts.adb:218
    7c. 违反 Pre (S.Top > 0) 被捕获: failed precondition from ch24_contracts.adb:113

所有契约验证完毕！
提示：编译时加 -gnata 显式启用所有断言；
      不加时部分断言可能被跳过。
```

**关键观察：**

- 每条违反消息都**精确指出源文件和行号**，便于定位。
- 即使是私有类型的字段（如 `Counter.Value`），通过 `Type_Invariant` + 外部可见函数的方式仍可被约束。
- 循环不变式与循环变体的组合，能让编译器与验证器**自动证明循环的正确性与终止性**。

---

## 24.12 与 SPARK 的关系

Ada 2012 的契约是**通往形式化验证的钥匙**：

```
                ┌──────────────┐
                │  Ada 2012    │
                │  动态契约     │  ← 运行时检查，捕获 bug
                └──────┬───────┘
                       │ 同一套契约语法
                       ▼
                ┌──────────────┐
                │  SPARK Pro   │
                │  静态证明     │  ← 编译时数学证明，零运行时开销
                └──────────────┘
```

**SPARK** 是 Ada 的可判定子集，移除了"难以静态分析"的特性（如指针运算、动态派发、异常），并使用 Ada 2012 的契约作为**证明的目标**：

```ada
function Safe_Divide (X, Y : Integer) return Integer is
  (X / Y)
with
  Pre  => Y /= 0,
  Post => Safe_Divide'Result * Y = X;
--  SPARK 会用自动定理证明器（CVC4/Z3）证明：
--  "对所有满足 Pre 的输入，Post 都必然成立"
```

**这意味着：**

- 同一份 Ada 代码，在调试时启用 `-gnata` 做**动态检查**。
- 在关键系统中，用 SPARK 做**静态证明**——无需运行测试用例，就能**数学上保证**代码满足契约。
- 从 Ada 2012 到 SPARK 的迁移是**平滑的**——你只需让代码逐渐符合 SPARK 子集的约束。

这是 Ada / SPARK 在航空航天、铁路、医疗等**高可靠领域**成为首选语言的根本原因：**它把"代码质量"从依赖测试覆盖率，升级为依赖数学证明**。

---
上一章：[23 容器](23-containers.md) ｜ 下一章：[25 SPARK](25-spark.md) ｜ 返回：[README](../README.md)

