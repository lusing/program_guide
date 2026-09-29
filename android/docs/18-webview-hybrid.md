# 18 · WebView 与混合开发

> 对应示例：`examples/27_webview_hybrid.kt`。取材：李刚《疯狂Android讲义（第3版）》13.4（WebView 三节）。08 章讲了"App 怎么发 HTTP"，本章讲"App 里怎么装一个浏览器，并让它和 Kotlin 互相说话"——混合开发的全部地基。

## 1. WebView 是什么

`WebView` 表面像个 ImageView，实际是**一个完整的 Chromium**（书 13.4 开篇的原话：5.0 起基于 Chromium M37）。渲染、JS 引擎、开发者工具一条龙——Android 系统浏览器与无数"套壳 App"都是它。且自 Android 5.0 起 WebView 作为系统组件随 Play 商店独立更新，不再绑死系统版本。

三个前提先立好：**`INTERNET` 权限**（Manifest）、**默认不开 JS**、**默认点链接跳系统浏览器**——后两个都要手工改，"WebView 用起来不对劲"九成是这两个默认值没动。

## 2. 五分钟迷你浏览器

书 13.4.1 的迷你浏览器（输入框 + WebView + `loadUrl`），补上现代默认配置后是这副样子（`Example27MiniBrowser`）：

```kotlin
val webView = WebView(this).apply {
    settings.javaScriptEnabled = true              // ① 默认关——现代网页没有 JS 基本残废
    settings.domStorageEnabled = true              // localStorage/sessionStorage
    webViewClient = WebViewClient()                // ② 关键：链接留在本 WebView 里跳
}
setContentView(webView)
webView.loadUrl("https://example.com")
```

**② 是新手第一坑**：不设 `webViewClient`，任何点击都甩给系统浏览器，你的 WebView 永远停在第一页。要精细控制再重写 `shouldOverrideUrlLoading(view, request)`——返回 true 表示"这个链接我自己处理"（拦截 scheme、外链跳浏览器都在这做）。返回键接历史：`onBackPressed { if (webView.canGoBack()) webView.goBack() else super }`。

`WebSettings` 常用开关速查：

| 开关 | 默认 | 说明 |
|---|---|---|
| `javaScriptEnabled` | false | JS 总闸 |
| `domStorageEnabled` | false | 网页存储 |
| `loadWithOverviewMode` / `useWideViewPort` | false | 按桌面宽度排版（viewport） |
| `setSupportZoom(true)` + `builtInZoomControls` | false | 双指缩放（记得 `displayZoomControls=false` 收掉那个老缩放按钮） |
| `mediaPlaybackRequiresUserGesture` | true | 视频自动播放要关它 |
| `mixedContentMode` | MIXED_CONTENT_NEVER_ALLOW | https 页里 http 资源的策略 |

## 3. 加载本地内容：三个入口与一个乱码坑

```kotlin
webView.loadData(html, "text/html", "utf-8")                  // 书里实测：中文乱码
webView.loadDataWithBaseURL(null, html, "text/html", "utf-8", null)   // 正解
webView.loadUrl("file:///android_asset/page.html")            // assets 静态页
```

书 13.4.2 的乱码结论至今成立：`loadData` 对非 ASCII 内容的编码处理有历史毛病，**带中文一律 `loadDataWithBaseURL`**（它还给出页面的基准 URL——相对路径资源、同源判断都以它为准，混合开发里常指向一个虚拟域）。**现代校准**：`file://` 直载正被官方劝退（安全与 CORS 怪癖），正门是 **WebViewAssetLoader**——把 assets 映射成 `https://appassets.androidplatform.net/` 域名，网页活在真实 https 语义里。

## 4. JS 与 Kotlin 互相说话

### JS → Kotlin：`addJavascriptInterface` + 注解

书 13.4.3 的三步（开 JS → 暴露对象 → 页面里调用）结构没变，但**安全模型换过血**：

```kotlin
webView.addJavascriptInterface(BridgeObject(this), "Android")   // 暴露成 JS 的 Android 对象

class BridgeObject(private val context: Context) {
    @JavascriptInterface                                 // API 17 起强制：没有注解的方法不可见
    fun showToast(msg: String) {
        Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
    }
}
```

页面侧一句 `Android.showToast("来自网页")` 即通。历史教训值得记：API 17 之前暴露的是**整个对象**，JS 经反射能摸到 Runtime 执行任意命令——当年大批 WebView 远程执行漏洞皆出于此，注解就是补丁。**所以纪律是：暴露对象里只放 @JavascriptInterface 标注的最小方法集，别的成员一概不给。**

### Kotlin → JS：`evaluateJavascript`

老代码的 `loadUrl("javascript:foo()")` 已被取代——`evaluateJavascript` 带结果回调（异步、跑在专用线程，**回调里不能直接碰 UI**）：

```kotlin
webView.evaluateJavascript("sayHi('Android')") { value ->
    Log.d("Bridge", "JS 返回：$value")     // JS 函数的返回值（序列化成字符串/JSON）
}
```

### 组合出双向桥

