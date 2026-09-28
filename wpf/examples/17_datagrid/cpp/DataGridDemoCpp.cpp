// 17 ListView 与 DataGrid（C++/CLI 版）：与 csharp/ 版功能一致。
// XAML 的 GridViewColumnHeader.Click 是附加路由事件——代码里 listView->AddHandler 挂。
using namespace System;
using namespace System::Collections::ObjectModel;
using namespace System::ComponentModel;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Data;
using namespace System::Windows::Media;

namespace DataGridDemoCpp {

    public ref class Employee : public INotifyPropertyChanged
    {
    private:
        String^ _name;
        String^ _dept;
        Decimal _salary;
        bool _isActive;
    public:
        virtual event PropertyChangedEventHandler^ PropertyChanged;

        Employee(String^ name, String^ dept, Decimal salary)
        {
            _name = name; _dept = dept; _salary = salary; _isActive = true;
        }

        property String^ Name
        {
            String^ get() { return _name; }
            void set(String^ value) { _name = value; PropertyChanged(this, gcnew PropertyChangedEventArgs(L"Name")); }
        }
        property String^ Department
        {
            String^ get() { return _dept; }
            void set(String^ value) { _dept = value; PropertyChanged(this, gcnew PropertyChangedEventArgs(L"Department")); }
        }
        property Decimal Salary
        {
            Decimal get() { return _salary; }
            void set(Decimal value)
            {
                _salary = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"Salary"));
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"IsHighSalary"));   // 派生属性联动
            }
        }
        // 派生状态：模板触发器只做等值比较（C++/CLI 没有 m 后缀，Decimal(18000) 造字面量）
        property bool IsHighSalary { bool get() { return _salary >= Decimal(18000); } }
        property bool IsActive
        {
            bool get() { return _isActive; }
            void set(bool value) { _isActive = value; PropertyChanged(this, gcnew PropertyChangedEventArgs(L"IsActive")); }
        }
    };

    public ref class EmployeesViewModel
    {
    public:
        EmployeesViewModel()
        {
            Employees = gcnew ObservableCollection<Employee^>();
            array<String^>^ names = { L"张三", L"李四", L"王五", L"赵六", L"孙七" };
            array<String^>^ depts = { L"研发", L"设计", L"研发", L"测试", L"研发" };
            array<int>^ salaries = { 18000, 15000, 21000, 13000, 17500 };
            for (int i = 0; i < 5; i++)
                Employees->Add(gcnew Employee(names[i], depts[i], Decimal(salaries[i])));
        }
        property ObservableCollection<Employee^>^ Employees;
    };

    public ref class MainWindow : public Window
    {
    private:
        EmployeesViewModel^ _vm;
        String^ _lastProp;
        ListSortDirection _lastDir;

        static SolidColorBrush^ BrushFromHex(String^ hex)
        {
            Color c = (Color)ColorConverter::ConvertFromString(hex);
            return gcnew SolidColorBrush(c);
        }

        DataTemplate^ BuildSalaryCell()
        {
            FrameworkElementFactory^ tb = gcnew FrameworkElementFactory(TextBlock::typeid);
            tb->SetValue(TextBlock::HorizontalAlignmentProperty, System::Windows::HorizontalAlignment::Right);
            Binding^ b = gcnew Binding(L"Salary");
            b->StringFormat = L"￥{0:N0}";
            tb->SetBinding(TextBlock::TextProperty, b);
            System::Windows::Style^ st = gcnew System::Windows::Style(TextBlock::typeid);
            st->Setters->Add(gcnew Setter(TextBlock::ForegroundProperty, BrushFromHex(L"#334155")));
            DataTrigger^ high = gcnew DataTrigger();
            high->Binding = gcnew Binding(L"IsHighSalary");
            high->Value = true;
            high->Setters->Add(gcnew Setter(TextBlock::ForegroundProperty, BrushFromHex(L"#2563EB")));
            st->Triggers->Add(high);
            tb->SetValue(FrameworkElement::StyleProperty, st);
            DataTemplate^ dt = gcnew DataTemplate();
            dt->VisualTree = tb;
            return dt;
        }

    public:
        MainWindow()
        {
            Title = L"列表数据：ListView 与 DataGrid (C++/CLI)";
            Width = 600; Height = 560;
            _vm = gcnew EmployeesViewModel();
            DataContext = _vm;
            _lastProp = L"";
            _lastDir = ListSortDirection::Ascending;

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(16);

            // ① ListView + GridView
            ListView^ listView = gcnew ListView();
            listView->SetBinding(ItemsControl::ItemsSourceProperty, gcnew Binding(L"Employees"));

            GridView^ gv = gcnew GridView();
            array<String^>^ headers = { L"姓名", L"部门" };
            array<String^>^ paths = { L"Name", L"Department" };
            for (int i = 0; i < 2; i++)
            {
                GridViewColumn^ col = gcnew GridViewColumn();
                col->Header = headers[i];
                col->Width = 90;
                col->DisplayMemberBinding = gcnew Binding(paths[i]);
                gv->Columns->Add(col);
            }
            GridViewColumn^ salaryCol = gcnew GridViewColumn();
            salaryCol->Header = L"薪水"; salaryCol->Width = 110;
            salaryCol->CellTemplate = BuildSalaryCell();
            gv->Columns->Add(salaryCol);

            DataTemplate^ activeCell = gcnew DataTemplate();
            FrameworkElementFactory^ cbF = gcnew FrameworkElementFactory(CheckBox::typeid);
            cbF->SetBinding(CheckBox::IsCheckedProperty, gcnew Binding(L"IsActive"));
            cbF->SetValue(FrameworkElement::HorizontalAlignmentProperty, System::Windows::HorizontalAlignment::Center);
            activeCell->VisualTree = cbF;
            GridViewColumn^ activeCol = gcnew GridViewColumn();
            activeCol->Header = L"在职"; activeCol->Width = 60;
            activeCol->CellTemplate = activeCell;
            gv->Columns->Add(activeCol);
            listView->View = gv;

            // 表头点击排序：附加路由事件用 AddHandler 挂
            listView->AddHandler(GridViewColumnHeader::ClickEvent,
                gcnew RoutedEventHandler(this, &MainWindow::OnHeaderClick));

            // ② DataGrid
            DataGrid^ grid = gcnew DataGrid();
            grid->AutoGenerateColumns = false;
            grid->CanUserAddRows = false;
            grid->SelectionMode = Controls::DataGridSelectionMode::Single;
            grid->HeadersVisibility = Controls::DataGridHeadersVisibility::Column;
            grid->GridLinesVisibility = Controls::DataGridGridLinesVisibility::Horizontal;
            grid->RowHeight = 30;
            grid->ColumnWidth = DataGridLength(1.0, DataGridLengthUnitType::Star);
            grid->SetBinding(ItemsControl::ItemsSourceProperty, gcnew Binding(L"Employees"));

            array<String^>^ colHeads = { L"姓名", L"部门", L"薪水" };
            array<String^>^ colPaths = { L"Name", L"Department", L"Salary" };
            array<String^>^ colFormats = { nullptr, nullptr, L"{0:N0}" };
            for (int i = 0; i < 3; i++)
            {
                DataGridTextColumn^ col = gcnew DataGridTextColumn();
                col->Header = colHeads[i];
                Binding^ b = gcnew Binding(colPaths[i]);
                b->UpdateSourceTrigger = UpdateSourceTrigger::PropertyChanged;
                if (colFormats[i] != nullptr) b->StringFormat = colFormats[i];
                col->Binding = b;
                grid->Columns->Add(col);
            }
            DataGridCheckBoxColumn^ checkCol = gcnew DataGridCheckBoxColumn();
            checkCol->Header = L"在职";
            checkCol->Binding = gcnew Binding(L"IsActive");
            grid->Columns->Add(checkCol);

            DataTemplate^ progressCell = gcnew DataTemplate();
            FrameworkElementFactory^ pb = gcnew FrameworkElementFactory(ProgressBar::typeid);
            pb->SetValue(ProgressBar::MinimumProperty, 0.0);
            pb->SetValue(ProgressBar::MaximumProperty, 21000.0);
            pb->SetValue(ProgressBar::HeightProperty, 12.0);
            pb->SetBinding(ProgressBar::ValueProperty, gcnew Binding(L"Salary"));
            progressCell->VisualTree = pb;
            DataGridTemplateColumn^ tplCol = gcnew DataGridTemplateColumn();
            tplCol->Header = L"薪资水位";
            tplCol->CellTemplate = progressCell;
            grid->Columns->Add(tplCol);

            TextBlock^ t1 = gcnew TextBlock();
            t1->Text = L"① ListView + GridView：列结构自己搭，表头可点排序（试试点「薪水」）";
            t1->FontWeight = FontWeights::Bold; t1->Margin = Thickness(0, 0, 0, 6);
            TextBlock^ t2 = gcnew TextBlock();
            t2->Text = L"② DataGrid：内置编辑/排序/选择。双击单元格直接改，改完 INPC 自动刷（ListView 那份也跟着变）";
            t2->FontWeight = FontWeights::Bold; t2->Margin = Thickness(0, 18, 0, 6);
            t2->TextWrapping = TextWrapping::Wrap;

            panel->Children->Add(t1);
            panel->Children->Add(listView);
            panel->Children->Add(t2);
            panel->Children->Add(grid);

            ScrollViewer^ scroll = gcnew ScrollViewer();
            scroll->VerticalScrollBarVisibility = ScrollBarVisibility::Auto;
            scroll->Content = panel;
            Content = scroll;
        }

    private:
        void OnHeaderClick(Object^ sender, RoutedEventArgs^ e)
        {
            GridViewColumnHeader^ header = dynamic_cast<GridViewColumnHeader^>(e->OriginalSource);
            if (header == nullptr) return;

            String^ prop = L"";
            String^ h = (String^)header->Column->Header;
            if (h == L"姓名") prop = L"Name";
            else if (h == L"部门") prop = L"Department";
            else if (h == L"薪水") prop = L"Salary";
            else if (h == L"在职") prop = L"IsActive";
            if (prop->Length == 0) return;

            if (_lastProp == prop)
                _lastDir = _lastDir == ListSortDirection::Ascending
                    ? ListSortDirection::Descending : ListSortDirection::Ascending;
            else
                _lastDir = ListSortDirection::Ascending;
            _lastProp = prop;

            ICollectionView^ view = CollectionViewSource::GetDefaultView(_vm->Employees);
            view->SortDescriptions->Clear();
            view->SortDescriptions->Add(SortDescription(prop, _lastDir));
        }
    };

    public ref class App
    {
    public:
        static void Run()
        {
            Application^ app = gcnew Application();
            app->Run(gcnew MainWindow());
        }
    };
}
