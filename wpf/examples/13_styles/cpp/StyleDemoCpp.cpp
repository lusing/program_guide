// 13 资源与样式（C++/CLI 版）：与 csharp/ 版功能一致。
// 代码建树三换算：StaticResource→字典取值 / DynamicResource→SetResourceReference /
// TemplateBinding→Binding + RelativeSource.TemplatedParent。
// 注意：Style 类名在 Window 子类里被 Style 属性遮蔽——声明要写 System::Windows::Style（实测坑）。
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Data;
using namespace System::Windows::Media;

namespace StyleDemoCpp {

    public ref class MainWindow : public Window
    {
    private:
        array<SolidColorBrush^>^ _skins;
        int _skinIndex;

        static SolidColorBrush^ BrushFromHex(String^ hex)
        {
            Color c = (Color)ColorConverter::ConvertFromString(hex);
            return gcnew SolidColorBrush(c);
        }

    public:
        MainWindow()
        {
            Title = L"Style Demo (C++/CLI)";
            Width = 500; Height = 280;

            // ── 模板：TemplateBinding 的代码等价物 ──
            FrameworkElementFactory^ borderF = gcnew FrameworkElementFactory(Border::typeid);
            Binding^ bgBinding = gcnew Binding(L"Background");
            bgBinding->RelativeSource = RelativeSource::TemplatedParent;
            borderF->SetBinding(Border::BackgroundProperty, bgBinding);
            Binding^ padBinding = gcnew Binding(L"Padding");
            padBinding->RelativeSource = RelativeSource::TemplatedParent;
            borderF->SetBinding(Border::PaddingProperty, padBinding);
            borderF->SetValue(Border::CornerRadiusProperty, CornerRadius(6));
            FrameworkElementFactory^ presenter = gcnew FrameworkElementFactory(ContentPresenter::typeid);
            presenter->SetValue(FrameworkElement::HorizontalAlignmentProperty,
                                System::Windows::HorizontalAlignment::Center);
            borderF->AppendChild(presenter);

            // template 是 C++ 关键字，不能当变量名——变量叫 ctrlTemplate
            ControlTemplate^ ctrlTemplate = gcnew ControlTemplate(Button::typeid);
            ctrlTemplate->VisualTree = borderF;

            // ── PrimaryButtonStyle ──
            System::Windows::Style^ primaryStyle = gcnew System::Windows::Style(Button::typeid);
            primaryStyle->Setters->Add(gcnew Setter(Button::BackgroundProperty, BrushFromHex(L"#3B82F6")));
            primaryStyle->Setters->Add(gcnew Setter(Button::ForegroundProperty, Brushes::White));
            primaryStyle->Setters->Add(gcnew Setter(Button::FontWeightProperty, FontWeights::Bold));
            primaryStyle->Setters->Add(gcnew Setter(Button::PaddingProperty, Thickness(14, 8, 14, 8)));
            primaryStyle->Setters->Add(gcnew Setter(Button::MarginProperty, Thickness(0, 0, 12, 0)));
            primaryStyle->Setters->Add(gcnew Setter(Button::TemplateProperty, ctrlTemplate));

            System::Windows::Trigger^ hover = gcnew System::Windows::Trigger();   // 无 (DP,value) 构造器
            hover->Property = Control::IsMouseOverProperty;
            hover->Value = true;
            hover->Setters->Add(gcnew Setter(Button::BackgroundProperty, BrushFromHex(L"#2563EB")));
            primaryStyle->Triggers->Add(hover);

            // ── AccentTextStyle ──
            System::Windows::Style^ accentStyle = gcnew System::Windows::Style(TextBlock::typeid);
            accentStyle->Setters->Add(gcnew Setter(TextBlock::ForegroundProperty, BrushFromHex(L"#1D4ED8")));
            accentStyle->Setters->Add(gcnew Setter(TextBlock::FontSizeProperty, 18.0));
            accentStyle->Setters->Add(gcnew Setter(TextBlock::FontWeightProperty, FontWeights::Bold));

            // ── 动态资源换肤（教材 10.3.2 / 11.3.5）──
            _skins = gcnew array<SolidColorBrush^> {
                BrushFromHex(L"#8B5CF6"), BrushFromHex(L"#0EA5E9"), BrushFromHex(L"#F59E0B") };
            _skinIndex = 0;
            Resources->Add(L"accentBrush", _skins[0]);
            Button^ skinBtn = gcnew Button();
            skinBtn->Content = L"动态资源皮肤（点我换肤）";
            skinBtn->Foreground = Brushes::White;
            skinBtn->Padding = Thickness(14, 8, 14, 8);
            skinBtn->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            skinBtn->SetResourceReference(Button::BackgroundProperty, L"accentBrush");   // = {DynamicResource}
            skinBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnSkinClick);

            // ── 总装 ──
            TextBlock^ title = gcnew TextBlock();
            title->Text = L"样式与资源示例";
            title->Margin = Thickness(0, 0, 0, 12);
            title->Style = accentStyle;

            Button^ save = gcnew Button();
            save->Content = L"保存";
            save->Style = primaryStyle;
            Button^ cancel = gcnew Button();
            cancel->Content = L"取消"; cancel->Width = 96;
            StackPanel^ buttonRow = gcnew StackPanel();
            buttonRow->Orientation = System::Windows::Controls::Orientation::Horizontal;
            buttonRow->Margin = Thickness(0, 0, 0, 12);
            buttonRow->Children->Add(save); buttonRow->Children->Add(cancel);

            TextBox^ box = gcnew TextBox();
            box->Text = L"统一风格的文本框";
            box->Height = 32; box->Width = 260;
            box->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            box->Margin = Thickness(0, 0, 0, 12);

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(20);
            panel->Children->Add(title); panel->Children->Add(buttonRow);
            panel->Children->Add(box); panel->Children->Add(skinBtn);

            Content = panel;
        }

    private:
        void OnSkinClick(Object^ sender, RoutedEventArgs^ e)
        {
            _skinIndex = (_skinIndex + 1) % _skins->Length;
            Resources[L"accentBrush"] = _skins[_skinIndex];
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
