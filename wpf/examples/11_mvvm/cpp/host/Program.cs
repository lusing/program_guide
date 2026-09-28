// 托管启动器：C++/CLI 只能产混合模式 DLL（NETSDK1116），EXE 入口在这里。
// [STAThread] 服务于整个 UI 线程：C++ 侧的窗口同样受益（WPF 强制 STA）。
namespace MvvmDemoHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        MvvmDemoCpp.App.Run();
    }
}
