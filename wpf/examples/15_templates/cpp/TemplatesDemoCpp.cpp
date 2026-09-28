// 15 模板（C++/CLI 版）：与 csharp/ 版功能一致。
// TargetName 触发器两件套：factory->Name = L"Chrome"（注册部件名）+ Setter->TargetName = L"Chrome"。
using namespace System;
using namespace System::Collections::ObjectModel;
using namespace System::ComponentModel;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Controls::Primitives;
using namespace System::Windows::Data;
using namespace System::Windows::Media;
using namespace System::Windows::Shapes;

namespace TemplatesDemoCpp {

    public ref class Person
    {
    public:
        Person(String^ name, int age) { Name = name; Age = age; }
        property String^ Name;
        property int Age;
        property String^ AgeGroup
        {
            String^ get() { return Age < 30 ? L"青年" : (Age < 50 ? L"中年" : L"资深"); }
        }
    };

    public ref class PeopleViewModel : public INotifyPropertyChanged
    {
    private:
        Person^ _selected;
    public:
        virtual event PropertyChangedEventHandler^ PropertyChanged;

        PeopleViewModel()
        {
            People = gcnew ObservableCollection<Person^>();
            array<String^>^ names = { L"张三", L"李四", L"王五", L"赵六", L"孙七" };
            array<int>^ ages = { 24, 35, 46, 58, 28 };
            for (int i = 0; i < 5; i++)
                People->Add(gcnew Person(names[i], ages[i]));
        }

        property ObservableCollection<Person^>^ People;
        property Person^ Selected
        {
            Person^ get() { return _selected; }
            void set(Person^ value)
            {
                _selected = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"Selected"));
            }
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

        static Setter^ TargetSetter(DependencyProperty^ prop, Object^ value)
        {
            Setter^ s = gcnew Setter(prop, value);
            s->TargetName = L"Chrome";
            return s;
        }

        static TextBlock^ Hint(String^ text)
        {
            TextBlock^ t = gcnew TextBlock();
            t->Text = text;
            t->Foreground = BrushFromHex(L"#555555");
            return t;
        }

        DataTemplate^ BuildPersonCard()
        {
            System::Windows::Style^ dotStyle = gcnew System::Windows::Style(Ellipse::typeid);
            dotStyle->Setters->Add(gcnew Setter(Ellipse::FillProperty, BrushFromHex(L"#94A3B8")));
            array<String^>^ groups = { L"青年", L"中年" };
            array<String^>^ colors = { L"#3B82F6", L"#F59E0B" };
            for (int i = 0; i < 2; i++)
            {
                DataTrigger^ dt = gcnew DataTrigger();
                dt->Binding = gcnew Binding(L"AgeGroup");
                dt->Value = groups[i];
                dt->Setters->Add(gcnew Setter(Ellipse::FillProperty, BrushFromHex(colors[i])));
                dotStyle->Triggers->Add(dt);
            }

            FrameworkElementFactory^ row = gcnew FrameworkElementFactory(StackPanel::typeid);
            row->SetValue(StackPanel::OrientationProperty, System::Windows::Controls::Orientation::Horizontal);
            row->SetValue(FrameworkElement::MarginProperty, Thickness(0, 2, 0, 2));

            FrameworkElementFactory^ dot = gcnew FrameworkElementFactory(Ellipse::typeid);
            dot->SetValue(Ellipse::WidthProperty, 10.0);
            dot->SetValue(Ellipse::HeightProperty, 10.0);
            dot->SetValue(FrameworkElement::VerticalAlignmentProperty, System::Windows::VerticalAlignment::Center);
            dot->SetValue(FrameworkElement::StyleProperty, dotStyle);
            row->AppendChild(dot);

            FrameworkElementFactory^ name = gcnew FrameworkElementFactory(TextBlock::typeid);
            name->SetBinding(TextBlock::TextProperty, gcnew Binding(L"Name"));
            name->SetValue(TextBlock::FontWeightProperty, FontWeights::Bold);
            name->SetValue(FrameworkElement::MarginProperty, Thickness(8, 0, 0, 0));
            name->SetValue(FrameworkElement::VerticalAlignmentProperty, System::Windows::VerticalAlignment::Center);
            row->AppendChild(name);

            FrameworkElementFactory^ age = gcnew FrameworkElementFactory(TextBlock::typeid);
            Binding^ bAge = gcnew Binding(L"Age");
            bAge->StringFormat = L"（{0} 岁）";
            age->SetBinding(TextBlock::TextProperty, bAge);
            age->SetValue(TextBlock::ForegroundProperty, BrushFromHex(L"#64748B"));
            age->SetValue(FrameworkElement::MarginProperty, Thickness(4, 0, 0, 0));
            age->SetValue(FrameworkElement::VerticalAlignmentProperty, System::Windows::VerticalAlignment::Center);
            row->AppendChild(age);

            FrameworkElementFactory^ badge = gcnew FrameworkElementFactory(Border::typeid);
            badge->SetValue(Border::BackgroundProperty, BrushFromHex(L"#F1F5F9"));
            badge->SetValue(Border::CornerRadiusProperty, CornerRadius(8));
            badge->SetValue(Border::PaddingProperty, Thickness(8, 1, 8, 1));
            badge->SetValue(FrameworkElement::MarginProperty, Thickness(8, 0, 0, 0));
            badge->SetValue(FrameworkElement::VerticalAlignmentProperty, System::Windows::VerticalAlignment::Center);
            FrameworkElementFactory^ badgeText = gcnew FrameworkElementFactory(TextBlock::typeid);
            badgeText->SetBinding(TextBlock::TextProperty, gcnew Binding(L"AgeGroup"));
            badgeText->SetValue(TextBlock::FontSizeProperty, 11.0);
            badgeText->SetValue(TextBlock::ForegroundProperty, BrushFromHex(L"#475569"));
            badge->AppendChild(badgeText);
            row->AppendChild(badge);

            DataTemplate^ dtCard = gcnew DataTemplate(Person::typeid);
            dtCard->VisualTree = row;
            return dtCard;
        }

