using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;

namespace TreeViewDemo;

public partial class MainWindow : Window
{
    private readonly TreeViewModel _vm = new();

    public MainWindow()
    {
        InitializeComponent();
        DataContext = _vm;
    }

    // TreeView.SelectedItem 是只读属性，不能 TwoWay 绑定——只能用事件拿（本章第一坑）
    private void FileTree_SelectedItemChanged(object sender, RoutedPropertyChangedEventArgs<object> e)
    {
        if (e.NewValue is FileNode node)
            StatusText.Text = $"选中：{node.Name}（{(node.IsFolder ? "文件夹" : "文件")}）";
    }

    private void ExpandAll_Click(object sender, RoutedEventArgs e)
        => SetExpanded(_vm.Root, true);

    private void CollapseAll_Click(object sender, RoutedEventArgs e)
        => SetExpanded(_vm.Root, false);

    // 递归遍历模型本身：树形 UI 的批量操作落在数据上，而不是视觉树上
    private static void SetExpanded(IEnumerable<FileNode> nodes, bool expanded)
    {
        foreach (var node in nodes)
        {
            node.IsExpanded = expanded;
            SetExpanded(node.Children, expanded);
        }
    }
}
