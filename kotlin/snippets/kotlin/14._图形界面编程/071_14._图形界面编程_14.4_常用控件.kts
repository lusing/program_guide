val slider = Slider(0.0, 100.0, 50.0)
slider.showTickLabels = true
slider.showTickMarks = true
slider.majorTickUnit = 25.0
slider.minorTickCount = 4

slider.valueProperty().addListener { _, _, newValue ->
    println("Slider value: $newValue")
}
