// 05 文本类控件（C++/CLI 版）
// 语法增量：数组的 array<Control^>^；Controls->AddRange 接 ICollection^，
// 用 gcnew array<Control^>{...} 直接构造
using namespace System;
using namespace System::Diagnostics;
using namespace System::Drawing;
using namespace System::Windows::Forms;

namespace TextCpp {

    public ref class MainForm : public Form
    {
    private:
        RichTextBox^ _rich;
        TextBox^ _user;
        TextBox^ _pwd;
        NumericUpDown^ _age;
        Label^ _status;

    public:
        MainForm()
        {
            Text = L"文本类控件";
            ClientSize = System::Drawing::Size(640, 480);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);

            // ═══ 5.1 单行输入三件套 ═══
            auto login = gcnew GroupBox();
            login->Text = L" 单行输入 ";
            login->Dock = DockStyle::Top; login->Height = 130;

            auto userLabel = gcnew Label();
            userLabel->Text = L"用户名："; userLabel->AutoSize = true;
            userLabel->Location = System::Drawing::Point(16, 32);

            _user = gcnew TextBox();
            _user->Location = System::Drawing::Point(100, 28);
            _user->Width = 180;
            _user->MaxLength = 12;

            auto pwdLabel = gcnew Label();
            pwdLabel->Text = L"密码："; pwdLabel->AutoSize = true;
            pwdLabel->Location = System::Drawing::Point(16, 68);

            _pwd = gcnew TextBox();
            _pwd->Location = System::Drawing::Point(100, 64);
            _pwd->Width = 180;
            _pwd->UseSystemPasswordChar = true;

            auto ageLabel = gcnew Label();
            ageLabel->Text = L"年龄："; ageLabel->AutoSize = true;
            ageLabel->Location = System::Drawing::Point(300, 32);

            _age = gcnew NumericUpDown();
            _age->Location = System::Drawing::Point(370, 28);
            _age->Width = 110;
            _age->Minimum = 1; _age->Maximum = 120;
            _age->Value = 18;
            _age->ValueChanged += gcnew EventHandler(this, &MainForm::OnAgeChanged);

            _status = gcnew Label();
            _status->Dock = DockStyle::Bottom; _status->Height = 28;
            _status->TextAlign = ContentAlignment::MiddleLeft;
            _status->BackColor = Color::Gainsboro;

            auto echo = gcnew Button();
            echo->Text = L"回显";
            echo->Location = System::Drawing::Point(300, 62); echo->Width = 90;
            echo->Click += gcnew EventHandler(this, &MainForm::OnEcho);

            login->Controls->AddRange(gcnew array<Control^>
            {
                userLabel, _user, pwdLabel, _pwd, ageLabel, _age, echo
            });

            // ═══ 5.2 RichTextBox ═══
            auto richLabel = gcnew Label();
            richLabel->Text = L"RichTextBox（彩色追加 / 选区加粗 / 字数统计）";
            richLabel->Dock = DockStyle::Top; richLabel->Height = 26;

            _rich = gcnew RichTextBox();
            _rich->Dock = DockStyle::Fill;
            _rich->AcceptsTab = true;
            _rich->ScrollBars = RichTextBoxScrollBars::Vertical;
            _rich->Text = L"普通文本一行。\n选中一段文字再点「加粗选中」试试。\n";

            // ═══ 5.3 工具条 ═══
            auto tools = gcnew FlowLayoutPanel();
            tools->Dock = DockStyle::Top; tools->Height = 44;

            auto red = gcnew Button(); red->Text = L"追加红字"; red->AutoSize = true;
            red->Click += gcnew EventHandler(this, &MainForm::OnAppendRed);
            auto blue = gcnew Button(); blue->Text = L"追加蓝字"; blue->AutoSize = true;
            blue->Click += gcnew EventHandler(this, &MainForm::OnAppendBlue);
            auto bold = gcnew Button(); bold->Text = L"加粗选中"; bold->AutoSize = true;
            bold->Click += gcnew EventHandler(this, &MainForm::OnBold);
            auto count = gcnew Button(); count->Text = L"字数统计"; count->AutoSize = true;
            count->Click += gcnew EventHandler(this, &MainForm::OnCount);
            tools->Controls->AddRange(gcnew array<Control^> { red, blue, bold, count });

            // ═══ 5.4 LinkLabel ═══
            auto link = gcnew LinkLabel();
            link->Text = L"遇到问题？查阅 Microsoft Learn 的 WinForms 文档";
            link->Dock = DockStyle::Bottom; link->Height = 34;
            link->LinkBehavior = LinkBehavior::HoverUnderline;
            link->Links->Add(8, 15, L"https://learn.microsoft.com/dotnet/desktop/winforms/");
            link->LinkClicked += gcnew LinkLabelLinkClickedEventHandler(this, &MainForm::OnLink);

            Controls->Add(_rich);
            Controls->Add(tools);
            Controls->Add(richLabel);
            Controls->Add(_status);
            Controls->Add(login);
            Controls->Add(link);
        }

    private:
        void AppendColored(String^ text, Color color)
        {
            _rich->SelectionStart = _rich->Text->Length;
            _rich->SelectionLength = 0;
            _rich->SelectionColor = color;
            _rich->AppendText(text);
            _rich->SelectionColor = _rich->ForeColor;
        }

        void OnAgeChanged(Object^ s, EventArgs^ e)
        {
            _status->Text = String::Format(L"  年龄 = {0}（NumericUpDown 自带上下箭头与校验）", _age->Value);
        }

        void OnEcho(Object^ s, EventArgs^ e)
        {
            MessageBox::Show(String::Format(L"用户名「{0}」长度 {1}\n密码（明文在内存里）「{2}」",
                              _user->Text, _user->Text->Length, _pwd->Text),
                             L"回显", MessageBoxButtons::OK, MessageBoxIcon::Information);
        }

        void OnAppendRed(Object^ s, EventArgs^ e) { AppendColored(L"这是红色追加的一行\n", Color::Firebrick); }
        void OnAppendBlue(Object^ s, EventArgs^ e) { AppendColored(L"这是蓝色追加的一行\n", Color::RoyalBlue); }

        void OnBold(Object^ s, EventArgs^ e)
        {
            if (_rich->SelectionLength == 0) { MessageBox::Show(L"先选中一段文字"); return; }
            _rich->SelectionFont = gcnew Drawing::Font(_rich->Font,
                static_cast<FontStyle>(_rich->SelectionFont->Style | FontStyle::Bold));
        }

        void OnCount(Object^ s, EventArgs^ e)
        {
            MessageBox::Show(String::Format(L"字符数 {0}，当前选区 {1} 字",
                              _rich->Text->Length, _rich->SelectionLength), L"统计");
        }

        void OnLink(Object^ s, LinkLabelLinkClickedEventArgs^ e)
        {
            auto url = safe_cast<String^>(e->Link->LinkData);
            Process::Start(gcnew ProcessStartInfo(url))->Close();
            // LinkVisited 需要拿到具体 Link 对象：C++/CLI 里通过 sender 反查
            safe_cast<LinkLabel^>(s)->LinkVisited = true;
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
