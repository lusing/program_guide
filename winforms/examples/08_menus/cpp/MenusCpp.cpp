// 08 菜单、工具栏与状态栏（C++/CLI 版）
// 语法增量：lambda 等价物就是成员函数 + gcnew 委托；
// 事件处理器签名不同的事件用对应的 XxxEventHandler 类型
using namespace System;
using namespace System::Drawing;
using namespace System::Windows::Forms;

namespace MenusCpp {

    public ref class MainForm : public Form
    {
    private:
        RichTextBox^ _editor;
        ToolStripStatusLabel^ _hint;
        ToolStripStatusLabel^ _count;
        ToolStrip^ _tool;
        StatusStrip^ _status;

    public:
        MainForm()
        {
            Text = L"菜单工具栏示例——迷你编辑器";
            ClientSize = System::Drawing::Size(720, 480);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);

            _editor = gcnew RichTextBox();
            _editor->Dock = DockStyle::Fill;
            _editor->Text = L"试试：菜单、Ctrl+N、在正文里点右键、拖宽看状态栏数字。\n";

            // ═══ 状态栏 ═══
            _hint = gcnew ToolStripStatusLabel();
            _hint->Spring = true;
            _hint->TextAlign = ContentAlignment::MiddleLeft;
            _count = gcnew ToolStripStatusLabel(L"0 字");
            _status = gcnew StatusStrip();
            _status->Items->AddRange(gcnew array<ToolStripItem^> { _hint, _count });
            Say(L"就绪");

            // ═══ 菜单栏 ═══
            auto menu = gcnew MenuStrip();
            auto miNew = Item(L"新建(&N)", static_cast<Keys>(Keys::Control | Keys::N), L"新建文档");
            auto miSave = Item(L"保存(&S)", static_cast<Keys>(Keys::Control | Keys::S), L"保存 (Ctrl+S)");
            auto miQuit = Item(L"退出(&Q)", static_cast<Keys>(Keys::Control | Keys::Q), L"退出");
            menu->Items->Add(Drop(L"文件(&F)", gcnew array<ToolStripItem^>
            {
                miNew, miSave, gcnew ToolStripSeparator(), miQuit
            }));

            auto miAll = Item(L"全选(&A)", static_cast<Keys>(Keys::Control | Keys::A), L"全选 (Ctrl+A)");
            auto miCopy = Item(L"复制(&C)", static_cast<Keys>(Keys::Control | Keys::C), L"复制 (Ctrl+C)");
            auto miClear = Item(L"清空", Keys::None, L"清空文档");
            menu->Items->Add(Drop(L"编辑(&E)", gcnew array<ToolStripItem^>
            {
                miAll, miCopy, gcnew ToolStripSeparator(), miClear
            }));

            // 视图：CheckOnClick 的勾选菜单
            auto miTool = gcnew ToolStripMenuItem(L"工具栏(&T)");
            miTool->Checked = true; miTool->CheckOnClick = true;
            miTool->Click += gcnew EventHandler(this, &MainForm::OnToggleTool);
            auto miStatus = gcnew ToolStripMenuItem(L"状态栏(&B)");
            miStatus->Checked = true; miStatus->CheckOnClick = true;
            miStatus->Click += gcnew EventHandler(this, &MainForm::OnToggleStatus);
            menu->Items->Add(Drop(L"视图(&V)", gcnew array<ToolStripItem^> { miTool, miStatus }));

            auto miAbout = Item(L"关于(&A)", Keys::F1, L"关于");
            menu->Items->Add(Drop(L"帮助(&H)", gcnew array<ToolStripItem^> { miAbout }));

            // ═══ 工具栏 ═══
            _tool = gcnew ToolStrip();
            _tool->GripStyle = ToolStripGripStyle::Hidden;
            _tool->Items->AddRange(gcnew array<ToolStripItem^>
            {
                ToolBtn(L"新建", L"新建文档 (Ctrl+N)", miNew),
                ToolBtn(L"保存", L"保存 (Ctrl+S)", miSave),
                gcnew ToolStripSeparator(),
                ToolBtn(L"全选", L"全选 (Ctrl+A)", miAll),
                ToolBtn(L"清空", L"清空文档", miClear)
            });

            // ═══ 右键菜单 ═══
            // ContextMenuStrip 也是"Form 属性名遮蔽类型名"：gcnew 时要全限定
            auto ctx = gcnew System::Windows::Forms::ContextMenuStrip();
            ctx->Items->AddRange(gcnew array<ToolStripItem^>
            {
                Item(L"剪切", static_cast<Keys>(Keys::Control | Keys::X), L"剪切 (Ctrl+X)"),
                Item(L"复制", static_cast<Keys>(Keys::Control | Keys::C), L"复制 (Ctrl+C)"),
                Item(L"粘贴", static_cast<Keys>(Keys::Control | Keys::V), L"粘贴 (Ctrl+V)"),
                gcnew ToolStripSeparator(),
                Item(L"全选", static_cast<Keys>(Keys::Control | Keys::A), L"全选 (Ctrl+A)")
            });
            _editor->ContextMenuStrip = ctx;

            _editor->TextChanged += gcnew EventHandler(this, &MainForm::OnTextChanged);

            Controls->Add(_editor);
            Controls->Add(_tool);
            Controls->Add(_status);
            Controls->Add(menu);
            MainMenuStrip = menu;
        }

