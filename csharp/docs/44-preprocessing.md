# 44 · 预处理指令与代码组织：条件编译、命名空间、嵌套类型、程序集

> 对应示例：`examples/44_preprocessor`

> **本章你将学会**：#define/#if 家族的布尔开关语义（与 C 宏的本质区别）、DEBUG/NET10_0 等白送符号、#error/#pragma warning/#line 的实战用法、命名空间与 using 别名的组织术、:: 限定符与 global::、嵌套类型的访问特权、程序集这一「集装箱」里装了什么。
> **前置章节**：[02 工具链](02-toolchain.md)（csproj 逐行解读）、[21 可空引用类型](21-nullable.md)、[23 反射与特性](23-reflection-attributes.md)。

《程序设计教程》（唐大仕版）4.5-4.6 节把「命名空间、嵌套类型、程序集、编译预处理」合成一讲——视角很对：**这些都是编译器如何看待你代码的问题**，本教程此前散落各章，本章收拢。

## 1. 预处理指令不是宏，是布尔开关

C/C++ 的 `#define SIZE 10` 是文本替换宏；**C# 的 `#define SELF_TEST` 只定义一个 true/false 符号**，配合 `#if/#elif/#else/#endif` 让编译器决定哪段代码进 IL：

```csharp
#define SELF_TEST          // 必须在文件头、一切语句之前
#if SELF_TEST
Console.WriteLine("编译进产物");
#else
Console.WriteLine("根本不进 IL——不是死代码，是不存在");
#endif
```

一个实测差异（写示例时撞的）：**C# 的 `#define`/`#undef` 只能出现在文件第一个标记之前**——想在语句中间 `#undef` 关开关？编译器直接 CS1032。C/C++ 程序员最容易想当然的地方。

## 2. 编译器白送的符号

不用自己 define，两个符号自动就有：

- **`DEBUG`**：Debug 配置定义、Release 不定义——`dotnet run` 默认 Debug，`dotnet run -c Release` 就换边（示例输出可对照）
- **`NET10_0`**：csproj 的 `<TargetFramework>` 自动映射——同一份源码按 TFM 编出不同产物

诊断日志只在 DEBUG 编译、平台差异按 TFM 分支——**零运行时判断开销**是它与 `if (常量)` 的本质区别。

## 3. #error / #warning：把配错环境拦在编译期

```csharp
#if NETFRAMEWORK
#error 本库不支持 .NET Framework，请改用 net10.0
#endif
```

`#error` 让编译直接失败、错误信息就是你写的句子——比「编过了然后运行时神秘崩溃」体面得多。部署脚本、CI、多目标项目里当**配置哨兵**用。

## 4. #pragma warning：定点静音

```csharp
#pragma warning disable CS0219   // 写明编号
int unused = 42;                // 这段不再报「赋值未使用」
#pragma warning restore CS0219  // 成对恢复
```

原则：**不全局关警告**（csproj NoWarn 是大锤）、**定点关、写编号、成对恢复**——修好了就把三行一起删掉。示例实测：把 disable/restore 删掉重编，CS0219 立刻回来。

## 5. #line hidden：异常栈里的隐身术

`#line hidden ... #line default` 之间的代码**不产生行号信息**。示例用异常栈实测：

```text
正常区: at Program.<<Main>$>g__ThrowVisible|0_0() in ...\Program.cs:line 91
隐藏区: at Program.<<Main>$>g__ThrowHidden|0_1()
```

方法名都在，行号只有隐藏区没有。源生成器、模板生成代码用它让自己的帧不污染用户的异常栈——你在 ASP.NET 栈里看不到几千行生成器代码就是它的功劳。

## 6. 命名空间与 using 的组织术

- **块状 vs 文件级**：`namespace Foo { ... }` 与 `namespace Foo;`（C# 10+，一文件一空间，少一层缩进，新代码首选）
- **using 别名**：`using IntMap = Dictionary<int, string>;`——长泛型名起短名，还能消歧两个同名类
- **global using**：写一次全解决方案生效；csproj 的 `ImplicitUsings` 就是微软预置的 global using 包（[02 章](02-toolchain.md)拆过箱）

**`::` 限定符与 `global::`**：给名字一个「绝对起点」，专治遮蔽与歧义：

