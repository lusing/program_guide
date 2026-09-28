// 17 ListView 与 DataGrid（F# 版）：与 csharp/ 版功能一致。
// 新面孔：GridView/GridViewColumn（DisplayMemberBinding 走普通 Binding）、
// DataGrid 各列型、表头点击排序（CollectionViewSource.GetDefaultView + SortDescription）。
module DataGridDemoFs.Program

open System
open System.Collections.ObjectModel
open System.ComponentModel
open System.Windows
open System.Windows.Controls
open System.Windows.Data
open System.Windows.Media

let brushFromHex (hex: string) =
    ColorConverter.ConvertFromString hex :?> Color |> SolidColorBrush

type Employee(name: string, dept: string, salary: decimal) as this =
    let pc = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()
    let mutable name = name
    let mutable dept = dept
    let mutable salary = salary
    let mutable isActive = true
    member _.Name with get () = name and set v = name <- v; pc.Trigger(this, PropertyChangedEventArgs "Name")
    member _.Department with get () = dept and set v = dept <- v; pc.Trigger(this, PropertyChangedEventArgs "Department")
    member _.Salary
        with get () = salary
        and set v =
            salary <- v
            pc.Trigger(this, PropertyChangedEventArgs "Salary")
            pc.Trigger(this, PropertyChangedEventArgs "IsHighSalary")   // 派生属性联动
    member _.IsHighSalary = salary >= 18000m
    member _.IsActive with get () = isActive and set v = isActive <- v; pc.Trigger(this, PropertyChangedEventArgs "IsActive")
    interface INotifyPropertyChanged with
        [<CLIEvent>]
        member _.PropertyChanged = pc.Publish

type EmployeesViewModel() =
    let employees = ObservableCollection<Employee>()
    do
        for (n, d, s) in [ "张三", "研发", 18000m; "李四", "设计", 15000m; "王五", "研发", 21000m
                           "赵六", "测试", 13000m; "孙七", "研发", 17500m ] do
            employees.Add(Employee(n, d, s))
    member _.Employees = employees

/// 薪水列的展示模板：千分位 + 高薪标蓝（DataTrigger 等值比较，范围判断已在 IsHighSalary 算好）
let salaryCell () : DataTemplate =
    let tb = FrameworkElementFactory(typeof<TextBlock>)
    tb.SetValue(TextBlock.HorizontalAlignmentProperty, HorizontalAlignment.Right)
    tb.SetBinding(TextBlock.TextProperty, Binding("Salary", StringFormat = "￥{0:N0}"))
    let st = Style(typeof<TextBlock>)
    st.Setters.Add(Setter(TextBlock.ForegroundProperty, brushFromHex "#334155"))
    let high = DataTrigger(Binding = Binding "IsHighSalary", Value = true)
    high.Setters.Add(Setter(TextBlock.ForegroundProperty, brushFromHex "#2563EB"))
    st.Triggers.Add high
    tb.SetValue(FrameworkElement.StyleProperty, st)
    let dt = DataTemplate()
    dt.VisualTree <- tb
    dt

