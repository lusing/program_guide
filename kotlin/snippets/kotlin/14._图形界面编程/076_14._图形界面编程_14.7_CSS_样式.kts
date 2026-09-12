// 内联样式
button.style = """
    -fx-background-color: linear-gradient(to bottom, #1c6ba0, #145080);
    -fx-text-fill: white;
    -fx-font-size: 14px;
    -fx-padding: 8 16;
    -fx-border-radius: 4;
    -fx-background-radius: 4;
"""

button.hoverProperty().addListener { _, _, isHover ->
    if (isHover) {
        button.style = """
            -fx-background-color: linear-gradient(to bottom, #2a7cb5, #1d5f95);
        """
    } else {
        button.style = """
            -fx-background-color: linear-gradient(to bottom, #1c6ba0, #145080);
        """
    }
}
