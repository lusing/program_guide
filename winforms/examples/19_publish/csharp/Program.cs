// 19 发布演示：把"我是谁"摆在明面上，用于验证三种发布形态
using System.Drawing;
using System.Reflection;
using System.Windows.Forms;

namespace PublishWin;

internal class MainForm : Form
{
    public MainForm()
    {
        var asm = Assembly.GetExecutingAssembly();
        Text = "发布演示";
        ClientSize = new Size(460, 240);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;

        var info = new ListBox { Dock = DockStyle.Fill, Font = new Font("Consolas", 10F) };
        info.Items.Add($"程序集     {asm.GetName().Name}");
        info.Items.Add($"版本       {asm.GetName().Version}");
        info.Items.Add($"运行时     {Environment.Version}");
        info.Items.Add($"框架描述   {System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription}");
        info.Items.Add($"本机目录   {AppContext.BaseDirectory}");
        info.Items.Add("");
        info.Items.Add("用 build.ps1 发布后三种形态对比见 docs/19-publish.md：");
        info.Items.Add("  框架依赖 / 自包含 / 单文件（体积与依赖文件数不同）");
        Controls.Add(info);
    }
}

internal static class Program
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MainForm());
    }
}
