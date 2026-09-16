# 07 · 委托、lambda 与事件：把方法当值传

> 对应示例：`examples/07_delegates`

## 1. 方法的类型

回调和策略模式都需要"把一段行为传给别人"——C# 里承载行为的类型就是**委托**（delegate）。语言层面可以 `delegate int Op(int a, int b);` 自定义委托类型，但现代 C# 几乎只用 BCL 内置的两个泛型委托家族：

```csharp
Func<int, int, int> add = (a, b) => a + b;              // Func<入参…, 返回值>
Action<string> print = msg => Console.WriteLine(msg);   // Action<入参>：无返回值
```

- `Func<T>` 最后一个类型参数是返回值，前面全是入参：`Func<int,int,int>` = 两个 int 进、一个 int 出。
- `Action<T>` 无返回值版本；无参无返回就是 `Action`。
- 另有 `Predicate<T>`（等价 `Func<T,bool>`）在 List 的查找 API 里出没。

示例开头就展示了"变量装着方法"：

```csharp
Console.WriteLine(add(2, 3));     // 5——像调用普通方法一样调用委托
print("hello delegates");
```

## 2. lambda：写匿名方法的语法

`(a, b) => a + b` 是 **lambda 表达式**：左边参数表、右边表达式（或 `{ …; return …; }` 语句体）。它没有名字，编译器把它变成一个委托实例。等价的老写法（匿名方法）`delegate (int a, int b) { return a + b; }` 仍能见到，读得懂即可。

类型推断规则：委托变量已声明类型（上例 `Func<int,int,int>`），所以 lambda 参数不用写类型。直接传给泛型方法时也大多能推断出来。

## 3. 闭包：捕获的是变量，不是快照

示例里最值得反复看的一段：

```csharp
int factor = 3;
Func<int, int> multiply = x => x * factor;              // 闭包：捕获的是变量本身
factor = 10;
Console.WriteLine(multiply(5));                         // 50 而不是 15
```

lambda 捕获的不是"捕获那一刻的值 3"，而是**变量 factor 本身**。之后 factor 改成 10，multiply 的行为随之变化——输出 50。这是闭包的语义（JS/Python 相同），也是强大与危险的同源：

- 强大：回调天然带着上下文（循环里为每个元素捕获各自的临时变量）。
- 危险：捕获**生命周期意外延长**的变量（被闭包引用的对象无法被 GC）、并发场景下闭包改共享变量（第 14 章的主角）。

## 4. 事件：受限的委托字段

示例的后半段是一个完整的事件模型：

```csharp
var cart = new Cart("cart-001");
cart.PriceChanged += name => Console.WriteLine($"[通知] {name} 价格已更新");
cart.PriceChanged += name => Console.WriteLine($"[审计] {name} 价格已更新");

cart.Price = 100m;                                      // 一次赋值，两个订阅者都被调用
cart.Price = 120m;
```

发布方（Cart）的定义：

```csharp
class Cart(string id)
{
    private decimal _price;

    public string Id { get; } = id;

    public decimal Price
    {
        get => _price;
        set
        {
            if (_price == value) return;
            _price = value;
            PriceChanged?.Invoke(Id);      // ?. 触发：没有订阅者时避免 NullReferenceException
        }
    }

    public event Action<string>? PriceChanged;   // 事件：外部只能 += / -=，不能直接调用
}
```

读懂四件事：

1. `event` 是给委托字段加**访问限制**的关键字：外部只能 `+=`（订阅）/ `-=`（退订），不能赋值、不能清空、不能自己 Invoke——"谁都能喊一声价格变了"会被封死。
2. 触发方用 `PriceChanged?.Invoke(Id)`：事件字段默认 null，`?.` 保证没订阅者时不炸。
3. 委托是**多播**的：`+=` 两次就挂了两个订阅者，Invoke 时按订阅顺序全部调用（输出里每次价格变化打印两行）。
4. 惯用法模板：属性 setter 里"值没变就不发；变了就先改再发"，事件参数带上语境（这里是 Id）。

事件在 UI 框架（WPF/WinForms）与解耦组件间通信里到处都是；服务端代码更多直接用 `Func`/`Action` 参数或接口（第 04 章），event 见得少但必须认识。

## 5. 高阶函数：行为作参数

示例末尾两个小函数，是 LINQ 的原型：

```csharp
static int Apply(int input, Func<int, int> transform) => transform(input);

static List<T> Filter<T>(IEnumerable<T> source, Func<T, bool> predicate)
{
    var result = new List<T>();
    foreach (var item in source)
    {
        if (predicate(item)) result.Add(item);
    }
    return result;
}

Console.WriteLine(Apply(3, x => x * 10));                                  // 30
Console.WriteLine(string.Join(",", Filter(new[] {1, 2, 3, 4, 5}, x => x % 2 == 0)));   // 2,4
```

`Filter` 就是**你亲手写的 `Where`**：遍历 + 把"留不留"这个决策外包给调用方传入的谓词。下一章讲集合、再下一章 LINQ——本质都是把本章的模式产品化。

## 6. 坑位清单

1. **忘退订事件 = 内存泄漏**：订阅者被事件发布方引用着，GC 不走。长生命周期对象（单例服务、静态事件）上订阅，务必在 Dispose/关闭时 `-=`。
2. **多播委托的返回值**：多个订阅的 Func 只保留**最后一个**的返回值，前面的全丢——需要多个结果用事件参数收集或改用接口回调列表。
3. **闭包改捕获变量**：lambda 里 `factor++` 改的是外部变量本体；多个 lambda 捕获同一变量时互相可见对方的修改。
4. **循环变量捕获**：`foreach` 的迭代变量每次迭代是新变量（C# 5 起）；但 `for` 的 `int i` 是同一个——`for` 里捕获 i 且 lambda 延迟执行时，十个 lambda 看到的都是最终的 i。老坑，for 循环里先 `var copy = i;`。
5. **事件触发时的订阅者异常**：多播 Invoke 遇到某个订阅者抛异常，后面的订阅者不执行——关键路径上逐个 try/catch（`GetInvocationList()` 遍历）。
