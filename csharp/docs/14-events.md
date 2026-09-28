# 14 · 事件

> 对应示例：`examples/14_events`（股价变动的完整发布-订阅链路）

> **本章你将学会**：发布-订阅模式、event 关键字的保护语义、EventHandler<T> 标准签名、触发事件的规范三步、IObservable 可组合事件流。
> **前置章节**：[13 委托](13-delegates.md)。

## 1. 事件解决什么问题

一个对象状态变了，**一群**关心它的对象都想被通知——但状态拥有者不想（也不该）认识每一个订阅者。发布-订阅（pub/sub）：

```text
发布者 PriceTicker           订阅者们（互不相识）
   │  "价格变了"                │ 记录器：写日志
   │ ────────────────────────► │ 快讯器：发推送
   │        event 广播          │ 分析器：算指标
```

对比直接调用的两个收益：**发布者与订阅者解耦**（新增订阅者零改动发布者）；**一变多播**（一次触发 N 方响应）。委托（第 13 章）的多播是它的机制底座，事件在其上加了一层**访问控制**。

## 2. 完整实现：三件套

示例 `PriceTicker` 的标准结构：

```csharp
// ① 事件数据：携带发生了什么（只读、继承 EventArgs）
class PriceChangedEventArgs(decimal oldPrice, decimal newPrice) : EventArgs
{
    public decimal OldPrice { get; } = oldPrice;
    public decimal NewPrice { get; } = newPrice;
    public double DeltaPercent => ...;
}

// ② 发布者
class PriceTicker(string symbol)
{
    public event EventHandler<PriceChangedEventArgs>? PriceChanged;   // ★ event 字段式声明

    public void UpdatePrice(decimal newPrice)
    {
        if (newPrice <= 0) throw new ArgumentOutOfRangeException(nameof(newPrice));
        var old = _price;
        _price = newPrice;
        // ③ 触发的规范三步（见第 4 节）
        PriceChanged?.Invoke(this, new PriceChangedEventArgs(old, newPrice));
    }
}
```

```csharp
// 订阅方
ticker.PriceChanged += OnPriceChanged;                     // 订阅
ticker.PriceChanged += (sender, e) => Console.WriteLine(...); // lambda 也可以
ticker.UpdatePrice(201.5m);                                 // 触发——两个订阅者都被调
ticker.PriceChanged -= OnPriceChanged;                      // 退订
```

## 3. event 关键字加了哪道锁

`event` 声明的字段式事件，编译器生成**私有的委托字段 + 公开的 add/remove 访问器**。对比裸委托字段：

| 操作 | 裸委托字段 | event |
|---|---|---|
| 外部 `+=` / `-=` | ✓ | ✓ |
| 外部 `Invoke` 触发 | ✓（**任何人能伪造事件**） | ✘ 编译错误 |
| 外部 `= null` 清空订阅表 | ✓（**毁灭性**） | ✘ |
| 发布者内部触发 | ✓ | ✓ |

**触发权独占给发布者、订阅表只能增删**——事件 = 受保护的多播。不用 event 也能凑合（裸委托 +=），但等于把广播电台的话筒交给了路人。

## 4. 触发的规范三步

```csharp
PriceChanged?.Invoke(this, new PriceChangedEventArgs(old, newPrice));
```

拆开是三个纪律：

1. **局部快照**（多线程下防止触发瞬间订阅表被改）：严谨写法 `var handler = PriceChanged; handler?.Invoke(...)`
2. **`?.` 空条件**：零订阅者时不空引用
3. **`this` 作 sender**：订阅者拿到"谁发的"

配套约定：EventArgs 数据**只读**（事件是广播不是传话筒）；先改完状态再触发（订阅者回调里读状态应看到新值）；触发方法内**不要 try/catch 吞掉订阅者异常**——让上层决定（或用 GetInvocationList 隔离，见第 13 章坑）。

## 5. EventHandler<T>：全框架的标准签名

```csharp
public event EventHandler<PriceChangedEventArgs>? PriceChanged;
//          └──── 签名：(object? sender, TEventArgs e)
```

- `sender`：发布者自己（订阅者一个处理器可服务多个源，用 sender 区分）
- `e`：事件数据（`EventArgs.Empty` 表示"没有额外数据"）

统一签名的价值：**任何事件处理器都是这个形状**——处理器跨事件复用、泛型工具（如 WeakEventManager）得以存在。老式 `delegate void PriceHandler(...)` 自定义签名已被淘汰，新代码一律 `EventHandler<T>`。

## 6. 事件的生命周期与泄漏

**订阅即持引用**：`ticker.PriceChanged += window.Handler` 后，ticker 持有 window——window 想被回收必须先退订。WPF/WinForms 长生命周期对象订阅短生命周期对象是**经典内存泄漏**（WPF 教程 08 章的同款坑）。

