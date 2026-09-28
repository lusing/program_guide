# 11 · 结构体与记录

> 对应示例：`examples/11_records`

> **本章你将学会**：四种数据形态（class/struct/record/record struct）的选型、with 表达式、浅拷贝与深拷贝、解构、值相等。
> **前置章节**：[05 值与引用](05-value-reference.md)、[09 Equals 样板](09-inheritance.md)。

## 1. 一张表看四种数据形态

第 05 章铺垫了值/引用之分，第 09 章手写了 10 行 Equals 样板——本章的主角把这一切收拢成声明：

| 声明 | 语义 | 相等 | 典型 |
|---|---|---|---|
| `class` | 引用、可变 | 身份（默认） | 有行为的服务/实体 |
| `record` | 引用、**不可变** | **内容（自动合成）** | 数据传输（DTO/消息） |
| `struct` | 值、小而快 | 内容（可合成） | 坐标/金额/颜色 |
| `record struct` | 值、**不可变** | 内容 + with/解构全送 | 高频小数据 |

选型顺序口诀：**数据载体 → record；小的性能敏感值 → struct/record struct；有行为有状态 → class**。

## 2. record：一行得到全套

```csharp
record Order(int Id, string Customer, decimal Amount);
```

这一行（**位置记录**）编译器合成了：构造函数、只读属性、**基于全部字段的 Equals/GetHashCode**、可读的 `ToString`、解构方法、`with` 支持。对比 class 手写这套（第 08-09 章加起来 30 行样板），record 是"数据即类型"的直达车。

```csharp
var o1 = new Order(1, "张三", 99.9m);
var o2 = new Order(1, "张三", 99.9m);
o1.Equals(o2)      // true！内容相等（class 默认 false）
o1.ToString()      // "Order { Id = 1, Customer = 张三, Amount = 99.9 }"——日志友好
```

**非位置形态**想加验证或自定义属性时用：

```csharp
record Order
{
    public int Id { get; init; }
    public decimal Amount { get; init; }
    public string Note => Amount > 1000 ? "大额" : "普通";   // 派生成员随便加
}
```

record 是引用类型（第 05 章）——传递不拷贝、可为 null；只是**默认不可变 + 内容相等**。要值语义的 record 用 `record struct`（第 4 节）。

## 3. with：不可变世界的"修改"

不可变对象怎么"改"？**不改——拷一份改一处**：

```csharp
var upgraded = o1 with { Amount = 199.9m };
// 原地不动 o1（Amount 仍是 99.9），新对象只换指定的字段
```

`with` 基于原型做浅拷贝 + 覆写指定成员。配套心智：**配置传播**（默认配置 with 出各环境特化）、**状态流转**（新状态 = 旧状态 with 变化字段）、**测试数据**（基准数据 with 出各用例变体）。链式多个字段 `{ A = 1, B = 2 }` 一句完成。

## 4. 浅拷贝 vs 深拷贝：引用成员的复制边界

「拷贝一个对象」在引用类型上有两档，边界画在**引用成员**上：

```csharp
class Team(string name, List<string> members)
{
    public string Name { get; } = name;
    public List<string> Members { get; } = members;

    public Team ShallowCopy() => (Team)MemberwiseClone();   // 逐字段拷贝：List 引用原样搬过来
    public Team DeepCopy() => new(Name, [.. Members]);      // 引用成员另造一份，彻底脱钩
}
```

示例实测三连：

```text
浅拷贝后原队: 张三、李四、王五        ← shallow.Members.Add("王五")，原队的 List 多了人！
深拷贝后原队: 张三、李四、王五（新队 张三、李四、王五、赵六）
JSON roundtrip 深拷贝: 一组 3 人      ← JsonSerializer.Serialize 再 Deserialize，深拷贝的偷懒法
```

三个配套事实：

- **`Object.MemberwiseClone()` 是 protected**——只能在类自己的 `Clone()` 方法里调，类外拿不到。这是刻意设计：拷贝语义（浅/深）该由类型作者声明，不该让调用方乱选
- **`ICloneable` 官方不推荐**——它没说清 `Clone()` 拷出来的是浅还是深，实现者各猜各的，接口等于没契约
- **首选现代写法**：`record` + `with`（明确就是浅拷贝，嵌套引用成员用不可变类型根治）；`with` 的浅拷贝语义见第 3 节与常见坑

深拷贝什么时候真需要？**对象图里有可变引用成员且两份要独立演化**时。成员全是不可变（record 套 record、ImmutableList）的话，浅拷贝就够了——不可变让"共享"无害，这正是第 05 章「不可变的红利」的延伸。

