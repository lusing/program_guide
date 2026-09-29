# 14 · 动画三体系

> 对应示例：`examples/24_view_animations.kt`。取材：李刚《疯狂Android讲义（第3版）》7.4–7.6（逐帧/补间/属性动画）与 6.5（属性动画资源）。05 章第 5 节给过属性动画的敲门砖，本章把传统 View 世界的三套动画体系一次讲全——它们至今活在每个存量工程里。

## 1. 三体系总览

"Android 动画"其实是三个时代叠出来的三层，API 名字很容易混，先立总表：

| 体系 | 核心 API | 本质 | 引入 | 现状 |
|---|---|---|---|---|
| 逐帧 Frame | `AnimationDrawable` | N 张图轮播（放电影） | API 1 | 活着；loading 动图、游戏爆炸 |
| 补间 Tween（视图动画 View Animation） | `AlphaAnimation` 等四类 + `AnimationSet` | 只算"画在哪"，**不改真属性** | API 1 | 存量巨大；新代码基本被属性动画取代 |
| 属性 Property | `ValueAnimator`/`ObjectAnimator`/`AnimatorSet` | 每帧真的调 setter 改属性 | API 11 | **现代主力**；Compose 之外的标准答案 |

一句话分水岭（05 章讲过，值得再敲一次）：**补间动画把变化"画"在屏幕上，控件的真实位置与点击区域纹丝不动；属性动画改的是对象真实的属性值**。列表项补间位移后点不中、控件"看起来走了人还在原地"，都是补间的经典事故。

三套体系共享两个概念：**Interpolator（插值器）**决定"时间进度的几分之几该到哪个值"（匀速/加速/回弹都是它的事），**duration 毫秒**。属性动画的插值接口叫 `TimeInterpolator`，补间叫 `Interpolator`——历史包袱，同一个思想。

## 2. 逐帧动画：AnimationDrawable

逐帧就是"图片播放器"：帧序列 + 每帧时长（书 7.4）。XML 形态（`res/anim/` 或 `drawable/`，根元素 `<animation-list>`）：

```xml
<animation-list xmlns:android="http://schemas.android.com/apk/res/android"
    android:oneshot="false">
    <item android:drawable="@drawable/f1" android:duration="80" />
    <item android:drawable="@drawable/f2" android:duration="80" />
</animation-list>
```

代码等价物在 12 章见过：`addFrame(drawable, 80)` 加帧、`isOneShot = false` 循环。挂到 `ImageView.background`（或 src）后**必须显式 `start()`**——这是逐帧动画第一坑；第二坑更隐蔽：**AnimationDrawable 不能在还没挂载的 View 上启动**，`onCreate` 里紧跟 `setBackgroundResource` 就 `start()` 是静默不播的，要 `view.post { anim.start() }` 等一帧（书里的实例都要等按钮触发，天然避开了这个坑）。`stop()` 后再 `start()` 从头播；判尾自动隐藏（书"在指定点爆炸"的 `setVisible` 技巧）在 oneShot 场景才需要操心。

爆炸、说话的嘴、闪电——凡是美术能给全套序列帧的需求，逐帧都是最省事的答案。

## 3. 补间动画：四类变换 + Interpolator

补间（tween）= 你只给**关键帧**（起止状态），系统"补"中间帧（书 7.5）。四种基本变换，每种对应一个类：

| 类 | 变什么 | 关键参数 |
|---|---|---|
| `AlphaAnimation` | 透明度 | fromAlpha/toAlpha（0–1） |
| `ScaleAnimation` | 缩放 | 起止比例 + **pivotX/pivotY 缩放中心**（比例值 `RELATIVE_TO_SELF`） |
| `TranslateAnimation` | 位移 | 起止坐标（绝对 px 或相对比例） |
| `RotateAnimation` | 旋转 | 起止角度 + **pivot 轴心** |

`AnimationSet(shareInterpolator)` 把它们打包同播，`AnimationUtils.loadAnimation(context, R.anim.x)` 从 XML 加载（`<set>`/`<alpha>`/`<scale>`/`<translate>`/`<rotate>`），`view.startAnimation(anim)` 启动（`Example24Tween`）：

```kotlin
val set = AnimationSet(true).apply {                      // true = 共享插值器
    addAnimation(AlphaAnimation(1f, 0.2f))
    addAnimation(RotateAnimation(0f, 720f,
        Animation.RELATIVE_TO_SELF, 0.5f,                 // 轴心：自身中心
        Animation.RELATIVE_TO_SELF, 0.5f))
    duration = 1600
    interpolator = AccelerateDecelerateInterpolator()
    fillAfter = true                                      // 停在终态（画布层面）
}
view.startAnimation(set)
```

