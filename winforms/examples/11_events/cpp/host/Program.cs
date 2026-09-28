// 11 的 C# 启动器
namespace EventsHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        EventsCpp.App.Run();
    }
}
