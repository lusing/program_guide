package guide.android.examples

import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.Toast

// ---- 18 章第 2 节：迷你浏览器（现代默认配置）----

class Example27MiniBrowser : Activity() {
    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val input = EditText(this).apply {
            hint = "输入网址，如 example.com"
            setText("https://example.com")
        }
        webView = WebView(this).apply {
            settings.javaScriptEnabled = true          // 默认关，必须显式开
            settings.domStorageEnabled = true
            webViewClient = WebViewClient()            // 链接留在本 WebView，不跳系统浏览器
        }
        val go = Button(this).apply {
            text = "前往"
            setOnClickListener {
                var url = input.text.toString()
                if (!url.startsWith("http")) url = "https://$url"
                webView.loadUrl(url)
            }
        }
        setContentView(LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            addView(input, LinearLayout.LayoutParams(0,
                LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            addView(go)
            // 布局示意：真实工程里 WebView 在下方（此处省略挂载以聚焦逻辑）
        })
        webView.loadUrl(input.text.toString())
    }

    // AndroidX 工程里已被 OnBackPressedDispatcher 取代（预测性返回）；
    // 教学工程只挂 android.jar，保留传统覆写并显式标注
    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        if (webView.canGoBack()) webView.goBack() else super.onBackPressed()
    }
}

// ---- 18 章第 4 节：JS <-> Kotlin 双向桥 ----

class Example27JsBridge : Activity() {
    private lateinit var webView: WebView

    /** 暴露给 JS 的桥对象：只放 @JavascriptInterface 方法，成员最小化 */
    class Bridge(private val context: Context) {
        @JavascriptInterface                       // API 17 起强制：缺注解静默不可见
        fun showToast(msg: String) {
            Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        webView = WebView(this).apply {
            settings.javaScriptEnabled = true
            addJavascriptInterface(Bridge(applicationContext), "Android")   // 暴露成 JS 的 Android
        }
        setContentView(webView)
        loadBridgePage()
    }

    private fun loadBridgePage() {
        val html = """
            <html><body>
              <h3>JS Bridge Demo</h3>
              <button onclick="Android.showToast('来自网页的问候')">JS 调 Android</button>
              <script>
                function sayHi(from) {
                  Android.showToast('sayHi 收到：' + from);   // 回调里再过桥
                  return 'hi from js';
                }
              </script>
            </body></html>
        """.trimIndent()
        // 中文内容必须走 loadDataWithBaseURL（loadData 有乱码历史毛病）
        webView.loadDataWithBaseURL(null, html, "text/html", "utf-8", null)
    }

    override fun onResume() {
        super.onResume()
        // Kotlin -> JS：evaluateJavascript 带结果回调（JS 线程，勿直接碰 UI）
        webView.evaluateJavascript("sayHi('Android')") { value ->
            Log.d("JsBridge", "JS 返回：$value")
        }
    }
}
