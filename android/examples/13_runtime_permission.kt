package guide.android.examples

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.TextView

class Example13RuntimePermission : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(Manifest.permission.CAMERA), 101)
                tv.text = "requesting CAMERA"
            } else {
                tv.text = "CAMERA granted"
            }
        } else {
            tv.text = "runtime permission not required"
        }
        setContentView(tv)
    }
}

