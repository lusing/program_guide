// 13 的 C# 启动器
namespace ChartHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        ChartCpp.App.Run();
    }
}