**Interpolator 家族**（两套体系通用，控制速度曲线）：

| Interpolator | 曲线 |
|---|---|
| `LinearInterpolator` | 匀速 |
| `AccelerateInterpolator` | 先慢后快 |
| `DecelerateInterpolator` | 先快后慢 |
| `AccelerateDecelerateInterpolator` | 两头慢中间快（默认款） |
| `CycleInterpolator(cycles)` | 正弦往返 |
| `OvershootInterpolator` / `AnticipateInterpolator` | 冲过头回弹 / 先退一步再冲 |
| `BounceInterpolator` | 落地弹跳 |

XML 里 `@android:anim/linear_interpolator` 这种引用名 = 类名驼峰转下划线（书里的小规律，现在仍对）。

**fillAfter 的语义坑**要单独讲：它让**画面**停在终态，但 View 的 left/top/真实属性全都没动——点击区域留在原地。所以"动画后按钮挪到新位置"这种需求，补间天生做不对，得用属性动画。`fillBefore`（弹回起点）与 `fillEnabled` 是同一族开关。

**自定义补间**（书 7.5.3）继承 `Animation` 重写 `applyTransformation(interpolatedTime, t)`：前者是归一化时间（恒 0→1），后者 `Transformation` 内封一个 `Matrix`，按时间改 Matrix 即任意变形；配 `android.graphics.Camera`（**空间变换工具，不是摄像头**）的 `rotateX/rotateY/translate` 还能做出 3D 翻转——老工程里ListView 的 3D 入场效果就是这套。读得懂即可，新代码的 3D 效果走 `rotationX` 属性（View 自带，5.0 起非黑盒）或 Compose。

## 4. 属性动画：引擎、插值、求值三分工

属性动画的设计值得当成范本记（书 7.6 的 API 综述 + 现代视角）：

- **`ValueAnimator`：时间引擎**。每帧算出"当前值"，但不碰任何对象——值给谁用是你的事（`addUpdateListener` 里自己取 `animatedValue` 应用）。一个 1000ms 从 0 到 1 的心跳：
- **`TimeInterpolator`：塑速度曲线**——同上节的家族
- **`TypeEvaluator`：算值**——`IntEvaluator`/`FloatEvaluator`/`ArgbEvaluator`（颜色插值，渐变背景的标准件）开箱即用，`ofObject(evaluator, start, end)` 配自定义 evaluator 可动画任何类型（`Example24ValueAnim` 用 `PointF` 演示）

```kotlin
ValueAnimator.ofFloat(0f, 1f).apply {
    duration = 1000
    addUpdateListener { anim ->                // 每帧回调：值自己用
        customView.progress = anim.animatedValue as Float
    }
    start()
}
```

**`ObjectAnimator` 是引擎在"对象属性"上的封装**，日常主力。它对目标对象有三条硬要求（书 7.6.1 的注意点，全部是真实坑）：

1. **属性必须有 public setter**：`ofFloat(tv, "alpha", 0f, 1f)` 运行时找 `setAlpha(Float)`——没有 setter 直接静默失败或抛异常
2. **只给一个值时它是终点**，起点取 getter（`getAlpha()`）——没有 getter 又只给一值，当场报错
3. **View 内建属性（alpha/translationX/scaleX/rotation）的 setter 自带重绘**；**自定义属性必须自己在 setter 里 `invalidate()`**——05 章坑的回收：给你的自定义 View 做"progress"动画，setter 里不 invalidate 就一格不动

## 5. 组合与编排

单看动画是素材，编排才是成品。三层工具由简到繁：

**一个对象多属性同时动——`PropertyValuesHolder`**（免开三个 ObjectAnimator）：

```kotlin
val tx = PropertyValuesHolder.ofFloat("translationX", 0f, 300f)
val rot = PropertyValuesHolder.ofFloat("rotation", 0f, 360f)
ObjectAnimator.ofPropertyValuesHolder(button, tx, rot).apply {
    duration = 800
    start()
}
```

**一个属性多关键帧——`Keyframe`**（书里"大珠小珠落玉盘"的压扁弹起就是关键帧思路）：

