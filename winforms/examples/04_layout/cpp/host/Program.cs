// 04 的 C# 启动器
namespace LayoutHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        LayoutCpp.App.Run();
    }
}
