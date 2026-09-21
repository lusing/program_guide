using System.Text;
using System.Windows;

namespace NotepadPlus;

public partial class App : Application
{
    public App()
    {
        // GB18030 等代码页编码默认不注册，读老文件前先注册提供程序
        Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
    }
}
