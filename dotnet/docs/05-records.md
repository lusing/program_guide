# 05 · record 与模式匹配：数据优先的类型

> 对应示例：`examples/05_records`

## 1. 一行顶三十行

示例全文只有 12 行，最后一行是全部魔法所在：

```csharp
var u = new User("alice", 22);
string level = u switch
{
    {Age: < 18} => "minor",
    {Age: >= 18 and < 60} => "adult",
    _ => "senior"
};

var (name, age) = u;
Console.WriteLine($"{name}:{age} => {level}");

record User(string Name, int Age);
```

`record User(string Name, int Age);` 叫**位置记录**（C# 9 引入）。编译器替这行生成了什么：

| 生成的成员 | 等价手写 class 要写的 |
|---|---|
| 构造函数 + 只读属性 `Name`/`Age` | 3 行构造 + 2 个属性 |
| `Equals` + `GetHashCode`（**按值**） | 约 20 行，还容易写错 |
| `ToString()`（`User { Name = alice, Age = 22 }`） | 1–3 行 |
| `Deconstruct`（支持解构） | 2 个 out 参数的方法 |
| `==` / `!=` 运算符 | 2 个运算符重载 |
| `with` 拷贝支持 | 不可手写（需要编译器配合） |

凡是"一组数据的载体"——配置项、API 请求/响应、领域事件、DTO——record 都是比 class 更短更对的选择。class 留给有行为/有身份语义的对象（第 04 章的 Shape）。

## 2. 值语义 vs 引用语义

record 的判等是**按内容**，这是它和 class 的本质区别：

```csharp
var a = new User("alice", 22);
var b = new User("alice", 22);
Console.WriteLine(a == b);        // record：True（值相同）
// 若 User 是 class：False（两个引用指向不同对象）
```

对照日常经验：**class 的相等是"同一张身份证"，record 的相等是"长一样"**。把用户输入、反序列化结果、数据库行拿来做集合元素/字典键时，值语义正是你想要的。

## 3. with：非破坏性修改

record 默认不可变（位置属性全是 `{ get; init; }`），改一个字段不是赋值而是"复制并替换"：

```csharp
var u2 = u with { Age = 23 };   // 新对象，Name 带过来，Age 换新
// u.Age 仍是 22——原对象不动
```

`with` 是**浅拷贝 + 指定字段替换**。配合不可变性，整个"修改数据"的模型变成流水线：原值进、新值出，没有中间状态被就地改坏的风险。

## 4. 解构

```csharp
var (name, age) = u;   // 调用编译器生成的 Deconstruct
```

一行把记录拆回各字段，多返回值、元组风格的代码都靠它（第 11 章的错误处理示例会再用这个惯用法）。

## 5. 模式匹配：switch 的完全体

示例核心：

```csharp
string level = u switch
{
    {Age: < 18} => "minor",
    {Age: >= 18 and < 60} => "adult",
    _ => "senior"
};
```

- `{Age: < 18}` 是**属性模式**：花括号里递归匹配属性，`Age` 后跟**关系模式**。
- `and`（还有 `or`、`not`）组合模式；一个分支可以同时约束多个属性：`{Name: "alice", Age: > 18}`。
- 分支自上而下测试，`_` 兜底——和第 03 章 switch 表达式的骨架一致，这里换上了更有表达力的模式。

模式匹配不止住在 switch 里，`if` 与 `is` 也能用：

```csharp
if (u is { Age: >= 60 }) { /* 老年分支 */ }          // is + 属性模式，直接当布尔条件

if (FindUser("bob") is { } bob)                       // is { } x：非空才进分支并绑定变量
{
    Console.WriteLine(bob.Name);
}
```

`is { } bob` 这种"判空 + 取值"是第 10 章可空处理的惯用法，先在这里混个脸熟。

**模式 vs if-else 的分界**：条件是对数据的"形状"提问（类型是什么、属性落在哪个区间、是否为空）→ 模式；条件是业务规则演算 → 普通布尔表达式。

## 6. record 的一些变体

| 写法 | 含义 |
|---|---|
| `record User(...)` | 引用类型 + 值相等（默认） |
| `record struct Point(int X, int Y)` | 值类型的记录（C# 10），栈上分配 |
| `sealed record …` | 禁止再继承（record 默认可继承，见坑位） |
| 带体记录 `record User(…) { public string Note => …; }` | 补充计算属性/方法 |

## 7. 坑位清单

1. **`with` 是浅拷贝**：字段是可变引用（List、class）时，新旧记录共享同一个 List——"改副本影响了原件"的幽灵来自这里。嵌套数据用嵌套 record。
2. **继承的 record 相等性**：子类实例与父类实例**永不相等**（运行时类型参与判等），即使字段全同——record 继承慎用，需要时加 `sealed` 封住。
3. **record 里塞可变集合**：`record Box(List<int> Items)` 的 Items 是 List，判等按引用不按内容。要值语义就 `ImmutableArray`/`ReadOnlyCollection`。
4. **忘了 `_` 兜底**：switch 表达式必须穷尽，编译器会报 CS8511；属性模式覆盖不了所有取值范围时用 `_` 收尾。
5. **位置属性是 init 不是 set**：构造之后赋值编译错（CS8852）——这就是"不可变"的落实，修改请走 `with`。
