// 09 数据绑定基础（C++/CLI 版）：与 csharp/ 版功能一致。
// 注意：用 Binding 就要引 System.Xaml（Cpp.Common.props 已带）——MarkupExtension 本体在那里。
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Data;

namespace BindingDemoCpp {

    public ref class MainWindow : public Window
    {
    public:
        MainWindow()
        {
            Title = L"Data Binding Demo (C++/CLI)";
            Width = 420; Height = 260;

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(20);

            TextBlock^ l1 = gcnew TextBlock();
            l1->Text = L"名称"; l1->FontWeight = FontWeights::Bold; l1->Margin = Thickness(0, 0, 0, 8);
            TextBox^ nameEntry = gcnew TextBox();
            nameEntry->Text = L"Alice"; nameEntry->Margin = Thickness(0, 0, 0, 12);

            TextBlock^ l2 = gcnew TextBlock();
            l2->Text = L"亮度"; l2->FontWeight = FontWeights::Bold; l2->Margin = Thickness(0, 0, 0, 8);
            Slider^ valueSlider = gcnew Slider();
            valueSlider->Minimum = 0; valueSlider->Maximum = 100;
            valueSlider->Value = 60; valueSlider->Margin = Thickness(0, 0, 0, 12);

            // {Binding ElementName=nameEntry, Path=Text, StringFormat='Hello, {0}!'}
            TextBlock^ hello = gcnew TextBlock();
            hello->FontSize = 20; hello->Margin = Thickness(0, 0, 0, 8);
            Binding^ b1 = gcnew Binding(L"Text");
            b1->Source = nameEntry;
            b1->StringFormat = L"Hello, {0}!";
            hello->SetBinding(TextBlock::TextProperty, b1);

            // {Binding ElementName=valueSlider, Path=Value}
            TextBlock^ echo = gcnew TextBlock();
            echo->FontSize = 18;
            Binding^ b2 = gcnew Binding(L"Value");
            b2->Source = valueSlider;
            echo->SetBinding(TextBlock::TextProperty, b2);

            panel->Children->Add(l1); panel->Children->Add(nameEntry);
            panel->Children->Add(l2); panel->Children->Add(valueSlider);
            panel->Children->Add(hello); panel->Children->Add(echo);

            Content = panel;
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
