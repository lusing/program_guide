// 03 的 C# 启动器：加载 FormsCpp.dll 混合模式程序集并进入窗体
namespace FormsHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        FormsCpp.App.Run();
    }
}
