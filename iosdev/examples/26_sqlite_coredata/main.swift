// ============================================================
// 26 - SQLite3 与 CoreData：同一个文件上的两套 API
//
// 第 18 章把「持久化」讲到了文件层（UserDefaults / 归档 / 沙盒目录）。
// 这一章往上走两层：
//   SQLite3：iOS SDK 自带的 C 库，Swift 里 `import SQLite3` 就能用，
//     准备语句 → 绑定 → 逐步求值 → 列读取 → 错误码 → 事务 → 自定义函数
//   CoreData：不是 SQL，是「托管对象 + 上下文 + store」三层，
//     底下默认还是同一个 SQLite 文件 —— 所以本章把两边**指向同一个库文件**，
//     用 C API 去读 CoreData 写出来的表，也用 CoreData 去数 C API 直插的行
//
// 这一章的驱动力是「谁替你做了什么，以及出事时谁告诉你」：
//   - SQLite 侧：几乎每个函数都靠**返回码**说话，而返回码有一族看起来都算成功；
//     错误分「主码 / 扩展码」两套，默认只给主码（19），开了扩展才是 1555
//   - CoreData 侧：真正的错误走 throws，但**更多的问题既不抛也不崩**：
//     属性读回 nil、聚合列读回 nil、批量请求绕过你的上下文
//   - 两边交界处：CoreData 的表名全是 Z 前缀、没有 FOREIGN KEY 子句、
//     主键分配靠 Z_PRIMARYKEY 这张表记账 —— 绕过它直插就得自己维护那本账
//
// 六条判定（stderr 必须空、debug/release 逐字节一致）带来的四条写法约束：
//   - 不打印任何路径 / UUID / 文件大小：临时目录带设备标识，store 的 UUID 每次建库都不同
//     —— 只打印「是不是 36 个字符」「两次的 host 是否相同」这类可复现的形状
//   - 不打印 BLOB：Z_METADATA.Z_PLIST、Z_MODELCACHE.Z_CONTENT 是二进制，
//     判定 5 禁止控制字符，所以只打印「是不是非空」「列声明是什么」
//   - CoreData 失败时会往 stderr 打一整段 `CoreData: error: …`，里面还带绝对路径；
//     本章故意制造失败的那些调用（§14）用 quiet() 把 fd 2 临时指向 /dev/null，
//     错误信息由我们自己从 NSError 里取 domain/code/userInfo 键名打印
//   - 崩溃与死循环的调用（§15 的坏聚合表达式、§16 的 handler 永不返回）
//     只能在独立探针进程里量，本章正文引用其原文，示例一行都不执行
// ============================================================

import Foundation
import CoreData
import SQLite3

setvbuf(stdout, nil, _IONBF, 0)

var failures = 0
/// 断言 + 讲解。讲解写成若干段字符串拼起来，输出一整行，方便文档逐字引用
func expect(_ condition: Bool, _ parts: String...) {
    print("  \(condition ? "ok  " : "FAIL") \(parts.joined(separator: ""))")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
/// C 字符串指针 → String；NULL 给明确的哨兵，不隐式解包
func sp(_ p: UnsafePointer<CChar>?) -> String {
    guard let p else { return "<nil>" }
    return String(cString: p)
}
/// sqlite3_column_text 给的是 UInt8 指针，不是 CChar 指针：只能按字节长度解码
func colText(_ st: OpaquePointer?, _ i: Int32) -> String {
    guard let p = sqlite3_column_text(st, i) else { return "<NULL>" }
    return String(decoding: UnsafeBufferPointer(start: p, count: Int(sqlite3_column_bytes(st, i))), as: UTF8.self)
}
/// 跑一条只回一列的 SQL，把首行首列收成字符串（NULL 给 <NULL>，prepare 失败把 errmsg 带出来）
func scalar(_ db: OpaquePointer?, _ sql: String) -> String {
    var st: OpaquePointer?
    if sqlite3_prepare_v2(db, sql, -1, &st, nil) != SQLITE_OK {
        return "prepare失败:\(sp(sqlite3_errmsg(db)))"
    }
    defer { sqlite3_finalize(st) }
    if sqlite3_step(st) != SQLITE_ROW { return "<无行>" }
    return colText(st, 0)
}
/// 只回若干列的首行，列间用 | 分隔
func row(_ db: OpaquePointer?, _ sql: String, _ cols: Int) -> String {
    var st: OpaquePointer?
    if sqlite3_prepare_v2(db, sql, -1, &st, nil) != SQLITE_OK {
        return "prepare失败:\(sp(sqlite3_errmsg(db)))"
    }
    defer { sqlite3_finalize(st) }
    if sqlite3_step(st) != SQLITE_ROW { return "<无行>" }
    return (0..<Int32(cols)).map { colText(st, $0) }.joined(separator: " | ")
}
/// 把一条查询的所有行收成 "a | b" 形式，行间用 ;; 分隔
func allRows(_ db: OpaquePointer?, _ sql: String, _ cols: Int) -> String {
    var st: OpaquePointer?
    if sqlite3_prepare_v2(db, sql, -1, &st, nil) != SQLITE_OK {
        return "prepare失败:\(sp(sqlite3_errmsg(db)))"
    }
    defer { sqlite3_finalize(st) }
    var out: [String] = []
    while sqlite3_step(st) == SQLITE_ROW {
        out.append((0..<Int32(cols)).map { colText(st, $0) }.joined(separator: " | "))
    }
    return out.isEmpty ? "<无行>" : out.joined(separator: " ;; ")
}
/// 跑一条查询，把所有行的所有列都收出来（列数由结果自己决定）
func dump(_ db: OpaquePointer?, _ sql: String) -> String {
    var st: OpaquePointer?
    if sqlite3_prepare_v2(db, sql, -1, &st, nil) != SQLITE_OK {
        return "prepare失败:\(sp(sqlite3_errmsg(db)))"
    }
    defer { sqlite3_finalize(st) }
    let n = Int(sqlite3_column_count(st))
    var out: [String] = []
    while sqlite3_step(st) == SQLITE_ROW {
        out.append((0..<Int32(n)).map { colText(st, $0) }.joined(separator: ","))
    }
    return out.isEmpty ? "<无行>" : out.joined(separator: " | ")
}
/// 准备好并 step 一行，把 stmt 交给闭包读任意列；prepare 失败返回 nil
func withStmt<T>(_ db: OpaquePointer?, _ sql: String, _ body: (OpaquePointer?) -> T) -> T? {
    var st: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &st, nil) == SQLITE_OK else { return nil }
    defer { sqlite3_finalize(st) }
    return body(st)
}
/// CoreData 的 Error → 只取 domain / code / userInfo 的键名（描述文本带路径，不能打）
func errInfo(_ e: Error?) -> String {
    guard let e else { return "domain=nil（没出错）" }
    let n = e as NSError
    return "domain=\(n.domain) code=\(n.code) userInfo键=\(n.userInfo.keys.sorted())"
}
/// 字典的键名列表（AnyHashable → String 再排序）：options / sqlitePragmas / userInfo 都是这种字典
func keyNames(_ d: [AnyHashable: Any]?) -> [String] {
    guard let d else { return [] }
    return d.keys.compactMap { $0 as? String }.sorted()
}
/// 把 fd 2 临时指向 /dev/null 跑一段，跑完恢复：见文件头第三条约束
func quiet(_ body: () -> Void) {
    let saved = dup(2)
    let dn = open("/dev/null", O_RDWR)
    _ = dup2(dn, 2)
    close(dn)
    body()
    _ = dup2(saved, 2)
    close(saved)
}

// ------------------------------------------------------------
// CoreData 模型：本章全程用**代码构造**的模型（没有 .xcdatamodeld 文件）
//   Note{title:String?, stars:Int32(必填), author→Author}
//   Author{name:String?, notes→[Note]}
// ------------------------------------------------------------
func attr(_ name: String, _ type: NSAttributeType, _ optional: Bool) -> NSAttributeDescription {
    let a = NSAttributeDescription()
    a.name = name
    a.attributeType = type
    a.isOptional = optional
    return a
}
func rel(_ name: String, _ dest: NSEntityDescription, toMany: Bool, rule: NSDeleteRule) -> NSRelationshipDescription {
    let r = NSRelationshipDescription()
    r.name = name
    r.destinationEntity = dest
    r.minCount = 0
    r.maxCount = toMany ? 0 : 1
    r.deleteRule = rule
    return r
}
/// 建一对互相指向的实体；deleteRule 两侧分别给
func makeModel(noteRule: NSDeleteRule = .nullifyDeleteRule,
               authorRule: NSDeleteRule = .cascadeDeleteRule)
    -> (model: NSManagedObjectModel, note: NSEntityDescription, author: NSEntityDescription) {
    let note = NSEntityDescription(); note.name = "Note"
    let author = NSEntityDescription(); author.name = "Author"
    let rNA = rel("author", author, toMany: false, rule: noteRule)
    let rAN = rel("notes", note, toMany: true, rule: authorRule)
    rNA.inverseRelationship = rAN
    rAN.inverseRelationship = rNA
    note.properties = [attr("title", .stringAttributeType, true),
                       attr("stars", .integer32AttributeType, false), rNA]
    author.properties = [attr("name", .stringAttributeType, true), rAN]
    let m = NSManagedObjectModel()
    // 故意把 Note 放在声明顺序的第一位：§11 会量 Z_ENT 到底按不按这个顺序
    m.entities = [note, author]
    return (m, note, author)
}
/// 一个建在临时目录里的文件型 store；路径不打印，只用来做后面的对照
func makeContainer(_ model: NSManagedObjectModel, tag: String,
                   tune: (NSPersistentStoreDescription) -> Void = { _ in })
    -> (NSPersistentContainer, URL) {
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("c26-\(tag).sqlite")
    for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: url.path + suffix) }
    let c = NSPersistentContainer(name: "c26", managedObjectModel: model)
    let d = NSPersistentStoreDescription(url: url)
    tune(d)
    c.persistentStoreDescriptions = [d]
    c.loadPersistentStores { _, _ in }
    return (c, url)
}
/// 拿 SQLite 的裸句柄去开 CoreData 正在用的那个库文件
/// 用给定 url 打开一个 store，loadPersistentStores 包在 quiet 里（失败时 CoreData 会往 stderr 打整段带路径的日志）
func loaded(_ m: NSManagedObjectModel, _ url: URL, readOnly: Bool = false) -> (NSPersistentContainer, String) {
    let c = NSPersistentContainer(name: "c26", managedObjectModel: m)
    let d = NSPersistentStoreDescription(url: url)
    d.isReadOnly = readOnly
    c.persistentStoreDescriptions = [d]
    var e = "?"
    quiet { c.loadPersistentStores { _, err in e = errInfo(err) } }
    return (c, e)
}
func rawHandle(_ url: URL) -> OpaquePointer? {
    var db: OpaquePointer?
    _ = sqlite3_open(url.path, &db)
    return db
}
func storeURL(_ c: NSPersistentContainer) -> URL {
    c.persistentStoreCoordinator.persistentStores.first?.url
        ?? URL(fileURLWithPath: NSTemporaryDirectory())
}
let (model, eNote, eAuthor) = makeModel()

// ============================================================
// §1 import SQLite3：它从哪来，以及那批返回码到底是几
// ============================================================
line("== 1) import SQLite3：它从哪来，以及那批返回码到底是几 ==")
line("  libversion=\(sp(sqlite3_libversion())) libnumber=\(sqlite3_libversion_number()) sourceid 前 8 字符=\(String(cString: sqlite3_sourceid()).prefix(8))")
line("  状态码：OK=\(SQLITE_OK) ROW=\(SQLITE_ROW) DONE=\(SQLITE_DONE) ERROR=\(SQLITE_ERROR) MISUSE=\(SQLITE_MISUSE) RANGE=\(SQLITE_RANGE)")
line("  约束码：CONSTRAINT=\(SQLITE_CONSTRAINT) PRIMARYKEY 扩展码=\(SQLITE_CONSTRAINT | (6 << 8)) BUSY=\(SQLITE_BUSY)")
line("  值类型码：INTEGER=\(SQLITE_INTEGER) FLOAT=\(SQLITE_FLOAT) BLOB=\(SQLITE_BLOB) NULL=\(SQLITE_NULL) TEXT=\(SQLITE_TEXT)")
expect(scalar(nil, "SELECT 1").contains("prepare失败") && (SQLITE_CONSTRAINT | (6 << 8)) == 1555,
       "iOS SDK 里就带着 SQLite：`import SQLite3` 直接可用（本文件第 3 个 import），不需要 -lsqlite3、",
       "不需要桥接头，也不需要在本示例的 Frameworks 文件里列它 —— SDK 的 usr/include 下有 SQLite3.modulemap，",
       "顶层 module.modulemap 又写了 extern module \"SQLite3\"，Swift 就把这个 C 模块当库来用；",
       "但**链接期并没有 libSQLite3.tbd**，硬写 -framework SQLite3 会直接 ld: framework 'SQLite3' not found。",
       "读回来的版本是这台工具链（iPhoneSimulator18.2.sdk）里的 3.43.2 / 3043002 / sourceid 前缀 2023-10，",
       "换一份 Xcode 就是另一批数字，所以本章所有常量都是打印出来对照的，不是背出来的。",
       "版本号本身有个算术关系可用来验算：3043002 == 3*1000000 + 43*1000 + 2。",
       "真正要记住的只有形状：ROW=100、DONE=101 是大数字而不是 0/1（写过 if sqlite3_step(st) == 1 的人都在这里翻过车），",
       "MISUSE=21、RANGE=25 也不挨着；CONSTRAINT=19 只是**主码**，",
       "它下面还有一整套扩展码（PRIMARYKEY = 19 + 256*6 = 1555），默认拿不到，§6 现场演示那个开关。",
       "顺带这一行的 expect 条件也说明了一件事：对一个根本没打开的 NULL 连接调 prepare 也是失败（返回 MISUSE），",
       "不会崩 —— 而失败之后 errmsg 给的是 'out of memory'，§2 展开。")
line("")

// ============================================================
// §2 打开连接：三种「打开」和出厂 PRAGMA
// ============================================================
line("== 2) 打开连接：三种「打开」和出厂 PRAGMA ==")
var mdb: OpaquePointer?
let rcMem = sqlite3_open(":memory:", &mdb)
line("  open(\":memory:\") rc=\(rcMem) 句柄有值=\(mdb != nil)")
line("  内存库出厂 PRAGMA：journal_mode=\(scalar(mdb, "PRAGMA journal_mode")) encoding=\(scalar(mdb, "PRAGMA encoding")) foreign_keys=\(scalar(mdb, "PRAGMA foreign_keys")) user_version=\(scalar(mdb, "PRAGMA user_version"))")
var magicDB: OpaquePointer?
let rcMagic = sqlite3_open("", &magicDB)
line("  open(\"\")（空串不是魔法文件名）rc=\(rcMagic) 句柄有值=\(magicDB != nil) 表数量=\(scalar(magicDB, "SELECT count(*) FROM sqlite_master"))")
sqlite3_close_v2(magicDB)
var nullNameDB: OpaquePointer?
let rcNullName = sqlite3_open(nil, &nullNameDB)
line("  open(NULL 文件名) rc=\(rcNullName) 句柄有值=\(nullNameDB != nil) errmsg=\(sp(sqlite3_errmsg(nullNameDB)))")
line("  对 NULL 句柄动真格：exec 返回 \(sqlite3_exec(nil, "SELECT 1", nil, nil, nil))，errmsg(NULL) 给 '\(sp(sqlite3_errmsg(nil)))'，close_v2(NULL) 返回 \(sqlite3_close_v2(nil))")
line("  拿这个「打开成功」的句柄执行一条 SQL：rc=\(sqlite3_exec(nullNameDB, "CREATE TABLE t(x)", nil, nil, nil)) errmsg=\(sp(sqlite3_errmsg(nullNameDB)))")
sqlite3_close_v2(nullNameDB)
let rcVersion = sqlite3_exec(mdb, "PRAGMA user_version=7;", nil, nil, nil)
line("  user_version 是可以直接写的应用槽位：exec rc=\(rcVersion) 读回=\(scalar(mdb, "PRAGMA user_version"))")
sqlite3_close_v2(mdb)
expect(rcNullName == SQLITE_OK && rcMem == SQLITE_OK,
       "SQLite 的 C API **不校验空指针的场合比想象中多**，三条路都通到「看起来没事」：\n",
       "  · open 传 NULL 文件名 → 返回 0（成功），给你一个**匿名临时库**：建表插入都合法（上面那行 rc=0），",
       "只是它不在任何路径上，关掉就没了，也没法再打开一次 —— 你的数据全在里面，而你以为写进了文件；\n",
       "  · open 传空串 → 同上，和 :memory: 也不是一回事（:memory: 是共享名字，空串是每次私有）；\n",
       "  · 对根本没打开的 NULL 句柄调 errmsg → 不是 'invalid handle'、也不崩，而是 '\(sp(sqlite3_errmsg(nil)))'，",
       "一句和真实原因毫不相干的谎。\n",
       "这三条是同一个教训：这一层的返回值必须**每一次都判**，判不过就立刻停，",
       "因为 SQLite 既不替你兜住「你传了个空」，也不替你保留真正的失败原因。",
       "另外记四个出厂值：journal_mode 对内存库是 memory（对文件库是 wal，§11 现场对比）；",
       "encoding 是 UTF-8（跟连接走，不看你的字符串内容）；**foreign_keys 是 0** —— ",
       "外键约束默认关闭，这是「SQLite 为什么不报错」最常见的一个原因（§6 现场验证）；",
       "user_version 出厂 0，是给应用自己用的整数槽位，PRAGMA user_version=7 写进去就能读回来，",
       "很多不用 CoreData 的项目就靠它做自己的 schema 版本迁移（§14 会看到 CoreData **完全不维护它**，读完还是 0）。")
line("")

