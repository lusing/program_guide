// 14 触发器（C++/CLI 版）：与 csharp/ 版功能一致——四类触发器全部代码化。
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Data;
using namespace System::Windows::Media;
using namespace System::Windows::Media::Animation;

namespace TriggersDemoCpp {

    public ref class MainWindow : public Window
    {
    private:
        static SolidColorBrush^ BrushFromHex(String^ hex)
        {
            Color c = (Color)ColorConverter::ConvertFromString(hex);
            return gcnew SolidColorBrush(c);
        }

        static TextBlock^ Header(String^ text)
        {
            TextBlock^ t = gcnew TextBlock();
            t->Text = text; t->FontWeight = FontWeights::Bold;
            t->Margin = Thickness(0, 8, 0, 8);
            return t;
        }

        // XAML <EventTrigger RoutedEvent="..."><BeginStoryboard><Storyboard>…</Storyboard></BeginStoryboard></EventTrigger>
        // 的代码形态：EventTrigger 收 RoutedEvent，BeginStoryboard 包 Storyboard，Add 进 Actions。
        static void AttachAnimation(FrameworkElement^ target, RoutedEvent^ ev,
                                    Timeline^ animation, DependencyProperty^ prop)
        {
            Storyboard::SetTarget(animation, target);
            Storyboard::SetTargetProperty(animation, gcnew PropertyPath(prop));
            Storyboard^ sb = gcnew Storyboard();
            sb->Children->Add(animation);
            EventTrigger^ trigger = gcnew EventTrigger(ev);
            // BeginStoryboard 类型与 FrameworkElement 上的同名成员查找打架——全限定消歧
            System::Windows::Media::Animation::BeginStoryboard^ beginAction =
                gcnew System::Windows::Media::Animation::BeginStoryboard();
            beginAction->Storyboard = sb;
            trigger->Actions->Add(beginAction);
            target->Triggers->Add(trigger);
        }

    public:
        MainWindow()
        {
            Title = L"触发器实验室 (C++/CLI)";
            Width = 460; Height = 520;

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(16);

            // ① 属性触发器
            System::Windows::Style^ focusStyle = gcnew System::Windows::Style(TextBox::typeid);
            focusStyle->Setters->Add(gcnew Setter(TextBox::MarginProperty, Thickness(0, 0, 0, 8)));
            focusStyle->Setters->Add(gcnew Setter(TextBox::PaddingProperty, Thickness(6, 4, 6, 4)));
            System::Windows::Trigger^ ft = gcnew System::Windows::Trigger();
            ft->Property = TextBox::IsKeyboardFocusWithinProperty;
            ft->Value = true;
            ft->Setters->Add(gcnew Setter(TextBox::BackgroundProperty, BrushFromHex(L"#FFFBEB")));
            ft->Setters->Add(gcnew Setter(TextBox::BorderBrushProperty, BrushFromHex(L"#F59E0B")));
            focusStyle->Triggers->Add(ft);
            TextBox^ focusBox = gcnew TextBox();
            focusBox->Text = L"点我获得焦点试试";
            focusBox->Style = focusStyle;

            // ② 多条件触发器
            System::Windows::Style^ primaryStyle = gcnew System::Windows::Style(Button::typeid);
            primaryStyle->Setters->Add(gcnew Setter(Button::BackgroundProperty, BrushFromHex(L"#3B82F6")));
            primaryStyle->Setters->Add(gcnew Setter(Button::ForegroundProperty, Brushes::White));
            primaryStyle->Setters->Add(gcnew Setter(Button::PaddingProperty, Thickness(14, 8, 14, 8)));
            MultiTrigger^ multi = gcnew MultiTrigger();
            multi->Conditions->Add(gcnew Condition(Control::IsMouseOverProperty, true));
            multi->Conditions->Add(gcnew Condition(Control::IsEnabledProperty, true));
            multi->Setters->Add(gcnew Setter(Button::BackgroundProperty, BrushFromHex(L"#1D4ED8")));
            primaryStyle->Triggers->Add(multi);
            System::Windows::Trigger^ disabled = gcnew System::Windows::Trigger();
            disabled->Property = Control::IsEnabledProperty;
            disabled->Value = false;
            disabled->Setters->Add(gcnew Setter(Button::BackgroundProperty, BrushFromHex(L"#CBD5E1")));
            disabled->Setters->Add(gcnew Setter(Button::ForegroundProperty, BrushFromHex(L"#64748B")));
            primaryStyle->Triggers->Add(disabled);

            CheckBox^ agreeBox = gcnew CheckBox();
            agreeBox->Content = L"同意协议（勾选后按钮变为可用）";
            agreeBox->Margin = Thickness(0, 0, 0, 8);
            Button^ submit = gcnew Button();
            submit->Content = L"提交"; submit->Width = 120;
            submit->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            submit->Style = primaryStyle;
            Binding^ bEnabled = gcnew Binding(L"IsChecked");
            bEnabled->Source = agreeBox;
            submit->SetBinding(Button::IsEnabledProperty, bEnabled);

            // ③ 数据触发器
            CheckBox^ darkBox = gcnew CheckBox();
            darkBox->Content = L"夜间模式"; darkBox->Margin = Thickness(0, 0, 0, 8);

            System::Windows::Style^ panelStyle = gcnew System::Windows::Style(Border::typeid);
            panelStyle->Setters->Add(gcnew Setter(Border::BackgroundProperty, BrushFromHex(L"#F1F5F9")));
            DataTrigger^ dt = gcnew DataTrigger();
            Binding^ bDark = gcnew Binding(L"IsChecked");
            bDark->Source = darkBox;
            dt->Binding = bDark;
            dt->Value = true;
            dt->Setters->Add(gcnew Setter(Border::BackgroundProperty, BrushFromHex(L"#1E293B")));
            panelStyle->Triggers->Add(dt);

            System::Windows::Style^ textStyle = gcnew System::Windows::Style(TextBlock::typeid);
            textStyle->Setters->Add(gcnew Setter(TextBlock::ForegroundProperty, BrushFromHex(L"#0F172A")));
            DataTrigger^ dt2 = gcnew DataTrigger();
            Binding^ bDark2 = gcnew Binding(L"IsChecked");
            bDark2->Source = darkBox;
            dt2->Binding = bDark2;
            dt2->Value = true;
            dt2->Setters->Add(gcnew Setter(TextBlock::ForegroundProperty, BrushFromHex(L"#E2E8F0")));
            textStyle->Triggers->Add(dt2);

            TextBlock^ panelText = gcnew TextBlock();
            panelText->Text = L"两个 DataTrigger（面板背景 + 文字颜色）同时响应一个状态";
            panelText->Style = textStyle;
            Border^ darkPanel = gcnew Border();
            darkPanel->CornerRadius = CornerRadius(8);
            darkPanel->Padding = Thickness(16);
            darkPanel->Margin = Thickness(0, 0, 0, 8);
            darkPanel->Style = panelStyle;
            darkPanel->Child = panelText;

            // ④ 事件触发器：窗口淡入 + 按钮滑过伸缩
            DoubleAnimation^ fadeIn = gcnew DoubleAnimation();
            fadeIn->From = 0; fadeIn->To = 1;
            fadeIn->Duration = Duration(TimeSpan::FromSeconds(0.6));
            AttachAnimation(this, FrameworkElement::LoadedEvent, fadeIn, Window::OpacityProperty);

            Button^ hoverBtn = gcnew Button();
            hoverBtn->Content = L"鼠标滑过我"; hoverBtn->Width = 120;
            hoverBtn->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            DoubleAnimation^ widen = gcnew DoubleAnimation();
            widen->To = 180; widen->Duration = Duration(TimeSpan::FromSeconds(0.25));
            AttachAnimation(hoverBtn, UIElement::MouseEnterEvent, widen, Button::WidthProperty);
            DoubleAnimation^ shrink = gcnew DoubleAnimation();
            shrink->To = 120; shrink->Duration = Duration(TimeSpan::FromSeconds(0.25));
            AttachAnimation(hoverBtn, UIElement::MouseLeaveEvent, shrink, Button::WidthProperty);

            panel->Children->Add(Header(L"① 属性触发器：点击输入框获得焦点，背景与边框自动变色"));
            panel->Children->Add(focusBox);
            panel->Children->Add(Header(L"② 多条件触发器：按钮「悬停 且 可用」才变深色"));
            panel->Children->Add(agreeBox); panel->Children->Add(submit);
            panel->Children->Add(Header(L"③ 数据触发器：CheckBox 的状态驱动整个面板换肤（零代码）"));
            panel->Children->Add(darkBox); panel->Children->Add(darkPanel);
            panel->Children->Add(Header(L"④ 事件触发器：鼠标移入/移出，按钮宽度动画伸缩（动画预告）"));
            panel->Children->Add(hoverBtn);

            ScrollViewer^ scroll = gcnew ScrollViewer();
            scroll->VerticalScrollBarVisibility = ScrollBarVisibility::Auto;
            scroll->Content = panel;
            Content = scroll;
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
