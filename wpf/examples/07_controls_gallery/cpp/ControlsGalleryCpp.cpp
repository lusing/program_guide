// 07 核心控件画廊（C++/CLI 版）：与 csharp/ 版功能一致。
// 事件签名差异是本章重点——每种事件一个专属委托类型：
//   TextChanged → TextChangedEventHandler；SelectionChanged → SelectionChangedEventHandler
//   ValueChanged → RoutedPropertyChangedEventHandler<double>；DatePicker → EventHandler<SelectionChangedEventArgs^>
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Controls::Primitives;   // StatusBar / Selector 在 Primitives
using namespace System::Windows::Media;

namespace ControlsGalleryCpp {

    public ref class MainWindow : public Window
    {
    private:
        TextBlock^ _status;

    public:
        MainWindow()
        {
            Title = L"控件画廊 (C++/CLI)";
            Width = 560; Height = 620;

            _status = gcnew TextBlock();
            _status->Text = L"等待操作…";

            ScrollViewer^ scroll = gcnew ScrollViewer();
            scroll->VerticalScrollBarVisibility = ScrollBarVisibility::Auto;
            StackPanel^ list = gcnew StackPanel();
            scroll->Content = list;

            // ── 文本输入 ──
            StackPanel^ textBody = gcnew StackPanel();
            TextBox^ single = gcnew TextBox();
            single->Text = L"单行文本框"; single->Margin = Thickness(0, 0, 0, 6);
            single->TextChanged += gcnew TextChangedEventHandler(this, &MainWindow::OnTextChanged);
            TextBox^ multi = gcnew TextBox();
            multi->Text = L"多行文本框\n第二行";
            multi->AcceptsReturn = true; multi->TextWrapping = TextWrapping::Wrap;
            multi->Height = 60; multi->VerticalScrollBarVisibility = ScrollBarVisibility::Auto;
            multi->Margin = Thickness(0, 0, 0, 6);
            PasswordBox^ pwd = gcnew PasswordBox();
            pwd->Password = L"12345"; pwd->Width = 160;
            pwd->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            pwd->PasswordChanged += gcnew RoutedEventHandler(this, &MainWindow::OnAnyRouted);
            textBody->Children->Add(single); textBody->Children->Add(multi); textBody->Children->Add(pwd);
            list->Children->Add(Group(L"文本输入", textBody));

            // ── 选择 ──
            StackPanel^ selectBody = gcnew StackPanel();
            CheckBox^ check1 = gcnew CheckBox();
            check1->Content = L"普通复选框"; check1->IsChecked = true;
            check1->Margin = Thickness(0, 0, 0, 6);
            check1->Checked += gcnew RoutedEventHandler(this, &MainWindow::OnAnyRouted);
            check1->Unchecked += gcnew RoutedEventHandler(this, &MainWindow::OnAnyRouted);
            CheckBox^ check2 = gcnew CheckBox();
            check2->Content = L"三态复选框（IsChecked 是 bool?）";
            check2->IsThreeState = true; check2->Margin = Thickness(0, 0, 0, 6);
            StackPanel^ radioRow = gcnew StackPanel();
            radioRow->Orientation = System::Windows::Controls::Orientation::Horizontal;
            radioRow->Margin = Thickness(0, 0, 0, 6);
            RadioButton^ radioA = gcnew RadioButton();
            radioA->Content = L"选项 A"; radioA->GroupName = L"g1"; radioA->IsChecked = true;
            radioA->Margin = Thickness(0, 0, 16, 0);
            radioA->Checked += gcnew RoutedEventHandler(this, &MainWindow::OnAnyRouted);
            RadioButton^ radioB = gcnew RadioButton();
            radioB->Content = L"选项 B"; radioB->GroupName = L"g1";
            radioB->Checked += gcnew RoutedEventHandler(this, &MainWindow::OnAnyRouted);
            radioRow->Children->Add(radioA); radioRow->Children->Add(radioB);
            ComboBox^ cityBox = gcnew ComboBox();
            cityBox->Width = 140;
            array<String^>^ cities = { L"北京", L"上海", L"深圳" };
            for (int i = 0; i < cities->Length; i++)
            {
                ComboBoxItem^ item = gcnew ComboBoxItem();
                item->Content = cities[i];
                item->IsSelected = (i == 0);
                cityBox->Items->Add(item);
            }
            cityBox->SelectionChanged += gcnew SelectionChangedEventHandler(this, &MainWindow::OnComboChanged);
            selectBody->Children->Add(check1); selectBody->Children->Add(check2);
            selectBody->Children->Add(radioRow); selectBody->Children->Add(cityBox);
            list->Children->Add(Group(L"选择", selectBody));

            // ── 数值与进度 ──
            StackPanel^ numberBody = gcnew StackPanel();
            ProgressBar^ progress = gcnew ProgressBar();
            progress->Minimum = 0; progress->Maximum = 100; progress->Height = 18; progress->Value = 40;
            Slider^ slider = gcnew Slider();
            slider->Minimum = 0; slider->Maximum = 100; slider->Value = 40;
            slider->TickFrequency = 10; slider->IsSnapToTickEnabled = true;
            slider->Margin = Thickness(0, 0, 0, 6);
            slider->ValueChanged += gcnew RoutedPropertyChangedEventHandler<double>(this, &MainWindow::OnSliderChanged);
            numberBody->Children->Add(slider); numberBody->Children->Add(progress);
            list->Children->Add(Group(L"数值与进度", numberBody));

            // ── 列表 ──
            ListBox^ fruitBox = gcnew ListBox();
            fruitBox->Height = 110;
            array<String^>^ fruits = { L"苹果", L"香蕉", L"樱桃", L"榴莲" };
            for each (String^ f in fruits)
            {
                ListBoxItem^ item = gcnew ListBoxItem();
                item->Content = f;
                fruitBox->Items->Add(item);
            }
            fruitBox->SelectionChanged += gcnew SelectionChangedEventHandler(this, &MainWindow::OnListChanged);
            StackPanel^ listBody = gcnew StackPanel();
            listBody->Children->Add(fruitBox);   // Panel 没有 Content，只有 Children
            list->Children->Add(Group(L"列表", listBody));

            // ── 菜单与工具栏（教材 4.2）──
            StackPanel^ menuBody = gcnew StackPanel();
            Menu^ menu = gcnew Menu();
            MenuItem^ fileMenu = gcnew MenuItem();
            fileMenu->Header = L"文件(_F)";
            fileMenu->Items->Add(MenuOf(L"新建(_N)", L"Ctrl+N"));
            fileMenu->Items->Add(MenuOf(L"打开(_O)", L"Ctrl+O"));
            fileMenu->Items->Add(gcnew Separator());
            fileMenu->Items->Add(MenuOf(L"退出(_X)", L"Alt+F4"));
            MenuItem^ helpMenu = gcnew MenuItem();
            helpMenu->Header = L"帮助(_H)";
            helpMenu->Items->Add(MenuOf(L"关于(_A)", nullptr));
            menu->Items->Add(fileMenu); menu->Items->Add(helpMenu);

            ToolBarTray^ tray = gcnew ToolBarTray();
            tray->Margin = Thickness(0, 6, 0, 0);
            ToolBar^ toolBar = gcnew ToolBar();
            toolBar->Items->Add(ToolOf(L"加粗"));
            toolBar->Items->Add(ToolOf(L"倾斜"));
            toolBar->Items->Add(gcnew Separator());
            ComboBox^ sizeBox = gcnew ComboBox();
            sizeBox->Width = 80; sizeBox->SelectedIndex = 0;
            ComboBoxItem^ s14 = gcnew ComboBoxItem(); s14->Content = L"14";
            ComboBoxItem^ s18 = gcnew ComboBoxItem(); s18->Content = L"18";
            sizeBox->Items->Add(s14); sizeBox->Items->Add(s18);
            toolBar->Items->Add(sizeBox);
            tray->ToolBars->Add(toolBar);
            menuBody->Children->Add(menu); menuBody->Children->Add(tray);
            list->Children->Add(Group(L"菜单与工具栏（教材 4.2）", menuBody));

            // ── 日期与手写（教材 4.5.4 / 4.8）──
            StackPanel^ dateBody = gcnew StackPanel();
            StackPanel^ dateRow = gcnew StackPanel();
            dateRow->Orientation = System::Windows::Controls::Orientation::Horizontal;
            dateRow->Margin = Thickness(0, 0, 0, 6);
            TextBlock^ cap = gcnew TextBlock();
            cap->Text = L"日期选择："; cap->VerticalAlignment = System::Windows::VerticalAlignment::Center;
            cap->Margin = Thickness(0, 0, 8, 0);
            DatePicker^ picker = gcnew DatePicker();
            picker->Width = 140;
            picker->SelectedDateChanged +=
                gcnew EventHandler<SelectionChangedEventArgs^>(this, &MainWindow::OnDateChanged);
            dateRow->Children->Add(cap); dateRow->Children->Add(picker);
            InkCanvas^ ink = gcnew InkCanvas();
            ink->Height = 110; ink->Background = Brushes::AliceBlue;
            dateBody->Children->Add(dateRow); dateBody->Children->Add(ink);
            list->Children->Add(Group(L"日期与手写（教材 4.5.4 / 4.8）", dateBody));

            // ── 其他 ──
            StackPanel^ miscBody = gcnew StackPanel();
            Button^ tipBtn = gcnew Button();
            tipBtn->Content = L"悬停我有工具提示";
            tipBtn->ToolTip = L"ToolTip 是免费的，给控件加一行说明就用它";
            tipBtn->Width = 220;
            tipBtn->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            tipBtn->Margin = Thickness(0, 0, 0, 6);
            tipBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnAnyRouted);
            Expander^ expander = gcnew Expander();
            expander->Header = L"点我展开（Expander）"; expander->IsExpanded = false;
            TextBlock^ detail = gcnew TextBlock();
            detail->Text = L"折叠面板：放次要选项，默认收起。设置中心常见。";
            detail->Margin = Thickness(8); detail->TextWrapping = TextWrapping::Wrap;
            expander->Content = detail;
            miscBody->Children->Add(tipBtn); miscBody->Children->Add(expander);
            list->Children->Add(Group(L"其他", miscBody));

            // ── 总装 ──
            TextBlock^ top = gcnew TextBlock();
            top->Text = L"每个控件的事件都汇到底部状态栏——试着操作任意一个";
            top->Margin = Thickness(0, 0, 0, 10);
            StatusBar^ statusBar = gcnew StatusBar();
            statusBar->Items->Add(_status);   // StatusBar 是 ItemsControl：子项进 Items

            DockPanel^ dock = gcnew DockPanel();
            dock->Margin = Thickness(12);
            DockPanel::SetDock(top, Dock::Top);
            DockPanel::SetDock(statusBar, Dock::Bottom);
            dock->Children->Add(top);
            dock->Children->Add(statusBar);
            dock->Children->Add(scroll);

            Content = dock;
        }

