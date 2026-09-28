// 16 数据验证（C++/CLI 版）：与 csharp/ 版功能一致——INotifyDataErrorInfo 全套。
// 双接口实现：INotifyPropertyChanged + INotifyDataErrorInfo（HasErrors / GetErrors / ErrorsChanged）。
using namespace System;
using namespace System::Collections::Generic;
using namespace System::ComponentModel;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Data;
using namespace System::Windows::Media;

namespace ValidationDemoCpp {

    public ref class FormViewModel : public INotifyPropertyChanged, public INotifyDataErrorInfo
    {
    private:
        Dictionary<String^, List<String^>^>^ _errors;
        String^ _userName;
        String^ _ageText;
        String^ _email;
        String^ _result;

        bool AnyErrors()
        {
            for each (KeyValuePair<String^, List<String^>^>^ kv in _errors)
                if (kv->Value->Count > 0) return true;
            return false;
        }

        void SetErrors(String^ name, List<String^>^ newErrors)
        {
            bool changed = !_errors->ContainsKey(name);
            if (!changed)
            {
                List<String^>^ old = _errors[name];
                changed = old->Count != newErrors->Count;
                if (!changed)
                    for (int i = 0; i < old->Count; i++)
                        if (old[i] != newErrors[i]) { changed = true; break; }
            }
            if (!changed) return;

            if (newErrors->Count == 0) _errors->Remove(name);
            else _errors[name] = newErrors;

            ErrorsChanged(this, gcnew DataErrorsChangedEventArgs(name));
            PropertyChanged(this, gcnew PropertyChangedEventArgs(L"HasErrors"));
        }

        void ValidateUserName()
        {
            List<String^>^ e = gcnew List<String^>();
            if (String::IsNullOrWhiteSpace(_userName)) e->Add(L"用户名不能为空");
            else if (_userName->Length < 2) e->Add(L"用户名至少 2 个字符");
            SetErrors(L"UserName", e);
        }

        void ValidateAge()
        {
            List<String^>^ e = gcnew List<String^>();
            if (String::IsNullOrWhiteSpace(_ageText)) e->Add(L"年龄不能为空");
            else
            {
                int age;
                if (!Int32::TryParse(_ageText, age)) e->Add(L"年龄必须是整数");
                else if (age < 18 || age > 60) e->Add(L"年龄必须在 18 到 60 之间");
            }
            SetErrors(L"AgeText", e);
        }

        void ValidateEmail()
        {
            List<String^>^ e = gcnew List<String^>();
            if (!String::IsNullOrEmpty(_email) && !_email->Contains(L'@'))
                e->Add(L"邮箱必须包含 @（留空表示不填）");
            SetErrors(L"Email", e);
        }

    public:
        virtual event PropertyChangedEventHandler^ PropertyChanged;
        virtual event EventHandler<DataErrorsChangedEventArgs^>^ ErrorsChanged;

        FormViewModel()
        {
            _errors = gcnew Dictionary<String^, List<String^>^>();
            _userName = L""; _ageText = L""; _email = L""; _result = L"";
        }

        property String^ UserName
        {
            String^ get() { return _userName; }
            void set(String^ value)
            {
                _userName = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"UserName"));
                ValidateUserName();
            }
        }
        property String^ AgeText
        {
            String^ get() { return _ageText; }
            void set(String^ value)
            {
                _ageText = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"AgeText"));
                ValidateAge();
            }
        }
        property String^ Email
        {
            String^ get() { return _email; }
            void set(String^ value)
            {
                _email = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"Email"));
                ValidateEmail();
            }
        }
        property String^ Result
        {
            String^ get() { return _result; }
            void set(String^ value)
            {
                _result = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"Result"));
            }
        }

        // INotifyDataErrorInfo
        virtual property bool HasErrors { bool get() { return AnyErrors(); } }

        virtual Collections::IEnumerable^ GetErrors(String^ propertyName)
        {
            if (propertyName != nullptr && _errors->ContainsKey(propertyName))
                return _errors[propertyName];
            return gcnew array<String^>(0);
        }

        void Submit()
        {
            if (AnyErrors())
            {
                Result = L"表单有错误，请按红框提示修改后再提交。";
                return;
            }
            String^ emailPart = String::IsNullOrEmpty(_email) ? L"，未留邮箱"
                : String::Concat(L"，邮箱 ", _email);
            Result = String::Format(L"提交成功：{0}，{1} 岁{2}", _userName, Int32::Parse(_ageText), emailPart);
        }
    };

    public ref class MainWindow : public Window
    {
    private:
        static SolidColorBrush^ BrushFromHex(String^ hex)
        {
            Color c = (Color)ColorConverter::ConvertFromString(hex);
            return gcnew SolidColorBrush(c);
        }

    public:
        MainWindow()
        {
            Title = L"表单验证 (C++/CLI)";
            Width = 440; Height = 440;
            FormViewModel^ vm = gcnew FormViewModel();
            DataContext = vm;

            SolidColorBrush^ red = BrushFromHex(L"#EF4444");

            // 自定义错误模板：红框 + 叹号（悬停看完整信息）——15 章工厂法的又一次实战
            ControlTemplate^ errTemplate = gcnew ControlTemplate();
            FrameworkElementFactory^ row = gcnew FrameworkElementFactory(StackPanel::typeid);
            row->SetValue(StackPanel::OrientationProperty, System::Windows::Controls::Orientation::Horizontal);
            FrameworkElementFactory^ frame = gcnew FrameworkElementFactory(Border::typeid);
            frame->SetValue(Border::BorderBrushProperty, red);
            frame->SetValue(Border::BorderThicknessProperty, Thickness(1.5));
            frame->SetValue(Border::CornerRadiusProperty, CornerRadius(4));
            frame->AppendChild(gcnew FrameworkElementFactory(AdornedElementPlaceholder::typeid));
            row->AppendChild(frame);
            FrameworkElementFactory^ mark = gcnew FrameworkElementFactory(TextBlock::typeid);
            mark->SetValue(TextBlock::TextProperty, L"!");
            mark->SetValue(TextBlock::ForegroundProperty, red);
            mark->SetValue(TextBlock::FontWeightProperty, FontWeights::Bold);
            mark->SetValue(TextBlock::FontSizeProperty, 16.0);
            mark->SetValue(FrameworkElement::MarginProperty, Thickness(6, 0, 0, 0));
            mark->SetValue(FrameworkElement::VerticalAlignmentProperty, System::Windows::VerticalAlignment::Center);
            mark->SetBinding(FrameworkElement::ToolTipProperty, gcnew Binding(L"[0].ErrorContent"));
            row->AppendChild(mark);
            errTemplate->VisualTree = row;

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(20);

            TextBlock^ intro = gcnew TextBlock();
            intro->Text = L"逐字输入体会验证时机（UpdateSourceTrigger=PropertyChanged）";
            intro->Foreground = BrushFromHex(L"#555555");
            intro->Margin = Thickness(0, 0, 0, 14);
            intro->TextWrapping = TextWrapping::Wrap;
            panel->Children->Add(intro);

            array<String^>^ props = { L"UserName", L"AgeText", L"Email" };
            array<String^>^ labels = { L"用户名（必填 ≥2 字符）", L"年龄（18–60 的整数）", L"邮箱（可留空；填了须含 @）" };
            array<double>^ tails = { 10, 10, 16 };
            for (int i = 0; i < 3; i++)
            {
                TextBlock^ label = gcnew TextBlock();
                label->Text = labels[i];
                panel->Children->Add(label);

                TextBox^ box = gcnew TextBox();
                box->Margin = Thickness(0, 2, 0, 2);
                Binding^ b = gcnew Binding(props[i]);
                b->UpdateSourceTrigger = UpdateSourceTrigger::PropertyChanged;
                b->ValidatesOnNotifyDataErrors = true;
                box->SetBinding(TextBox::TextProperty, b);
                Validation::SetErrorTemplate(box, errTemplate);
                panel->Children->Add(box);

                // XAML 的 {Binding (Validation.Errors)[0].ErrorContent, ElementName=X} → 代码版
                RegisterName(String::Concat(props[i], L"Box"), box);
                TextBlock^ errLine = gcnew TextBlock();
                errLine->Foreground = red;
                errLine->FontSize = 11;
                errLine->Margin = Thickness(4, 0, 0, tails[i]);
                Binding^ eb = gcnew Binding(L"(Validation.Errors)[0].ErrorContent");
                eb->ElementName = String::Concat(props[i], L"Box");
                eb->FallbackValue = L"";
                errLine->SetBinding(TextBlock::TextProperty, eb);
                panel->Children->Add(errLine);
            }

            Button^ submit = gcnew Button();
            submit->Content = L"提交"; submit->Width = 120;
            submit->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            submit->Click += gcnew RoutedEventHandler(this, &MainWindow::OnSubmit);
            panel->Children->Add(submit);

            TextBlock^ resultLine = gcnew TextBlock();
            resultLine->Margin = Thickness(0, 16, 0, 0);
            resultLine->TextWrapping = TextWrapping::Wrap;
            resultLine->FontWeight = FontWeights::Bold;
            resultLine->SetBinding(TextBlock::TextProperty, gcnew Binding(L"Result"));
            panel->Children->Add(resultLine);

            Content = panel;
        }

    private:
        void OnSubmit(Object^ sender, RoutedEventArgs^ e)
        {
            ((FormViewModel^)DataContext)->Submit();
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
