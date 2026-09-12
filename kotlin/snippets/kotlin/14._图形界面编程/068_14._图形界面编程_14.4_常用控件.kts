import javafx.scene.control.TableColumn
import javafx.scene.control.cell.PropertyValueFactory

data class Person(val name: String, val age: Int, val email: String)

val people = FXCollections.observableArrayList(
    Person("Alice", 25, "alice@example.com"),
    Person("Bob", 30, "bob@example.com"),
    Person("Charlie", 35, "charlie@example.com")
)

val table = TableView(people)

val nameCol = TableColumn<Person, String>("Name")
nameCol.cellValueFactory = PropertyValueFactory("name")
nameCol.prefWidth = 150.0

val ageCol = TableColumn<Person, Int>("Age")
ageCol.cellValueFactory = PropertyValueFactory("age")
ageCol.prefWidth = 80.0

val emailCol = TableColumn<Person, String>("Email")
emailCol.cellValueFactory = PropertyValueFactory("email")
emailCol.prefWidth = 200.0

table.columns.addAll(nameCol, ageCol, emailCol)
table.prefWidth = 430.0
