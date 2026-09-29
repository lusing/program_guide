# 13 · 自定义 View 与绘图

> 对应示例：`examples/23_custom_view_drawing.kt`。取材：李刚《疯狂Android讲义（第3版）》2.1.5（自定义 View）、3.2–3.3（监听与回调）、7.1–7.3 与 7.7（绘图、特效、SurfaceView）、8.4.1（手势检测）。系统控件满足不了的界面，从这一章起自己画。

## 1. 自定义 View：三个回调撑起一切

自定义 View 最小只需继承 `View` 重写 `onDraw(canvas)`；完整的自定义控件要面对三个可重写的回调，分工是**测量、摆位、绘制**：

| 回调 | 谁调用 | 干什么 | 必须重写吗 |
|---|---|---|---|
| `onMeasure(widthMeasureSpec, heightMeasureSpec)` | 父容器 | 声明"我想要多大"（`setMeasuredDimension`） | 有固有尺寸时必须 |
| `onLayout(changed, l, t, r, b)` | 父容器 | **ViewGroup 才有意义**：摆孩子的位置 | 自定义容器时 |
| `onDraw(canvas)` | 系统 | 把自己画出来 | 几乎总是 |

`widthMeasureSpec` 是"尺寸 + 模式"的复合整数，模式三档：`EXACTLY`（match_parent/精确 dp）、`AT_MOST`（wrap_content）、`UNSPECIFIED`（父容器不管）。`View.resolveSize(想要的值, measureSpec)` 一行把"愿望"与"约束"协商成最终值——自定义 View 测量坑的头号来源就是无视 measureSpec 直接返回写死的尺寸。

书 2.1.5 的"跟随手指的小球"是最经典的第一课（`Example23FollowBall`）：

```kotlin
class FollowBallView(context: Context) : View(context) {
    private var x = 100f
    private var y = 100f
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {   // 抗锯齿从画笔建起就给
        color = 0xFF3366CC.toInt()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawCircle(x, y, 60f, paint)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        x = event.x                        // 跟随手指
        y = event.y
        invalidate()                       // 请求重绘 → 系统择机再调 onDraw
        return true                        // true = 消费，事件不再向上传播
    }
}
```

四条铁律藏在 12 行里：**状态用字段记，onDraw 只读不写**（每帧重画是常态）；**改状态后 `invalidate()`**（UI 线程）/ `postInvalidate()`（后台线程）；**`onTouchEvent` 返回 `true`** 才能持续收到后续 MOVE/UP；**onDraw 里不要 new 对象**（Paint/Path 提到字段）。

三个构造器的差异也在此立住：`View(context)` 代码创建用；`View(context, attrs)` XML inflate 走（12 章的 `obtainStyledAttributes` 在这里取自定义属性）；第三个带 defStyleAttr 的指定主题默认样式。

## 2. Canvas、Paint、Path：绘图三件套

`Canvas` 是画布（"依附"于 View 或 Bitmap），`Paint` 是画笔（风格），`Path` 是任意形状（点序列）。Canvas 常用方法按记忆块分组：

| 组 | 方法 |
|---|---|
| 几何 | `drawPoint/drawLine/drawRect/drawRoundRect/drawCircle/drawOval/drawArc` |
| 高级 | `drawPath(path, paint)`、`drawBitmap`、`drawText`、`drawTextOnPath` |
| 变换 | `rotate(deg, px, py)`、`scale(sx, sy, px, py)`、`skew`、`translate(dx, dy)` |
| 存取 | `save()` / `restore()`——变换前 save、画完 restore，配对使用 |
| 裁剪 | `clipRect` / `clipPath` |

Paint 的常用开关：`color`、`style`（`FILL`/`STROKE`/`FILL_AND_STROKE`）、`strokeWidth`、`textSize`、`isAntiAlias`、`shader`（6 节）、`pathEffect`、`setShadowLayer`（见 7 节的硬件加速限制）。

`Path` 记住三招就够日常：`moveTo` 落笔、`lineTo`/`quadTo`（二阶贝塞尔，圆滑曲线靠它）/`cubicTo` 连笔、`close` 闭合。配上 `PathEffect` 家族，一条线能玩出花（书 7.2.2 的七条对照线）：

| Effect | 效果 |
|---|---|
| `DashPathEffect(间距数组, 相位)` | 虚线；**相位变化 + 重绘 = 蚂蚁线动画** |
| `CornerPathEffect(半径)` | 拐角变圆 |
| `DiscretePathEffect(段长, 偏移)` | 随机抖动，手绘感 |
| `PathDashPathEffect(小形状, 间距, 相位)` | 用小形状当"笔尖"沿路径盖章 |
| `SumPathEffect` / `ComposePathEffect` | 两个效果叠加/组合 |

