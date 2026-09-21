using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace BindingAdvanced;

// 任务项：元素级通知。ObservableCollection 只管"列表增删"，元素内部变化靠 INPC
public sealed class TaskItem : INotifyPropertyChanged
{
    private string _name = "";
    private bool _done;

    public string Name
    {
        get => _name;
        set { _name = value; OnPropertyChanged(); }
    }

    public bool Done
    {
        get => _done;
        set { _done = value; OnPropertyChanged(); }
    }

    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}

public sealed class MainViewModel : INotifyPropertyChanged
{
    private string _firstName = "三";
    private string _lastName = "张";
    private double _progress = 30;
    private TaskItem? _selectedTask;
    private int _taskCount;
    private bool _showStats = true;

    public MainViewModel()
    {
        Tasks = new ObservableCollection<TaskItem>
        {
            new() { Name = "学习绑定四要素" },
            new() { Name = "实现 INPC" },
            new() { Name = "用上 ObservableCollection" },
        };
        // 集合变化时同步派生属性：总数是"算出来的"，但界面要它主动通知
        Tasks.CollectionChanged += (_, _) => TaskCount = Tasks.Count;
        TaskCount = Tasks.Count;
    }

    public string FirstName
    {
        get => _firstName;
        set { _firstName = value; OnPropertyChanged(); }
    }

    public string LastName
    {
        get => _lastName;
        set { _lastName = value; OnPropertyChanged(); }
    }

    public double Progress
    {
        get => _progress;
        set { _progress = value; OnPropertyChanged(); }
    }

    public ObservableCollection<TaskItem> Tasks { get; }

    public TaskItem? SelectedTask
    {
        get => _selectedTask;
        set { _selectedTask = value; OnPropertyChanged(); }
    }

    public int TaskCount
    {
        get => _taskCount;
        private set { _taskCount = value; OnPropertyChanged(); }
    }

    public bool ShowStats
    {
        get => _showStats;
        set { _showStats = value; OnPropertyChanged(); }
    }

    public void AddTask(string? name)
    {
        if (string.IsNullOrWhiteSpace(name)) return;
        Tasks.Add(new TaskItem { Name = name.Trim() });
    }

    public void RemoveSelected()
    {
        if (SelectedTask is not null)
            Tasks.Remove(SelectedTask);
    }

    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}
