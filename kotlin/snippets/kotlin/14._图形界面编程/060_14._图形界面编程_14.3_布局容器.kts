import javafx.scene.layout.HBox

val hbox = HBox(20.0)  // 20px 间距
hbox.alignment = Pos.CENTER_LEFT

val btn1 = Button("OK")
val btn2 = Button("Cancel")
val btn3 = Button("Help")

hbox.children.addAll(btn1, btn2, btn3)
