// 29_winrt_modern — 从 Win32 控制台调用 WinRT（C++/WinRT 投影 + C++20 协程）
//
// 对应教程：docs/26-WinRT与CppWinRT.md
// 本示例由 29_winrt_modern/build.ps1 构建（额外带 cppwinrt 头与 WindowsApp.lib）
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Globalization.DateTimeFormatting.h>
#include <winrt/Windows.System.Threading.h>
#include <stdio.h>
#include <locale.h>

namespace wf = winrt::Windows::Foundation;

// C++20 协程消费 WinRT 异步：co_await 一个 IAsyncAction
static wf::IAsyncAction WorkAsync() {
    co_await winrt::Windows::System::Threading::ThreadPool::RunAsync(
        [](auto&&) { /* 工作项在线程池上执行（此处空转演示） */ });
}

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // WinRT 版的 CoInitializeEx
    winrt::init_apartment(winrt::apartment_type::single_threaded);

    // 1) 投影类型：像普通 C++ 类一样用系统组件
    using namespace winrt::Windows::Globalization::DateTimeFormatting;
    DateTimeFormatter date{ L"{year.full} 年 {month.integer(2)} 月 {day.integer(2)} 日" };
    DateTimeFormatter time{ L"{hour.integer(2)}:{minute.integer(2)}:{second.integer(2)}" };
    auto now = winrt::clock::now();
    wprintf(L"[1] 今天：%s\n", date.Format(now).c_str());
    wprintf(L"    现在：%s（格式化由系统组件完成，不是我们写的）\n",
            time.Format(now).c_str());

    // 2) 协程异步：提交线程池工作并等待
    wprintf(L"[2] 提交线程池工作并 co_await ...\n");
    auto action = WorkAsync();
    action.get();               // 阻塞等完成（真实程序里会继续 co_await）
    wprintf(L"    工作完成\n");

    wprintf(L"演示结束（没有手工引用计数——投影全托管了）\n");
    return 0;
}
