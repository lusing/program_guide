package guide.android.examples

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.TextView

class Example20ActivityResultStyle : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startActivityForResult(Intent(this, Example20PickerActivity::class.java), 501)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 501 && resultCode == RESULT_OK && data != null) {
            val value = data.getStringExtra("picked") ?: "none"
            setContentView(TextView(this).apply { text = value })
        }
    }
}

class Example20PickerActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val result = Intent()
        result.putExtra("picked", "android-item")
        setResult(RESULT_OK, result)
        finish()
    }
}

