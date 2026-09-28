// 18 TreeView 与层级数据（C++/CLI 版）：与 csharp/ 版功能一致。
// HierarchicalDataTemplate 两挂钩：VisualTree + ItemsSource（值是 Binding）。
// TreeView.SelectedItem 只读不能 TwoWay——选中要靠 SelectedItemChanged 事件拿。
using namespace System;
using namespace System::Collections::ObjectModel;
using namespace System::ComponentModel;
using namespace System::Windows;
using namespace System::Windows::Controls;
using namespace System::Windows::Controls::Primitives;
using namespace System::Windows::Data;
using namespace System::Windows::Media;

namespace TreeViewDemoCpp {

    public ref class BoolToIconConverter : public IValueConverter
    {
    public:
        virtual Object^ Convert(Object^ value, Type^ targetType, Object^ parameter, System::Globalization::CultureInfo^ culture)
        {
            return (value != nullptr && safe_cast<bool>(value)) ? (Object^)L"\U0001F4C1"   // 📁
                                                                : (Object^)L"\U0001F4C4";  // 📄
        }
        virtual Object^ ConvertBack(Object^ value, Type^ targetType, Object^ parameter, System::Globalization::CultureInfo^ culture)
        {
            throw gcnew NotSupportedException();
        }
    };

    public ref class FileNode : public INotifyPropertyChanged
    {
    private:
        String^ _name;
        bool _isFolder;
        bool _isExpanded;
    public:
        virtual event PropertyChangedEventHandler^ PropertyChanged;

        FileNode(String^ name, bool isFolder)
        {
            _name = name; _isFolder = isFolder; _isExpanded = false;
            Children = gcnew ObservableCollection<FileNode^>();
        }

        property String^ Name { String^ get() { return _name; } }
        property bool IsFolder { bool get() { return _isFolder; } }
        property ObservableCollection<FileNode^>^ Children;
        property bool IsExpanded
        {
            bool get() { return _isExpanded; }
            void set(bool value)
            {
                _isExpanded = value;
                PropertyChanged(this, gcnew PropertyChangedEventArgs(L"IsExpanded"));
            }
        }
        property String^ Badge
        {
            String^ get() { return _isFolder ? String::Format(L"{0} 项", Children->Count) : L""; }
        }
    };

