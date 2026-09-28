// 10 的 C# 启动器
namespace MdiHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        MdiCpp.App.Run();
    }
}
