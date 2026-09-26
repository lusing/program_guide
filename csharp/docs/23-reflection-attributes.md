# 23 · 反射与特性

> 对应示例：`examples/23_reflection`

> **本章你将学会**：Type 的获取与成员枚举、特性的定义与读取、动态实例化与调用、反射的性能边界。
> **前置章节**：[08 类](08-classes.md)、[22 异常](22-exceptions.md)。

## 1. 反射是什么：程序读自己

编译后的程序集里除了代码还带着**元数据**——每个类型叫什么、有哪些成员、贴了什么特性。**反射 = 运行时查询和操作这些元数据**：

```csharp
Type t1 = typeof(Worker);        // 编译期已知 → Type 对象
Worker w = new("反射");
Type t2 = w.GetType();           // 运行期实例 → 真身（可能是子类）
t1 == t2                          // true
```

`Type` 是反射宇宙的入口——从一个 Type 出发能到达一切：属性、方法、特性、构造函数、基类、接口……

## 2. 枚举成员

```csharp
foreach (var p in typeof(Worker).GetProperties())
    Console.WriteLine($"{p.PropertyType.Name} {p.Name}");

foreach (var m in typeof(Worker).GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly))
    if (!m.IsSpecialName) ...      // 过滤编译器生成的 get_/set_
```

BindingFlags 控制取哪一层（Public/NonPublic、Instance/Static、DeclaredOnly 排除继承的）。`IsSpecialName` 滤掉属性的幕后方法——枚举方法时的标准动作。

## 3. 特性：贴在代码上的元数据

```csharp
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Struct)]    // 这个特性能贴在哪
public sealed class AuthorAttribute(string name) : Attribute
{
    public string Name { get; } = name;
    public double Version { get; set; }       // 可选参数 = 命名属性赋值
}

[Author("张三", Version = 1.2)]
public class Worker(string name) { ... }
```

特性本身是**普通类**（继承 Attribute、后缀 Attribute、使用时可省略后缀）——它是"编译进程序集的注解数据"。**没有反射读它，特性就是死数据**：

```csharp
foreach (var attr in typeof(Worker).GetCustomAttributes(false))
    if (attr is AuthorAttribute a)
        Console.WriteLine($"作者 {a.Name}，版本 {a.Version}");
```

你已经用过的特性都是这个原理：`[Flags]`（第 07 章）、`[JsonPropertyName]`（第 33 章）、`[HttpGet]`（ASP.NET Core 路由）。框架的"约定优于配置"引擎 = 特性声明 + 反射扫描。

## 4. 动态实例化与调用

```csharp
var obj = Activator.CreateInstance(typeof(Worker), "动态造的")!;   // 按类型+参数 new
var method = obj.GetType().GetMethod("Greet")!;
method.Invoke(obj, Array.Empty<object>());                        // 反射调方法

var prop = obj.GetType().GetProperty("Name")!;
prop.GetValue(obj);                       // 反射读属性
prop.SetValue(obj, "改过的");             // 反射写属性
```

"知道类型名（字符串）→ 造对象 → 调方法"——插件系统、配置驱动加载、序列化器都靠这条链。`Activator` 返回 object，取具体成员要强转（第 05 章语法）或继续用反射。

## 5. typeof / nameof / GetType 三兄弟

```csharp
typeof(Worker)     // Type 对象——数据（给反射用）
nameof(Worker)     // "Worker" 字符串——编译期（重构安全：改名跟着改）
w.GetType()        // 实例运行时真身（子类对象给子类 Type）
```

`nameof` 只拿名字不拿元数据，零运行时成本——日志/参数校验/绑定属性名的标配（WPF 教程里满篇 `nameof`）。`GetType()` 是虚方法——多态到类型级。

## 6. 反射的性能与边界

- **慢**：比直接调用慢一个数量级以上（类型检查 + 参数装 object[] + 装箱）。热路径优化：**缓存 PropertyInfo/MethodInfo**（字典缓存一次查多次）或转成委托 `method.CreateDelegate<...>()` 调用（快一个数量级）
- **能绕门禁**：`BindingFlags.NonPublic` 可摸私有成员——测试隔离有用，业务里用 = 破坏封装 + 脆弱（内部一改就崩）
- **AOT/裁剪的敌人**：反射依赖元数据完整——PublishTrimmed（WPF 教程 24 章）会裁掉"看似没人用"的反射目标；**第 24 章源生成器是反射的现代替代**

## 7. 反射的三大真实用户

1. **序列化器**（System.Text.Json 反射模式）：读属性名/类型 ↔ JSON 字段映射
2. **DI 容器**（ASP.NET Core）：`Activator.CreateInstance` 造服务实例、构造函数注入
3. **ORM/验证/单元测试框架**：特性扫描 + 动态调用

理解了反射，这些"魔法框架"的魔法全部祛魅——它们都只是本章 API 的搬运工。

## 常见坑

**GetMethods 带出一堆 get_/set_**：属性幕后方法混入——`IsSpecialName` 过滤。

**反射调私有成员**：能跑但破坏封装；版本一升级私有结构变了就崩——封装被反射打穿不是框架的承诺。

**没缓存 PropertyInfo**：循环里反复 GetProperty——反射查询本身也贵，缓存到静态字段。

**Activator 造的 object 直接 . 属性**：编译错误（object 类型）——强转或反射取（示例的标准写法）。

**Trimmed/AOT 环境反射失灵**：被裁掉的类型 Type 为 null 或成员缺失——反射依赖的形态提前用 `[DynamicallyAccessedMembers]` 标注，或换源生成。

## 实战建议

- 业务代码尽量**不用**反射——它是框架的武器不是业务的；需要"按字符串加载"先问配置能不能换成显式注册
- 真要反射：MethodInfo/PropertyInfo 缓存 + CreateDelegate 提速（一个数量级）
- 自定义特性配 `[AttributeUsage]` 限定贴附目标——防止特性被乱贴
- 元编程需求排个序：**手写 > 泛型（12 章） > 源生成器（24 章） > 反射**——反射永远是最后手段
- 调试框架行为：断点打在反射调用处，`obj.GetType()` 看真身——"框架到底把我的对象当什么了"一目了然

## 自测

1. **Type 三种获取方式与各自场景？** —— typeof（编译期）、GetType（运行时真身）、Assembly.GetType（字符串加载）。
2. **特性与反射的关系？** —— 特性是编译进程序集的注解数据；反射读取它才有生命。
3. **反射慢在哪？两个提速手段？** —— 类型检查/装箱/间接调用；缓存元数据对象 + CreateDelegate。
4. **谁在用反射（三大用户）？** —— 序列化器、DI 容器、ORM/测试框架。

---
上一章：[22 异常处理](22-exceptions.md) ｜ 下一章：[24 元编程与源生成器](24-metaprogramming.md) ｜ 返回：[README](../README.md)
