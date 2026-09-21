# 22 · 异常处理

> 对应示例：`examples/22_exceptions`

> **本章你将学会**：try/catch/finally 与异常过滤器、栈展开与异常链、throw; vs throw ex;、自定义异常、异常 vs 返回值的决策线。
> **前置章节**：[04 方法](04-control-methods.md)、[21 防御编程](21-nullable.md)。

## 1. 异常的定位：意外，不是流程

C# 的两条错误通道：

| | 返回值/TryXxx | 异常 |
|---|---|---|
| 语义 | **可预期**的失败（文件不存在、格式不对、没找到） | **意外**状态（不变量被破坏、环境崩了） |
| 调用方 | 必须看返回值处理 | 不处理就上抛 |
| 性能 | 零开销 | 抛出时收集栈——贵（别当 goto 用） |
| 例子 | `int.TryParse`、`dict.TryGetValue` | 磁盘消失、配置不变量破裂、数据库连接中断 |

**决策线一句话：调用方"大概率要处理且能处理"的失败 → 返回值；调用方处理不了或没想到的 → 异常**。用异常做流程控制（拿异常跳出循环）既慢又毁可读性。

## 2. 基本结构与过滤器

```csharp
try
{
    var result = 100 / divisor;
}
catch (DivideByZeroException ex) when (DateTime.Now.Year > 2000)   // when 过滤器
{
    // 只在异常"且"条件成立时进入这个 catch
}
finally
{
    // 无论如何执行：资源释放的兜底位（第 25 章 using 的地基）
}
```

- **catch 从上到下匹配**，先具体后宽泛（`DivideByZeroException` 在 `Exception` 前）；直接 `catch (Exception)` 是最宽的网（见坑节）
- **`when` 过滤器**先于进入 catch 体求值——用途：按条件分诊（同一异常类型不同处理）、过滤后落空的异常**保留栈继续上抛**（catch 进了再 throw 不如 when 干净）
- **finally 一定执行**（try 正常/catch 到/return/抛新异常都拦不住它）——只放"必须做的清理"，别放业务

## 3. 栈展开：异常一路上抛

异常没人 catch 时**沿调用链逐层弹出（栈展开）**，路过的 finally 逐个执行，直到进程顶层（崩溃）或某层接住：

```text
Level2 抛出 → Level2 的 finally → Level1 的 finally → 顶层 catch
```

示例用三层调用演示了 finally 的执行顺序。**每一层的清理逻辑随栈展开自动执行**——这就是资源安全的基础（RAII 心智：清理挂在 finally/using 上，而不是祈祷记得调 Close）。

## 4. throw; vs throw ex;（保不保栈）

```csharp
catch (Exception ex)
{
    Log(ex);
    throw;          // ✓ 重新抛出，原始调用栈完整保留
    // throw ex;    // ✘ 栈被重置到这一行——原始抛出点丢失，排查变盲
}
```

规则：**中间层转手异常一律 `throw;`**。`throw ex;` 只在"有意包装成新异常"时出现，且要带 inner：

```csharp
throw new AppException("订单处理失败", ex);    // ex 作 InnerException——异常链
```

异常链的价值：顶层日志能看到**完整因果**（示例打印 `InnerException?.Message`）——每一层包装回答"这层在干什么"，最内层回答"到底哪里坏了"。

## 5. 自定义异常

```csharp
public class AppException(string message, Exception? inner = null)
    : Exception(message, inner);
```

三条惯例：**后缀 Exception**；提供 (message) 与 (message, inner) 两个构造；继承合适的层级（业务根异常 → 各域异常）。什么值得自定义异常：调用方需要**按类型分诊处理**的错误（catch (PaymentException) 重试）。只为"信息好看"的自定义毫无价值——字符串进通用异常即可。

## 6. 全局兜底

进程总得有最后的网（记日志 + 决定生死）：

```csharp
AppDomain.CurrentDomain.UnhandledException += (_, e) => Log(e.ExceptionObject);
TaskScheduler.UnobservedTaskException += ...       // 第 29 章任务的丢失异常
```

WPF 教程 02 章的 `DispatcherUnhandledException` 是 GUI 版的同一个网。兜底层做三件事：**记完整信息（含栈与内部链）、给用户人话、决定继续还是退出**。

## 常见坑

**catch 后一声不吭（吞异常）**：`catch { }` 是调试黑洞——错误现场被抹掉，下游得到诡异数据。最低限度记日志。

**`throw ex;` 重置栈**：第 4 节——中间层一律 `throw;`。

**catch (Exception) 太早太宽**：在底层就网住所有异常 → 上层的分诊逻辑失效。**在"有能力处理的那一层"catch**，其余放行。

**finally 里 return/throw**：会吞掉正在传播的异常——finally 只做清理，永不返回。

**异常当返回值**：用异常表达"用户名已存在"这类预期失败——调用方只能 try/catch 处理业务，性能与可读性双输。换返回值/Result 型（TryXxx 模式）。

**丢 InnerException**：包装异常忘了带 inner——根因永久丢失。

## 实战建议

- API 设计的失败语义前置想清楚：TryXxx（可预期）/异常（意外），**别混用两套表达同一件事**
- 边界层（HTTP 入口/消息消费/任务循环）统一 try/catch + 日志 + 包装领域异常——内层代码得以只写"快乐路径"
- 日志要记 `ex.ToString()`（含栈与内部链），不是 `ex.Message`（后者只是半句话）
- 资源清理挂 using/finally（第 25 章），不依赖调用者记得 close
- 性能热路径里"可能频繁失败"的解析用 TryXxx 模式（第 03 章 TryParse 家族）

## 自测

1. **可预期失败与意外各走哪条通道？** —— 返回值/TryXxx；异常。
2. **when 过滤器比 catch 后 throw 好在哪？** —— 条件不满足时异常保留原始栈自然上抛，不污染。
3. **throw; 与 throw ex; 的区别？包装异常要带什么？** —— 前者保栈后者重置；InnerException。
4. **finally 的铁律？** —— 无论如何都执行；只放清理，不放 return/throw。

---
上一章：[21 可空引用类型](21-nullable.md) ｜ 下一章：[23 反射与特性](23-reflection-attributes.md)
