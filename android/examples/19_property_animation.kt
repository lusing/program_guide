package guide.android.examples

import android.animation.ObjectAnimator
import android.app.Activity
import android.os.Bundle
import android.widget.TextView

class Example19PropertyAnimation : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this).apply { text = "animate me" }
        setContentView(tv)
        ObjectAnimator.ofFloat(tv, "alpha", 0.2f, 1.0f).apply {
            duration = 600L
            start()
        }
    }
}

