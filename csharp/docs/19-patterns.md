# 19 · 模式匹配

> 对应示例：`examples/19_patterns`

> **本章你将学会**：is 的组合模式、switch 表达式全家族（常量/类型/属性/位置/关系/逻辑/列表）、Deconstruct 配合、模式替换 if-as 链。
> **前置章节**：[04 switch 表达式](04-control-methods.md)、[11 解构](11-records.md)。

## 1. 模式匹配是什么

`if (obj is string s && s.Length > 0)` 这样的"**类型测试 + 条件 + 取值**"三连，C# 7 之后进化成一门小语言——**模式（pattern）**。模式 = "值的形状描述"，匹配成功还能顺便把部件取出来。现代 C# 处理分支的第一工具。

## 2. 模式家族一览

示例的 switch 表达式浓缩了全部形态：

```csharp
var desc = v switch
{
    int n when n > 100       => "大于 100 的 int",     // 类型 + when 守卫
    int n                    => $"int: {n}",           // 类型模式：测试 + 命名
    string { Length: 0 }     => "空字符串",             // 属性模式
    string s                 => $"string: {s}",        // 类型模式
    Point { X: 0, Y: 0 }     => "原点",                 // 属性递归匹配
    Point p                  => $"Point({p.X},{p.Y})",
    null                     => "null",
    _                        => "其他",                 // 丢弃：兜底
};
```

| 模式 | 形态 | 测什么 |
|---|---|---|
| 常量 | `0`、`"abc"`、`Level.High` | 等值 |
| 丢弃 | `_` | 万能（兜底） |
| 类型 | `int n`、`string s` | 是该类型且**命名取出** |
| 声明 + when | `int n when n > 100` | 类型 + 额外条件 |
| 属性 | `{ Length: 0 }`、`{ X: 0, Y: 0 }` | 成员匹配（可嵌套） |
| 位置 | `(0, 0)`、`(var x, var y)` | 按 Deconstruct 拆位 |
| 关系 | `>= 90`、`< 0` | 大小比较（数值） |
| 逻辑 | `a and b`、`a or b`、`not null` | 组合 |
| 列表 | `[]`、`[var x]`、`[var f, .., var l]` | 序列形状（C# 11） |

## 3. is：轻量组合

不配 switch 的单点判断用 is：

```csharp
if (shape is Circle { Radius: > 1 } big)     // 类型 + 属性条件 + 命名，一行完成
    Console.WriteLine(big.Area());
```

老写法对照：`if (shape is Circle c && c.Radius > 1)`——模式版把"类型、条件、取名"压进一个表达式，且 `Radius: > 1` 是**递归模式**（属性里再套关系模式）。`not` 前缀：`if (o is not null)` 比 `o != null` 更好（值类型的 != 重载陷阱免疫）。

## 4. switch 表达式的骨架（第 04 章进阶版）

```csharp
static string Classify(int score) => score switch
{
    < 0 or > 100   => "非法分数",       // 逻辑 + 关系组合
    >= 90          => "优秀",
    >= 60 and < 90 => "及格",           // and 组合范围
    0              => "零分",           // 常量模式；0 未被上面的关系覆盖，可达
    _              => "不及格",
};
```

三条铁律（第 04 章讲过，这里带上全家族再确认）：

1. **从上到下匹配，命中即止**——顺序即优先级，窄条件在前
2. **穷尽性检查**：输入类型可能取值未被覆盖（无 `_` 时对闭集类型）→ 编译错误
3. 编译器对不可达分支报错（前面已覆盖的再写 → warning/error）

## 5. 位置模式与 Deconstruct

```csharp
static string WhereAmI(Point p) => p switch
{
    (0, 0)         => "原点",
    (0, _)         => "在 y 轴上",
    (_, 0)         => "在 x 轴上",
    (var x, var y) => $"一般位置 ({x},{y})",
};
```

`(a, b)` 位置模式按 **Deconstruct** 方法拆对象——record 自动有（第 11 章），自定义类型手写 `public void Deconstruct(out int x, out int y)` 即可接入。位置模式处理"元组形状"最自然：方法的多元返回（`(bool ok, int value)`）直接 switch。

## 6. 列表模式（C# 11）

```csharp
static string Describe(int[] a) => a switch
{
    []                       => "空数组",
    [var single]             => $"只有一个 {single}",
    [var first, .., var last] => $"首 {first} 尾 {last}",
    _ => "其他",
};
```

`[a, ..rest, b]` 里的 `..` 是切片模式——匹配"中间任意多个"。解析协议头（固定前缀 + 变长体）、校验参数形状时非常好用。

## 7. 重构信号：什么时候换模式匹配

- **if-else 链里反复出现 `is/as + 强转 + 判空`** → 类型模式
- **一串枚举/状态的 switch 语句给变量赋值** → switch 表达式
- **嵌套条件判断对象的多个属性** → 属性模式（`{ Age: > 18, City: "北京" }`）
- **元组/多返回值分支** → 位置模式

模式匹配的价值不只是短——**编译器检查穷尽性与不可达**，把运行期 bug 前移到编译期。

## 常见坑

**模式里的标识符是"新变量"不是比较**：`{ Name: name }` 是取出 Name 命名为 name；要和常量比须 `{ Name: "张三" }` 或 `{ Name: var n } when n == target`（**模式不能直接比变量**——属性模式右侧必须是常量或嵌套模式，第 36 章解析器就踩过这坑，最后用传统 == 比较）。

**分支顺序错杀**：`>= 60` 在 `>= 90` 前 → 95 分被判"及格"。窄在前。

**穷尽性误判**：加 `_` 兜底后编译器不再提示遗漏——兜底分支里放日志/断言防"未预期值静默通过"。

**null 模式的位置**：`null` 分支别忘（引用类型的 switch 表达式缺 `_` 时编译器会提醒覆盖 null）。

**列表模式只认集合语义**：匹配数组/List；IEnumerable 任意实现不保证按索引可切——先物化。

## 实战建议

- 分支逻辑超过三个 arm 一律 switch 表达式——编译器成为你的测试员
- 属性模式替你消灭"金字塔式嵌套取值判断"（`a?.B?.C != null && a.B.C.D > 0` 的地狱）
- 解构（record/手写 Deconstruct）+ 位置模式是一对：多返回值的设计（第 04 章）到消费端在此闭环
- `is not null` 替代 `!= null`；`is not string` 替代 `!(o is string)`——not 读起来更顺
- 复杂业务规则（多层属性 + 范围 + 组合）用模式写完，可读性经常超过注释

## 自测

1. **类型模式一行完成了老写法的哪三件事？** —— 类型测试 + 命名取出 + 后续可用。
2. **属性模式右侧能放变量吗？** —— 不能，只能常量或嵌套模式；比变量用 when 或先取出再比。
3. **位置模式靠什么机制拆对象？** —— Deconstruct（record 自动合成）。
4. **穷尽性检查的价值？** —— 新增枚举值/新形态时，漏改的 switch 直接编译失败。

---
上一章：[18 迭代器与 yield](18-iterators.md) ｜ 下一章：[20 扩展方法与运算符重载](20-extensions-operators.md)
