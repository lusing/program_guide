// 11 事件与委托（C++/CLI 版）
// 本版的主角是 C++/CLI 独有的大坑：**解绑 -= 必须用当初 += 的同一个委托实例**。
// C# 里 `x -= this.OnFoo` 靠编译器合成的委托相等（方法组+目标都相同）；
// C++/CLI 里 `gcnew EventHandler(this, &T::OnFoo)` 每次都是新对象，
// 直接再 gcnew 一个去 -= 是减不掉的——必须把当初那个缓存下来。
using namespace System;
using namespace System::Drawing;
using namespace System::Windows::Forms;

namespace EventsCpp {

    // ═══ 11.1 事件参数 ═══
    public ref class TempEventArgs : public EventArgs
    {
    public:
        TempEventArgs(double temp, double delta) { Temp = temp; Delta = delta; }
        property double Temp;
        property double Delta;
    };

    // ═══ 11.2 事件源 ═══
    public ref class Thermometer
    {
    private:
        Random^ _rng;
        double _temp;

    public:
        Thermometer(int seed)
        {
            _rng = gcnew Random(seed);
            _temp = 20.0;
        }

        // 委托类型别名：C++/CLI 没有 generic EventHandler 的推断糖，写全
        event EventHandler<TempEventArgs^>^ Reading;

        void Poll()
        {
            double next = _temp + (_rng->NextDouble() - 0.5) * 2.0;
            double delta = next - _temp;
            _temp = next;
            Reading(this, gcnew TempEventArgs(next, delta));   // 直接调用即触发（编译器合成 raise_）
        }
    };

    public ref class MainForm : public Form
    {
    private:
        Thermometer^ _thermo;
        Label^ _display;
        ListBox^ _log;
        Button^ _toggle;
        EventHandler<TempEventArgs^>^ _handlerB;    // ★ 缓存订阅者 B 的委托实例，解绑全靠它
        bool _bSubscribed;
        int _received;

    public:
        MainForm()
        {
            Text = L"事件与委托（C++/CLI）";
            ClientSize = System::Drawing::Size(560, 420);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);

            _thermo = gcnew Thermometer(42);
            _bSubscribed = false;
            _received = 0;

            _display = gcnew Label();
            _display->Dock = DockStyle::Top; _display->Height = 60;
            _display->TextAlign = ContentAlignment::MiddleCenter;
            _display->Font = gcnew Drawing::Font(L"微软雅黑", 20.0f);
            _display->Text = L"20.0 °C";

            _toggle = gcnew Button();
            _toggle->Text = L"暂停记录（解绑订阅者 B）";
            _toggle->Dock = DockStyle::Top; _toggle->Height = 36;
            _toggle->Click += gcnew EventHandler(this, &MainForm::OnToggle);

            _log = gcnew ListBox();
            _log->Dock = DockStyle::Fill;

            // ═══ 11.3 订阅：A 直接挂成员函数；B 的委托实例单独缓存 ═══
            _thermo->Reading += gcnew EventHandler<TempEventArgs^>(this, &MainForm::OnReadingA);
            _handlerB = gcnew EventHandler<TempEventArgs^>(this, &MainForm::OnReadingB);
            _thermo->Reading += _handlerB;
            _bSubscribed = true;

            auto timer = gcnew System::Windows::Forms::Timer();
            timer->Interval = 500;
            timer->Tick += gcnew EventHandler(this, &MainForm::OnTick);
            timer->Start();

            Controls->Add(_log);
            Controls->Add(_toggle);
            Controls->Add(_display);
        }

    private:
        void OnTick(Object^ s, EventArgs^ e) { _thermo->Poll(); }

        void OnReadingA(Object^ sender, TempEventArgs^ e)
        {
            _display->Text = String::Format(L"{0:F1} °C", e->Temp);
        }

        void OnReadingB(Object^ sender, TempEventArgs^ e)
        {
            _received++;
            String^ arrow = (e->Delta >= 0)
                ? String::Format(L"+{0:F2}", e->Delta)
                : String::Format(L"{0:F2}", e->Delta);
            bool senderOk = ReferenceEquals(sender, _thermo);
            _log->Items->Insert(0, String::Format(L"#{0:D3}  {1:F2}°C（变化 {2}）{3}",
                _received, e->Temp, arrow, senderOk ? L"  sender 验证通过" : L""));
        }

        void OnToggle(Object^ s, EventArgs^ e)
        {
            if (_bSubscribed)
            {
                _thermo->Reading -= _handlerB;      // ★ 用缓存的那个实例解绑
                _toggle->Text = L"恢复记录（重绑订阅者 B）";
                _log->Items->Insert(0, L"── 订阅者 B 已解绑：只剩大数字在动 ──");
            }
            else
            {
                _thermo->Reading += _handlerB;      // 重绑同一个实例也没问题
                _toggle->Text = L"暂停记录（解绑订阅者 B）";
                _log->Items->Insert(0, L"── 订阅者 B 已接回 ──");
            }
            _bSubscribed = !_bSubscribed;
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
