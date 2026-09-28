// 16 的 C# 启动器
namespace ThreadingHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        ThreadingCpp.App.Run();
    }
}
