package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.widget.TextView
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets

class Example08InternalStorage : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val fileName = "guide_internal.txt"
        val result = try {
            openFileOutput(fileName, MODE_PRIVATE).use { out ->
                out.write("line1\nline2\n".toByteArray(StandardCharsets.UTF_8))
            }
            openFileInput(fileName).use { input ->
                BufferedReader(InputStreamReader(input, StandardCharsets.UTF_8)).use { reader ->
                    buildString {
                        var line = reader.readLine()
                        while (line != null) {
                            append(line).append("|")
                            line = reader.readLine()
                        }
                    }
                }
            }
        } catch (e: IOException) {
            e::class.java.simpleName
        }

        val tv = TextView(this).apply { text = result }
        setContentView(tv)
    }
}

