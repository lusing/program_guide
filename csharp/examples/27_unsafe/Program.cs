// 27 · unsafe 与互操作初窥：指针、fixed 与 P/Invoke
using System.Runtime.InteropServices;
using System.Text;

Console.OutputEncoding = Encoding.UTF8;

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
if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
{
    Console.WriteLine($"  kernel32!GetCurrentThreadId() = {WinNative.GetCurrentThreadId()}");
    var sb = new StringBuilder(256);
    _ = WinNative.GetSystemDirectory(sb, 256);
    Console.WriteLine($"  kernel32!GetSystemDirectory() = {sb}");
}
else
{
    // macOS/Linux 是同一套机制，只是导出库换成 libc（运行时自动补 .dylib/.so 后缀）
    Console.WriteLine($"  libc!getpid() = {UnixNative.getpid()}");
    Console.WriteLine($"  libc!getenv(\"HOME\") = {Marshal.PtrToStringUTF8(UnixNative.getenv("HOME"))}");
}
Console.WriteLine("  跨平台要点：库名按平台分支；Windows 侧的字符集由 CharSet 声明，");
Console.WriteLine("              Unix 侧的 C 字符串是 UTF-8 字节，用 Marshal.PtrToStringUTF8 取回");

Console.WriteLine();
Console.WriteLine("===== 结构布局：和 C 对齐 =====");
Console.WriteLine($"  布局: {Marshal.SizeOf<WinPoint>()} 字节（显式 LayoutKind.Sequential）");
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

static class WinNative
{
    [DllImport("kernel32")]
    public static extern uint GetCurrentThreadId();

    [DllImport("kernel32", CharSet = CharSet.Unicode)]           // 字符串编解码方式
    public static extern uint GetSystemDirectory(StringBuilder sb, uint length);
}

static class UnixNative
{
    [DllImport("libc")]
    public static extern int getpid();

    [DllImport("libc")]
    public static extern IntPtr getenv(string name);             // 返回 char*，用 Marshal 取回
}

[StructLayout(LayoutKind.Sequential)]    // 字段按声明顺序线性排布（C 的默认）
public struct WinPoint
{
    public int X;
    public int Y;
}