## 5. 解构：一拆为多

```csharp
var (id, name, amount) = o1;      // 按位置拆到三个变量
```

位置记录自动合成 `Deconstruct`。用户：多返回值（比 out 干净，第 04 章的账还上了）、模式匹配的位置模式（第 19 章 `(0, 0)` 就在用它）。自己写类型时手动加 `public void Deconstruct(out int x, out int y)` 即可加入这套语法。

## 6. record struct 与 struct 的适用线

```csharp
record struct Pixel(int X, int Y);    // 值语义 + Equals/with/解构全家桶
```

**struct 的适用线**（三条同时满足）：

1. **小**：≤16 字节左右（两个 double 出头）——拷贝成本可忽略
2. **不可变**：可变 struct 是 bug 制造机（在第 05 章的拷贝语义下，改副本不改原件的经典事故）
3. **生命周期短、数量大**：值类型省 GC 压力（栈分配/内联在数组里）

BCL 的示范：`DateTime`、`TimeSpan`、`decimal`、`Guid` 都是 struct——小、不可变、无处不在。超过适用线就用 class/record：大 struct 每次赋值/传参整块拷贝，反而更慢。

**可变 struct 的一个天坑**：`list[0].X = 1`（List 索引器返回的是**副本**）编译都过不了；数组 `arr[0].X = 1` 却可以（数组直接返回存储位置）。行为不一致——又一个"默认不可变"的理由。

## 7. 真实项目的分层用例

一个典型 Web 请求的数据流（呼应 dotnet 教程）：

```csharp
record RegisterRequest(string Email, string Password);        // API 入参（record）
record User(int Id, string Email) { public string Masked => ...; }   // 领域数据
class UserService(IUserRepository repo) { ... }               // 有行为的服务（class）
record struct SearchFilter(int Page, int Size);               // 高频小参数
```

数据用 record 声明、行为用 class 承载——这条线画清楚，项目的可读性立刻上一个档次。

## 常见坑

**record 里放可变成员**：`public List<string> Items { get; set; } = new();`——record 的"不可变"只保引用不变，List 内容随便改。深不可变要 `ImmutableList` 或自定义。with 也是**浅拷贝**：原型里的 List 和新对象共享同一个（第 4 节的边界问题在 with 上原样存在）。

**以为拷贝了就是深拷贝**：`MemberwiseClone`/`with`/拷贝构造都只搬引用——`shallow.Members.Add(x)` 原对象跟着变（第 4 节实测）。深拷贝要么手写递归另造，要么 JSON roundtrip。

**位置 record 参数和属性不同名想要的验证**：位置形态放不下构造逻辑——转非位置形态或加验证属性。

**record struct 误用可变**：`record struct` 强制 init；自己写 struct 时记得 get-only / readonly。

**用 record 表达有身份的实体**：银行账户、订单实体有"唯一身份"语义（同一账户改了名字还是那个账户）——内容相等反而错，这类用 class + Id 比较。

**解构变量数不匹配**：`var (a, b) = threeFieldRecord` 编译错误——解构按 Deconstruct 签名走，可用弃元 `var (a, _, c)`。

## 实战建议

- 新项目的默认数据形态：**record 起步**，性能数据再 struct 化
- API 边界（HTTP/消息）的模型一律 record：不可变 + 内容相等 + ToString 排查三连
- `with` 造测试变体是单元测试的效率神器（第 35 章配合用）
- record 命名就是数据含义（Order/Request/Summary），后面别挂 Manager/Service 这类行为词

## 自测

1. **record 相比 class 自动合成了什么？** —— 内容相等的 Equals/GetHashCode、ToString、with、解构（位置形态）。
2. **with 是修改吗？浅拷贝意味着什么？** —— 不是，拷贝+覆写；嵌套引用类型新旧共享。
3. **浅拷贝与深拷贝的边界画在哪？MemberwiseClone 为什么是 protected？** —— 引用成员：浅拷贝搬引用、深拷贝另造；protected 强制拷贝语义由类型作者声明。ICloneable 因没说清浅/深而不被推荐。
4. **struct 的三条适用线？** —— 小（≈≤16 字节）、不可变、短命量大。
5. **什么时候 record 反而是错的选择？** —— 有身份语义的实体（同 ID 即同一物），内容相等会误判。

---
上一章：[10 接口](10-interfaces.md) ｜ 下一章：[12 泛型](12-generics.md) ｜ 返回：[README](../README.md)
