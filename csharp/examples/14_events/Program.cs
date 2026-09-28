// 14 · 事件：发布-订阅的安全版委托
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 股票价格变动的完整链路 =====");
var ticker = new PriceTicker("AAPL");

// 订阅方 1：普通方法
ticker.PriceChanged += OnPriceChanged;
// 订阅方 2：lambda（即时行情）
ticker.PriceChanged += (sender, e) =>
    Console.WriteLine($"  [快讯] {(sender as PriceTicker)!.Symbol}: {e.OldPrice:F2} → {e.NewPrice:F2}");

ticker.UpdatePrice(201.5m);      // 触发 → 两个订阅者都被调用
ticker.UpdatePrice(203.2m);

// 退订（UI 场景：窗口关闭时必须退订，否则泄漏——WPF 教程 08 章的同款坑）
ticker.PriceChanged -= OnPriceChanged;
Console.WriteLine("  （已退订 OnPriceChanged）");
ticker.UpdatePrice(198.0m);      // 只剩快讯

Console.WriteLine();
Console.WriteLine("===== event 关键字加的那道锁 =====");
Console.WriteLine("  没 event：外部能直接调 yourDelegate(...) 伪造事件、能清空订阅表");
Console.WriteLine("  有 event：外部只能 += / -=，触发权只在发布者手里");

Console.WriteLine();
Console.WriteLine("===== EventHandler<T>：全框架的标准签名 =====");
Console.WriteLine("  (object? sender, TEventArgs e)：sender=谁发的，e=事件数据");
Console.WriteLine("  自定义事件数据继承 EventArgs（本例 PriceChangedEventArgs）");

Console.WriteLine();
Console.WriteLine("===== IObservable<T>：可组合的事件流 =====");
// 事件的对偶形态（BCL 内置接口，《Concurrency in .NET》第 6 章主题）：
// IEnumerable 是消费者 pull，IObservable 是生产者 push —— 而且像 LINQ 一样可组合
var prices = new Subject<decimal>();
using var sub = prices
    .WhereR(p => p >= 200m)               // 只放行 200 以上的
    .SelectR(p => $"高价 {p:F1}")          // 再加工成消息
    .Subscribe(new PrintObserver());       // 订阅：之后的价格由源头推送过来
foreach (var p in new[] { 198.0m, 203.2m, 201.5m, 42m }) prices.OnNext(p);
prices.OnCompleted();                      // 流的「结束」语义——event 没有这个概念
Console.WriteLine("  （WhereR/SelectR 是手写的推送版 LINQ 算子；Rx 库把整套 LINQ 都做成了推送版）");

static void OnPriceChanged(object? sender, PriceChangedEventArgs e)
    => Console.WriteLine($"  [记录] 价格变动 {e.OldPrice:F2} → {e.NewPrice:F2}（幅度 {e.DeltaPercent:+0.0;-0.0}%）");

class PriceChangedEventArgs(decimal oldPrice, decimal newPrice) : EventArgs
{
    public decimal OldPrice { get; } = oldPrice;
    public decimal NewPrice { get; } = newPrice;
    public double DeltaPercent => OldPrice == 0 ? 0 : (double)((NewPrice - OldPrice) / OldPrice * 100);
}

class PriceTicker(string symbol)
{
    private decimal _price;

    public string Symbol { get; } = symbol;

    // event 字段式声明：编译器生成私有的委托字段 + 公开的 add/remove
    public event EventHandler<PriceChangedEventArgs>? PriceChanged;

    public void UpdatePrice(decimal newPrice)
    {
        if (newPrice <= 0) throw new ArgumentOutOfRangeException(nameof(newPrice));
        var old = _price;
        _price = newPrice;
        // 触发模式：局部变量快照（防竞态）+ ?.（无订阅者不空引）
        PriceChanged?.Invoke(this, new PriceChangedEventArgs(old, newPrice));
    }
}

// ── IObservable 家族：教学手写版（生产代码用 System.Reactive 的 Subject/Observable）──
// 最小 Subject：既是 IObservable（可订阅）又是发布端（OnNext/OnCompleted）
class Subject<T> : IObservable<T>
{
    private readonly List<IObserver<T>> _observers = [];
    public IDisposable Subscribe(IObserver<T> observer)
    {
        _observers.Add(observer);
        return new Unsubscriber(_observers, observer);    // 退订有了「句柄」——比事件的 -= 更工程化
    }
    public void OnNext(T value)
    {
        foreach (var o in _observers.ToArray()) o.OnNext(value);   // 快照遍历：防触发瞬间订阅表被改
    }
    public void OnCompleted()
    {
        foreach (var o in _observers.ToArray()) o.OnCompleted();
    }
    sealed class Unsubscriber(List<IObserver<T>> observers, IObserver<T> observer) : IDisposable
    {
        public void Dispose() => observers.Remove(observer);
    }
}

// 推送版 LINQ 算子：Select（映射）
class MapObservable<T, R>(IObservable<T> source, Func<T, R> f) : IObservable<R>
{
    public IDisposable Subscribe(IObserver<R> down) => source.Subscribe(new Relay(f, down));
    sealed class Relay(Func<T, R> f, IObserver<R> down) : IObserver<T>
    {
        public void OnNext(T value) => down.OnNext(f(value));
        public void OnError(Exception e) => down.OnError(e);
        public void OnCompleted() => down.OnCompleted();
    }
}

// 推送版 LINQ 算子：Where（筛选）
class FilterObservable<T>(IObservable<T> source, Func<T, bool> pred) : IObservable<T>
{
    public IDisposable Subscribe(IObserver<T> down) => source.Subscribe(new Relay(pred, down));
    sealed class Relay(Func<T, bool> pred, IObserver<T> down) : IObserver<T>
    {
        public void OnNext(T value) { if (pred(value)) down.OnNext(value); }
        public void OnError(Exception e) => down.OnError(e);
        public void OnCompleted() => down.OnCompleted();
    }
}

static class ObservableOps
{
    public static IObservable<R> SelectR<T, R>(this IObservable<T> source, Func<T, R> f)
        => new MapObservable<T, R>(source, f);
    public static IObservable<T> WhereR<T>(this IObservable<T> source, Func<T, bool> pred)
        => new FilterObservable<T>(source, pred);
}

class PrintObserver : IObserver<string>
{
    public void OnNext(string value) => Console.WriteLine($"  [订阅] {value}");
    public void OnError(Exception e) => Console.WriteLine($"  [错误] {e.Message}");
    public void OnCompleted() => Console.WriteLine("  [订阅] 流结束（OnCompleted）");
}
