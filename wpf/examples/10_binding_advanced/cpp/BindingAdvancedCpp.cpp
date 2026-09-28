// 10 绑定进阶（C++/CLI 版）：与 csharp/ 版功能一致。
// INPC → virtual event + 直接触发（C3918：不能 if(ev!=nullptr) 判空，合成的 raise_ 自带保护）；
// CallerMemberName 在 C++/CLI 不可用——属性名手写传参。
using namespace System;
using namespace System::Collections::ObjectModel;
using namespace System::Collections::Specialized;
using namespace System::ComponentModel;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Data;
using namespace System::Windows::Media;

namespace BindingAdvancedCpp {

    // ── 转换器 ──
    public ref class BoolToVisibilityConverter : public IValueConverter
    {
    public:
        virtual Object^ Convert(Object^ value, Type^ targetType, Object^ parameter, System::Globalization::CultureInfo^ culture)
        {
            return (value != nullptr && safe_cast<bool>(value)) ? (Object^)Visibility::Visible
                                                                : (Object^)Visibility::Collapsed;
        }
        virtual Object^ ConvertBack(Object^ value, Type^ targetType, Object^ parameter, System::Globalization::CultureInfo^ culture)
        {
            if (value == nullptr) return false;
            return safe_cast<Visibility>(value) == Visibility::Visible;
        }
    };

    public ref class FullNameConverter : public IMultiValueConverter
    {
    public:
        virtual Object^ Convert(array<Object^>^ values, Type^ targetType, Object^ parameter, System::Globalization::CultureInfo^ culture)
        {
            String^ last = values->Length > 0 && values[0] != nullptr ? values[0]->ToString() : L"";
            String^ first = values->Length > 1 && values[1] != nullptr ? values[1]->ToString() : L"";
            return String::Concat(last, first);
        }
        virtual array<Object^>^ ConvertBack(Object^ value, array<Type^>^ targetTypes, Object^ parameter, System::Globalization::CultureInfo^ culture)
        {
            throw gcnew NotSupportedException(L"单向聚合，不回写");
        }
    };

    // ── INPC 实体 ──
    public ref class TaskItem : public INotifyPropertyChanged
    {
    private:
        String^ _name;
        bool _done;
    public:
        virtual event PropertyChangedEventHandler^ PropertyChanged;

        TaskItem() { _name = L""; _done = false; }

        property String^ Name
        {
            String^ get() { return _name; }
            void set(String^ value) { _name = value; PropertyChanged(this, gcnew PropertyChangedEventArgs(L"Name")); }
        }
        property bool Done
        {
            bool get() { return _done; }
            void set(bool value) { _done = value; PropertyChanged(this, gcnew PropertyChangedEventArgs(L"Done")); }
        }
    };

    public ref class MainViewModel : public INotifyPropertyChanged
    {
    private:
        String^ _firstName;
        String^ _lastName;
        double _progress;
        TaskItem^ _selectedTask;
        int _taskCount;
        bool _showStats;
    public:
        virtual event PropertyChangedEventHandler^ PropertyChanged;

        MainViewModel()
        {
            _firstName = L"三"; _lastName = L"张"; _progress = 30;
            _selectedTask = nullptr; _taskCount = 0; _showStats = true;

            Tasks = gcnew ObservableCollection<TaskItem^>();
            array<String^>^ seeds = { L"学习绑定四要素", L"实现 INPC", L"用上 ObservableCollection" };
            for each (String^ s in seeds)
            {
                TaskItem^ t = gcnew TaskItem();
                t->Name = s;
                Tasks->Add(t);
            }
            Tasks->CollectionChanged += gcnew NotifyCollectionChangedEventHandler(this, &MainViewModel::OnTasksChanged);
            _taskCount = Tasks->Count;
        }

        void OnTasksChanged(Object^ sender, NotifyCollectionChangedEventArgs^ e)
        {
            _taskCount = Tasks->Count;
            PropertyChanged(this, gcnew PropertyChangedEventArgs(L"TaskCount"));
        }

        property String^ FirstName
        {
            String^ get() { return _firstName; }
            void set(String^ value) { _firstName = value; PropertyChanged(this, gcnew PropertyChangedEventArgs(L"FirstName")); }
        }
        property String^ LastName
        {
            String^ get() { return _lastName; }
            void set(String^ value) { _lastName = value; PropertyChanged(this, gcnew PropertyChangedEventArgs(L"LastName")); }
        }
        property double Progress
        {
            double get() { return _progress; }
            void set(double value) { _progress = value; PropertyChanged(this, gcnew PropertyChangedEventArgs(L"Progress")); }
        }
        property ObservableCollection<TaskItem^>^ Tasks;
        property TaskItem^ SelectedTask
        {
            TaskItem^ get() { return _selectedTask; }
            void set(TaskItem^ value) { _selectedTask = value; PropertyChanged(this, gcnew PropertyChangedEventArgs(L"SelectedTask")); }
        }
        property int TaskCount { int get() { return _taskCount; } }
        property bool ShowStats
        {
            bool get() { return _showStats; }
            void set(bool value) { _showStats = value; PropertyChanged(this, gcnew PropertyChangedEventArgs(L"ShowStats")); }
        }

        void AddTask(String^ name)
        {
            if (String::IsNullOrWhiteSpace(name)) return;
            TaskItem^ t = gcnew TaskItem();
            t->Name = name->Trim();
            Tasks->Add(t);
        }

        void RemoveSelected()
        {
            if (_selectedTask != nullptr)
                Tasks->Remove(_selectedTask);
        }
    };

