class DrawingApp: Application() {
    private val canvas = Canvas(600.0, 400.0)
    private val graphics = canvas.graphicsContext2D

    private var lastX = 0.0
    private var lastY = 0.0
    private var isDrawing = false

    override fun start(stage: Stage) {
        graphics.stroke = Color.BLACK
        graphics.lineWidth = 2.0

        canvas.setOnMousePressed { event ->
            isDrawing = true
            lastX = event.x
            lastY = event.y
        }

        canvas.setOnMouseDragged { event ->
            if (isDrawing) {
                graphics.stroke = Color.BLACK
                graphics.strokeLine(lastX, lastY, event.x, event.y)
                lastX = event.x
                lastY = event.y
            }
        }

        canvas.setOnMouseReleased { isDrawing = false }

        val toolbar = HBox(10.0).apply {
            padding = Insets(10.0)
            children.addAll(
                createColorButton(Color.RED, "Red"),
                createColorButton(Color.BLUE, "Blue"),
                createColorButton(Color.GREEN, "Green"),
                Button("Clear").apply {
                    setOnAction { graphics.clearRect(0.0, 0.0, 600.0, 400.0) }
                }
            )
        }

        val root = BorderPane().apply {
            center = canvas
            top = toolbar
        }

        val scene = Scene(root, 600.0, 480.0)
        stage.title = "Drawing App"
        stage.scene = scene
        stage.show()
    }

    private fun createColorButton(color: Color, name: String): Button {
        return Button(name).apply {
            style = "-fx-background-color: ${color.web}; -fx-text-fill: white;"
            setOnAction { graphics.stroke = color }
        }
    }
}
