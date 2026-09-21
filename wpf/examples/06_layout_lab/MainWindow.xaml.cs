using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;

namespace LayoutLab;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        BuildChips();
    }

    private void BuildChips()
    {
        var palette = new[]
        {
            BrushFromHex("#3B82F6"), BrushFromHex("#10B981"), BrushFromHex("#F59E0B"),
            BrushFromHex("#EF4444"), BrushFromHex("#8B5CF6"), BrushFromHex("#14B8A6"),
        };

        for (var i = 1; i <= 50; i++)
        {
            var brush = palette[(i - 1) % palette.Length];
            ChipPanel.Children.Add(new Border
            {
                Background = brush,
                CornerRadius = new CornerRadius(12),
                Padding = new Thickness(12, 5, 12, 5),
                Margin = new Thickness(0, 0, 8, 8),
                Child = new TextBlock
                {
                    Text = $"标签 {i:D2}",
                    Foreground = Brushes.White,
                },
            });
        }
    }

    // 第 4 页：窗口宽度变化时实时汇报各列实际宽度，直观看到 1* : 2* : Auto 的分配结果
    private void StarGrid_SizeChanged(object sender, SizeChangedEventArgs e)
        => SizeReport.Text = $"实际列宽  1* → {Col1.ActualWidth:F0}px   2* → {Col2.ActualWidth:F0}px   Auto → {Col3.ActualWidth:F0}px";

    private void Stretch_Changed(object sender, RoutedEventArgs e)
    {
        if (ScaleBox is null) return;
        if (ReferenceEquals(sender, StretchUniform)) ScaleBox.Stretch = Stretch.Uniform;
        else if (ReferenceEquals(sender, StretchFill)) ScaleBox.Stretch = Stretch.Fill;
        else if (ReferenceEquals(sender, StretchNone)) ScaleBox.Stretch = Stretch.None;
    }

    private static Brush BrushFromHex(string hex)
        => (Brush)new BrushConverter().ConvertFromString(hex)!;
}