// ============================================================
// §3 准备语句：一段文本两条语句，tail 才是循环的推进方式
// ============================================================
line("== 3) 准备语句：一段文本两条语句，tail 与 nByte ==")
var pdb: OpaquePointer?
_ = sqlite3_open(":memory:", &pdb)
_ = sqlite3_exec(pdb, "CREATE TABLE t(id INTEGER PRIMARY KEY, name TEXT);", nil, nil, nil)
let two = "SELECT 1; SELECT 2;"
two.withCString { p in
    var st: OpaquePointer?
    var tail: UnsafePointer<CChar>?
    let rc = sqlite3_prepare_v2(pdb, p, -1, &st, &tail)
    line("  \"\(two)\" 一次 prepare：rc=\(rc) 第一条列数=\(sqlite3_column_count(st)) step=\(sqlite3_step(st)) 值=\(colText(st, 0))")
    line("  tail 指向原文第 \(tail.map { Int($0 - p) } ?? -1) 个字节，内容='\(sp(tail))'（开头有个空格）")
    sqlite3_finalize(st)
    if let t = tail {
        var st2: OpaquePointer?
        let rc2 = sqlite3_prepare_v2(pdb, t, -1, &st2, nil)
        line("  拿 tail 再 prepare 第二条：rc=\(rc2) step=\(sqlite3_step(st2)) 值=\(colText(st2, 0))")
        sqlite3_finalize(st2)
    }
}
let mixed = "INSERT INTO t(id,name) VALUES(7,'七'); SELECT name FROM t WHERE id=7;"
mixed.withCString { p in
    var s1: OpaquePointer?
    var t1: UnsafePointer<CChar>?
    _ = sqlite3_prepare_v2(pdb, p, -1, &s1, &t1)
    line("  第一条是 INSERT：step=\(sqlite3_step(s1))（DONE=101，不是 ROW）last_insert_rowid=\(sqlite3_last_insert_rowid(pdb)) changes=\(sqlite3_changes(pdb))")
    sqlite3_finalize(s1)
    var s2: OpaquePointer?
    _ = sqlite3_prepare_v2(pdb, t1, -1, &s2, nil)
    line("  第二条（由 tail 得到）：step=\(sqlite3_step(s2)) 值=\(colText(s2, 0))")
    sqlite3_finalize(s2)
}
let badSecond = "SELECT 1; SELEKT 2;"
badSecond.withCString { p in
    var s1: OpaquePointer?
    var t1: UnsafePointer<CChar>?
    let rc = sqlite3_prepare_v2(pdb, p, -1, &s1, &t1)
    line("  坏在第二条：第一条 rc=\(rc) tail='\(sp(t1))' —— prepare 只看第一条")
    sqlite3_finalize(s1)
    var s2: OpaquePointer?
    let rc2 = sqlite3_prepare_v2(pdb, t1, -1, &s2, nil)
    line("  于是错误要等 prepare 第二条才现形：rc=\(rc2) 句柄还是 nil=\(s2 == nil) errmsg=\(sp(sqlite3_errmsg(pdb)))")
}
do {
    let s = "SELECT 'abcdef', 7;"
    s.withCString { p in
        var st: OpaquePointer?
        let rc12 = sqlite3_prepare_v2(pdb, p, 12, &st, nil)
        line("  nByte=12（正好切在字符串字面量中间）：rc=\(rc12) errmsg=\(sp(sqlite3_errmsg(pdb)))")
        var st2: OpaquePointer?
        let rc18 = sqlite3_prepare_v2(pdb, p, 18, &st2, nil)
        line("  nByte=18（只是少了结尾分号）：rc=\(rc18) step=\(sqlite3_step(st2)) 两列=\(colText(st2, 0))/\(colText(st2, 1))")
        sqlite3_finalize(st); sqlite3_finalize(st2)
    }
}
line("  语句级只读判定：stmt_readonly(SELECT)=\(pdb.flatMap { d in withStmt(d, "SELECT 1;") { sqlite3_stmt_readonly($0) } } ?? -1) "
     + "stmt_readonly(INSERT)=\(pdb.flatMap { d in withStmt(d, "INSERT INTO t(id,name) VALUES(8,'八');") { sqlite3_stmt_readonly($0) } } ?? -1) "
     + "db_readonly(内存库)=\(pdb.map { sqlite3_db_readonly($0, "main") } ?? -1)")
expect(withStmt(pdb, "SELECT 1;") { sqlite3_stmt_readonly($0) } == 1,
       "把这几段放在一起，说明 **prepare 不是「执行」**：它只做词法/语法分析并交出第一条语句，",
       "剩下的字节从输出参数 tail 拿。所以「一次跑一整段 SQL 文本」的正确循环是",
       "`while tail 没走到结尾 { 拿 tail 再 prepare }`；",
       "写成「prepare 一次然后指望它把整段跑完」的人会撞到本节的第三种情形：",
       "第一条好、第二条坏 —— **prepare 返回 SQLITE_OK，坏语句一根汗毛都没暴露**，",
       "直到拿 tail 去 prepare 才看到上面那行的 'near \"SELEKT\": syntax error'。",
       "另一个细节是 nByte：-1 表示「到 NUL 为止」，给正数就**按字节硬切**，",
       "切在 token 中间得到的是 unrecognized token，而不是「少了个分号」这种温和错误；",
       "少了分号反而完全没事（SQLite 不要求最后一条带分号）。",
       "只读判定分两层：sqlite3_stmt_readonly 是**语句**级的（SELECT=1 / INSERT=0），",
       "sqlite3_db_readonly 是**连接**级的（正常打开都是 0，除非用 SQLITE_OPEN_READONLY 打开），",
       "判断「这条语句能不能安全地在只读事务里跑」要用前者。")
line("")

// ============================================================
// §4 绑定：参数名、越界、没绑的槽位
// ============================================================
line("== 4) 绑定：参数名、越界、没绑的槽位 ==")
var bdb: OpaquePointer?
_ = sqlite3_open(":memory:", &bdb)
_ = sqlite3_exec(bdb, "CREATE TABLE p(id INTEGER PRIMARY KEY, a TEXT, b REAL);", nil, nil, nil)
var stQ: OpaquePointer?
_ = sqlite3_prepare_v2(bdb, "INSERT INTO p(a,b) VALUES(?, ?);", -1, &stQ, nil)
line("  两个问号：bind_parameter_count=\(sqlite3_bind_parameter_count(stQ)) name(1)='\(sp(sqlite3_bind_parameter_name(stQ, 1)))' index(\"?\")=\(sqlite3_bind_parameter_index(stQ, "?"))")
var stN: OpaquePointer?
_ = sqlite3_prepare_v2(bdb, "INSERT INTO p(a,b) VALUES($AAA, :bbb);", -1, &stN, nil)
line("  具名参数：count=\(sqlite3_bind_parameter_count(stN)) name(1)='\(sp(sqlite3_bind_parameter_name(stN, 1)))' name(2)='\(sp(sqlite3_bind_parameter_name(stN, 2)))'")
line("  按名字问索引：index(\"$AAA\")=\(sqlite3_bind_parameter_index(stN, "$AAA")) index(\":bbb\")=\(sqlite3_bind_parameter_index(stN, ":bbb")) index(\"$aaa\")=\(sqlite3_bind_parameter_index(stN, "$aaa"))")
let rcOob0 = sqlite3_bind_int(stN, 0, 1)
let rcOob3 = sqlite3_bind_int(stN, 3, 1)
let oobMsg = sp(sqlite3_errmsg(bdb))
line("  越界索引：idx=0 → \(rcOob0)，idx=3 → \(rcOob3)（SQLITE_RANGE=\(SQLITE_RANGE)），当场 errmsg='\(oobMsg)'")
let rcStepUnbound = sqlite3_step(stN)
line("  一个都不绑，直接 step：rc=\(rcStepUnbound) 表里行数=\(scalar(bdb, "SELECT count(*) FROM p")) a 列的 typeof=\(scalar(bdb, "SELECT typeof(a) FROM p LIMIT 1"))")
sqlite3_finalize(stN)
let tmpStr = "临时字符串"
var rcBindPair: (Int32, Int32) = (-1, -1)
tmpStr.withCString { cString in
    rcBindPair = (sqlite3_bind_text(stQ, 1, cString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)),
                 sqlite3_bind_double(stQ, 2, 1.5))
    _ = sqlite3_step(stQ)
}
line("  绑 TEXT（第 4 个参数给 -1，即 C 里的 SQLITE_TRANSIENT）rc=\(rcBindPair.0)，绑 REAL rc=\(rcBindPair.1)")
line("  表里两行原样（第 1 行是没绑就 step 的，第 2 行是绑过的）：\(allRows(bdb, "SELECT id, a, b, typeof(a), typeof(b) FROM p ORDER BY id", 5))")
let rcStepAgain = sqlite3_step(stQ)
line("  同一条语句 step 到底之后再 step：rc=\(rcStepAgain)（MISUSE=\(SQLITE_MISUSE)）；reset rc=\(sqlite3_reset(stQ)) 再 step rc=\(sqlite3_step(stQ))")
sqlite3_finalize(stQ)
expect(rcOob0 == SQLITE_RANGE && rcOob3 == SQLITE_RANGE && rcStepUnbound == SQLITE_DONE,
       "参数索引**从 1 开始**，0 和 count+1 一样都是越界，越界给的是 RANGE=25 而不是崩溃 —— ",
       "也就是说 bind 失败可以「静默过去」：本节接着 step，那条 INSERT 照样成功，",
       "两个槽位都按 NULL 存进去（typeof 读回来是 '\(scalar(bdb, "SELECT typeof(a) FROM p LIMIT 1"))'）。",
       "**这是「数据莫名变成空」的经典成因**：bind 的返回值没判，或者 if/else 少走了一分支，",
       "SQLite 不会拒绝你，它把没绑的槽当 NULL。",
       "越界那一瞬间 errmsg 确实是 '\(oobMsg)'，但**一次成功的 step 就把它冲回 'not an error'**（§6 末尾同一件事再来一次），",
       "所以 errmsg 只适合打日志，不适合用来判断「这次到底成没成」。",
       "三个细节：`?` 这种匿名参数 name 返回 NULL、index(\"?\") 返回 0（问不出来，只能按位置绑）；",
       "具名参数大小写敏感（$AAA 与 $aaa 是两个槽，问后者得到 0）；",
       "第四个参数在 C 里是 SQLITE_TRANSIENT / SQLITE_STATIC 两个**宏**，",
       "Swift 里这两个名字根本不存在（直接写会 cannot find 'SQLITE_TRANSIENT' in scope），",
       "只能像本节这样 unsafeBitCast(-1, to: sqlite3_destructor_type.self) 手搓 TRANSIENT 的语义。",
       "STATIC（给 0）的意思是「这块内存我保证活得比 stmt 久」，",
       "而 Swift 的 String.withCString 只在闭包内保证指针有效，所以本章一律用 TRANSIENT；",
       "谁在这里图省事写了 0，就是一个 use-after-free 级别的偶发乱码。",
       "最后一行是生命周期：一条语句 step 到 DONE 之后再 step 返回 MISUSE，必须先 reset（返回 0）才能再跑 —— ",
       "「绑新参数 → reset → step」就是批量插入的正确节奏，而 CoreData 把这整套节奏都替你做了（§16）。")
line("")

// ============================================================
// §5 列的六种读法，与「类型亲和」到底亲和了什么
// ============================================================
line("== 5) 列的六种读法，与「类型亲和」 ==")
var cdb: OpaquePointer?
_ = sqlite3_open(":memory:", &cdb)
_ = sqlite3_exec(cdb, "CREATE TABLE c(i INTEGER, r REAL, s TEXT, b BLOB, n INTEGER);", nil, nil, nil)
_ = sqlite3_exec(cdb, "INSERT INTO c VALUES(4, 4.0, 'hello', X'DEAD', NULL);", nil, nil, nil)
_ = sqlite3_exec(cdb, "INSERT INTO c(i,r,s,b,n) VALUES(10,'24','24abc',42,'7z');", nil, nil, nil)
var stBad: OpaquePointer?
let rcNoSuch = sqlite3_prepare_v2(cdb, "SELECT nosuch FROM c", -1, &stBad, nil)
line("  列名写错在 **prepare** 就失败：rc=\(rcNoSuch) errmsg=\(sp(sqlite3_errmsg(cdb)))")
var stc: OpaquePointer?
_ = sqlite3_prepare_v2(cdb, "SELECT i, r, s, b, n, i+1 FROM c LIMIT 1;", -1, &stc, nil)
_ = sqlite3_step(stc)
line("  列数=\(sqlite3_column_count(stc)) 列名=\((0..<6).map { sp(sqlite3_column_name(stc, Int32($0))) }.joined(separator: ","))")
line("  decltype（建表时声明的类型）=\((0..<6).map { sp(sqlite3_column_decltype(stc, Int32($0))) }.joined(separator: ","))")
line("  运行时类型码=\((0..<6).map { "\(sqlite3_column_type(stc, Int32($0)))" }.joined(separator: ","))（INTEGER=1 TEXT=3 BLOB=4 NULL=5）")
line("  同一列的不同取法：int(r)=\(sqlite3_column_int(stc, 1)) double(r)=\(sqlite3_column_double(stc, 1)) text(r)='\(colText(stc, 1))' int(s)=\(sqlite3_column_int(stc, 2)) text(i)='\(colText(stc, 0))'")
line("  NULL 列（第 5 列）：type=\(sqlite3_column_type(stc, 4)) text 指针 nil=\(sqlite3_column_text(stc, 4) == nil) blob 指针 nil=\(sqlite3_column_blob(stc, 4) == nil) bytes=\(sqlite3_column_bytes(stc, 4)) int=\(sqlite3_column_int(stc, 4)) double=\(sqlite3_column_double(stc, 4))")
sqlite3_finalize(stc)
line("  亲和性现场：INTEGER 列存 '24abc' 之后 typeof=\(scalar(cdb, "SELECT typeof(s) FROM c WHERE i=10")) 值='\(scalar(cdb, "SELECT s FROM c WHERE i=10"))'，REAL 列存 '24' → typeof=\(scalar(cdb, "SELECT typeof(r) FROM c WHERE i=10")) 值=\(scalar(cdb, "SELECT r+0 FROM c WHERE i=10"))")
line("  BLOB 列（第二行给了整数 42）：typeof=\(scalar(cdb, "SELECT typeof(b) FROM c WHERE i=10")) length()=\(scalar(cdb, "SELECT length(b) FROM c WHERE i=10")) column_blob 指针 nil=\(withStmt(cdb, "SELECT b FROM c WHERE i=10") { sqlite3_column_blob($0, 0) == nil } ?? true) 先 column_bytes 再取指针 nil=\(withStmt(cdb, "SELECT b FROM c WHERE i=10") { _ = sqlite3_column_bytes($0, 0); return sqlite3_column_blob($0, 0) == nil } ?? true)")
line("  CAST 才是显式转换：CAST(s AS INTEGER)='\(scalar(cdb, "SELECT CAST(s AS INTEGER) FROM c WHERE i=4"))'（'hello' 转不成数），CAST('24abc' AS INTEGER)='\(scalar(cdb, "SELECT CAST(s AS INTEGER) FROM c WHERE i=10"))'（前缀 24 被吃下来了）")
expect(scalar(cdb, "SELECT CAST(s AS INTEGER) FROM c WHERE i=4") == "0",
       "这一节是 SQLite「弱类型 + 类型亲和」的真面目。先说最容易埋雷的：TEXT 的 'hello' 用 ",
       "sqlite3_column_int 读是 **0**，不报错、不返回 nil、errmsg 也不动 —— 它只是尽力转换，转不动就给 0。",
       "REAL 的 4.0 用 text 读回来是 '4.0'（带小数点），用 int 读是 4；这两个方向都不抛异常，",
       "所以「列读出来是 0」既可能是数据真是 0，也可能是读法不对。",
       "第二件事：列**不会**把你要的类型当约束。INTEGER 列塞 '24abc' 就按 TEXT 存着（typeof 读回 text），",
       "因为声明类型只决定「亲和性」——能转成整数才转（'24' 转成 REAL 24，'7z' 这种转不动的原样存）。",
       "想要硬约束只有两条路：CHECK 约束，或者 §6 现场演示的 foreign_keys（它默认还是关的）。",
       "BLOB 那行更阴：往 BLOB 列塞整数 42，它不会变成 blob（typeof 读回 integer，length() 按字符数给 2），",
       "而 column_blob **直接返回 NULL 指针** —— 明明有值却读不到字节，先调 column_bytes 也一样。",
       "要真拿二进制就存 X'DEAD' 这种 blob 字面量，读的时候 column_blob + column_bytes 成对用；",
       "第三件事最危险：NULL 那一行 text 和 blob 两个指针**都是 NULL**，bytes=0，int=0，double=0.0。",
       "所以任何 String(cString: sqlite3_column_text(...)) 都是在赌这列不是 NULL，",
       "赌输的现场是 Swift 的一句 Unexpectedly found nil + signal 4；",
       "本章所有列读取都走 colText / scalar / row / allRows 四个包装函数，先判指针再按 bytes 长度解码。",
       "顺便：column_text 的返回类型是 UnsafeMutablePointer<UInt8>?（不是 CChar），",
       "所以它**不能**直接喂给 String(cString:)，只能 String(decoding:as:UTF8.self)。",
       "第四件事是 decltype：它给的是**建表时写的声明类型**，表达式列（i+1）没有声明类型 → NULL，",
       "判「这列现在装的是什么」必须用 typeof() 或 sqlite3_column_type()，别拿 decltype 当运行时类型。",
       "还有列名写错的时机：'no such column' 是在 **prepare** 就返回 ERROR（不是 step），",
       "所以列名拼错会在建语句句柄那一步立刻暴露 —— 这也是 CoreData 的 fetch 里拼错属性名会抛错的原因（§15）。")
line("")

// ============================================================
// §6 主码 / 扩展码，以及外键默认关闭
// ============================================================
line("== 6) 主码与扩展码：同一个错，两种说法 ==")
var edb: OpaquePointer?
_ = sqlite3_open(":memory:", &edb)
_ = sqlite3_exec(edb, "CREATE TABLE k(id INTEGER PRIMARY KEY, tag TEXT NOT NULL);", nil, nil, nil)
_ = sqlite3_exec(edb, "INSERT INTO k(id,tag) VALUES(1,'甲');", nil, nil, nil)
let rcDup = sqlite3_exec(edb, "INSERT INTO k(id,tag) VALUES(1,'乙');", nil, nil, nil)
line("  主键重复：exec rc=\(rcDup) errcode=\(sqlite3_errcode(edb)) extended_errcode=\(sqlite3_extended_errcode(edb)) errmsg=\(sp(sqlite3_errmsg(edb)))")
line("  不开扩展时拿不到 1555，只有主码 \(SQLITE_CONSTRAINT)；扩展码的构成是 主码 + 256*子序号：19 + 256*6 = \(SQLITE_CONSTRAINT | (6 << 8))")
let rcNotNull = sqlite3_exec(edb, "INSERT INTO k(id) VALUES(2);", nil, nil, nil)
line("  同一层里的 NOT NULL 违约：rc=\(rcNotNull)，也就是主码 \(rcNotNull & 0xFF)，**开关没开时看不出色子**；同一时刻 sqlite3_extended_errcode 已经能问出 \(sqlite3_extended_errcode(edb)) = 19 + 256*\((sqlite3_extended_errcode(edb) >> 8))，errmsg=\(sp(sqlite3_errmsg(edb)))")
let rcExtOn = sqlite3_extended_result_codes(edb, 1)
let rcDup2 = sqlite3_exec(edb, "INSERT INTO k(id,tag) VALUES(1,'丙');", nil, nil, nil)
line("  sqlite3_extended_result_codes(db,1) rc=\(rcExtOn) 之后再犯同一个错：rc=\(rcDup2)（返回值本身升级了）errmsg=\(sp(sqlite3_errmsg(edb)))")
line("  开关打开之后 sqlite3_errcode 也跟着返回扩展码：同一时刻 errcode=\(sqlite3_errcode(edb)) extended=\(sqlite3_extended_errcode(edb))")
line("  errmsg 只记录**最后一次调用**，成功一次就清空：紧跟着插一行 rc=\(sqlite3_exec(edb, "INSERT INTO k(id,tag) VALUES(3,'丁');", nil, nil, nil))，errmsg 立刻变回 '\(sp(sqlite3_errmsg(edb)))'")
_ = sqlite3_exec(edb, "CREATE TABLE child(pid INTEGER REFERENCES k(id), note TEXT);", nil, nil, nil)
let rcOrphan = sqlite3_exec(edb, "INSERT INTO child VALUES(999,'父不存在');", nil, nil, nil)
line("  外键默认关：往 REFERENCES k(id) 的列插一个不存在的父键 rc=\(rcOrphan) errmsg='\(sp(sqlite3_errmsg(edb)))'")
_ = sqlite3_exec(edb, "PRAGMA foreign_keys=ON;", nil, nil, nil)
line("  PRAGMA foreign_keys=ON 之后 foreign_keys=\(scalar(edb, "PRAGMA foreign_keys"))")
let rcOrphan2 = sqlite3_exec(edb, "INSERT INTO child VALUES(998,'还是不存在');", nil, nil, nil)
line("  同一个错再犯一次：rc=\(rcOrphan2) extended=\(sqlite3_extended_errcode(edb)) errmsg=\(sp(sqlite3_errmsg(edb)))")
expect(rcDup == SQLITE_CONSTRAINT && rcDup2 == SQLITE_CONSTRAINT | (6 << 8),
       "这一节的核心是**同一个错误有两种说法**。默认 rc 给的是主码 19（SQLITE_CONSTRAINT），",
       "想知道到底是「主键重复」「外键没父」「CHECK 失败」还是「NOT NULL 缺失」，",
       "要么看 errmsg 的文本（做产品可以，做逻辑判断不行），要么用 sqlite3_extended_errcode 显式问扩展码，",
       "要么调 sqlite3_extended_result_codes(db,1) 让**返回值本身**升一级（19 + 256*子序号，主键重复就是 1555）。",
       "注意开关是**连接级**的：换一条连接就得重设一遍。",
       "第二件事：NOT NULL 违约的主码也是 19（rc & 0xFF），子序号却是 5（1299 = 19 + 256*5），",
       "主键重复是 6，外键没父是 3 —— **想知道是哪一类约束只有扩展码办得到**。",
       "还要知道那个开关的副作用：打开之后 sqlite3_errcode **也**返回扩展码（上面倒数第二行两个数字相等就是证据），",
       "所以判 `rc == SQLITE_CONSTRAINT` 的代码在有的连接上会突然不再成立 —— 开关要么全局统一，要么用主码掩码。",
       "errmsg 只记最后一次调用：紧跟着一次成功的 INSERT 就把它冲回 'not an error'，",
       "所以它只能用来打日志，不能当「最近一次错误历史」查，也不能用来判断这次成没成 —— 判 rc 才对。",
       "第三件事值得单独抄一遍：**外键默认是关的**（§2 的出厂 PRAGMA 已经给了 0），",
       "所以带 REFERENCES 的表照样能插进没有父记录的孤儿子行，rc=0、errmsg 说 'not an error'。",
       "这不是 bug，是 SQLite 的历史默认值；要么每条连接都 PRAGMA foreign_keys=ON（CoreData 不给你开，§11 见），",
       "要么就别指望这层约束。开了之后同一个错立刻变成 rc=\(rcOrphan2)，扩展码 \(sqlite3_extended_errcode(edb))，",
       "errmsg 变成 'FOREIGN KEY constraint failed' —— 一句之差就是「脏数据静默入库」和「当场拒绝」。")
