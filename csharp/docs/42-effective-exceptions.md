# 42 · Effective C#·异常设计（条 45-50）

> 对应示例：`examples/42_effective_exceptions`

> **本章你将学会**：异常 vs 错误码 vs Try 方法的分界、为应用创建专属异常（按处理方式分型 + 异常转换）、三级异常保证与「拷贝-处理-替换」、异常筛选器保住栈现场的原理、筛选器副作用做日志钩子与调试器门禁。这是全书的收束章。
> **前置章节**：[22 异常处理](22-exceptions.md)。

[22 章](22-exceptions.md)讲了异常的机制（栈展开、throw; vs throw ex;、when 过滤器、自定义异常的基础）；本章是《Effective C#》第 5 章的**设计层**——异常什么时候抛、抛什么类型、抛出时对程序状态许下什么承诺。

## 1. 条 45：方法契约被违背时抛异常——并提供「先试后做」路径

异常与错误码的分界不是「能不能」，而是**谁负责传播**：

- 错误码：每个调用方都得检查并手动上抛——忘了就吞错，写对了又污染主逻辑
- 异常：自动沿调用栈上浮直到合适的 catch——抛出点与处理点可以隔着好几层

但**正常流程不该用异常当控制流**（抛异常的开销比普通方法调用大几个数量级）。所以给「可预期的失败」提供测试路径：

```csharp
public void DoWork(bool widgetsReady)
{
    if (!widgetsReady) throw new InvalidOperationException("部件未就绪");   // 执行版：违约才抛
    ...
}
public bool TryDoWork(bool widgetsReady)                      // 试探版：同一失败返回 false
{
    if (!widgetsReady) return false;
    DoWork(widgetsReady: true);
    return true;
}
```

BCL 的同款配对：`File.Open`（抛）↔ `File.Exists`（查）、`int.Parse`（抛）↔ `int.TryParse`（试）、`Dictionary[key]`（抛）↔ `TryGetValue`（试）。判据是**约定是否完成**：`File.Exists` 无论文件在不在都完成了「告诉我结果」的约定（不抛）；`File.Open` 约定是「打开文件」，文件不在就是违约（抛）。

## 2. 条 47：为应用程序创建专属异常

分型的依据**不是错误的来源**，而是**调用方能不能用不同的办法恢复**：

```text
找不到配置文件 → 回落默认值      → ConfigurationNotFoundException（可恢复）
网络断连      → 重试/进降级队列  → DownstreamUnavailableException（可恢复）
数据损坏      → 停机报警          → DataCorruptedException（不可恢复）
```

能用不同办法恢复 → 各建一个类型（catch 按类型分派策略）；只能一样处理 → 合成一个类型（类型爆炸同样害人）。**不要直接抛 `Exception`**——调用方除了终止什么也做不了。

**异常转换（translate）**：底层异常包进领域异常、根因放进 InnerException：

```csharp
try { SimulateRemoteCall(); }
catch (TimeoutException inner)
{
    throw new DownstreamUnavailableException("支付通道暂不可用", inner);   // 调用方按业务语义 catch
}
// 排查时 ex.InnerException 挖到 TimeoutException: 上游 30s 无响应（实测）
```

实现惯例：无参/带消息/带 InnerException 三个构造函数配齐。书（2016 年）还要求第四个「序列化构造函数」——**实测在 .NET 8+ 已过时**（SYSLIB0051 警告，二进制异常序列化被淘汰），现代 .NET 不再写它：这是「书本时代 vs 当前 API」的一个典型演化点。

## 3. 条 48：优先做出强异常保证

三级保证（源自 C++ 时代的 Abrahams 分类）：

| 级别 | 承诺 |
|---|---|
| 基本保证 | 不泄漏资源、对象处在有效状态（可能已部分修改） |
| **强保证** | **要么完全成功，要么程序状态与执行前完全相同** |
| no-throw | 绝不抛出 |

强保证的实现公式——**拷贝、处理、替换**：

```csharp
public void ApplyAll(Func<Entry, Entry> f)
{
    var updated = new List<Entry>(Items.Count);   // ① 拷贝目标
    foreach (var e in Items) updated.Add(f(e));   // ② 在副本上做可能抛的操作
    Items.Clear();                                // ③ 全部成功才用 no-throw 的方式替换
    Items.AddRange(updated);
}
```

示例实测对照（账本 [1, -2]，翻倍操作遇到负数抛异常）：

```text
强保证版（拷贝-处理-替换）: [1,-2]  ← 全是旧值，干净回滚
原地修改版（for 循环里改）: [2,-2]  ← 第 1 笔已改、第 2 笔没改——半个状态
```

LINQ 的「返回新序列」风格天然带强保证（条 39 的呼应）。**no-throw 的四个特例**：`Dispose`、终结器、`when` 筛选器表达式、委托目标——这四个地方抛异常会造成「异常吃异常」，处理起来最痛苦。

引用类型的坑：替换的是**引用**还是**数据**？`data = temp` 只换了字段指向，别人手里的旧引用看不到新数据——要真正替换得清空+回填（或上信封-信纸模式封装替换逻辑）。

## 4. 条 49：异常筛选器代替「捕获再重抛」

