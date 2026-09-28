// 17 的 C# 启动器
namespace CryptoHost;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        CryptoCpp.App.Run();
    }
}