line("")

// ============================================================
// §7 事务、changes 计数与「没 finalize 就 close」
// ============================================================
line("== 7) 事务、changes 计数、close 的两种脾气 ==")
var tdb: OpaquePointer?
_ = sqlite3_open(":memory:", &tdb)
_ = sqlite3_exec(tdb, "CREATE TABLE g(x INTEGER);", nil, nil, nil)
line("  出厂：autocommit=\(sqlite3_get_autocommit(tdb))（1＝每条语句自己就是一个事务）")
let rcB = sqlite3_exec(tdb, "BEGIN;", nil, nil, nil)
let rcIn = sqlite3_exec(tdb, "INSERT INTO g VALUES(1); INSERT INTO g VALUES(2);", nil, nil, nil)
line("  BEGIN rc=\(rcB) 两条 INSERT rc=\(rcIn) 事务内 autocommit=\(sqlite3_get_autocommit(tdb)) changes()=\(scalar(tdb, "SELECT changes()")) total_changes()=\(scalar(tdb, "SELECT total_changes()"))")
let rcNested = sqlite3_exec(tdb, "BEGIN;", nil, nil, nil)
line("  事务没结束再 BEGIN：rc=\(rcNested) errmsg=\(sp(sqlite3_errmsg(tdb)))（autocommit 还是 \(sqlite3_get_autocommit(tdb))，前两条 INSERT 没被它毁掉）")
let rcSp = sqlite3_exec(tdb, "SAVEPOINT sp1; INSERT INTO g VALUES(3); RELEASE sp1;", nil, nil, nil)
line("  要嵌套只能用 SAVEPOINT：rc=\(rcSp) 行数=\(scalar(tdb, "SELECT count(*) FROM g"))")
let rcCommit = sqlite3_exec(tdb, "COMMIT;", nil, nil, nil)
line("  COMMIT rc=\(rcCommit) 之后 autocommit=\(sqlite3_get_autocommit(tdb)) 行数=\(scalar(tdb, "SELECT count(*) FROM g"))")
_ = sqlite3_exec(tdb, "BEGIN; INSERT INTO g VALUES(99); ROLLBACK;", nil, nil, nil)
line("  BEGIN/INSERT/ROLLBACK：行数=\(scalar(tdb, "SELECT count(*) FROM g")) 但 total_changes 仍然把回滚掉的算进去了=\(scalar(tdb, "SELECT total_changes()"))")
let rcRollNoTrans = sqlite3_exec(tdb, "ROLLBACK;", nil, nil, nil)
line("  不在事务里 ROLLBACK：rc=\(rcRollNoTrans) errmsg=\(sp(sqlite3_errmsg(tdb)))")
let rcUpd = sqlite3_exec(tdb, "UPDATE g SET x=0 WHERE x=12345;", nil, nil, nil)
line("  changes 是**语句级**的：插一行 rc=\(sqlite3_exec(tdb, "INSERT INTO g VALUES(9);", nil, nil, nil)) changes=\(scalar(tdb, "SELECT changes()"))；紧接着 UPDATE 一行都不命中 rc=\(rcUpd) changes=\(scalar(tdb, "SELECT changes()")) 而 x=0 的行数=\(scalar(tdb, "SELECT count(*) FROM g WHERE x=0"))")
var leaky: OpaquePointer?
_ = sqlite3_prepare_v2(tdb, "SELECT count(*) FROM g;", -1, &leaky, nil)
let rcClose = sqlite3_close(tdb)
line("  留着没 finalize 的 stmt 去 close：rc=\(rcClose) errmsg=\(sp(sqlite3_errmsg(tdb)))")
let rcCloseV2 = sqlite3_close_v2(tdb)
line("  同一个句柄改用 close_v2：rc=\(rcCloseV2)（它答应「有未完成的语句也放行」，见 §11 CoreData 的收尾）")
expect(rcNested == SQLITE_ERROR && rcClose == SQLITE_BUSY,
       "SQLite 的事务是**扁平**的：事务没结束再 BEGIN 直接 rc=\(rcNested)（ERROR），",
       "errmsg 就是上面那行引号里的 'cannot start a transaction within a transaction'（它不带任何「你的数据怎么样了」的信息），",
       "好消息是它**不会**把已有事务撕开（autocommit 还是 \(sqlite3_get_autocommit(tdb))），坏消息是很多封装层就是这么把外面的 BEGIN 提前 COMMIT 掉的；",
       "要嵌套只有 SAVEPOINT/RELEASE/ROLLBACK TO 这一条路（上面刚跑过，rc=\(rcSp)），",
       "或者先查 sqlite3_get_autocommit()：返回 1 才说明当前不在事务里，这时才可以 BEGIN。",
       "计数有两个：changes() 只说**上一条语句**影响了几行（UPDATE 不命中就是 0，DDL 也是 0），",
       "total_changes() 说这条连接打开以来累计了几行，**连回滚掉的也一并累计**（上面 ROLLBACK 之后它照涨），",
       "所以用它判断「这次有没有改到数据」是错的，用它做遥测才对；不在事务里 ROLLBACK 也给 rc=\(rcRollNoTrans)。",
       "还有 close：留着一个没 finalize 的 stmt 去 sqlite3_close，返回 \(rcClose)（SQLITE_BUSY，不是错误码里的 SUCCESS），",
       "库**没有被关**，连接还在；这条路径上是内存与文件句柄泄漏的经典来源（Swift 里 OpaquePointer 不走 ARC，",
       "忘了 finalize 就是真忘了）。sqlite3_close_v2 则是「有未完成的语句也照样放行，",
       "等最后一个游标关掉时再真正释放」，所以本节的第二次调用返回 0。",
       "官方建议：新代码一律用 close_v2，除非你确实需要「漏了 finalize」这件事以错误码的形式暴露出来 —— ",
       "上面那两行就是让你看见两种脾气的差别。")
line("")

// ============================================================
// §8 exec + callback + 自定义函数
// ============================================================
line("== 8) sqlite3_exec 的回调，和往 SQL 里塞一个 Swift 函数 ==")
var fdb: OpaquePointer?
_ = sqlite3_open(":memory:", &fdb)
_ = sqlite3_exec(fdb, "CREATE TABLE s(id INTEGER, name TEXT); INSERT INTO s VALUES(1,'甲'),(2,'乙');", nil, nil, nil)
final class RowBox { var rows: [String] = [] }
let box = RowBox()
let rcExecCB = sqlite3_exec(fdb, "SELECT id, name FROM s ORDER BY id;", { p, n, vals, names in
    guard let p, let vals, let names else { return 1 }
    let b = Unmanaged<RowBox>.fromOpaque(p).takeUnretainedValue()
    var hdr: [String] = []
    var cols: [String] = []
    for i in 0..<Int(n) { hdr.append(sp(names[i])); cols.append(sp(vals[i])) }
    b.rows.append(hdr.joined(separator: ",") + "|" + cols.joined(separator: ","))
    return 0
}, Unmanaged.passUnretained(box).toOpaque(), nil)
line("  exec 带 callback：rc=\(rcExecCB) 回调次数=\(box.rows.count) 每行收到的列数=\(box.rows.map { $0.split(separator: "|").last?.split(separator: ",").count ?? 0 })")
line("  第 1 次回调：列名=\(box.rows.first?.split(separator: "|").first.map(String.init) ?? "?") 值=\(box.rows.first?.split(separator: "|").last.map(String.init) ?? "?")")
let rcExecAbort = sqlite3_exec(fdb, "SELECT id, name FROM s;", { p, _, _, _ in
    Unmanaged<RowBox>.fromOpaque(p!).takeUnretainedValue().rows.append("中止")
    return 7   // 非 0：立刻中止整个 exec
}, Unmanaged.passUnretained(box).toOpaque(), nil)
line("  回调返回 7（非 0）：rc=\(rcExecAbort) 表里本来有 2 行，回调只被叫了 \((box.rows.count - 2)) 次")
var cbErr: UnsafeMutablePointer<CChar>?
let rcExecErr = sqlite3_exec(fdb, "SELECT id FROM s; SELEKT 2;", nil, nil, &cbErr)
line("  exec 里第二条坏：rc=\(rcExecErr) 第 5 个参数给='\(sp(cbErr))'，db 的 errmsg='\(sp(sqlite3_errmsg(fdb)))'")
sqlite3_free(cbErr)
func sqlLen(_ ctx: OpaquePointer?, _ argc: Int32, _ argv: UnsafeMutablePointer<OpaquePointer?>?) {
    guard argc == 1, let v = argv?[0], sqlite3_value_type(v) != SQLITE_NULL else { sqlite3_result_null(ctx); return }
    sqlite3_result_int(ctx, sqlite3_value_bytes(v))
}
let rcCreate = sqlite3_create_function(fdb, "mylen", 1, SQLITE_UTF8, nil, sqlLen, nil, nil)
line("  sqlite3_create_function(\"mylen\", argc=1) rc=\(rcCreate)（第三个参数 SQLITE_ANY=\(SQLITE_ANY) 在头文件里注释成 Deprecated，所以给 SQLITE_UTF8=\(SQLITE_UTF8)）")
line("  在 SQL 里当普通函数用：mylen('hi')=\(scalar(fdb, "SELECT mylen('hi')")) mylen(12345)=\(scalar(fdb, "SELECT mylen(12345)")) mylen('中文')=\(scalar(fdb, "SELECT mylen('中文')")) typeof(mylen('hi'))=\(scalar(fdb, "SELECT typeof(mylen('hi'))"))")
line("  参数是 NULL：mylen(NULL) 用 column_text 读=\(withStmt(fdb, "SELECT mylen(NULL)" ) { colText($0, 0) } ?? "prepare失败")（result_null → text 指针是 NULL）")
var stArity: OpaquePointer?
let rcArity = sqlite3_prepare_v2(fdb, "SELECT mylen()", -1, &stArity, nil)
line("  参数个数不对：prepare 'SELECT mylen()' rc=\(rcArity) errmsg=\(sp(sqlite3_errmsg(fdb)))")
var stArity2: OpaquePointer?
let rcArity2 = sqlite3_prepare_v2(fdb, "SELECT mylen(1,2)", -1, &stArity2, nil)
line("  多给一个参数：rc=\(rcArity2) errmsg=\(sp(sqlite3_errmsg(fdb)))（注册时 argc 写死，问不出来）")
sqlite3_close_v2(fdb)
expect(rcExecCB == SQLITE_OK && box.rows.count == 3 && rcExecAbort != SQLITE_OK && rcCreate == SQLITE_OK,
       "sqlite3_exec 是「一次跑多条语句」的便捷壳：它内部就是 prepare+step 循环，",
       "每出一行调一次回调，回调拿到 (用户指针, 列数, 值数组, 列名数组)，返回非 0 就**中止整个 exec**。",
       "注意回调里给的值是 C 字符串数组：NULL 列在回调里同样是 NULL 指针，所以 sp() 那个包装在这里也是必需品。",
       "错误信息有两份：exec 的第五个参数（要自己 sqlite3_free，否则泄漏）和 db 的 errmsg；",
       "本节让第二条语句坏，两份都非空但措辞一样，rc=\(rcExecErr)（ERROR）—— 第一条其实已经跑完并出了行。",
       "自定义函数是 SQLite 最有意思的一块：sqlite3_create_function 注册一个 @convention(c) 函数之后，",
       "SQL 里就能写 mylen(...)，而且它会**进到查询计划里**（WHERE 里也能用）。",
       "两个必须记住的限制：回调必须是**不捕获任何 Swift 上下文**的函数（本节的 sqlLen 只能读参数、写结果），",
       "参数个数在注册时就定死，写错个数是 prepare 期错误（上面那行 'wrong number of arguments to function mylen()'），",
       "而不是运行时才崩 —— 这跟 CoreData 的自定义 NSEntityDescription 校验完全不是一个路子。",
       "最后：sqlite3_value_text 对 NULL 参数给 NULL 指针，所以本节选择 result_null；",
       "如果像很多教程那样直接 strlen(t)，NULL 就会被当成某个长度算进去，得到一个说不清来源的数字。")
line("")

// ============================================================
// §9 CoreData 侧：代码构造的模型，和它的一堆出厂默认值
// ============================================================
line("== 9) CoreData 的程序化模型：出厂值比想象中多 ==")
line("  model.entities 声明顺序=\(model.entities.map { $0.name ?? "?" }) 而 entitiesByName 的键=\(model.entitiesByName.keys.sorted())")
line("  Note.managedObjectClassName=\(String(describing: eNote.managedObjectClassName)) isAbstract=\(eNote.isAbstract) 属性数=\(eNote.properties.count) 父实体=\(String(describing: eNote.superentity))")
line("  NSAttributeType 的 rawValue（一百一档）：undefined=\(NSAttributeType.undefinedAttributeType.rawValue) integer16=\(NSAttributeType.integer16AttributeType.rawValue) integer32=\(NSAttributeType.integer32AttributeType.rawValue) integer64=\(NSAttributeType.integer64AttributeType.rawValue)")
line("  …decimal=\(NSAttributeType.decimalAttributeType.rawValue) double=\(NSAttributeType.doubleAttributeType.rawValue) float=\(NSAttributeType.floatAttributeType.rawValue) string=\(NSAttributeType.stringAttributeType.rawValue) boolean=\(NSAttributeType.booleanAttributeType.rawValue) date=\(NSAttributeType.dateAttributeType.rawValue)")
line("  …binaryData=\(NSAttributeType.binaryDataAttributeType.rawValue) UUID=\(NSAttributeType.UUIDAttributeType.rawValue) URI=\(NSAttributeType.URIAttributeType.rawValue) transformable=\(NSAttributeType.transformableAttributeType.rawValue) objectID=\(NSAttributeType.objectIDAttributeType.rawValue) composite=\(NSAttributeType(rawValue: 2100).map { String($0.rawValue) } ?? "枚举里没有这一档")")
let bare = attr("x", .integer32AttributeType, true)
line("  刚 new 出来、什么都没设的 NSAttributeDescription：attributeType=\(bare.attributeType.rawValue) isOptional=\(bare.isOptional) isTransient=\(bare.isTransient) defaultValue=\(String(describing: bare.defaultValue))")
line("  …attributeValueClassName=\(String(describing: bare.attributeValueClassName)) versionHash 字节数=\(bare.versionHash.count) userInfo 键=\(keyNames(bare.userInfo))")
let bareRel = NSRelationshipDescription()
line("  刚 new 出来的 NSRelationshipDescription：deleteRule=\(bareRel.deleteRule.rawValue)（**不是 0**）isOptional=\(bareRel.isOptional) minCount=\(bareRel.minCount) maxCount=\(bareRel.maxCount) inverse=\(String(describing: bareRel.inverseRelationship))")
line("  NSDeleteRule 四档 rawValue：noAction=\(NSDeleteRule.noActionDeleteRule.rawValue) nullify=\(NSDeleteRule.nullifyDeleteRule.rawValue) cascade=\(NSDeleteRule.cascadeDeleteRule.rawValue) deny=\(NSDeleteRule.denyDeleteRule.rawValue)")
expect(bareRel.deleteRule == .nullifyDeleteRule && bare.attributeType == .integer32AttributeType,
       "CoreData 这一层和 SQLite 最大的差别从这里开始：**它不看你的字符串，它看对象**。",
       "本节的模型是纯代码构造的（没有 .xcdatamodeld、没有 NSManagedObject 子类，全部用 NSManagedObject + setValue(forKey:)），",
       "这样本章每个数字都能自己跑出来给你看。几个出厂值必须记，因为它们跟直觉不合：",
       "NSAttributeType 的 rawValue 是**一百一档**（string=700、integer32=200、date=900、transformable=1800），",
       "不是从 0 连排的序号，所以拿 rawValue 当数组下标、或者存进自己的设置里再猜含义，一定会猜错；",
       "新 new 的属性默认是 integer32（不是 undefined）、isOptional=true、",
       "attributeValueClassName 是 NSNumber（只有字符串属性才会变成 NSString），",
       "versionHash 是 32 字节 —— 就是 §14 那两个迁移错误 userInfo 里的 NSStoreModelVersionHashes。",
       "最反直觉的是关系：**新关系的 deleteRule 默认是 nullify(1)**，不是 noAction(0) —— ",
       "也就是说你忘写删除规则时，CoreData 会把关系断开而不是留下悬空引用（§12 用四种规则各跑一遍，看它们在 SQL 层分别做了什么）。",
       "还有一个只在代码构造模型时才会撞到的坑：关系**必须**被塞进 entity.properties 里，",
       "只给 inverseRelationship 和 destinationEntity 是不够的 —— 探针里直接对没进 properties 的关系调 setValue(forKey:\"author\")，",
       "得到的是 NSUnknownKeyException（\"this class is not key value coding-compliant for the key author.\"）+ signal 6，",
       "而报错的对象类名是 NSManagedObject 本身，看起来像是 KVC 用错了字段，其实是模型没装配完整。")
