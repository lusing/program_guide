package guide.android.examples

import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.Keyframe
import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.animation.TimeInterpolator
import android.animation.TypeEvaluator
import android.animation.ValueAnimator
import android.app.Activity
import android.graphics.Color
import android.graphics.PointF
import android.graphics.drawable.AnimationDrawable
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.AlphaAnimation
import android.view.animation.Animation
import android.view.animation.AnimationSet
import android.view.animation.BounceInterpolator
import android.view.animation.RotateAnimation
import android.view.animation.TranslateAnimation
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

// ---- 14 章第 2 节：逐帧动画（代码建帧 + 挂载后再 start）----

class Example24FrameAnim : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
        }
        val strip = TextView(this).apply {
            text = "逐帧色带"
            gravity = android.view.Gravity.CENTER
        }
        val frames = AnimationDrawable().apply {
            isOneShot = false
            addFrame(ColorDrawable(0xFFFF4444.toInt()), 300)
            addFrame(ColorDrawable(0xFF44FF44.toInt()), 300)
            addFrame(ColorDrawable(0xFF4444FF.toInt()), 300)
        }
        strip.background = frames
        root.addView(strip, LinearLayout.LayoutParams(
            android.view.ViewGroup.LayoutParams.MATCH_PARENT, 96))
        root.addView(Button(this).apply {
            text = "start / stop"
            setOnClickListener {
                if (frames.isRunning) frames.stop() else frames.start()
            }
        })
        setContentView(root)
        strip.post { frames.start() }          // 挂载完成后再启动
    }
}

// ---- 14 章第 3 节：补间动画（四类变换 + AnimationSet + Interpolator）----

class Example24Tween : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val target = TextView(this).apply {
            text = "补间动画的目标"
            setPadding(24, 24, 24, 24)
            setBackgroundColor(Color.parseColor("#EFEFEF"))
        }
        val fire = Button(this).apply { text = "播放补间" }
        fire.setOnClickListener {
            val set = AnimationSet(true).apply {               // 共享插值器
                addAnimation(AlphaAnimation(1f, 0.2f))
                addAnimation(RotateAnimation(0f, 720f,
                    Animation.RELATIVE_TO_SELF, 0.5f,          // 轴心 = 自身中心
                    Animation.RELATIVE_TO_SELF, 0.5f))
                addAnimation(TranslateAnimation(0f, 160f, 0f, 0f))
                duration = 1600
                interpolator = AccelerateDecelerateInterpolator()
                fillAfter = true                               // 画面停在终态（属性没动）
            }
            target.startAnimation(set)
        }
        setContentView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
            addView(fire)
            addView(target, LinearLayout.LayoutParams(
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT,
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                topMargin = 48
            })
        })
    }
}

// ---- 14 章第 4 节：ValueAnimator 引擎 + 自定义 TypeEvaluator ----

class Example24ValueAnim : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this).apply {
            text = "ValueAnimator：点一下，沿贝塞尔动起来"
            setPadding(24, 24, 24, 24)
        }

        // 自定义求值器：两控制点的二阶贝塞尔
        val bezier = TypeEvaluator<PointF> { fraction, start, end ->
            val t = fraction
            val mt = 1 - t
            PointF(
                mt * mt * start.x + 2 * t * mt * start.x + t * t * end.x,
                mt * mt * start.y + 2 * t * mt * (start.y + 300f) + t * t * end.y
            )
        }
        tv.setOnClickListener {
            ValueAnimator.ofObject(bezier, PointF(0f, 0f), PointF(600f, 0f)).apply {
                duration = 1200
                interpolator = BounceInterpolator() as TimeInterpolator
                addUpdateListener { anim ->
                    val p = anim.animatedValue as PointF
                    tv.translationX = p.x
                    tv.translationY = p.y
                }
                start()
            }
        }
        setContentView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
            addView(tv)
        })
    }
}

// ---- 14 章第 4/5 节：ObjectAnimator 三件套 + AnimatorSet 编排 ----

class Example24ObjectAnim : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val target = TextView(this).apply {
            text = "属性动画：真的在动"
            setPadding(24, 24, 24, 24)
            setBackgroundColor(Color.WHITE)
        }
        val fire = Button(this).apply { text = "播放组合" }
        fire.setOnClickListener {
            // 一个对象多属性：PropertyValuesHolder
            val tx = PropertyValuesHolder.ofFloat("translationX", 0f, 300f)
            val rot = PropertyValuesHolder.ofFloat("rotation", 0f, 360f)
            val move = ObjectAnimator.ofPropertyValuesHolder(target, tx, rot).apply {
                duration = 800
            }
            // 一个属性多关键帧：Keyframe
            val kf0 = Keyframe.ofFloat(0f, 1f)
            val kf1 = Keyframe.ofFloat(0.5f, 0.3f)
            val kf2 = Keyframe.ofFloat(1f, 1f)
            val blink = ObjectAnimator.ofPropertyValuesHolder(target,
                PropertyValuesHolder.ofKeyframe("alpha", kf0, kf1, kf2)).apply {
                duration = 800
            }
            // 颜色渐变：ofArgb（ArgbEvaluator 开箱即用）
            val tint = ObjectAnimator.ofArgb(target, "backgroundColor",
                Color.WHITE, 0xFFCCDDFF.toInt(), Color.WHITE).apply {
                duration = 1600
            }
            AnimatorSet().apply {
                play(move).with(blink).before(tint)     // 同播 + 顺序编排
                addListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: android.animation.Animator) {
                        Toast.makeText(this@Example24ObjectAnim, "组合完毕",
                            Toast.LENGTH_SHORT).show()
                    }
                })
                start()
            }
        }
        setContentView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
            addView(fire)
            addView(target, LinearLayout.LayoutParams(
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT,
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                topMargin = 48
            })
        })
    }
}

// ---- 14 章第 6 节：ViewPropertyAnimator 一行流 ----

class Example24ViewProperty : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val target = TextView(this).apply {
            text = "view.animate()：点我"
            setPadding(24, 24, 24, 24)
            setBackgroundColor(Color.parseColor("#FFF3E0"))
        }
        var flipped = false
        target.setOnClickListener {
            flipped = !flipped
            target.animate()
                .alpha(if (flipped) 0.4f else 1f)
                .translationX(if (flipped) 200f else 0f)
                .rotation(if (flipped) 180f else 0f)
                .scaleX(if (flipped) 1.3f else 1f)
                .setDuration(450)
                .start()
        }
        setContentView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
            addView(target)
        })
    }
}
