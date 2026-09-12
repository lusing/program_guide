val root = StackPane()
root.style = "-fx-background-color: #f0f0f0"

val button1 = Button("Top")
val button2 = Button("Center")
val button3 = Button("Bottom")

StackPane.setAlignment(button1, Pos.TOP_CENTER)
StackPane.setAlignment(button2, Pos.CENTER)
StackPane.setAlignment(button3, Pos.BOTTOM_CENTER)

root.children.addAll(button1, button2, button3)
