// 23 窗口与页面导航（C++/CLI 版）：与 csharp/ 版功能一致。
// Frame::Navigate(页面对象) 是对象导航（每次都新实例）。
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Navigation;   // NavigationUIVisibility 在这

namespace NavigationDemoCpp {

    public ref class Pages abstract sealed
    {
    public:
        static Page^ Home()
        {
            Page^ p = gcnew Page();
            TextBlock^ t = gcnew TextBlock();
            t->Text = L"欢迎来到首页"; t->FontSize = 22;
            t->FontWeight = FontWeights::Bold; t->Margin = Thickness(20);
            p->Content = t;
            return p;
        }

        static Page^ Settings()
        {
            Page^ p = gcnew Page();
            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(20);
            TextBlock^ title = gcnew TextBlock();
            title->Text = L"设置页面"; title->FontSize = 22; title->FontWeight = FontWeights::Bold;
            panel->Children->Add(title);
            CheckBox^ notify = gcnew CheckBox();
            notify->Content = L"启用通知"; notify->IsChecked = true;
            notify->Margin = Thickness(0, 12, 0, 0);
            panel->Children->Add(notify);
            CheckBox^ autosave = gcnew CheckBox();
            autosave->Content = L"自动保存"; autosave->IsChecked = true;
            panel->Children->Add(autosave);
            p->Content = panel;
            return p;
        }
    };

    public ref class MainWindow : public Window
    {
    private:
        Frame^ _frame;

    public:
        MainWindow()
        {
            Title = L"Navigation Demo (C++/CLI)";
            Width = 500; Height = 300;

            _frame = gcnew Frame();
            _frame->NavigationUIVisibility = NavigationUIVisibility::Visible;

            Button^ homeBtn = gcnew Button();
            homeBtn->Content = L"首页"; homeBtn->Width = 90;
            homeBtn->Margin = Thickness(0, 0, 8, 0);
            homeBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnHome);

            Button^ settingsBtn = gcnew Button();
            settingsBtn->Content = L"设置"; settingsBtn->Width = 90;
            settingsBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnSettings);

            StackPanel^ toolbar = gcnew StackPanel();
            toolbar->Orientation = System::Windows::Controls::Orientation::Horizontal;
            toolbar->Margin = Thickness(0, 0, 0, 12);
            toolbar->Children->Add(homeBtn);
            toolbar->Children->Add(settingsBtn);

            DockPanel^ dock = gcnew DockPanel();
            dock->Margin = Thickness(12);
            DockPanel::SetDock(toolbar, Dock::Top);
            dock->Children->Add(toolbar);
            dock->Children->Add(_frame);

            Content = dock;

            _frame->Navigate(Pages::Home());   // 启动页
        }

    private:
        void OnHome(Object^ sender, RoutedEventArgs^ e) { _frame->Navigate(Pages::Home()); }
        void OnSettings(Object^ sender, RoutedEventArgs^ e) { _frame->Navigate(Pages::Settings()); }
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
