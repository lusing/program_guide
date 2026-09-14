package guide.android.examples

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle

class Example12Notifications : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "guide_channel"
        val channel = NotificationChannel(
            channelId,
            "Guide",
            NotificationManager.IMPORTANCE_DEFAULT
        )
        manager.createNotificationChannel(channel)
        val builder = Notification.Builder(this, channelId)
        val notification = builder
            .setContentTitle("Guide")
            .setContentText("Android notification sample")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()
        manager.notify(1001, notification)
    }
}
