import javafx.collections.FXCollections

val items = FXCollections.observableArrayList(
    "Apple", "Banana", "Cherry", "Date"
)

val listView = ListView(items)

listView.selectionModel.selectedItemProperty().addListener { _, _, newVal ->
    println("Selected: $newVal")
}

listView.setOnMouseClicked { event ->
    println("Clicked")
}