`canvas.drawTextOnPath(文本, path, hOffset, vOffset, paint)` 让文字沿路径排布——公告栏弯曲字幕的做法（`Example23Shapes` 演示）。

## 3. Bitmap 与 BitmapFactory

Bitmap 是像素的容器，四条解码入口 + 一套裁剪工具（书 7.1.2）：

```kotlin
BitmapFactory.decodeResource(resources, R.drawable.icon)   // 资源
BitmapFactory.decodeStream(assets.open("a.png"))            // 流（assets/网络）
BitmapFactory.decodeFile("/sdcard/img.png")                 // 文件路径
BitmapFactory.decodeByteArray(bytes, 0, bytes.size)         // 内存字节

Bitmap.createScaledBitmap(src, 120, 120, true)              // 缩放新图
Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)          // 造画布（双缓冲的主角）
```

**大图内存纪律**是这一节真正的现代重点（书写作时 4MB 堆时代更狠，今天原则不变）：

1. 解码前先用 `inJustDecodeBounds = true` 只量尺寸不解码像素，算出 `inSampleSize`（2 的幂），再正式解码——相机原图 4000×3000 直接进内存就是 48MB
2. `recycle()` 已是历史话题：API 11 起像素数据放 Java 堆、由 GC 管理，日常代码不需要再手动 recycle（读老代码看到它别慌，也别照抄进新代码）
3. 列表/网格场景直接上 Glide/Coil（26 章生态），它们把采样缓存线程全做了

## 4. Shader 与 Matrix：填充与变换

### Shader 四种填充

`Paint.shader` 决定"用什么东西填"，颜色只是最朴素的填充物（书 7.3.3）：

| Shader | 效果 | 构造要点 |
|---|---|---|
| `LinearGradient` | 线性渐变 | 起点、终点、两端颜色、TileMode |
| `RadialGradient` | 圆形渐变 | 圆心、半径、两端颜色 |
| `SweepGradient` | 角度渐变（雷达扫描） | 圆心、起止颜色 |
| `BitmapShader` | 位图平铺 | 位图 + `TileMode.REPEAT/MIRROR/CLAMP` |

`Example23Shaders` 四种全画。给文字加渐变、给圆形头像做填充（Paint 直接配 BitmapShader 画圆）都是这套。`ComposeShader` 把两个 Shader 用 PorterDuff 模式叠一起，见到名别陌生。

### Matrix 几何变换

Matrix 本身不画东西，它是"变换的账本"：`setTranslate/setRotate/setScale/setSkew`（**set 系列会清空之前的变换**，`postXxx`/`preXxx` 才是追加），应用到 `canvas.drawBitmap(bitmap, matrix, paint)` 上。注意 View 自己也有 `rotationX/translationY` 这些属性（14 章属性动画的目标），Matrix 主要用于**位图像素级**的变换。书里"移动游戏背景"的套路值得一记：`Bitmap.createBitmap(源图, x, y, w, h)` 定时挖取不同窗口，肉眼就是背景滚动——老 2D 游戏的标准技法。

`drawBitmapMesh` 是同一章的高阶玩具：把位图划成 mesh 网格，给每个网格顶点重设坐标实现"水波/揉动"——现代工程基本只在图像特效库里见到，认识即可（书 7.3.2 有完整"可揉动的图片"实现思路）。

## 5. 双缓冲与 SurfaceView

### 双缓冲

书 7.2.3 的手绘板讲透了两个机制：

1. **曲线是短线段的幻觉**：每次 MOVE 事件从上一点 `quadTo` 到当前点，肉眼看就是笔迹
2. **双缓冲**：直接画在 View 上，每次 onDraw 只画"最新一段"，旧笔迹全丢——所以先画进内存里的一张 `Bitmap`（缓冲区），onDraw 时把整张 Bitmap 贴上去

```kotlin
class HandDrawView(context: Context) : View(context) {
    private val path = Path()                                    // 本次笔迹
    private var preX = 0f
    private var preY = 0f
    private lateinit var cacheBitmap: Bitmap                      // 缓冲区：历史笔迹
    private lateinit var cacheCanvas: Canvas                      // 画在缓冲区上的画布
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE; strokeWidth = 6f; color = 0xFF222222.toInt()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        cacheBitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        cacheCanvas = Canvas(cacheBitmap)                         // Canvas 依附到缓冲位图
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> { preX = event.x; preY = event.y
                                         path.moveTo(preX, preY) }
            MotionEvent.ACTION_MOVE -> {
                path.quadTo(preX, preY, (event.x + preX) / 2f, (event.y + preY) / 2f)
                preX = event.x; preY = event.y
                cacheCanvas.drawPath(path, paint) }
        }
        invalidate()
        return true
    }

    override fun onDraw(canvas: Canvas) {
        canvas.drawBitmap(cacheBitmap, 0f, 0f, null)              // 缓冲区整体上屏
    }
}
```