[<EntryPoint; STAThread>]
let main _ =
    let vm = EmployeesViewModel()
    let window = Window(Title = "列表数据：ListView 与 DataGrid (F#)", Height = 560., Width = 600.)

    // ① ListView + GridView
    let listView = ListView()
    listView.SetBinding(ItemsControl.ItemsSourceProperty, Binding "Employees") |> ignore

    let mkCol (header: string) (width: float) (binding: string) =
        GridViewColumn(Header = header, Width = width, DisplayMemberBinding = Binding binding)
    let salaryCol = GridViewColumn(Header = "薪水", Width = 110., CellTemplate = salaryCell ())
    let activeCell = DataTemplate()
    let cbF = FrameworkElementFactory(typeof<CheckBox>)
    cbF.SetBinding(CheckBox.IsCheckedProperty, Binding "IsActive")
    cbF.SetValue(FrameworkElement.HorizontalAlignmentProperty, HorizontalAlignment.Center)
    activeCell.VisualTree <- cbF
    let activeCol = GridViewColumn(Header = "在职", Width = 60., CellTemplate = activeCell)

    let gv = GridView()
    gv.Columns.Add(mkCol "姓名" 90. "Name") |> ignore
    gv.Columns.Add(mkCol "部门" 90. "Department") |> ignore
    gv.Columns.Add salaryCol |> ignore
    gv.Columns.Add activeCol |> ignore
    listView.View <- gv

    // 表头点击排序（XAML 的 GridViewColumnHeader.Click 是附加路由事件——代码里 AddHandler）
    let mutable lastProp = ""
    let mutable lastDir = ListSortDirection.Ascending
    listView.AddHandler(GridViewColumnHeader.ClickEvent,
        RoutedEventHandler(fun _ e ->
            match e.OriginalSource with
            | :? GridViewColumnHeader as header ->
                let prop =
                    match string header.Column.Header with
                    | "姓名" -> "Name" | "部门" -> "Department"
                    | "薪水" -> "Salary" | "在职" -> "IsActive" | _ -> ""
                if prop.Length > 0 then
                    if lastProp = prop then
                        lastDir <- if lastDir = ListSortDirection.Ascending then ListSortDirection.Descending
                                   else ListSortDirection.Ascending
                    else
                        lastDir <- ListSortDirection.Ascending
                    lastProp <- prop
                    let view = CollectionViewSource.GetDefaultView(vm.Employees)
                    view.SortDescriptions.Clear()
                    view.SortDescriptions.Add(SortDescription(prop, lastDir))
            | _ -> ())) |> ignore

    // ② DataGrid：内置编辑/排序/选择
    let grid = DataGrid(AutoGenerateColumns = false, CanUserAddRows = false,
                        SelectionMode = DataGridSelectionMode.Single,
                        HeadersVisibility = DataGridHeadersVisibility.Column,
                        GridLinesVisibility = DataGridGridLinesVisibility.Horizontal,
                        RowHeight = 30., ColumnWidth = DataGridLength(1., DataGridLengthUnitType.Star))
    grid.SetBinding(ItemsControl.ItemsSourceProperty, Binding "Employees") |> ignore

    let textCol (header: string) (path: string) (format: string) =
        let c = DataGridTextColumn(Header = header)
        let b = Binding(path, UpdateSourceTrigger = UpdateSourceTrigger.PropertyChanged)
        if not (isNull format) then b.StringFormat <- format
        c.Binding <- b
        c
    grid.Columns.Add(textCol "姓名" "Name" null) |> ignore
    grid.Columns.Add(textCol "部门" "Department" null) |> ignore
    grid.Columns.Add(textCol "薪水" "Salary" "{0:N0}") |> ignore

    let checkCol = DataGridCheckBoxColumn(Header = "在职")
    checkCol.Binding <- Binding "IsActive"
    grid.Columns.Add checkCol |> ignore

    // 模板列：进度条相对最高薪水 21000 的比例
    let progressCell = DataTemplate()
    let pb = FrameworkElementFactory(typeof<ProgressBar>)
    pb.SetValue(ProgressBar.MinimumProperty, 0.)
    pb.SetValue(ProgressBar.MaximumProperty, 21000.)
    pb.SetValue(ProgressBar.HeightProperty, 12.)
    pb.SetBinding(ProgressBar.ValueProperty, Binding "Salary")
    progressCell.VisualTree <- pb
    let tplCol = DataGridTemplateColumn(Header = "薪资水位", CellTemplate = progressCell)
    grid.Columns.Add tplCol |> ignore

    let panel = StackPanel(Margin = Thickness 16.)
    panel.Children.Add(TextBlock(Text = "① ListView + GridView：列结构自己搭，表头可点排序（试试点「薪水」）",
                                 FontWeight = FontWeights.Bold, Margin = Thickness(0., 0., 0., 6.))) |> ignore
    panel.Children.Add listView |> ignore
    panel.Children.Add(TextBlock(Text = "② DataGrid：内置编辑/排序/选择。双击单元格直接改，改完 INPC 自动刷（ListView 那份也跟着变）",
                                 FontWeight = FontWeights.Bold, Margin = Thickness(0., 18., 0., 6.),
                                 TextWrapping = TextWrapping.Wrap)) |> ignore
    panel.Children.Add grid |> ignore

    window.Content <- ScrollViewer(VerticalScrollBarVisibility = ScrollBarVisibility.Auto, Content = panel)
    window.DataContext <- vm
    Application().Run window
