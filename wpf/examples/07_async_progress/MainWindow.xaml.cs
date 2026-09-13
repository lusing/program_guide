using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Input;

namespace AsyncProgressDemo;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        DataContext = new MainViewModel();
    }
}

public sealed class MainViewModel : INotifyPropertyChanged
{
    private int _progress;
    private string _statusText = "等待开始";

    public int Progress
    {
        get => _progress;
        set
        {
            if (_progress == value) return;
            _progress = value;
            OnPropertyChanged();
        }
    }

    public string StatusText
    {
        get => _statusText;
        set
        {
            if (_statusText == value) return;
            _statusText = value;
            OnPropertyChanged();
        }
    }

    public ICommand StartCommand { get; }

    public MainViewModel()
    {
        StartCommand = new RelayCommand(_ => _ = RunAsync());
    }

    private async Task RunAsync()
    {
        for (var i = 0; i <= 100; i += 10)
        {
            Progress = i;
            StatusText = $"处理中 {i}%";
            await Task.Delay(200);
        }

        StatusText = "完成";
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}

#pragma warning disable CS0067
public sealed class RelayCommand : ICommand
{
    private readonly Action<object?> _execute;

    public RelayCommand(Action<object?> execute)
    {
        _execute = execute ?? throw new ArgumentNullException(nameof(execute));
    }

    public bool CanExecute(object? parameter) => true;

    public void Execute(object? parameter) => _execute(parameter);

    public event EventHandler? CanExecuteChanged;
}
#pragma warning restore CS0067
