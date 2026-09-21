using System.Collections.ObjectModel;
using System.IO;
using System.Text;
using System.Windows.Input;
using NotepadPlus.Services;

namespace NotepadPlus.ViewModels;

public sealed class MainViewModel : ViewModelBase
{
    private string _content = string.Empty;
    private string? _filePath;
    private Encoding _encoding = new UTF8Encoding(encoderShouldEmitUTF8Identifier: true);
    private bool _isDirty;
    private string _statusMessage = "就绪";
    private string _caretInfo = "行 1，列 1";
    private string _encodingName = "UTF-8";
    private bool _isWordWrap;

    /// <summary>视图职责通过委托注入：文件对话框由 Window 提供，ViewModel 不碰 UI。</summary>
    public Func<string?>? PickOpenFile { get; set; }
    public Func<string?>? PickSaveFile { get; set; }
    public Func<bool>? ConfirmDiscard { get; set; }

    /// <summary>查找窗口由 View 打开——VM 只发通知。</summary>
    public event Action? FindRequested;

    public string Content
    {
        get => _content;
        set
        {
            if (!SetField(ref _content, value)) return;
            IsDirty = true;                          // 任何编辑都置脏
            CharCount = value.Length;
        }
    }

    public string? FilePath
    {
        get => _filePath;
        private set
        {
            if (!SetField(ref _filePath, value)) return;
            OnPropertyChanged(nameof(Title));
        }
    }

    public bool IsDirty
    {
        get => _isDirty;
        private set
        {
            if (!SetField(ref _isDirty, value)) return;
            OnPropertyChanged(nameof(Title));
            SaveCommand.RaiseCanExecuteChanged();    // CanExecute 依赖 IsDirty，变了要通知
        }
    }

    public string StatusMessage { get => _statusMessage; set => SetField(ref _statusMessage, value); }
    public string CaretInfo { get => _caretInfo; set => SetField(ref _caretInfo, value); }
    public string EncodingName { get => _encodingName; set => SetField(ref _encodingName, value); }
    public int CharCount { get => _charCount; private set => SetField(ref _charCount, value); }
    private int _charCount;

    public bool IsWordWrap { get => _isWordWrap; set => SetField(ref _isWordWrap, value); }

    /// <summary>标题栏：脏标记打星号 + 文件名。</summary>
    public string Title
    {
        get
        {
            var name = FilePath is null ? "无标题" : Path.GetFileName(FilePath);
            return $"{(IsDirty ? "*" : "")}{name} - WPF 记事本+";
        }
    }

    public ObservableCollection<string> RecentFiles { get; } = new(RecentFilesService.Load());

    public ICommand NewDocumentCommand { get; }
    public ICommand OpenFileCommand { get; }
    public ICommand OpenRecentCommand { get; }
    public RelayCommand SaveCommand { get; }
    public ICommand SaveAsCommand { get; }
    public ICommand FindCommand { get; }

    public MainViewModel()
    {
        NewDocumentCommand = new RelayCommand(_ => NewDocument());
        OpenFileCommand = new RelayCommand(_ => _ = OpenAsync(null));
        OpenRecentCommand = new RelayCommand(p => _ = OpenAsync(p as string));
        SaveCommand = new RelayCommand(_ => _ = SaveAsync(), _ => IsDirty);
        SaveAsCommand = new RelayCommand(_ => _ = SaveAsAsync());
        FindCommand = new RelayCommand(_ => FindRequested?.Invoke());
    }

    private void NewDocument()
    {
        if (IsDirty && ConfirmDiscard?.Invoke() != true) return;
        Content = string.Empty;
        FilePath = null;
        _encoding = new UTF8Encoding(true);
        EncodingName = "UTF-8";
        IsDirty = false;
        StatusMessage = "新建文档";
    }

    public async Task OpenAsync(string? path)
    {
        path ??= PickOpenFile?.Invoke();
        if (path is null) return;
        if (!File.Exists(path))
        {
            StatusMessage = $"文件不存在: {path}";
            return;
        }

        try
        {
            StatusMessage = "正在打开…";
            var (content, encoding) = await TextFileService.ReadAsync(path);
            Content = content;
            FilePath = path;
            _encoding = encoding;
            EncodingName = encoding.WebName.ToUpperInvariant();
            IsDirty = false;                          // 载入不算编辑，清掉 Content 置上的脏
            StatusMessage = $"已打开 {path}";
            PushRecent(path);
        }
        catch (Exception ex)
        {
            StatusMessage = $"打开失败: {ex.Message}";
        }
    }

    public async Task<bool> SaveAsync()
    {
        var path = FilePath ?? PickSaveFile?.Invoke();
        if (path is null) return false;
        return await SaveCoreAsync(path);
    }

    public async Task<bool> SaveAsAsync()
    {
        var path = PickSaveFile?.Invoke();
        if (path is null) return false;
        return await SaveCoreAsync(path);
    }

    private async Task<bool> SaveCoreAsync(string path)
    {
        try
        {
            StatusMessage = "正在保存…";
            await TextFileService.WriteAsync(path, Content, _encoding);
            FilePath = path;
            IsDirty = false;
            StatusMessage = $"已保存 {path}";
            PushRecent(path);
            return true;
        }
        catch (Exception ex)
        {
            StatusMessage = $"保存失败: {ex.Message}";
            return false;
        }
    }

    private void PushRecent(string path)
    {
        RecentFiles.Remove(path);                     // 去重：挪到最上
        RecentFiles.Insert(0, path);
        while (RecentFiles.Count > 8)
            RecentFiles.RemoveAt(RecentFiles.Count - 1);
        RecentFilesService.Save(RecentFiles);
    }

    // ---- 查找/替换：纯字符串逻辑，不碰任何控件，可以单独测试 ----

    /// <summary>从 startIndex 起查找，找不到回绕到开头。返回下标，-1 = 没找到。</summary>
    public int FindNext(string query, bool matchCase, int startIndex)
    {
        if (string.IsNullOrEmpty(query)) return -1;
        var comparison = matchCase ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
        if (startIndex < 0 || startIndex > Content.Length) startIndex = 0;
        var idx = Content.IndexOf(query, startIndex, comparison);
        if (idx < 0 && startIndex > 0)
            idx = Content.IndexOf(query, 0, comparison);   // 回绕
        return idx;
    }

    /// <summary>校验 [start, start+length) 是否匹配 query，匹配则替换。返回是否替换了。</summary>
    public bool ReplaceSelection(int start, int length, string query, bool matchCase, string replacement)
    {
        if (start < 0 || start + length > Content.Length) return false;
        var current = Content.Substring(start, length);
        var equal = string.Equals(current, query,
            matchCase ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase);
        if (!equal) return false;
        Content = Content[..start] + replacement + Content[(start + length)..];
        return true;
    }

    /// <summary>全部替换。返回替换次数。</summary>
    public int ReplaceAll(string query, string replacement, bool matchCase)
    {
        if (string.IsNullOrEmpty(query)) return 0;
        var comparison = matchCase ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
        var count = 0;
        int idx;
        var pos = 0;
        while ((idx = Content.IndexOf(query, pos, comparison)) >= 0)
        {
            Content = Content[..idx] + replacement + Content[(idx + query.Length)..];
            pos = idx + replacement.Length;
            count++;
        }
        return count;
    }
}
