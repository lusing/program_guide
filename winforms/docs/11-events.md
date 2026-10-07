# 11 · 事件与委托深入

> 对应示例：`examples/11_events`（温度计事件源 + 双订阅者 + 解绑实验 + F# Observable 流处理）

> **本章你将学会**：EventHandler 模式、自定义事件、多播委托链、解绑、三语言事件接线对照、F# 的 Observable 组合子。
> **前置章节**：[03 窗体](03-forms.md)（用过 += 与 Add）。

## 1. 事件是"回调的工业化"

委托 = 类型安全的函数引用；事件 = **带访问控制的委托字段**（外部只能 `+=`/`-=`，不能invoke、不能清空）。WinForms 一切交互的底层都是它。

标准模式（.NET 约定）：

```csharp
public class TempEventArgs : EventArgs          // ① 数据包： EventArgs 派生
{
    public double Temp { get; }
    public double Delta { get; }
    public TempEventArgs(double temp, double delta) { Temp = temp; Delta = delta; }
}

public class Thermometer                        // ② 事件源
{
    public event EventHandler<TempEventArgs> Reading;    // ③ 泛型事件

    public void Poll()
    {
        …
        Reading?.Invoke(this, new TempEventArgs(next, delta));   // ④ this 当 sender
    }
}
```

**sender 塞 this** 不是仪式——订阅方靠它区分"事件来自哪个实例"（一个处理器订阅多个温度计时就是命根子）。

## 2. 多播：一个事件多个订阅者

```csharp
_thermo.Reading += OnReadingA;      // 订阅者 A：更新大数字
_thermo.Reading += OnReadingB;      // 订阅者 B：写日志 → 两个都会被依次调用（多播委托链）
```

调用顺序 = 订阅顺序（实现细节，别依赖，但要知道是"都会调"）。

## 3. 解绑：`-=` 的语义

```csharp
_thermo.Reading -= OnReadingB;      // 方法组再次出现，编译器合成"相等"的委托 → 能减掉
_thermo.Reading += OnReadingB;      // 重绑
```

C# 的方法组转换保证 `this.OnReadingB` 两次产生的委托**相等**（目标+方法都相同）——所以 `-=` 认得出。**lambda 解不掉**（每次 new 一个不相等的委托）：

```csharp
x.Click += (s, e) => Foo();    // 这个挂上就摘不下来了（除非留存引用）
EventHandler h = (s, e) => Foo();
x.Click += h;  …  x.Click -= h;   // 要解绑就先存变量
```

## 4. 三语言事件接线对照（本章核心表）

| | C# | F# | C++/CLI |
|---|---|---|---|
| 挂 lambda | `x.Click += (s,e) => …` | `x.Click.Add(fun _ -> …)` | 无 lambda：成员函数 + `gcnew EventHandler(this, &T::OnX)` |
| 挂方法 | `x.Click += OnClick`（方法组） | `x.Click.Add(OnClick)` | 同上 |
| 解绑 | `x.Click -= OnClick` | `x.Click.Remove(OnClick)` | `x->Click -= handler;`（**必须当初那个实例**） |
| 自定义事件 | `public event … ;` | `let ev = Event<_>()` + `[<CLIEvent>]` | `event EventHandler<T^>^ Ev;` |
| 触发 | `Ev?.Invoke(args)` | `ev.Trigger(args)` | `Ev(args);`（不能判空） |

## 5. C++/CLI 的大坑：解绑要缓存委托

```cpp
// ✘ 错：减不掉！gcnew 每次都是新委托实例，与当初 += 的那个"不相等"
_thermo->Reading += gcnew EventHandler<TempEventArgs^>(this, &MainForm::OnReadingB);
_thermo->Reading -= gcnew EventHandler<TempEventArgs^>(this, &MainForm::OnReadingB);

// ✔ 对：把当初 += 的实例缓存下来，解绑用同一个
_handlerB = gcnew EventHandler<TempEventArgs^>(this, &MainForm::OnReadingB);
_thermo->Reading += _handlerB;
_thermo->Reading -= _handlerB;
```

C# 靠编译器合成的委托相等；C++/CLI 的 `gcnew` 没这个待遇——**`-=` 认实例不认目标+方法对**。11 的 C++ 版用按钮实测"解绑后只剩大数字在动"。

另一个 C++/CLI 坑：**事件触发不能判空**：

```cpp
if (TitleChanged != nullptr) …   // ✘ C3918：事件不是数据成员
TitleChanged(msg);               // ✔ 直接调用，编译器合成的 raise_ 自带空调用保护
```

## 6. F# 的杀手锏：事件当流

F# 的 `IEvent<_>` 本身实现 `IObservable<_>`，能用组合子管道处理——**过滤、变换、合并写起来是声明式的**：

```fsharp
thermo.Reading                                  // IEvent<...> 就是 IObservable
|> Observable.filter (fun (_, t, _) -> t > 20.5)      // 只留高温
|> Observable.map (fun (_, t, d) -> …)                // 变换成消息
|> Observable.subscribe (fun msg -> form.Text <- msg) // 订阅
```

对照 C#/C++ 版的 if 判断塞进订阅者里——关注点分离到了操作符层。这来自 [fsharp 教程 18 章](../../fsharp/docs/18-interop.md)的同一套 `Observable` 组合子。

F# 自定义事件的标准三件：

```fsharp
type Thermometer(seed: int) as this =
    let reading = Event<Thermometer * float * float>()     // ① 内部 Event<_>
    [<CLIEvent>]                                            // ② 暴露成 .NET 事件（不加则 FS0859 接口不认）
    member _.Reading = reading.Publish
    member _.Poll() = … reading.Trigger(this, next, delta) // ③ 触发
```

## 7. 谁在订阅谁：生命周期

事件订阅是**强引用**——订阅者不 `-=`，事件源就拽着它不放手（窗体关闭了还被 Timer 拽着 = 内存泄漏 + 僵尸回调）。规矩：

- 短命对象订阅长命源：**Disposed/FormClosed 时解绑**
- 长命对象订阅短命源（主窗体订阅子窗体）：随它去，源死了引用自然断

## 坑位清单

1. C# lambda 挂事件解不掉——要解绑就先存委托变量。
2. C++/CLI `-= gcnew ...` 减不掉（实例不等）——缓存当初的委托。
3. C++/CLI 事件判空 C3918——直接调用。
4. F# 接口实现的事件成员缺 `[<CLIEvent>]` → FS0859。
5. 忘解绑 + 长命事件源 → 订阅者泄漏（附录级话题，规矩见 §7）。

## 自测

1. `event` 关键字比公开委托字段多限制了什么？
2. sender 参数的实际用途？两订阅者如何区分事件来自谁？
3. C# 的 `-=` 靠什么认出"当初那个"委托？C++/CLI 缺什么？
4. F# 的 `Observable.filter` 在 C# 里对应什么写法？
5. 短命订阅者挂长命源，规矩是什么？

---

上一章：[10 SDI 与 MDI](10-mdi.md) · 下一章：[12 GDI+ 基础](12-gdi-basics.md)
