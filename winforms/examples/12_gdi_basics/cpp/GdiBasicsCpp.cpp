// 12 GDI+ 基础（C++/CLI 版）
// 语法增量：虚函数重写 override this->OnPaint(e)；托管资源用栈语义 "Pen pen(...)" 自动 Dispose
using namespace System;
using namespace System::Drawing;
using namespace System::Drawing::Drawing2D;
using namespace System::Windows::Forms;

namespace GdiBasicsCpp {

    // ═══ 画布 ═══
    public ref class Canvas : public Panel
    {
    private:
        System::Collections::Generic::List<Point>^ _stroke;
        bool _smooth;

    public:
        Canvas()
        {
            _stroke = gcnew System::Collections::Generic::List<Point>();
            _smooth = true;
            Dock = DockStyle::Fill;
            BackColor = Color::White;
            // 位或合并枚举标志
            SetStyle(static_cast<ControlStyles>(
                ControlStyles::AllPaintingInWmPaint | ControlStyles::UserPaint |
                ControlStyles::OptimizedDoubleBuffer | ControlStyles::ResizeRedraw), true);
        }

        void ClearStroke() { _stroke->Clear(); Invalidate(); }

        bool ToggleSmooth()
        {
            _smooth = !_smooth;
            Invalidate();
            return _smooth;
        }

    protected:
        virtual void OnPaint(PaintEventArgs^ e) override
        {
            __super::OnPaint(e);                    // 等价 C# 的 base.OnPaint(e)
            Graphics^ g = e->Graphics;
            if (_smooth)
            {
                g->SmoothingMode = SmoothingMode::AntiAlias;
                g->TextRenderingHint = System::Drawing::Text::TextRenderingHint::ClearTypeGridFit;
            }

            // —— Pen 家族：栈语义（结尾自动 Dispose，等价 C# 的 using）——
            Pen pen(Color::SteelBlue, 3.0f);
            g->DrawLine(%pen, 20, 20, 180, 60);

            Pen dash(Color::OrangeRed, 2.0f);
            dash.DashStyle = DashStyle::Dash;
            g->DrawRectangle(%dash, 20, 80, 160, 70);

            Pen thick(Color::FromArgb(120, 30, 144), 6.0f);
            thick.StartCap = LineCap::Round;
            thick.EndCap = LineCap::ArrowAnchor;
            g->DrawLine(%thick, 220, 100, 380, 100);

            // —— Brush 家族 ——
            SolidBrush solid(Color::FromArgb(140, Color::MediumSeaGreen));
            g->FillEllipse(%solid, 220, 20, 140, 70);

            HatchBrush hatch(HatchStyle::DiagonalCross, Color::Gray, Color::WhiteSmoke);
            g->FillRectangle(%hatch, 20, 170, 160, 70);

            Rectangle rect(220, 140, 160, 80);
            LinearGradientBrush grad(rect, Color::RoyalBlue, Color::White, LinearGradientMode::Vertical);
            g->FillEllipse(%grad, rect);
            g->DrawEllipse(%pen, rect);

            // —— 曲线与多边形 ——
            g->DrawBezier(%pen, 420, 180, 470, 20, 500, 220, 560, 120);
            array<Point>^ poly = { Point(420, 30), Point(500, 55), Point(470, 110), Point(430, 95) };
            g->DrawPolygon(%pen, poly);

            // —— 文本： Brushes::DimGray 是共享缓存，不 Dispose ——
            g->DrawString(L"这段字是 DrawString 画的", Font, Brushes::DimGray, 20.0f, 250.0f);

            // —— 鼠标笔迹 ——
            if (_stroke->Count > 1)
            {
                Pen ink(Color::Black, 2.0f);
                g->DrawLines(%ink, _stroke->ToArray());
            }
        }

        virtual void OnMouseDown(MouseEventArgs^ e) override
        {
            __super::OnMouseDown(e);
            _stroke->Clear();
            _stroke->Add(e->Location);
            Invalidate();
        }

        virtual void OnMouseMove(MouseEventArgs^ e) override
        {
            __super::OnMouseMove(e);
            // MouseButtons 同样被 Control 的同名属性遮蔽：全限定
            if (e->Button == System::Windows::Forms::MouseButtons::Left && _stroke->Count > 0)
            {
                _stroke->Add(e->Location);
                Invalidate();
            }
        }
    };

    public ref class MainForm : public Form
    {
    public:
        MainForm()
        {
            Text = L"GDI+ 绘图基础（C++/CLI）";
            ClientSize = System::Drawing::Size(760, 480);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);

            auto canvas = gcnew Canvas();

            auto bar = gcnew FlowLayoutPanel();
            bar->Dock = DockStyle::Top; bar->Height = 44;

            auto clear = gcnew Button();
            clear->Text = L"清空笔迹"; clear->AutoSize = true;
            clear->Click += gcnew EventHandler(this, &MainForm::OnClear);

            auto smooth = gcnew Button();
            smooth->Text = L"抗锯齿：开"; smooth->AutoSize = true;
            smooth->Click += gcnew EventHandler(this, &MainForm::OnToggleSmooth);
            smooth->Tag = canvas;

            auto hint = gcnew Label();
            hint->Text = L"｜在空白处按住左键拖动 = 手写笔迹（拖大窗口试试）";
            hint->AutoSize = true;
            hint->Padding = System::Windows::Forms::Padding(6, 10, 0, 0);

            bar->Controls->AddRange(gcnew array<Control^> { clear, smooth, hint });

            Controls->Add(canvas);
            Controls->Add(bar);
            _canvas = canvas;
        }

    private:
        Canvas^ _canvas;

        void OnToggleSmooth(Object^ s, EventArgs^ e)
        {
            bool on = _canvas->ToggleSmooth();
            safe_cast<Button^>(s)->Text = on ? L"抗锯齿：开" : L"抗锯齿：关";
        }

        void OnClear(Object^ s, EventArgs^ e) { _canvas->ClearStroke(); }
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
