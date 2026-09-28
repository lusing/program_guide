// 06 选择类控件（C++/CLI 版）
// 语法增量：模式匹配风格的类型判断用 safe_cast + try 或 is + cast；
// 这里演示 C++/CLI 的条件类型查询：if (dynamic_cast<RadioButton^>(c) != nullptr)
using namespace System;
using namespace System::Drawing;
using namespace System::Windows::Forms;

namespace SelectCpp {

    public ref class MainForm : public Form
    {
    private:
        FlowLayoutPanel^ _deptFlow;
        FlowLayoutPanel^ _typeFlow;
        ComboBox^ _city;
        CheckedListBox^ _hobbies;
        DateTimePicker^ _date;
        TrackBar^ _volume;
        Label^ _volumeLabel;
        Label^ _status;

    public:
        MainForm()
        {
            Text = L"选择类控件";
            ClientSize = System::Drawing::Size(660, 460);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);

            _status = gcnew Label();
            _status->Dock = DockStyle::Bottom; _status->Height = 30;
            _status->TextAlign = ContentAlignment::MiddleLeft;
            _status->BackColor = Color::Gainsboro;

            // ═══ 6.1 RadioButton 互斥组 ═══
            _deptFlow = gcnew FlowLayoutPanel();
            _deptFlow->Dock = DockStyle::Fill;
            _deptFlow->FlowDirection = FlowDirection::TopDown;
            array<String^>^ depts = { L"研发", L"测试", L"设计" };
            for each (String^ d in depts)
            {
                auto rb = gcnew RadioButton();
                rb->Text = d; rb->AutoSize = true;
                rb->Tag = d;
                rb->CheckedChanged += gcnew EventHandler(this, &MainForm::OnDeptChanged);
                _deptFlow->Controls->Add(rb);
            }
            safe_cast<RadioButton^>(_deptFlow->Controls[0])->Checked = true;
            auto deptBox = gcnew GroupBox();
            deptBox->Text = L" 部门（互斥组 A）"; deptBox->Dock = DockStyle::Fill;
            deptBox->Controls->Add(_deptFlow);

            _typeFlow = gcnew FlowLayoutPanel();
            _typeFlow->Dock = DockStyle::Fill;
            _typeFlow->FlowDirection = FlowDirection::TopDown;
            array<String^>^ types = { L"全职", L"实习" };
            for each (String^ t in types)
            {
                auto rb = gcnew RadioButton();
                rb->Text = t; rb->AutoSize = true;
                _typeFlow->Controls->Add(rb);
            }
            safe_cast<RadioButton^>(_typeFlow->Controls[1])->Checked = true;
            auto typeBox = gcnew GroupBox();
            typeBox->Text = L" 用工类型（互斥组 B）"; typeBox->Dock = DockStyle::Fill;
            typeBox->Controls->Add(_typeFlow);

            // ═══ 6.2 ComboBox ═══
            _city = gcnew ComboBox();
            _city->Dock = DockStyle::Top;
            _city->DropDownStyle = ComboBoxStyle::DropDownList;
            _city->Items->AddRange(gcnew array<Object^> { L"北京", L"上海", L"广州", L"深圳", L"杭州" });
            _city->SelectedIndex = 0;
            _city->SelectedIndexChanged += gcnew EventHandler(this, &MainForm::OnCityChanged);
            auto cityBox = gcnew GroupBox();
            cityBox->Text = L" 城市（ComboBox，DropDownList 只能选）"; cityBox->Dock = DockStyle::Fill;
            cityBox->Controls->Add(_city);

            // ═══ 6.3 CheckedListBox ═══
            _hobbies = gcnew CheckedListBox();
            _hobbies->Dock = DockStyle::Fill;
            _hobbies->CheckOnClick = true;
            _hobbies->Items->AddRange(gcnew array<Object^> { L"看书", L"游戏", L"爬山", L"摄影", L"做饭" });
            auto hobbyBox = gcnew GroupBox();
            hobbyBox->Text = L" 兴趣（CheckedListBox，可多选）"; hobbyBox->Dock = DockStyle::Fill;
            hobbyBox->Controls->Add(_hobbies);

            // ═══ 6.4 + 6.5 ═══
            auto miscBox = gcnew GroupBox();
            miscBox->Text = L" 日期与音量 "; miscBox->Dock = DockStyle::Fill;

            auto dateLabel = gcnew Label();
            dateLabel->Text = L"入职日期："; dateLabel->AutoSize = true;
            dateLabel->Location = System::Drawing::Point(12, 30);

            _date = gcnew DateTimePicker();
            _date->SetBounds(100, 26, 200, 30);
            _date->Format = DateTimePickerFormat::Long;
            _date->Value = DateTime::Today;
            _date->ValueChanged += gcnew EventHandler(this, &MainForm::OnDateChanged);

            auto volLabel = gcnew Label();
            volLabel->Text = L"音量："; volLabel->AutoSize = true;
            volLabel->Location = System::Drawing::Point(12, 76);

            _volume = gcnew TrackBar();
            _volume->SetBounds(96, 70, 220, 45);
            _volume->Minimum = 0; _volume->Maximum = 100;
            _volume->Value = 60;
            _volume->TickFrequency = 10;
            _volume->Scroll += gcnew EventHandler(this, &MainForm::OnVolumeScroll);

            auto volumeLabel = gcnew Label();
            volumeLabel->Text = L"音量 = 60"; volumeLabel->AutoSize = true;
            volumeLabel->Location = System::Drawing::Point(100, 106);
            _volumeLabel = volumeLabel;

            auto summary = gcnew Button();
            summary->Text = L"汇总我的选择"; summary->AutoSize = true;
            summary->Location = System::Drawing::Point(12, 136);
            summary->Click += gcnew EventHandler(this, &MainForm::OnSummary);

            miscBox->Controls->AddRange(gcnew array<Control^>
            {
                dateLabel, _date, volLabel, _volume, volumeLabel, summary
            });

            // ═══ 布局 ═══
            auto rightSplit = gcnew TableLayoutPanel();
            rightSplit->Dock = DockStyle::Fill; rightSplit->RowCount = 2;
            rightSplit->RowStyles->Add(gcnew RowStyle(SizeType::Percent, 55.0f));
            rightSplit->RowStyles->Add(gcnew RowStyle(SizeType::Percent, 45.0f));
            rightSplit->Controls->Add(miscBox, 0, 0);
            rightSplit->Controls->Add(hobbyBox, 0, 1);

            auto grid = gcnew TableLayoutPanel();
            grid->Dock = DockStyle::Fill; grid->ColumnCount = 2; grid->RowCount = 2;
            grid->ColumnStyles->Add(gcnew ColumnStyle(SizeType::Percent, 50.0f));
            grid->ColumnStyles->Add(gcnew ColumnStyle(SizeType::Percent, 50.0f));
            grid->RowStyles->Add(gcnew RowStyle(SizeType::Percent, 45.0f));
            grid->RowStyles->Add(gcnew RowStyle(SizeType::Percent, 55.0f));
            grid->Controls->Add(deptBox, 0, 0);
            grid->Controls->Add(typeBox, 1, 0);
            grid->Controls->Add(cityBox, 0, 1);
            grid->Controls->Add(rightSplit, 1, 1);

            Controls->Add(grid);
            Controls->Add(_status);
        }