    public ref class MainWindow : public Window
    {
    private:
        TextBlock^ _status;
        ObservableCollection<FileNode^>^ _root;

        static FileNode^ FileOf(String^ name) { return gcnew FileNode(name, false); }

        static FileNode^ FolderOf(String^ name, bool expanded, array<FileNode^>^ kids)
        {
            FileNode^ f = gcnew FileNode(name, true);
            f->IsExpanded = expanded;
            for each (FileNode^ kid in kids)
                f->Children->Add(kid);
            return f;
        }

        // 递归遍历模型本身：树形 UI 的批量操作落在数据上，而不是视觉树上
        static void SetExpanded(ObservableCollection<FileNode^>^ nodes, bool expanded)
        {
            for each (FileNode^ node in nodes)
            {
                node->IsExpanded = expanded;
                SetExpanded(node->Children, expanded);
            }
        }

    public:
        MainWindow()
        {
            Title = L"TreeView：层级数据 (C++/CLI)";
            Width = 420; Height = 460;

            // ── 造树（与 csharp 版同一棵）──
            _root = gcnew ObservableCollection<FileNode^>();
            _root->Add(FolderOf(L"NotepadPlus", true, gcnew array<FileNode^> {
                FileOf(L"App.xaml"),
                FileOf(L"NotepadPlus.csproj"),
                FolderOf(L"ViewModels", false, gcnew array<FileNode^> {
                    FileOf(L"MainViewModel.cs"), FileOf(L"RelayCommand.cs") }),
                FolderOf(L"Views", false, gcnew array<FileNode^> {
                    FileOf(L"MainWindow.xaml"), FileOf(L"FindReplaceWindow.xaml") }),
                FolderOf(L"Services", false, gcnew array<FileNode^> {
                    FileOf(L"EncodingDetector.cs"), FileOf(L"RecentFilesService.cs") }),
            }));
            _root->Add(FolderOf(L"docs", false, gcnew array<FileNode^> {
                FileOf(L"07-mvvm-commands.md"), FileOf(L"12-notepad-plus.md") }));

            _status = gcnew TextBlock();
            _status->Text = L"选中树里的任意节点";

            // ── HierarchicalDataTemplate ──
            HierarchicalDataTemplate^ hdt = gcnew HierarchicalDataTemplate(FileNode::typeid);
            hdt->ItemsSource = gcnew Binding(L"Children");   // 孩子从哪来——值是一个 Binding

            FrameworkElementFactory^ row = gcnew FrameworkElementFactory(StackPanel::typeid);
            row->SetValue(StackPanel::OrientationProperty, System::Windows::Controls::Orientation::Horizontal);

            FrameworkElementFactory^ icon = gcnew FrameworkElementFactory(TextBlock::typeid);
            Binding^ ib = gcnew Binding(L"IsFolder");
            ib->Converter = gcnew BoolToIconConverter();
            ib->FallbackValue = L"?";
            icon->SetBinding(TextBlock::TextProperty, ib);

            FrameworkElementFactory^ name = gcnew FrameworkElementFactory(TextBlock::typeid);
            name->SetBinding(TextBlock::TextProperty, gcnew Binding(L"Name"));
            name->SetValue(FrameworkElement::MarginProperty, Thickness(6, 0, 0, 0));
            name->SetValue(FrameworkElement::VerticalAlignmentProperty, System::Windows::VerticalAlignment::Center);

            FrameworkElementFactory^ badge = gcnew FrameworkElementFactory(TextBlock::typeid);
            badge->SetBinding(TextBlock::TextProperty, gcnew Binding(L"Badge"));
            badge->SetValue(TextBlock::FontSizeProperty, 11.0);
            badge->SetValue(TextBlock::ForegroundProperty,
                gcnew SolidColorBrush(Color::FromRgb(0x94, 0xA3, 0xB8)));
            badge->SetValue(FrameworkElement::MarginProperty, Thickness(8, 0, 0, 0));
            badge->SetValue(FrameworkElement::VerticalAlignmentProperty, System::Windows::VerticalAlignment::Center);

            row->AppendChild(icon); row->AppendChild(name); row->AppendChild(badge);
            hdt->VisualTree = row;

            TreeView^ tree = gcnew TreeView();
            tree->ItemTemplate = hdt;
            tree->ItemsSource = _root;   // 代码里数据就在手边：直赋比绕一圈绑定干净
            VirtualizingStackPanel::SetIsVirtualizing(tree, true);   // XAML 的附加属性 → 静态方法

            // SelectedItem 只读：拿选中只能靠事件
            tree->SelectedItemChanged +=
                gcnew RoutedPropertyChangedEventHandler<Object^>(this, &MainWindow::OnSelectedChanged);

            // ── 工具栏 + 状态栏 ──
            Button^ expandAll = gcnew Button();
            expandAll->Content = L"展开全部"; expandAll->Width = 90;
            expandAll->Margin = Thickness(0, 0, 8, 0);
            expandAll->Click += gcnew RoutedEventHandler(this, &MainWindow::OnExpandAll);
            Button^ collapseAll = gcnew Button();
            collapseAll->Content = L"收起全部"; collapseAll->Width = 90;
            collapseAll->Click += gcnew RoutedEventHandler(this, &MainWindow::OnCollapseAll);
            StackPanel^ toolbar = gcnew StackPanel();
            toolbar->Orientation = System::Windows::Controls::Orientation::Horizontal;
            toolbar->Margin = Thickness(0, 0, 0, 8);
            toolbar->Children->Add(expandAll); toolbar->Children->Add(collapseAll);

            StatusBar^ statusBar = gcnew StatusBar();
            statusBar->Items->Add(_status);

            DockPanel^ dock = gcnew DockPanel();
            dock->Margin = Thickness(12);
            DockPanel::SetDock(toolbar, Dock::Top);
            DockPanel::SetDock(statusBar, Dock::Bottom);
            dock->Children->Add(toolbar);
            dock->Children->Add(statusBar);
            dock->Children->Add(tree);

            Content = dock;
        }

    private:
        void OnSelectedChanged(Object^ sender, RoutedPropertyChangedEventArgs<Object^>^ e)
        {
            FileNode^ node = dynamic_cast<FileNode^>(e->NewValue);
            if (node != nullptr)
                _status->Text = String::Format(L"选中：{0}（{1}）", node->Name,
                    node->IsFolder ? L"文件夹" : L"文件");
        }

        void OnExpandAll(Object^ sender, RoutedEventArgs^ e) { SetExpanded(_root, true); }
        void OnCollapseAll(Object^ sender, RoutedEventArgs^ e) { SetExpanded(_root, false); }
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
