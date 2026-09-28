// 14 数据绑定（C++/CLI 版）
// 语法增量：实现 INotifyPropertyChanged 要显式写接口 + 事件；
// C++/CLI 属性 set 里触发通知与 C# 一一对应
using namespace System;
using namespace System::ComponentModel;
using namespace System::Drawing;
using namespace System::Windows::Forms;

namespace BindingCpp {

    // ═══ 14.1 INPC 模型 ═══
    public ref class Person : public INotifyPropertyChanged
    {
    private:
        String^ _name;
        int _age;
        String^ _email;

        void Notify(String^ propName)
        {
            PropertyChanged(this, gcnew PropertyChangedEventArgs(propName));
        }

    public:
        Person() { _name = L""; _age = 0; _email = L""; }
        Person(String^ name, int age, String^ email) { _name = name; _age = age; _email = email; }

        virtual event PropertyChangedEventHandler^ PropertyChanged;   // virtual 才满足接口

        property String^ Name
        {
            String^ get() { return _name; }
            void set(String^ value) { if (_name != value) { _name = value; Notify(L"Name"); } }
        }
        property int Age
        {
            int get() { return _age; }
            void set(int value) { if (_age != value) { _age = value; Notify(L"Age"); } }
        }
        property String^ Email
        {
            String^ get() { return _email; }
            void set(String^ value) { if (_email != value) { _email = value; Notify(L"Email"); } }
        }

        virtual String^ ToString() override { return _name; }
    };

    public ref class MainForm : public Form
    {
    private:
        BindingSource^ _source;
        TextBox^ _name;
        NumericUpDown^ _age;
        TextBox^ _email;

    public:
        MainForm()
        {
            Text = L"数据绑定（C++/CLI）";
            ClientSize = System::Drawing::Size(680, 520);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);

            // BindingList<T> 在 System::ComponentModel（不是 ObjectModel——那边的 ObservableCollection 不是绑定列表）
            auto people = gcnew BindingList<Person^>();
            people->Add(gcnew Person(L"林一", 28, L"linyi@example.com"));
            people->Add(gcnew Person(L"陈二", 35, L"chener@example.com"));
            people->Add(gcnew Person(L"张三", 41, L"zhangsan@example.com"));

            _source = gcnew BindingSource();
            _source->DataSource = people;

            auto box = gcnew GroupBox();
            box->Text = L" 当前人员（编辑后看表格同步刷新）"; box->Dock = DockStyle::Top; box->Height = 150;

            auto nl = gcnew Label(); nl->Text = L"姓名："; nl->AutoSize = true;
            nl->Location = System::Drawing::Point(16, 32);
            _name = gcnew TextBox(); _name->SetBounds(90, 28, 160, 30);
            _name->DataBindings->Add(L"Text", _source, L"Name");

            auto al = gcnew Label(); al->Text = L"年龄："; al->AutoSize = true;
            al->Location = System::Drawing::Point(16, 70);
            _age = gcnew NumericUpDown(); _age->SetBounds(90, 66, 90, 30);
            _age->Minimum = 0; _age->Maximum = 120;
            _age->DataBindings->Add(L"Value", _source, L"Age");   // int↔decimal 由绑定引擎换算

            auto el = gcnew Label(); el->Text = L"邮箱："; el->AutoSize = true;
            el->Location = System::Drawing::Point(16, 108);
            _email = gcnew TextBox(); _email->SetBounds(90, 104, 200, 30);
            _email->DataBindings->Add(L"Text", _source, L"Email");

            box->Controls->AddRange(gcnew array<Control^> { nl, _name, al, _age, el, _email });

            auto nav = gcnew BindingNavigator(true);
            nav->BindingSource = _source;
            nav->Dock = DockStyle::Top;

            auto add = gcnew Button();
            add->Text = L"＋新增人员"; add->Dock = DockStyle::Top; add->Height = 32;
            add->Click += gcnew EventHandler(this, &MainForm::OnAdd);

            auto grid = gcnew DataGridView();
            grid->Dock = DockStyle::Fill;
            grid->DataSource = _source;
            grid->AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode::Fill;
            grid->SelectionMode = DataGridViewSelectionMode::FullRowSelect;

            Controls->Add(grid);
            Controls->Add(add);
            Controls->Add(nav);
            Controls->Add(box);
        }

    private:
        void OnAdd(Object^ s, EventArgs^ e)
        {
            _source->Add(gcnew Person(L"新人员", 20, L""));
            _source->Position = _source->Count - 1;
        }
    };

    public ref class App
    {
    public:
        static void Run()
        {
            Application::EnableVisualStyles();
            Application::SetCompatibleTextRenderingDefault(false);
            Application::Run(gcnew MainForm());
        }
    };
}
