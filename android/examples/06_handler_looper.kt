package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.TextView

class Example06HandlerLooper : Activity() {
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this).apply { text = "waiting..." }
        setContentView(tv)

        handler.postDelayed({
            tv.text = "updated by main looper"
        }, 1000L)
    }
}

