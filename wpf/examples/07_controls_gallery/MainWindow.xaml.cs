using System.Windows;
using System.Windows.Controls;

namespace ControlsGallery;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private void Any_Changed(object sender, RoutedEventArgs e)
    {
        var who = sender is FrameworkElement fe ? fe.GetType().Name : sender?.GetType().Name ?? "?";
        var action = e.RoutedEvent?.Name ?? "事件";
        StatusText.Text = $"{who} 触发了 {action}";
    }

    // 注意：TextChanged 不是路由事件，委托类型不同，不能和 Click 共用处理器
    private void Text_Changed(object sender, TextChangedEventArgs e)
        => StatusText.Text = $"TextBox 文本变了（TextChanged 是直接事件）";

    private void Combo_Changed(object sender, SelectionChangedEventArgs e)
    {
        if (StatusText is null) return;
        var item = (ComboBoxItem)((ComboBox)sender).SelectedItem;
        StatusText.Text = $"ComboBox 选中了 {item?.Content}";
    }

    private void Slider_Changed(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (DemoProgress is null) return;
        DemoProgress.Value = e.NewValue;
        StatusText.Text = $"Slider = {e.NewValue:F0}，进度条同步（事件直连演示）";
    }

    private void List_Changed(object sender, SelectionChangedEventArgs e)
    {
        if (StatusText is null) return;
        var item = (ListBoxItem)((ListBox)sender).SelectedItem;
        StatusText.Text = $"ListBox 选中了 {item?.Content}";
    }
}
