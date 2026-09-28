// 15 DataGridView（C++/CLI 版）
using namespace System;
using namespace System::ComponentModel;
using namespace System::Drawing;
using namespace System::Windows::Forms;

namespace GridCpp {

    public ref class Order
    {
    public:
        property int Id;
        property String^ Customer;
        property String^ Product;
        property int Qty;
        property Decimal Price;
        property bool Paid;
        property Decimal Total
        {
            Decimal get() { return (Decimal)Qty * Price; }
        }

        Order() { Customer = L""; Product = L""; Qty = 0; Price = Decimal::Zero; Paid = false; }
    };

    public ref class MainForm : public Form
    {
    private:
        BindingList<Order^>^ _orders;
        BindingSource^ _source;
        DataGridView^ _grid;
        ComboBox^ _customer;
        CheckBox^ _all;
        Label^ _sum;

    public:
        MainForm()
        {
            Text = L"DataGridView 深入（C++/CLI）";
            ClientSize = System::Drawing::Size(760, 520);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);

            _orders = gcnew BindingList<Order^>();
            _orders->Add(Mk(1, L"林一", L"键盘", 2, (Decimal)299, true));
            _orders->Add(Mk(2, L"林一", L"显示器", 1, (Decimal)1899, false));
            _orders->Add(Mk(3, L"陈二", L"鼠标", 5, (Decimal)89, false));
            _orders->Add(Mk(4, L"陈二", L"内存条", 2, (Decimal)459, true));
            _orders->Add(Mk(5, L"张三", L"U盘", 10, (Decimal)39, true));

            _source = gcnew BindingSource();

            _sum = gcnew Label();
            _sum->Dock = DockStyle::Bottom; _sum->Height = 30;
            _sum->BackColor = Color::Gainsboro;
            _sum->TextAlign = ContentAlignment::MiddleLeft;

            // ═══ 主从联动 ═══
            auto filterBox = gcnew GroupBox();
            filterBox->Text = L" 主从联动 "; filterBox->Dock = DockStyle::Top; filterBox->Height = 74;

            auto fl = gcnew Label(); fl->Text = L"客户："; fl->AutoSize = true;
            fl->Location = System::Drawing::Point(14, 32);
            _customer = gcnew ComboBox();
            _customer->DropDownStyle = ComboBoxStyle::DropDownList;
            _customer->SetBounds(70, 28, 140, 30);
            _customer->Items->Add(L"林一"); _customer->Items->Add(L"陈二"); _customer->Items->Add(L"张三");
            _customer->SelectedIndex = 0;
            _customer->SelectedIndexChanged += gcnew EventHandler(this, &MainForm::OnFilterChanged);

            _all = gcnew CheckBox();
            _all->Text = L"看全部"; _all->AutoSize = true;
            _all->Location = System::Drawing::Point(230, 30);
            _all->CheckedChanged += gcnew EventHandler(this, &MainForm::OnFilterChanged);

            filterBox->Controls->AddRange(gcnew array<Control^> { fl, _customer, _all });

            // ═══ 手工列 ═══
            _grid = gcnew DataGridView();
            _grid->Dock = DockStyle::Fill;
            _grid->AutoGenerateColumns = false;
            _grid->DataSource = _source;
            _grid->AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode::Fill;
            _grid->SelectionMode = DataGridViewSelectionMode::FullRowSelect;
            _grid->AllowUserToAddRows = false;

            auto idCol = gcnew DataGridViewTextBoxColumn();
            idCol->HeaderText = L"单号"; idCol->DataPropertyName = L"Id"; idCol->FillWeight = 10; idCol->ReadOnly = true;
            _grid->Columns->Add(idCol);

            auto custCol = gcnew DataGridViewTextBoxColumn();
            custCol->HeaderText = L"客户"; custCol->DataPropertyName = L"Customer"; custCol->FillWeight = 16;
            _grid->Columns->Add(custCol);

            auto productCol = gcnew DataGridViewComboBoxColumn();
            productCol->HeaderText = L"商品"; productCol->DataPropertyName = L"Product"; productCol->FillWeight = 18;
            auto products = gcnew System::Collections::Generic::List<String^>();
            products->Add(L"键盘"); products->Add(L"鼠标"); products->Add(L"显示器");
            products->Add(L"内存条"); products->Add(L"U盘");
            productCol->DataSource = products;
            _grid->Columns->Add(productCol);

            auto qtyCol = gcnew DataGridViewTextBoxColumn();
            qtyCol->HeaderText = L"数量"; qtyCol->DataPropertyName = L"Qty"; qtyCol->FillWeight = 12;
            _grid->Columns->Add(qtyCol);

            auto priceCol = gcnew DataGridViewTextBoxColumn();
            priceCol->HeaderText = L"单价"; priceCol->DataPropertyName = L"Price"; priceCol->FillWeight = 14;
            priceCol->DefaultCellStyle->Format = L"C";
            _grid->Columns->Add(priceCol);

            auto paidCol = gcnew DataGridViewCheckBoxColumn();
            paidCol->HeaderText = L"已付"; paidCol->DataPropertyName = L"Paid"; paidCol->FillWeight = 10;
            _grid->Columns->Add(paidCol);

            auto totalCol = gcnew DataGridViewTextBoxColumn();
            totalCol->HeaderText = L"合计"; totalCol->DataPropertyName = L"Total"; totalCol->FillWeight = 14;
            totalCol->ReadOnly = true;
            totalCol->DefaultCellStyle->Format = L"C";
            totalCol->DefaultCellStyle->ForeColor = Color::DarkSlateBlue;
            _grid->Columns->Add(totalCol);

            auto delCol = gcnew DataGridViewButtonColumn();
            delCol->HeaderText = L"操作"; delCol->Text = L"删除";
            delCol->UseColumnTextForButtonValue = true; delCol->FillWeight = 10;
            _grid->Columns->Add(delCol);

            // ═══ 校验 ═══
            _grid->CellValidating += gcnew DataGridViewCellValidatingEventHandler(this, &MainForm::OnValidating);
            _grid->CellEndEdit += gcnew DataGridViewCellEventHandler(this, &MainForm::OnEndEdit);

            // ═══ 条件着色 ═══
            _grid->CellFormatting += gcnew DataGridViewCellFormattingEventHandler(this, &MainForm::OnFormatting);

            // ═══ 按钮列 ═══
            _grid->CellContentClick += gcnew DataGridViewCellEventHandler(this, &MainForm::OnCellClick);

            Controls->Add(_grid);
            Controls->Add(_sum);
            Controls->Add(filterBox);

            ApplyFilter();
        }