line("")

// ============================================================
// §10 NSPersistentContainer 与 NSPersistentStoreDescription 的出厂值
// ============================================================
line("== 10) 容器与 store 描述：谁替你填了哪些默认值 ==")
let bareContainer = NSPersistentContainer(name: "c26-bare", managedObjectModel: model)
let bd = bareContainer.persistentStoreDescriptions.first!
line("  工厂容器自带的描述：count=\(bareContainer.persistentStoreDescriptions.count) type=\(bd.type) url 有值=\(bd.url != nil) url 末段=\(bd.url?.lastPathComponent ?? "<nil>")")
line("  迁移两开关：shouldMigrateStoreAutomatically=\(bd.shouldMigrateStoreAutomatically) shouldInferMappingModelAutomatically=\(bd.shouldInferMappingModelAutomatically) shouldAddStoreAsynchronously=\(bd.shouldAddStoreAsynchronously)")
line("  其它出厂值：timeout=\(bd.timeout) configuration=\(String(describing: bd.configuration)) isReadOnly=\(bd.isReadOnly) options 键=\(keyNames(bd.options)) sqlitePragmas 键=\(keyNames(bd.sqlitePragmas))")
let inMemDesc = NSPersistentStoreDescription()
line("  NSPersistentStoreDescription() **无参**构造：type=\(inMemDesc.type) url=\(inMemDesc.url?.path ?? "<nil>")（不是 nil，是 /dev/null）")
let memContainer = NSPersistentContainer(name: "c26-mem", managedObjectModel: model)
let md = NSPersistentStoreDescription()
md.type = NSInMemoryStoreType
memContainer.persistentStoreDescriptions = [md]
var memLoadErr = "?"
memContainer.loadPersistentStores { desc, err in memLoadErr = errInfo(err) + " 回调给的 type=\(desc.type)" }
line("  内存库 loadPersistentStores：\(memLoadErr) 实际 store 数=\(memContainer.persistentStoreCoordinator.persistentStores.count) 换型之后原描述还有 url=\(md.url != nil)")
let roMissingURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("c26-ro-missing.sqlite")
for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: roMissingURL.path + suffix) }
let (roC1, ro1Err) = loaded(model, roMissingURL, readOnly: true)
line("  isReadOnly=true 打开**不存在**的文件：\(ro1Err) store 数=\(roC1.persistentStoreCoordinator.persistentStores.count)")
let (roC2, roU2) = makeContainer(model, tag: "ro-seed")
let roCtx = roC2.viewContext
let roNote = NSManagedObject(entity: eNote, insertInto: roCtx)
roNote.setValue(1, forKey: "stars"); roNote.setValue("种一条", forKey: "title")
try? roCtx.save()
let (roC3, ro3Err) = loaded(model, roU2, readOnly: true)
line("  isReadOnly=true 打开**已存在**的库：\(ro3Err) store 数=\(roC3.persistentStoreCoordinator.persistentStores.count) 读得到=\(String(describing: (try? roC3.viewContext.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note"))))) 条")
let roWriter = NSManagedObject(entity: model.entitiesByName["Note"]!, insertInto: roC3.viewContext)
roWriter.setValue(9, forKey: "stars")
var roSaveErr = "?"
quiet { do { try roC3.viewContext.save(); roSaveErr = "保存成功（没报错！）" } catch { roSaveErr = errInfo(error) } }
line("  在只读 store 上新增一行再保存：\(roSaveErr) 上下文 hasChanges=\(roC3.viewContext.hasChanges)")
expect(bd.shouldMigrateStoreAutomatically && bd.shouldInferMappingModelAutomatically && !bd.shouldAddStoreAsynchronously,
       "NSPersistentContainer 的价值全在「它替你填了默认值」，这一节把填的东西摊开。",
       "工厂方法给的那一条描述 type 是 SQLite、url 指向 Application Support 下同名文件（本示例的模型没有对应文件，所以只看末段名字），",
       "**两个迁移开关默认都开着**（§14 就靠这一条解释：为什么加一列不写 mapping model 也能跑起来），",
       "shouldAddStoreAsynchronously 默认 false（同步加载，启动慢一点，但回调一定跑过）。",
       "options 出厂就有两个键，正是那两个迁移开关的另一副面孔（同一份设置的 dictionary 形式）；",
       "sqlitePragmas 出厂是空的，timeout 是 240 秒而不是「无穷」，configuration=nil 表示用默认配置名。",
       "一个坑：NSPersistentStoreDescription() 无参构造出来的对象**不是**「什么都没设」——",
       "它的 url 是 file:///dev/null，而 type 仍然报 SQLite（上面那行实测），",
       "也就是说这个默认值是「往 /dev/null 写一个 SQLite 库」；要真拿内存库必须显式设 type=NSInMemoryStoreType，",
       "反过来把 type 改成内存型之后 url 也照样有值 —— 所以判断「这是文件库还是内存库」只能看 type，不能看 url。",
       "还有 options 是**只读属性**，不能 desc.options[k] = v（cannot assign through subscript: 'options' is a get-only property），",
       "只有 setOption(_:forKey:) 和 setValue(_:forPragmaNamed:) 两个 setter，",
       "后者才是真正往 SQLite 下发 PRAGMA 的那一个（§11 现场对比两者的差别）。",
       "最后两条是 isReadOnly：它对**不存在**的文件是直接失败 —— NSCocoaErrorDomain code=260，",
       "userInfo 的 reason 写着 'Attempt to open missing file read only'（CoreData 不会替你创建，也不会退化成读写模式），",
       "store 数因此是 0；打开**已存在**的文件才成立，读得到数据，但一保存就报错，",
       "而且**失败的对象会留在上下文里**（上面 hasChanges 还是 true，跟 §12 的 deny 一模一样要 reset 才能继续）。",
       "顺带这一节的两次失败都用 quiet() 包了：CoreData 的失败日志会把整条绝对路径打到 stderr，",
       "而判定 3 要 stderr 为空、判定 4 要输出可复现（路径里有设备 UUID），所以错误信息由我们自己从 NSError 里取。")
line("")

// ============================================================
// §11 CoreData 写出来的 SQLite 文件长什么样
// ============================================================
line("== 11) 打开 CoreData 的库文件，用 SQLite 的眼睛看它 ==")
let (c11, u11) = makeContainer(model, tag: "schema")
let ctx11 = c11.viewContext
let au11 = NSManagedObject(entity: eAuthor, insertInto: ctx11); au11.setValue("张三", forKey: "name")
for i in 1...2 {
    let n = NSManagedObject(entity: eNote, insertInto: ctx11)
    n.setValue(i == 1 ? "甲" : nil, forKey: "title")
    n.setValue(i == 1 ? 7 : 2, forKey: "stars")
    if i == 1 { n.setValue(au11, forKey: "author") }
}
var save11 = "?"
do { try ctx11.save(); save11 = "保存成功" } catch { save11 = "抛出 \(errInfo(error))" }
line("  两条 Note + 一条 Author：\(save11)（第二条 Note 故意不给 title，它是可选的）")
let db11 = rawHandle(u11)
line("  sqlite_master 里全部条目：\(dump(db11, "SELECT type || ':' || name FROM sqlite_master ORDER BY name"))")
line("  Z_PRIMARYKEY 建表语句：\(dump(db11, "SELECT sql FROM sqlite_master WHERE name='Z_PRIMARYKEY'"))")
line("  Z_PRIMARYKEY 内容（Z_ENT,Z_NAME,Z_SUPER,Z_MAX）：\(dump(db11, "SELECT Z_ENT, Z_NAME, Z_SUPER, Z_MAX FROM Z_PRIMARYKEY ORDER BY Z_ENT"))")
line("  ZNOTE 列明细（cid:name:type:notnull:dflt）：\(dump(db11, "SELECT cid || ':' || name || ':' || type || ':' || \"notnull\" || ':' || COALESCE(dflt_value,'NULL') FROM PRAGMA_table_info('ZNOTE') ORDER BY cid"))")
line("  ZNOTE 的 Z_PK 序列=\(dump(db11, "SELECT Z_PK FROM ZNOTE ORDER BY Z_PK"))（**哪条内容拿哪个号不保证**：探针连跑三次，同一段代码里 title=甲 的记录过 2 也拿过 1 —— CoreData 保存时按内部集合遍历取号，别把 Z_PK 当业务 ID）")
line("  ZNOTE 内容按 ZSTARS 排序（Z_ENT,Z_OPT,ZAUTHOR 是否空,ZTITLE）：\(dump(db11, "SELECT Z_ENT, Z_OPT, (ZAUTHOR IS NULL), COALESCE(ZTITLE,'<NULL>') FROM ZNOTE ORDER BY ZSTARS"))")
line("  建表语句里 FOREIGN KEY 出现的位置=\(dump(db11, "SELECT instr(sql, 'FOREIGN KEY') FROM sqlite_master WHERE name='ZNOTE'")) 而这条连接 PRAGMA foreign_keys=\(scalar(db11, "PRAGMA foreign_keys"))")
line("  ZNOTE 的建表语句原文：\(dump(db11, "SELECT sql FROM sqlite_master WHERE name='ZNOTE'"))")
line("  连接级 PRAGMA：user_version=\(scalar(db11, "PRAGMA user_version")) journal_mode=\(scalar(db11, "PRAGMA journal_mode")) page_size=\(scalar(db11, "PRAGMA page_size")) encoding=\(scalar(db11, "PRAGMA encoding"))")
line("  Z_METADATA 列=\(dump(db11, "SELECT name || ':' || type FROM PRAGMA_table_info('Z_METADATA') ORDER BY cid")) 内容只打非空标记=\(dump(db11, "SELECT Z_VERSION, (Z_UUID IS NOT NULL), (Z_PLIST IS NOT NULL) FROM Z_METADATA"))")
let fm26 = FileManager.default
line("  store 旁边的文件族：主文件=\(fm26.fileExists(atPath: u11.path)) -wal=\(fm26.fileExists(atPath: u11.path + "-wal")) -shm=\(fm26.fileExists(atPath: u11.path + "-shm"))")
line("  wal_checkpoint(PASSIVE) 的 busy 位=\(scalar(db11, "PRAGMA wal_checkpoint(PASSIVE)"))（只打第一列；帧数随页面布局变，本章不打印）")
let (c11p, u11p) = makeContainer(model, tag: "pragma-pragma") { $0.setValue("delete" as NSString, forPragmaNamed: "journal_mode") }
let (c11o, u11o) = makeContainer(model, tag: "pragma-option") { $0.setOption("delete" as NSString, forKey: "journal_mode") }
let (c11t, u11t) = makeContainer(model, tag: "pragma-truncate") { $0.setValue("truncate" as NSString, forPragmaNamed: "journal_mode") }
let dbP = rawHandle(u11p); let dbO = rawHandle(u11o); let dbT = rawHandle(u11t)
line("  setValue(_:forPragmaNamed:) 建的库，外部读 journal_mode=\(scalar(dbP, "PRAGMA journal_mode"))；setOption(_:forKey:) 建的=\(scalar(dbO, "PRAGMA journal_mode"))；给 truncate 的=\(scalar(dbT, "PRAGMA journal_mode"))")
sqlite3_close_v2(dbP); sqlite3_close_v2(dbO); sqlite3_close_v2(dbT)
_ = (c11p, c11o, c11t)
expect(scalar(db11, "PRAGMA foreign_keys") == "0" && dump(db11, "SELECT instr(sql, 'FOREIGN KEY') FROM sqlite_master WHERE name='ZNOTE'") == "0",
       "这一节把「CoreData 底下到底是什么」摊开，六件事一次讲完。",
       "第一，表名列名全部 Z 前缀，实体名大写（Note→ZNOTE、Author→ZAUTHOR），属性名直接大写当列名（ZSTARS/ZTITLE/ZAUTHOR），",
       "所以改属性名就等于改列名 —— 这正是 §14 迁移问题的来源。",
       "第二，除了你的两张表还有三张 CoreData 自己的账本：",
       "Z_PRIMARYKEY（每个实体一个 Z_MAX，记「这个实体用到过的最大主键」，新对象从这里取号；**取号的先后次序不保证** —— 探针连跑三次，同一段代码里两条 Note 的 Z_PK 会互换，所以 Z_PK 只能当内部主键，不能拿来当业务顺序或业务 ID）、",
       "Z_METADATA（模型版本哈希 + store UUID + plist）、Z_MODELCACHE（模型缓存，BLOB，判定 5 不许打内容）。",
       "第三，**Z_ENT 不是声明顺序**：本示例把 Note 写在 entities 数组第一位，但表里 Author=1、Note=2，",
       "因为 CoreData 按实体名**字母序**编号，建表顺序也跟着字母序。",
       "第四，也是最重要的一条：**ZNOTE 的建表语句里没有 FOREIGN KEY 子句**（instr 找那个词返回 0），",
       "关系只是 ZNOTE.ZAUTHOR 一个普通整数列，外加一条建在 (ZAUTHOR) 上的索引；",
       "而 PRAGMA foreign_keys 又正好是 0（§6）。所以「删父行会不会级联」SQLite 完全不知道，",
       "全是 CoreData 在删之前自己算好一批要一起删的行 —— §12 的四种删除规则因此是在**对象图层面**执行的。",
       "第五，journal_mode 是 wal（旁边就有 -wal/-shm 两个文件，上面用 fileExists 验过），",
       "user_version 是 0 —— CoreData 不用 SQLite 那个槽位，它自己的版本写在 Z_METADATA.Z_VERSION（§14）。",
       "第六，PRAGMA 的两条通道实测差别：setValue(_:forPragmaNamed:) 真的下发到 SQLite（外部读到 delete），",
       "setOption(_:forKey:) 只是塞进 CoreData 的 options 字典，键名不属于它认的那一份就完全不生效（外部还是 wal）；",
       "而 truncate / memory 这些值 SQLite 会接受但**不会记住**（重新打开读回来是 delete），journal_mode 只有 WAL/delete 这一档是持久的。")
sqlite3_close_v2(db11)
line("")

// ============================================================
// §12 删除规则、以及绕开 CoreData 直接改它的表
// ============================================================
func ruleName(_ r: NSDeleteRule) -> String {
    switch r {
    case .noActionDeleteRule: return "noAction(0)"
    case .nullifyDeleteRule: return "nullify(1)"
    case .cascadeDeleteRule: return "cascade(2)"
    case .denyDeleteRule: return "deny(3)"
    default: return "other(\(r.rawValue))"
    }
}
/// 1 个 Author + 2 条 Note，存好；返回容器、库文件、父对象
func seed(_ m: NSManagedObjectModel, _ tag: String) -> (NSPersistentContainer, URL, NSManagedObject) {
    let (c, u) = makeContainer(m, tag: tag)
    let ctx = c.viewContext
    let au = NSManagedObject(entity: m.entitiesByName["Author"]!, insertInto: ctx)
    au.setValue("父", forKey: "name")
    for i in 1...2 {
        let n = NSManagedObject(entity: m.entitiesByName["Note"]!, insertInto: ctx)
        n.setValue(i, forKey: "stars")
        n.setValue("t\(i)", forKey: "title")
        n.setValue(au, forKey: "author")
    }
    try! ctx.save()
    return (c, u, au)
}
/// 只打形状：谁被删了、谁被置空、谁悬空，以及 Z_MAX 记账
func shape(_ db: OpaquePointer?) -> String {
    "父行=\(scalar(db, "SELECT count(*) FROM ZAUTHOR")) 子行=\(scalar(db, "SELECT count(*) FROM ZNOTE"))"
        + " 子的父键为空=\(scalar(db, "SELECT count(*) FROM ZNOTE WHERE ZAUTHOR IS NULL"))"
        + " 真悬空=\(scalar(db, "SELECT count(*) FROM ZNOTE WHERE ZAUTHOR IS NOT NULL AND ZAUTHOR NOT IN (SELECT Z_PK FROM ZAUTHOR)"))"
        + " NOT IN 裸写法=\(scalar(db, "SELECT count(*) FROM ZNOTE WHERE ZAUTHOR NOT IN (SELECT Z_PK FROM ZAUTHOR)"))"
        + " Z_MAX(按字母序)=\(dump(db, "SELECT Z_NAME || '=' || Z_MAX FROM Z_PRIMARYKEY ORDER BY Z_ENT"))"
}
func trySave(_ ctx: NSManagedObjectContext) -> String {
    var e = "?"
    quiet { do { try ctx.save(); e = "保存成功" } catch { e = "抛出 \(errInfo(error))" } }
    return e
}
line("== 12) 四种删除规则在 SQL 层各做了什么，和绕开 CoreData 直接改表 ==")
var deleteOutcome: [String] = []
var outcomeShapes: [String] = []
var denyMessage = "?"
for rule in [NSDeleteRule.noActionDeleteRule, .nullifyDeleteRule, .cascadeDeleteRule, .denyDeleteRule] {
    let m = makeModel(noteRule: rule, authorRule: rule).model
    line("  -- 删父对象 Author，两侧规则都是 \(ruleName(rule)) --")
    let (c, u, au) = seed(m, "dr\(rule.rawValue)")
    let db = rawHandle(u)
    line("    删之前：\(shape(db))")
    c.viewContext.delete(au)
    let e = trySave(c.viewContext)
    let afterShape = shape(db)
    line("    删+存：\(e)  删之后：\(afterShape)")
    deleteOutcome.append(e.hasPrefix("抛出") ? "抛出" : "保存成功")
    outcomeShapes.append(afterShape)
    if rule == .denyDeleteRule { denyMessage = e }
    if e.hasPrefix("抛出") {
        line("    失败之后上下文没干净：hasChanges=\(c.viewContext.hasChanges) deletedObjects=\(c.viewContext.deletedObjects.count)")
        line("    不 reset 直接再存一次：\(trySave(c.viewContext))")
        c.viewContext.reset()
        line("    reset 之后 hasChanges=\(c.viewContext.hasChanges)，再存：\(trySave(c.viewContext))  表=\(shape(db))")
        let note = NSFetchRequest<NSManagedObject>(entityName: "Author")
        line("    父对象还在库里吗（同上下文 fetch 数）=\(String(describing: try? c.viewContext.count(for: note)))")
    }
    // 从不遍历 notes 关系，只 fetch 父对象删掉
    let (c2, u2, _) = seed(m, "dr\(rule.rawValue)b")
    let db2 = rawHandle(u2)
    let ctx2 = c2.viewContext
    let auList = (try? ctx2.fetch(NSFetchRequest<NSManagedObject>(entityName: "Author"))) ?? []
    if let au2 = auList.first {
        ctx2.delete(au2)
        line("    从不读 notes 关系，只删父：\(trySave(ctx2))  表=\(shape(db2))")
    }
    sqlite3_close_v2(db); sqlite3_close_v2(db2)
}
line("")
var childCascade = "?"
var childDeny = "?"
for rule in [NSDeleteRule.cascadeDeleteRule, .denyDeleteRule] {
    let m = makeModel(noteRule: rule, authorRule: .nullifyDeleteRule).model
    line("  -- 反过来删子对象 Note，只把 to-one 侧 Note.author 设成 \(ruleName(rule))（Author.notes 固定 nullify）--")
    let (c, u, _) = seed(m, "ch\(rule.rawValue)")
    let db = rawHandle(u)
    let ctx = c.viewContext
    let req = NSFetchRequest<NSManagedObject>(entityName: "Note")
    req.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: true)]
    let note = ((try? ctx.fetch(req)) ?? []).first!
    let beforeChild = shape(db)
    ctx.delete(note)
    let childSave = trySave(ctx)
    let afterChild = shape(db)
    if rule == .cascadeDeleteRule { childCascade = afterChild }
    if rule == .denyDeleteRule { childDeny = childSave }
    line("    删之前：\(beforeChild)  删+存：\(childSave)  删之后：\(afterChild)")
    sqlite3_close_v2(db)
}
expect(deleteOutcome == ["保存成功", "保存成功", "保存成功", "抛出"] && denyMessage.contains("code=1600")
       && outcomeShapes[0].contains("真悬空=2") && outcomeShapes[1].contains("子的父键为空=2")
       && outcomeShapes[2].contains("子行=0") && outcomeShapes[3].contains("父行=1 子行=2")
       && childCascade.contains("父行=0") && childCascade.contains("子的父键为空=1") && childDeny.contains("code=1600"),
       "§11 已经量到 ZNOTE 的建表语句里没有 FOREIGN KEY 子句、PRAGMA foreign_keys 又是 0，所以「删父行会怎样」SQLite 一概不知，",
       "全是 CoreData 在 save 时按模型里的删除规则自己生成 SQL —— 这一节把四档规则各自的 SQL 后果摊开（上面每一行都是真跑出来的）。",
       "**noAction 不是 RESTRICT**：它只删父行，子行留着，ZAUTHOR 还指着已经不存在的 Z_PK（上面「真悬空=2」），",
       "SQLite 不报错、CoreData 也不报错，数据就此烂掉 —— 想要「拦住」得用 deny，想要「留个洞」才是 nullify。",
       "**nullify 把子行的键置空**（子的父键为空=2），行都还在；这也是 §9 量的出厂值（新关系默认 nullify=1）。",
       "**cascade 把子行一起删干净**（子行=0），而且**跟你有没有遍历过关系无关**：",
       "上面第二段同一规则、只 fetch 父对象、从不去读 author/notes，结果一样 —— CoreData 是自己在 SQL 层查了那批子行的。",
       "**deny 不写任何东西**：save 抛 NSCocoaErrorDomain code=1600，userInfo 的键是 NSValidationErrorObject/Key/Value 那一族",
       "（它是**校验错误**，不是 SQL 错误 —— 所以 domain 不是 NSSQLiteErrorDomain），表里父行子行一个没少。",
       "然后是最容易栽的半步：deny 失败之后**上下文并不干净**（hasChanges 还是 true、deletedObjects 还是 1），",
       "紧接着再 save 会**再抛一次同样的错**；必须先 `reset()`（或 discardChanges），上面 reset 之后那句「保存成功」",
       "是一次空保存 —— 父对象还在库里（fetch 数=1），不是「第二次删成功了」。",
       "删子对象那一半更值得记：把 to-one 侧 Note.author 设成 cascade，删**一条 Note** 会**把它的 Author 也删掉**（父行=0），",
       "然后 Author 自己那条 nullify 规则接着在**另一条 Note** 上生效（子的父键为空=1）—— 删除规则是沿对象图双向传播的，",
       "两侧互相影响，最后写成什么样的 SQL 取决于两侧的规则，而不取决于你觉得「谁是父」。",
       "同理，to-one 侧设成 deny，那么**任何挂在父对象上的子对象都删不掉**（上面第二次 1600），这是很常见的「我明明只删一条，为什么保存总失败」。")
