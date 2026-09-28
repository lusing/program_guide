// 14 的 C# 启动器
namespace BindingHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        BindingCpp.App.Run();
    }
}
