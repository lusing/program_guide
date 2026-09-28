// 09 通用对话框（C++/CLI 版）
// 注意：File/Directory/Path 在 System::IO；对话框类名若被 Form 属性遮蔽要全限定
using namespace System;
using namespace System::IO;
using namespace System::Drawing;
using namespace System::Windows::Forms;

namespace DialogsCpp {

    public ref class MainForm : public Form
    {
    private:
        RichTextBox^ _editor;
        ToolStripStatusLabel^ _status;
        String^ _file;         // nullptr = 未命名
        bool _dirty;

    public:
        MainForm()
        {
            _file = nullptr;
            _dirty = false;

            Text = L"迷你编辑器——对话框大全";
            ClientSize = System::Drawing::Size(720, 480);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);

            _editor = gcnew RichTextBox();
            _editor->Dock = DockStyle::Fill;
            _editor->Text = L"改一个字看标题出现 *，再按 Ctrl+S 保存。\n格式菜单里四个对话框随便玩。\n";
            _editor->TextChanged += gcnew EventHandler(this, &MainForm::OnTextChanged);

            _status = gcnew ToolStripStatusLabel();
            _status->Spring = true;
            _status->TextAlign = ContentAlignment::MiddleLeft;
            auto statusStrip = gcnew StatusStrip();
            statusStrip->Items->Add(_status);

            auto menu = gcnew MenuStrip();
            auto miOpen = gcnew ToolStripMenuItem(L"打开(&O)…");
            miOpen->ShortcutKeys = static_cast<Keys>(Keys::Control | Keys::O);
            miOpen->Click += gcnew EventHandler(this, &MainForm::OnOpen);

            auto miSave = gcnew ToolStripMenuItem(L"保存(&S)");
            miSave->ShortcutKeys = static_cast<Keys>(Keys::Control | Keys::S);
            miSave->Tag = false;
            miSave->Click += gcnew EventHandler(this, &MainForm::OnSaveClick);

            auto miSaveAs = gcnew ToolStripMenuItem(L"另存为(&A)…");
            miSaveAs->Tag = true;
            miSaveAs->Click += gcnew EventHandler(this, &MainForm::OnSaveClick);

            auto miQuit = gcnew ToolStripMenuItem(L"退出(&Q)");
            miQuit->Click += gcnew EventHandler(this, &MainForm::OnQuit);

            auto fileMenu = gcnew ToolStripMenuItem(L"文件(&F)");
            fileMenu->DropDownItems->AddRange(gcnew array<ToolStripItem^>
            {
                miOpen, miSave, miSaveAs, gcnew ToolStripSeparator(), miQuit
            });

            auto miColor = gcnew ToolStripMenuItem(L"文字颜色(&C)…");
            miColor->Click += gcnew EventHandler(this, &MainForm::OnColor);

            auto miFont = gcnew ToolStripMenuItem(L"字体(&F)…");
            miFont->Click += gcnew EventHandler(this, &MainForm::OnFont);

            auto miDir = gcnew ToolStripMenuItem(L"统计文件夹(&D)…");
            miDir->Click += gcnew EventHandler(this, &MainForm::OnFolder);

            auto fmtMenu = gcnew ToolStripMenuItem(L"格式(&M)");
            fmtMenu->DropDownItems->AddRange(gcnew array<ToolStripItem^> { miColor, miFont, miDir });

            menu->Items->AddRange(gcnew array<ToolStripItem^> { fileMenu, fmtMenu });

            FormClosing += gcnew FormClosingEventHandler(this, &MainForm::OnClosing);

            Controls->Add(_editor);
            Controls->Add(statusStrip);
            Controls->Add(menu);
            MainMenuStrip = menu;
            UpdateTitle();
            Say(L"就绪");
        }

    private:
        void Say(String^ msg) { _status->Text = L"  " + msg; }

        void UpdateTitle()
        {
            String^ name = (_file == nullptr) ? L"未命名" : Path::GetFileName(_file);
            String^ star = _dirty ? L" *" : L"";
            Text = String::Format(L"迷你编辑器——{0}{1}", name, star);
        }