line("  -- C) 用 C API 直接读写 CoreData 的表 --")
let (c12, u12) = makeContainer(model, tag: "raw-io")
let ctx12 = c12.viewContext
let au12 = NSManagedObject(entity: eAuthor, insertInto: ctx12); au12.setValue("p", forKey: "name")
for i in 1...2 {
    let n = NSManagedObject(entity: eNote, insertInto: ctx12)
    n.setValue(i, forKey: "stars"); n.setValue("t\(i)", forKey: "title"); n.setValue(au12, forKey: "author")
}
try! ctx12.save()
let db12 = rawHandle(u12)
let byTitle = "SELECT ZTITLE || ' 的 Z_OPT=' || Z_OPT || ' stars=' || ZSTARS FROM ZNOTE ORDER BY ZTITLE"
let pkSet = "SELECT Z_PK FROM ZNOTE ORDER BY Z_PK"
line("    起点：\(dump(db12, byTitle))  Z_PK 集合=\(dump(db12, pkSet))  \(shape(db12))")
let req12 = NSFetchRequest<NSManagedObject>(entityName: "Note")
req12.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: true)]
let got12 = (try! ctx12.fetch(req12))
got12[0].setValue(50, forKey: "stars")
try! ctx12.save()
line("    CoreData 改 stars=1 那条为 50 并存盘：\(dump(db12, byTitle))")
_ = sqlite3_exec(db12, "UPDATE ZNOTE SET ZSTARS=99 WHERE ZTITLE='t2'", nil, nil, nil)
line("    手工 UPDATE t2 的 stars=99（没碰 Z_OPT）：\(dump(db12, byTitle))")
_ = sqlite3_exec(db12, "INSERT INTO ZNOTE (Z_PK,Z_ENT,Z_OPT,ZSTARS,ZTITLE) VALUES (3,2,1,42,'raw3')", nil, nil, nil)
line("    手工 INSERT 占住 3 号（Z_MAX 仍是 \(scalar(db12, "SELECT Z_MAX FROM Z_PRIMARYKEY WHERE Z_NAME='Note'"))）：\(dump(db12, byTitle))  Z_PK 集合=\(dump(db12, pkSet))")
let cnt12 = (try? ctx12.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? -1
line("    老上下文（它只认识 2 条）count(for:)=\(cnt12)  fetch 到的标题=\((try! ctx12.fetch(req12)).map { $0.value(forKey: "title") as? String ?? "nil" }.sorted().joined(separator: ","))")
let c12b = NSPersistentContainer(name: "c26", managedObjectModel: model)
c12b.persistentStoreDescriptions = [NSPersistentStoreDescription(url: u12)]
c12b.loadPersistentStores { _, _ in }
let ctx12b = c12b.newBackgroundContext()
var fresh12 = "?"
quiet { ctx12b.performAndWait { fresh12 = "新上下文 count=\(((try? ctx12b.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? -1))" } }
line("    \(fresh12)（同一条 SQL，只是换了个上下文）")
var collide12 = "?"
quiet {
    ctx12b.performAndWait {
        let n = NSManagedObject(entity: eNote, insertInto: ctx12b)
        n.setValue(7, forKey: "stars"); n.setValue("cd4", forKey: "title")
        do { try ctx12b.save(); collide12 = "保存成功" } catch { collide12 = "抛出 \(errInfo(error))" }
    }
}
line("    让 CoreData 自己新增一条（它从 Z_MAX+1 取号，而 3 号已被手工占掉）：\(collide12)")
line("    失败之后账本自己动了：\(shape(db12))  Z_PK 集合=\(dump(db12, pkSet))")
_ = sqlite3_exec(db12, "UPDATE Z_PRIMARYKEY SET Z_MAX=9 WHERE Z_NAME='Note'", nil, nil, nil)
var retry12 = "?"
quiet {
    ctx12b.performAndWait {
        ctx12b.reset()
        let n = NSManagedObject(entity: eNote, insertInto: ctx12b)
        n.setValue(7, forKey: "stars"); n.setValue("cd5", forKey: "title")
        do { try ctx12b.save(); retry12 = "保存成功" } catch { retry12 = "抛出 \(errInfo(error))" }
    }
}
line("    手工把 Z_MAX 抬到 9 再新增：\(retry12)  Z_PK 集合=\(dump(db12, pkSet))  \(shape(db12))")
let rcBad = sqlite3_exec(db12, "INSERT INTO ZNOTE (Z_PK,Z_ENT,Z_OPT,ZSTARS,ZTITLE) VALUES (20,99,1,1,'badEnt')", nil, nil, nil)
let rcNoOpt = sqlite3_exec(db12, "INSERT INTO ZNOTE (Z_PK,Z_ENT,ZSTARS,ZTITLE) VALUES (21,2,5,'noOpt')", nil, nil, nil)
line("    两条手工 INSERT 的 rc：Z_ENT=99 那条=\(rcBad)（errmsg=\(sp(sqlite3_errmsg(db12)))），不给 Z_OPT 那条=\(rcNoOpt)（errmsg=\(sp(sqlite3_errmsg(db12)))）")
var cnt12c = -1
quiet { ctx12b.performAndWait { cnt12c = (try? ctx12b.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? -1 } }
line("    再手工插两行：一行 Z_ENT=99（这个实体编号根本不存在）、一行不给 Z_OPT："
     + "表里 \(scalar(db12, "SELECT count(*) FROM ZNOTE")) 行，CoreData 的 count(for:)=\(cnt12c)"
     + "  新行的 Z_OPT=\(scalar(db12, "SELECT COALESCE(CAST(Z_OPT AS TEXT),'NULL') FROM ZNOTE WHERE Z_PK=21"))")
line("    CoreData 眼里这两行的内容：\(dump(db12, "SELECT ZTITLE || ':' || Z_ENT || ':' || COALESCE(CAST(Z_OPT AS TEXT),'NULL') FROM ZNOTE WHERE Z_PK IN (20,21) ORDER BY Z_PK"))")
expect(cnt12 == 3 && collide12.contains("code=133020") && shape(db12).contains("Note=10"),
       "C 这一半讲「绕开 CoreData 直接写它的表」要付的四笔账，每一条都是上面真跑出来的。",
       "**第一笔：Z_OPT 是 CoreData 的行版本号，只有它自己会维护**。",
       "CoreData 改一条并存盘，那行 Z_OPT 从 1 变 2；同一条 SQL 手工 UPDATE 别的列，Z_OPT 纹丝不动（t2 一直是 1）。",
       "它不是时间戳，是「这行被 CoreData 存过几次」的计数，用来做 §13 的变更判断和冲突检测；",
       "手工插的行给 1 能用（上面 raw3 之后所有查询都正常），干脆不给也能读出来（noOpt 那行 Z_OPT=NULL 照样被 count 到），",
       "但那意味着这一行没有版本号可用 —— 属于「别这么干」，不是「没事」。",
       "**第二笔：外部写的行 CoreData 立刻看得见**，不用重开 store —— 老上下文 count(for:)=3、fetch 也把 raw3 取了回来，",
       "因为 count/fetch 每次都要跑一遍 SQL；反过来说，**它不会通知你这个上下文里已经存在的对象被别人改了**（§13、§17）。",
       "**第三笔：取号只看 Z_PRIMARYKEY.Z_MAX，不扫表**。CoreData 新增对象拿的是 Z_MAX+1（这里是 3），",
       "而 3 号已经被手工行占了 → save 抛 NSCocoaErrorDomain code=133020，userInfo 键是 conflictList（冲突清单）和 NSExceptionOmitCallstacks。",
       "更麻烦的是**这次失败并不回滚账本**：Z_MAX 已经被推到 3（号先预定再插），所以后面把 Z_MAX 抬到 9 再新增，",
       "拿到的是 10 而不是 4。手工写它的表就必须**同时**维护这张表（UPDATE Z_PRIMARYKEY SET Z_MAX=(SELECT max(Z_PK) FROM ZNOTE) 之类），",
       "或者干脆用 §16 的批量请求走 CoreData 自己的通道。",
       "**第四笔：Z_ENT 不是查询条件**。插一行 Z_ENT=99（模型里根本没有这个实体号），",
       "Note 的 count(for:) 仍然是 6 行全算、fetch 也把它当 Note 读出来 —— 这个版本的 CoreData 对没有子实体的实体就是 `SELECT … FROM ZNOTE`，不加 Z_ENT 过滤。",
       "所以「行藏在别的实体号下面」这种事不会发生，Z_ENT 只在实体继承（Z_SUPER 那条链）时才有意义；",
       "有继承时查询会怎么加条件本章没测，留给诚实边界。",
       "最后一个小坑，是数悬空行时踩的：nullify 那一档里「子的父键为空=2」但**裸写 `ZAUTHOR NOT IN (SELECT Z_PK FROM ZAUTHOR)` 也数到 2** ——",
       "父表已经空了，`NULL NOT IN (空集合)` 在 SQLite 里为真，于是把刚被置空的行也算成悬空。",
       "查孤儿一定要写成 `ZAUTHOR IS NOT NULL AND ZAUTHOR NOT IN (…)`，上面两个数分别是 0 和 2 就是这个差。")
sqlite3_close_v2(db12)
line("")
// ============================================================
// §13 对象生命周期：objectID 的三段身份、fault、多上下文
// ============================================================
/// 跑一段可能 throws 的检查，把结果或错误收成一行（CoreData 失败时往 stderr 打的那段用 quiet 吞掉）
func attempt(_ body: () throws -> String) -> String {
    var out = ""
    quiet { do { out = try body() } catch { out = "抛出 \(errInfo(error))" } }
    return out
}
/// 只关心成不抛的调用（save 这种返回 Void 的）
func attemptVoid(_ body: () throws -> Void) -> String {
    var out = "成功"
    quiet { do { try body() } catch { out = "抛出 \(errInfo(error))" } }
    return out
}
/// 用 SQLite 眼睛看文件里的 Note 行（每次现开现关，不占着 CoreData 的连接）
func fileNotes(_ u: URL) -> String {
    let d = rawHandle(u)
    let s = "行数=\(scalar(d, "SELECT count(*) FROM ZNOTE")) Z_MAX=\(scalar(d, "SELECT Z_MAX FROM Z_PRIMARYKEY WHERE Z_NAME='Note'"))"
    sqlite3_close_v2(d)
    return s
}
line("== 13) 对象的身份：objectID、fault、以及第二个上下文 ==")
let (c13, u13) = makeContainer(model, tag: "lifecycle")
let ctx13 = c13.viewContext
let mp13 = ctx13.mergePolicy as? NSMergePolicy
line("  viewContext 出厂：concurrencyType=\(ctx13.concurrencyType.rawValue) parent=\(ctx13.parent == nil ? "nil" : "有") 有 coordinator=\(ctx13.persistentStoreCoordinator != nil) automaticallyMergesChangesFromParent=\(ctx13.automaticallyMergesChangesFromParent) includesPendingChanges 默认=\(NSFetchRequest<NSManagedObject>(entityName: "Note").includesPendingChanges) mergePolicy 实际类型=\(String(describing: type(of: ctx13.mergePolicy))) 能收成 NSMergePolicy 吗=\(mp13 != nil) mergeType raw=\(mp13.map { Int($0.mergeType.rawValue) } ?? -1) undoManager 有吗=\(ctx13.undoManager != nil)")
let n13 = NSManagedObject(entity: eNote, insertInto: ctx13)
n13.setValue(1, forKey: "stars"); n13.setValue("idx", forKey: "title")
let uriTmp = n13.objectID.uriRepresentation()
var idChangeEvents = 0
let obs13 = n13.observe(\.objectID, options: [.old, .new]) { _, _ in idChangeEvents += 1 }
line("  刚 insert、还没存：isTemporaryID=\(n13.objectID.isTemporaryID) uri.scheme=\(uriTmp.scheme ?? "nil") host 有没有=\(uriTmp.host != nil) 路径段数=\(uriTmp.pathComponents.count) 末段首字符=\(uriTmp.lastPathComponent.prefix(1)) entity 名=\(n13.objectID.entity.name ?? "nil")")
line("  这时拿它的 objectID 去 existingObject(with:)：\(attempt { _ = try ctx13.existingObject(with: n13.objectID); return "拿到了" })")
line("  没 save 就 obtainPermanentIDs(for:)：\(attemptVoid { try ctx13.obtainPermanentIDs(for: [n13]) }) isTemporaryID=\(n13.objectID.isTemporaryID) host 长度=\(n13.objectID.uriRepresentation().host?.count ?? -1) 末段首字符=\(n13.objectID.uriRepresentation().lastPathComponent.prefix(1)) objectID 的 KVO 触发次数=\(idChangeEvents)")
try! ctx13.save()
let uriSaved = n13.objectID.uriRepresentation()
line("  存盘之后：isTemporaryID=\(n13.objectID.isTemporaryID) uri 变成 scheme=\(uriSaved.scheme ?? "nil") host 长度=\(uriSaved.host?.count ?? -1) 路径段数=\(uriSaved.pathComponents.count) 末段首字符=\(uriSaved.lastPathComponent.prefix(1)) KVO 累计=\(idChangeEvents)")
line("  拿永久 ID 反查对象：\(attempt { let o = try ctx13.existingObject(with: n13.objectID); return "跟原来同一个实例吗=\(o === n13) 标题=\(o.value(forKey: "title") as? String ?? "nil")" })")
line("  拿 store 描述里另一个 URL 的容器反查同一个 ID：\(attempt { let other = NSPersistentContainer(name: "c26-other", managedObjectModel: model); other.persistentStoreDescriptions = [NSPersistentStoreDescription(url: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("c26-elsewhere.sqlite"))]; quiet { other.loadPersistentStores { _, _ in } }; _ = try other.viewContext.existingObject(with: n13.objectID); return "居然拿到了" } )")
obs13.invalidate()
line("")
line("  -- fault：什么时候才真的去查库 --")
let (c13f, u13f) = makeContainer(model, tag: "faults")
let seed13 = c13f.viewContext
let au13f = NSManagedObject(entity: eAuthor, insertInto: seed13); au13f.setValue("pa", forKey: "name")
for i in 1...3 {
    let n = NSManagedObject(entity: eNote, insertInto: seed13)
    n.setValue(i, forKey: "stars"); n.setValue("f\(i)", forKey: "title"); n.setValue(au13f, forKey: "author")
}
try! seed13.save()
line("    库里有 3 条 Note：\(fileNotes(u13f))")
let ctxB = c13f.newBackgroundContext()
quiet {
    ctxB.performAndWait {
        let r = NSFetchRequest<NSManagedObject>(entityName: "Note")
        r.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: true)]
        let rows = (try! ctxB.fetch(r))
        line("    fetch 回来 \(rows.count) 条，立刻看 isFault=\(rows.map { $0.isFault ? "T" : "F" }.joined())")
        let h = rows[0].hasFault(forRelationshipNamed: "author")
        let ids = rows[0].objectIDs(forRelationshipNamed: "author")
        let cv = rows[0].changedValues().keys.sorted()
        line("    还没读属性值时：hasFault(forRelationshipNamed:author)=\(h)、objectIDs(forRelationshipNamed:author) 给 \(ids.count) 个 ID、changedValues 键=\(cv)，问完再看 isFault=\(rows.map { $0.isFault ? "T" : "F" }.joined())（被问过的那条已经解开了）")
        _ = rows[0].value(forKey: "title")
        line("    只读 rows[0] 的 title 之后 isFault=\(rows.map { $0.isFault ? "T" : "F" }.joined())（只解开被读的那个）")
        let au = rows[0].value(forKey: "author") as? NSManagedObject
        let au2 = rows[0].value(forKey: "author") as? NSManagedObject
        line("    读了 author：另一端到手时 isFault=\(au?.isFault.description ?? "nil")，再读它的 name=\(au?.value(forKey: "name") as? String ?? "nil")；两次读 author 拿到同一个实例吗=\(au2 === au)")
        let again = (try? ctxB.fetch(r)) ?? []
        line("    同上下文再 fetch 一次：\(again.count) 条，第一条跟第一次是同一实例吗=\(again.first === rows.first)")
        let ctxO = c13f.newBackgroundContext()
        ctxO.performAndWait {
            let ro = NSFetchRequest<NSManagedObject>(entityName: "Note")
            let o = (try! ctxO.fetch(ro))
            line("    同一个容器再开一个**全新**上下文、默认设置 fetch：\(o.count) 条，isFault=\(o.map { $0.isFault ? "T" : "F" }.joined())")
            let rn = NSFetchRequest<NSManagedObject>(entityName: "Note")
            rn.returnsObjectsAsFaults = false
            let o2 = (try! ctxO.fetch(rn))
            line("    还是那个上下文，把 returnsObjectsAsFaults 设成 false 再 fetch：\(o2.count) 条，isFault=\(o2.map { $0.isFault ? "T" : "F" }.joined())（对象已被上下文记住，所以看到的是同一批实例）")
        }
    }
}
let coldContainer = NSPersistentContainer(name: "c26-cold", managedObjectModel: model)
coldContainer.persistentStoreDescriptions = [NSPersistentStoreDescription(url: u13f)]
coldContainer.loadPersistentStores { _, _ in }
let ctxCold = coldContainer.newBackgroundContext()
quiet {
    ctxCold.performAndWait {
        let rc = NSFetchRequest<NSManagedObject>(entityName: "Note")
        let rows = (try! ctxCold.fetch(rc))
        let rs = NSFetchRequest<NSManagedObject>(entityName: "Note")
        rs.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: true)]
        let rowsSorted = (try! ctxCold.fetch(rs))
        let rNo = NSFetchRequest<NSManagedObject>(entityName: "Note")
        rNo.returnsObjectsAsFaults = false
        let rowsNoFault = (try! ctxCold.fetch(rNo))
        line("    换一个**全新容器**读同一个文件：默认请求 fetch 到 \(rows.count) 条 isFault=\(rows.map { $0.isFault ? "T" : "F" }.joined())，带 sortDescriptors 的也=\(rowsSorted.map { $0.isFault ? "T" : "F" }.joined())")
        line("    这个新容器上把 returnsObjectsAsFaults 设成 false（默认值 \(NSFetchRequest<NSManagedObject>(entityName: "Note").returnsObjectsAsFaults)）：\(rowsNoFault.count) 条，isFault=\(rowsNoFault.map { $0.isFault ? "T" : "F" }.joined()) —— 跟上面看不出差别")
        let rCnt = NSFetchRequest<NSNumber>(entityName: "Note")
        rCnt.resultType = .countResultType
        let cntRows = (try? ctxCold.fetch(rCnt)) ?? []
        line("    resultType=.countResultType：fetch 给 \(cntRows.count) 个元素，元素=\(cntRows.map { $0.description }.joined(separator: ","))；count(for:) 给 \((try? ctxCold.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? -1)")
    }
}
line("")
line("  -- refresh / rollback / hasChanges --")
let ctxR = c13f.newBackgroundContext()
var refreshText = ""
quiet {
    ctxR.performAndWait {
        let rr = NSFetchRequest<NSManagedObject>(entityName: "Note")
        rr.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: true)]
        let o = (try! ctxR.fetch(rr))[0]
        o.setValue(999, forKey: "stars")
        let dirty = "改完没存：stars 读回=\(o.value(forKey: "stars") as? Int ?? -1) 上下文 hasChanges=\(ctxR.hasChanges) 对象 hasChanges=\(o.hasChanges) hasPersistentChangedValues=\(o.hasPersistentChangedValues)"
        ctxR.refresh(o, mergeChanges: true)
        let keep = "refresh(mergeChanges:true) 之后 stars=\(o.value(forKey: "stars") as? Int ?? -1)/上下文 hasChanges=\(ctxR.hasChanges)"
        o.setValue(888, forKey: "stars")
        ctxR.refresh(o, mergeChanges: false)
        let drop = "refresh(mergeChanges:false) 之后 stars=\(o.value(forKey: "stars") as? Int ?? -1)/上下文 hasChanges=\(ctxR.hasChanges)/对象 hasChanges=\(o.hasChanges)/updatedObjects=\(ctxR.updatedObjects.count)/changedValues 键=\(o.changedValues().keys.sorted())"
        ctxR.refreshAllObjects()
        ctxR.rollback()
        refreshText = "\(dirty) | \(keep) | \(drop) | refreshAllObjects + rollback 之后文件=\(fileNotes(u13f))"
    }
}
line("    \(refreshText)")
line("")
line("  -- 多上下文：谁看得见谁的改动 --")
let ctxP = c13f.newBackgroundContext()
let ctxQ = c13f.newBackgroundContext()
var pSees = -1
var pSeesSkip = -1
var qSees = -1
quiet {
    ctxP.performAndWait {
        let unsaved = NSManagedObject(entity: eNote, insertInto: ctxP)
        unsaved.setValue(50, forKey: "stars"); unsaved.setValue("p-unsaved", forKey: "title")
        let rq1 = NSFetchRequest<NSManagedObject>(entityName: "Note")
        pSees = (try? ctxP.count(for: rq1)) ?? -1
        rq1.includesPendingChanges = false
        pSeesSkip = (try? ctxP.count(for: rq1)) ?? -1
    }
    ctxQ.performAndWait {
        qSees = (try? ctxQ.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? -1
    }
    ctxP.performAndWait { ctxP.rollback() }
}
line("    store 里 3 条；ctxP 插 1 条没存 → ctxP count=\(pSees)，同一请求改成 includesPendingChanges=false 再数=\(pSeesSkip)，兄弟上下文 ctxQ count=\(qSees)（文件里 \(fileNotes(u13f))）")
let child13 = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
child13.parent = ctxP
var childText = ""
quiet {
    child13.performAndWait {
        let sees = (try? child13.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? -1
        let newOne = NSManagedObject(entity: eNote, insertInto: child13)
        newOne.setValue(60, forKey: "stars"); newOne.setValue("c-unsaved", forKey: "title")
        let saved = attemptVoid { try child13.save() }
        childText = "child(parent=ctxP) 起始 count=\(sees)；child 插 1 条后 \(saved)，此时文件里 \(fileNotes(u13f))"
    }
    ctxP.performAndWait {
        let parentSaw = (try? ctxP.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? -1
        let savedUp = attemptVoid { try ctxP.save() }
        childText += " | parent count=\(parentSaw)，parent \(savedUp) 之后文件里 \(fileNotes(u13f))"
        ctxP.rollback()
    }
}
line("    \(childText)")
line("")
line("  -- 同一行被两个上下文改：合并策略与 Z_OPT --")
let ctxU = c13f.newBackgroundContext()
let ctxV = c13f.newBackgroundContext()
var conflictText = ""
quiet {
    ctxU.performAndWait {
        let ru = NSFetchRequest<NSManagedObject>(entityName: "Note")
        ru.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: true)]
        let a = (try! ctxU.fetch(ru))[0]
        a.setValue(11, forKey: "stars")
        ctxV.performAndWait {
            let rv = NSFetchRequest<NSManagedObject>(entityName: "Note")
            rv.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: true)]
            let b = (try! ctxV.fetch(rv))[0]
            b.setValue(22, forKey: "stars")
            let sameObject = a === b
            let first = "ctxV 先存：" + attemptVoid { try ctxV.save() }
            let second = "ctxU 再存：" + attemptVoid { try ctxU.save() }
            ctxU.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
            let policyName = "mergeType=\((ctxU.mergePolicy as? NSMergePolicy).map { Int($0.mergeType.rawValue) } ?? -1)"
            let third = "ctxU 换成 storeTrump 再存：" + attemptVoid { try ctxU.save() }
            conflictText = "同一个对象实例吗=\(sameObject) | \(first) | \(second)（此时 \(policyName)）| \(third)"
        }
    }
}
line("    \(conflictText)")
let db13z = rawHandle(u13f)
let finalFile13 = dump(db13z, "SELECT ZTITLE || ':' || ZSTARS || ':Z_OPT=' || COALESCE(CAST(Z_OPT AS TEXT),'NULL') FROM ZNOTE ORDER BY ZTITLE")
sqlite3_close_v2(db13z)
expect(uriTmp.host == nil && uriSaved.host?.count == 36 && pSees == 4 && pSeesSkip == 3 && qSees == 3
       && finalFile13.contains("f1:22:Z_OPT=3") && conflictText.contains("133020") && conflictText.contains("同一个对象实例吗=false"),
       "这一节全在讲「一个对象到底是谁」，四件事各自有坑。",
       "**objectID 有三段身份**：刚 insert 的是临时 ID（isTemporaryID=true，uri 的 host 是 nil，末段以 t 开头）；",
       "`obtainPermanentIDs(for:)` 不存盘也能提前换成永久 ID（host 立刻变成长 36 的 store UUID，末段以 p 开头）；",
       "存盘之后再量，uri 的形状和 obtain 之后一样。",
       "两个坑在这儿：一是**没存盘也能 existingObject(with:) 拿到对象**（上面「拿到了」），别指望它帮你校验存没存；",
       "二是拿这个 ID 去**另一个容器**（另一个 store）反查会抛 NSCocoaErrorDomain code=133000，userInfo 只有 objectID 一个键 —— ",
       "ID 里的 host 就是 store 的 UUID，所以 objectID 只在**同一个 store** 内有意义，不能当跨环境的主键存起来。",
       "另外这条 URI 形状（x-coredata://<store-UUID>/Note/p<行号>）本身就不稳定：p 后面的数字是 Z_PK，而 §11 已经量到 CoreData 存盘时给谁分配几号不保证 —— 别拿它当稳定字符串存进设置或 URL。",
       "**KVO 听不到 objectID 变化**：上面用 KVO 盯 objectID 这个键全程触发 0 次，而头文件里能 grep 到的公开通知只有上下文那五个（WillSave/DidSave/ObjectsDidChange/DidSaveObjectIDs/DidMergeChangesObjectIDs），",
       "这一版 SDK 根本没有 objectID 变化的通知 —— 想在新建对象上拿到永久 ID，只能在 save 之后重新读 objectID。",
       "**fault 不是你能预测的开关**：默认 fetch 在「刚存过这批数据的容器」上给 TTT（三条都是没解开的占位），",
       "换成全新容器读同一个文件却直接给 FFF；带不带 sortDescriptors 也一样；把 returnsObjectsAsFaults 关掉当然是 FFF。",
       "能靠住的只有 isFault 这个**读出来的状态**，不是「设了某个开关就一定懒加载」。",
       "不过有两件事是明确的：读一个对象的一个属性只解开**那一个**对象（FTT，其余照旧）；",
       "而 `objectIDs(forRelationshipNamed:)` 虽然名义上是「不解开也能拿关系里的 ID」，实测它把被问过的那条**解开了**（FTT 那行），",
       "真正不触发读取的是 `hasFault(forRelationshipNamed:)` —— 问完仍然是 TTT 的那个（上面「还没读属性值时」那行是问完之后的形状，被问过的那条已经解开）。",
       "另外**同一个上下文里同一行永远是同一个实例**（两次 fetch 都相等），不同上下文则各一份实例（上面「同一个对象实例吗=false」）—— 这就是 CoreData 的身份保证只到上下文为止。",
       "**上下文之间只靠 save 和合并传消息**：ctxP 插一条没存，它自己数到 4（includesPendingChanges 默认 true），",
       "同一个请求把该开关关了就数到 3，而兄弟上下文 ctxQ 一直是 3、文件里也一直是 3 行；",
       "child context（parent=ctxP）save 成功但文件一行没多，得 parent 再存一次才落到 SQLite（Z_MAX 也从 3 变 4，§12 那本账）。",
       "**同一行被两个上下文各改一次**：默认 mergePolicy 的 mergeType 就是 0（ NSErrorMergePolicy 那一档），",
       "所以 ctxV 先存成功、ctxU 后存抛 133020（跟 §12 撞号同一个码，userInfo 也是 conflictList），",
       "换成 storeTrump（mergeType=1）再存就成功，最后文件里 f1 是 **22**、Z_OPT 已经涨到 **3** —— ",
       "冲突 CoreData 不替你决定，先把 133020 抛回来；「让谁的值赢」是你换 mergePolicy 定的，",
       "而它判断「你手里那份还是不是最新的」用的就是 §12 那本 Z_OPT 账：每次成功存盘给那行加一。")