    private:
        static GroupBox^ Group(String^ header, Object^ body)
        {
            GroupBox^ gb = gcnew GroupBox();
            gb->Header = header; gb->Margin = Thickness(0, 0, 0, 10);
            gb->Content = body;
            return gb;
        }

        MenuItem^ MenuOf(String^ header, String^ gesture)
        {
            MenuItem^ m = gcnew MenuItem();
            m->Header = header;
            m->InputGestureText = gesture;
            m->Click += gcnew RoutedEventHandler(this, &MainWindow::OnMenuClick);
            return m;
        }

        Button^ ToolOf(String^ label)
        {
            Button^ b = gcnew Button();
            b->Content = label;
            b->Click += gcnew RoutedEventHandler(this, &MainWindow::OnToolClick);
            return b;
        }

        void Report(String^ message) { _status->Text = message; }

        void OnAnyRouted(Object^ sender, RoutedEventArgs^ e)
        {
            FrameworkElement^ fe = dynamic_cast<FrameworkElement^>(sender);
            String^ who = fe != nullptr ? fe->GetType()->Name : sender->GetType()->Name;
            String^ action = e->RoutedEvent != nullptr ? e->RoutedEvent->Name : L"事件";
            Report(String::Format(L"{0} 触发了 {1}", who, action));
        }

