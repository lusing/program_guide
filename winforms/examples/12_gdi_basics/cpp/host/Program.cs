// 12 的 C# 启动器
namespace GdiBasicsHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        GdiBasicsCpp.App.Run();
    }
}
