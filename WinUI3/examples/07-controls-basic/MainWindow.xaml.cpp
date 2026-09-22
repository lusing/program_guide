#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::BasicGallery::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"BasicGallery");
        // 固定窗口尺寸：让 NavigationView 的"按逻辑宽度自适应收起"不触发
        // （150% DPI 下 900 物理px = 600 逻辑px < 640 阈值，面板会被折叠），
        // 也让 ui-smoke 的点击坐标有确定性的落点。AppWindow 机制见 docs/31。
        if (auto appWindow = AppWindow())
        {
            appWindow.Resize({ 1280, 860 });
        }
        // 初始页：不依赖 NavigationView 的初始选中事件，构造期直接导航
        ContentFrame().Navigate(xaml_typename<BasicGallery::HomePage>());
    }

    void MainWindow::OnNavSelectionChanged(IInspectable const&,
        NavigationViewSelectionChangedEventArgs const& args)
    {
        // Tag 在 XAML 里是字符串字面量，装箱后用 unbox_value 解回 hstring（docs/14）
        if (auto item = args.SelectedItem().try_as<NavigationViewItem>())
        {
            NavigateTo(winrt::unbox_value<winrt::hstring>(item.Tag()));
        }
    }

    void MainWindow::NavigateTo(winrt::hstring const& tag)
    {
        if (tag == L"home") ContentFrame().Navigate(xaml_typename<BasicGallery::HomePage>());
        if (tag == L"button") ContentFrame().Navigate(xaml_typename<BasicGallery::ButtonPage>());
        if (tag == L"textblock") ContentFrame().Navigate(xaml_typename<BasicGallery::TextBlockPage>());
        if (tag == L"textbox") ContentFrame().Navigate(xaml_typename<BasicGallery::TextBoxPage>());
        if (tag == L"checkbox") ContentFrame().Navigate(xaml_typename<BasicGallery::CheckBoxPage>());
        if (tag == L"toggle") ContentFrame().Navigate(xaml_typename<BasicGallery::TogglePage>());
        if (tag == L"slider") ContentFrame().Navigate(xaml_typename<BasicGallery::SliderPage>());
        if (tag == L"numberbox") ContentFrame().Navigate(xaml_typename<BasicGallery::NumberBoxPage>());
        if (tag == L"combobox") ContentFrame().Navigate(xaml_typename<BasicGallery::ComboBoxPage>());
        // 每章任务追加分支
    }
}
