package guide.android.examples

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.Shader
import android.graphics.SweepGradient
import android.os.Bundle
import android.util.Log
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import kotlin.concurrent.thread

// ---- 13 章第 1 节：跟随手指的小球（自定义 View 最小完整版）----

class FollowBallView(context: Context) : View(context) {
    private var x = 100f
    private var y = 100f
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF3366CC.toInt()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        // wrap_content 与父约束协商：愿望 200px 见方
        setMeasuredDimension(
            resolveSize(200, widthMeasureSpec),
            resolveSize(200, heightMeasureSpec)
        )
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawCircle(x, y, 40f, paint)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        x = event.x
        y = event.y
        invalidate()
        return true
    }
}

class Example23FollowBall : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(FollowBallView(this))
    }
}

// ---- 13 章第 2 节：Path、PathEffect 与沿路径文字 ----

class ShapesView(context: Context) : View(context) {
    private val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 6f
        color = 0xFF2255AA.toInt()
    }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textSize = 40f
        color = 0xFF664400.toInt()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        // 虚线：相位变化 + 重绘即蚂蚁线动画
        stroke.pathEffect = DashPathEffect(floatArrayOf(24f, 12f, 48f, 12f), 0f)
        val wave = Path().apply {
            moveTo(40f, 120f)
            quadTo(240f, 40f, 440f, 120f)          // 二阶贝塞尔
            quadTo(640f, 200f, 840f, 120f)
        }
        canvas.drawPath(wave, stroke)
        // 沿路径排文字
        canvas.drawTextOnPath("沿着贝塞尔曲线排布的文字", wave, 0f, -12f, textPaint)
    }
}

class Example23Shapes : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(ShapesView(this))
    }
}

// ---- 13 章第 4 节：Shader 四种填充 ----

class ShaderView(context: Context) : View(context) {
    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private lateinit var tileShader: BitmapShader

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        // 位图平铺的素材：32x32 棋盘格
        val tile = Bitmap.createBitmap(32, 32, Bitmap.Config.ARGB_8888)
        Canvas(tile).apply {
            drawColor(Color.LTGRAY)
            val cell = Paint().apply { color = Color.DKGRAY }
            drawRect(0f, 0f, 16f, 16f, cell)
            drawRect(16f, 16f, 32f, 32f, cell)
        }
        tileShader = BitmapShader(tile, Shader.TileMode.REPEAT, Shader.TileMode.REPEAT)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val quarter = w / 4f
        fill.shader = LinearGradient(0f, 0f, quarter, h, 0xFF3366CC.toInt(),
            0xFFCCFF99.toInt(), Shader.TileMode.CLAMP)
        canvas.drawRect(0f, 0f, quarter, h, fill)

        fill.shader = RadialGradient(quarter * 1.5f, h / 2f, quarter,
            Color.YELLOW, Color.TRANSPARENT, Shader.TileMode.CLAMP)
        canvas.drawRect(quarter, 0f, quarter * 2, h, fill)

        fill.shader = SweepGradient(quarter * 2.5f, h / 2f, Color.RED, Color.BLUE)
        canvas.drawRect(quarter * 2, 0f, quarter * 3, h, fill)

        fill.shader = tileShader
        canvas.drawRect(quarter * 3, 0f, w, h, fill)
    }
}

class Example23Shaders : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(ShaderView(this))
    }
}

// ---- 13 章第 5 节：双缓冲手绘板 ----

class HandDrawView(context: Context) : View(context) {
    private val path = Path()
    private var preX = 0f
    private var preY = 0f
    private lateinit var cacheBitmap: Bitmap
    private lateinit var cacheCanvas: Canvas
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 6f
        color = 0xFF222222.toInt()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        cacheBitmap = Bitmap.createBitmap(w.coerceAtLeast(1), h.coerceAtLeast(1),
            Bitmap.Config.ARGB_8888)
        cacheCanvas = Canvas(cacheBitmap)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                preX = event.x; preY = event.y
                path.moveTo(preX, preY)
            }
            MotionEvent.ACTION_MOVE -> {
                path.quadTo(preX, preY, (event.x + preX) / 2f, (event.y + preY) / 2f)
                preX = event.x; preY = event.y
                cacheCanvas.drawPath(path, paint)
            }
        }
        invalidate()
        return true
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawBitmap(cacheBitmap, 0f, 0f, null)      // 缓冲区整体上屏
    }
}

class Example23HandDraw : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(HandDrawView(this))
    }
}

// ---- 13 章第 6 节：GestureDetector 把触摸翻成语义 ----

class GestureBallView(context: Context) : View(context) {
    private var cx = 200f
    private var cy = 200f
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xFFAA3366.toInt() }
    private val detector = GestureDetector(context,
        object : GestureDetector.SimpleOnGestureListener() {
            override fun onScroll(e1: MotionEvent?, e2: MotionEvent, dx: Float, dy: Float): Boolean {
                cx -= dx            // 滚动给的是增量，方向取反即"跟手拖动"
                cy -= dy
                invalidate()
                return true
            }

            override fun onFling(e1: MotionEvent?, e2: MotionEvent, vx: Float, vy: Float): Boolean {
                Log.d("GestureBall", "fling velocity=($vx, $vy)")
                return true
            }
        })

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawCircle(cx, cy, 48f, paint)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean = detector.onTouchEvent(event)
}

class Example23GestureBall : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(GestureBallView(this))
    }
}

// ---- 13 章第 5 节：SurfaceView 独立线程游戏循环 ----

class SurfaceLoopView(context: Context) : SurfaceView(context), SurfaceHolder.Callback {
    @Volatile private var running = false
    private var ballX = 100f
    private var ballY = 200f
    private var dx = 8f

    init {
        holder.addCallback(this)
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        running = true
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xFF3366CC.toInt() }
        thread(name = "game-loop") {
            while (running) {
                val canvas = holder.lockCanvas() ?: continue
                try {
                    ballX += dx
                    if (ballX > canvas.width - 40 || ballX < 40) dx = -dx
                    canvas.drawColor(Color.WHITE)
                    canvas.drawCircle(ballX, ballY, 40f, paint)
                } finally {
                    holder.unlockCanvasAndPost(canvas)
                }
                Thread.sleep(16)          // ≈60fps
            }
        }
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {}

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        running = false                   // 通知循环退出，线程自然收尾
    }
}

class Example23Surface : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(SurfaceLoopView(this))
    }
}
