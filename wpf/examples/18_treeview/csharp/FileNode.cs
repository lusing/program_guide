using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace TreeViewDemo;

// 树节点：Children 的类型必须与 HierarchicalDataTemplate 的 ItemsSource 匹配
public sealed class FileNode : INotifyPropertyChanged
{
    private bool _isExpanded;

    public required string Name { get; init; }
    public required bool IsFolder { get; init; }

    public ObservableCollection<FileNode> Children { get; } = new();

    public bool IsExpanded
    {
        get => _isExpanded;
        set { _isExpanded = value; OnPropertyChanged(); }
    }

    // 展示用派生属性：文件数徽标（子树变化时由调用方刷新）
    public string Badge => IsFolder ? $"{Children.Count} 项" : "";

    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}

public sealed class TreeViewModel
{
    public ObservableCollection<FileNode> Root { get; } = new()
    {
        new()
        {
            Name = "NotepadPlus", IsFolder = true, IsExpanded = true,
            Children =
            {
                new FileNode { Name = "App.xaml", IsFolder = false },
                new FileNode { Name = "NotepadPlus.csproj", IsFolder = false },
                new()
                {
                    Name = "ViewModels", IsFolder = true,
                    Children =
                    {
                        new FileNode { Name = "MainViewModel.cs", IsFolder = false },
                        new FileNode { Name = "RelayCommand.cs", IsFolder = false },
                    },
                },
                new()
                {
                    Name = "Views", IsFolder = true,
                    Children =
                    {
                        new FileNode { Name = "MainWindow.xaml", IsFolder = false },
                        new FileNode { Name = "FindReplaceWindow.xaml", IsFolder = false },
                    },
                },
                new()
                {
                    Name = "Services", IsFolder = true,
                    Children =
                    {
                        new FileNode { Name = "EncodingDetector.cs", IsFolder = false },
                        new FileNode { Name = "RecentFilesService.cs", IsFolder = false },
                    },
                },
            },
        },
        new()
        {
            Name = "docs", IsFolder = true,
            Children =
            {
                new FileNode { Name = "07-mvvm-commands.md", IsFolder = false },
                new FileNode { Name = "12-notepad-plus.md", IsFolder = false },
            },
        },
    };
}
