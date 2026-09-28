// 04 布局（C++/CLI 版）
// 语法增量：位或合并枚举用 |（C# 的 |，F# 的 |||）；数组用 array<>^ 或 cli::array
using namespace System;
using namespace System::Drawing;
using namespace System::Windows::Forms;

namespace LayoutCpp {

    public ref class MainForm : public Form
    {
    private:
        Label^ _sizeLabel;
        TextBox^ _anchorBox;

    public:
        MainForm()
        {
            Text = L"布局系统";
            ClientSize = System::Drawing::Size(520, 400);
            MinimumSize = System::Drawing::Size(420, 320);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);
            // AutoScaleMode 同样是"属性名遮蔽枚举类型"：全限定
            AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;

            // ═══ 4.1 底部状态 ═══
            _sizeLabel = gcnew Label();
            _sizeLabel->Dock = DockStyle::Bottom;
            _sizeLabel->Height = 30;
            _sizeLabel->TextAlign = ContentAlignment::MiddleLeft;
            _sizeLabel->BackColor = Color::Gainsboro;
            Resize += gcnew EventHandler(this, &MainForm::OnResize);
            ReportSize();

            // ═══ 4.2 FlowLayoutPanel ═══
            auto flow = gcnew FlowLayoutPanel();
            flow->Dock = DockStyle::Bottom; flow->Height = 76;
            array<String^>^ names = { L"重置", L"保存", L"导出", L"打印", L"分享", L"更多…" };
            for each (String^ name in names)
            {
                auto b = gcnew Button();
                b->Text = name; b->AutoSize = true;
                b->Margin = System::Windows::Forms::Padding(4);
                b->Click += gcnew EventHandler(this, &MainForm::OnFlowClick);
                b->Tag = name;                       // 把名字随身带：一个处理器服务所有按钮
                flow->Controls->Add(b);
            }

            // ═══ 4.3 Anchor 实验 ═══
            _anchorBox = gcnew TextBox();
            _anchorBox->Anchor = static_cast<AnchorStyles>(
                AnchorStyles::Left | AnchorStyles::Top | AnchorStyles::Right);
            _anchorBox->Location = System::Drawing::Point(120, 250);
            _anchorBox->Width = 300;

            auto anchorLabel = gcnew Label();
            anchorLabel->Text = L"Anchor →"; anchorLabel->AutoSize = true;
            anchorLabel->Location = System::Drawing::Point(16, 253);

            auto anchorHint = gcnew Label();
            anchorHint->Text = L"拖宽窗口：上面这个文本框跟着变宽（锚住了左右两边）";
            anchorHint->AutoSize = true;
            anchorHint->Location = System::Drawing::Point(120, 278);
            anchorHint->ForeColor = Color::DimGray;

            // ═══ 4.4 TableLayoutPanel ═══
            auto table = gcnew TableLayoutPanel();
            table->Dock = DockStyle::Top; table->Height = 220;
            table->ColumnCount = 2; table->RowCount = 4;
            table->ColumnStyles->Add(gcnew ColumnStyle(SizeType::Percent, 28.0f));
            table->ColumnStyles->Add(gcnew ColumnStyle(SizeType::Percent, 72.0f));
            table->Padding = System::Windows::Forms::Padding(12);

            AddRow(table, 0, L"用户名：", gcnew TextBox());
            AddRow(table, 1, L"邮箱：", gcnew TextBox());

            auto combo = gcnew ComboBox();
            combo->Dock = DockStyle::Fill;
            combo->DropDownStyle = ComboBoxStyle::DropDownList;
            combo->Items->Add(L"研发部"); combo->Items->Add(L"市场部");
            combo->Items->Add(L"财务部"); combo->Items->Add(L"人事部");
            combo->SelectedIndex = 0;
            AddRow(table, 2, L"部门：", combo);

            auto notify = gcnew CheckBox();
            notify->Text = L"接受通知邮件"; notify->AutoSize = true;
            AddRow(table, 3, L"偏好：", notify);

            Controls->Add(table);
            Controls->Add(anchorLabel);
            Controls->Add(_anchorBox);
            Controls->Add(anchorHint);
            Controls->Add(flow);
            Controls->Add(_sizeLabel);
        }

    private:
        static void AddRow(TableLayoutPanel^ table, int row, String^ caption, Control^ input)
        {
            auto label = gcnew Label();
            label->Text = caption;
            label->Dock = DockStyle::Fill;
            label->TextAlign = ContentAlignment::MiddleRight;
            label->Margin = System::Windows::Forms::Padding(0, 9, 8, 3);
            table->Controls->Add(label, 0, row);
            table->Controls->Add(input, 1, row);
        }

        void OnFlowClick(Object^ sender, EventArgs^ e)
        {
            auto b = safe_cast<Button^>(sender);
            _sizeLabel->Text = String::Format(L"[flow] 点击了「{0}」——注意本行放不下时会自动换行", b->Tag);
        }

        void OnResize(Object^ sender, EventArgs^ e) { ReportSize(); }

        void ReportSize()
        {
            _sizeLabel->Text = String::Format(L"  ClientSize = {0}×{1}（拖动窗口右下角试试）",
                ClientSize.Width, ClientSize.Height);
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
