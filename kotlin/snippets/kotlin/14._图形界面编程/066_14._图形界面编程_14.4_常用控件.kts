// CheckBox
val checkbox = CheckBox("Enable notifications")
checkbox.selected = true
checkbox.selectedProperty().addListener { _, _, newValue ->
    println("Checked: $newValue")
}

// RadioButton (单选)
val rb1 = RadioButton("Option 1")
val rb2 = RadioButton("Option 2")
val rb3 = RadioButton("Option 3")

val toggleGroup = ToggleGroup()
toggleGroup.buttons.addAll(rb1, rb2, rb3)

rb1.isSelected = true
