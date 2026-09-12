import javafx.scene.shape.*
import javafx.scene.paint.*

// 矩形
val rect = Rectangle(50.0, 50.0, 100.0, 80.0)
rect.fill = Color.LIGHTBLUE
rect.stroke = Color.DARKBLUE
rect.arcHeight = 10.0  // 圆角
rect.arcWidth = 10.0

// 圆形
val circle = Circle(50.0, Color.RED)
circle.centerX = 100.0
circle.centerY = 100.0
circle.stroke = Color.BLACK
circle.strokeWidth = 2.0

// 线条
val line = Line(10.0, 10.0, 200.0, 100.0)
line.stroke = Color.BLUE
line.strokeWidth = 3.0

// 多边形
val polygon = Polygon(
    100.0, 20.0,
    140.0, 80.0,
    60.0, 80.0
)
polygon.fill = Color.CHARTREUSE
polygon.stroke = Color.DARKGREEN

// 路径
val path = Path(
    MoveTo(50.0, 150.0),
    LineTo(100.0, 100.0),
    LineTo(150.0, 150.0),
    LineTo(200.0, 100.0)
)
path.stroke = Color.PURPLE
path.fill = null
