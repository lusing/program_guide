// 06 的 C# 启动器
namespace SelectHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        SelectCpp.App.Run();
    }
}
