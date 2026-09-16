#include "pch.h"
#include "MainWindow.xaml.h"
#include "ToolService.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::OsIntApp::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        // 在 UI 线程上抓取 UI 队列，供后台线程回流（docs/10 10.1）
        m_dispatcherQueue = Microsoft::UI::Dispatching::DispatcherQueue::GetForCurrentThread();
    }

    void MainWindow::OnShowPathClicked(IInspectable const&, RoutedEventArgs const&)
    {
        try
        {
            // 两个类型都叫 ApplicationData，写全限定避免 using 歧义（docs/10 10.2.1）
            winrt::hstring local =
                winrt::Microsoft::Windows::Storage::ApplicationData::GetDefault().LocalPath();
            StatusText().Text(local);
        }
        catch (winrt::hresult_error const&)
        {
            // 本机 1.8 实测：非打包进程调 GetDefault() 同样抛"该进程没有程序包标识符"，
            // 并非文档所说的回退目录。非打包就用普通文件系统目录。
            wchar_t buffer[MAX_PATH]{};
            DWORD len = GetEnvironmentVariableW(L"LOCALAPPDATA", buffer, MAX_PATH);
            StatusText().Text(len
                ? winrt::hstring{ std::wstring(buffer, len) + L"\\OsIntApp" }
                : winrt::hstring{ L"no app data directory available" });
        }
    }

    void MainWindow::OnPickClicked(IInspectable const&, RoutedEventArgs const&)
    {
        (void)PickFileAsync();
    }

    winrt::Windows::Foundation::IAsyncAction MainWindow::PickFileAsync()
    {
        // 窗口归属通过构造函数的 WindowId 传入：AppWindow().Id() 就是这个窗口的 WindowId
        // （docs/10 10.2.2）
        winrt::Microsoft::Windows::Storage::Pickers::FileOpenPicker picker{ AppWindow().Id() };
        picker.FileTypeFilter().Append(L".json");

        auto result = co_await picker.PickSingleFileAsync();
        if (!result) { co_return; }               // 用户取消

        // 新 picker 只给字符串路径，不再返回 StorageFile
        StatusText().Text(result.Path());
    }

    void MainWindow::OnRunToolClicked(IInspectable const&, RoutedEventArgs const&)
    {
        StatusText().Text(L"running...");

        // 回调里持 DispatcherQueue + 自身引用；jthread 生命周期短（一次子进程等待），
        // 长命线程才需要 weak_ref 断环（docs/10 10.5）
        auto strong = get_strong();
        auto queue = m_dispatcherQueue;

        m_worker = std::jthread([strong, queue](std::stop_token st)
        {
            // 后台线程要碰 WinRT 对象就必须先加入 MTA
            winrt::init_apartment(winrt::apartment_type::multi_threaded);

            DWORD exitCode{};
            bool ok = RunTool(L"cmd.exe /c exit 0", exitCode);
            if (st.stop_requested()) { return; }

            // TryEnqueue 返回 false 说明 UI 队列已关闭（进程正在退出）
            queue.TryEnqueue([strong, ok, exitCode]
            {
                strong->ReportToolResult(ok, exitCode);
            });
        });
    }

    void MainWindow::ReportToolResult(bool ok, DWORD exitCode)
    {
        StatusText().Text(ok
            ? winrt::hstring{ L"tool succeeded" }
            : winrt::hstring{ L"tool failed, exit/win32 code = " + std::to_wstring(exitCode) });
    }
}
