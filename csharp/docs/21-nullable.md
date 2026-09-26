# 21 · 可空引用类型

> 对应示例：`examples/21_nullable`

> **本章你将学会**：NRT 的编译期本质、`?`/`!`/`?.`/`??` 家族、防御性 null 的三板斧、可空值类型 int? 的独立语义。
> **前置章节**：[05 值与引用](05-value-reference.md)、[08 属性](08-classes.md)。

## 1. 十亿美元的错误与 C# 的补法

引用类型的变量可以装 null——1965 年 Tony Hoare 后悔发明它（"十亿美元的错误"）。C# 8（2019）的补法不是禁 null，而是**让 null 进入类型系统**：

```xml
<Nullable>enable</Nullable>   <!-- 新工程默认开 -->
```

开启后（NRT，Nullable Reference Types）：

```csharp
string name = "张三";      // 不可空：编译器假定永不为 null
name = null;              // ⚠ 警告：把 null 装进"不会是 null"的类型
string? maybe = null;     // 可空：声明了 ? 就可以装 null
maybe.Length;             // ⚠ 警告：可能空引用
```

**NRT 是编译期静态分析，不是运行时检查**——运行时 string 与 string? 是同一个类型（不像 int? 真的多了包装）。它的价值：编译器沿着数据流推理"这里可能为 null 吗"，把 NullReferenceException 从运行期崩溃前移为编辑器里的黄波浪。

## 2. 语法家族：? ! ?. ?? 的分工

```csharp
string? s = Get();          // ?  声明：允许 null

s.Length                    // ⚠ 警告
s?.Length                   // ?. 条件访问：s 为 null 时整个表达式为 null（不炸）
s?.Length ?? -1             // ?? null 合并：左侧为 null 取右侧
s!.Length                   // !  容忍断言："我担保非 null，别警告"（骗编译器）
```

| 符号 | 谁 | 语义 |
|---|---|---|
| `T?`（引用） | 声明 | 该变量/参数/返回可为 null |
| `?.` | 使用 | 空则短路，不触发成员访问 |
| `??` | 使用 | 空则给兜底值 |
| `!` | 使用 | **断言非空**（骗过编译器；错了照样炸） |

`!` 是逃生舱不是常规操作——每写一个 `!` 都该有"为什么编译器不知道"的答案（泛型边界、反射构造、外部契约未标注）。示例演示了 `null!` 这种"明知故犯"：编译器放行但运行时真 null——**NRT 挡不住恶意/外来的 null**。

## 3. 防御性 null 的三板斧

```csharp
// ① 入口拒绝：公共 API 的不可空参数，运行时校验兜底（防外部没开 NRT 的调用方）
static int LenOf(string? s)
{
    ArgumentNullException.ThrowIfNull(s);   // .NET 6+ 标准写法（抛 ArgumentNullException）
    return s.Length;                       // 校验后编译器知道非空，警告消失
}

// ② 兜底默认
var host = config["host"] ?? "localhost";
var port = config.GetValueOrDefault("port") ?? "3306";

// ③ 源头清洗：数据一进来就归位成不可空
var clean = raw?.Trim() is { Length: > 0 } t ? t : "(空)";
```

`is { Length: > 0 } t` 是模式匹配（第 19 章）与 null 检查的合体——"非 null 且非空串且取出命名"，一行完成。

## 4. int?：另一个物种

可空**值**类型与 NRT 完全是两回事：

```csharp
int? maybe = null;          // 真的多了一个状态：Nullable<int> 结构体（HasValue + Value）
maybe ?? -1                 // 有值取值，无值兜底
maybe.HasValue / maybe.Value

var found = arr.FirstOrDefault(n => n % 2 == 0);   // int：没找到 = 0（和"找到 0"分不清！）
var found2 = arr.Cast<int?>().FirstOrDefault(...); // int?：没找到 = null——语义清晰
```

int? 是**运行时真实存在的结构**（装着 HasValue 标志），不是标注。它的舞台：数据库可空列、Find 结果、三态 UI（WPF 的 CheckBox.IsChecked 就是 bool?）。**"没找到"和"默认值"语义分离**时用它。

## 5. 注解家族：给编译器递证据

跨 API 边界时编译器看不见对方代码，注解声明契约：

| 注解 | 含义 |
|---|---|
| `[MaybeNull] T` | 返回值/出参可能为 null（如 TryGet 的 T） |
| `[NotNull]` | 方法返回时该参数保证非空 |
| `[NotNullWhen(false)]` | 返回 false 时参数非空 |
| `[AllowNull]` | 传入可为 null，但属性本身不变 null |

`string.IsNullOrEmpty` 就标了 `[NotNullWhen(false)]`——所以 `if (!string.IsNullOrEmpty(s)) s.Length` 无警告：**编译器认识这个方法的行为**。自家 TryXxx 方法配上注解，调用方的 if 就能自动"收窄"null 性——零运行时成本。

## 6. 迁移与团队策略

- **新工程**：默认 enable，从第一行就写对
- **老工程**：`#nullable enable` 逐文件开（或 csproj 开 + 热点文件 `#nullable disable` 缓冲）；警告当 TODO 清单逐个消灭
- 泛型边界 `T?` 与 `where T : notnull` 的组合有微妙规则——深水区再查
- **别用 `!` 消警告**：那是静音不是修复。警告是编译器在告诉你"这里有它不知道的事"——补注解、补校验、补判空

## 常见坑

**以为 NRT 是运行时保护**：`string s = GetSneakyNull(); s.Length` 照样 NullReferenceException——NRT 只是静态提示。公共入口运行时校验（ThrowIfNull）不能省。

**`!` 满天飞**：每个 `!` 都是一次"我比编译器聪明"的赌注——赌错就是生产崩溃。控制在确有把握的边界。

**`?.` 链吞掉设计错误**：`a?.B?.C?.D` 全程静默 null 返回 null——本该炸的地方不炸，错误传到远处更难查。该断言的地方断言。

**忘了 `??` 兜底也能产生 null 注入**：`string s = maybeName ?? "";` 兜了才安全——兜底值本身别再是 null。

**老库返回值未标注**：编译器对无注解的程序集按"不可为 null"处理（乐观）——外部库返回的 null 不警告直接炸。防御性校验覆盖外部边界。

## 实战建议

- 心法：**null 是"合法但特殊"的值，用类型标出来、用模式处理掉**——NRT 时代的 null 处理三段论
- 首选"消除 null"而不是"处理 null"：空集合（`Enumerable.Empty<T>`）代替 null 集合、空串常量、Optional 语义的 TryXxx
- 公共 API 三件套：参数 `ThrowIfNull`、返回值诚实标注 `?`、TryXxx 配 `[NotNullWhen]`
- `is null / is not null` 判断（第 19 章）比 `== null` 更稳（重载免疫）
- WPF 教程 21 章的 Dispatcher 上下文与本章共用 `?.` 家族——GUI 与服务的 null 防御是同一套

## 自测

1. **NRT 是编译期还是运行时机制？推论？** —— 编译期静态流分析；运行时无保护，公共入口仍要校验。
2. **`?.` `??` `!` 各自的语义与使用心态？** —— 条件访问/兜底/断言（逃生舱，慎用）。
3. **int? 与 string? 的本质区别？** —— 运行时真实结构（HasValue）vs 编译期标注。
4. **[NotNullWhen] 给编译器递了什么？** —— 方法行为证据，让调用方 if 后自动收窄 null 性。

---
上一章：[20 扩展方法与运算符重载](20-extensions-operators.md) ｜ 下一章：[22 异常处理](22-exceptions.md) ｜ 返回：[README](../README.md)
