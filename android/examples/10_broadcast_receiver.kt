package guide.android.examples

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.widget.TextView

class Example10BroadcastReceiver : Activity() {
    private val receiver = GuideReceiver()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this).apply { text = "receiver registered" }
        setContentView(tv)
        registerReceiver(receiver, IntentFilter("guide.ACTION_PING"))
        sendBroadcast(Intent("guide.ACTION_PING"))
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(receiver)
    }

    private class GuideReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
        }
    }
}

