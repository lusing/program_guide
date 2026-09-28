using System.Windows;

namespace ValidationDemo;

public partial class MainWindow : Window
{
    private readonly FormViewModel _vm = new();

    public MainWindow()
    {
        InitializeComponent();
        DataContext = _vm;
    }

    private void Submit_Click(object sender, RoutedEventArgs e)
        => _vm.Submit();
}