混合开发的经典需求"JS 调原生拿异步结果（如取相册、支付回调）"，用两条单向通道拼：JS 调 `Android.getPaymentToken(orderId)`，Kotlin 侧异步完成后 `post` 回 `evaluateJavascript("window.onToken('$token')")` 调 JS 的全局回调。JSBridge 容器（各厂 Hybrid 框架的核心）本质就是把这套回调管理规范化。

## 5. 两个 Client：页面级与浏览器级

WebView 把回调拆给两个类，分工是"网页的事"与"浏览器外壳的事"：

| | `WebViewClient`（页面级） | `WebChromeClient`（外壳级） |
|---|---|---|
| 管什么 | 加载跳转、错误、证书 | 进度、弹窗、文件选择、权限 |
| 常重写 | `shouldOverrideUrlLoading`、`onPageFinished`（注入 JS 的标准时机）、`onReceivedError`（自绘 404 页）、`onReceivedSslError`（**别无脑 proceed**） | `onProgressChanged`（进度条）、`onJsAlert/onJsConfirm`（js 三件套原生化）、`onShowFileChooser`（网页 `<input type=file>`）、`onPermissionRequest`（getUserMedia） |

进度条的经典接法：`WebChromeClient.onProgressChanged` 里 `progressBar.progress = newProgress`，`onPageFinished` 里藏条。

## 6. 会话、Cookie 与混合架构坐标

**CookieManager** 是 Cookie 的全局管家（WebView 不自动带：登录态打通全靠它）：

```kotlin
CookieManager.getInstance().apply {
    setAcceptCookie(true)              // 接受
    setAcceptThirdPartyCookies(webView, true)   // 三方 Cookie 单独开关（默认关）
    flush()                            // 持久化到磁盘——onPause 里 flush 是礼貌
}
```

**混合架构谱系**（认亲地图）：书时代的"WebView + JSBridge 容器"（13.5 的 Web Service/SOAP 是同代的另一支，XML 消息协议，今天已被 REST/JSON 全面取代）→ Cordova/Ionic（插件桥标准化）→ 小程序双线程（渲染层 WebView + 逻辑层 JS 引擎，通信全走序列化消息）→ 现代混合壳（WebView 承 H5、Compose 承原生，`AndroidView { WebView(it) }` 一行互操作，19 章）。**JSBridge 的双向通道（4 节）从 2013 到今天一字未变**——这是本章比看起来更"保值"的原因。

## 7. 安全校准：四条底线

1. **明文流量默认禁**（API 28 起）：`http://` 页面/资源直接被拒——要么上 https，要么 Manifest 显式 `usesCleartextTraffic="true"`（并自问为什么要）
2. **file 域默认锁**：`settings.allowFileAccess` 默认 false（API 30 起），file:// 页面再想读别的 file 是自找漏洞；本地内容走 3 节的 AssetLoader
3. **注入面最小化**：addJavascriptInterface 的对象只做薄转发，业务实现留在内部类后面；密码/ token 别经暴露方法传
4. **证书错误不无脑放行**：`onReceivedSslError` 里 `handler.proceed()` 一写，中间人检测等于关灯——默认 cancel 才对

## 8. 常见坑

**点链接跳到系统浏览器**：没设 `webViewClient`（2 节）。所有"WebView 只显示第一页"的 bug 第一嫌疑。

**JS 调原生方法没反应**：`javaScriptEnabled` 忘开；或方法缺 `@JavascriptInterface`（API 17+ 静默不可见——不报错，就是没有）。

**loadData 中文乱码**：换 `loadDataWithBaseURL`（3 节，书里同结论）。

**evaluateJavascript 回调里改 UI 崩溃**：回调在 JS 线程，回 UI 要 `post` 或 runOnUiThread（08 章三件套）。

**JS 桥泄漏 Activity**：暴露对象持着 Activity 引用，WebView 活得比页面久——暴露对象持 ApplicationContext，回 UI 再想办法；`onDestroy` 里 `webView.destroy()` 收尾。

**https 页面加载不出 http 图片**：mixedContentMode 默认拦截（2 节表）——该改资源协议就改协议，别惯着改开关。

**返回键直接退出 App**：没接 `canGoBack/goBack`——浏览器型页面的返回语义是网页历史优先。

## 9. 实战建议

- WebView 三件套默认化：**开 JS + 设 WebViewClient + 返回键接管**，起手就写全
- 桥接口按"能力"设计而不是按"页面"设计（`getUserInfo()` 而不是 `fillFormOfPage3()`），H5 侧封装一个 `native.call()` 收敛入口
- `onPageFinished` 是注入全局 JS（桥初始化、主题色、字体注入）的标准时机；`onProgressChanged >= 90` 做骨架屏切换更平滑
- 登录态打通优先让服务端 Set-Cookie + CookieManager 自动管理，手动 setCookie 只做兜底
- 本地 H5 离线包用 WebViewAssetLoader + 版本目录切换；别再走 file://
- 至此传统线收尾：19 章起进 Compose——WebView 在那里的形态是 `AndroidView` 一行互操作，混合思想不变，声明式换了一层皮

---
上一章：[17 桌面组件与系统管理器](17-appwidget-managers.md) ｜ 下一章：[19 Jetpack Compose 基础](19-compose-basics.md) ｜ 返回：[README](../README.md)