        void OnTextChanged(Object^ sender, TextChangedEventArgs^ e)
        {
            Report(L"TextBox 文本变了（TextChanged 是直接事件）");
        }

        void OnComboChanged(Object^ sender, SelectionChangedEventArgs^ e)
        {
            ComboBoxItem^ item = dynamic_cast<ComboBoxItem^>(((Selector^)sender)->SelectedItem);
            Report(String::Format(L"ComboBox 选中了 {0}", item != nullptr ? item->Content : (Object^)L"?"));
        }

        void OnListChanged(Object^ sender, SelectionChangedEventArgs^ e)
        {
            ListBoxItem^ item = dynamic_cast<ListBoxItem^>(((Selector^)sender)->SelectedItem);
            Report(String::Format(L"ListBox 选中了 {0}", item != nullptr ? item->Content : (Object^)L"?"));
        }

        void OnSliderChanged(Object^ sender, RoutedPropertyChangedEventArgs<double>^ e)
        {
            Slider^ slider = (Slider^)sender;
            // 从事件反查进度条：同 GroupBox 的兄弟节点（教学版从简）
            FrameworkElement^ panel = slider->Parent != nullptr ? dynamic_cast<FrameworkElement^>(slider->Parent) : nullptr;
            ProgressBar^ progress = nullptr;
            if (panel != nullptr)
            {
                StackPanel^ sp = dynamic_cast<StackPanel^>(panel);
                if (sp != nullptr && sp->Children->Count > 1)
                    progress = dynamic_cast<ProgressBar^>(sp->Children[1]);
            }
            if (progress != nullptr) progress->Value = e->NewValue;
            Report(String::Format(L"Slider = {0:F0}，进度条同步（事件直连演示）", e->NewValue));
        }

        void OnMenuClick(Object^ sender, RoutedEventArgs^ e)
        {
            MenuItem^ m = (MenuItem^)sender;
            Report(String::Format(L"菜单「{0}」被点击", m->Header));
        }

        void OnToolClick(Object^ sender, RoutedEventArgs^ e)
        {
            Button^ b = (Button^)sender;
            Report(String::Format(L"工具栏「{0}」被点击", b->Content));
        }

        void OnDateChanged(Object^ sender, SelectionChangedEventArgs^ e)
        {
            DatePicker^ picker = (DatePicker^)sender;
            Nullable<DateTime> d = picker->SelectedDate;
            if (d.HasValue)
                Report(String::Format(L"DatePicker 选了 {0:yyyy-MM-dd}", d));
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