    private:
        static Order^ Mk(int id, String^ c, String^ p, int qty, Decimal price, bool paid)
        {
            auto o = gcnew Order();
            o->Id = id; o->Customer = c; o->Product = p; o->Qty = qty; o->Price = price; o->Paid = paid;
            return o;
        }

        void OnFilterChanged(Object^ s, EventArgs^ e) { ApplyFilter(); }

        void ApplyFilter()
        {
            auto view = gcnew BindingList<Order^>();
            if (_all->Checked)
                for each (Order^ o in _orders) view->Add(o);
            else
                for each (Order^ o in _orders)
                    if (o->Customer == safe_cast<String^>(_customer->SelectedItem)) view->Add(o);
            _source->DataSource = view;
            RefreshSum();
        }

        void RefreshSum()
        {
            auto view = safe_cast<BindingList<Order^>^>(_source->DataSource);   // 泛型引用类型别忘 ^
            Decimal total = Decimal::Zero;
            for each (Order^ o in view) total += o->Total;
            _sum->Text = String::Format(L"  当前列出 {0} 单，合计 {1:C}（改个数量试试，合计实时变）",
                                        view->Count, total);
        }

        void OnValidating(Object^ s, DataGridViewCellValidatingEventArgs^ e)
        {
            if (_grid->Columns[e->ColumnIndex]->DataPropertyName != L"Qty") return;
            int qty;
            bool ok = Int32::TryParse(safe_cast<String^>(e->FormattedValue), qty);
            if (!ok || qty < 1 || qty > 99)
            {
                e->Cancel = true;
                _grid->Rows[e->RowIndex]->ErrorText = L"数量必须是 1~99 的整数";
            }
        }

        void OnEndEdit(Object^ s, DataGridViewCellEventArgs^ e)
        {
            _grid->Rows[e->RowIndex]->ErrorText = nullptr;
        }

        void OnFormatting(Object^ s, DataGridViewCellFormattingEventArgs^ e)
        {
            if (e->RowIndex < 0) return;
            auto row = dynamic_cast<Order^>(_grid->Rows[e->RowIndex]->DataBoundItem);
            if (row == nullptr) return;
            e->CellStyle->BackColor = (row->Total >= (Decimal)1000) ? Color::MistyRose : Color::White;
        }

        void OnCellClick(Object^ s, DataGridViewCellEventArgs^ e)
        {
            if (dynamic_cast<DataGridViewButtonColumn^>(_grid->Columns[e->ColumnIndex]) == nullptr) return;
            auto doomed = dynamic_cast<Order^>(_grid->Rows[e->RowIndex]->DataBoundItem);
            if (doomed != nullptr)
            {
                _orders->Remove(doomed);
                ApplyFilter();
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
