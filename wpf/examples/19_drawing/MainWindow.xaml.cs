using System.Windows;

namespace DrawingDemo;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    // 直接改变换对象的属性：UIElement 的渲染结果随之更新，无需重画
    private void Rotate_Click(object sender, RoutedEventArgs e)
        => StarRotate.Angle += 30;

    private void ScaleUp_Click(object sender, RoutedEventArgs e)
    {
        StarScale.ScaleX *= 1.2;
        StarScale.ScaleY *= 1.2;
    }

    private void Reset_Click(object sender, RoutedEventArgs e)
    {
        StarRotate.Angle = 0;
        StarScale.ScaleX = 1;
        StarScale.ScaleY = 1;
    }
}
