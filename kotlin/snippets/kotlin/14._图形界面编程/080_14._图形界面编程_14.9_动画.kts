import javafx.animation.*
import javafx.util.Duration

// 淡入动画
val fadeIn = FadeTransition(Duration.seconds(1), node)
fadeIn.fromValue = 0.0
fadeIn.toValue = 1.0
fadeIn.play()

// 缩放动画
val scale = ScaleTransition(Duration.seconds(0.5), node)
scale.fromX = 1.0
scale.fromY = 1.0
scale.toX = 1.2
scale.toY = 1.2
scale.autoReverse = true
scale.cycleCount = Animation.INDEFINITE
scale.play()

// 路径动画
val path = Path(
    MoveTo(0.0, 0.0),
    LineTo(100.0, 0.0),
    LineTo(100.0, 100.0)
)
val pathAnimation = PathTransition(Duration.seconds(2), path, circle)
pathAnimation.orientation = PathTransition.OrientationType.ORTHOGONAL_TO_TANGENT
pathAnimation.play()

// 逐帧动画
val frames = Timeline(
    KeyFrame(Duration.seconds(0), KeyValue(node.opacityProperty(), 0.0)),
    KeyFrame(Duration.seconds(0.5), KeyValue(node.opacityProperty(), 0.5)),
    KeyFrame(Duration.seconds(1), KeyValue(node.opacityProperty(), 1.0))
)
frames.play()