// ============================================================
// §14 模型改了，旧库怎么办：两个迁移开关的四种组合
// ============================================================
/// §14 用一个只有 Note 的极简模型，方便看清列的变化
func noteModel(_ names: [String]) -> NSManagedObjectModel {
    let note = NSEntityDescription()
    note.name = "Note"
    note.properties = [attr("stars", .integer32AttributeType, false)]
        + names.map { attr($0, .stringAttributeType, true) }
    let m = NSManagedObjectModel()
    m.entities = [note]
    return m
}
func noteColumns(_ u: URL) -> String {
    let d = rawHandle(u)
    let s = dump(d, "SELECT name FROM PRAGMA_table_info('ZNOTE') ORDER BY cid")
    sqlite3_close_v2(d)
    return s
}
func storeVersion(_ u: URL) -> String {
    let d = rawHandle(u)
    let s = "Z_VERSION=\(scalar(d, "SELECT Z_VERSION FROM Z_METADATA")) 行数=\(scalar(d, "SELECT count(*) FROM ZNOTE")) 元数据带 plist=\(scalar(d, "SELECT count(*) FROM Z_METADATA WHERE Z_PLIST IS NOT NULL"))"
    sqlite3_close_v2(d)
    return s
}
func migURL(_ name: String) -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("c26-mig-\(name).sqlite")
}
func wipe(_ u: URL) {
    for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: u.path + suffix) }
}
line("== 14) 模型改了、旧库怎么办：两个迁移开关的四种组合 ==")
let m14v1 = noteModel(["title"])
let m14v2 = noteModel(["title", "tag"])
let m14v3 = noteModel(["title2"])
let seed14 = migURL("seed")
wipe(seed14)
let c14v1 = NSPersistentContainer(name: "c26-mig", managedObjectModel: m14v1)
c14v1.persistentStoreDescriptions = [NSPersistentStoreDescription(url: seed14)]
var load14v1 = "?"
quiet { c14v1.loadPersistentStores { _, err in load14v1 = errInfo(err) } }
let oldNote = NSManagedObject(entity: m14v1.entitiesByName["Note"]!, insertInto: c14v1.viewContext)
oldNote.setValue(3, forKey: "stars"); oldNote.setValue("旧数据", forKey: "title")
line("  母本（v1 模型，属性只有 title/stars）：建库 \(load14v1) 存一条 \(attemptVoid { try c14v1.viewContext.save() })")
let dbSeed = rawHandle(seed14)
line("    母本现状：列=\(noteColumns(seed14))  \(storeVersion(seed14))  wal_checkpoint(TRUNCATE) 的 busy 位=\(scalar(dbSeed, "PRAGMA wal_checkpoint(TRUNCATE)"))")
sqlite3_close_v2(dbSeed)
var migResults: [String] = []
/// 每个用例都从母本复制一份文件出来，免得前一个用例迁移过的库污染后一个
func reopen14(_ label: String, _ m: NSManagedObjectModel, migrate: Bool, infer: Bool, key: String, readKey: String, from: URL) -> String {
    let u = migURL(key)
    wipe(u)
    let fm = FileManager.default
    for suffix in ["", "-wal", "-shm"] {
        if fm.fileExists(atPath: from.path + suffix) { try? fm.copyItem(atPath: from.path + suffix, toPath: u.path + suffix) }
    }
    let c = NSPersistentContainer(name: "c26-mig2", managedObjectModel: m)
    let d = NSPersistentStoreDescription(url: u)
    d.shouldMigrateStoreAutomatically = migrate
    d.shouldInferMappingModelAutomatically = infer
    c.persistentStoreDescriptions = [d]
    var e = "?"
    quiet { c.loadPersistentStores { _, err in e = errInfo(err) } }
    var rows = "读不到"
    quiet {
        c.viewContext.performAndWait {
            let got = (try? c.viewContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? []
            rows = "fetch \(got.count) 条"
            if let g = got.first { rows += " \(readKey) 读回=\(String(describing: g.value(forKey: readKey)))" }
        }
    }
    let text = "  \(label)：\(e)  \(rows)  列=\(noteColumns(u))  \(storeVersion(u))"
    line(text)
    _ = c
    return text
}
migResults.append(reopen14("v2 多加一个可选列 tag，两开关都开（出厂默认）", m14v2, migrate: true, infer: true, key: "both-on", readKey: "title", from: seed14))
migResults.append(reopen14("v2 同上，migrate 开 / infer 关", m14v2, migrate: true, infer: false, key: "infer-off", readKey: "title", from: seed14))
migResults.append(reopen14("v2 同上，两开关都关", m14v2, migrate: false, infer: false, key: "both-off", readKey: "title", from: seed14))
migResults.append(reopen14("v3 把 title 改名成 title2，两开关都开", m14v3, migrate: true, infer: true, key: "rename", readKey: "title2", from: seed14))
let db14 = rawHandle(migURL("rename"))
line("  改名那次之后，文件里 ZNOTE 的列明细：\(dump(db14, "SELECT name || ':' || type FROM PRAGMA_table_info('ZNOTE') ORDER BY cid"))")
let oldGone14 = dump(db14, "SELECT ZTITLE FROM ZNOTE")
line("  老数据在 SQL 层还找得到吗（问 ZTITLE）：\(oldGone14)")
sqlite3_close_v2(db14)
let backV1 = reopen14("v1 旧模型开在「上面 v2 已经加过 ZTAG 的那个库」上，两开关都开", m14v1, migrate: true, infer: true, key: "back-v1", readKey: "title", from: migURL("both-on"))
let c14bad = NSPersistentContainer(name: "c26-prag", managedObjectModel: noteModel(["title"]))
let badURL = migURL("badpragma")
wipe(badURL)
let d14bad = NSPersistentStoreDescription(url: badURL)
d14bad.setValue("not-a-mode" as NSString, forPragmaNamed: "journal_mode")
c14bad.persistentStoreDescriptions = [d14bad]
var badErr = "?"
quiet { c14bad.loadPersistentStores { _, err in badErr = errInfo(err) } }
line("  给 setValue(_:forPragmaNamed:) 塞一个非法值（journal_mode=not-a-mode）：\(badErr) store 数=\(c14bad.persistentStoreCoordinator.persistentStores.count) 主文件建了吗=\(FileManager.default.fileExists(atPath: badURL.path))")
_ = c14bad

let bothOn14 = migResults[0]
let inferOff14 = migResults[1]
let bothOff14 = migResults[2]
let rename14 = migResults[3]
/// 每个用例那行文本的后半截才是列清单（标签里也写着 ZTAG，不能整行 contains）
func cols14(_ t: String) -> String { t.components(separatedBy: "  列=").last ?? "" }
expect(bothOn14.contains("domain=nil") && cols14(bothOn14).contains("ZTAG") && bothOn14.contains("旧数据")
       && inferOff14.contains("code=134140") && inferOff14.contains("destinationModel") && !cols14(inferOff14).contains("ZTAG")
       && bothOff14.contains("code=134100") && bothOff14.contains("metadata")
       && rename14.contains("domain=nil") && cols14(rename14).contains("ZTITLE2") && rename14.contains("读回=nil")
       && oldGone14.contains("no such column: ZTITLE")
       && backV1.contains("domain=nil") && !cols14(backV1).contains("ZTAG") && cols14(backV1).contains("ZTITLE")
       && badErr.contains("code=256") && badErr.contains("NSSQLiteErrorDomain"),
       "这一节只有两个开关，但四种组合的失败方式各不相同，而最贵的那种根本不算失败。",
       "**先把两个开关分工说清**：shouldMigrateStoreAutomatically 是「开库前先试迁移」，",
       "shouldInferMappingModelAutomatically 是「没有手工做的 mapping model 时，允许它自己推断」。两个都为 true，是出厂值。",
       "都开着时，「多加一个可选属性」这条路是真能用：both-on 那行文件里多出一个 ZTAG 列，老行还在，title 读回「旧数据」。",
       "**关掉的两种失败长得不一样，但结论都是 store 没挂上**：migrate 开 / infer 关 → code=134140，",
       "userInfo 给的是 sourceModel、destinationModel、reason（它在抱怨没有映射模型可加载）；两开关都关 → code=134100，",
       "userInfo 只有 metadata 和 reason（模型指纹和库里存的那份对不上）。",
       "两种情况下 fetch 都是 0 条而不是「读到旧数据」，别把「fetch 到空」误读成「库是空的」—— 上面那两行的列清单还是老五列，文件一动没动。",
       "**最贵的一课：改属性名不是迁移，是删一列再建一列**。v3 把 title 改名成 title2，两开关全开，",
       "loadPersistentStores 一句错都没报（domain=nil），fetch 照样 1 条 —— 可 title2 读回 nil，",
       "因为文件里那列已经叫 ZTITLE2，SQL 层再问 ZTITLE 就是 no such column。老数据不是读不到，是不存在了。",
       "推断只认「加/删可选属性」这种对得上号的差；改名要有语义映射（NSMappingModel 的 attribute renaming）才保得住数据。",
       "**Z_VERSION 帮不上忙**：这四种组合里 Z_VERSION 从头到尾是 1（本章从没给模型设版本标识），",
       "对得上对不上靠的是 Z_METADATA 里那份模型指纹（Z_PLIST 非空那 1 行）—— §11 提过的那本账在这里兑现。",
       "**迁移不是只朝前发生的**：把 v1 旧模型开在「刚才已经加过 ZTAG 的那个库」上，同样两开关全开、同样不报错、title 照旧读得到，",
       "但文件里的 ZTAG 这一列被删了 —— 旧模型开新库会按旧模型重建表结构，回滚版本时丢的是新属性那部分数据。",
       "**最后一个 store 描述的坑**：给 setValue(_:forPragmaNamed:) 塞一个非法值（journal_mode=not-a-mode），",
       "拿到的错误码只有 256（一个笼统的写失败），userInfo 里连 SQLite 的返回码都没有，只有 NSFilePath 和 NSSQLiteErrorDomain；",
       "而 coordinator 的 persistentStores 是空数组、磁盘上的主文件却已经建好了 —— 失败不会替你清理半成品，重开前记得自己删干净。")


// ============================================================
// §15 一次问出统计值：聚合表达式、分组、去重
// ============================================================
func agg15(_ name: String, _ fn: String, _ key: String, _ t: NSAttributeType) -> NSExpressionDescription {
    let x = NSExpressionDescription()
    x.name = name
    x.expression = NSExpression(forFunction: fn, arguments: [NSExpression(forKeyPath: key)])
    x.expressionResultType = t
    return x
}
/// 跑一个字典结果的请求，把每行的键值按键名排序拼出来（键不存在和值是 nil 分开写）；顺手把整行文本回给调用方做断言
@discardableResult func runDict15(_ label: String, _ r: NSFetchRequest<NSDictionary>, _ ctx: NSManagedObjectContext) -> String {
    var out = ""
    quiet {
        do {
            let rs = try ctx.fetch(r)
            out = "行数=\(rs.count) "
            out += rs.map { dd in
                dd.allKeys.compactMap { $0 as? String }.sorted().map { k in
                    "\(k)=\(dd[k].map { String(describing: $0) } ?? "nil值")"
                }.joined(separator: " ")
            }.joined(separator: " | ")
        } catch { out = "抛出 \(errInfo(error))" }
    }
    line("  \(label)：\(out)")
    return out
}
line("== 15) 一次问出统计值：聚合表达式、分组与去重 ==")
let (c15, _) = makeContainer(model, tag: "agg")
let ctx15 = c15.viewContext
// 六条：stars = 1,2,3,1,2,4（总和 13、平均不是整数）；第 6 条的 title 故意不给
ctx15.performAndWait {
    let stars15 = [1, 2, 3, 1, 2, 4]
    for (i, v) in stars15.enumerated() {
        let o = NSManagedObject(entity: eNote, insertInto: ctx15)
        o.setValue(v, forKey: "stars")
        if i < 5 { o.setValue("第\(i + 1)条", forKey: "title") }
    }
    quiet { try? ctx15.save() }
}
// A 别名只用中文，且只有一个聚合
let rA = NSFetchRequest<NSDictionary>(entityName: "Note")
rA.resultType = .dictionaryResultType
rA.propertiesToFetch = [agg15("个数", "count:", "stars", .integer64AttributeType)]
let tA = runDict15("A 单个聚合、别名「个数」", rA, ctx15)
// B 两个中文别名的聚合放同一个请求
let rB = NSFetchRequest<NSDictionary>(entityName: "Note")
rB.resultType = .dictionaryResultType
rB.propertiesToFetch = [agg15("个数", "count:", "stars", .integer64AttributeType),
                       agg15("总和", "sum:", "stars", .integer64AttributeType)]
let tB = runDict15("B 两个中文别名：个数 + 总和", rB, ctx15)
// C 中文别名 + ASCII 别名混装
let rC = NSFetchRequest<NSDictionary>(entityName: "Note")
rC.resultType = .dictionaryResultType
rC.propertiesToFetch = [agg15("cnt", "count:", "stars", .integer64AttributeType),
                       agg15("个数", "count:", "stars", .integer64AttributeType)]
let tC = runDict15("C 同一个 count: 起两个名字：cnt 与 个数", rC, ctx15)
// D 四个 ASCII 别名的聚合一次取完
let rD = NSFetchRequest<NSDictionary>(entityName: "Note")
rD.resultType = .dictionaryResultType
rD.propertiesToFetch = [agg15("cnt", "count:", "stars", .integer64AttributeType),
                       agg15("sum", "sum:", "stars", .integer64AttributeType),
                       agg15("min", "min:", "stars", .integer64AttributeType),
                       agg15("max", "max:", "stars", .integer64AttributeType)]
let tD = runDict15("D 四个 ASCII 别名一次取（cnt/sum/min/max）", rD, ctx15)
// E expressionResultType 只是「你怎么读」，不参与计算
let rE1 = NSFetchRequest<NSDictionary>(entityName: "Note")
rE1.resultType = .dictionaryResultType
rE1.propertiesToFetch = [agg15("avg64", "average:", "stars", .integer64AttributeType)]
let tE1 = runDict15("E1 average 声明 integer64（真实值 13/6）", rE1, ctx15)
let rE2 = NSFetchRequest<NSDictionary>(entityName: "Note")
rE2.resultType = .dictionaryResultType
rE2.propertiesToFetch = [agg15("avg64", "average:", "stars", .doubleAttributeType)]
let tE2 = runDict15("E2 同一个 average 声明 double", rE2, ctx15)
let rE3 = NSFetchRequest<NSDictionary>(entityName: "Note")
rE3.resultType = .dictionaryResultType
rE3.propertiesToFetch = [agg15("sum", "sum:", "stars", .stringAttributeType)]
let tE3 = runDict15("E3 sum 声明 string", rE3, ctx15)
quiet {
    let v3 = (try? ctx15.fetch(rE3))?.first?["sum"]
    line("     E3 那个值拿到的真实类型=\(v3.map { String(describing: type(of: $0)) } ?? "无") 值=\(String(describing: v3))（声明成 string 并不会给你一个字符串）")
}
// F 普通列 + 聚合，不设 groupBy
let rF = NSFetchRequest<NSDictionary>(entityName: "Note")
rF.resultType = .dictionaryResultType
rF.propertiesToFetch = ["title", agg15("sum", "sum:", "stars", .integer64AttributeType)]
rF.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
let tF = runDict15("F 普通列 title + 聚合 sum，没有 groupBy", rF, ctx15)
// G 补上 groupBy 才有分组
let rG = NSFetchRequest<NSDictionary>(entityName: "Note")
rG.resultType = .dictionaryResultType
rG.propertiesToFetch = ["stars", agg15("cnt", "count:", "stars", .integer64AttributeType)]
rG.propertiesToGroupBy = ["stars"]
rG.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: true)]
let tG = runDict15("G 按 stars 分组 + count", rG, ctx15)
// H 去重
let rH = NSFetchRequest<NSDictionary>(entityName: "Note")
rH.resultType = .dictionaryResultType
rH.propertiesToFetch = ["stars"]
rH.returnsDistinctResults = true
rH.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: true)]
let tH = runDict15("H 只取 stars + distinct=true", rH, ctx15)
let rH2 = NSFetchRequest<NSDictionary>(entityName: "Note")
rH2.resultType = .dictionaryResultType
rH2.propertiesToFetch = ["stars"]
rH2.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: true)]
let tH2 = runDict15("H2 同样的请求，distinct 保持出厂值 false", rH2, ctx15)
// I count 对 NULL 的脾气：title 有第六条没给值，stars 是非可选列
let rI = NSFetchRequest<NSDictionary>(entityName: "Note")
rI.resultType = .dictionaryResultType
rI.propertiesToFetch = [agg15("cntTitle", "count:", "title", .integer64AttributeType),
                       agg15("cntStars", "count:", "stars", .integer64AttributeType)]
