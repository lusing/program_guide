import javafx.scene.control.*

// Alert 对话框
val alert = Alert(Alert.AlertType.INFORMATION)
alert.title = "Information"
alert.headerText = "Header Text"
alert.contentText = "Content Text"
alert.showAndWait()

// 确认对话框
val confirm = Alert(Alert.AlertType.CONFIRMATION)
confirm.title = "Confirm"
confirm.contentText = "Are you sure?"
val result = confirm.showAndWait()
if (result.isPresent && result.get().buttonData == ButtonBar.ButtonData.OK_DONE) {
    println("Confirmed")
}

// 输入对话框
val input = Dialog<String>()
input.title = "Input"
input.headerText = "Enter your name"
input.contentText = "Name:"

val nameField = TextField()
input.dialogPane.content = nameField

val okButton = ButtonType("OK", ButtonBar.ButtonData.OK_DONE)
input.buttonTypes.addAll(okButton, ButtonType.CANCEL)

val result = input.showAndWait()
if (result.isPresent) {
    println("Name: ${nameField.text}")
}

// 自定义对话框
class ColorPickerDialog: Dialog<Color>() {
    init {
        title = "Pick a Color"
        headerText = "Select a color"

        val colorPicker = ColorPicker(Color.RED)
        dialogPane.content = colorPicker

        val okButton = ButtonType("OK", ButtonBar.ButtonData.OK_DONE)
        dialogPane.buttonTypes.addAll(okButton, ButtonType.CANCEL)

        setResultConverter { button ->
            if (button == okButton) colorPicker.value else null
        }
    }
}
