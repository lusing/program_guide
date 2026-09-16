using System.Windows;
using NotepadPlus.ViewModels;

namespace NotepadPlus.Views;

/// <summary>非模态查找替换窗口。VM 提供纯字符串逻辑，本窗口负责选区与提示。</summary>
public partial class FindReplaceWindow : Window
{
    private readonly MainViewModel _vm;
    private readonly Func<int> _getSearchStart;                       // 编辑器当前查找起点
    private readonly Action<int, int> _select;                        // (start, length) → 编辑器选区

    public FindReplaceWindow(MainViewModel vm, Func<int> getSearchStart, Action<int, int> select)
    {
        InitializeComponent();
        _vm = vm;
        _getSearchStart = getSearchStart;
        _select = select;
    }

    private void FindNext_Click(object sender, RoutedEventArgs e)
    {
        var idx = _vm.FindNext(FindBox.Text, MatchCaseBox.IsChecked == true, _getSearchStart());
        if (idx < 0)
        {
            MessageBox.Show(this, $"找不到 \"{FindBox.Text}\"", "查找",
                MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }
        _select(idx, FindBox.Text.Length);
    }

    private void Replace_Click(object sender, RoutedEventArgs e)
    {
        var start = _getSearchStart() - FindBox.Text.Length;          // 当前选区起点
        if (start < 0) start = 0;
        _vm.ReplaceSelection(start, FindBox.Text.Length,
            FindBox.Text, MatchCaseBox.IsChecked == true, ReplaceBox.Text);
        FindNext_Click(sender, e);                                    // 替换完顺势找下一个
    }

    private void ReplaceAll_Click(object sender, RoutedEventArgs e)
    {
        var count = _vm.ReplaceAll(FindBox.Text, ReplaceBox.Text, MatchCaseBox.IsChecked == true);
        MessageBox.Show(this, $"共替换 {count} 处。", "全部替换",
            MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private void Close_Click(object sender, RoutedEventArgs e) => Close();
}