    private:
        void Say(String^ msg) { _hint->Text = L"  " + msg; }

        ToolStripMenuItem^ Item(String^ text, Keys shortcut, String^ tip)
        {
            auto mi = gcnew ToolStripMenuItem(text);
            if (shortcut != Keys::None)
            {
                mi->ShortcutKeys = shortcut;
                mi->ShowShortcutKeys = true;
            }
            mi->Tag = tip;                             // 处理器按 Tag 分发（成员函数没有闭包，这是惯用替代）
            mi->Click += gcnew EventHandler(this, &MainForm::OnMenuClick);
            return mi;
        }

        static ToolStripMenuItem^ Drop(String^ text, array<ToolStripItem^>^ children)
        {
            auto m = gcnew ToolStripMenuItem(text);
            m->DropDownItems->AddRange(children);
            return m;
        }

        ToolStripButton^ ToolBtn(String^ text, String^ tip, ToolStripMenuItem^ mirror)
        {
            auto b = gcnew ToolStripButton(text);
            b->ToolTipText = tip;
            b->Tag = mirror;        // 镜像菜单项存 Tag；PerformClick 签名 (void) 挂不上
                                    // EventHandler(Object^,EventArgs^)，经 OnToolClick 中转
            b->Click += gcnew EventHandler(this, &MainForm::OnToolClick);
            return b;
        }

        void OnToolClick(Object^ sender, EventArgs^ e)
        {
            auto b = safe_cast<ToolStripButton^>(sender);
            safe_cast<ToolStripMenuItem^>(b->Tag)->PerformClick();
        }

        void OnMenuClick(Object^ sender, EventArgs^ e)
        {
            auto mi = safe_cast<ToolStripMenuItem^>(sender);
            String^ tip = safe_cast<String^>(mi->Tag);
            String^ text = mi->Text;

            if (text == L"新建(&N)") { _editor->Clear(); Say(L"新建文档"); }
            else if (text == L"保存(&S)") { Say(L"保存到哪？—— 09 章的 SaveFileDialog 负责"); }
            else if (text == L"退出(&Q)") { Close(); }
            else if (text == L"全选(&A)") { _editor->SelectAll(); }
            else if (text == L"复制(&C)") { _editor->Copy(); }
            else if (text == L"清空") { _editor->Clear(); }
            else if (text == L"剪切") { _editor->Cut(); }
            else if (text == L"粘贴") { _editor->Paste(); }
            else if (text == L"关于(&A)") { MessageBox::Show(this, L"迷你编辑器 1.0\n三语言示例 · 08 章", L"关于"); }
        }

        void OnToggleTool(Object^ s, EventArgs^ e)
        {
            auto mi = safe_cast<ToolStripMenuItem^>(s);
            _tool->Visible = mi->Checked;
        }

        void OnToggleStatus(Object^ s, EventArgs^ e)
        {
            auto mi = safe_cast<ToolStripMenuItem^>(s);
            _status->Visible = mi->Checked;
        }

        void OnTextChanged(Object^ s, EventArgs^ e)
        {
            _count->Text = String::Format(L"{0} 字", _editor->Text->Length);
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
