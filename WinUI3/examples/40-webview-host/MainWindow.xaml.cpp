#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
using namespace Microsoft::Web::WebView2::Core;

namespace winrt::WebViewHost::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"WebViewHost");

        // 构造期自定位（31.5.2），逻辑单位（40 章示例照抄 37/34 的尺寸）
        if (auto appWindow = AppWindow())
        {
            appWindow.MoveAndResize(Windows::Graphics::RectInt32{ 30, 30, 1080, 620 });
        }
    }

    void MainWindow::OnCoreInitialized(
        IInspectable const&, Controls::CoreWebView2InitializedEventArgs const& args)
    {
        // 初始化失败（如没装 WebView2 运行时）在此暴露
        if (args.Exception())
        {
            StatusText().Text(L"webview2 init failed (runtime installed?)");
            return;
        }

        // 页面就绪后立刻导航到内嵌 HTML：NavigateToString 是本地内容最省事的
        // 路线（正式站点用 SetVirtualHostNameToFolderMapping，见 40 章）
        Web().NavigateToString(LocalPageHtml());
        StatusText().Text(L"webview2 ready -> local page");
    }

    void MainWindow::OnNavCompleted(
        IInspectable const&, CoreWebView2NavigationCompletedEventArgs const& args)
    {
        if (args.IsSuccess())
        {
            StatusText().Text(std::wstring{ L"navigated: " } +
                Web().Source().AbsoluteUri().c_str());
        }
        else
        {
            StatusText().Text(L"navigation failed");
        }
    }

    void MainWindow::OnGoClicked(IInspectable const&, RoutedEventArgs const&)
    {
        std::wstring address{ AddressBox().Text() };
        if (address.empty()) { return; }

        // 无 scheme 时补 https://，否则 Uri 解析当相对路径抛异常
        if (address.rfind(L"http", 0) != 0)
        {
            address = L"https://" + address;
        }
        try
        {
            Web().Source(Windows::Foundation::Uri{ address });
            StatusText().Text(std::wstring{ L"loading " } + address);
        }
        catch (winrt::hresult_error const&)
        {
            StatusText().Text(L"invalid uri");
        }
    }

    void MainWindow::OnAddressKeyDown(
        IInspectable const&, Input::KeyRoutedEventArgs const& args)
    {
        if (args.Key() == Windows::System::VirtualKey::Enter)
        {
            OnGoClicked(nullptr, nullptr);
            args.Handled(true);
        }
    }

    void MainWindow::OnLocalClicked(IInspectable const&, RoutedEventArgs const&)
    {
        Web().NavigateToString(LocalPageHtml());
    }

    void MainWindow::OnScriptClicked(IInspectable const&, RoutedEventArgs const&)
    {
        (void)RunTitleScriptAsync();
    }

    winrt::Windows::Foundation::IAsyncAction MainWindow::RunTitleScriptAsync()
    {
        auto lifetime = get_strong();
        // 返回值是 JSON 编码的字符串："My page" 带引号
        winrt::hstring result = co_await Web().ExecuteScriptAsync(L"document.title");
        StatusText().Text(std::wstring{ L"script -> " } + result.c_str());
    }

    void MainWindow::OnPostClicked(IInspectable const&, RoutedEventArgs const&)
    {
        // 宿主 -> 页面：PostWebMessageAsJson 触发页面里的 message 监听器
        Web().CoreWebView2().PostWebMessageAsJson(L"{ \"from\": \"winrt host\", \"n\": 42 }");
        StatusText().Text(L"posted json to page");
    }

    void MainWindow::OnWebMessage(
        IInspectable const&, CoreWebView2WebMessageReceivedEventArgs const& args)
    {
        // 页面 -> 宿主：字符串消息走 TryGetWebMessageAsString，JSON 走 WebMessageAsJson
        StatusText().Text(std::wstring{ L"message from page: " } +
            args.TryGetWebMessageAsString().c_str());
    }

    winrt::hstring MainWindow::LocalPageHtml() const
    {
        return LR"-(<html>
<body style="font-family:Segoe UI;background:#f3f3f3;margin:24px">
  <h3 id="title">WebView2 local page</h3>
  <p>This page arrived via <code>NavigateToString</code> - no server, no virtual host.</p>
  <input id="msg" value="hello from html"/>
  <button onclick="send()">postMessage to host</button>
  <p>host says: <b id="out">(nothing yet)</b></p>
  <script>
    function send() {
      // 页面 -> 宿主：window.chrome.webview 是 WebView2 注入的桥
      window.chrome.webview.postMessage(document.getElementById('msg').value);
    }
    // 宿主 -> 页面
    window.chrome.webview.addEventListener('message', function (e) {
      document.getElementById('out').textContent = e.data;
    });
  </script>
</body>
</html>)-";
    }
}
