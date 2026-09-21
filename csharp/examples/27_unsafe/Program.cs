// 27 · unsafe 与互操作初窥：指针、fixed 与 P/Invoke
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== unsafe 块：拿到裸指针 =====");
unsafe
{
    int value = 42;
    int* p = &value;                 // 取地址
    Console.WriteLine($"  *p = {*p}（value 的地址上的内容）");
    *p = 100;                        // 通过指针改
    Console.WriteLine($"  *p = 100 后 value = {value}");
    Console.WriteLine($"  sizeof(int) = {sizeof(int)} 字节，指针步进按它走");
}

Console.WriteLine();
Console.WriteLine("===== fixed：钉住托管对象再取指针 =====");
var data = new int[] { 1, 2, 3, 4 };
unsafe
{
    fixed (int* p = data)            // GC 会搬对象；fixed 期间保证钉住不动
    {
        int sum = 0;
        for (int* q = p; q < p + data.Length; q++)
            sum += *q;               // 指针算术：q++ 实际走 sizeof(int) 字节
        Console.WriteLine($"  指针遍历求和 = {sum}");
    }
}

Console.WriteLine();
Console.WriteLine("===== P/Invoke：调用操作系统的 C 函数 =====");
Console.WriteLine($"  GetCurrentThreadId() = {Native.GetCurrentThreadId()}");
var sb = new System.Text.StringBuilder(256);
_ = Native.GetSystemDirectory(sb, 256);
Console.WriteLine($"  GetSystemDirectory() = {sb}");

Console.WriteLine();
Console.WriteLine("===== 结构布局：和 C 对齐 =====");
Console.WriteLine($"  布局: {System.Runtime.InteropServices.Marshal.SizeOf<WinPoint>()} 字节（显式 LayoutKind.Sequential）");
Console.WriteLine("  互操作结构体要 [StructLayout] 声明布局，字段顺序=内存顺序");

Console.WriteLine();
Console.WriteLine("===== 函数指针（delegate*）：比委托快的回调 =====");
unsafe
{
    Console.WriteLine("  delegate*<int,int,int> 形态：指向静态方法的非托管函数指针");
    Console.WriteLine("  函数指针用于把托管方法递给非托管回调，热路径省委托分配");
}

Console.WriteLine();
Console.WriteLine("===== 纪律 =====");
Console.WriteLine("  99% 的业务代码用不到 unsafe——Span/Memory（第 26 章）已覆盖大部分需求");
Console.WriteLine("  需要 unsafe 的信号：对接 C 库、极致热路径、位级协议解析");
Console.WriteLine("  每处 unsafe 都要注释为什么非它不可");

static class Native
{
    [System.Runtime.InteropServices.DllImport("kernel32")]
    public static extern uint GetCurrentThreadId();

    [System.Runtime.InteropServices.DllImport("kernel32", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
    public static extern uint GetSystemDirectory(System.Text.StringBuilder sb, uint length);
}

[System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
public struct WinPoint
{
    public int X;
    public int Y;
}
