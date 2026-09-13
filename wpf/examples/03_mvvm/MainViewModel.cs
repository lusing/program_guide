using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Input;

namespace MvvmDemo;

public sealed class MainViewModel : INotifyPropertyChanged
{
    private string _taskName = "学习 WPF";
    private string _statusMessage = "待处理";

    public string TaskName
    {
        get => _taskName;
        set
        {
            if (_taskName == value) return;
            _taskName = value;
            OnPropertyChanged();
        }
    }

    public string StatusMessage
    {
        get => _statusMessage;
        set
        {
            if (_statusMessage == value) return;
            _statusMessage = value;
            OnPropertyChanged();
        }
    }

    public ICommand AddTaskCommand { get; }

    public MainViewModel()
    {
        AddTaskCommand = new RelayCommand(_ =>
        {
            if (string.IsNullOrWhiteSpace(TaskName))
            {
                StatusMessage = "任务名称不能为空。";
                return;
            }

            StatusMessage = $"已添加任务: {TaskName}";
        });
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}

public sealed class RelayCommand : ICommand
{
    private readonly Action<object?> _execute;
    private readonly Predicate<object?>? _canExecute;

    public RelayCommand(Action<object?> execute, Predicate<object?>? canExecute = null)
    {
        _execute = execute ?? throw new ArgumentNullException(nameof(execute));
        _canExecute = canExecute;
    }

    public bool CanExecute(object? parameter) => _canExecute is null || _canExecute(parameter);

    public void Execute(object? parameter) => _execute(parameter);

    public event EventHandler? CanExecuteChanged;

    public void RaiseCanExecuteChanged() => CanExecuteChanged?.Invoke(this, EventArgs.Empty);
}
