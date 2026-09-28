// 06 布局实验室（C++/CLI 版）：与 csharp/ 版功能一致。
// 注意两处属性名遮蔽：Viewbox::Stretch 属性与 Stretch 枚举同名——赋值右侧要全限定。
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Media;

namespace LayoutLabCpp {

    public ref class MainWindow : public Window
    {
    private:
        Viewbox^ _scaleBox;
        Border^ _col1;
        Border^ _col2;
        Border^ _col3;
        TextBlock^ _sizeReport;

        static Brush^ BrushFromHex(String^ hex)
        {
            Color c = (Color)ColorConverter::ConvertFromString(hex);
            return gcnew SolidColorBrush(c);
        }

        static TextBlock^ Note(String^ text)
        {
            TextBlock^ t = gcnew TextBlock();
            t->Text = text;
            t->Foreground = gcnew SolidColorBrush(Color::FromRgb(0x55, 0x55, 0x55));
            return t;
        }

        // 一行 label/编辑，标签列挂 SharedSizeGroup
        static Grid^ SharedRow(String^ label, String^ value)
        {
            Grid^ g = gcnew Grid();
            g->Margin = Thickness(0, 0, 0, 6);
            ColumnDefinition^ c0 = gcnew ColumnDefinition();
            c0->Width = GridLength::Auto;
            c0->SharedSizeGroup = L"label";
            ColumnDefinition^ c1 = gcnew ColumnDefinition();
            c1->Width = GridLength(1.0, GridUnitType::Star);
            g->ColumnDefinitions->Add(c0);
            g->ColumnDefinitions->Add(c1);
            TextBlock^ l = gcnew TextBlock();
            l->Text = String::Concat(label, L"："); l->FontWeight = FontWeights::Bold;
            TextBox^ box = gcnew TextBox(); box->Text = value;
            Grid::SetColumn(box, 1);
            g->Children->Add(l); g->Children->Add(box);
            return g;
        }

        static TabItem^ Tab(String^ header, Object^ content)
        {
            TabItem^ t = gcnew TabItem();
            t->Header = header;
            t->Content = content;
            return t;
        }

    public:
        MainWindow()
        {
            Title = L"布局实验室 (C++/CLI)";
            Width = 640; Height = 420;

            TabControl^ tabs = gcnew TabControl();
            tabs->Margin = Thickness(8);

            // ── Tab① 共享尺寸 ──
            StackPanel^ tab1 = gcnew StackPanel();
            tab1->Margin = Thickness(12);
            Grid::SetIsSharedSizeScope(tab1, true);   // XAML 的 Grid.IsSharedSizeScope="True"
            tab1->Children->Add(Note(L"两个独立的 Grid，标签列却能对齐——SharedSizeGroup 的功劳"));
            tab1->Children->Add(SharedRow(L"姓名", L"王小明"));
            tab1->Children->Add(SharedRow(L"电子邮箱地址", L"xiaoming@example.com"));
            tab1->Children->Add(SharedRow(L"部门", L"研发中心"));
            tabs->Items->Add(Tab(L"共享尺寸", tab1));

            // ── Tab② Viewbox ──
            _scaleBox = gcnew Viewbox();
            _scaleBox->Stretch = System::Windows::Media::Stretch::Uniform;
            StackPanel^ fixedPanel = gcnew StackPanel();
            fixedPanel->Width = 300; fixedPanel->Height = 120;
            fixedPanel->Background = Brushes::AliceBlue;
            TextBlock^ cap = gcnew TextBlock();
            cap->Text = L"我是 300×120 的固定面板"; cap->FontSize = 16;
            cap->HorizontalAlignment = System::Windows::HorizontalAlignment::Center;
            cap->Margin = Thickness(8);
            Button^ innerBtn = gcnew Button();
            innerBtn->Content = L"窗口再小我也完整";
            innerBtn->Width = 160; innerBtn->Height = 30;
            innerBtn->HorizontalAlignment = System::Windows::HorizontalAlignment::Center;
            fixedPanel->Children->Add(cap);
            fixedPanel->Children->Add(innerBtn);
            _scaleBox->Child = fixedPanel;   // Viewbox 是 Decorator：子元素属性叫 Child，不叫 Content

            array<String^>^ modes = { L"Uniform（等比）", L"Fill（拉伸）", L"None（原样）" };
            array<System::Windows::Media::Stretch>^ values = {
                System::Windows::Media::Stretch::Uniform, System::Windows::Media::Stretch::Fill, System::Windows::Media::Stretch::None };
            StackPanel^ radioPanel = gcnew StackPanel();
            radioPanel->Orientation = System::Windows::Controls::Orientation::Horizontal;
            for (int i = 0; i < 3; i++)
            {
                RadioButton^ r = gcnew RadioButton();
                r->Content = modes[i];
                r->IsChecked = (i == 0);
                r->Margin = Thickness(0, 0, i == 0 ? 16 : 8, 0);
                r->Checked += gcnew RoutedEventHandler(this, &MainWindow::OnStretchChecked);
                r->Tag = values[i];   // C++/CLI 没有 lambda 捕获——用 Tag 捺带模式，处理器里取回
            }

            StackPanel^ tab2Top = gcnew StackPanel();
            tab2Top->Margin = Thickness(0, 0, 0, 10);
            tab2Top->Children->Add(Note(L"下面这块面板固定 300×120，拖动窗口大小看它如何整体缩放"));
            tab2Top->Children->Add(radioPanel);
            DockPanel^ tab2 = gcnew DockPanel();
            tab2->Margin = Thickness(12);
            DockPanel::SetDock(tab2Top, Dock::Top);
            tab2->Children->Add(tab2Top);
            Border^ boxBorder = gcnew Border();
            boxBorder->BorderBrush = BrushFromHex(L"#BBBBBB");
            boxBorder->BorderThickness = Thickness(1);
            boxBorder->Background = BrushFromHex(L"#FAFAFA");
            boxBorder->Child = _scaleBox;
            tab2->Children->Add(boxBorder);
            tabs->Items->Add(Tab(L"Viewbox 缩放", tab2));

            // ── Tab③ 滚动与折行 ──
            WrapPanel^ chipPanel = gcnew WrapPanel();
            array<String^>^ hexes = { L"#3B82F6", L"#10B981", L"#F59E0B", L"#EF4444", L"#8B5CF6", L"#14B8A6" };
            for (int i = 1; i <= 50; i++)
            {
                Border^ chip = gcnew Border();
                chip->Background = BrushFromHex(hexes[(i - 1) % 6]);
                chip->CornerRadius = CornerRadius(12);
                chip->Padding = Thickness(12, 5, 12, 5);
                chip->Margin = Thickness(0, 0, 8, 8);
                TextBlock^ label = gcnew TextBlock();
                label->Text = String::Format(L"标签 {0:D2}", i);
                label->Foreground = Brushes::White;
                chip->Child = label;
                chipPanel->Children->Add(chip);
            }
            TextBlock^ tab3Top = Note(L"50 个标签放进 WrapPanel，宽度不够自动折行；整体再套 ScrollViewer 保证滚得动");
            tab3Top->TextWrapping = TextWrapping::Wrap;
            tab3Top->Margin = Thickness(0, 0, 0, 10);
            DockPanel^ tab3 = gcnew DockPanel();
            tab3->Margin = Thickness(12);
            DockPanel::SetDock(tab3Top, Dock::Top);
            tab3->Children->Add(tab3Top);
            ScrollViewer^ scroll = gcnew ScrollViewer();
            scroll->VerticalScrollBarVisibility = ScrollBarVisibility::Auto;
            scroll->Content = chipPanel;
            tab3->Children->Add(scroll);
            tabs->Items->Add(Tab(L"滚动与折行", tab3));

            // ── Tab④ 星号与 Auto ──
            _col1 = gcnew Border();
            _col1->Background = BrushFromHex(L"#DBEAFE"); _col1->Margin = Thickness(0, 0, 4, 0);
            _col1->Child = Centered(L"1*");
            _col2 = gcnew Border();
            _col2->Background = BrushFromHex(L"#DCFCE7"); _col2->Margin = Thickness(0, 0, 4, 0);
            _col2->Child = Centered(L"2*");
            _col3 = gcnew Border();
            _col3->Background = BrushFromHex(L"#FEF3C7");
            TextBlock^ autoLabel = gcnew TextBlock();
            autoLabel->Text = L"Auto 自动列";
            autoLabel->Margin = Thickness(12, 0, 12, 0);
            autoLabel->VerticalAlignment = System::Windows::VerticalAlignment::Center;
            _col3->Child = autoLabel;

            Grid^ starGrid = gcnew Grid();
            ColumnDefinition^ s0 = gcnew ColumnDefinition();
            s0->Width = GridLength(1.0, GridUnitType::Star); s0->MinWidth = 80;
            ColumnDefinition^ s1 = gcnew ColumnDefinition();
            s1->Width = GridLength(2.0, GridUnitType::Star); s1->MinWidth = 120;
            ColumnDefinition^ s2 = gcnew ColumnDefinition();
            s2->Width = GridLength::Auto;
            starGrid->ColumnDefinitions->Add(s0);
            starGrid->ColumnDefinitions->Add(s1);
            starGrid->ColumnDefinitions->Add(s2);
            Grid::SetColumn(_col2, 1); Grid::SetColumn(_col3, 2);
            starGrid->Children->Add(_col1); starGrid->Children->Add(_col2); starGrid->Children->Add(_col3);
            starGrid->SizeChanged += gcnew SizeChangedEventHandler(this, &MainWindow::OnStarGridResized);

            _sizeReport = Note(L"");

            Grid^ tab4 = gcnew Grid();
            tab4->Margin = Thickness(12);
            RowDefinition^ r0 = gcnew RowDefinition(); r0->Height = GridLength::Auto;
            RowDefinition^ r1 = gcnew RowDefinition(); r1->Height = GridLength(1.0, GridUnitType::Star);
            RowDefinition^ r2 = gcnew RowDefinition(); r2->Height = GridLength::Auto;
            tab4->RowDefinitions->Add(r0); tab4->RowDefinitions->Add(r1); tab4->RowDefinitions->Add(r2);
            TextBlock^ desc = Note(L"三列宽度 1* : 2* : Auto。拖动窗口宽度：前两列按 1:2 瓜分剩余空间，第三列永远刚好包住内容");
            desc->TextWrapping = TextWrapping::Wrap;
            desc->Margin = Thickness(0, 0, 0, 10);
            Grid::SetRow(desc, 0); Grid::SetRow(starGrid, 1); Grid::SetRow(_sizeReport, 2);
            _sizeReport->Margin = Thickness(0, 10, 0, 0);
            tab4->Children->Add(desc); tab4->Children->Add(starGrid); tab4->Children->Add(_sizeReport);
            tabs->Items->Add(Tab(L"星号与 Auto", tab4));

            Content = tabs;
        }

    private:
        static TextBlock^ Centered(String^ text)
        {
            TextBlock^ t = gcnew TextBlock();
            t->Text = text;
            t->HorizontalAlignment = System::Windows::HorizontalAlignment::Center;
            t->VerticalAlignment = System::Windows::VerticalAlignment::Center;
            return t;
        }

        void OnStretchChecked(Object^ sender, RoutedEventArgs^ e)
        {
            RadioButton^ r = safe_cast<RadioButton^>(sender);
            _scaleBox->Stretch = safe_cast<System::Windows::Media::Stretch>(r->Tag);
        }

        void OnStarGridResized(Object^ sender, SizeChangedEventArgs^ e)
        {
            _sizeReport->Text = String::Format(L"实际列宽  1* → {0:F0}px   2* → {1:F0}px   Auto → {2:F0}px",
                _col1->ActualWidth, _col2->ActualWidth, _col3->ActualWidth);
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
