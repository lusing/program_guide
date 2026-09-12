import javafx.scene.layout.BorderPane

val border = BorderPane()

// 顶部
val topBar = HBox(Label("Header"))
BorderPane.setAlignment(topBar, Pos.CENTER)
border.top = topBar

// 底部
val statusBar = HBox(Label("Status: Ready"))
BorderPane.setAlignment(statusBar, Pos.CENTER_LEFT)
border.bottom = statusBar

// 中间
val center = StackPane(Label("Main Content"))
border.center = center
