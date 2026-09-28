// 18 通讯录（C++/CLI UI；数据层在 datalib/ 的 C# 类库里）
using namespace System;
using namespace System::Data;
using namespace System::Drawing;
using namespace System::IO;
using namespace System::Windows::Forms;
using namespace DataLib;

namespace DataCpp {

    public ref class MainForm : public Form
    {
    private:
        ContactRepository^ _repo;
        DataGridView^ _grid;
        TextBox^ _name;
        TextBox^ _phone;
        TextBox^ _city;
        TextBox^ _search;
        Label^ _status;
        Int64 _selectedId;

    public:
        MainForm()
        {
            Text = L"通讯录（SQLite，C++/CLI UI + C# 数据层）";
            ClientSize = System::Drawing::Size(700, 480);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);
            _selectedId = 0;

            String^ db = Path::Combine(Path::GetTempPath(), L"winforms18cpp.db");
            _repo = gcnew ContactRepository(db);

            auto editor = gcnew GroupBox();
            editor->Text = L" 联系人（先在表格里选中一行，再编辑/删除）";
            editor->Dock = DockStyle::Top; editor->Height = 120;

            _name = Field(editor, L"姓名：", 30);
            _phone = Field(editor, L"电话：", 66);
            _city = Field(editor, L"城市：", 102);

            auto add = gcnew Button(); add->Text = L"新增"; add->AutoSize = true;
            add->Location = System::Drawing::Point(430, 26);
            add->Click += gcnew EventHandler(this, &MainForm::OnAdd);
            auto upd = gcnew Button(); upd->Text = L"保存修改"; upd->AutoSize = true;
            upd->Location = System::Drawing::Point(510, 26);
            upd->Click += gcnew EventHandler(this, &MainForm::OnUpdate);
            auto del = gcnew Button(); del->Text = L"删除选中"; del->AutoSize = true;
            del->Location = System::Drawing::Point(430, 60);
            del->Click += gcnew EventHandler(this, &MainForm::OnDelete);
            editor->Controls->AddRange(gcnew array<Control^> { add, upd, del });

            auto searchBox = gcnew GroupBox();
            searchBox->Text = L" 搜索（参数化——输入 ' OR '1'='1 也只是当普通文本）";
            searchBox->Dock = DockStyle::Top; searchBox->Height = 70;
            _search = gcnew TextBox(); _search->SetBounds(16, 28, 240, 30);
            auto go = gcnew Button(); go->Text = L"查"; go->AutoSize = true;
            go->Location = System::Drawing::Point(270, 26);
            go->Click += gcnew EventHandler(this, &MainForm::OnSearch);
            searchBox->Controls->AddRange(gcnew array<Control^> { _search, go });

            _grid = gcnew DataGridView();
            _grid->Dock = DockStyle::Fill;
            _grid->ReadOnly = true;
            _grid->AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode::Fill;
            _grid->SelectionMode = DataGridViewSelectionMode::FullRowSelect;
            _grid->AllowUserToAddRows = false;
            _grid->CellClick += gcnew DataGridViewCellEventHandler(this, &MainForm::OnCellClick);

            _status = gcnew Label();
            _status->Dock = DockStyle::Bottom; _status->Height = 30;
            _status->BackColor = Color::Gainsboro;

            Controls->Add(_grid);
            Controls->Add(searchBox);
            Controls->Add(editor);
            Controls->Add(_status);

            Reload(nullptr);
            Say(String::Format(L"数据库：{0}", db));
        }

    private:
        static TextBox^ Field(GroupBox^ box, String^ caption, int y)
        {
            auto label = gcnew Label();
            label->Text = caption; label->AutoSize = true;
            label->Location = System::Drawing::Point(16, y + 4);
            auto tb = gcnew TextBox();
            tb->Location = System::Drawing::Point(70, y);
            tb->Width = 200;
            box->Controls->Add(label);
            box->Controls->Add(tb);
            return tb;
        }

        void Say(String^ msg) { _status->Text = L"  " + msg; }

        void Reload(String^ message)
        {
            _grid->DataSource = _repo->All(_search->Text->Trim());
            _selectedId = 0;
            if (message != nullptr)
                Say(String::Format(L"{0}，当前 {1} 条", message, _grid->RowCount));
        }

        void OnCellClick(Object^ s, DataGridViewCellEventArgs^ e)
        {
            if (e->RowIndex < 0) return;
            auto row = _grid->Rows[e->RowIndex];
            _selectedId = safe_cast<Int64>(row->Cells[L"id"]->Value);
            _name->Text = safe_cast<String^>(row->Cells[L"name"]->Value);
            _phone->Text = safe_cast<String^>(row->Cells[L"phone"]->Value);
            _city->Text = safe_cast<String^>(row->Cells[L"city"]->Value);
        }

        void OnSearch(Object^ s, EventArgs^ e) { Reload(nullptr); }

        void OnAdd(Object^ s, EventArgs^ e)
        {
            _repo->Add(_name->Text, _phone->Text, _city->Text);
            Reload(L"已新增");
        }

        void OnUpdate(Object^ s, EventArgs^ e)
        {
            if (_selectedId == 0) { Say(L"先在表格里选中一行"); return; }
            _repo->Update(_selectedId, _name->Text, _phone->Text, _city->Text);
            Reload(L"已修改");
        }

        void OnDelete(Object^ s, EventArgs^ e)
        {
            if (_selectedId == 0) { Say(L"先在表格里选中一行"); return; }
            _repo->Delete(_selectedId);
            Reload(L"已删除");
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
