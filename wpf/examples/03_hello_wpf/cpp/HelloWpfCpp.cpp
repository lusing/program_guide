// 03 第一个 WPF 程序（C++/CLI 版）：与 csharp/ 的 C# 版功能一致。
// C++/CLI 没有 XAML 代码生成器（x:Class 靠分部类，C++/CLI 写不了 XAML 分部类），
// 本教程 C++ 章节统一走「混合模式 DLL + C# 启动器 + 纯代码 UI」路线。
//
// C++/CLI 语法地图：
//   gcnew T(...)        托管堆分配（对应 C# 的 new）    句柄类型 T^
//   btn->Content        句柄用 -> 访问成员（同 C++ 指针）
//   gcnew RoutedEventHandler(this, &T::OnX)   成员函数做事件处理器
//   L"..."              宽字符串字面量
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;

namespace HelloWpfCpp {

    public ref class MainWindow : public Window
    {
    private:
        TextBox^ _nameBox;

    public:
        MainWindow()
        {
            Title = L"Hello WPF (C++/CLI)";
            Width = 400; Height = 220;

            TextBlock^ prompt = gcnew TextBlock();
            prompt->Text = L"请输入你的名字：";
            prompt->FontSize = 18;
            prompt->Margin = Thickness(0, 0, 0, 12);

            _nameBox = gcnew TextBox();
            _nameBox->Width = 220;
            _nameBox->Height = 32;
            _nameBox->Margin = Thickness(0, 0, 0, 12);

            Button^ greet = gcnew Button();
            greet->Content = L"打招呼";
            greet->Width = 120;
            greet->Height = 36;
            greet->Click += gcnew RoutedEventHandler(this, &MainWindow::OnGreet);

            StackPanel^ panel = gcnew StackPanel();
            // 属性名遮蔽枚举类型名（本教程头号 C++/CLI 坑）：必须全限定
            panel->VerticalAlignment = System::Windows::VerticalAlignment::Center;
            panel->Children->Add(prompt);
            panel->Children->Add(_nameBox);
            panel->Children->Add(greet);

            Grid^ grid = gcnew Grid();
            grid->Margin = Thickness(20);
            grid->Children->Add(panel);

            Content = grid;
        }

    private:
        void OnGreet(Object^ sender, RoutedEventArgs^ e)
        {
            String^ name = String::IsNullOrWhiteSpace(_nameBox->Text) ? L"朋友" : _nameBox->Text->Trim();
            MessageBox::Show(this, String::Concat(L"Hello, ", name, L"!"), L"Greeting");
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
