using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace TemplatesDemo;

// 数据模型：AgeGroup 是"为显示预加工"的属性——模板触发器只做等值比较，范围判断提前算好
public sealed class Person
{
    public required string Name { get; init; }
    public required int Age { get; init; }

    public string AgeGroup => Age < 30 ? "青年" : Age < 50 ? "中年" : "资深";
}

public sealed class PeopleViewModel : INotifyPropertyChanged
{
    private Person? _selected;

    public ObservableCollection<Person> People { get; } = new()
    {
        new() { Name = "张三", Age = 24 },
        new() { Name = "李四", Age = 35 },
        new() { Name = "王五", Age = 46 },
        new() { Name = "赵六", Age = 58 },
        new() { Name = "孙七", Age = 28 },
    };

    public Person? Selected
    {
        get => _selected;
        set { _selected = value; OnPropertyChanged(); }
    }

    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}
