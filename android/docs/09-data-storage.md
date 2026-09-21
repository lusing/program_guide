# 09 · 本地数据持久化

> 对应示例：`examples/07_shared_preferences.kt`、`examples/08_internal_storage.kt`、`examples/09_sqlite_helper.kt`

## 1. 存储选型总表：先想清楚再动手

写数据之前先回答三个问题：**数据有多大？有没有结构？要不要跨应用共享？** 答案直接落到下表某一格，不要"上来就建数据库"：

| 方案 | 容量 | 结构化 | 适用场景 |
|---|---|---|---|
| SharedPreferences | 小（几十~几百个键） | 无（键值对） | 用户设置、开关、上次状态 |
| 内部存储 `filesDir` | 任意 | 无（裸字节，格式自己定） | 日志、导出文件、大块文本 |
| 外部存储 | 大 | 无 | 媒体、下载内容（API 29 起 Scoped Storage 限制，见第 6 节） |
| SQLite | 大 | 有（SQL 表、索引、查询） | 列表数据、要按条件查的业务数据 |
| Room | 大 | 有 | SQLite 的官方 ORM 封装，工程首选，详见[第 14 章](14-compose-architecture.md) |
| DataStore | 小 | 半结构化（键值 / 协议缓冲） | SharedPreferences 的现代替代：协程异步、Flow 响应式、写事务保证 |

观点先行：

- 设置类数据 SP 三行搞定，别为它上数据库；反过来，业务记录（便签、聊天、订单）别硬塞 SP
- 本章刻意全部使用框架 API（不引任何 Jetpack 库），把最底层的一次看清楚；工程里再让 Room 替你生成这些样板代码
- DataStore 一句话定位：**SP 的现代替代**，解决 SP 全量加载、主线程写盘、无类型安全三宗罪。新工程设置类存储选它

## 2. SharedPreferences：键值对设置

`examples/07_shared_preferences.kt` 完整逻辑只有三行：

```kotlin
val prefs = getSharedPreferences("guide", MODE_PRIVATE)
prefs.edit().putString("username", "android_user").apply()
val value = prefs.getString("username", "none")
```

四个角色：

| 调用 | 作用 |
|---|---|
| `getSharedPreferences("guide", MODE_PRIVATE)` | 取名为 `guide` 的配置文件实例（不存在则首次写盘时创建） |
| `edit()` | 开启一次编辑事务，返回 `SharedPreferences.Editor` |
| `putString(key, value)` | 写入一个键，同类还有 `putInt` / `putBoolean` / `putLong` / `putStringSet` |
| `apply()` | 提交事务 |

读不需要 `edit()`：`getString("username", "none")` 的第二个参数是**键不存在时的默认值**——所以 SP 读操作永远不会"失败"，只会给你默认值。

**SP 的本质是一个 XML 键值文件**，路径在应用沙箱内：

```text
/data/data/guide.android.examples/shared_prefs/guide.xml
```

内容长这样：

```xml
<map>
    <string name="username">android_user</string>
</map>
```

`MODE_PRIVATE` 表示仅本应用可读写；历史上还有 `MODE_WORLD_READABLE`（跨应用可读），早已废弃，现代 Android 上等同不生效。

### apply vs commit

`Editor` 的提交有两个方法，差别值得单独记：

| | `apply()` | `commit()` |
|---|---|---|
| 写内存缓存 | 立即 | 立即 |
| 写磁盘 | 异步（后台线程） | 同步（阻塞当前线程） |
| 返回值 | 无 | `Boolean`，是否写盘成功 |
| 主线程调用 | 安全，推荐 | 大文件时卡顿甚至 ANR |

除非你要拿"磁盘真的写成功了"这个结果，否则一律 `apply()`。

还有一条隐含成本：**SP 第一次 `getSharedPreferences` 时会把整个 XML 全量读进内存并永久缓存**。这是"别往 SP 塞大对象"的根源——一个 2MB 的 JSON 字符串塞进去，进程从启动起就背着它。

## 3. 内部存储：把文件当文件

键值对不够用（内容大、有顺序、是文本/二进制流）时，直接写文件。`examples/08_internal_storage.kt` 演示了写一行、再读回来的完整闭环：

```kotlin
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
```

逐个拆：

| 调用 | 作用 |
|---|---|
| `openFileOutput(fileName, MODE_PRIVATE)` | 在应用私有目录建输出流，返回 `FileOutputStream` |
| `openFileInput(fileName)` | 打开同目录下文件的输入流 |
| `use { ... }` | Kotlin 扩展：块结束自动关流，异常路径也关——流管理的标准写法 |
| `toByteArray(StandardCharsets.UTF_8)` | 显式指定编码，避免依赖平台默认值 |

这些流落地的物理位置是：

