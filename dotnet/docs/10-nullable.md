# 10 · 可空引用类型：编译器替你盯 null

> 对应示例：`examples/10_nullable`

## 1. NRT 是什么、不是什么

`NullReferenceException`（NRE，运行时炸）是新手异常的头号来源。C# 8 起的**可空引用类型**（Nullable Reference Types，NRT）让编译器在你写代码时就盯着 null：

> **NRT 是编译期的警告与流分析，不是运行时检查。** `string` 与 `string?` 在运行时都是同一个 string 类型——开不开 NRT，生成的 IL 完全一样，变的只是编译器对你的约束。

工程里的开关就是 csproj 的 `<Nullable>enable</Nullable>`（第 01 章提过，新工程默认开）。本教程所有示例都在 NRT 下编写。

## 2. 两种声明：承诺不同

```csharp
string title = "hello";          // 非可空引用类型：承诺不为 null
string? subtitle = null;         // ? 声明"可能为 null"，编译器放松限制

Console.WriteLine(title.Length);
// Console.WriteLine(subtitle.Length);   // CS8602 警告：可能为 null 的解引用
```

把类型系统想成"你向编译器做出的承诺"：

- `string title`：**我保证它不会是 null**——编译器允许直接 `.Length`；你若把 null 塞进来，编译器警告你"违背承诺"（CS8600/CS8601）。
- `string? subtitle`：**它可能是 null**——直接解引用被警告（CS8602），你得先"证明非空"或显式处理 null。

整套 NRT 就是围绕这两个承诺做**流分析**：判空之后变量在后续代码里"变回"非空，编译器全程记账。

## 3. 处理 null 的四式

示例依次演示了全部惯用法：

**式一：`?.` 配 `??`——"空就给个替代"**

```csharp
Console.WriteLine(subtitle?.Length ?? -1);                       // 写法 1：?. 配 ??
```

`subtitle?.Length` 为 null 时整个表达式为 null（不调用 Length），`?? -1` 兜底。适合"缺失数据有合理默认值"的场景。

**式二：判空分支——"空走另一条路"**

```csharp
Console.WriteLine(subtitle is null ? "(空)" : subtitle);         // 写法 2：判空后编译器"流"出非空
```

`is null` 判断（比 `== null` 更纯粹：不触发运算符重载）之后，`:` 右边的 subtitle 被编译器认定为非空——三元表达式直接用，无警告。这个"记状态"能力就是流分析。

**式三：`is { } x` 模式——"非空才进来，顺便取变量"**

```csharp
if (FindUser("bob") is { } bob)                          // 属性模式：非空才进入分支
{
    Console.WriteLine($"bob 的邮箱: {bob.Email ?? "未填写"}");
}
```

`is { }` 是第 05 章属性模式的空壳版："匹配任意非 null"，并在分支内绑定变量 bob。一行完成"判空 + 取值 + 进分支"，现代 C# 的招牌写法。

**式四：`!` 断言——"我担保非空，别烦我"**

```csharp
Console.WriteLine(Shout(title)!);                        // ! 断言非空：确信时才用，用错就是 NRE
```

`!`（null-forgiving 运算符）只**关掉警告**，不生成任何运行时检查——担保错了，NRE 照炸。合法用例：编译器流分析跟不上的"事实上非空"（如 `Dictionary.ContainsKey` 先查后取）；滥用 `!` 是把警告当噪音关掉，等于裸奔回 C# 7。

## 4. 可空值类型 int?

值类型的世界是镜像的：`int` 本身不可能 null，`int?`（`Nullable<int>`）给它加了"没有值"状态：

```csharp
int? maybeScore = null;                                  // 可空值类型 int?
Console.WriteLine($"score={maybeScore ?? 0}");
```

`??` 同样适用；`maybeScore.Value` 直接取（null 时抛 InvalidOperationException）、`HasValue` 探测。数据库可空列、JSON 缺失字段映射到 `int?` 是常见场景。

## 5. API 边界：用签名表达"找不到"

```csharp
static User? FindUser(string name) =>
    name == "alice" ? new User("alice", "alice@example.com") : null;

var found = FindUser("alice");
Console.WriteLine(found?.Name ?? "(未找到)");
```

返回类型 `User?` 把"可能找不到"写进了契约——调用方被编译器推着处理 null。对比反模式：返回 `User` 且查不到时抛异常、或返回魔法值（Id = -1 的 User）、或 null 但签名不标 `?`（调用方毫无防备）。**"找不到"是正常业务分支，用类型表达；"不该发生"才是异常（第 11 章）**。

record 的字段同理：`record User(string Name, string? Email)`——Email 允许缺失，Name 不允许，一行声明读者全懂。

## 6. 坑位清单

1. **`!` 滥用**：出现 `!` 的每一处都该能说出"为什么这里事实非空"。说不出来就是 CS8602 没修、只是消音。
2. **`??` 抛新异常掩盖来源**：`user ?? throw new Exception("数据错")` 把 null 的**成因**（哪来的 null？）吞了——异常信息要带上原始上下文。
3. **反序列化结果未判空**：`JsonSerializer.Deserialize<T>` 返回 `T?`（第 12 章），"JSON 顶层是 null"是合法输入——拿到就解引用会在生产环境炸。
4. **可空注解只覆盖你这一层**：旧库、动态构造的数据（`JsonDocument`、反射）不受编译器保护，边界处仍要运行时校验。
5. **遗留代码迁移**：老工程开 NRT 会刷屏警告——按文件逐步迁移：文件头 `#nullable enable`、修完一个文件删一个；全关（`#nullable disable`）只该是过渡态。
