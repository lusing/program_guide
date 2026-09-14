package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.widget.TextView

class Example01HelloActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val textView = TextView(this)
        textView.text = "Hello Android Kotlin"
        setContentView(textView)
    }
}

