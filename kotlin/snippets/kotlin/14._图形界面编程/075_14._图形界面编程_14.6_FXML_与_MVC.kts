// Main App
class App: Application() {
    override fun start(stage: Stage) {
        val loader = FXMLLoader(javaClass.getResource("/MainView.fxml"))
        val root = loader.load<Parent>()

        val scene = Scene(root, 600.0, 400.0)
        stage.scene = scene
        stage.show()
    }
}
