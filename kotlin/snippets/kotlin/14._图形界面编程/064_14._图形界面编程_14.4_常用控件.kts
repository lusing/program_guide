val button = Button("Click Me")
button.style = """
    -fx-background-color: #007bff;
    -fx-text-fill: white;
    -fx-padding: 10 20;
    -fx-border-radius: 5;
"""

button.onAction = EventHandler {
    println("Button pressed")
}

// 禁用按钮
button.isDisabled = true
