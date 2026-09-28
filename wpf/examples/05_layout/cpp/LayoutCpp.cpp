// 05 布局系统（C++/CLI 版）：与 csharp/ 的 C#+XAML 版功能一致。
// XAML → C++/CLI 对应三件套：
//   <RowDefinition Height="Auto"/>     → r->Height = GridLength::Auto;（GridLength 结构体）
//   Height="*"                         → GridLength(1.0, GridUnitType::Star)
//   Grid.Row / DockPanel.Dock          → Grid::SetRow(el, n) / DockPanel::SetDock(el, Dock::Top)
using namespace System;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Controls::Primitives;   // UniformGrid 在 Primitives 里
using namespace System::Windows::Media;

namespace LayoutCpp {

    public ref class MainWindow : public Window
    {
    public:
        MainWindow()
        {
            Title = L"Layout Demo (C++/CLI)";
            Width = 620; Height = 460;

            // ── 左栏 ──
            StackPanel^ menuPanel = gcnew StackPanel();
            TextBlock^ menuTitle = gcnew TextBlock();
            menuTitle->Text = L"菜单"; menuTitle->FontWeight = FontWeights::Bold;
            menuPanel->Children->Add(menuTitle);
            array<String^>^ menus = { L"首页", L"文档", L"设置" };
            for each (String^ m in menus)
            {
                Button^ b = gcnew Button();
                b->Content = m;
                if (m != L"设置") b->Margin = Thickness(0, 0, 0, 8);
                menuPanel->Children->Add(b);
            }

            Border^ sidebar = gcnew Border();
            sidebar->Background = Brushes::AliceBlue;
            sidebar->Margin = Thickness(0, 0, 12, 0);
            sidebar->Padding = Thickness(12);
            sidebar->BorderBrush = Brushes::LightGray;
            sidebar->BorderThickness = Thickness(1);
            sidebar->Child = menuPanel;

            // ── 右栏 DockPanel ──
            TextBlock^ title = gcnew TextBlock();
            title->Text = L"工作区"; title->FontWeight = FontWeights::Bold;
            DockPanel::SetDock(title, Dock::Top);
            title->Margin = Thickness(0, 0, 0, 8);

            TextBox^ editor = gcnew TextBox();
            editor->Height = 90; editor->Text = L"这里展示正文内容…";
            editor->TextWrapping = TextWrapping::Wrap;
            editor->AcceptsReturn = true;
            DockPanel::SetDock(editor, Dock::Bottom);

            Grid^ twoCol = gcnew Grid();
            twoCol->ColumnDefinitions->Add(gcnew ColumnDefinition());
            twoCol->ColumnDefinitions->Add(gcnew ColumnDefinition());
            Button^ newBtn = gcnew Button(); newBtn->Content = L"新建"; newBtn->Margin = Thickness(0, 0, 8, 0);
            Button^ saveBtn = gcnew Button(); saveBtn->Content = L"保存";
            Grid::SetColumn(newBtn, 0); Grid::SetColumn(saveBtn, 1);
            twoCol->Children->Add(newBtn); twoCol->Children->Add(saveBtn);

            StackPanel^ mainArea = gcnew StackPanel();
            TextBlock^ heading = gcnew TextBlock();
            heading->Text = L"主内容区域"; heading->FontSize = 16; heading->Margin = Thickness(0, 0, 0, 8);
            mainArea->Children->Add(heading);
            mainArea->Children->Add(twoCol);

            Border^ content = gcnew Border();
            content->BorderBrush = Brushes::LightGray;
            content->BorderThickness = Thickness(1);
            content->Padding = Thickness(10);
            content->Child = mainArea;

            DockPanel^ dock = gcnew DockPanel();
            dock->LastChildFill = true;
            dock->Children->Add(title);
            dock->Children->Add(editor);
            dock->Children->Add(content);

            // ── 左右两栏 ──
            Grid^ body = gcnew Grid();
            ColumnDefinition^ c0 = gcnew ColumnDefinition(); c0->Width = GridLength(220.0, GridUnitType::Pixel);
            ColumnDefinition^ c1 = gcnew ColumnDefinition(); c1->Width = GridLength(1.0, GridUnitType::Star);
            body->ColumnDefinitions->Add(c0); body->ColumnDefinitions->Add(c1);
            Grid::SetColumn(sidebar, 0); Grid::SetColumn(dock, 1);
            body->Children->Add(sidebar); body->Children->Add(dock);

            // ── UniformGrid（教材 3.2.5）──
            UniformGrid^ uniform = gcnew UniformGrid();
            uniform->Columns = 5;
            uniform->Margin = Thickness(0, 12, 0, 0);
            for (int i = 1; i <= 5; i++)
            {
                Button^ b = gcnew Button();
                b->Content = String::Format(L"{0}/5", i);
                uniform->Children->Add(b);
            }

            StatusBar^ status = gcnew StatusBar();
            status->Margin = Thickness(0, 12, 0, 0);
            TextBlock^ ready = gcnew TextBlock(); ready->Text = L"Ready";
            status->Items->Add(ready);

            // ── 外层 Grid：4 行 ──
            Grid^ grid = gcnew Grid();
            grid->Margin = Thickness(16);
            RowDefinition^ r0 = gcnew RowDefinition(); r0->Height = GridLength::Auto;
            RowDefinition^ r1 = gcnew RowDefinition(); r1->Height = GridLength(1.0, GridUnitType::Star);
            RowDefinition^ r2 = gcnew RowDefinition(); r2->Height = GridLength::Auto;
            RowDefinition^ r3 = gcnew RowDefinition(); r3->Height = GridLength::Auto;
            grid->RowDefinitions->Add(r0); grid->RowDefinitions->Add(r1);
            grid->RowDefinitions->Add(r2); grid->RowDefinitions->Add(r3);

            TextBlock^ head = gcnew TextBlock();
            head->Text = L"布局示例"; head->FontSize = 24;
            head->FontWeight = FontWeights::Bold;
            head->Margin = Thickness(0, 0, 0, 12);
            Grid::SetRow(head, 0); Grid::SetRow(body, 1);
            Grid::SetRow(uniform, 2); Grid::SetRow(status, 3);
            grid->Children->Add(head); grid->Children->Add(body);
            grid->Children->Add(uniform); grid->Children->Add(status);

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
