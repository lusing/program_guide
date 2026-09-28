# 40. WebView2：在 XAML 里嵌浏览器

> 对应《Learn WinUI 3》第 12 章的可 C++ 承接部分。书用 WebView2 承载 Blazor Wasm 应用（C# Web 框架）；**WebView2 本身与语言无关**——它是 Edge 的 Chromium 内核进程外承载，C++/WinRT 的 XAML 控件直接可用。本章做纯 C++ 的 Web 内容集成：导航、双向消息、脚本执行、本地内容。Blazor/Uno 侧见 [43 章](43-ecosystem.md)。

示例：`examples/40-webview-host`——URL 导航 + 内嵌 HTML 页 + 宿主↔页面双向消息 + 取页面标题。

## 40.1 WebView2 是什么

三层结构先立住：

```
你的进程                      WebView2 进程组（系统级，共享）
┌─────────────────┐          ┌──────────────────────────┐
│ WebView2 XAML 控件 │ ←COM→  │ msedgewebview2.exe (x N)  │
│ (Microsoft.UI.Xaml)│        │ Chromium 渲染 + JS 引擎    │
└─────────────────┘          └──────────────────────────┘
```

- **运行时**：WebView2 运行时随 Edge 分发（Win11 内置）。`CoreWebView2Initialized` 事件的 `Exception()` 非空 = 运行时缺失，应用要给降级路径。
- **进程模型**：页面跑在独立的 Edge 进程里，不是你的进程——**页面 JS 崩溃不崩宿主**；通信全部走 IPC（这就是"消息"的原因）。
- **控件 vs Core**：XAML 控件（`Microsoft::UI::Xaml::Controls::WebView2`）管布局与显示；`CoreWebView2` 对象管浏览器行为（设置、脚本、消息）。Core 在异步初始化完成后才可用。

## 40.2 最小骨架

```xml
<!-- examples/40-webview-host/MainWindow.xaml -->
<WebView2 x:Name="Web"
          CoreWebView2Initialized="OnCoreInitialized"
          NavigationCompleted="OnNavCompleted"
          WebMessageReceived="OnWebMessage"/>
```

```cpp
void MainWindow::OnCoreInitialized(
    IInspectable const&, Controls::CoreWebView2InitializedEventArgs const& args)
{
    if (args.Exception())                    // 运行时缺失/初始化失败的唯一暴露点
    {
        StatusText().Text(L"webview2 init failed (runtime installed?)");
        return;
    }
    Web().NavigateToString(LocalPageHtml()); // Core 就绪，开导航
}
```

**时序是本章第一坑**：`CoreWebView2()` 在初始化完成前是空引用。三条规则：

1. 要碰 Core 的代码放 `CoreWebView2Initialized` 事件里（如上），不要放构造函数。
2. 控件级便捷成员（`Source`、`NavigateToString`、`ExecuteScriptAsync`、`WebMessageReceived` 等）**转发到 Core**，但同样要初始化后才有效。
3. 纯 `Source="https://..."` 的 XAML 声明式导航可以放构造期——控件内部会排队到初始化后。

## 40.3 导航

```cpp
// 按地址栏跳转（40 例 OnGoClicked）
std::wstring address{ AddressBox().Text() };
if (address.rfind(L"http", 0) != 0) { address = L"https://" + address; }  // 补 scheme
try
{
    Web().Source(Windows::Foundation::Uri{ address });
}
catch (winrt::hresult_error const&) { StatusText().Text(L"invalid uri"); }
```

坑：**没有 scheme 的裸域名当相对路径处理，Uri 构造直接抛**。补 `https://` 是地址栏的标准姿势。`NavigationCompleted` 里 `args.IsSuccess()` 给结果，失败原因在 `args.WebErrorStatus()`。

`GoBack()/GoForward()/Reload()/CanGoBack()` 是控件自带的历史栈——桌面应用常见的"内嵌浏览器"工具条就是这几个属性 + 按钮 IsEnabled 直绑。

## 40.4 本地内容：NavigateToString 与虚拟主机

**字符串直灌**是最省事的本地路线（40 例用）：

```cpp
Web().NavigateToString(LocalPageHtml());   // 一个 hstring 的完整 HTML
```

适用：帮助页、协议展示、模板渲染。**限制**：无相对资源（图片/JS 文件不能引用本地路径）、字符串大小有实际上限（几 MB 级）。

**虚拟主机映射**是文件级路线（教程未铺，签名在此）：

```cpp
Web().CoreWebView2().SetVirtualHostNameToFolderMapping(
    L"app.local", folderPath,
    CoreWebView2HostResourceAccessKind::Allow);
Web().Source(Windows::Foundation::Uri{ L"https://app.local/index.html" });
```

把磁盘目录映射成 `https://app.local/`——页面里的相对引用、fetch、甚至 IndexedDB 都按同源规则工作。**要发正式 Web 资产的应用用这条**，`NavigateToString` 只够演示。

## 40.5 宿主 → 页面：执行脚本与发消息

两条完全不同的通道，语义别混：

**ExecuteScriptAsync——侵入执行**（宿主把 JS 塞进页面跑，拿到返回值）：

