package guide.android.examples

import android.app.Activity
import android.content.ContentValues
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.os.Bundle
import android.widget.TextView

class Example09SQLiteHelper : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val helper = DBHelper(this)
        val db = helper.writableDatabase
        val values = ContentValues().apply { put("name", "android") }
        db.insert("topics", null, values)

        val cursor = db.query("topics", arrayOf("name"), null, null, null, null, null)
        val firstName = if (cursor.moveToFirst()) cursor.getString(0) else ""
        cursor.close()
        db.close()

        val tv = TextView(this).apply { text = "first_topic=$firstName" }
        setContentView(tv)
    }

    private class DBHelper(activity: Activity) : SQLiteOpenHelper(activity, "guide.db", null, 1) {
        override fun onCreate(db: SQLiteDatabase) {
            db.execSQL("CREATE TABLE topics(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)")
        }

        override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            db.execSQL("DROP TABLE IF EXISTS topics")
            onCreate(db)
        }
    }
}

