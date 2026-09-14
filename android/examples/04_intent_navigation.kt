package guide.android.examples

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.TextView

class Example04IntentNavigation : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val intent = Intent(this, Example04TargetActivity::class.java)
        intent.putExtra("message", "hello target")
        startActivity(intent)
    }
}

class Example04TargetActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val message = intent.getStringExtra("message") ?: "empty"
        val tv = TextView(this).apply { text = message }
        setContentView(tv)
    }
}

