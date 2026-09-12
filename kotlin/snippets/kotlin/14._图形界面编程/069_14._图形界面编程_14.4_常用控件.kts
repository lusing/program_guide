val items = listOf("Java", "Kotlin", "Python", "JavaScript")
val comboBox = ComboBox(FXCollections.observableArrayList(*items.toArray()))

// 默认选中
comboBox.selectionModel.selectFirst()

// 监听选择
comboBox.setOnAction {
    println("Selected: ${comboBox.value}")
}
