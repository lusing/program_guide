#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::MediaLibrary::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        m_viewModel = make<LibraryViewModel>();

        // 首次 Activated 时设默认选中（XAML 里写 SelectedIndex="0" 会在
        // Items 尚为空的解析序上让 Selector 抛 stowed 异常——XAML 属性按
        // 出现序赋值，SelectedIndex 必须排在 ItemsSource 之后才安全）。
        m_activatedRevoker = Activated(auto_revoke_t{},
            [this](auto const&, auto const&)
        {
            if (CategoryFilter().SelectedIndex() == -1)
            {
                CategoryFilter().SelectedIndex(0);   // "All"
            }
        });

        // 构造期自定位（31.5.2：外部再动窗口会打烂岛输入变换）
        // AppWindow 的 MoveAndResize 实测按逻辑单位解释：1080x620 逻辑 ≈ 1890x1085 物理 @175%
        if (auto appWindow = AppWindow())
        {
            appWindow.MoveAndResize(Windows::Graphics::RectInt32{ 30, 30, 1080, 620 });
        }

        (void)m_viewModel.InitializeAsync();
    }

    void MainWindow::OnSelectionChanged(
        IInspectable const& sender, Controls::SelectionChangedEventArgs const& args)
    {
        // 12.5 深坑：SelectionChanged 在 XAML 解析期与析构期都会触发。
        // AddedItems 可能为空（清空选择触发，17 章实测），GetAt 前必查 Size。
        auto list = sender.as<Controls::ListView>();
        if (!list || args.AddedItems().Size() == 0)
        {
            m_viewModel.ClearSelection();
            return;
        }
        m_viewModel.SelectItem(args.AddedItems().GetAt(0).as<MediaLibrary::MediaItem>());
    }

    void MainWindow::OnCategoryChanged(
        IInspectable const&, Controls::SelectionChangedEventArgs const& args)
    {
        // 解析期 SelectedIndex=0 也会来一次；ViewModel 未就绪时直接放过
        if (!m_viewModel || args.AddedItems().Size() == 0) { return; }
        // 列表项是 hstring 装箱：unbox 取回，失败回退 All
        auto category = winrt::unbox_value_or<winrt::hstring>(
            args.AddedItems().GetAt(0), L"All");
        m_viewModel.SelectedCategory(category);   // setter 里级联重查（书 3 章）
    }
}
