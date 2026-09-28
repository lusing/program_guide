// 11 MVVM 模式（C++/CLI 版）：与 csharp/ 版功能一致。
// RelayCommand 的 C++/CLI 形态：没有 lambda 捕获，execute 用「目标对象 + 方法组」做委托，
// 也可以像下面这样把整个命令做成一个类（无参命令最省事的写法）。
using namespace System;
using namespace System::ComponentModel;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Input;

namespace MvvmDemoCpp {

    // ── RelayCommand ──
    public ref class RelayCommand : public ICommand
    {
    private:
        Action<Object^>^ _execute;
        Predicate<Object^>^ _canExecute;
    public:
        RelayCommand(Action<Object^>^ execute) { _execute = execute; _canExecute = nullptr; }

        virtual event EventHandler^ CanExecuteChanged;

        virtual bool CanExecute(Object^ parameter)
        {
            return _canExecute == nullptr || _canExecute(parameter);
        }
        virtual void Execute(Object^ parameter) { _execute(parameter); }

        void RaiseCanExecuteChanged()
        {
            CanExecuteChanged(this, EventArgs::Empty);
        }
    };

    // ── ViewModel ──
    public ref class MainViewModel : public INotifyPropertyChanged
    {
    private:
        String^ _taskName;
        String^ _statusMessage;
    public:
        virtual event PropertyChangedEventHandler^ PropertyChanged;

        MainViewModel()
        {
            _taskName = L"学习 WPF";
            _statusMessage = L"待处理";

            // 没有闭包：命令体写成私有方法，委托拿「this + 方法组」
            AddTaskCommand = gcnew RelayCommand(gcnew Action<Object^>(this, &MainViewModel::OnAddTask));
        }

        property String^ TaskName
        {
            String^ get() { return _taskName; }
            void set(String^ value)
            {
                if (_taskName == value) return;
                _taskName = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"TaskName"));
            }
        }
        property String^ StatusMessage
        {
            String^ get() { return _statusMessage; }
            void set(String^ value)
            {
                if (_statusMessage == value) return;
                _statusMessage = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"StatusMessage"));
            }
        }
        property ICommand^ AddTaskCommand;

    private:
        void OnAddTask(Object^ parameter)
        {
            if (String::IsNullOrWhiteSpace(_taskName))
            {
                StatusMessage = L"任务名称不能为空。";
                return;
            }
            StatusMessage = String::Concat(L"已添加任务: ", _taskName);
        }
    };

    public ref class MainWindow : public Window
    {
    public:
        MainWindow()
        {
            Title = L"MVVM Demo (C++/CLI)";
            Width = 420; Height = 240;

            DataContext = gcnew MainViewModel();

            Grid^ grid = gcnew Grid();
            grid->Margin = Thickness(20);

            StackPanel^ panel = gcnew StackPanel();
            panel->VerticalAlignment = System::Windows::VerticalAlignment::Center;

            TextBlock^ label = gcnew TextBlock();
            label->Text = L"任务名称"; label->FontWeight = FontWeights::Bold;
            label->Margin = Thickness(0, 0, 0, 8);

            TextBox^ nameBox = gcnew TextBox();
            nameBox->Margin = Thickness(0, 0, 0, 12);
            System::Windows::Data::Binding^ b1 = gcnew System::Windows::Data::Binding(L"TaskName");
            b1->UpdateSourceTrigger = System::Windows::Data::UpdateSourceTrigger::PropertyChanged;
            nameBox->SetBinding(TextBox::TextProperty, b1);

            TextBlock^ status = gcnew TextBlock();
            status->FontSize = 18; status->Margin = Thickness(0, 0, 0, 12);
            status->SetBinding(TextBlock::TextProperty, gcnew System::Windows::Data::Binding(L"StatusMessage"));

            Button^ addBtn = gcnew Button();
            addBtn->Content = L"添加任务"; addBtn->Width = 150; addBtn->Height = 36;
            addBtn->SetBinding(Button::CommandProperty, gcnew System::Windows::Data::Binding(L"AddTaskCommand"));

            panel->Children->Add(label);
            panel->Children->Add(nameBox);
            panel->Children->Add(status);
            panel->Children->Add(addBtn);
            grid->Children->Add(panel);

            Content = grid;
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