    private:
        static String^ CheckedText(FlowLayoutPanel^ flow)
        {
            for each (Control^ c in flow->Controls)
            {
                auto rb = dynamic_cast<RadioButton^>(c);
                if (rb != nullptr && rb->Checked)
                    return rb->Text;
            }
            return L"（未选）";
        }

        void OnDeptChanged(Object^ s, EventArgs^ e)
        {
            auto rb = safe_cast<RadioButton^>(s);
            if (rb->Checked)
                _status->Text = String::Format(L"  部门 → {0}", rb->Tag);
        }

        void OnCityChanged(Object^ s, EventArgs^ e)
        {
            _status->Text = String::Format(L"  城市 → {0}（索引 {1}）", _city->SelectedItem, _city->SelectedIndex);
        }

        void OnDateChanged(Object^ s, EventArgs^ e)
        {
            _status->Text = String::Format(L"  入职 → {0:yyyy-MM-dd}", _date->Value);
        }

        void OnVolumeScroll(Object^ s, EventArgs^ e)
        {
            _volumeLabel->Text = String::Format(L"音量 = {0}（拖动时连续触发 Scroll）", _volume->Value);
        }

        void OnSummary(Object^ s, EventArgs^ e)
        {
            auto hobbies = gcnew System::Text::StringBuilder();
            for each (Object^ o in _hobbies->CheckedItems)
            {
                if (hobbies->Length > 0) hobbies->Append(L"、");
                hobbies->Append(safe_cast<String^>(o));
            }
            if (hobbies->Length == 0) hobbies->Append(L"（无）");
            MessageBox::Show(this,
                String::Format(L"部门：{0}\n用工：{1}\n城市：{2}\n入职：{3:yyyy-MM-dd}\n音量：{4}\n兴趣：{5}",
                    CheckedText(_deptFlow), CheckedText(_typeFlow), _city->SelectedItem,
                    _date->Value, _volume->Value, hobbies->ToString()),
                L"汇总");
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
