// 09 的 C# 启动器
namespace DialogsHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        DialogsCpp.App.Run();
    }
}