    public:
        MainWindow()
        {
            Title = L"模板实验室 (C++/CLI)";
            Width = 520; Height = 560;
            PeopleViewModel^ vm = gcnew PeopleViewModel();
            DataContext = vm;

            // ① ControlTemplate：圆角按钮
            FrameworkElementFactory^ chrome = gcnew FrameworkElementFactory(Border::typeid);
            chrome->Name = L"Chrome";   // XAML 里 Border x:Name="Chrome" 的代码等价物
            chrome->SetValue(Border::CornerRadiusProperty, CornerRadius(18));
            Binding^ bgB = gcnew Binding(L"Background");
            bgB->RelativeSource = RelativeSource::TemplatedParent;
            chrome->SetBinding(Border::BackgroundProperty, bgB);
            Binding^ padB = gcnew Binding(L"Padding");
            padB->RelativeSource = RelativeSource::TemplatedParent;
            chrome->SetBinding(Border::PaddingProperty, padB);
            FrameworkElementFactory^ presenter = gcnew FrameworkElementFactory(ContentPresenter::typeid);
            presenter->SetValue(FrameworkElement::HorizontalAlignmentProperty, System::Windows::HorizontalAlignment::Center);
            presenter->SetValue(FrameworkElement::VerticalAlignmentProperty, System::Windows::VerticalAlignment::Center);
            chrome->AppendChild(presenter);

            ControlTemplate^ roundTemplate = gcnew ControlTemplate(Button::typeid);
            roundTemplate->VisualTree = chrome;

            System::Windows::Trigger^ hoverT = gcnew System::Windows::Trigger();
            hoverT->Property = Control::IsMouseOverProperty;
            hoverT->Value = true;
            hoverT->Setters->Add(TargetSetter(UIElement::OpacityProperty, 0.85));
            roundTemplate->Triggers->Add(hoverT);

            System::Windows::Trigger^ pressT = gcnew System::Windows::Trigger();
            pressT->Property = ButtonBase::IsPressedProperty;
            pressT->Value = true;
            pressT->Setters->Add(TargetSetter(UIElement::OpacityProperty, 0.7));
            pressT->Setters->Add(TargetSetter(Border::BorderBrushProperty, BrushFromHex(L"#0EA5E9")));
            pressT->Setters->Add(TargetSetter(Border::BorderThicknessProperty, Thickness(2)));
            roundTemplate->Triggers->Add(pressT);

            System::Windows::Trigger^ disT = gcnew System::Windows::Trigger();
            disT->Property = Control::IsEnabledProperty;
            disT->Value = false;
            disT->Setters->Add(TargetSetter(UIElement::OpacityProperty, 0.4));
            roundTemplate->Triggers->Add(disT);

            // BasedOn：继承蓝色样式，只覆盖背景色
            System::Windows::Style^ blueStyle = gcnew System::Windows::Style(Button::typeid);
            blueStyle->Setters->Add(gcnew Setter(Button::TemplateProperty, roundTemplate));
            blueStyle->Setters->Add(gcnew Setter(Button::BackgroundProperty, BrushFromHex(L"#3B82F6")));
            blueStyle->Setters->Add(gcnew Setter(Button::ForegroundProperty, Brushes::White));
            blueStyle->Setters->Add(gcnew Setter(Button::PaddingProperty, Thickness(20, 10, 20, 10)));
            System::Windows::Style^ greenStyle = gcnew System::Windows::Style(Button::typeid);
            greenStyle->BasedOn = blueStyle;
            greenStyle->Setters->Add(gcnew Setter(Button::BackgroundProperty, BrushFromHex(L"#10B981")));

            Button^ blue1 = gcnew Button();
            blue1->Content = L"蓝色按钮"; blue1->Style = blueStyle; blue1->Margin = Thickness(0, 0, 12, 0);
            Button^ green1 = gcnew Button();
            green1->Content = L"绿色按钮"; green1->Style = greenStyle; green1->Margin = Thickness(0, 0, 12, 0);
            Button^ disabledBtn = gcnew Button();
            disabledBtn->Content = L"禁用态"; disabledBtn->Style = blueStyle; disabledBtn->IsEnabled = false;
            StackPanel^ buttonRow = gcnew StackPanel();
            buttonRow->Orientation = System::Windows::Controls::Orientation::Horizontal;
            buttonRow->Children->Add(blue1); buttonRow->Children->Add(green1); buttonRow->Children->Add(disabledBtn);

            // ② DataTemplate 三处复用
            DataTemplate^ card = BuildPersonCard();
            ListBox^ listBox = gcnew ListBox();
            listBox->ItemTemplate = card;
            listBox->Margin = Thickness(0, 2, 0, 10);
            listBox->SetBinding(ListBox::ItemsSourceProperty, gcnew Binding(L"People"));
            listBox->SetBinding(ListBox::SelectedItemProperty, gcnew Binding(L"Selected"));
            ItemsControl^ items = gcnew ItemsControl();
            items->ItemTemplate = card;
            items->Margin = Thickness(0, 2, 0, 10);
            items->SetBinding(ItemsControl::ItemsSourceProperty, gcnew Binding(L"People"));
            ContentControl^ single = gcnew ContentControl();
            single->ContentTemplate = card;
            single->SetBinding(ContentControl::ContentProperty, gcnew Binding(L"Selected"));
            Border^ singleHost = gcnew Border();
            singleHost->BorderBrush = BrushFromHex(L"#CBD5E1");
            singleHost->BorderThickness = Thickness(1);
            singleHost->CornerRadius = CornerRadius(8);
            singleHost->Padding = Thickness(12);
            singleHost->Child = single;

            TextBlock^ t1 = gcnew TextBlock();
            t1->Text = L"① ControlTemplate：圆角按钮，悬停/按压状态由模板内部触发器负责";
            t1->FontWeight = FontWeights::Bold; t1->Margin = Thickness(0, 0, 0, 10);
            TextBlock^ t2 = gcnew TextBlock();
            t2->Text = L"② DataTemplate：同一份 PersonCard 模板用在三个地方";
            t2->FontWeight = FontWeights::Bold; t2->Margin = Thickness(0, 20, 0, 4);
            TextBlock^ foot = gcnew TextBlock();
            foot->Text = L"↑ 在上面的 ListBox 里点选一行，这里跟着变——模板只管长相，数据决定内容";
            foot->Foreground = BrushFromHex(L"#555555");
            foot->FontSize = 11; foot->Margin = Thickness(0, 6, 0, 0);

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(16);
            panel->Children->Add(t1); panel->Children->Add(buttonRow);
            panel->Children->Add(t2);
            panel->Children->Add(Hint(L"ListBox（可选）：")); panel->Children->Add(listBox);
            panel->Children->Add(Hint(L"ItemsControl（纯展示，无选中无高亮）：")); panel->Children->Add(items);
            panel->Children->Add(Hint(L"ContentControl（单个对象，选中谁显示谁）：")); panel->Children->Add(singleHost);
            panel->Children->Add(foot);

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
