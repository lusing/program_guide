// 13 GDI+ 应用（C++/CLI 版）
using namespace System;
using namespace System::Drawing;
using namespace System::Drawing::Drawing2D;
using namespace System::Windows::Forms;

namespace ChartCpp {

    // ═══ 13.1 柱形图 ═══
    public ref class BarChart : public Control
    {
    private:
        array<String^>^ _labels;
        array<int>^ _values;

    public:
        BarChart()
        {
            _labels = gcnew array<String^> { L"1月", L"2月", L"3月", L"4月", L"5月", L"6月" };
            _values = gcnew array<int> { 42, 68, 55, 90, 73, 61 };
            Dock = DockStyle::Fill;
            BackColor = Color::White;
            SetStyle(static_cast<ControlStyles>(
                ControlStyles::AllPaintingInWmPaint | ControlStyles::UserPaint |
                ControlStyles::OptimizedDoubleBuffer | ControlStyles::ResizeRedraw), true);
        }

        void Randomize(Random^ rng)
        {
            for (int i = 0; i < _values->Length; i++)
                _values[i] = rng->Next(20, 100);
            Invalidate();
        }

    protected:
        virtual void OnPaint(PaintEventArgs^ e) override
        {
            __super::OnPaint(e);
            Graphics^ g = e->Graphics;
            g->SmoothingMode = SmoothingMode::AntiAlias;

            Rectangle plot(40, 16, Width - 60, Height - 50);
            float max = 100.0f;
            float slot = (float)plot.Width / _values->Length;
            float barW = slot * 0.6f;

            Pen axis(Color::Gray, 1.0f);
            g->DrawLine(%axis, (float)plot.Left, (float)plot.Top, (float)plot.Left, (float)plot.Bottom);
            g->DrawLine(%axis, (float)plot.Left, (float)plot.Bottom, (float)plot.Right, (float)plot.Bottom);
            for (int tick = 0; tick <= 4; tick++)
            {
                float y = (float)plot.Bottom - (float)plot.Height * tick / 4.0f;
                g->DrawString((tick * 25).ToString(), Font, Brushes::Gray, 2.0f, y - Font->Height / 2.0f);
                g->DrawLine(%axis, (float)plot.Left - 4.0f, y, (float)plot.Left, y);
            }

            LinearGradientBrush brush(plot, Color::CornflowerBlue, Color::RoyalBlue, LinearGradientMode::Vertical);
            for (int i = 0; i < _values->Length; i++)
            {
                float h = (float)plot.Height * _values[i] / max;
                RectangleF bar((float)plot.Left + i * slot + (slot - barW) / 2.0f,
                               (float)plot.Bottom - h, barW, h);
                g->FillRectangle(%brush, bar);
                g->DrawString(_values[i].ToString(), Font, Brushes::Black, bar.X, bar.Y - Font->Height);
                g->DrawString(_labels[i], Font, Brushes::DimGray,
                              (float)plot.Left + i * slot + slot / 2.0f - 12.0f, (float)plot.Bottom + 4.0f);
            }
        }
    };