    public ref class MainWindow : public Window
    {
    private:
        MainViewModel^ _vm;
        TextBox^ _newTaskBox;

        static TextBlock^ Header(String^ text)
        {
            TextBlock^ t = gcnew TextBlock();
            t->Text = text; t->FontWeight = FontWeights::Bold; t->Margin = Thickness(0, 0, 0, 8);
            return t;
        }

    public:
        MainWindow()
        {
            Title = L"绑定进阶实验室 (C++/CLI)";
            Width = 480; Height = 520;
            _vm = gcnew MainViewModel();
            DataContext = _vm;

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(16);

            // ① MultiBinding
            TextBox^ lastBox = gcnew TextBox();
            lastBox->Width = 120; lastBox->ToolTip = L"姓"; lastBox->Margin = Thickness(0, 0, 8, 0);
            Binding^ bLast = gcnew Binding(L"LastName");
            bLast->UpdateSourceTrigger = UpdateSourceTrigger::PropertyChanged;
            lastBox->SetBinding(TextBox::TextProperty, bLast);
            TextBox^ firstBox = gcnew TextBox();
            firstBox->Width = 120; firstBox->ToolTip = L"名";
            Binding^ bFirst = gcnew Binding(L"FirstName");
            bFirst->UpdateSourceTrigger = UpdateSourceTrigger::PropertyChanged;
            firstBox->SetBinding(TextBox::TextProperty, bFirst);
            StackPanel^ nameRow = gcnew StackPanel();
            nameRow->Orientation = System::Windows::Controls::Orientation::Horizontal;
            nameRow->Margin = Thickness(0, 0, 0, 4);
            nameRow->Children->Add(lastBox); nameRow->Children->Add(firstBox);

            TextBlock^ fullName = gcnew TextBlock();
            fullName->FontSize = 20; fullName->Margin = Thickness(0, 4, 0, 16);
            MultiBinding^ mb = gcnew MultiBinding();
            mb->Converter = gcnew FullNameConverter();
            mb->Bindings->Add(gcnew Binding(L"LastName"));
            mb->Bindings->Add(gcnew Binding(L"FirstName"));
            fullName->SetBinding(TextBlock::TextProperty, mb);

            // ② 数值绑定 + StringFormat
            Slider^ slider = gcnew Slider();
            slider->Minimum = 0; slider->Maximum = 100; slider->Margin = Thickness(0, 0, 0, 4);
            slider->SetBinding(Slider::ValueProperty, gcnew Binding(L"Progress"));
            ProgressBar^ bar = gcnew ProgressBar();
            bar->Minimum = 0; bar->Maximum = 100; bar->Height = 18; bar->Margin = Thickness(0, 0, 0, 4);
            bar->SetBinding(ProgressBar::ValueProperty, gcnew Binding(L"Progress"));
            TextBlock^ pct = gcnew TextBlock();
            pct->Margin = Thickness(0, 0, 0, 16);
            Binding^ bPct = gcnew Binding(L"Progress");
            bPct->StringFormat = L"完成 {0:F0}%";
            pct->SetBinding(TextBlock::TextProperty, bPct);

            // ③ 集合绑定 + ItemTemplate（FrameworkElementFactory）
            _newTaskBox = gcnew TextBox();
            _newTaskBox->Width = 240; _newTaskBox->Margin = Thickness(0, 0, 8, 0);
            _newTaskBox->KeyDown += gcnew System::Windows::Input::KeyEventHandler(this, &MainWindow::OnNewTaskKey);
            Button^ addBtn = gcnew Button();
            addBtn->Content = L"添加"; addBtn->Width = 70;
            addBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnAdd);
            StackPanel^ inputRow = gcnew StackPanel();
            inputRow->Orientation = System::Windows::Controls::Orientation::Horizontal;
            inputRow->Margin = Thickness(0, 0, 0, 6);
            inputRow->Children->Add(_newTaskBox); inputRow->Children->Add(addBtn);

            DataTemplate^ dt = gcnew DataTemplate(TaskItem::typeid);
            FrameworkElementFactory^ row = gcnew FrameworkElementFactory(StackPanel::typeid);
            row->SetValue(StackPanel::OrientationProperty, System::Windows::Controls::Orientation::Horizontal);
            FrameworkElementFactory^ cb = gcnew FrameworkElementFactory(CheckBox::typeid);
            cb->SetBinding(CheckBox::IsCheckedProperty, gcnew Binding(L"Done"));
            cb->SetValue(FrameworkElement::VerticalAlignmentProperty, System::Windows::VerticalAlignment::Center);
            FrameworkElementFactory^ tb = gcnew FrameworkElementFactory(TextBlock::typeid);
            tb->SetBinding(TextBlock::TextProperty, gcnew Binding(L"Name"));
            tb->SetValue(FrameworkElement::MarginProperty, Thickness(8, 0, 0, 0));
            tb->SetValue(FrameworkElement::VerticalAlignmentProperty, System::Windows::VerticalAlignment::Center);
            row->AppendChild(cb);
            row->AppendChild(tb);
            dt->VisualTree = row;

            ListBox^ taskList = gcnew ListBox();
            taskList->Height = 150; taskList->Margin = Thickness(0, 0, 0, 6);
            taskList->ItemTemplate = dt;
            taskList->SetBinding(ListBox::ItemsSourceProperty, gcnew Binding(L"Tasks"));
            taskList->SetBinding(ListBox::SelectedItemProperty, gcnew Binding(L"SelectedTask"));
            Button^ removeBtn = gcnew Button();
            removeBtn->Content = L"删除选中项"; removeBtn->Width = 110;
            removeBtn->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            removeBtn->Margin = Thickness(0, 0, 0, 16);
            removeBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnRemove);

