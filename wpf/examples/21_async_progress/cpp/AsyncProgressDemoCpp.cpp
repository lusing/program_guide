// 21 异步与线程模型（C++/CLI 版）：与 csharp/ 版功能一致。
// C++/CLI 没有 async/await——等价物是 Task::Delay + ContinueWith + Dispatcher::InvokeAsync 三连：
// 延时回调默认落在线程池线程，摸 UI 前必须经 Dispatcher 回主线程。
using namespace System;
using namespace System::ComponentModel;
using namespace System::Threading::Tasks;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Data;
using namespace System::Windows::Input;

namespace AsyncProgressDemoCpp {

    public ref class RelayCommand : public ICommand
    {
    private:
        Action<Object^>^ _execute;
    public:
        RelayCommand(Action<Object^>^ execute) { _execute = execute; }
        virtual event EventHandler^ CanExecuteChanged;   // 本例不用（恒可执行）
        virtual bool CanExecute(Object^ parameter) { return true; }
        virtual void Execute(Object^ parameter) { _execute(parameter); }
    };

    public ref class MainViewModel : public INotifyPropertyChanged
    {
    private:
        int _progress;
        String^ _statusText;
    public:
        virtual event PropertyChangedEventHandler^ PropertyChanged;

        MainViewModel()
        {
            _progress = 0;
            _statusText = L"等待开始";
        }

        property int Progress
        {
            int get() { return _progress; }
            void set(int value)
            {
                if (_progress == value) return;
                _progress = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"Progress"));
            }
        }
        property String^ StatusText
        {
            String^ get() { return _statusText; }
            void set(String^ value)
            {
                if (_statusText == value) return;
                _statusText = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"StatusText"));
            }
        }
    };

    public ref class MainWindow : public Window
    {
    private:
        MainViewModel^ _vm;
        int _step;

    public:
        MainWindow()
        {
            Title = L"Async Progress Demo (C++/CLI)";
            Width = 420; Height = 220;
            _vm = gcnew MainViewModel();
            _step = 0;
            DataContext = _vm;

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(20);

            TextBlock^ title = gcnew TextBlock();
            title->Text = L"异步任务与进度";
            title->FontSize = 22; title->FontWeight = FontWeights::Bold;
            title->Margin = Thickness(0, 0, 0, 12);

            ProgressBar^ bar = gcnew ProgressBar();
            bar->Height = 20; bar->Minimum = 0; bar->Maximum = 100;
            bar->Margin = Thickness(0, 0, 0, 12);
            bar->SetBinding(ProgressBar::ValueProperty, gcnew Binding(L"Progress"));

            TextBlock^ status = gcnew TextBlock();
            status->FontSize = 16; status->Margin = Thickness(0, 0, 0, 12);
            status->SetBinding(TextBlock::TextProperty, gcnew Binding(L"StatusText"));

            Button^ start = gcnew Button();
            start->Content = L"启动任务";
            start->Width = 140; start->Height = 36;
            start->SetBinding(Button::CommandProperty, gcnew Binding(L"StartCommand"));

            panel->Children->Add(title); panel->Children->Add(bar);
            panel->Children->Add(status); panel->Children->Add(start);
            Content = panel;

            StartCommand = gcnew RelayCommand(gcnew Action<Object^>(this, &MainWindow::OnStart));
        }

        property ICommand^ StartCommand;

    private:
        void OnStart(Object^ parameter)
        {
            _step = 0;
            StepAsync();
        }

        // 每步：更新 VM（此时在 UI 线程）→ 延时 → 回调里经 Dispatcher 再走下一步
        void StepAsync()
        {
            _vm->Progress = _step;
            _vm->StatusText = String::Format(L"处理中 {0}%", _step);
            Task::Delay(200)->ContinueWith(gcnew Action<Task^>(this, &MainWindow::OnDelay));
        }

        void OnDelay(Task^ delayed)
        {
            // ContinueWith 默认在线程池线程——回 UI 线程走 Dispatcher
            Dispatcher->InvokeAsync(gcnew Action(this, &MainWindow::Advance));
        }

        void Advance()
        {
            _step += 10;
            if (_step > 100)
            {
                _vm->Progress = 100;
                _vm->StatusText = L"完成";
            }
            else
            {
                StepAsync();
            }
        }
    };

    public ref class App
    {
    public:
        static void Run()
        {
            Application^ app = gcnew Application();
            app->Run(gcnew MainWindow());
        }
    };
}
