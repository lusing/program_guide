import javafx.scene.layout.GridPane
import javafx.scene.control.Label
import javafx.scene.control.TextField
import javafx.scene.control.PasswordField

val grid = GridPane()
grid.hgap = 10.0
grid.vgap = 10.0
grid.padding = Insets(20.0)

grid.add(Label("Username:"), 0, 0)
val username = TextField()
grid.add(username, 1, 0)

grid.add(Label("Password:"), 0, 1)
val password = PasswordField()
grid.add(password, 1, 1)

val loginBtn = Button("Login")
GridPane.setHalignment(loginBtn, javafx.geometry.HPos.RIGHT)
grid.add(loginBtn, 1, 2)
