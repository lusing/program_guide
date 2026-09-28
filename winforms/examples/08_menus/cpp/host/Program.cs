// 08 的 C# 启动器
namespace MenusHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        MenusCpp.App.Run();
    }
}
