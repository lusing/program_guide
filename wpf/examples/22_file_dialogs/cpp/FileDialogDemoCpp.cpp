// 22 对话框与文件 IO（C++/CLI 版）：与 csharp/ 版功能一致。
// OpenFileDialog/SaveFileDialog 在 Microsoft::Win32；ShowDialog 返 Nullable<bool>——判 HasValue 取值。
using namespace System;
using namespace System::IO;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace Microsoft::Win32;

namespace FileDialogDemoCpp {

    public ref class MainWindow : public Window
    {
    private:
        TextBox^ _pathBox;

    public:
        MainWindow()
        {
            Title = L"File Dialog Demo (C++/CLI)";
            Width = 480; Height = 260;

            _pathBox = gcnew TextBox();
            _pathBox->Text = L"未选择文件";
            _pathBox->TextWrapping = TextWrapping::Wrap;
            _pathBox->IsReadOnly = true;
            _pathBox->VerticalScrollBarVisibility = ScrollBarVisibility::Auto;

            Button^ openBtn = gcnew Button();
            openBtn->Content = L"打开文件";
            openBtn->Width = 120; openBtn->Height = 32;
            openBtn->Margin = Thickness(0, 0, 12, 0);
            openBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnOpenFile);

            Button^ saveBtn = gcnew Button();
            saveBtn->Content = L"保存文件";
            saveBtn->Width = 120; saveBtn->Height = 32;
            saveBtn->Click += gcnew RoutedEventHandler(this, &MainWindow::OnSaveFile);

            StackPanel^ row = gcnew StackPanel();
            row->Orientation = System::Windows::Controls::Orientation::Horizontal;
            row->Margin = Thickness(0, 0, 0, 12);
            row->Children->Add(openBtn);
            row->Children->Add(saveBtn);

            Grid^ grid = gcnew Grid();
            grid->Margin = Thickness(20);
            RowDefinition^ r0 = gcnew RowDefinition(); r0->Height = GridLength::Auto;
            RowDefinition^ r1 = gcnew RowDefinition(); r1->Height = GridLength::Auto;
            RowDefinition^ r2 = gcnew RowDefinition(); r2->Height = GridLength(1.0, GridUnitType::Star);
            grid->RowDefinitions->Add(r0); grid->RowDefinitions->Add(r1); grid->RowDefinitions->Add(r2);

            TextBlock^ title = gcnew TextBlock();
            title->Text = L"文件对话框示例";
            title->FontSize = 22; title->FontWeight = FontWeights::Bold;
            title->Margin = Thickness(0, 0, 0, 12);
            Grid::SetRow(title, 0); Grid::SetRow(row, 1); Grid::SetRow(_pathBox, 2);
            grid->Children->Add(title); grid->Children->Add(row); grid->Children->Add(_pathBox);

            Content = grid;
        }

    private:
        void OnOpenFile(Object^ sender, RoutedEventArgs^ e)
        {
            OpenFileDialog^ dialog = gcnew OpenFileDialog();
            dialog->Filter = L"文本文件|*.txt|所有文件|*.*";
            dialog->InitialDirectory = Environment::GetFolderPath(Environment::SpecialFolder::MyDocuments);

            Nullable<bool> result = dialog->ShowDialog();
            if (result.HasValue && result.Value)
            {
                _pathBox->Text = dialog->FileName;
                MessageBox::Show(this, String::Concat(L"已选择: ", dialog->FileName), L"Open File");
            }
        }

        void OnSaveFile(Object^ sender, RoutedEventArgs^ e)
        {
            SaveFileDialog^ dialog = gcnew SaveFileDialog();
            dialog->Filter = L"文本文件|*.txt|所有文件|*.*";
            dialog->FileName = L"newfile.txt";
            dialog->InitialDirectory = Environment::GetFolderPath(Environment::SpecialFolder::MyDocuments);

            Nullable<bool> result = dialog->ShowDialog();
            if (result.HasValue && result.Value)
            {
                _pathBox->Text = dialog->FileName;
                File::WriteAllText(dialog->FileName, L"Hello from WPF!\r\n");
                MessageBox::Show(this, String::Concat(L"已保存: ", dialog->FileName), L"Save File");
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
