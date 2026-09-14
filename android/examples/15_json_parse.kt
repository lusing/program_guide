package guide.android.examples

import android.app.Activity
import android.os.Bundle
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

class Example15JsonParse : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val text = try {
            val obj = JSONObject()
            obj.put("name", "android")
            obj.put("level", 1)
            obj.put("tags", JSONArray().put("mobile").put("native"))
            "${obj.getString("name")}:${obj.getJSONArray("tags").length()}"
        } catch (e: JSONException) {
            e.message ?: "json error"
        }
        setContentView(TextView(this).apply { this.text = text })
    }
}