let tI = runDict15("I count: 分别是 title(有一条没值) 和 stars", rI, ctx15)
// J 空表
let (c15e, _) = makeContainer(model, tag: "agg-empty")
let rJ = NSFetchRequest<NSDictionary>(entityName: "Note")
rJ.resultType = .dictionaryResultType
rJ.propertiesToFetch = [agg15("cnt", "count:", "stars", .integer64AttributeType),
                       agg15("sum", "sum:", "stars", .integer64AttributeType),
                       agg15("avg", "average:", "stars", .doubleAttributeType),
                       agg15("mx", "max:", "stars", .integer64AttributeType)]
var tJ = ""
var tJkeys = ""

c15e.viewContext.performAndWait { tJ = runDict15("J 空表上四个聚合", rJ, c15e.viewContext) }
let rJ2 = NSFetchRequest<NSDictionary>(entityName: "Note")
rJ2.resultType = .dictionaryResultType
rJ2.propertiesToFetch = ["stars"]
c15e.viewContext.performAndWait {
    _ = runDict15("J2 空表上只取普通列", rJ2, c15e.viewContext)
    quiet {
        if let dd = (try? c15e.viewContext.fetch(rJ))?.first {
            tJkeys = "     J 的字典里按键名排序只有 \(dd.allKeys.compactMap { $0 as? String }.sorted())；问它有没有 avg 这个键=\(dd.allKeys.contains { $0 as? String == "avg" })，而 cnt/sum 是有的=\(dd.allKeys.contains { $0 as? String == "cnt" } && dd.allKeys.contains { $0 as? String == "sum" })"
            line(tJkeys)
        }
    }
}
// K 默认 resultType：不显式设成 dictionary 时，fetch 回来的到底是什么
let rK = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
rK.propertiesToFetch = ["stars"]
rK.returnsDistinctResults = true
line("  K 不设 resultType：request.resultType=\(rK.resultType.rawValue)（0=managedObject 1=dictionary 2=objectID 3=section 4=count）distinct=true")
quiet {
    let rs = (try? ctx15.fetch(rK)) ?? []
    line("     fetch 回来 \(rs.count) 个元素，第一个的真实类型=\(rs.isEmpty ? "无" : String(describing: type(of: rs[0]))) —— 同一个请求写成 NSFetchRequest<NSDictionary> 再取元素就是本节讲的崩溃点")
}
// L 聚合能不能作用于 to-many 关系
let rL = NSFetchRequest<NSDictionary>(entityName: "Author")
rL.resultType = .dictionaryResultType
rL.propertiesToFetch = ["name", agg15("cnt", "count:", "notes", .integer64AttributeType)]
let (c15b, _) = makeContainer(model, tag: "agg-rel")
c15b.viewContext.performAndWait {
    let a = NSManagedObject(entity: eAuthor, insertInto: c15b.viewContext)
    a.setValue("作者甲", forKey: "name")
    for v in [1, 2, 3] {
        let o = NSManagedObject(entity: eNote, insertInto: c15b.viewContext)
        o.setValue(v, forKey: "stars")
        o.setValue("r\(v)", forKey: "title")
        o.setValue(a, forKey: "author")
    }
    for v in [7] {
        let o = NSManagedObject(entity: eNote, insertInto: c15b.viewContext)
        o.setValue(v, forKey: "stars")
        o.setValue("noAuthor", forKey: "title")
    }
    quiet { try? c15b.viewContext.save() }
    runDict15("L 实体 Author 上 count: notes（to-many 关系）", rL, c15b.viewContext)
}
let rM = NSFetchRequest<NSDictionary>(entityName: "Note")
rM.resultType = .dictionaryResultType
rM.propertiesToFetch = [agg15("cntAuthor", "count:", "author", .integer64AttributeType),
                       agg15("sumStars", "sum:", "stars", .integer64AttributeType)]
c15b.viewContext.performAndWait { _ = runDict15("M 实体 Note 上 count: author（to-one）+ sum: stars", rM, c15b.viewContext) }
expect(tA.contains("个数=6") && tB.contains("个数=nil值") && tB.contains("总和=13")
       && tC.contains("cnt=6") && tC.contains("个数=nil值")
       && tD.contains("cnt=6") && tD.contains("max=4") && tD.contains("sum=13")
       && tE1.contains("avg64=2") && tE2.contains("avg64=2.166666666666667") && tE3.contains("sum=13.0")
       && tF.contains("行数=6") && tF.contains("sum=13") && tG.contains("行数=4")
       && tH.contains("行数=4") && tH2.contains("行数=6")
       && tI.contains("cntStars=6") && tI.contains("cntTitle=5")
       && tJ.contains("cnt=0") && tJ.contains("sum=0") && !tJ.contains("avg")
       && tJkeys.contains("avg 这个键=false"),
       "统计值这条路 CoreData 不给 SQL，给的是 NSExpressionDescription，而它有五个各自会咬人的地方。",
       "**先说形状**：聚合表达式只有塞进 `propertiesToFetch`、并且把 `resultType` 设成 `.dictionaryResultType` 才生效，",
       "回来的每一行是一个「别名 → 值」的字典（D 一次取 cnt/sum/min/max 就是 1 行 4 个键）。",
       "**第一个坑：别名的字符集**。只放一个聚合时中文别名完全正常（A 的「个数」给 6），",
       "可只要同一个请求里有**两个以上**聚合表达式，非 ASCII 的别名那一格就开始静默变 nil：",
       "B 里「个数」nil 而「总和」有值、C 里同一个 count: 起两个名字则 ASCII 的 cnt 有值、中文的个数 nil，",
       "全部用 ASCII（D 的四个）就一个都没丢。它不报错也不抛异常，读到 nil 是唯一线索 —— 聚合列的 name 请一律用 ASCII。",
       "**第二个坑：expressionResultType 是「你要什么形状」，不是「它算什么」**。",
       "同一列的 average（真实值 13/6）声明 integer64 拿到 2（截断，不是四舍五入）、声明 double 拿到 2.166666666666667；",
       "sum 声明 string 会真的给你一个字符串「13.0」（E3 那行量的类型就是 NSTaggedPointerString）。",
       "所以声明错了不会崩，只会给你一个形状不对的值 —— 编译器帮不上忙。",
       "**第三个坑：普通列和聚合混在一起时，不设 propertiesToGroupBy 也照样出结果，但是逐行的**。",
       "F 只多写了一个 title，就拿到 6 行、每行的 sum 都是整表的 13（它没有分组，等于把聚合当常量贴在每行上）；",
       "这类请求的行序不保证（不加 sortDescriptors 时同一份代码 debug/release 打出来的先后就不一样），",
       "所以下面 F 那行是加了按 title 排序才打得出来的，排序和「逐行给常量」这件事无关。",
       "想要「每组多少」必须显式 groupBy（G 按 stars 分组才给 4 行：2/2/1/1）。",
       "**第四个坑：distinct 的出厂值是 false，而且只对 dictionary 结果起作用**。",
       "H 开了给 4 个不同值，H2 保持默认给 6 行；而 K 那种「设了 distinct 却没设 resultType」的请求，",
       "`request.resultType` 仍是 0（managedObject），fetch 回来的还是 NSManagedObject —— distinct 直接被忽略。",
       "这里顺手把 §15 唯一的崩法说明白：同样这个请求，只要写成 `NSFetchRequest<NSDictionary>` 去取元素，",
       "Swift 侧就当场挂掉，探针进程原文是 ",
       "`Fatal error: NSArray element failed to match the Swift Array Element type / Expected NSDictionary but found NSManagedObject`（信号 4）—— ",
       "泛型参数只是个断言，运行时不会替你校验，示例正文一行都没执行它，K 那两行用 NSFetchRequestResult 收才是安全写法。",
       "**第五个坑：空表和 NULL**。空表上聚合不报错，给 1 行，COUNT/SUM 是 0（J），",
       "但 AVG/MAX 那一格**连键都不在字典里**（J 那行量的 allKeys 只有 cnt 和 sum）—— ",
       "Swift 侧按键取「avg」和「有键但值是 nil」的 B 一样都读成 nil，只有 allKeys 能区分这两种。",
       "另外 count: 走的是 SQL `COUNT(列)` 的语义、NULL 不计：I 里 title 有第六条没给值 → cntTitle=5，",
       "非可选的 stars 仍是 6；关系也算 count（L 在 Author 上 count: notes 给 3，M 在 Note 上 count: author 只数有 author 的那 3 条）。")

