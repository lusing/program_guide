# 20 · 扩展方法与运算符重载

> 对应示例：`examples/20_extensions`

> **本章你将学会**：扩展方法的机制、C# 14 扩展成员、运算符重载、隐式/显式转换运算符。
> **前置章节**：[13 委托](13-delegates.md)、[05 值类型](05-value-reference.md)。

## 1. 扩展方法：给别人的类型加方法

string 没有 Truncate？你自己加：

```csharp
public static class StringExtensions
{
    public static string Truncate(this string s, int max)      // ★ this 参数
        => s.Length <= max ? s : s[..max] + "…";
}

"hello world".Truncate(8)      // "hello w…"——像实例方法一样调用
3.IsEven()                     // int 也加了一个
```

机制：**静态类 + this 修饰第一个参数**。编译器把 `x.Foo(a)` 翻译成 `Ext.Foo(x, a)`——纯语法糖，实例并不被"修改"（string 还是那个 string）。使用方需要 `using` 扩展类所在的命名空间——**扩展是"按命名空间发放"的能力**。

LINQ 的 50+ 操作符（Where/Select...）全是扩展方法——`System.Linq.Enumerable` 给 `IEnumerable<T>` 加的。你天天写的 `list.Where(...)` 就是这套机制，第 17 章 MyWhere 已亲手复刻过。

## 2. 扩展方法的规矩

- 只能"加方法"，**加不了字段/属性/事件**（传统扩展）——状态无处安放
- 扩展方法**发现不了**私有成员；与实例方法撞名时**实例方法优先**（扩展是备胎）
- 命名空间失控会"到处都是扩展"——收敛到一个 `Extensions` 命名空间/目录

## 3. C# 14 扩展成员：一个块管一族

C# 14 把扩展从"单个方法"升级为"成族成员"：

```csharp
public static class RectExtensions
{
    extension(Rect r)                       // 接收者类型 + 成员族
    {
        public double Area() => r.Width * r.Height;        // 扩展方法
        public bool IsSquare => Math.Abs(r.Width - r.Height) < 1e-9;   // 扩展属性！
    }
}

var r = new Rect(3, 4);
r.Area(); r.IsSquare         // 属性也能扩展了
```

`extension(类型 参数名)` 块内可以声明方法/属性（块内用参数名访问接收者）。比老写法（每个方法都带 this）更内聚，且补上了"扩展属性"这个多年缺口。**新代码推荐块形态**；满世界的老代码是 this 方法形态——两种都要认识。

## 4. 运算符重载：让 Money 像内置类型

自定义类型参与 `+ - * ==`：

```csharp
public readonly struct Money(decimal amount)
{
    public static Money operator +(Money a, Money b) => new(a.Amount + b.Amount);
    public static Money operator *(Money m, int times) => new(m.Amount * times);
    public static bool operator ==(Money a, Money b) => a.Amount == b.Amount;
    public static bool operator !=(Money a, Money b) => !(a == b);
}

Money total = price * 3;  Money withTip = total + new Money(5m);
total == new Money(59.97m)      // true
```

规则速记：

- `public static` + `operator` 关键字 + 运算符符号；至少一个参数是本类型
- **`==` 和 `!=` 必须成对**；重载 `==` 还应重写 `Equals`/`GetHashCode`（三件套，IDE 会提醒）
- 可重载：算术、比较、true/false；**不可重载**：`&& || ?? . ? :` 等（由可重载的 & | 组合派生）
- 数值语义的值类型（金额/向量/复数/分数）是最佳适用场景；"字符串拼接式滥用"（+ 表示发消息？）是可读性灾难

## 5. 隐式/显式转换运算符

类型之间的桥：

```csharp
public readonly struct Celsius(double degrees)
{
    public static implicit operator Celsius(double d) => new(d);        // 隐式：无损
    public static implicit operator double(Celsius c) => c.Degrees;
    public static explicit operator Fahrenheit(Celsius c) => new(c.Degrees * 9 / 5 + 32);   // 显式
}

Celsius c = 25;                  // double → Celsius 隐式（顺手）
double back = c;                 // 反向也隐式
Fahrenheit f = (Fahrenheit)c;    // 显式：要写强转——提醒"这里有语义跳跃"
```

选型铁律：**绝不丢信息 → implicit；可能丢/可能失败/语义重释 → explicit**。implicit 用多了调用点无声变形（`Celsius c = someDouble;` 读者毫无察觉）；explicit 的 `(Fahrenheit)` 强转是显眼的信号灯。

## 6. 扩展方法的设计用途盘点

1. **BCL 补全**：给 string/IEnumerable 加项目内通用工具（Truncate/ChunkBy）
2. **流畅接口**：`config.UseJson().WithRetry(3)`——配置器模式的骨架
3. **第三方类型适配**：不能改源码的类型（NuGet 包）加项目语义方法
4. **测试辅助**：`fakeStream.MakeReadable("...")` 之类搭建工具（第 35 章配合）
5. **老代码渐进增强**：不动原类型，外面挂能力

## 常见坑

**扩展方法与实例方法撞名**：实例方法赢，扩展静默失效——"扩展好好的突然不调用了"先查是不是类型自己加了同名方法。

**扩展加在 object 上**：`this object o` 的扩展对所有类型可见——命名空间污染之最。除非基类库级别的工具，别这么干。

**== 重载忘了 Equals/GetHashCode**：`==` 说相等、Dictionary 按哈希找不到——三件套一起动（record 直接免）。

**运算符重载语义不直观**：`operator +` 干了"合并订单"的活——读代码的人按数学直觉理解就错了。运算符只承载数学直觉内的事。

**implicit 转换链太长**：多个 implicit 串联，编译器自动套两层转换——类型不再"看得见"。转换预算：一条链最多一个 implicit。

## 实战建议

- 项目工具扩展集中一处（`Extensions/` + 统一命名空间），禁止散装
- 新写扩展用 C# 14 `extension` 块；读得懂老的 `this` 形态即可
- 值对象（金额/坐标/百分比）动手前先想运算符：让领域类型获得原生算力，业务代码更读作领域语言
- `==` 重载三件套纪律，或直接 record（第 11 章）省心
- 扩展是"外挂"，核心领域逻辑放类型内——别让领域模型靠扩展拼装

## 自测

1. **扩展方法的本质机制？** —— 静态类 this 参数；编译器把 x.Foo() 翻译为 Static.Foo(x)，类型本身未变。
2. **C# 14 extension 块相对老形态的新能力？** —— 成员族内聚声明 + 扩展属性。
3. **隐式与显式转换的分界？** —— 无损 implicit；可能丢/失败 explicit（强转即信号）。
4. **重载 == 的连带义务？** —— 同步重写 Equals/GetHashCode（三件套）。

---
上一章：[19 模式匹配](19-patterns.md) ｜ 下一章：[21 可空引用类型](21-nullable.md) ｜ 返回：[README](../README.md)