```text
/data/data/guide.android.examples/files/guide_internal.txt
```

即 `filesDir` 目录（可用 `File(filesDir, fileName)` 直接拿到路径对象）。

**私有性是这套 API 的核心语义**：

- 其他应用（在非 root 设备上）无法读写你的 `filesDir`，不需要任何权限声明
- **卸载应用即整目录删除**——数据生命周期与应用绑定
- `cacheDir` 是旁边的孪生目录：语义是"缓存"，系统磁盘紧张时可能直接清空，**别放唯一副本**；放之前先想清楚丢了怎么办

## 4. SQLite：结构化数据

文件和键值对都回答不了"给我按时间倒序取前 20 条"。此时上数据库。`examples/09_sqlite_helper.kt` 用最短的路径走完"建库建表 → 插一行 → 查一行"：

### SQLiteOpenHelper：库和表的生命周期管家

```kotlin
private class DBHelper(activity: Activity) : SQLiteOpenHelper(activity, "guide.db", null, 1) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE topics(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS topics")
        onCreate(db)
    }
}
```

构造参数四个：`Context`、库名 `"guide.db"`（落在 `/data/data/<包名>/databases/`）、`cursorFactory`（一般 `null`）、**版本号 `1`**。

两个回调的触发时机是 `SQLiteOpenHelper` 的全部精髓：

| 回调 | 何时执行 | 语义 |
|---|---|---|
| `onCreate(db)` | 数据库文件**第一次被打开**时执行一次 | 建表、建索引、灌初始数据 |
| `onUpgrade(db, old, new)` | 构造传入的版本号**高于**已存在的版本时执行 | **迁移**：把旧结构改成新结构，并保住旧数据 |

版本升级语义：把构造里的 `1` 改成 `2` 重新运行，系统发现磁盘上是 1、代码要 2，就调 `onUpgrade(db, 1, 2)`。示例里 `DROP TABLE IF EXISTS` 后重建是**教程式偷懒**——真实项目这么写等于每次升级清空用户数据，正确姿势是 `ALTER TABLE topics ADD COLUMN ...` 这类增量迁移（见第 7 节）。

### 增删改查

```kotlin
val helper = DBHelper(this)
val db = helper.writableDatabase
val values = ContentValues().apply { put("name", "android") }
db.insert("topics", null, values)

val cursor = db.query("topics", arrayOf("name"), null, null, null, null, null)
val firstName = if (cursor.moveToFirst()) cursor.getString(0) else ""
cursor.close()
db.close()
```

- `writableDatabase`：懒打开（必要时创建）数据库并返回 `SQLiteDatabase`；只读场景用 `readableDatabase`
- `ContentValues` 就是"一行"：键是列名，值是列值。`insert("topics", null, values)` 等价于 `INSERT INTO topics(name) VALUES('android')`，返回新行的 rowId（失败 -1）；第二个参数 `nullColumnHack` 在整行皆空时指定一列，日常传 `null`
- `query(...)` 的七个参数是 Android 数据访问的通用形状（第 11 章的 `ContentResolver.query` 同构）：

| 参数 | 含义 | 示例值 |
|---|---|---|
| `table` | 表名 | `"topics"` |
| `projection` | 查哪些列 | `arrayOf("name")` |
| `selection` | WHERE 子句（不含 `WHERE` 关键字） | `"name = ?"` |
| `selectionArgs` | 占位符 `?` 的实参 | `arrayOf("android")` |
| `groupBy` / `having` | 分组 | `null` |
| `orderBy` | 排序 | `"id DESC"` |

- `Cursor`（游标）是结果集的顺序读取指针：`moveToFirst()` 定位到第一行，`getString(0)` 按列下标取值（也可以 `getColumnIndex("name")` 先换下标）。**用完必须 `close()`**——它持有底层资源，泄漏多了直接崩

多行遍历的标准式（`Cursor` 实现了 `Closeable`，可以直接 `use`）：

```kotlin
val names = mutableListOf<String>()
db.query("topics", arrayOf("name"), null, null, null, null, "id DESC").use { c ->
    if (c.moveToFirst()) {
        do {
            names += c.getString(0)
        } while (c.moveToNext())
    }
}
```

### SQL 注入与占位符

把用户输入直接拼进 SQL 是老毛病，Android 上也一样炸：

```kotlin
// 危险：用户输入 name = 'x'; DROP TABLE topics;-- 时直接完蛋
db.rawQuery("SELECT * FROM topics WHERE name = '$keyword'", null)

// 安全：占位符由驱动转义，且执行计划可复用
db.query("topics", null, "name = ?", arrayOf(keyword), null, null, null)
```

规则一句话：**凡有变量进 SQL，一律走 `selection` + `selectionArgs` 占位符**，`rawQuery` 只留给无变量的静态 DDL/DML。

