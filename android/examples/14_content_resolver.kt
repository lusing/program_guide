package guide.android.examples

import android.app.Activity
import android.content.ContentProvider
import android.content.ContentUris
import android.content.ContentValues
import android.content.UriMatcher
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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

        // 第 11 章第 4 节：客户端监听数据变更（register/unregister 成对，离开界面注销）
        val observer = object : android.database.ContentObserver(
            Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                // 数据变了：重查一次（不复用旧 Cursor）
                val c = contentResolver.query(Settings.System.CONTENT_URI, arrayOf("name"), null, null, null)
                tv.text = "changed rows=${c?.count ?: 0}"
                c?.close()
            }
        }
        contentResolver.registerContentObserver(
            Settings.System.CONTENT_URI, true, observer)   // true = 子路径也通知
    }
}

// ---- 11 章第 4 节：自建 ContentProvider（服务端六方法 + UriMatcher 分拣）----
// 真实工程需在 manifest 注册：
//   <provider android:name=".DictProvider"
//             android:authorities="guide.android.examples.dictprovider"
//             android:exported="true"/>

class DictProvider : ContentProvider() {
    private lateinit var db: SQLiteDatabase
    private val matcher = UriMatcher(UriMatcher.NO_MATCH)

    override fun onCreate(): Boolean {
        db = context!!.openOrCreateDatabase("dict.db", android.content.Context.MODE_PRIVATE, null)
        db.execSQL("CREATE TABLE IF NOT EXISTS dict(_id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT, detail TEXT)")
        matcher.addURI(AUTHORITY, "words", WORDS)        // content://auth/words → 全表
        matcher.addURI(AUTHORITY, "word/#", WORD_ID)     // content://auth/word/2 → 单条（# 通配数字）
        return true
    }

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?,
                       selectionArgs: Array<out String>?, sortOrder: String?): Cursor? =
        when (matcher.match(uri)) {                      // 分拣员先分流
            WORDS -> db.query("dict", projection, selection, selectionArgs, null, null, sortOrder)
            WORD_ID -> db.query("dict", projection, "_id=?",
                arrayOf(ContentUris.parseId(uri).toString()), null, null, null)
            else -> throw IllegalArgumentException("Unknown URI: $uri")
        }

    override fun insert(uri: Uri, values: ContentValues?): Uri? {
        val id = db.insert("dict", null, values)
        context?.contentResolver?.notifyChange(uri, null)   // 忘了这行，观察者永远沉默
        return ContentUris.withAppendedId(uri, id)
    }

    override fun update(uri: Uri, values: ContentValues?, selection: String?,
                        selectionArgs: Array<out String>?): Int {
        val n = db.update("dict", values, selection, selectionArgs)
        context?.contentResolver?.notifyChange(uri, null)
        return n
    }

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int {
        val n = db.delete("dict", selection, selectionArgs)
        context?.contentResolver?.notifyChange(uri, null)
        return n
    }

    override fun getType(uri: Uri): String? = when (matcher.match(uri)) {
        WORDS -> "vnd.android.cursor.dir/vnd.$AUTHORITY.words"
        WORD_ID -> "vnd.android.cursor.item/vnd.$AUTHORITY.words"
        else -> null
    }

    companion object {
        const val AUTHORITY = "guide.android.examples.dictprovider"
        const val WORDS = 1
        const val WORD_ID = 2
    }
}

