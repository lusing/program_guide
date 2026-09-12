// 通过 ID 获取
val element = document.getElementById("my-id") as? HTMLElement

// 通过类名获取
val elements = document.getElementsByClassName("my-class")

// 修改属性
element?.style?.backgroundColor = "#f0f0f0"
element?.setAttribute("data-value", "123")

// 修改内容
element?.innerHTML = "<b>Bold text</b>"
element?.textContent = "Plain text"