        void OnTextChanged(Object^ s, EventArgs^ e) { _dirty = true; UpdateTitle(); }

        void OnOpen(Object^ s, EventArgs^ e)
        {
            auto dlg = gcnew OpenFileDialog();
            dlg->Title = L"挑一个文本文件";
            dlg->Filter = L"文本文件|*.txt;*.md|日志|*.log|所有文件|*.*";
            dlg->InitialDirectory = Environment::GetFolderPath(Environment::SpecialFolder::MyDocuments);
            dlg->CheckFileExists = true;
            if (dlg->ShowDialog(this) != System::Windows::Forms::DialogResult::OK) { delete dlg; return; }
            _editor->Text = File::ReadAllText(dlg->FileName);
            _file = dlg->FileName;
            _dirty = false;
            UpdateTitle();
            Say(String::Format(L"打开 {0}", _file));
            delete dlg;
        }

        void OnSaveClick(Object^ s, EventArgs^ e)
        {
            bool saveAs = safe_cast<bool>(safe_cast<ToolStripMenuItem^>(s)->Tag);
            Save(saveAs);
        }

        void Save(bool saveAs)
        {
            if (_file == nullptr || saveAs)
            {
                auto dlg = gcnew SaveFileDialog();
                dlg->Filter = L"文本文件|*.txt|所有文件|*.*";
                dlg->DefaultExt = L"txt";
                dlg->AddExtension = true;
                dlg->OverwritePrompt = true;
                dlg->FileName = (_file == nullptr) ? L"新文档.txt" : Path::GetFileName(_file);
                if (dlg->ShowDialog(this) != System::Windows::Forms::DialogResult::OK)
                {
                    Say(L"取消保存");
                    delete dlg;
                    return;
                }
                _file = dlg->FileName;
                delete dlg;
            }
            File::WriteAllText(_file, _editor->Text);
            _dirty = false;
            UpdateTitle();
            Say(String::Format(L"已保存到 {0}", _file));
        }

        void OnColor(Object^ s, EventArgs^ e)
        {
            auto dlg = gcnew ColorDialog();
            dlg->Color = _editor->ForeColor;
            dlg->FullOpen = true;
            if (dlg->ShowDialog(this) == System::Windows::Forms::DialogResult::OK)
                _editor->SelectionColor = dlg->Color;
            delete dlg;
        }

        void OnFont(Object^ s, EventArgs^ e)
        {
            auto dlg = gcnew FontDialog();
            dlg->ShowColor = false;
            dlg->MinSize = 9;
            dlg->MaxSize = 36;
            dlg->FontMustExist = true;
            if (dlg->ShowDialog(this) == System::Windows::Forms::DialogResult::OK)
                _editor->SelectionFont = dlg->Font;
            delete dlg;
        }

        void OnFolder(Object^ s, EventArgs^ e)
        {
            auto dlg = gcnew FolderBrowserDialog();
            dlg->Description = L"选一个文件夹，统计里面文本文件的数量";
            dlg->UseDescriptionForTitle = true;
            if (dlg->ShowDialog(this) == System::Windows::Forms::DialogResult::OK)
            {
                int n = Directory::GetFiles(dlg->SelectedPath, L"*.txt", SearchOption::TopDirectoryOnly)->Length;
                Say(String::Format(L"{0} 下有 {1} 个 .txt（只看第一层）", dlg->SelectedPath, n));
            }
            delete dlg;
        }

        void OnQuit(Object^ s, EventArgs^ e) { Close(); }

        void OnClosing(Object^ s, FormClosingEventArgs^ e)
        {
            if (!_dirty) return;
            auto r = MessageBox::Show(this,
                L"内容有未保存的修改。\n「是」保存后退出，「否」直接退出，「取消」留在编辑器。",
                L"迷你编辑器", MessageBoxButtons::YesNoCancel, MessageBoxIcon::Warning);
            if (r == System::Windows::Forms::DialogResult::Cancel)
                e->Cancel = true;
            else if (r == System::Windows::Forms::DialogResult::Yes)
            {
                Save(false);
                if (_dirty) e->Cancel = true;   // 保存被取消就别退出
            }
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