// ============================================================
// §16 批量请求：走 store 那条通道，不经过你的上下文
// ============================================================
func attempt16(_ body: () throws -> Void) -> String {
    do { try body(); return "成功" } catch { return "抛出 \(nsErr16(error))" }
}
/// 只打 domain/code，外加「消息里不含路径」时把消息带上（批量请求的错误信息常常就一句话）
func nsErr16(_ e: Error) -> String {
    let n = e as NSError
    let msg = n.localizedDescription
    return "domain=\(n.domain) code=\(n.code) userInfo键=\(n.userInfo.keys.sorted()) 消息=\(msg.contains("/") ? "<带路径，略>" : msg)"
}
line("== 16) 批量请求：insert / update / delete 走 store，不经过上下文 ==")
let (c16, u16) = makeContainer(model, tag: "batch")
let ctx16 = c16.viewContext
let db16 = rawHandle(u16)
func notes16() -> String { dump(db16!, "SELECT ZTITLE || ':' || ZSTARS FROM ZNOTE ORDER BY ZTITLE") }
func pk16() -> String { dump(db16!, "SELECT Z_NAME || '=Z_MAX:' || Z_MAX FROM Z_PRIMARYKEY ORDER BY Z_ENT") }
func cnt16(_ ctx: NSManagedObjectContext) -> String {
    var v = -1
    ctx.performAndWait { v = (try? ctx.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? -1 }
    return "\(v)"
}
// A 出厂值：resultType 与 handler/objects 两个入口
let bir0 = NSBatchInsertRequest(entity: eNote, objects: [["stars": 1, "title": "a1"]])
line("  A 新建 NSBatchInsertRequest：resultType 出厂=\(bir0.resultType.rawValue)（0=statusOnly 1=objectIDs 2=count）entityName=\(bir0.entityName) objectsToInsert 回数=\(bir0.objectsToInsert?.count ?? -1) dictionaryHandler 是否已设=\(bir0.dictionaryHandler != nil)")
var insCount = ""
quiet {
    ctx16.performAndWait {
        bir0.resultType = .count
        do {
            let r = try ctx16.execute(bir0) as? NSBatchInsertResult
            insCount = "result=\(String(describing: r?.result)) 类型=\(r.map { String(describing: type(of: $0)) } ?? "nil")"
        } catch { insCount = "抛出 \(nsErr16(error))" }
    }
}
line("  B objects: 版插一条（resultType=.count）：\(insCount) 上下文 count=\(cnt16(ctx16)) 文件里=\(notes16()) 主键账=\(pk16())")
// C 漏掉非可选属性
let bir1 = NSBatchInsertRequest(entity: eNote, objects: [["title": "noStars"]])
bir1.resultType = .count
var missErr = ""
quiet {
    ctx16.performAndWait {
        do { _ = try ctx16.execute(bir1) } catch { missErr = "抛出 \(nsErr16(error))" }
    }
}
line("  C objects: 里漏掉非可选的 stars：\(missErr) 之后文件里=\(notes16())")
// D dictionaryHandler：return true 表示「够了」，第 3 次给 true
var dh16 = 0
var dhFirstDict = ""
let bir2 = NSBatchInsertRequest(entity: eNote, dictionaryHandler: { (d: NSMutableDictionary) -> Bool in
    dh16 += 1
    if dh16 == 1 {
        dhFirstDict = d.allKeys.compactMap { $0 as? String }.sorted().map { "\($0)=\(d[$0] ?? "nil")" }.joined(separator: " ")
    }
    d["stars"] = 100 + dh16
    d["title"] = "h\(dh16)"
    return dh16 >= 3
})
bir2.resultType = .count
var dhResult = ""
quiet {
    ctx16.performAndWait {
        do {
            let r = try ctx16.execute(bir2) as? NSBatchInsertResult
            dhResult = "result=\(String(describing: r?.result)) handler 调了 \(dh16) 次"
        } catch { dhResult = "抛出 \(nsErr16(error)) 调了 \(dh16) 次" }
    }
}
line("  D dictionaryHandler 第三次 return true：\(dhResult)（第一次进来时那个字典里是\(dhFirstDict.isEmpty ? "空的" : dhFirstDict)）之后文件里=\(notes16())")
// F resultType=.objectIDs 拿到的是什么
let bir4 = NSBatchInsertRequest(entity: eNote, objects: [["stars": 5, "title": "oid1"], ["stars": 6, "title": "oid2"]])
bir4.resultType = .objectIDs
var oidOut = ""
func runInsert16(_ req: NSBatchInsertRequest) -> [NSManagedObjectID] {
    var ids: [NSManagedObjectID] = []
    ctx16.performAndWait {
        do {
            let res = try ctx16.execute(req) as? NSBatchInsertResult
            ids = (res?.result as? [NSManagedObjectID]) ?? []
        } catch { oidOut = "抛出 \(nsErr16(error))" }
    }
    return ids
}
quiet {
    let ids = runInsert16(bir4)
    if oidOut.isEmpty {
        let firstTail = ids.first.map { $0.uriRepresentation().absoluteString.split(separator: "/").last.map(String.init) ?? "?" } ?? "无"
        oidOut = "拿到 \(ids.count) 个 objectID，URI 末段形状=\(firstTail) 是否全是永久 ID=\(ids.allSatisfy { !$0.isTemporaryID })"
    }
}
line("  F objects: 版两条 + resultType=.objectIDs：\(oidOut)")
line("  F2 这批新行在 viewContext 里的可见性：count(for:)=\(cnt16(ctx16))（每次都跑 SQL，所以看得见）")
// G 批量更新：不设 predicate 就是全表
let bur = NSBatchUpdateRequest(entity: eNote)
bur.propertiesToUpdate = ["stars": 77]
line("  G NSBatchUpdateRequest 出厂：resultType=\(bur.resultType.rawValue)（0=statusOnly 1=updatedObjectIDs 2=count）includesSubentities=\(bur.includesSubentities) predicate=\(String(describing: bur.predicate))")
var upOut = ""
quiet {
    ctx16.performAndWait {
        let before = (try? ctx16.fetch(NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? []
        let first = before.first
        let oldVal = first?.value(forKey: "stars")
        bur.resultType = .updatedObjectsCountResultType
        do {
            let r = try ctx16.execute(bur) as? NSBatchUpdateResult
            upOut = "result=\(String(describing: r?.result))"
            let afterVal = first?.value(forKey: "stars")
            upOut += " 更新前手里那条=\(String(describing: oldVal)) 更新后同一个对象再读=\(String(describing: afterVal)) 上下文 hasChanges=\(ctx16.hasChanges)"
        } catch { upOut = "抛出 \(nsErr16(error))" }
    }
}
line("  G2 batch update 把 stars 全表改成 77：\(upOut)")
line("  G3 文件里实际是什么：\(dump(db16!, "SELECT ZTITLE || ':' || ZSTARS || ':typeof=' || typeof(ZSTARS) FROM ZNOTE ORDER BY ZTITLE"))")
// H 更新时给错类型
let bur2 = NSBatchUpdateRequest(entity: eNote)
bur2.propertiesToUpdate = ["stars": "文字"]
bur2.predicate = NSPredicate(format: "title == %@", "a1")
bur2.resultType = .updatedObjectsCountResultType
var up2 = ""
quiet {
    ctx16.performAndWait {
        do {
            let res = try ctx16.execute(bur2) as? NSBatchUpdateResult
            up2 = "result=\(String(describing: res?.result)) 文件里那行现在="
                + dump(db16!, "SELECT ZTITLE || ':' || ZSTARS || ':typeof=' || typeof(ZSTARS) FROM ZNOTE WHERE ZTITLE='a1'")
        } catch { up2 = "抛出 \(nsErr16(error))" }
    }
}
line("  H propertiesToUpdate 给 integer 属性塞字符串（只改 title==a1 那行）：\(up2)")
// I 批量删除：先拿 objectIDs，再看上下文里那个对象的反应
let bdel = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "Note"))
line("  I NSBatchDeleteRequest(fetchRequest:) 出厂 resultType=\(bdel.resultType.rawValue)（0=statusOnly 1=objectIDs 2=count）带的 fetch request resultType=\(bdel.fetchRequest.resultType.rawValue)")
var delOut = ""
quiet {
    ctx16.performAndWait {
        let some = (try? ctx16.fetch(NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? []
        let doomed = some.last
        let doomedTitle = doomed?.value(forKey: "title") as? String
        let ok = NSBatchDeleteRequest(objectIDs: [doomed!.objectID])
        ok.resultType = .resultTypeObjectIDs
        do {
            let r = try ctx16.execute(ok) as? NSBatchDeleteResult
            let ids = r?.result as? [NSManagedObjectID] ?? []
            delOut = "删 1 条（title=\(String(describing: doomedTitle))）result 回数=\(ids.count) 之后同一个对象读 title=\(String(describing: doomed?.value(forKey: "title")))"
            doomed?.setValue(999, forKey: "stars")
            delOut += " 给它改个值再 save：" + attempt16 { try ctx16.save() }
            delOut += " 文件里还剩 \(dump(db16!, "SELECT count(*) FROM ZNOTE")) 行，主键账=\(pk16())"
        } catch { delOut = "抛出 \(nsErr16(error))" }
    }
}
line("  I2 用 objectIDs: 版删掉上下文里已经拿着的那条：\(delOut)")
// J 删除走不走删除规则：对 Author 发批量删除
let (c16r, u16r) = makeContainer(model, tag: "batch-rel")
let cntSql16 = "SELECT '作者=' || (SELECT count(*) FROM ZAUTHOR) || ' 笔记=' || (SELECT count(*) FROM ZNOTE)"
    + " || ' 挂了author=' || (SELECT count(*) FROM ZNOTE WHERE ZAUTHOR IS NOT NULL)"
    + " || ' 悬空=' || (SELECT count(*) FROM ZNOTE WHERE ZAUTHOR IS NOT NULL AND ZAUTHOR NOT IN (SELECT Z_PK FROM ZAUTHOR))"
let db16r = rawHandle(u16r)
quiet {
    c16r.viewContext.performAndWait {
        let a = NSManagedObject(entity: eAuthor, insertInto: c16r.viewContext)
        a.setValue("作者甲", forKey: "name")
        for v in 1...3 {
            let o = NSManagedObject(entity: eNote, insertInto: c16r.viewContext)
            o.setValue(v, forKey: "stars"); o.setValue("k\(v)", forKey: "title")
            o.setValue(a, forKey: "author")
        }
        try? c16r.viewContext.save()
    }
}
line("  J 删之前：\(dump(db16r!, cntSql16)) 主键账=\(dump(db16r!, "SELECT Z_NAME || '=Z_MAX:' || Z_MAX FROM Z_PRIMARYKEY ORDER BY Z_ENT"))")
let bdelAuthor = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "Author"))
bdelAuthor.resultType = .resultTypeCount
var delRule = ""
quiet {
    c16r.viewContext.performAndWait {
        do {
            let res = try c16r.viewContext.execute(bdelAuthor) as? NSBatchDeleteResult
            delRule = "批量删 Author result=\(String(describing: res?.result))"
        } catch { delRule = "抛出 \(nsErr16(error))" }
    }
}
let afterJ16 = dump(db16r!, cntSql16)
line("  J2 批量删完 Author：\(delRule) 删之后文件里=\(afterJ16)")
line("  J3 上下文里再 fetch 一次 Note：\(cnt16(c16r.viewContext)) 条，而 SQL 层是 \(scalar(db16r!, "SELECT count(*) FROM ZNOTE")) 行")
let pkEnd16 = pk16()
let notesEnd16 = notes16()
sqlite3_close_v2(db16r)
sqlite3_close_v2(db16)
expect(insCount.contains("result=Optional(1)") && notesEnd16.components(separatedBy: " | ").count == 4
       && pkEnd16.contains("Note=Z_MAX:5") && pkEnd16.contains("Author=Z_MAX:0")
       && missErr.contains("code=1570") && missErr.contains("%{PROPERTY}@ is a required value.")
       && dhResult.contains("result=Optional(2)") && dhResult.contains("调了 3 次") && dhFirstDict.isEmpty
       && oidOut.contains("拿到 2 个 objectID") && oidOut.contains("永久 ID=true")
       && upOut.contains("result=Optional(5)") && upOut.contains("更新后同一个对象再读=Optional(1)") && upOut.contains("hasChanges=false")
       && up2.contains("result=Optional(1)") && up2.contains("a1:0:typeof=integer")
       && bdel.resultType.rawValue == 0 && bdel.fetchRequest.resultType.rawValue == 1
       && delOut.contains("code=133020") && delOut.contains("conflictList") && delOut.contains("title=Optional(oid2)")
       && afterJ16 == "作者=0 笔记=0 挂了author=0 悬空=0",
       "批量请求这一节的核心只有一句话：它走 store 那条通道，所以它**既不受你的上下文管，也不给你上下文的待遇**。",
       "**先说三个请求的出厂值**：NSBatchInsertRequest 的 resultType 出厂是 0（statusOnly，什么都不回），",
       "NSBatchUpdateRequest 也是 statusOnly 且 includesSubentities=true、predicate=nil（不设条件就是全表），",
       "NSBatchDeleteRequest 更值得注意：它把传给它的 fetchRequest 的 resultType **改写成 objectID（1）**，",
       "因为它内部就是靠那批 ID 去删的 —— 上面 I 那行量到的 0 和 1 就是这个改写。",
       "**insert 的两条入口脾气不同**。objects: 版是「你给我字典数组」，漏掉非可选属性就直接抛 NSCocoaErrorDomain code=1570，",
       "而且它的错误文本里那个占位符根本没替换：消息原文是 `%{PROPERTY}@ is a required value.`（C 那行），",
       "userInfo 里倒是给了 NSValidationErrorKey/Object/Value 三个真信息，要用人家得自己拼。",
       "dictionaryHandler 版是「CoreData 反过来问你」：它每次给你一个**空的** NSMutableDictionary，你填进去的键值就是一行，",
       "**返回值是「够了吗」而不是「成功吗」** —— D 那行第三次 return true，result 就只数到 2（第三个字典还没写就被丢了）。",
       "反过来，一次都不 return true 就是**没有终点的循环**：探针里 handler 被连调 826 万次、100 秒都没返回，",
       "只在磁盘上留下 187 MB 的 WAL（另一支每调一次打一行日志的探针被杀掉前已经打了 299488 行）；",
       "示例正文一行都不执行它，写的时候请在 handler 里放一个计数器兜底。",
       "**取号还是走 CoreData 自己的账**：批量插一条之后 Z_PRIMARYKEY 里 Note 的 Z_MAX 从 0 变 1（B 那行），",
       "这就是 §12 说的那条路 —— 绕开 CoreData 手工 INSERT 要自己维护那本账，走批量请求就不用。",
       "resultType=.objectIDs 也确实拿回 2 个**永久** ID（F 那行：URI 末段是 p4，isTemporaryID 全 false），",
       "所以批量插入之后想用这些对象，直接 existingObject(with:) 接上就行。",
       "**update 完全不通知你，也不回头改你手里已经拿着的对象**：G 那行先把全表 stars 改成 77，",
       "result 数到 5 行，SQL 层也确实全是 77（G3），可上下文里那个之前就 fetch 到的对象再读还是 1，",
       "而且 `ctx.hasChanges` 是 false —— 它没在自己的登记簿上记这笔，所以 save 也不会帮你带出去。",
       "要让它可见得自己 `mergeChanges(fromContextDidSave:)`（用 result 里的 objectIDs）或者 refresh；",
       "count(for:) 那种「每次都重新跑 SQL」的读法则立刻看得到（F2 从 1 变 5）。",
       "**propertiesToUpdate 给错类型也不报错，交给 SQLite 的类型亲和去办**：H 把 integer 属性 stars 设成字符串「文字」，",
       "result=1 表示改成功了，文件里那一行的值是 **0**（typeof 仍是 integer）—— 和 §5 那条「列亲和什么，值就被拧成什么」是同一件事，",
       "只是这里拧的人换成了 CoreData 发出去的那条 UPDATE。",
       "**delete 这一半有两笔账**。一是它删得掉 store，删不掉你手里的对象：I2 用 objectIDs: 版删掉上下文正拿着的那条，",
       "上下文里那个对象照样读得到 title（它不知道），等给它改了值再 save 才炸出来 —— NSCocoaErrorDomain code=133020、",
       "userInfo 带 conflictList，和 §12 撞号、§13 双写同一个码，那句 localizedDescription 是「Could not merge changes.」。",
       "二是 Z_MAX 不回收：删完文件里剩 4 行，而 Z_PRIMARYKEY 的 Z_MAX 还是 5（上面最后那行的主键账）。",
       "**但它仍然走模型里的删除规则**：J 那对容器里 1 个作者挂着 3 条笔记（Note.author=nullify、Author.notes=cascade，§12 定的），",
       "对 Author 发批量删除之后，文件里笔记也一起没了、悬空行 0（J2）—— 批量请求绕的是上下文，不是模型的约束。",
       "这一点和 §12 的手工 SQL 正好对照：手工 DELETE 才是真的没人管你，删完留下悬空的 ZAUTHOR。")
line("")
line("== 本章的诚实边界 ==")
line("  1) 模型全是代码构造的：本章每一节都用 NSManagedObjectModel + NSEntityDescription 手搓模型、用 KVC 读写值，")
line("     所以 .xcdatamodeld 文件、codegen 出来的 NSManagedObject 子类、@objc dynamic、representedClass 这些")
line("     只在 Xcode 模型编辑器里才有的东西一条都没验；SwiftData/@Model 更不在范围内。")
line("  2) 迁移只量了「两个开关 + 轻量级推断」：真正的 mapping model、自定义 NSEntityMigrationPolicy、")
line("     多版本模型与 versionIdentifiers（§14 里 Z_VERSION 全程是 1，正是因为本章从没给模型设过版本）、")
line("     NSMigrationManager、以及上线前先备份 store 这套工程做法都没跑。")
line("     §14 只证明了「改名会静默丢数据」，没给出保数据的完整通路。")
line("  3) 数量级与性能一条都没量：批量插入的正常路径只有几条记录，正常 handler 分支也没超过三次；")
line("     一万/十万条的耗时、内存峰值、WAL 膨胀、fetchBatchSize 的效果、调 PRAGMA 能省多少，都不在本章证据里。")
line("  4) 并发只量到形状：多上下文可见性、child context、mergePolicy、批量请求绕过上下文都测了，")
line("     但 perform/performAndWait 的队列归属、嵌套 performAndWait 的死锁、跨进程共享同一个 store")
line("     （NSPersistentHistory 那条同步链路）都没做。§16 那个 NSSQLiteErrorDomain 6922 是把磁盘写爆之后的副作用，")
line("     不是受控复现的并发故障 —— 别把它当结论引用。")
line("  5) store 的类型与位置没换过：全程 NSSQLiteStoreType + 临时目录下的单文件；")
line("     InMemory / Binary / XML 三种 store、CloudKit 同步、migratePersistentStore 换位置、")
line("     以及只读 store 被写入的分支都没测（§10 只开了 isReadOnly 这个开关看它默认值）。")
line("  6) SQLite 侧留了很大一块没进：sqlite3_blob_* 的增量读写、FTS5 与虚拟表、自定义 collation、")
line("     authorizer 与 progress handler（这两个和 §16 的 dictionaryHandler 一样，回调不返回就永远卡住）、")
line("     sqlite3_backup、增量 VACUUM、多线程共用一个句柄的语义（§7 只处理了同进程开两个连接的情况）。")
line("  7) 有些数字是这一版 SDK 的脾气，不是永恒事实：Z_PK 的取号顺序不保证（§11）、fault 何时出现随容器而异（§13）、")
line("     聚合别名的静默 nil（§15）都只在 iOS 18.3.1 模拟器 + x86_64 这一套上量到；换 Xcode 版本请重跑示例，别照抄文档里的数字。")
line("  8) UI 层完全没碰：本章不出现 NSFetchedResultsController —— 它的分节、变更差分和列表动画必须")
line("     在真跑起来的列表里才看得出对错，那是 §15（UIKit 列表）和 §11（SwiftUI 列表）的地盘；")
line("     本章给的「上下文不会自动通知你」那几条，正是接 FRC 之前必须先知道的前提。")
line("")
line("  一句话：这一章把「同一份 SQLite 文件上，C API 和 CoreData 各自替你做了什么、出事时谁说话」讲透了；")
line("  凡是性能、迁移通路、跨进程同步这三类问题，本章只指出坑在哪，答案得你自己按上面的边界去量。")
line("")
line("==== 26 结束 ====")
exit(failures == 0 ? 0 : 1)
