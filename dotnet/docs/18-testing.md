# 18 · 测试：从第一个断言到可测设计

> 对应示例：`examples/18_testing`

## 1. 示例的形态：自检控制台

真项目的测试工程用 `dotnet new xunit` 起：`[Fact]` 标注测试方法、`dotnet test` 跑全部。本教程示例为了能进 build.ps1 统一构建，做成了**自检控制台**——自己的 `AssertEx` 断言类 + Main 里顺序执行，任何断言失败抛异常、进程非零退出：

```csharp
var calc = new Calculator();

AssertEx.Equal(8, calc.Add(5, 3), "Add");
AssertEx.Equal(2, calc.Subtract(5, 3), "Subtract");
AssertEx.Equal(15, calc.Multiply(5, 3), "Multiply");
AssertEx.True(Math.Abs(calc.Divide(10, 2) - 5.0) < 0.0001, "Divide");
AssertEx.Throws<DivideByZeroException>(() => calc.Divide(10, 0), "Divide by zero");
```

两种形态的映射关系——概念完全同构，只是宿主不同：

| 自检控制台 | xUnit 工程 |
|---|---|
| `AssertEx.Equal(8, calc.Add(5, 3), "名字")` | `Assert.Equal(8, calc.Add(5, 3))` |
| 顺序调用 | `[Fact] public void Add_Works() { … }` |
| 抛异常即失败 | 断言失败记为红，继续跑其他用例 |
| 退出码 | `dotnet test` 汇总报告 |

真项目无脑选 xUnit；自检模式适合小工具与教学（本文讲解用示例本体）。

## 2. AAA：每个测试的三幕剧

一个测试 = 三幕：**Arrange**（布置场景）→ **Act**（执行动作）→ **Assert**（断言结果）。看异步用例：

```csharp
var asyncCalc = new AsyncCalculator();          // Arrange：准备被测对象
var sum = await asyncCalc.AddAsync(4, 6);       // Act：一个动作
AssertEx.Equal(10, sum, "AddAsync");            // Assert：验证一个事实
```

纪律：**Act 只有一个动作、Assert 聚焦一个行为**。一个测试塞三个动作，挂了不知道是哪个坏——测试名与断言要能互相印证（`Add_Works` 断言加法的结果）。

## 3. 断言的设计：示例的 AssertEx

```csharp
static class AssertEx
{
    public static void Equal<T>(T expected, T actual, string name)
    {
        if (!EqualityComparer<T>.Default.Equals(expected, actual))
        {
            throw new InvalidOperationException($"{name}: expected={expected}, actual={actual}");
        }
    }

    public static void True(bool condition, string name)
    {
        if (!condition) throw new InvalidOperationException($"{name}: condition failed");
    }

    public static void Throws<TException>(Action action, string name) where TException : Exception
    {
        try
        {
            action();
        }
        catch (TException)
        {
            return;
        }
        throw new InvalidOperationException($"{name}: expected exception {typeof(TException).Name}");
    }
}
```

三个设计决策值得咀嚼：

- `EqualityComparer<T>.Default.Equals`（而非 `==`）：泛型下 `==` 用 object 引用比较（第 03 章坑位），Default 分派到类型的**值相等**——record/数值全正确。
- **失败消息带上 expected/actual**：断言的价值一半在失败时——一眼看出"期望 8 实际 9"比"断言失败"省十分钟。
- `Throws<T>` 的结构：期待抛出（`catch (TException) return;` 通过）、**没抛或抛了别的类型都算失败**——比"只要不炸就算过"严格得多。

浮点断言的写法也看一眼：`Math.Abs(calc.Divide(10, 2) - 5.0) < 0.0001`——**浮点永远比较误差带**，`== 5.0` 在二进制浮点下迟早假阴性。

## 4. 测试替身：FakeLogger

被测的 `ServiceWithLogger` 依赖 `ILogger` 接口（第 04 章的接口在此兑现价值）：

```csharp
interface ILogger
{
    bool IsEnabled(string level);
    void Log(string message);
}

sealed class FakeLogger(bool enabled) : ILogger
{
    public List<string> Messages { get; } = [];
    public bool IsEnabled(string level) => enabled && level == "Info";
    public void Log(string message) => Messages.Add(message);
}

var logger = new FakeLogger(enabled: true);
var svc = new ServiceWithLogger(logger);
var result = svc.DoWork();
AssertEx.Equal("完成", result, "Service result");
AssertEx.True(logger.Messages.Count == 1, "Service log called");
```

FakeLogger 是**测试替身**（test double）：真 logger 可能写文件/发网络——慢且不可观察；假实现把消息**收进内存列表**，测试既快又能**断言"Log 被调用过"**（行为验证）。替身光谱一句话：**stub** 提供假数据、**fake** 是简化实现（本例）、**mock** 是预设期望的框架产物（Moq/NSubstitute）。优先级：能用真实简单实现就不用框架 mock。

这一切的前提是 `ServiceWithLogger(ILogger logger)` **依赖抽象**——若它内部 `new FileLogger()`，测试就得跟文件系统纠缠。可测性是设计属性，不是测试框架的功能。

## 5. 测试金字塔与投入

单元测试（本章：快、隔离、海量）→ 集成测试（真数据库/真 HTTP，第 16/17 章的栈可组合）→ 少量端到端。投入配比金字塔 7:2:1。新代码的实践起点：**修 bug 先写复现测试**（红了再修，绿了留作回归防线）、新功能的核心路径配测试——覆盖率的数字本身不是目标，被守护的行为才是。

## 6. 坑位清单

1. **断言里写逻辑**：`AssertEx.True(Calc(x) > 0 && Calc(x) < 10)` 失败时不知道哪个条件挂了——拆成两个断言，各自可判。
2. **测试间共享状态**：静态 `Counter.Count`（第 04 章）这类东西让用例顺序影响结果——每个测试自造自 cleanup；xUnit 里每个测试类/方法都是新实例，正是为此。
3. **测实现而非行为**：断言"内部调用了三次私有方法"——重构立刻红。断言**输入 → 输出**的契约，实现随便换。
4. **浮点 `==`**：见 §3，一律误差带。
5. **测试慢了就没人跑**：单测毫秒级；出现秒级用例（sleep、网络、真库）就该挪到集成层或用替身。
