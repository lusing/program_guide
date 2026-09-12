class CalculatorApp: Application() {
    private val display = TextField("0").apply {
        isEditable = false
        promptText = "0"
        style = "-fx-font-size: 24px; -fx-alignment: CENTER_RIGHT;"
    }

    private var currentOperation: String? = null
    private var previousValue: Double? = null

    override fun start(stage: Stage) {
        val root = BorderPane()

        root.top = display
        root.center = createGrid()

        val scene = Scene(root, 320.0, 400.0)
        scene.stylesheets.add(javaClass.getResource("/calculator.css").toExternalForm())

        stage.title = "Calculator"
        stage.scene = scene
        stage.isResizable = false
        stage.show()
    }

    private fun createGrid(): GridPane {
        val grid = GridPane()
        grid.hgap = 10.0
        grid.vgap = 10.0

        val buttons = listOf(
            listOf("7", "8", "9", "/"),
            listOf("4", "5", "6", "*"),
            listOf("1", "2", "3", "-"),
            listOf("0", ".", "=", "+")
        )

        for (row in buttons.indices) {
            for (col in buttons[row].indices) {
                val btn = Button(buttons[row][col])
                btn.styleClass.add("calculator-btn")

                btn.onAction = EventHandler {
                    handleButtonPress(btn.text)
                }
                grid.add(btn, col, row)
            }
        }

        val clearBtn = Button("C")
        clearBtn.styleClass.add("calculator-btn")
        clearBtn.onAction = EventHandler { display.text = "0" }
        grid.add(clearBtn, 4, 0)

        return grid
    }

    private fun handleButtonPress(value: String) {
        when (value) {
            in "0".."9" -> {
                if (display.text == "0") display.text = value
                else display.text = display.text + value
            }
            "." -> {
                if (!display.text.contains(".")) display.text = display.text + "."
            }
            in listOf("+", "-", "*", "/") -> {
                currentOperation = value
                previousValue = display.text.toDouble()
                display.text = "0"
            }
            "=" -> {
                val currentValue = display.text.toDouble()
                val result = when (currentOperation) {
                    "+" -> previousValue!! + currentValue
                    "-" -> previousValue!! - currentValue
                    "*" -> previousValue!! * currentValue
                    "/" -> previousValue!! / currentValue
                    else -> currentValue
                }
                display.text = result.toString()
                currentOperation = null
                previousValue = null
            }
        }
    }
}