## 5. 同一份"用户设置"，三种方案的代码量

需求：持久化"用户名 + 主题色"两项设置，读写都要。三种方案的真实代价：

| 方案 | 写入 | 读取 | 序列化 | 额外代价 |
|---|---|---|---|---|
| SharedPreferences | 2 行（`putString` ×2 + `apply`） | 1 行（`getXxx` ×2） | 系统包办 | 无 |
| 内部文件 | ~10 行：拼 JSON/行文本 + `openFileOutput` 流管理 | ~10 行：读流 + `BufferedReader` 逐行解析 | **手写**，格式一改两头都要动 | 自己处理半写状态（崩溃时文件残缺） |
| SQLite | ~25 行：`DBHelper` 类 + 建表 + `ContentValues` | ~10 行：`query` + Cursor 遍历 | 手写表结构 + 迁移 | 版本升级要写 `onUpgrade` |

结论自明：**两项设置用 SP 是三行的事，用 SQLite 是三十行的事**；而"存 1000 条按日期查询的记录"时关系反过来。选型错误不是风格问题，是每一行都要还的债。

## 6. Scoped Storage：Android 10 起外部存储的规矩

老 Android 上应用拿到 `WRITE_EXTERNAL_STORAGE` 就能扫遍整个共享存储（SD 卡根目录建文件夹、翻别人的下载目录），垃圾文件与隐私泄露齐飞。**Android 10（API 29）起引入 Scoped Storage（分区存储）**，规则概念上只有三条：

1. 外部存储上的**应用专属目录**（`getExternalFilesDir(null)`）随便写、卸载即删、不需要任何权限——它只是"容量更大的 `filesDir`"
2. 要贡献/读取**共享媒体**（图片、音频、视频）走 **MediaStore**——按媒体类型集合管理，读写别人的贡献需要对应运行时权限（第 11 章）
3. 要访问**任意文件/目录**（如 PDF、ZIP）走 **SAF（Storage Access Framework）**：发 `ACTION_OPEN_DOCUMENT` 意图（第 06 章），由系统文件选择器代用户授权，应用只拿到一个文档 URI

顺带一句：`WRITE_EXTERNAL_STORAGE` 对 targetSdk 30+ 的应用已基本失效，别再指望"申请存储权限就能扫盘"。本章三个示例都写内部/私有目录，完全不涉及这些麻烦——这是刻意的：**私有存储永远是首选，共享才需要谈权限**。

## 7. 常见坑

**SP 存大对象**：把整页 JSON、Bitmap 的 Base64 塞进 SP。SP 是启动时全量加载进内存的单体 XML——首屏变慢、写入放大、`ClassCastException` 风险三连。大对象去 `filesDir` 或数据库；设置项保持"小而扁平"。

**`onUpgrade` 忘了迁移丢数据**：示例里的 `DROP TABLE` + 重建在真机上等于"升级版本 = 清空数据"。正确写法是按 `oldVersion` 分支逐级 `ALTER TABLE`；更省心的办法是把建表/迁移交给 Room（[第 14 章](14-compose-architecture.md)），编译期校验 schema。

**Cursor 泄漏**：`query` 返回的 `Cursor` 忘了 `close()`。偶发 `IllegalStateException: attempt to re-open an already-closed object` 或游标数量超限崩溃，且日志离案发现场很远。一律 `cursor.use { ... }`，让 Kotlin 替你关。

**主线程做数据库操作**：`writableDatabase` 的增删查改都是磁盘 IO，主线程调用轻则掉帧重则 `StrictMode` 报错/ANR。数据库操作放进后台线程或协程（第 08 章的线程模型在这里兑现）。

## 8. 实战建议

- 选型就按第 1 节的表走：设置 SP/DataStore、文件 `filesDir`、记录 SQLite/Room，别发明第四种
- `SQLiteOpenHelper` 按单例持有（配合 `applicationContext`），全应用共用一个连接池；示例里 `db.close()` 是演示用，频繁开关库反而低效
- 任何带用户输入的查询都用 `selection` + `selectionArgs` 占位符，把"拼 SQL"从肌肉记忆里删掉
- 数据库版本号只升不降；`onUpgrade` 写成 `if (oldVersion < 2) { ... }` 的阶梯，保证跳版本升级也能走通
- 第 16 章的 MemoPad 存便签选的就是 `filesDir` + JSON 文件——数据量小、不需要按条件查询，文件方案代码量最少；等需求长出"搜索/排序/分页"，再迁去 SQLite/Room 不迟

---
上一章：[08 线程、Handler 与网络请求](08-threads-network.md) ｜ 下一章：[10 BroadcastReceiver、Service 与通知](10-system-components.md) ｜ 返回：[README](../README.md)
