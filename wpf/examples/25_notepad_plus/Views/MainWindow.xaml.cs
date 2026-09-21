using System.ComponentModel;
using System.Windows;
using Microsoft.Win32;
using NotepadPlus.ViewModels;

namespace NotepadPlus.Views;

public partial class MainWindow : Window
{
    private readonly MainViewModel _vm = new();
    private FindReplaceWindow? _findWindow;   // 非模态：可能还开着

    public MainWindow()
    {
        InitializeComponent();
        DataContext = _vm;

        // 文件对话框是视图职责：ViewModel 通过委托调用，自己不碰 UI
        _vm.PickOpenFile = PickOpenFile;
        _vm.PickSaveFile = PickSaveFile;
        _vm.ConfirmDiscard = () => MessageBox.Show(this,
            "文档已修改，放弃更改？", "记事本+",
            MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes;
        _vm.FindRequested += OpenFindWindow;

        UpdateCaretStatus();
    }

    private string? PickOpenFile()
    {
        var dlg = new OpenFileDialog
        {
            Filter = "文本文件|*.txt;*.md;*.log|所有文件|*.*",
            InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)
        };
        return dlg.ShowDialog(this) == true ? dlg.FileName : null;
    }

    private string? PickSaveFile()
    {
        var dlg = new SaveFileDialog
        {
            Filter = "文本文件|*.txt|所有文件|*.*",
            FileName = _vm.FilePath is null ? "无标题.txt" : System.IO.Path.GetFileName(_vm.FilePath)
        };
        return dlg.ShowDialog(this) == true ? dlg.FileName : null;
    }

    private void Exit_Click(object sender, RoutedEventArgs e) => Close();

    private void Editor_TextChanged(object sender, System.Windows.Controls.TextChangedEventArgs e)
        => UpdateCaretStatus();

    private void Editor_SelectionChanged(object sender, RoutedEventArgs e)
        => UpdateCaretStatus();

    private void UpdateCaretStatus()
    {
        var line = Editor.GetLineIndexFromCharacterIndex(Editor.CaretIndex);
        var column = Editor.CaretIndex - Editor.GetCharacterIndexFromLineIndex(line);
        _vm.CaretInfo = $"行 {line + 1}，列 {column + 1}";
    }

    private void OpenFindWindow()
    {
        if (_findWindow is { IsLoaded: true })
        {
            _findWindow.Activate();   // 已经开着就置前
            return;
        }
        _findWindow = new FindReplaceWindow(_vm,
            () => Editor.SelectionStart + Editor.SelectionLength,   // 从当前选区之后找
            (start, length) => { Editor.Select(start, length); Editor.Focus(); });
        _findWindow.Owner = this;
        _findWindow.Show();           // Show() 而非 ShowDialog()：边看文档边替换
    }

    protected override void OnClosing(CancelEventArgs e)
    {
        if (!_vm.IsDirty) return;

        var result = MessageBox.Show(this, "文档已修改，保存吗？", "记事本+",
            MessageBoxButton.YesNoCancel, MessageBoxImage.Warning);

        switch (result)
        {
            case MessageBoxResult.Cancel:
                e.Cancel = true;
                return;
            case MessageBoxResult.Yes:
                e.Cancel = true;                    // 先拦住，存完再关
                _ = SaveThenCloseAsync();
                break;
        }
    }

    private async Task SaveThenCloseAsync()
    {
        if (await _vm.SaveAsync())
            Close();
        // 用户在"另存为"里点了取消 → 留在编辑器，什么都不发生
    }
}
