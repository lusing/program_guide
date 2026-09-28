// 10 SDI 与 MDI（C++/CLI 版）
using namespace System;
using namespace System::Drawing;
using namespace System::Windows::Forms;

namespace MdiCpp {

    // ═══ 10.1 子窗体 ═══
    public ref class ChildForm : public Form
    {
    public:
        RichTextBox^ Editor;

        ChildForm(int index)
        {
            Text = String::Format(L"文档 {0}", index);
            Width = 420; Height = 300;
            Editor = gcnew RichTextBox();
            Editor->Dock = DockStyle::Fill;
            Editor->Text = String::Format(L"我是第 {0} 个子文档。\n", index);
            Controls->Add(Editor);
        }
    };

    // ═══ 10.2 父窗体 ═══
    public ref class MainForm : public Form
    {
    private:
        int _created;
        ToolStripStatusLabel^ _status;

    public:
        MainForm()
        {
            _created = 0;
            Text = L"MDI 多文档示例";
            IsMdiContainer = true;
            ClientSize = System::Drawing::Size(860, 560);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);

            auto menu = gcnew MenuStrip();

            auto miNew = gcnew ToolStripMenuItem(L"新建文档(&N)");
            miNew->ShortcutKeys = static_cast<Keys>(Keys::Control | Keys::N);
            miNew->Click += gcnew EventHandler(this, &MainForm::OnNewChild);
            auto miQuit = gcnew ToolStripMenuItem(L"退出(&Q)");
            miQuit->Click += gcnew EventHandler(this, &MainForm::OnQuit);
            auto fileMenu = gcnew ToolStripMenuItem(L"文件(&F)");
            fileMenu->DropDownItems->AddRange(gcnew array<ToolStripItem^>
            {
                miNew, gcnew ToolStripSeparator(), miQuit
            });

            // ═══ 10.3 窗口菜单 ═══
            auto winMenu = gcnew ToolStripMenuItem(L"窗口(&W)");
            auto miCascade = LayoutItem(L"层叠排列(&C)", MdiLayout::Cascade);
            auto miTileV = LayoutItem(L"垂直平铺(&V)", MdiLayout::TileVertical);
            auto miTileH = LayoutItem(L"水平平铺(&H)", MdiLayout::TileHorizontal);
            auto miArrange = LayoutItem(L"排列图标(&A)", MdiLayout::ArrangeIcons);
            winMenu->DropDownItems->AddRange(gcnew array<ToolStripItem^>
            {
                miCascade, miTileV, miTileH, miArrange, gcnew ToolStripSeparator()
            });
            // MdiWindowListItem 在 MenuStrip 上：指定项后面自动填子窗体清单
            menu->MdiWindowListItem = miCascade;

            menu->Items->AddRange(gcnew array<ToolStripItem^> { fileMenu, winMenu });

            _status = gcnew ToolStripStatusLabel();
            _status->Spring = true;
            _status->TextAlign = ContentAlignment::MiddleLeft;
            auto statusStrip = gcnew StatusStrip();
            statusStrip->Items->Add(_status);

            MdiChildActivate += gcnew EventHandler(this, &MainForm::OnChildActivate);

            Controls->Add(statusStrip);
            Controls->Add(menu);
            MainMenuStrip = menu;

            NewChild();
            NewChild();
        }

    private:
        ToolStripMenuItem^ LayoutItem(String^ text, MdiLayout layout)
        {
            auto mi = gcnew ToolStripMenuItem(text);
            mi->Tag = layout;                          // 枚举装箱进 Tag，处理器里拆出来
            mi->Click += gcnew EventHandler(this, &MainForm::OnLayoutClick);
            return mi;
        }

        void NewChild()
        {
            auto child = gcnew ChildForm(++_created);
            child->MdiParent = this;                   // ★ 认父
            child->StartPosition = FormStartPosition::Manual;
            child->Location = System::Drawing::Point(30 * (_created % 8), 30 * (_created % 8));
            child->Editor->TextChanged += gcnew EventHandler(this, &MainForm::OnChildText);
            child->Show();
            RefreshStatus();
        }

        void RefreshStatus()
        {
            auto active = dynamic_cast<ChildForm^>(ActiveMdiChild);
            String^ activeInfo = (active == nullptr)
                ? L"（无）"
                : String::Format(L"「{0}」{1} 字", active->Text, active->Editor->Text->Length);
            _status->Text = String::Format(L"  子窗体 {0} 个；活动文档：{1}", MdiChildren->Length, activeInfo);
        }

        void OnNewChild(Object^ s, EventArgs^ e) { NewChild(); }
        void OnQuit(Object^ s, EventArgs^ e) { Close(); }
        void OnChildActivate(Object^ s, EventArgs^ e) { RefreshStatus(); }
        void OnChildText(Object^ s, EventArgs^ e) { RefreshStatus(); }

        void OnLayoutClick(Object^ s, EventArgs^ e)
        {
            auto mi = safe_cast<ToolStripMenuItem^>(s);
            LayoutMdi(safe_cast<MdiLayout>(mi->Tag));
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
