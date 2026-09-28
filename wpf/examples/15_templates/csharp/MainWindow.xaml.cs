using System.Windows;

namespace TemplatesDemo;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        DataContext = new PeopleViewModel();
    }
}