    public ref class MainForm : public Form
    {
    private:
        BarChart^ _chart;
        PictureBox^ _captcha;
        TextBox^ _answer;
        Random^ _rng;
        String^ _code;
        Label^ _spin;
        int _angle;
        System::Windows::Forms::Timer^ _timer;

    public:
        MainForm()
        {
            Text = L"GDI+ 应用（C++/CLI）";
            ClientSize = System::Drawing::Size(720, 560);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);
            _rng = gcnew Random(2026);
            _code = L"";
            _angle = 0;

            // 柱形图区
            _chart = gcnew BarChart();
            auto chartBox = gcnew GroupBox();
            chartBox->Text = L" 柱形图（每次随机数据）"; chartBox->Dock = DockStyle::Top; chartBox->Height = 240;
            auto rand = gcnew Button();
            rand->Text = L"换一组数据"; rand->Dock = DockStyle::Bottom;
            rand->Click += gcnew EventHandler(this, &MainForm::OnRandomize);
            chartBox->Controls->Add(_chart);
            chartBox->Controls->Add(rand);

            // 验证码区
            _captcha = gcnew PictureBox();
            _captcha->Size = System::Drawing::Size(160, 48);
            _captcha->Location = System::Drawing::Point(16, 40);
            _captcha->BorderStyle = BorderStyle::FixedSingle;
            _captcha->Click += gcnew EventHandler(this, &MainForm::OnNewCaptcha);

            auto capBox = gcnew GroupBox();
            capBox->Text = L" 图片验证码 "; capBox->Dock = DockStyle::Top; capBox->Height = 130;
            auto refresh = gcnew Button();
            refresh->Text = L"看不清？换一张"; refresh->AutoSize = true;
            refresh->Location = System::Drawing::Point(190, 50);
            refresh->Click += gcnew EventHandler(this, &MainForm::OnNewCaptcha);

            _answer = gcnew TextBox();
            _answer->Font = gcnew Drawing::Font(L"Consolas", 14.0f);
            _answer->SetBounds(330, 44, 140, 30);

            auto check = gcnew Button();
            check->Text = L"验证"; check->AutoSize = true;
            check->Location = System::Drawing::Point(490, 42);
            check->Click += gcnew EventHandler(this, &MainForm::OnCheck);

            auto capHint = gcnew Label();
            capHint->Text = L"点击图片也能换（不区分大小写）"; capHint->AutoSize = true;
            capHint->Location = System::Drawing::Point(16, 96);
            capBox->Controls->AddRange(gcnew array<Control^> { _captcha, refresh, _answer, check, capHint });

            // ═══ 13.3 旋转文字 ═══
            auto spinBox = gcnew GroupBox();
            spinBox->Text = L" 坐标变换：旋转的文字 "; spinBox->Dock = DockStyle::Top; spinBox->Height = 120;
            _spin = gcnew Label();
            _spin->Dock = DockStyle::Fill;
            _spin->TextAlign = ContentAlignment::MiddleCenter;
            _spin->Font = gcnew Drawing::Font(L"微软雅黑", 16.0f, FontStyle::Bold);
            _spin->Text = L"WinForms";
            _timer = gcnew System::Windows::Forms::Timer();
            _timer->Interval = 50;
            _timer->Tick += gcnew EventHandler(this, &MainForm::OnTick);
            _timer->Start();
            spinBox->Controls->Add(_spin);

            Controls->Add(spinBox);
            Controls->Add(capBox);
            Controls->Add(chartBox);

            NewCaptcha();
        }

    private:
        void OnRandomize(Object^ s, EventArgs^ e) { _chart->Randomize(_rng); }
        void OnNewCaptcha(Object^ s, EventArgs^ e) { NewCaptcha(); }

        void OnCheck(Object^ s, EventArgs^ e)
        {
            bool ok = String::Equals(_answer->Text->Trim(), _code, StringComparison::OrdinalIgnoreCase);
            MessageBox::Show(this, ok ? L"通过！" : String::Format(L"不对，答案是「{0}」", _code), L"验证结果");
            if (ok) NewCaptcha();
        }

        void OnTick(Object^ s, EventArgs^ e)
        {
            _angle = (_angle + 5) % 360;
            auto bmp = gcnew Bitmap(_spin->Width, _spin->Height);
            Graphics^ g = Graphics::FromImage(bmp);   // 位图上的画布（用完 delete）
            g->SmoothingMode = SmoothingMode::AntiAlias;
            g->TranslateTransform((float)bmp->Width / 2.0f, (float)bmp->Height / 2.0f);
            g->RotateTransform((float)_angle);
            auto size = g->MeasureString(_spin->Text, _spin->Font);
            g->DrawString(_spin->Text, _spin->Font, Brushes::RoyalBlue,
                          -size.Width / 2.0f, -size.Height / 2.0f);
            delete g;
            delete _spin->BackgroundImage;           // 旧位图释放（null 时 delete 安全）
            _spin->BackgroundImage = bmp;
        }

        void NewCaptcha()
        {
            String^ pool = L"ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
            auto chars = gcnew array<wchar_t>(4);
            for (int i = 0; i < 4; i++)
                chars[i] = pool[_rng->Next(pool->Length)];
            _code = gcnew String(chars);
            _answer->Clear();

            auto bmp = gcnew Bitmap(160, 48);
            Graphics^ g = Graphics::FromImage(bmp);
            g->Clear(Color::AliceBlue);
            Drawing::Font font(L"Consolas", 20.0f, FontStyle::Bold);
            for (int i = 0; i < 4; i++)
            {
                g->TranslateTransform(20.0f + i * 34.0f, 24.0f);
                g->RotateTransform((float)_rng->Next(-25, 26));
                String^ one = _code->Substring(i, 1);
                auto size = g->MeasureString(one, %font);
                SolidBrush ink(Color::FromArgb(_rng->Next(80, 180), _rng->Next(80, 180), _rng->Next(80, 180)));
                g->DrawString(one, %font, %ink, -size.Width / 2.0f, -size.Height / 2.0f);
                g->ResetTransform();
            }
            for (int i = 0; i < 6; i++)
            {
                Pen p(Color::FromArgb(_rng->Next(120, 220), 0, 0), 1.5f);
                g->DrawLine(%p, (float)_rng->Next(160), (float)_rng->Next(48),
                                (float)_rng->Next(160), (float)_rng->Next(48));
            }
            delete g;
            delete _captcha->Image;
            _captcha->Image = bmp;
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
