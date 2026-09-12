import javafx.scene.layout.VBox
import javafx.geometry.Pos

val vbox = VBox(10.0)  // 10px 间距
vbox.alignment = Pos.CENTER
vbox.padding = Insets(20.0)

val label = Label("Hello")
val textField = TextField()
val button = Button("Submit")

vbox.children.addAll(label, textField, button)
