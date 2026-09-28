// 03 窗体属性、生命周期与两种子窗体（C++/CLI 版）
// 语法增量：lambda 写成 gcnew 委托或直接用成员函数；自定义事件 event Action<String^>^；
// "判空调用" C# 的 ?.Invoke(...) 在 C++/CLI 里是一个空三元 ?: 习惯（见 OnClick 部分）。
using namespace System;
using namespace System::Windows::Forms;

namespace FormsCpp {

    // ═══ 3.4 模态子窗体 ═══
    public ref class NameDialog : public Form
    {
    private:
        TextBox^ _name;

    public:
        NameDialog()
        {
            Text = L"输入姓名";
            // 注意全限定：Form 子类里，属性名 FormBorderStyle 会遮蔽同名枚举类型
            FormBorderStyle = System::Windows::Forms::FormBorderStyle::FixedDialog;
            MaximizeBox = false; MinimizeBox = false;
            ClientSize = System::Drawing::Size(320, 120);
            StartPosition = FormStartPosition::CenterParent;

            _name = gcnew TextBox();
            _name->Dock = DockStyle::Top;

            auto label = gcnew Label();
            label->Text = L"姓名：";
            label->Dock = DockStyle::Top;
            label->Height = 32;

            auto ok = gcnew Button();
            ok->Text = L"确定";
            ok->DialogResult = System::Windows::Forms::DialogResult::OK;
            ok->Dock = DockStyle::Left; ok->Width = 96;
            auto cancel = gcnew Button();
            cancel->Text = L"取消";
            cancel->DialogResult = System::Windows::Forms::DialogResult::Cancel;
            cancel->Dock = DockStyle::Right; cancel->Width = 96;
            AcceptButton = ok;
            CancelButton = cancel;

            Controls->Add(ok);
            Controls->Add(cancel);
            Controls->Add(_name);
            Controls->Add(label);
        }

        property String^ UserName
        {
            String^ get() { return _name->Text; }
        }
    };

    // ═══ 3.5 非模态子窗体：event Action<String^>^ ═══
    public ref class FloatingWindow : public Form
    {
    private:
        int _ticks;

    public:
        // C++/CLI 声明事件：编译器生成 add_/remove_ 访问器（对应 C# 的 event 关键字）
        event Action<String^>^ TitleChanged;

        FloatingWindow()
        {
            _ticks = 0;
            Text = L"浮动窗口";
            ClientSize = System::Drawing::Size(300, 150);

            auto shout = gcnew Button();
            shout->Text = L"向主窗体发消息";
            shout->Dock = DockStyle::Fill;
            shout->Click += gcnew EventHandler(this, &FloatingWindow::OnShout);
            Controls->Add(shout);
        }

    private:
        void OnShout(Object^ sender, EventArgs^ e)
        {
            _ticks++;
            String^ msg = String::Format(L"第 {0} 次汇报", _ticks);
            // 触发事件：直接用事件名调用（编译器合成的 raise_ 方法自带无订阅者保护）。
            // 注意不能写 if (TitleChanged != nullptr)——事件不是数据成员，那样报 C3918
            TitleChanged(msg);
        }
    };

    // ═══ 3.1 主窗体 ═══
    public ref class MainForm : public Form
    {
    private:
        ListBox^ _log;
        int _modalCount;

    public:
        MainForm()
        {
            _modalCount = 0;
            Text = L"窗体与生命周期";
            ClientSize = System::Drawing::Size(560, 380);
            StartPosition = FormStartPosition::CenterScreen;

            _log = gcnew ListBox();
            _log->Dock = DockStyle::Fill;
            _log->Items->Add(L"构造函数执行完毕（此时窗体还不可见）");

            auto openModal = gcnew Button();
            openModal->Text = L"模态：输入姓名(S)";
            openModal->Dock = DockStyle::Top; openModal->Height = 36;
            openModal->Click += gcnew EventHandler(this, &MainForm::OnOpenModal);

            auto openModeless = gcnew Button();
            openModeless->Text = L"非模态：浮动窗口";
            openModeless->Dock = DockStyle::Top; openModeless->Height = 36;
            openModeless->Click += gcnew EventHandler(this, &MainForm::OnOpenModeless);

            Controls->Add(_log);
            Controls->Add(openModeless);
            Controls->Add(openModal);

            // ═══ 3.2 生命周期事件 ═══
            Load += gcnew EventHandler(this, &MainForm::OnLoad);
            Shown += gcnew EventHandler(this, &MainForm::OnShown);
            Activated += gcnew EventHandler(this, &MainForm::OnActivated);
            Deactivate += gcnew EventHandler(this, &MainForm::OnDeactivate);

            // ═══ 3.3 关闭确认 ═══
            FormClosing += gcnew FormClosingEventHandler(this, &MainForm::OnClosing);
        }

        void Log(String^ msg)
        {
            _log->Items->Insert(0, String::Format(L"{0:HH:mm:ss}  {1}", DateTime::Now, msg));
        }

    private:
        void OnLoad(Object^ s, EventArgs^ e)   { Log(L"Load：窗体首次显示前（做初始化的好地方）"); }
        void OnShown(Object^ s, EventArgs^ e)  { Log(L"Shown：窗体已经显示出来（Load 之后必有一次）"); }
        void OnActivated(Object^ s, EventArgs^ e)   { Log(L"Activated：成为活动窗口（切回来也会再触发）"); }
        void OnDeactivate(Object^ s, EventArgs^ e)  { Log(L"Deactivate：失去焦点（点了别的窗口）"); }

        void OnOpenModal(Object^ s, EventArgs^ e)
        {
            NameDialog^ dlg = gcnew NameDialog();
            if (dlg->ShowDialog(this) == System::Windows::Forms::DialogResult::OK)
            {
                _modalCount++;
                Log(String::Format(L"模态返回 OK，姓名 = {0}（第 {1} 次）", dlg->UserName, _modalCount));
            }
            else
            {
                Log(String::Format(L"模态返回 {0}（用户取消）", dlg->DialogResult));
            }
            delete dlg;
        }

        void OnOpenModeless(Object^ s, EventArgs^ e)
        {
            FloatingWindow^ win = gcnew FloatingWindow();
            win->Owner = this;
            win->TitleChanged += gcnew Action<String^>(this, &MainForm::OnChildMessage);
            win->Show(this);
            Log(L"非模态窗口已打开（Show 立即返回）");
        }

        void OnChildMessage(String^ msg) { Log(String::Format(L"浮动窗口来消息：{0}", msg)); }

        void OnClosing(Object^ s, FormClosingEventArgs^ e)
        {
            auto r = MessageBox::Show(String::Format(L"日志里有 {0} 条记录，确定退出？", _log->Items->Count),
                                      L"关闭确认", MessageBoxButtons::YesNo, MessageBoxIcon::Question);
            if (r == System::Windows::Forms::DialogResult::No)
                e->Cancel = true;
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
