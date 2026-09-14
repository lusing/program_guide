package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.widget.Button
import android.widget.Toast

class Example03ButtonToast : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val button = Button(this).apply {
            text = "Click me"
            setOnClickListener {
                Toast.makeText(this@Example03ButtonToast, "clicked", Toast.LENGTH_SHORT).show()
            }
        }
        setContentView(button)
    }
}

