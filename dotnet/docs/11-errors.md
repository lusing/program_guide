# 11 · 错误处理：异常、TryParse 与 Result

> 对应示例：`examples/11_errors`

## 1. 两种失败，两套工具

C# 程序员要分清的第一件事：**可预期的失败**（用户输入 "abc"、文件不存在、键查不到）和**不可预期的故障**（代码 bug、环境坏了）。前者是业务逻辑的一部分，不该用异常表达；后者异常正是为此而生。示例演示的是前者，本章末尾把两者的分界画清楚。

## 2. 异常模型：栈展开与层次

方法 A 调 B、B 调 C，C 里 `throw` 抛出异常后：C 立即中止，沿调用栈**逐层上抛**（栈展开），直到某层的 `catch` 接住；没人接就是未处理异常、进程崩。异常对象本身携带现场：`Message`、`StackTrace`（抛出点向上的调用链）、`InnerException`（成因链）。

层次上一切异常派生自 `Exception`，两大主干：`SystemException` 系（如 `NullReferenceException`、`IndexOutOfRangeException`——代码 bug 的症状）与 `ApplicationException` 系/自定义异常（业务定义的故障）。**抛具体类型、catch 具体类型**，`catch (Exception)` 只该出现在最外层的兜底（日志 + 优雅退出）。

## 3. try/catch/finally 基本形

```csharp
foreach (var input in new[] {"42", "-1", "abc"})
{
    try
    {
        var r = ParsePositive(input);
        Console.WriteLine(r.ok ? $"ok:{r.value}" : $"err:{r.error}");
    }
    catch (Exception ex)
    {
        Console.WriteLine(ex.Message);
    }
}
```

规则要点：

- **catch 从上到下按类型匹配**，具体在前、基类在后（反了编译错 CS0160）。
- **finally 总是执行**（异常与否、return 与否）——放清理逻辑。
- `catch (Exception ex) when (ex.Message.Contains("…"))` 是**异常过滤器**：不满足条件继续找下一个 catch，栈迹不被破坏。

重抛的两种写法有讲究：

```csharp
catch (Exception ex)
{
    Log(ex);
    throw;          // 保留原始栈迹——重抛首选
    // throw ex;    // 栈迹从这行重算，原始抛出点丢失——几乎总是错的
}
```

## 4. 可预期失败：返回而不是抛

示例的核心函数：

```csharp
static (bool ok, int value, string error) ParsePositive(string text)
{
    if (!int.TryParse(text, out var n))
    {
        return (false, 0, "invalid-int");
    }

    return n > 0 ? (true, n, "") : (false, 0, "not-positive");
}
```

逐块拆：

- `int.TryParse(text, out var n)`：BCL 的"尝试解析"惯用法——**返回 bool 表示成败，`out` 交出解析结果**（成功才有意义）。解析失败不是异常，是每天都会发生的输入。`out var n` 内联声明（第 03 章的 out 参数）。
- 返回**元组** `(bool ok, int value, string error)`：调用方拿到的不是异常而是"结果说明书"，用 `r.ok`、`r.error` 命名访问（元组元素名，第 05 章解构同源）。
- 外层那个 try/catch 只是演示兜底——正常输入下三个循环都走 `ok:`/`err:` 分支，catch 一次都不触发。

## 5. Result 模式：把"说明书"类型化

元组够用但松散（error 是裸 string）。更正式的形态——一个专门的**结果类型**：

```csharp
record Result<T>(bool Ok, T? Value, string? Error)
{
    public static Result<T> Good(T value) => new(true, value, null);
    public static Result<T> Bad(string error) => new(false, default, error);
}

static Result<int> ParsePositive(string text) =>
    int.TryParse(text, out var n) && n > 0
        ? Result<int>.Good(n)
        : Result<int>.Bad("not-a-positive-int");
```

调用方被类型系统推着走：拿到 `Result<int>` 不检查 `Ok` 就取 `Value`，编译器会提醒（Value 可空）。第 05 章的 record 值相等 + 第 10 章的可空注解在这里各尽其职。

## 6. 什么时候抛异常

分界判据（对照第 10 章"找不到"一节）：

| 情形 | 工具 | 例 |
|---|---|---|
| 失败是**正常业务分支**（调用方应该处理） | 返回 TryParse/Result/可空 | 解析输入、查字典、查用户 |
| 失败意味着**程序自身坏了**（调用方救不了） | `throw` | 参数为 null（`ArgumentNullException.ThrowIfNull`）、不变量被破坏 |
| **跨越许多层的故障传播** | 异常（免层层透传） | IO 中断、数据库连不上 |

判断口诀：**"调用方会不会 if 处理它？"会 → 返回值；不会/救不了 → 异常**。

## 7. 坑位清单

1. **`catch (Exception)` 吞一切**：最外层之外出现它 = 掩盖 bug。真需要兜底也要记日志 + `throw;` 重抛。
2. **空 catch 块**：`catch { }` 连日志都没有——出了问题零线索，生产环境头号悬案制造者。
3. **finally 里 return/throw**：会"吃掉"正在传播的异常，C# 允许但绝对是坑（部分语言直接禁止）。
4. **异常做流程控制**：循环里靠抛异常跳出，性能（栈展开 + 构造异常对象）和可读性双输——可预期分支走返回值。
5. **异步里的异常**：async 方法抛出的异常存在返回的 Task 里，**不 await 就看不到**（第 13 章坑位清单第 3 条）——`Task` 不是 fire-and-forget。
6. **异常消息没上下文**：`throw new Exception("失败")` 不如带上"哪个输入、哪个环节"——异常是给未来排障的自己看的。
