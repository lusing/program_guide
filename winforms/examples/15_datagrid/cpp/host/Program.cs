// 15 的 C# 启动器
namespace GridHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        GridCpp.App.Run();
    }
}