```csharp
using Coll = System.Collections;              // 命名空间别名
Coll.Hashtable h = new();                     // 别名::类型 —— 名字解析从别名处出发
var e = global::System.Text.Encoding.UTF8;    // global:: —— 从全局命名空间根出发
```

两条实测规则：

- `::` 左边必须是**命名空间**别名——别名指向类型（如 `IntMap`）时只能用 `.`，用 `::` 报 **CS0431**「无法将别名与 :: 一起使用，因为该别名引用了类型」
- 真正的使用场景：类里恰好有成员叫 `System`（字段/属性）时，类内裸写 `System.Console` 会被成员遮蔽（实测报 CS1061「int 未包含 Console 的定义」），`global::System.Console` 是唯一逃生通道。生成的代码（不知道会被贴进什么类里）尤其依赖它

示例实测输出：`global::System.Text.Encoding.UTF8 → utf-8`；带 `System` 字段的类里，`Escape()` 方法必须写 `global::` 才能引用命名空间。

## 7. 嵌套类型：设计上的一家人

```csharp
class Outer
{
    private const string Secret = "...";
    public class Inner
    {
        public static string Peek() => Secret;   // 直接读外层私有！
    }
}
```

示例实测：`Inner` 能读 `Outer` 的私有常量——**访问特权来自嵌套关系本身**（public 字段做不到的，嵌套 private 可以）。用途：外部不应感知的实现细节（状态机的状态类、集合的枚举器），呼应 [18 章迭代器](18-iterators.md)里枚举器为什么常做成嵌套类。

## 8. 程序集：编译产物这个集装箱

一个 csproj 编译成一个程序集（dll/exe），IL + 元数据都装在里面。示例运行时自省：

```text
全名: PreprocessorConsole, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null
位置: ...\build\bin\Debug\net10.0\PreprocessorConsole.dll
引用的程序集: 4 个
```

记住一对互补关系：**#if 在编译期做选择、产物里不留痕迹；反射（[23 章](23-reflection-attributes.md)）在运行期读程序集元数据**。想「按配置切换实现」——编译期用 #if，部署后切用反射/注入，别混。

## 常见坑

**在语句中间写 #define/#undef**：CS1032——它们只能待在文件头（与 C/C++ 不同）。

**用 #if 做业务逻辑开关**：配置该走配置系统（环境变量/appsettings），#if 是「编译目标差异」的开关，改它要重新编译。

**全局 NoWarn 图省事**：把真正的 bug 静音了——永远定点关、写编号、成对恢复。

**条件编译看不出来**：`#if` 分支在编辑器里灰显；code review 时留意灰掉的代码是不是该删。

**类型别名后面试着用 `::`**：`IntMap::KeyCollection` 报 CS0431——`::` 只配命名空间别名，类型别名用 `.`。

## 实战建议

- 诊断代码：`#if DEBUG` 包住，Release 产物零残留
- 多目标项目（net10.0 + 老 Framework）：每处平台分支配一个 `#error` 哨兵，防止「以为兼容」
- 生成器/模板输出的代码段用 `#line hidden` 包住，用户异常栈只留业务帧
- 命名空间按「程序集内聚」组织：一程序集一主题命名空间，别做大型公共混合包

## 自测

1. **C# 的 #define 与 C/C++ 宏的本质区别？** —— 只定义布尔符号，不做文本替换；无参数宏函数。
2. **#undef 放在文件中间会怎样？** —— CS1032 编译错误：#define/#undef 必须先于一切标记。
3. **#line hidden 的实际效果在哪能看到？** —— 异常 StackTrace 里该帧丢失行号（示例实测对比）。
4. **嵌套类有什么访问特权？** —— 可访问外层类的 private 成员（反向不行）。
5. **#if 与反射各自管什么期的「选择」？** —— 编译期固化（产物无痕迹）vs 运行期读元数据动态决策。
6. **`::` 能跟在类型别名后面吗？global:: 解决什么问题？** —— 不能（CS0431，只配命名空间别名）；global:: 从全局命名空间根出发，专治成员名撞命名空间的遮蔽。

---
上一章：[43 常用工具类型](43-common-types.md) ｜ 下一章：[45 XML 与 LINQ to XML](45-xml.md) ｜ 返回：[README](../README.md)
