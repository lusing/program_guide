using System.Windows;

namespace HelloWpfApp;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private void Button_Click(object sender, RoutedEventArgs e)
    {
        var name = string.IsNullOrWhiteSpace(NameTextBox.Text) ? "朋友" : NameTextBox.Text.Trim();
        MessageBox.Show($"Hello, {name}!", "Greeting");
    }
}