```kotlin
val kf0 = Keyframe.ofFloat(0f, 0f)
val kf1 = Keyframe.ofFloat(0.5f, 300f)          // 50% 时已到 300
val kf2 = Keyframe.ofFloat(1f, 100f)            // 再回到 100
ObjectAnimator.ofPropertyValuesHolder(view,
    PropertyValuesHolder.ofKeyframe("translationX", kf0, kf1, kf2))
```

**多动画编排——`AnimatorSet`**：

```kotlin
AnimatorSet().apply {
    play(a1).with(a2).before(a3)                // a1、a2 同播，完了再 a3
    // 或 playTogether(a1, a2) / playSequentially(a1, a2)
    start()
}
```

重复播放三件套：`repeatCount = ValueAnimator.INFINITE`、`repeatMode = RESTART|REVERSE`（往返）、`startDelay`。监听用 `AnimatorListenerAdapter` 空实现打底——`onAnimationEnd` 里做收尾（书里小球落完渐隐后移除视图的套路）。**`pause()/resume()` 是 API 19 才有的**——老代码里的"暂停"都是 cancel + 记进度手工实现的。

## 6. 现代生态位

属性动画之上又长了两层，写新代码先想到它们：

- **`ViewPropertyAnimator`**：`tv.animate().alpha(0.3f).translationX(100f).setDuration(400)` 一行流——内部单个 ValueAnimator 驱动多属性，比开 N 个 ObjectAnimator 高效，View 动画首选（`Example24ViewProperty`）
- **`androidx.transition`**：场景变化动画（"布局从 A 变 B 自动补间"），Activity/Fragment 共享元素过渡的地基
- **Compose 动画**（24 章）：`animate*AsState`/`Animatable`/`updateTransition`——把"目标值变了自动动过去"做成默认行为，传统体系里你要手写的 start/cancel/复用全消失。心智模型迁移点：传统动画是**命令**（start 驱动），Compose 动画是**状态声明**（目标驱动）
- **Lottie**（26 章）：设计师 AE 导出的 JSON 动画直接播，运营位动效的事实标准

## 7. 常见坑

**补间动画后点击区域错位**：fillAfter 只骗过眼睛，触摸还是旧位置。要"真挪走"，属性动画；要"骗到底"，动画结束 `layoutParams` 手工同步。

**ObjectAnimator 属性名打错**：字符串无编译期检查，`"alpha "` 多个空格就是运行时找不到 setter。Kotlin 侧可用 `"${View::alpha.name}"`？——别绕，直接记：报"property not found"先查拼写与 setter 可见性。

**自定义属性动画不动**：setter 里没 `invalidate()`。View 内建属性不用管，自定义的一切要自己触发重绘（05 章同款坑）。

**AnimationDrawable 在 onCreate 里 start 不播**：View 还没挂载完。`post { }` 推一帧再启动。

**cancel 后 onAnimationEnd 的时序**：cancel 同样触发 onAnimationEnd——把"正常播完"的收尾逻辑放这里会在半途取消时也执行；需要区分时用 `onAnimationCancel` 打标记。

**Animator 与 Activity 生命周期**：动画持有 View、View 持有 Activity，`onDestroy` 不 cancel 是常见泄漏链。短动画无妨，无限循环动画必须在 `onStop`/`onDestroy` 里 cancel。

**repeatMode 想当然设 RESTART**：往返效果是 `REVERSE`——RESTART 是"跳回起点重放"，视觉上是瞬移。

## 8. 实战建议

- 默认答案：**View 上一行流 `view.animate()`，复杂编排 `ObjectAnimator` + `AnimatorSet`，UI 范围之外（自定义 View 状态、非 View 对象）`ValueAnimator`**
- 补间动画的定位：读老代码 + 简单的"闪一下/飘一下"一次性效果（此时它不改真属性反而无害）
- 逐帧动画美术资源够好就是最高性价比；加载大帧序列记得压缩尺寸
- 颜色渐变直接 `ObjectAnimator.ofArgb`/`ArgbEvaluator`，别手动位移 RGB
- 多属性同动先想 `PropertyValuesHolder`——一个动画器一份时间线，同步天然保证
- 学完传统体系再进 24 章：Compose 动画的 `AnimationSpec`/`Keyframes` 与本章 `Interpolator`/`Keyframe` 一一对应，名字换了思想没换

---
上一章：[13 自定义 View 与绘图](13-custom-view-drawing.md) ｜ 下一章：[15 Fragment 与任务栈](15-fragment-tasks.md) ｜ 返回：[README](../README.md)
