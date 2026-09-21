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
