using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace RoutedEvents;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    // ---------- 统一的日志工具：sender 是挂载点，OriginalSource 是事件真正的源头 ----------

    private void Log(string stage, string eventName, object sender, RoutedEventArgs e)
    {
        var mount = sender is FrameworkElement fe ? fe.Name : sender.GetType().Name;
        var origin = e.OriginalSource is FrameworkElement ofe ? ofe.Name : e.OriginalSource?.GetType().Name ?? "?";
        EventLog.Items.Add($"{stage,-4} {eventName,-18} 挂载点={mount,-12} 源头={origin}");
        EventLog.ScrollIntoView(EventLog.Items[^1]);
    }

    // ---------- 隧道阶段（Preview，根 → 子）----------

    private void Window_PreviewMouseDown(object sender, MouseButtonEventArgs e)
        => Log("隧道", "Window.PreviewMouseDown", sender, e);

    private void Border_PreviewMouseDown(object sender, MouseButtonEventArgs e)
    {
        Log("隧道", "Border.PreviewMouseDown", sender, e);
        if (StopAtMiddle.IsChecked == true) return; // 演示由 Grid 承担
    }

    private void Grid_PreviewMouseDown(object sender, MouseButtonEventArgs e)
    {
        Log("隧道", "Grid.PreviewMouseDown", sender, e);
        if (StopAtMiddle.IsChecked == true)
        {
            e.Handled = true;                       // 隧道截停：后面所有阶段全部消失
            Log("……", "Grid 截停 e.Handled", sender, e);
        }
    }

    private void Button_PreviewMouseDown(object sender, MouseButtonEventArgs e)
        => Log("隧道", "Button.PreviewMouseDown", sender, e);

    // ---------- 冒泡阶段（子 → 根）----------

    private void Button_MouseDown(object sender, MouseButtonEventArgs e)
        => Log("冒泡", "Button.MouseDown", sender, e);

    private void DeepButton_Click(object sender, RoutedEventArgs e)
        => Log("路由", "Button.Click", sender, e);

    private void Grid_MouseDown(object sender, MouseButtonEventArgs e)
        => Log("冒泡", "Grid.MouseDown", sender, e);

    private void Border_MouseDown(object sender, MouseButtonEventArgs e)
        => Log("冒泡", "Border.MouseDown", sender, e);

    private void Window_MouseDown(object sender, MouseButtonEventArgs e)
        => Log("冒泡", "Window.MouseDown", sender, e);

    private void Clear_Click(object sender, RoutedEventArgs e)
        => EventLog.Items.Clear();
}
