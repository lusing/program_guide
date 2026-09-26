# 13 · 委托

> 对应示例：`examples/13_delegates`

> **本章你将学会**：委托的类型本质、Action/Func/Predicate 三件套、多播、委托 vs 接口的选型。
> **前置章节**：[12 泛型](12-generics.md)。

## 1. 委托是什么：方法成了"值"

变量装数据，委托装**方法**——把"做什么"像数据一样传来传去：

```csharp
delegate int MathOp(int a, int b);          // 声明：这一族方法的类型签名

MathOp add = static (a, b) => a + b;        // 装一个 lambda（第 15 章）
MathOp mul = static (a, b) => a * b;

static int Run(MathOp op, int x, int y) => op(x, y);   // 方法作参数

Run(add, 3, 4);     // 7 —— 策略由调用方注入
Run(mul, 3, 4);     // 12
```

`Run` 不写死算法——**算法作为参数进来**。这个"策略注入"模式就是委托的日常：排序的比较器、按钮的点击处理（WPF）、LINQ 的过滤条件（第 16 章）全在用它。

心智模型：**委托 = 类型安全的函数指针 + 可组合（多播）**。类型安全指签名必须严格匹配——`MathOp` 装不下 `void F()`。

## 2. 内置三件套：别自己声明

`System` 命名空间把常用签名都备好了（都带泛型，0~16 个参数）：

```csharp
Action<string> print = s => ...;            // 无返回（0~16 参数版）
Func<int, int, int> sum = (a, b) => a + b;  // 有返回（最后一个类型参数是返回值）
Predicate<int> isEven = n => n % 2 == 0;    // 等价 Func<int, bool>（历史产物）
```

**只有特殊签名（ref/out 参数、可选参数）才自己声明 delegate**，其余一律 Action/Func——通用类型让 API 之间互通（人家的 `Func<int,bool>` 直接塞你的参数位）。

## 3. 多播委托：一串方法一次调

`+=` / `-=` 组装调用链，调用时**按顺序全跑**：

```csharp
Notification notify = Channels.SendEmail;    // 方法组转换：直接给方法名
notify += Channels.SendSms;
notify += static m => Console.WriteLine($"[日志] {m}");

notify("服务器告警");        // 三个方法依次执行
Console.WriteLine(notify.GetInvocationList().Length);   // 3

notify -= Channels.SendSms;  // 退订
```

三个须知：

1. **方法组转换**（直接写方法名）比包一层 lambda 更高效且可退订——lambda 每次 `+=` 都是新实例，`-=` 退不掉别人的 lambda
2. 多播的**返回值只保留最后一个**（有返回值的多播没意义，别用）
3. 一个抛异常**断链**——后面的订阅者不执行；需要全跑完用 `GetInvocationList()` 逐个 try（第 14 章事件同款问题）

多播是**事件（第 14 章）的底层机制**——event 就是对多播委托加了访问控制的外壳。

## 4. 委托的解剖：签名、目标、方法

一个委托实例内部装两样：**目标对象**（Target，实例方法的 this；静态方法为 null）+ **方法信息**（Method）。所以委托既能引用静态方法也能引用实例方法，比较相等 = 目标和方法都相同。理解了这一点，`notify += SomeInstance.Handler` 之后再 `-=` 才能对上号（同一个实例的同一个方法）。

## 5. 委托 vs 接口：策略的两种表达

同一个需求（可定制的行为）两条路：

```csharp
Array.Sort(data, (a, b) => b.CompareTo(a));          // lambda：一句话的策略
list.Sort(StringComparer.OrdinalIgnoreCase);          // 对象：有状态/可复用的策略
```

| | lambda/委托 | 接口 |
|---|---|---|
| 表达力 | 一个操作 | 一组相关操作 |
| 状态 | 闭包捕获（第 15 章） | 实现类字段 |
| 样板量 | 一行 | 一个类型 |
| 适用 | 一次性、局部、小逻辑 | 多方法契约、跨类复用、需 DI 替换 |

选型口诀：**一个动作用委托，一族行为用接口**。BCL 的示范：`Comparison<T>`（委托）满足轻量排序，`IComparer<T>`（接口）承载复杂比较器——两个都留着就是这个原因。

## 6. 委托在框架里的三个出镜位

1. **事件**（第 14 章）：`EventHandler<T>` 就是委托
2. **LINQ 全家**（第 16 章）：`Where(Func<T,bool>)`、`Select(Func<T,TResult>)`——你写的每个 lambda 都从这进来
3. **回调 API**：`Task.Run(Action)`、`List.ForEach(Action<T>)`、异步续体

## 常见坑

**签名差一点就装不进**：参数个数/类型/返回值任一不同 → 编译错误。委托类型系统是严格的（这是特性）。

**多播里一个抛全线停**：异常从链中间抛出，后续不执行——要求"全部执行完"的场景用 GetInvocationList 逐个调用 + 各自 try/catch。

**lambda +=/-=` 退订失败**：两个相同写法的 lambda 是不同实例。要退订就用**具名方法或先存变量**再 += -= 同一变量。

**在循环里创建委托捕获循环变量**：第 15 章闭包的主坑，这里先记索引——多播 + 闭包 = 双倍惊喜。

**Action 无返回还想要结果**：改 `Func<T>`——签名选错是设计期就错的信号。

## 实战建议

- API 设计：接受 `Action<T>`/`Func<T,TResult>` 而不是自定义 delegate 类型——与生态互通
- 多播只在事件场景用；普通调用链显式写三个调用更清晰
- 策略参数默认给重载：`Sort(list)` 用默认 + `Sort(list, comparison)` 注入——BCL 的标准做法
- 委托判 null 再调用：`notify?.Invoke(msg)`——多播可能一个订阅者都没有

## 自测

1. **委托与接口在表达"策略"时的分界？** —— 单个动作用委托（lambda 一行）；一族行为用接口。
2. **多播调用链的两个坑？** —— 中途异常断链；返回值只留最后一个。
3. **为什么退订要用具名方法/存变量？** —— lambda 每次新建实例，-=` 对不上号。
4. **Action 与 Func 的分界？最后一个类型参数是什么？** —— 无返回 vs 有返回；Func 的最后一个是返回类型。

---
上一章：[12 泛型](12-generics.md) ｜ 下一章：[14 事件](14-events.md) ｜ 返回：[README](../README.md)
