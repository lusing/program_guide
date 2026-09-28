// 05 的 C# 启动器
namespace TextHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        TextCpp.App.Run();
    }
}
