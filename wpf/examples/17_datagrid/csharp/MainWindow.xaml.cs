using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;

namespace DataGridDemo;

public partial class MainWindow : Window
{
    private readonly EmployeesViewModel _vm = new();
    private string _lastSortProperty = "";
    private ListSortDirection _lastDirection = ListSortDirection.Ascending;

    public MainWindow()
    {
        InitializeComponent();
        DataContext = _vm;
    }

    // ListView 表头点击排序：GridViewColumn 的 Header 映射到属性名，切换升降序
    private void ListView_HeaderClick(object sender, RoutedEventArgs e)
    {
        if (e.OriginalSource is not GridViewColumnHeader header) return;

        var property = header.Column.Header switch
        {
            "姓名" => nameof(Employee.Name),
            "部门" => nameof(Employee.Department),
            "薪水" => nameof(Employee.Salary),
            "在职" => nameof(Employee.IsActive),
            _ => "",
        };
        if (property.Length == 0) return;

        if (_lastSortProperty == property)
            _lastDirection = _lastDirection == ListSortDirection.Ascending
                ? ListSortDirection.Descending
                : ListSortDirection.Ascending;
        else
            _lastDirection = ListSortDirection.Ascending;
        _lastSortProperty = property;

        var view = CollectionViewSource.GetDefaultView(_vm.Employees);
        view.SortDescriptions.Clear();
        view.SortDescriptions.Add(new SortDescription(property, _lastDirection));
    }
}