            // ④ 转换器：bool → Visibility
            CheckBox^ showCheck = gcnew CheckBox();
            showCheck->Content = L"显示统计面板（转换器演示）"; showCheck->Margin = Thickness(0, 0, 0, 6);
            showCheck->SetBinding(CheckBox::IsCheckedProperty, gcnew Binding(L"ShowStats"));
            TextBlock^ countLine = gcnew TextBlock();
            Binding^ bCount = gcnew Binding(L"TaskCount");
            bCount->StringFormat = L"共 {0} 项任务";
            countLine->SetBinding(TextBlock::TextProperty, bCount);
            TextBlock^ selectedLine = gcnew TextBlock();
            selectedLine->Foreground = Brushes::Gray;
            Binding^ bSel = gcnew Binding(L"SelectedTask.Name");
            bSel->StringFormat = L"当前选中：{0}";
            bSel->TargetNullValue = L"（无）";
            selectedLine->SetBinding(TextBlock::TextProperty, bSel);
            StackPanel^ statsBody = gcnew StackPanel();
            statsBody->Children->Add(countLine); statsBody->Children->Add(selectedLine);
            Border^ stats = gcnew Border();
            stats->Background = Brushes::WhiteSmoke;
            stats->CornerRadius = CornerRadius(8);
            stats->Padding = Thickness(12);
            stats->Child = statsBody;
            Binding^ bVis = gcnew Binding(L"ShowStats");
            bVis->Converter = gcnew BoolToVisibilityConverter();
            stats->SetBinding(UIElement::VisibilityProperty, bVis);

            panel->Children->Add(Header(L"① MultiBinding：姓 + 名 = 全名"));
            panel->Children->Add(nameRow); panel->Children->Add(fullName);
            panel->Children->Add(Header(L"② Slider 驱动进度：值格式化全靠 StringFormat"));
            panel->Children->Add(slider); panel->Children->Add(bar); panel->Children->Add(pct);
            panel->Children->Add(Header(L"③ 任务列表：ObservableCollection + 元素 INPC"));
            panel->Children->Add(inputRow); panel->Children->Add(taskList); panel->Children->Add(removeBtn);
            panel->Children->Add(showCheck); panel->Children->Add(stats);

            ScrollViewer^ scroll = gcnew ScrollViewer();
            scroll->VerticalScrollBarVisibility = ScrollBarVisibility::Auto;
            scroll->Content = panel;
            Content = scroll;
        }

    private:
        void DoAdd()
        {
            _vm->AddTask(_newTaskBox->Text);
            _newTaskBox->Text = L"";
            _newTaskBox->Focus();
        }

        void OnAdd(Object^ sender, RoutedEventArgs^ e) { DoAdd(); }

        void OnNewTaskKey(Object^ sender, System::Windows::Input::KeyEventArgs^ e)
        {
            if (e->Key == System::Windows::Input::Key::Enter) DoAdd();
        }

        void OnRemove(Object^ sender, RoutedEventArgs^ e) { _vm->RemoveSelected(); }
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
