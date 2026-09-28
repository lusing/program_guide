// 16 UI 线程模型（C++/CLI 版）
// C++/CLI 没有 async/await，后台工作用 BackgroundWorker 最顺：
// DoWork 在线程池、ProgressChanged/RunWorkerCompleted 自动弹回 UI 线程——正好是给事件驱动语言准备的工具
using namespace System;
using namespace System::ComponentModel;
using namespace System::Drawing;
using namespace System::Threading;
using namespace System::Windows::Forms;

namespace ThreadingCpp {

    public ref class MainForm : public Form
    {
    private:
        ProgressBar^ _bar;
        Label^ _state;
        Label^ _formsTimer;
        Label^ _threadTimer;
        Label^ _elapsed;
        Button^ _start;
        Button^ _stop;
        BackgroundWorker^ _worker;
        System::Windows::Forms::Timer^ _uiTimer;
        System::Threading::Timer^ _poolTimer;      // 两个 Timer 同名：字段声明也要限定
        int _uiTicks;
        int _poolTicks;
        Diagnostics::Stopwatch^ _watch;

    public:
        MainForm()
        {
            Text = L"UI 线程与后台任务（C++/CLI）";
            ClientSize = System::Drawing::Size(680, 440);
            StartPosition = FormStartPosition::CenterScreen;
            Font = gcnew Drawing::Font(L"微软雅黑", 10.0f);
            _uiTicks = 0;
            _poolTicks = 0;
            _watch = Diagnostics::Stopwatch::StartNew();

            // ═══ 16.1 卡死演示 ═══
            auto freeze = gcnew GroupBox();
            freeze->Text = L" 反面教材：在 UI 线程上睡 2 秒 "; freeze->Dock = DockStyle::Top; freeze->Height = 76;
            auto sleep = gcnew Button();
            sleep->Text = L"睡 2 秒（点我然后拖动窗口）"; sleep->Dock = DockStyle::Fill;
            sleep->Click += gcnew EventHandler(this, &MainForm::OnFreeze);
            freeze->Controls->Add(sleep);

            // ═══ 16.2 后台计算 ═══
            auto work = gcnew GroupBox();
            work->Text = L" 后台数素数（0..2,000,000）——BackgroundWorker"; work->Dock = DockStyle::Top; work->Height = 130;

            _bar = gcnew ProgressBar();
            _bar->Dock = DockStyle::Top; _bar->Height = 26;
            _state = gcnew Label();
            _state->Dock = DockStyle::Top; _state->Height = 30;
            _state->Text = L"  ";

            auto row = gcnew FlowLayoutPanel();
            row->Dock = DockStyle::Top; row->Height = 46;
            _start = gcnew Button(); _start->Text = L"开始（BackgroundWorker）"; _start->AutoSize = true;
            _stop = gcnew Button(); _stop->Text = L"取消"; _stop->AutoSize = true; _stop->Enabled = false;
            _start->Click += gcnew EventHandler(this, &MainForm::OnStart);
            _stop->Click += gcnew EventHandler(this, &MainForm::OnStop);
            row->Controls->AddRange(gcnew array<Control^> { _start, _stop });

            auto result = gcnew Label();
            result->Text = L"答案应是 148933（2×10⁶ 内素数个数，已知值当断言）";
            result->AutoSize = true; result->Dock = DockStyle::Top; result->ForeColor = Color::DimGray;

            work->Controls->Add(row);
            work->Controls->Add(result);
            work->Controls->Add(_state);
            work->Controls->Add(_bar);

            // BackgroundWorker：WorkerReportsProgress/WorkerSupportsCancellation 先开
            _worker = gcnew BackgroundWorker();
            _worker->WorkerReportsProgress = true;
            _worker->WorkerSupportsCancellation = true;
            _worker->DoWork += gcnew DoWorkEventHandler(this, &MainForm::OnDoWork);
            _worker->ProgressChanged += gcnew ProgressChangedEventHandler(this, &MainForm::OnProgress);
            _worker->RunWorkerCompleted += gcnew RunWorkerCompletedEventHandler(this, &MainForm::OnCompleted);

            // ═══ 16.4/16.5 两种 Timer ═══
            auto timers = gcnew GroupBox();
            timers->Text = L" 两种 Timer：Forms（UI 线程）/ Threading（线程池）"; timers->Dock = DockStyle::Fill;
            _formsTimer = gcnew Label();
            _formsTimer->Dock = DockStyle::Top; _formsTimer->Height = 34;
            _formsTimer->Text = L"Forms.Timer：0（Tick 直接改 UI，天然安全）";
            _threadTimer = gcnew Label();
            _threadTimer->Dock = DockStyle::Top; _threadTimer->Height = 34;
            _threadTimer->Text = L"Threading.Timer：0（回调在线程池，改 UI 必须 Invoke）";
            _elapsed = gcnew Label();
            _elapsed->Dock = DockStyle::Top; _elapsed->Height = 34;

            _uiTimer = gcnew System::Windows::Forms::Timer();
            _uiTimer->Interval = 500;
            _uiTimer->Tick += gcnew EventHandler(this, &MainForm::OnUiTick);
            _uiTimer->Start();

            _poolTimer = gcnew System::Threading::Timer(gcnew TimerCallback(this, &MainForm::OnPoolTick), nullptr, 0, 500);

            timers->Controls->Add(_elapsed);
            timers->Controls->Add(_threadTimer);
            timers->Controls->Add(_formsTimer);

            Controls->Add(timers);
            Controls->Add(work);
            Controls->Add(freeze);
        }

    protected:
        virtual void OnFormClosed(FormClosedEventArgs^ e) override
        {
            if (_worker->IsBusy) _worker->CancelAsync();
            delete _poolTimer;                     // Threading::Timer 的 Dispose() 是显式接口实现，delete 才调得到
            _uiTimer->Stop();
            __super::OnFormClosed(e);
        }

    private:
        void OnFreeze(Object^ s, EventArgs^ e)
        {
            _state->Text = L"  UI 线程睡 2 秒——这期间不处理任何消息（拖不动、点不响）";
            Thread::Sleep(2000);
            _state->Text = L"  醒了。正经做法见下";
        }

        void OnStart(Object^ s, EventArgs^ e)
        {
            _start->Enabled = false;
            _stop->Enabled = true;
            _worker->RunWorkerAsync(2000000);
        }

        void OnStop(Object^ s, EventArgs^ e) { _worker->CancelAsync(); }

        // DoWork：跑在线程池——这里绝对不能碰任何控件
        void OnDoWork(Object^ sender, DoWorkEventArgs^ e)
        {
            int max = safe_cast<int>(e->Argument);
            auto worker = safe_cast<BackgroundWorker^>(sender);
            int count = 0;
            for (int n = 2; n <= max; n++)
            {
                if (worker->CancellationPending)
                {
                    e->Cancel = true;
                    return;
                }
                bool prime = true;
                for (int d = 2; d * d <= n; d++)
                    if (n % d == 0) { prime = false; break; }
                if (prime) count++;
                if (n % (max / 100) == 0)
                    worker->ReportProgress(n * 100 / max);     // → ProgressChanged（UI 线程）
            }
            e->Result = count;
        }

        void OnProgress(Object^ sender, ProgressChangedEventArgs^ e)
        {
            _bar->Value = Math::Min(e->ProgressPercentage, 100);
            _state->Text = String::Format(L"  进度 {0}%", e->ProgressPercentage);
        }

        // RunWorkerCompleted：回到 UI 线程——无论正常/取消/异常都从这一扇门出来
        void OnCompleted(Object^ sender, RunWorkerCompletedEventArgs^ e)
        {
            if (e->Cancelled)
                _state->Text = L"  已取消";
            else
            {
                int count = safe_cast<int>(e->Result);
                _state->Text = String::Format(L"  完成：{0:N0} 个素数{1}",
                    count, count == 148933 ? L"（与已知值一致 ✔）" : L"（不对！）");
            }
            _start->Enabled = true;
            _stop->Enabled = false;
        }

        void OnUiTick(Object^ s, EventArgs^ e)
        {
            _uiTicks++;
            _formsTimer->Text = String::Format(L"Forms.Timer：{0}（Tick 直接改 UI，天然安全）", _uiTicks);
        }

        // Threading.Timer 回调：线程池线程——改 UI 前必须 BeginInvoke；
        // 而且定时器可能在窗体句柄创建前就开火（dueTime=0 的竞态），先查 IsHandleCreated
        void OnPoolTick(Object^ state)
        {
            _poolTicks++;
            if (_threadTimer->IsHandleCreated)
                _threadTimer->BeginInvoke(gcnew Action(this, &MainForm::ShowPoolTick));
        }

        void ShowPoolTick()
        {
            _threadTimer->Text = String::Format(L"Threading.Timer：{0}（回调在线程池，改 UI 必须 Invoke）", _poolTicks);
            _elapsed->Text = String::Format(L"  已运行 {0:F0} 秒", _watch->Elapsed.TotalSeconds);
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
