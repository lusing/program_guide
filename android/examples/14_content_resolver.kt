package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.provider.Settings
import android.widget.TextView

class Example14ContentResolver : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val cursor = contentResolver.query(Settings.System.CONTENT_URI, arrayOf("name"), null, null, null)
        val count = cursor?.count ?: 0
        cursor?.close()
        val tv = TextView(this).apply { text = "rows=$count" }
        setContentView(tv)
    }
}

