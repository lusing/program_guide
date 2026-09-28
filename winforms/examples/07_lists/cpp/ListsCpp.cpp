// 07 容器与列表控件（C++/CLI 版）
// 数据建模：没有元组的语法糖，用一个小 ref struct 当记录
using namespace System;
using namespace System::Collections::Generic;
using namespace System::Drawing;
using namespace System::Windows::Forms;

namespace ListsCpp {

    // 值三元组：品名 / 单价 / 产地。给个构造函数收 double，省得每处手写 Decimal 转换
    public value struct Item
    {
        String^ Name;
        Decimal Price;
        String^ From;

        Item(String^ n, double price, String^ f)
        {
            Name = n;
            Price = (Decimal)price;
            From = f;
        }
    };

    public ref class MainForm : public Form
    {
    private:
        Dictionary<String^, List<Item>^>^ _catalog;
        TreeView^ _tree;
        ListView^ _list;
        Label^ _status;

    public:
        MainForm()
        {
            Text = L"容器与列表控件";
            ClientSize = System::Drawing::Size(760, 480);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);

            BuildCatalog();

            _status = gcnew Label();
            _status->Dock = DockStyle::Bottom; _status->Height = 30;
            _status->TextAlign = ContentAlignment::MiddleLeft;
            _status->BackColor = Color::Gainsboro;

            // ═══ 7.1 SplitContainer ═══
            auto split = gcnew SplitContainer();
            split->Dock = DockStyle::Fill;
            split->SplitterDistance = 220;

            // ═══ 7.2 TreeView ═══
            _tree = gcnew TreeView();
            _tree->Dock = DockStyle::Fill;
            _tree->HideSelection = false;
            for each (KeyValuePair<String^, List<Item>^> kv in _catalog)
            {
                auto node = _tree->Nodes->Add(kv.Key);
                node->Tag = kv.Key;
                for each (Item it in kv.Value)
                {
                    auto child = node->Nodes->Add(it.Name);
                    child->Tag = it.Name;         // 记录所属类别用另一个口袋：省事起见只存名字
                    child->Name = kv.Key;
                }
            }
            _tree->ExpandAll();
            _tree->AfterSelect += gcnew TreeViewEventHandler(this, &MainForm::OnTreeSelect);

            // ═══ 7.3 TabControl 三页 ═══
            auto tabs = gcnew TabControl();
            tabs->Dock = DockStyle::Fill;

            auto page1 = gcnew TabPage(L"明细表（Details）");
            _list = gcnew ListView();
            _list->Dock = DockStyle::Fill;
            _list->View = View::Details;
            _list->FullRowSelect = true;
            _list->GridLines = true;
            _list->Columns->Add(L"品名", 140);
            _list->Columns->Add(L"单价(元)", 90, HorizontalAlignment::Right);
            _list->Columns->Add(L"产地", 120);
            _list->SelectedIndexChanged += gcnew EventHandler(this, &MainForm::OnListSelect);
            page1->Controls->Add(_list);

            auto page2 = gcnew TabPage(L"图标视图（LargeIcon）");
            auto icons = gcnew ImageList();
            icons->ImageSize = System::Drawing::Size(32, 32);
            icons->Images->Add(L"shield", SystemIcons::Shield);
            icons->Images->Add(L"warn", SystemIcons::Warning);
            icons->Images->Add(L"info", SystemIcons::Information);
            auto iconList = gcnew ListView();
            iconList->Dock = DockStyle::Fill;
            iconList->View = View::LargeIcon;
            iconList->LargeImageList = icons;
            iconList->Items->Add(L"盾牌", L"shield");
            iconList->Items->Add(L"警告", L"warn");
            iconList->Items->Add(L"信息", L"info");
            page2->Controls->Add(iconList);

            auto page3 = gcnew TabPage(L"滚动面板（AutoScroll）");
            auto panel = gcnew Panel();
            panel->Dock = DockStyle::Fill;
            panel->AutoScroll = true;
            for (int i = 1; i <= 12; i++)
            {
                int col = (i - 1) % 3, row = (i - 1) / 3;
                auto b = gcnew Button();
                b->Text = String::Format(L"按钮 {0:00}", i);
                b->Location = System::Drawing::Point(16 + col * 130, 16 + row * 48);
                b->Size = System::Drawing::Size(120, 38);
                b->Tag = i;                       // C++ 的 for 循环变量同样被所有闭包共享：用 Tag 随身带
                b->Click += gcnew EventHandler(this, &MainForm::OnPanelButton);
                panel->Controls->Add(b);
            }
            page3->Controls->Add(panel);

            tabs->TabPages->AddRange(gcnew array<TabPage^> { page1, page2, page3 });

            split->Panel1->Controls->Add(_tree);
            split->Panel2->Controls->Add(tabs);

            Controls->Add(split);
            Controls->Add(_status);

            _tree->SelectedNode = _tree->Nodes[0];
        }

    private:
        void BuildCatalog()
        {
            _catalog = gcnew Dictionary<String^, List<Item>^>();
            auto fruits = gcnew List<Item>();
            fruits->Add(Item(L"苹果", 8.5, L"山东"));
            fruits->Add(Item(L"香蕉", 3.2, L"海南"));
            fruits->Add(Item(L"樱桃", 39.9, L"大连"));
            _catalog[L"水果"] = fruits;
            auto greens = gcnew List<Item>();
            greens->Add(Item(L"番茄", 4.0, L"寿光"));
            greens->Add(Item(L"黄瓜", 2.8, L"廊坊"));
            greens->Add(Item(L"土豆", 1.9, L"内蒙古"));
            _catalog[L"蔬菜"] = greens;
            auto grains = gcnew List<Item>();
            grains->Add(Item(L"大米", 5.6, L"五常"));
            grains->Add(Item(L"面粉", 4.3, L"河北"));
            grains->Add(Item(L"玉米油", 12.8, L"东北"));
            _catalog[L"粮油"] = grains;
        }

        void OnTreeSelect(Object^ s, TreeViewEventArgs^ e)
        {
            _status->Text = String::Format(L"  选中「{0}」（Level={1}，FullPath={2}）",
                                           e->Node->Text, e->Node->Level, e->Node->FullPath);
            RefreshList(e->Node);
        }

        void RefreshList(TreeNode^ node)
        {
            _list->Items->Clear();
            String^ cat = safe_cast<String^>(node->Tag);
            for each (Item it in _catalog[cat])
            {
                auto row = gcnew ListViewItem(it.Name);
                row->SubItems->Add(it.Price.ToString(L"F1"));
                row->SubItems->Add(it.From);
                _list->Items->Add(row);
            }
        }

        void OnListSelect(Object^ s, EventArgs^ e)
        {
            if (_list->SelectedItems->Count > 0)
                _status->Text = String::Format(L"  列表选中「{0}」", _list->SelectedItems[0]->Text);
        }

        void OnPanelButton(Object^ s, EventArgs^ e)
        {
            _status->Text = String::Format(L"  滚动面板：点了按钮 {0:00}", safe_cast<int>(safe_cast<Button^>(s)->Tag));
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
