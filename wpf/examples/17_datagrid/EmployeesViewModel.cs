using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace DataGridDemo;

public sealed class Employee : INotifyPropertyChanged
{
    private string _name = "";
    private string _department = "";
    private decimal _salary;
    private bool _isActive = true;

    public required string Name
    {
        get => _name;
        set { _name = value; OnPropertyChanged(); }
    }

    public required string Department
    {
        get => _department;
        set { _department = value; OnPropertyChanged(); }
    }

    public required decimal Salary
    {
        get => _salary;
        set
        {
            _salary = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(IsHighSalary));   // 派生属性跟着联动，否则界面看到旧值
        }
    }

    // 派生状态：模板触发器只做等值比较，范围判断提前算好（与 15 章的 AgeGroup 同一手法）
    public bool IsHighSalary => Salary >= 18000m;

    public bool IsActive
    {
        get => _isActive;
        set { _isActive = value; OnPropertyChanged(); }
    }

    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}

public sealed class EmployeesViewModel
{
    public ObservableCollection<Employee> Employees { get; } = new()
    {
        new() { Name = "张三", Department = "研发", Salary = 18000m },
        new() { Name = "李四", Department = "设计", Salary = 15000m },
        new() { Name = "王五", Department = "研发", Salary = 21000m },
        new() { Name = "赵六", Department = "测试", Salary = 13000m },
        new() { Name = "孙七", Department = "研发", Salary = 17500m },
    };
}
