// 07 的 C# 启动器
namespace ListsHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        ListsCpp.App.Run();
    }
}
