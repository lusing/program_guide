// 托管启动器：.NET Core/.NET 10 的 C++/CLI 只能产混合模式 DLL（NETSDK1116），
// EXE 入口由这个 C# 小工程承担——加载 DLL、把控制权交给 HelloCpp.App.Run()。
// [STAThread] 服务于整个 UI 线程：C++ 侧的窗体同样受益。
namespace HelloHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        HelloCpp.App.Run();
    }
}
