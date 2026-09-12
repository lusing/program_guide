import javafx.application.Application
import javafx.scene.Scene
import javafx.scene.control.Button
import javafx.scene.layout.StackPane
import javafx.stage.Stage

class Main: Application() {
    override fun start(stage: Stage) {
        val button = Button("Click Me")
        button.setOnAction {
            println("Button clicked!")
        }

        val root = StackPane(button)
        val scene = Scene(root, 300.0, 200.0)

        stage.title = "Kotlin JavaFX"
        stage.scene = scene
        stage.show()
    }
}

fun main() {
    Application.launch(Main::class.java)
}