（`Example23HandDraw` 的真身在此基础上补了 DOWN/MOVE 的控制点细节。）

### SurfaceView：另一条绘图通道

View 的 invalidate 走主线程消息循环，游戏要 60fps 连续重绘时主线程会被画屏吃光。**SurfaceView 自带一条独立绘图表面**：`SurfaceHolder` 暴露 `lockCanvas()` → 画 → `unlockCanvasAndPost()`，可以在任意线程跑游戏循环（书 7.7）：

```kotlin
class GameSurface(context: Context) : SurfaceView(context), SurfaceHolder.Callback {
    init { holder.addCallback(this) }

    override fun surfaceCreated(holder: SurfaceHolder) {
        thread {                                   // 游戏循环放后台线程
            while (true) {
                val canvas = holder.lockCanvas() ?: continue
                try { /* 按状态数据画一帧 */ } finally {
                    holder.unlockCanvasAndPost(canvas)
                }
                Thread.sleep(16)                   // ≈60fps
            }
        }
    }
    override fun surfaceChanged(h: SurfaceHolder, f: Int, w: Int, ih: Int) {}
    override fun surfaceDestroyed(h: SurfaceHolder) {}
}
```

选型表：

| | 普通 View + invalidate | SurfaceView |
|---|---|---|
| 线程 | 主线程 | **任意线程** |
| 适用 | 界面控件、低频重绘 | 游戏、相机预览、播放器、高频绘制 |
| 代价 | 简单、参与常规布局 | 独立表面叠在窗口下方（挖洞显示），Z 序与切孔有历史坑 |
| 现代替代 | — | **`TextureView`**（可变换的 View 内容）/ `SurfaceView` 仍为高性能首选 |

书里第 18 章整本用 SurfaceView 写了一个合金弹头——机制就是这一节 + 一个 while 循环 + 定时改坐标。

## 6. 事件：监听五形式、回调传播与手势

### 监听 vs 回调（书 3.2/3.3 的对偶）

05 章只用了"匿名内部类/lambda 监听"一种形态。书里把监听器实现形式列全了五种——**外部类、内部类、Activity 实现、匿名内部类、XML `android:onClick` 绑定**——Kotlin 时代答案简单：**lambda（SAM 转换）覆盖 95%，跨界面复用才独立成类**。XML onClick 至今能用但走反射查找方法，现代工程基本弃用。

回调是另一条通道：**继承组件重写 `onKeyDown`/`onTouchEvent`/`onTrackballEvent`，事件源自己就是处理器**。两条通道交汇出事件传播链（书 3.3.2 的经典实验，务必记牢）：

```text
触摸事件传播顺序：组件监听器 onTouchListener
  → 返回 false ↓
组件自身 onTouchEvent()
  → 返回 false ↓
容器逐层上抛 …
  → Activity.onTouchEvent()
```

**每级返回 `true` 即"完全消费"，链条截断**。这解释了两个日常怪象：自定义 View 里 `onTouchEvent` 忘了 return true，UP/MOVE 收不到；给 View 同时设 OnTouchListener 又重写 onTouchEvent，前者 return false 后者才会执行。Compose 时代链条被 `Modifier.pointerInput` 收敛成单点（25 章对照），但读存量自定义控件，这条传播链是底噪。

### GestureDetector：把手势翻译成语义

裸 onTouchEvent 只有 DOWN/MOVE/UP，"这是不是一次滑动/长按/双击"要自己算时间距离。`GestureDetector` 代劳（书 8.4.1），`OnGestureListener` 六个回调——`onDown`/`onShowPress`/`onSingleTapUp`（轻击）/`onScroll`（滚动，带位移增量）/`onFling`（甩，带速度）/`onLongPress`。固定搭配是**SimpleOnGestureListener 空实现打底，覆写需要的那个**：

