// 07_delegates：委托、lambda 与事件——LINQ 与回调的前置课
Func<int, int, int> add = (a, b) => a + b;              // Func<入参…, 返回值>
Action<string> print = msg => Console.WriteLine(msg);   // Action<入参>：无返回值

Console.WriteLine(add(2, 3));
print("hello delegates");

int factor = 3;
Func<int, int> multiply = x => x * factor;              // 闭包：捕获的是变量本身
factor = 10;
Console.WriteLine(multiply(5));                         // 50 而不是 15

var cart = new Cart("cart-001");
cart.PriceChanged += name => Console.WriteLine($"[通知] {name} 价格已更新");
cart.PriceChanged += name => Console.WriteLine($"[审计] {name} 价格已更新");

cart.Price = 100m;                                      // 一次赋值，两个订阅者都被调用
cart.Price = 120m;

Console.WriteLine(Apply(3, x => x * 10));
Console.WriteLine(string.Join(",", Filter(new[] {1, 2, 3, 4, 5}, x => x % 2 == 0)));

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
