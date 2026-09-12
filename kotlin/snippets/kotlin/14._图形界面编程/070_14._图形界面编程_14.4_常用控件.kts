val progressBar = ProgressBar(0.0)
progressBar.prefWidth = 200.0

// 动画进度
val animate = Timeline(
    KeyFrame(Duration.seconds(0), KeyValue(progressBar.progressProperty(), 0.0)),
    KeyFrame(Duration.seconds(2), KeyValue(progressBar.progressProperty(), 1.0))
)
animate.cycleCount = Animation.INDEFINITE
animate.autoReverse = true
animate.play()

val progressIndicator = ProgressIndicator()
progressIndicator.progress = 0.5
progressIndicator.style = "-fx-scale-x: 2; -fx-scale-y: 2;"
