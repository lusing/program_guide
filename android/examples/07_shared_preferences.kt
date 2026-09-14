package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.widget.TextView

class Example07SharedPreferences : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val prefs = getSharedPreferences("guide", MODE_PRIVATE)
        prefs.edit().putString("username", "android_user").apply()
        val value = prefs.getString("username", "none")
        val tv = TextView(this).apply { text = "username=$value" }
        setContentView(tv)
    }
}

