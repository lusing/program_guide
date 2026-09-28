using System.Windows;
using System.Windows.Controls;

namespace NavigationDemo;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        MainFrame.Navigate(new HomePage());
    }

    private void Home_Click(object sender, RoutedEventArgs e)
    {
        MainFrame.Navigate(new HomePage());
    }

    private void Settings_Click(object sender, RoutedEventArgs e)
    {
        MainFrame.Navigate(new SettingsPage());
    }
}

public sealed class HomePage : Page
{
    public HomePage()
    {
        Content = new TextBlock
        {
            Text = "欢迎来到首页",
            FontSize = 22,
            FontWeight = FontWeights.Bold,
            Margin = new Thickness(20)
        };
    }
}

public sealed class SettingsPage : Page
{
    public SettingsPage()
    {
        Content = new StackPanel
        {
            Margin = new Thickness(20),
            Children =
            {
                new TextBlock { Text = "设置页面", FontSize = 22, FontWeight = FontWeights.Bold },
                new CheckBox { Content = "启用通知", IsChecked = true, Margin = new Thickness(0,12,0,0) },
                new CheckBox { Content = "自动保存", IsChecked = true }
            }
        };
    }
}
