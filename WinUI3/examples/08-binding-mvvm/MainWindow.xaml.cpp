#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::MvvmApp::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        m_viewModel = make<TasksViewModel>();
        // 在 UI 线程构造时抓取 DispatcherQueue，供后台工作切回 UI 线程（docs/08 8.7）
        m_dispatcherQueue = Microsoft::UI::Dispatching::DispatcherQueue::GetForCurrentThread();
    }

    void MainWindow::OnDeleteClicked(IInspectable const&, RoutedEventArgs const&)
    {
        auto selected = TaskList().SelectedItem();
        if (!selected) { return; }
        // 选中项由页面读出再传给 ViewModel，Model 保持纯净（docs/08 8.5）
        (void)ConfirmDeleteAsync(selected.as<MvvmApp::TaskItem>());
    }

    void MainWindow::OnRefreshClicked(IInspectable const&, RoutedEventArgs const&)
    {
        (void)RefreshAsync();   // 发后不管的刷新任务（docs/08 8.7.2）
    }

    winrt::Windows::Foundation::IAsyncAction MainWindow::ConfirmDeleteAsync(
        MvvmApp::TaskItem const& item)
    {
        ContentDialog dialog;
        dialog.Title(box_value(L"Delete item"));
        dialog.Content(box_value(L"Do you want to delete this task?"));
        dialog.PrimaryButtonText(L"Delete");
        dialog.CloseButtonText(L"Cancel");
        dialog.DefaultButton(ContentDialogButton::Primary);

        // WinUI 3 必须设置 XamlRoot，否则 ShowAsync 运行时抛异常。
        // Window 本身没有 XamlRoot 成员，只能从内容树根元素取（docs/06 6.7）。
        dialog.XamlRoot(rootPanel().XamlRoot());

        auto result = co_await dialog.ShowAsync();
        if (result == ContentDialogResult::Primary)
        {
            m_viewModel.DeleteSelected(item);
        }
    }

    winrt::Windows::Foundation::IAsyncAction MainWindow::RefreshAsync()
    {
        // ── UI 线程：进入加载态 ──
        LoadingText().Text(L"Loading...");
        RefreshButton().IsEnabled(false);

        // ── 切到线程池 ──
        co_await winrt::resume_background();

        // 后台线程：只产生数据，不碰 UI
        std::vector<winrt::hstring> titles{ L"from store 1", L"from store 2" };

        // ── 切回 UI 线程 ──
        // WinUI 3 的 UI 队列是 Microsoft.UI.Dispatching.DispatcherQueue，而
        // winrt::resume_foreground 没有它的可 await 重载（只有 Windows.System 那个，
        // 桌面 UI 线程并不泵它），所以用 TryEnqueue 把落地段排回 UI 线程。
        m_dispatcherQueue.TryEnqueue(
            [strong = get_strong(), titles = std::move(titles)]() mutable
            {
                // UI 线程落地：更新可观察状态，绑定自动刷界面
                strong->m_viewModel.LoadFrom(single_threaded_vector(std::move(titles)));
                strong->LoadingText().Text(L"Finished");
                strong->RefreshButton().IsEnabled(true);
            });
    }
}
