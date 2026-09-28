// 12 命令系统（C++/CLI 版）：与 csharp/ 版功能一致。
// 两套命令机制：RelayCommand（ICommand 自实现）+ WPF 命令库 ApplicationCommands.Copy（教材 9.2.5）。
using namespace System;
using namespace System::ComponentModel;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Input;

namespace CommandDemoCpp {

    public ref class RelayCommand : public ICommand
    {
    private:
        Action<Object^>^ _execute;
        Predicate<Object^>^ _canExecute;
    public:
        RelayCommand(Action<Object^>^ execute, Predicate<Object^>^ canExecute)
        {
            _execute = execute;
            _canExecute = canExecute;
        }

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

    public ref class MainViewModel : public INotifyPropertyChanged
    {
    private:
        String^ _taskName;
        String^ _statusText;
        RelayCommand^ _addCmd;
    public:
        virtual event PropertyChangedEventHandler^ PropertyChanged;

        MainViewModel()
        {
            _taskName = L"学习 WPF 命令";
            _statusText = L"待执行";

            // 没有 lambda 捕获：execute / canExecute 都是「this + 方法组」委托
            _addCmd = gcnew RelayCommand(
                gcnew Action<Object^>(this, &MainViewModel::OnExecute),
                gcnew Predicate<Object^>(this, &MainViewModel::OnCanExecute));
        }

        property String^ TaskName
        {
            String^ get() { return _taskName; }
            void set(String^ value)
            {
                if (_taskName == value) return;
                _taskName = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"TaskName"));
                _addCmd->RaiseCanExecuteChanged();   // 输入变了 → 命令可执行性要重算
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
        property ICommand^ AddTaskCommand { ICommand^ get() { return _addCmd; } }

    private:
        void OnExecute(Object^ parameter)
        {
            StatusText = String::Concat(L"命令已执行: ", _taskName);
        }

        bool OnCanExecute(Object^ parameter)
        {
            return !String::IsNullOrWhiteSpace(_taskName);
        }
    };

    public ref class MainWindow : public Window
    {
    public:
        MainWindow()
        {
            Title = L"Command Demo (C++/CLI)";
            Width = 420; Height = 260;
            DataContext = gcnew MainViewModel();

            // WPF 命令库（教材 9.2.5）：ApplicationCommands.Copy 是现成的 RoutedUICommand
            CommandBindings->Add(gcnew CommandBinding(
                ApplicationCommands::Copy,
                gcnew ExecutedRoutedEventHandler(this, &MainWindow::OnCopyExecuted),
                gcnew CanExecuteRoutedEventHandler(this, &MainWindow::OnCopyCanExecute)));

            StackPanel^ panel = gcnew StackPanel();
            panel->Margin = Thickness(20);

            TextBlock^ title = gcnew TextBlock();
            title->Text = L"命令系统示例"; title->FontSize = 22;
            title->FontWeight = FontWeights::Bold; title->Margin = Thickness(0, 0, 0, 12);

            TextBox^ nameBox = gcnew TextBox();
            nameBox->Width = 250;
            nameBox->HorizontalAlignment = System::Windows::HorizontalAlignment::Left;
            nameBox->Margin = Thickness(0, 0, 0, 12);
            System::Windows::Data::Binding^ b1 = gcnew System::Windows::Data::Binding(L"TaskName");
            b1->UpdateSourceTrigger = System::Windows::Data::UpdateSourceTrigger::PropertyChanged;
            nameBox->SetBinding(TextBox::TextProperty, b1);

            Button^ runBtn = gcnew Button();
            runBtn->Content = L"执行命令"; runBtn->Width = 140; runBtn->Height = 36;
            runBtn->SetBinding(Button::CommandProperty, gcnew System::Windows::Data::Binding(L"AddTaskCommand"));

            TextBlock^ status = gcnew TextBlock();
            status->Margin = Thickness(0, 12, 0, 0); status->FontSize = 16;
            status->SetBinding(TextBlock::TextProperty, gcnew System::Windows::Data::Binding(L"StatusText"));

            Button^ libBtn = gcnew Button();
            libBtn->Content = L"命令库: 复制（Ctrl+C 也可）";
            libBtn->Command = ApplicationCommands::Copy;
            libBtn->Width = 200; libBtn->Height = 32; libBtn->Margin = Thickness(0, 16, 0, 0);

            panel->Children->Add(title);
            panel->Children->Add(nameBox);
            panel->Children->Add(runBtn);
            panel->Children->Add(status);
            panel->Children->Add(libBtn);

            Content = panel;
        }

    private:
        void OnCopyExecuted(Object^ sender, ExecutedRoutedEventArgs^ e)
        {
            MessageBox::Show(this, L"ApplicationCommands.Copy 执行（WPF 命令库）", L"Command");
        }

        void OnCopyCanExecute(Object^ sender, CanExecuteRoutedEventArgs^ e)
        {
            e->CanExecute = true;
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
