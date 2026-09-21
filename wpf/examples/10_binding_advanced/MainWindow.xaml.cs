using System.Windows;
using System.Windows.Input;

namespace BindingAdvanced;

public partial class MainWindow : Window
{
    private readonly MainViewModel _vm = new();

    public MainWindow()
    {
        InitializeComponent();
        DataContext = _vm;   // 窗口设一次，整棵树可绑（DataContext 继承）
    }

    private void Add_Click(object sender, RoutedEventArgs e)
    {
        _vm.AddTask(NewTaskBox.Text);
        NewTaskBox.Text = "";
        NewTaskBox.Focus();
    }

    private void NewTaskBox_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter)
            Add_Click(sender, e);
    }

    private void Remove_Click(object sender, RoutedEventArgs e)
        => _vm.RemoveSelected();
}