```cpp
winrt::Windows::Foundation::IAsyncAction MainWindow::RunTitleScriptAsync()
{
    auto lifetime = get_strong();
    // 返回值是 JSON 编码的字符串："My page" 带引号——要显示得自己剥
    winrt::hstring result = co_await Web().ExecuteScriptAsync(L"document.title");
    StatusText().Text(std::wstring{ L"script -> " } + std::wstring_view{ result });
}
```

**PostWebMessageAsJson——消息通信**（页面自愿监听，宿主不碰页面内部）：

```cpp
Web().CoreWebView2().PostWebMessageAsJson(L"{ \"from\": \"winrt host\", \"n\": 42 }");
```

裁决：**读页面的数据（爬自己的嵌入页）用脚本；驱动页面行为（通知它宿主事件）用消息**。脚本通道的返回值永远是 JSON 编码（字符串带引号、数字裸、对象序列化）——剥壳是调用方的事。

## 40.6 页面 → 宿主：WebMessageReceived

页面侧的桥是 WebView2 注入的 `window.chrome.webview` 对象——**这是宿主与页面之间的全部 API 面**：

```html
<script>
  function send() {
    // 页面 -> 宿主
    window.chrome.webview.postMessage(document.getElementById('msg').value);
  }
  // 宿主 -> 页面
  window.chrome.webview.addEventListener('message', function (e) {
    document.getElementById('out').textContent = e.data;
  });
</script>
```

宿主侧接收：

```cpp
void MainWindow::OnWebMessage(
    IInspectable const&, CoreWebView2WebMessageReceivedEventArgs const& args)
{
    // 字符串消息与 JSON 消息分两个读取口：
    StatusText().Text(std::wstring{ L"message from page: " } +
        std::wstring_view{ args.TryGetWebMessageAsString() });   // WebMessageAsJson() 是另一个
}
```

**消息内容是完全不可信的输入**——页面可能被 XSS 或就是第三方页。40 例只回显；真实工程要在 handler 里做校验/白名单，与处理任何进程外输入同级对待。

## 40.7 设置与能力（速查）

`Web().CoreWebView2().Settings()` 常用开关：`AreDevToolsEnabled`（F12，发布版关）、`AreDefaultContextMenusEnabled`、`IsZoomControlEnabled`、`UserAgent`。 профиль级（Cookie/缓存隔离）在 `EnsureCoreWebView2Configuration` 的 `CoreWebView2EnvironmentOptions`——同一应用多账号场景用不同 profile 互不污染。**这些都在 Core 上，记得 40.2 的时序**。

## 40.8 与 Blazor 托管的关系（书 12 章的另一半）

书 12 章的完整链路是"Blazor Wasm 应用部署到 Azure Static Web Apps → WinUI 里 WebView2 指向该 URL"。**这条链路对 C++ 宿主同样成立**：WebView2 不关心 URL 背后是静态文件还是 Blazor——把 `Source` 指向部署好的站点即可，离线 PWA 语义也照收。变的只是"你不能用 Blazor 写那个 Web 应用"（.NET 专属）；Web 侧用任意 JS 框架（React/Vue/原生）都行，宿主协议就是本章的 postMessage/脚本两条通道。43 章把这条"混合 Web+原生"路线与 Uno 等其它混合方案放在一起对比。

## 40.9 实测坑位（本章新增）

1. **`CoreWebView2()` 空引用**是时序坑的表象——初始化完成前访问（包括控件级转发的 `ExecuteScriptAsync`）直接崩。统一在 `CoreWebView2Initialized` 之后才碰。
2. **`ExecuteScriptAsync` 返回 JSON 编码**——`"title"` 带引号，直接显示会多一对引号。
3. **无 scheme 的 Uri 抛异常**——地址栏输入先补 `https://`。
4. **`NavigateToString` 的 HTML 里引号嵌套**——用 C++ 原始字符串字面量 `LR"-( ... )-"` 包整页，避免转义地狱。
5. **页面发消息的对象经过 JSON 序列化**：`postMessage(obj)` 到宿主是 `WebMessageAsJson()`，`postMessage(string)` 才是 `TryGetWebMessageAsString()`——发方收方要对准同一个口。
6. `window.chrome.webview` **只在 WebView2 里存在**——页面在普通浏览器调试时这行是 undefined，页面代码要判空（`if (window.chrome?.webview)`）。

## 40.10 练习与思考

1. 给 40 例加 GoBack/GoForward 按钮，`IsEnabled` 直绑 `Web().CanGoBack()`（需要 `SourceChanged` 或轮询——想想为什么没有 `CanGoBackChanged` 事件？）。
2. 用 `SetVirtualHostNameToFolderMapping` 把 `docs/` 目录映射成 `https://docs.local/`，用 WebView2 浏览本教程的 markdown 渲染产物。
3. 让页面把 `navigator.userAgent` 发回宿主（postMessage），对比宿主进程的 `GetVersionForSelf`——两边的"身份"为什么不同？
4. 思考：`AddScriptToExecuteOnDocumentCreatedAsync`（Core 上）与 `ExecuteScriptAsync` 的执行时机差异，哪个适合"给每个页面注入宿主桥"？
