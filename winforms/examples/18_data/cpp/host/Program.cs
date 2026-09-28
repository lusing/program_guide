// 18 的 C# 启动器（间接拉起 C# 数据层 + C++/CLI UI）
namespace DataHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        DataCpp.App.Run();
    }
}