```kotlin
private val detector = GestureDetector(context,
    object : GestureDetector.SimpleOnGestureListener() {
        override fun onScroll(e1: MotionEvent?, e2: MotionEvent, dx: Float, dy: Float): Boolean {
            offsetX -= dx; offsetY -= dy        // 拖动视图：减增量，不是设绝对值
            invalidate()
            return true
        }
        override fun onFling(e1: MotionEvent?, e2: MotionEvent, vx: Float, vy: Float): Boolean {
            Log.d("Gesture", "甩出速度 ($vx, $vy) px/s")   // 惯性滚动从这里起算
            return true
        }
    })

override fun onTouchEvent(event: MotionEvent): Boolean =
    detector.onTouchEvent(event)     // 事件转交检测器
```

双指缩放另有 `ScaleGestureDetector`（`onScale` 回调里读 `scaleFactor`），两台检测器可串在同一次 onTouchEvent 里喂。书里"手势库"（用户画图形存库识别，`GestureLibrary`）属冷门 API，读到认识即可。

## 7. 硬件加速时代的校准

书写作时软件绘制还是主流，今天默认全硬件加速（API 14+），三个校准：

1. **Canvas 不再直接面向屏幕**：View 的绘制先录成 DisplayList 再由 RenderThread 回放——所以 `onDraw` 里的对象分配、状态残留代价被放大，"字段持笔、onDraw 纯函数"从好习惯变成硬纪律
2. **个别 API 在硬件画布上无声失效**：`setShadowLayer` 只对文字生效，通用阴影要么 `setLayerType(LAYER_TYPE_SOFTWARE, null)` 退软件层（性能换效果），要么 elevation/9-patch；遇"画了没效果"先怀疑这一类
3. **invalidate 是合并的**：一帧内多次 invalidate 只触发一次 onDraw，别手动做节流

与 Compose 的对照：`DrawScope`（23 章）就是"Canvas+常驻 Paint"的封装——`drawCircle` 每次调用带参，状态由重组驱动而不是字段 + invalidate。学了本章，Compose Canvas 的 API 为什么长那样（`drawPath`、`rotate {}` 块对应 save/restore）一目了然。

## 8. 常见坑

**onTouchEvent 返回 super / false**：`super.onTouchEvent(event)` 对不可点击 View 返回 false——事件链断在 DOWN，后续 MOVE/UP 全收不到。自定义交互 View 直接 `return true`。

**onDraw 里 new Paint/Path**：每帧分配、GC 抖动、掉帧。画笔路径一律字段化，onDraw 只改参数。

**`wrap_content` 量出 0 或撑满**：没重写 onMeasure（或无视 measureSpec 直接 `setMeasuredDimension(固定值)`）。用 `resolveSize(固有尺寸, measureSpec)` 协商。

**在后台线程碰 View**：手绘板缓冲 Bitmap 后台画没问题（它不是 View），但 `invalidate()` 必须主线程调——后台用 `postInvalidate()`。`CalledFromWrongThreadException` 是这块的守门员。

**大图解码不采样**：`decodeResource` 一行炸 OOM 的日子在像素入堆后变成了"安静吃几百 MB"。列表头像 4000×3000 是事故，不是风格。

**Matrix 用 set 系列叠变换**：`setScale` 后再 `setRotate`，缩放丢了——set 覆盖整账本；连续变换用 `postXxx` 链。

**SurfaceView 忘了 unlockCanvasAndPost**：锁了画布不还，后续 lockCanvas 卡死。try/finally 是标配（如示例）。

**`save()`/`restore()` 不配对**：变换泄漏到后续绘制，界面越画越歪。每个 rotate/translate 块前 save、后 restore。

## 9. 实战建议

- 自定义控件骨架三件：字段持画笔 → onMeasure 协商尺寸 → onDraw 纯绘制；状态变更走"改字段 + invalidate"单行道
- 触摸交互优先 GestureDetector/ScaleGestureDetector，裸 MotionEvent 只留给画笔类应用
- 游戏级连续绘制用 SurfaceView + 独立线程循环；控件级用 View + invalidate；中间态（视频字幕叠加）看 TextureView
- 位图进内存前先 `inJustDecodeBounds` 量尺寸算 `inSampleSize`，显示尺寸是多少就解多大
- 学完这章立刻回头看 12 章 Drawable：ShapeDrawable/LayerDrawable 的底层正是本章 Canvas/Paint——"资源声明式"与"代码命令式"画的是同一个东西
- 14 章把这些"能动的东西"组织成体系：动画三体系全部建立在本章的 View 属性与 invalidate 机制上

---
上一章：[12 传统 View 深水区：布局、菜单与样式](12-views-deep.md) ｜ 下一章：[14 动画三体系](14-view-animations.md) ｜ 返回：[README](../README.md)
