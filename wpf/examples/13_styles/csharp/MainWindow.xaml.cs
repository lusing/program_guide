using System.Windows;
using System.Windows.Media;

namespace StyleDemo;

public partial class MainWindow : Window
{
    private readonly SolidColorBrush[] _skins =
    {
        BrushFromHex("#8B5CF6"), BrushFromHex("#0EA5E9"), BrushFromHex("#F59E0B"),
    };
    private int _skinIndex;

    public MainWindow()
    {
        InitializeComponent();
    }

    // 换肤 = 改资源字典里的那把刷子——所有 DynamicResource 引用处就地刷新
    private void SkinButton_Click(object sender, RoutedEventArgs e)
    {
        _skinIndex = (_skinIndex + 1) % _skins.Length;
        Resources["accentBrush"] = _skins[_skinIndex];
    }

    private static SolidColorBrush BrushFromHex(string hex)
        => (SolidColorBrush)new BrushConverter().ConvertFromString(hex)!;
}
