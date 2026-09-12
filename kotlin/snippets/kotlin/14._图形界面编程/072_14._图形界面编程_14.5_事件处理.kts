// 鼠标事件
button.setOnMouseClicked { event ->
    println("Click at: ${event.x}, ${event.y}")
    if (event.clickCount == 2) {
        println("Double click!")
    }
}

// 键盘事件
textField.setOnKeyPressed { event ->
    when (event.code) {
        KeyCode.ENTER -> println("Enter pressed")
        KeyCode.ESCAPE -> println("Escape pressed")
        else -> println("Key: ${event.code}")
    }
}

// 拖放事件
val draggable = Label("Drag Me")
draggable.setOnDragDetected { event ->
    val db = draggable.startDragAndDrop(TransferMode.MOVE)
    db.setContent(DataFormat.PLAIN_TEXT to draggable.text)
    event.consume()
}
