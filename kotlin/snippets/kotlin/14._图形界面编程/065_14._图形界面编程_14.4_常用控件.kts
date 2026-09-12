val textField = TextField()
textField.promptText = "Enter your name"
textField.prefColumnCount = 20

textField.textProperty().addListener { _, _, newValue ->
    println("Text changed: $newValue")
}

val textArea = TextArea()
textArea.prefRowCount = 5
textArea.wrapText = true