```csharp
catch (ArgumentException ex) when (ex.ParamName is not null && ex.ParamName.Length > 0)
{
    // 筛选器在栈展开【前】评估——false 时这个 catch 形同不存在，继续往上找
}
catch (ArgumentException ex)
{
    if (ex.ParamName is null) throw;      // 反面教材：先进 catch（栈已展开），再判断，再重抛
}
```

两种写法的差异（实测）：

- **现场**：筛选器版报告的栈顶是**原始抛出点**（`at ...CrashesWith|0_4(Int32 mode) in Program.cs:line 85`）；先捕后抛版报告的位置变成了 `throw` 所在行——原始现场被栈展开冲掉，局部变量也难查
- **性能**：筛选器 false 时**不展开栈**，CLR 对此有专门优化——无论如何不比先捕后抛差

典型场景全是「类型相同、内容不同」：`Task.Exception` 是 AggregateException 要筛 `InnerExceptions`、`COMException` 筛 HResult、HTTP 异常筛状态码。**只用异常类型不足以判断「我能不能处理」时就上 when**。

## 5. 条 50：筛选器的副作用妙用

筛选器「栈展开前评估」的特性可以故意利用——**写一个永远返回 false 的筛选器**：

```csharp
private bool Log(Exception e)
{
    Console.WriteLine($"记录异常 #{++_faults}: {e.GetType().Name}");
    return false;                                  // 永远 false → 永不拦截
}

try { action(); }
catch (Exception e) when (Log(e)) { }               // 记完账，异常继续上抛
```

实测：日志先打（`[when Log] 记录异常 #1`），随后业务侧的 catch 正常收到——**不打扰任何流程就把路过的异常全记了账**（含最终没人处理的）。它比「在顶层统一 catch 记日志」多了不干扰别人处理的优点，比「每个 throw 前打日志」少了侵入性。

另一个官方技巧——**调试器门禁**：

```csharp
catch (TimeoutException) when (failures++ < 10 && !Debugger.IsAttached)
```

调试器连着时 `Debugger.IsAttached == true` → 筛选器 false → 异常不被吞、断点直接停在抛出点。注意它看的是**运行期状态**，与 Debug/Release 构建配置无关。

## 6. 全书 50 条收束

《Effective C#》50 条至此全部落位（条 11/17 在 [25 章](25-gc.md)、机制基础在对应语言章）。三条心法贯穿：

1. **语言习惯（条 1-10，[38 章](38-effective-habits.md)）**：让编译器替你把关——var 保留最强类型、readonly 管可变常量、is/as 防转换事故、?.Invoke 治事件竞态
2. **初始化与生命周期（条 12-16，[39 章](39-effective-lifecycle.md)）**：顺序有表可查（8 步）、重复用链式删、分配能省则省
3. **泛型 / LINQ / 异常（条 18-50，[40](40-effective-generics.md)/[41](41-effective-linq.md)/本章）**：约束够用就好、查询默认惰性、异常做保证

公共内核一句话：**把假设写进类型系统（约束/断言式 API），把不变量留给运行时验证（探测/筛选器），把状态变化做成原子步骤（拷贝-处理-替换 / 返回新序列）**。

## 常见坑

**用异常做正常分支控制**：每次抛/捕都贵——可预期失败配 Try/Exists 路径（条 45）。

**直接抛 Exception 或按 Message 字符串分派**：调用方没法按类型恢复（条 47）——按「处理方式」建类型。

**循环里原地修改、中途抛异常**：半个状态无法回滚——拷贝-处理-替换（条 48 实测对照）。

**catch 里 if 判断再 throw**：原始现场被栈展开冲掉——换 when 筛选器（条 49）。

**Dispose/终结器/筛选器/委托目标里抛异常**：异常吃异常——这四处必须 no-throw。

**照老书给异常加序列化构造函数**：.NET 8+ 已淘汰（SYSLIB0051），删掉（条 47 的时代差异）。

## 实战建议

- 每个「会失败的操作」都想一遍：这个失败对调用方是可预期的吗？是 → 配 Try 版；否 → 抛
- 领域异常层次按「恢复策略」划分，用 InnerException 保留根因链（异常转换）
- 修改多个对象/集合的操作默认强保证写法（副本上做，成了才替换）
- catch 子句尽量带 when——类型不足以表达「能不能处理」时就该写条件
- 全局异常日志可以考虑 false 筛选器钩子；调试痛点用 Debugger.IsAttached 门禁

## 自测

1. **异常 vs 错误码的本质优势？** —— 自动沿栈传播（抛出点与处理点解耦）+ 不处理就崩溃（不会静默吞错）。
2. **专属异常按什么分型？** —— 调用方的恢复方式（能不同办法恢复 → 不同类型），不是错误来源。
3. **强保证的公式与实测差异？** —— 拷贝-处理-替换；实测原地修改版留下 [2,-2] 半状态、强保证版干净回滚 [1,-2]。
4. **when 筛选器比「catch 里判断重抛」好在哪？** —— 栈展开前评估：false 时不展开栈，原始现场完整保留，还有性能优化。
5. **no-throw 的四个特例？** —— Dispose、终结器、when 表达式、委托目标（含事件处理器）。

---
上一章：[41 Effective C#·LINQ 惯用法](41-effective-linq.md) ｜ 返回：[README](../README.md)
