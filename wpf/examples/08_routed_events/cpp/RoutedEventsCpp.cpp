// 08 路由事件（C++/CLI 版）：与 csharp/ 版功能一致——隧道/冒泡可视化 + 自定义路由事件（教材 6.3）。
// C++/CLI 的挂载全是 AddHandler + gcnew 委托；自定义路由事件用 static initonly RoutedEvent^。
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Input;
using namespace System::Windows::Media;

namespace RoutedEventsCpp {

    // 自定义路由事件（教材 6.3）
    public ref class AlarmButton : public Button
    {
    public:
        static initonly RoutedEvent^ AlarmEvent = EventManager::RegisterRoutedEvent(
            L"Alarm", RoutingStrategy::Bubble, RoutedEventHandler::typeid, AlarmButton::typeid);

        void RaiseAlarm()
        {
            RaiseEvent(gcnew RoutedEventArgs(AlarmEvent, this));
        }
    };

    public ref class MainWindow : public Window
    {
    private:
        ListBox^ _log;
        CheckBox^ _stopAtMiddle;
        Border^ _layerBorder;
        Grid^ _layerGrid;

        static String^ NameOf(Object^ o)
        {
            FrameworkElement^ fe = dynamic_cast<FrameworkElement^>(o);
            if (fe != nullptr && !String::IsNullOrEmpty(fe->Name)) return fe->Name;
            return o != nullptr ? o->GetType()->Name : L"?";
        }

        void Log(String^ stage, String^ eventName, Object^ sender, RoutedEventArgs^ e)
        {
            _log->Items->Add(String::Format(L"{0,-4} {1,-18} 挂载点={2,-12} 源头={3}",
                stage, eventName, NameOf(sender), NameOf(e->OriginalSource)));
            _log->ScrollIntoView(_log->Items[_log->Items->Count - 1]);
        }

        // 挂隧道（根 → 子）；maybeStop=true 的层负责演示 e.Handled 截停
        void MountTunnel(UIElement^ el, String^ label, bool maybeStop)
        {
            el->AddHandler(UIElement::PreviewMouseDownEvent,
                gcnew MouseButtonEventHandler(this, &MainWindow::OnPreviewDown), true);
            _tunnelLabels[el] = label;              // C++/CLI 没有 lambda 捕获——标签走查表
            _stopLayers->Add(el, maybeStop);
        }

        void MountBubble(UIElement^ el, String^ label)
        {
            el->AddHandler(UIElement::MouseDownEvent,
                gcnew MouseButtonEventHandler(this, &MainWindow::OnDown), true);
            _bubbleLabels[el] = label;
        }

    private:
        System::Collections::Generic::Dictionary<UIElement^, String^>^ _tunnelLabels;
        System::Collections::Generic::Dictionary<UIElement^, String^>^ _bubbleLabels;
        System::Collections::Generic::Dictionary<UIElement^, bool>^ _stopLayers;

    public:
        MainWindow()
        {
            Title = L"路由事件可视化 (C++/CLI)";
            Width = 560; Height = 480;

            _tunnelLabels = gcnew System::Collections::Generic::Dictionary<UIElement^, String^>();
            _bubbleLabels = gcnew System::Collections::Generic::Dictionary<UIElement^, String^>();
            _stopLayers = gcnew System::Collections::Generic::Dictionary<UIElement^, bool>();

            _log = gcnew ListBox();
            _log->FontFamily = gcnew System::Windows::Media::FontFamily(L"Consolas");

            _stopAtMiddle = gcnew CheckBox();
            _stopAtMiddle->Content = L"在中间层（Grid）截停：e.Handled = true";
            _stopAtMiddle->Margin = Thickness(0, 6, 0, 0);

            Button^ clear = gcnew Button();
            clear->Content = L"清空"; clear->Width = 70;
            clear->VerticalAlignment = System::Windows::VerticalAlignment::Bottom;
            clear->Click += gcnew RoutedEventHandler(this, &MainWindow::OnClear);

            // 三层容器：Window → Border → Grid → StackPanel → 按钮
            Button^ deep = gcnew Button();
            deep->Content = L"最深处的按钮"; deep->Padding = Thickness(12, 8, 12, 8);
            AlarmButton^ custom = gcnew AlarmButton();
            custom->Content = L"自定义事件"; custom->Padding = Thickness(12, 8, 12, 8);
            custom->Margin = Thickness(12, 0, 0, 0);
            custom->Click += gcnew RoutedEventHandler(this, &MainWindow::OnRaiseAlarm);

            StackPanel^ layerStack = gcnew StackPanel();
            layerStack->Orientation = System::Windows::Controls::Orientation::Horizontal;
            layerStack->HorizontalAlignment = System::Windows::HorizontalAlignment::Center;
            layerStack->VerticalAlignment = System::Windows::VerticalAlignment::Center;
            TextBlock^ cap = gcnew TextBlock();
            cap->Text = L"StackPanel 层"; cap->VerticalAlignment = System::Windows::VerticalAlignment::Center;
            cap->Margin = Thickness(0, 0, 12, 0);
            layerStack->Children->Add(cap);
            layerStack->Children->Add(deep);
            layerStack->Children->Add(custom);

            _layerGrid = gcnew Grid();
            _layerGrid->Background = gcnew SolidColorBrush(Color::FromRgb(0xF1, 0xF5, 0xF9));
            _layerGrid->Margin = Thickness(16);
            _layerGrid->Children->Add(layerStack);

            _layerBorder = gcnew Border();
            _layerBorder->BorderBrush = gcnew SolidColorBrush(Color::FromRgb(0x94, 0xA3, 0xB8));
            _layerBorder->BorderThickness = Thickness(2);
            _layerBorder->CornerRadius = CornerRadius(8);
            _layerBorder->Padding = Thickness(16);
            _layerBorder->Margin = Thickness(0, 0, 0, 12);
            _layerBorder->Child = _layerGrid;

            // 挂载：隧道 + 冒泡
            MountTunnel(this, L"Window.PreviewMouseDown", false);
            MountTunnel(_layerBorder, L"Border.PreviewMouseDown", false);
            MountTunnel(_layerGrid, L"Grid.PreviewMouseDown", true);
            MountTunnel(deep, L"Button.PreviewMouseDown", false);
            MountTunnel(custom, L"Button.PreviewMouseDown", false);
            MountBubble(deep, L"Button.MouseDown");
            MountBubble(custom, L"Button.MouseDown");
            MountBubble(_layerGrid, L"Grid.MouseDown");
            MountBubble(_layerBorder, L"Border.MouseDown");
            MountBubble(this, L"Window.MouseDown");

            deep->Click += gcnew RoutedEventHandler(this, &MainWindow::OnDeepClick);
            // 自定义路由事件：挂到 window 上看它从按钮一路冒泡上来
            AddHandler(AlarmButton::AlarmEvent, gcnew RoutedEventHandler(this, &MainWindow::OnAlarmReached));

            // 总装
            Grid^ bottom = gcnew Grid();
            ColumnDefinition^ b0 = gcnew ColumnDefinition(); b0->Width = GridLength(1.0, GridUnitType::Star);
            ColumnDefinition^ b1 = gcnew ColumnDefinition(); b1->Width = GridLength::Auto;
            bottom->ColumnDefinitions->Add(b0); bottom->ColumnDefinitions->Add(b1);
            Grid::SetColumn(clear, 1);
            bottom->Children->Add(_log); bottom->Children->Add(clear);

            TextBlock^ intro = gcnew TextBlock();
            intro->Text = L"点下面的按钮或空白处，看事件如何先隧道（根→子）再冒泡（子→根）穿过三层容器";
            intro->TextWrapping = TextWrapping::Wrap;
            StackPanel^ top = gcnew StackPanel();
            top->Margin = Thickness(0, 0, 0, 10);
            top->Children->Add(intro); top->Children->Add(_stopAtMiddle);

            DockPanel^ dock = gcnew DockPanel();
            dock->Margin = Thickness(12);
            DockPanel::SetDock(top, Dock::Top);
            DockPanel::SetDock(bottom, Dock::Bottom);
            dock->Children->Add(top); dock->Children->Add(bottom); dock->Children->Add(_layerBorder);

            Content = dock;
        }

    private:
        void OnPreviewDown(Object^ sender, MouseButtonEventArgs^ e)
        {
            UIElement^ el = (UIElement^)sender;
            Log(L"隧道", _tunnelLabels[el], sender, e);
            // Nullable<bool> 与字面量比较没有可用的 operator==——判 HasValue/GetValueOrDefault
            if (_stopLayers[el] && _stopAtMiddle->IsChecked.GetValueOrDefault())
            {
                e->Handled = true;
                Log(L"……", L"截停 e.Handled", sender, e);
            }
        }

        void OnDown(Object^ sender, MouseButtonEventArgs^ e)
        {
            UIElement^ el = (UIElement^)sender;
            Log(L"冒泡", _bubbleLabels[el], sender, e);
        }

        void OnDeepClick(Object^ sender, RoutedEventArgs^ e)
        {
            Log(L"路由", L"Button.Click", sender, e);
        }

        void OnRaiseAlarm(Object^ sender, RoutedEventArgs^ e)
        {
            ((AlarmButton^)sender)->RaiseAlarm();
        }

        void OnAlarmReached(Object^ sender, RoutedEventArgs^ e)
        {
            Log(L"路由", L"自定义 Alarm 冒泡到 Window", sender, e);
        }

        void OnClear(Object^ sender, RoutedEventArgs^ e)
        {
            _log->Items->Clear();
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
