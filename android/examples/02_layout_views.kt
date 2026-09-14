package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView

class Example02LayoutViews : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        val title = TextView(this).apply { text = "Profile" }
        val input = EditText(this).apply { hint = "Input your name" }
        layout.addView(title)
        layout.addView(input)
        setContentView(layout)
    }
}

