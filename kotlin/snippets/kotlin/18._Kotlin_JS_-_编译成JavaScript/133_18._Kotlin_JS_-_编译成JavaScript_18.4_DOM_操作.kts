import org.w3c.dom.*
import kotlinx.browser.document
import kotlinx.browser.window

fun main() {
    // 创建元素
    val div = document.createElement("div") as HTMLDivElement
    div.textContent = "Hello Kotlin/JS!"
    div.style.color = "blue"
    
    // 添加到页面
    document.body?.appendChild(div)
    
    // 事件监听
    val button = document.createElement("button") as HTMLButtonElement
    button.textContent = "Click me"
    button.addEventListener("click", {
        window.alert("Button clicked!")
    })
    
    document.body?.appendChild(button)
}
