// MainViewController.kt
open class MainViewController {
    @javafx.fxml.FXML
    private lateinit var statusLabel: Label

    @javafx.fxml.FXML
    private fun initialize() {
        statusLabel.text = "Ready"
    }

    @javafx.fxml.FXML
    private fun handleOk() {
        statusLabel.text = "OK clicked"
    }

    @javafx.fxml.FXML
    private fun handleCancel() {
        statusLabel.text = "Cancel clicked"
    }

    @javafx.fxml.FXML
    private fun handleExit() {
        Platform.exit()
    }
}
