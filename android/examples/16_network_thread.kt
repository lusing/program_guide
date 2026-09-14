package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.util.Log
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

class Example16NetworkThread : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Thread {
            var connection: HttpURLConnection? = null
            try {
                connection = URL("https://example.com").openConnection() as HttpURLConnection
                connection.connectTimeout = 2000
                connection.readTimeout = 2000
                val code = connection.responseCode
                Log.d("Guide", "response=$code")
            } catch (e: IOException) {
                Log.e("Guide", "network error", e)
            } finally {
                connection?.disconnect()
            }
        }.start()
    }
}