三条纪律：

1. **订阅方销毁前退订**（Dispose/窗口关闭事件里 `-=`）
2. **lambda 订阅要能退**：先存变量 `EventHandler h = (s,e) => ...; obj.Ev += h; ... obj.Ev -= h;`
3. 短命对象别订阅长命对象的全局事件；反过来（长订阅短）才安全

## 7. IObservable&lt;T&gt;：可组合的事件流

事件的进化形态是 BCL 内置的 `IObservable<T>`/`IObserver<T>`（System 命名空间，零依赖）。《Concurrency in .NET》第 6 章给了它一个精准的定位：**IObservable 是 IEnumerable 的对偶**——

```text
IEnumerable<T>：消费者主动 pull（foreach 一个一个要）
IObservable<T>：生产者主动 push（OnNext 一个一个推）
```

推送模型换来的是**LINQ 级的组合能力**。订阅者实现三个方法：`OnNext`（来了一条）、`OnError`（流出错）、`OnCompleted`（流结束——这是 event 没有的语义，事件永远不知道"以后没有了"）。示例手写了最小实现（生产代码用 Rx 库）：

```csharp
var prices = new Subject<decimal>();                     // 发布端：OnNext/OnCompleted
using var sub = prices
    .WhereR(p => p >= 200m)                              // 只放行 200 以上的
    .SelectR(p => $"高价 {p:F1}")                         // 再加工成消息
    .Subscribe(new PrintObserver());                     // 订阅
foreach (var p in new[] { 198.0m, 203.2m, 201.5m, 42m }) prices.OnNext(p);
prices.OnCompleted();
```

实测输出：

```text
[订阅] 高价 203.2
[订阅] 高价 201.5
[订阅] 流结束（OnCompleted）
```

三个对照记忆点：

- **退订是句柄**：`Subscribe` 返回 `IDisposable`，`Dispose` 即退——比事件的 `-=` 更工程化（F# 教程 18 章有同一主题的 F# 形态）
- **`WhereR`/`SelectR` 是手写教学版**：把 `IObservable` 的 `Subscribe` 接到"变换/筛选后的观察者"上；**Rx（System.Reactive NuGet 包）把整套 LINQ 都做成了推送版**（`Where/Select/Buffer/Throttle/Scan...`），股价、传感器、消息流这类"持续到来的事件序列"是它的主场
- 与第 18 章迭代器互为镜像：pull 世界靠 `yield return`，push 世界靠 `OnNext`；两边的组合子形状一模一样

## 常见坑

**忘退订导致对象长存**：第 6 节——"窗口关了怎么内存还在涨"的第一嫌疑人。

**在构造函数里触发事件**：订阅者还没机会订阅，白触发；且虚成员/事件在构造期都是雷区（第 09 章同理）。

**事件数据可变**：订阅者 A 改了 e 的字段，订阅者 B 看到被污染的数据——EventArgs 全只读。

**触发了但没订阅者**：直接 `.Invoke(...)` 空引用——永远 `?.Invoke`。

**接口里的事件忘了实现**：接口可以声明 event（实现类必须提供 add/remove 或字段式声明）——接口事件的订阅是解耦的更强形态。

## 实战建议

- 事件命名：**过去式或 PropertyChanged 式**（PriceChanged/FileLoaded）；数据类 XxxEventArgs；用 EventHandler<T>
- 触发点收敛在一个方法里（如 `OnPriceChanged(args)` 的 protected virtual 方法）——子类可覆写触发行为，这是框架（WPF）的标准姿势
- 一对多通知用事件；请求-响应别用事件（返回值/时序难处理）——用方法调用或 Task
- 现代 UI 框架（WPF/MAUI）的事件系统之上还有命令/绑定（WPF 教程 12 章），但底层全是本章机制

## 自测

1. **event 相比裸委托字段多了什么保护？** —— 外部只能 +=/-=；不能触发、不能清空——触发权归发布者。
2. **EventHandler<T> 的标准签名两部分各是什么？** —— (object? sender, TEventArgs e)：谁发的 + 发生了什么。
3. **触发事件的三个纪律？** —— 快照、?.、this 作 sender。
4. **事件怎么会造成内存泄漏？** —— 订阅即持引用；短命订阅者挂在长命发布者上就回收不了——退订。
5. **IObservable 与事件的核心差异？** —— push 模型可像 LINQ 一样组合，且有 OnCompleted「流结束」语义；退订变成 IDisposable 句柄。

---
上一章：[13 委托](13-delegates.md) ｜ 下一章：[15 Lambda 与闭包](15-lambdas.md) ｜ 返回：[README](../README.md)
