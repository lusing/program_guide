// 02 第一个 WinForms 程序：窗体即对象、消息循环、事件接线
using System.Drawing;
using System.Windows.Forms;

namespace HelloWin;

// 窗体是一个类：继承 Form，界面搭建写在构造函数里。
// 手写构造 = 设计器生成代码（InitializeComponent）的等价物——本教程全部手写。
internal class MainForm : Form
{
    private int _count = 0;

    private readonly Label _label = new();
    private readonly Button _button = new();

    public MainForm()
    {
        // ── 2.1 窗体自身的属性 ──
        Text = "你好，WinForms（C#）";       // 标题栏文字
        Width = 420;
        Height = 170;
        StartPosition = FormStartPosition.CenterScreen;   // 屏幕居中
        Font = new Font("微软雅黑", 10F);

        // ── 2.2 控件：创建 → 设属性 → 挂事件 → 加进 Controls ──
        _label.Text = "等你点击下面的按钮";
        _label.Dock = DockStyle.Top;       // Dock：贴满某条边（这里贴顶）
        _label.Height = 60;
        _label.TextAlign = ContentAlignment.MiddleCenter;

        _button.Text = "点我一下";
        _button.Dock = DockStyle.Bottom;   // 贴底
        _button.Height = 45;

        // 事件接线：+= 把一个委托（这里用 lambda）挂到按钮的 Click 事件上
        _button.Click += (sender, e) =>
        {
            _count++;
            _label.Text = $"第 {_count} 次点击——sender 是 {_button.Text} 按钮实例";
        };

        Controls.Add(_label);              // 控件必须挂到父容器才可见
        Controls.Add(_button);
    }
}

internal static class Program
{
    // WinForms 主线程必须是 STA（单线程单元）：剪贴板、文件对话框等 Shell 功能都依赖它
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();                    // 启用系统的视觉样式（按钮才有现代外观）
        Application.SetCompatibleTextRenderingDefault(false); // 统一文本渲染（GDI 而非 GDI+）
        Application.Run(new MainForm());                     // 推入消息循环：窗体显示，直到它被关闭
    }
}
