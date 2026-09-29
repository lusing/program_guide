# 26 · SQLite3 与 CoreData：同一个文件上的两套 API

> 示例：`examples/26_sqlite_coredata/main.swift`
> 实测输出见 `build/26_sqlite_coredata/stdout.debug.txt`

第 18 章把持久化讲到了**文件层**——UserDefaults、归档、Codable 写进沙盒、Keychain 存密钥。
那一层的共同点是「你交出一批值，框架还你一个文件」，中间没有查询、没有事务、没有增量更新。
这一章往下走两层，走到的地方是绝大多数 iOS 项目真正存数据的地方：

- **SQLite3**：iOS SDK 自带的 C 库。`import SQLite3` 之后你手里就是一个数据库文件，
  要自己准备语句、自己绑参数、自己逐步求值、自己判返回码。
- **CoreData**：不是 SQL，是「托管对象 + 上下文 + store」三层。它默认把数据写进**同一个 SQLite 文件**，
  但把上面那些活全替你做了——代价是它有一套自己的记账（`Z_PRIMARYKEY`、`Z_OPT`、`Z_METADATA`），
  以及一批「既不抛异常也不崩溃、只是读出 nil」的失败形态。

本章的写法是把**两套 API 指向同一个库文件**：用 C API 去读 CoreData 写出来的表（§11、§12），
也用 CoreData 的 `count(for:)` 去数 C API 直插进去的行（§12 的 C 段）。这样「谁替你做了什么、
出事时谁告诉你」就不是比喻，而是可以逐行打印出来的东西。

```
存在性   §1  import SQLite3 从哪来，以及那批返回码到底是几
连接     §2  三种「打开」和出厂 PRAGMA：NULL 文件名也算成功
准备     §3  一段文本两条语句：tail 才是循环的推进方式，nByte 按字节硬切
绑定     §4  参数名、越界、没绑的槽位——「数据莫名变空」的成因
读取     §5  列的六种读法，与「类型亲和」的真面目
错误码   §6  主码与扩展码：同一个错，两种说法，外键默认是关的
事务     §7  事务是扁平的、changes 是语句级的、close 有两种脾气
便捷壳   §8  sqlite3_exec 的回调，和往 SQL 里塞一个 Swift 函数
模型     §9  CoreData 的程序化模型：出厂值比想象中多（deleteRule 默认是 nullify）
容器     §10 容器与 store 描述：谁替你填了哪些默认值
底层     §11 打开 CoreData 的库文件，用 SQLite 的眼睛看它（Z 表、没有外键、WAL）
删除规则 §12 四种删除规则在 SQL 层各做了什么，和绕开 CoreData 直接改表的四笔账
身份     §13 objectID 的三段身份、fault 的不可预测、第二个上下文看什么
迁移     §14 模型改了、旧库怎么办：两个开关的四种组合，改名等于删数据
聚合     §15 一次问出统计值：NSExpressionDescription 的五个坑
批量     §16 批量请求：insert / update / delete 走 store，不经过上下文
```

## 本章的方法：这一章的每个数字是怎么来的

本章的每一条断言都跑在 iPhone 模拟器（iOS 18.3.1，x86_64）里，用 `xcrun simctl spawn` 直接执行
一个命令行可执行文件：没有 `UIApplicationMain`、没有窗口、没有 Xcode。示例文件头写着这套流程的
六条判定（编译零警告、退出码 0、**stderr 必须为空**、stdout 非空、stdout 不含控制字符、
末尾必须有 `==== 26 结束 ====`），外加 debug(`-Onone`) 与 release(`-O`) 两份 stdout **逐字节一致**。
这些判定直接决定了本章的四种写法，先立起来，后面每一节都能看见它们在起作用。

**1) 不打印任何路径、UUID、文件大小。** 临时目录名带设备标识，store 的 UUID 每次建库都不同，
打出来第二行就和第一行不一样。所以本章只打印**形状**：objectID 的 URI 里 host「是不是 36 个字符」
（§13）、store 旁边「有没有 -wal / -shm 两个文件」（§11）、错误消息里只要含斜杠就替换成
`<带路径，略>`（§16）。BLOB 同理不打内容，只打「是不是非空」和列的声明类型。

**2) CoreData 的失败日志一律用 `quiet()` 包住。** CoreData 出错时往 stderr 打一整段
`CoreData: error: …`，里面还带绝对路径，判定 3 和判定 4 会同时挂。做法是把 fd 2 临时 dup2 到
`/dev/null`：

```swift
func quiet(_ body: () -> Void) {
    let saved = dup(2)
    let dn = open("/dev/null", O_RDWR)
    _ = dup2(dn, 2)
    close(dn)
    body()
    _ = dup2(saved, 2)
    close(saved)
}
```

包住的代价是**错误信息得自己从 `NSError` 里取**——本章统一取三样：`domain`、`code`、
`userInfo.keys.sorted()`。这三样恰好都是稳定文本，可以直接写进断言，比原始日志更有信息量：

```swift
func errInfo(_ e: Error?) -> String {
    guard let e else { return "domain=nil（没出错）" }
    let n = e as NSError
    return "domain=\(n.domain) code=\(n.code) userInfo键=\(n.userInfo.keys.sorted())"
}
```

**3) 会崩、会死循环的调用只在独立探针进程里量，正文只引原文。** 本章撞到两处：§15 那个
「`resultType` 没设成 dictionary 却按 `NSFetchRequest<NSDictionary>` 取元素」的当场 trap，
以及 §16 那个「`dictionaryHandler` 永远不返回 true」的无终点循环。示例正文一行都不执行它们——
否则退出码就不是 0 了（后者还会把磁盘写满）。探针的做法和前面几章一样：单独编译一个可执行文件，
用命令行参数决定这个进程执行哪一条操作，逐个 spawn，崩了也只崩它自己。

**4) CoreData 的模型全部用代码构造。** 没有 `.xcdatamodeld`、没有 codegen 出来的子类，
读写一律走 `NSManagedObject` + `setValue(_:forKey:)` / `value(forKey:)`。这样做的目的是
**每个数字都能自己跑出来给你看**：属性类型、删除规则、表名列名，全都是运行时读回来的，
而不是「Xcode 里显示成这样」。代价写在章末的诚实边界里：模型编辑器那一套（`@objc dynamic`、
`representedClass`、codegen 选项）本章一条都没验。

**5) 断言写成「断言 + 讲解」同一行。** 这个 helper 是本章所有 `  ok  ` 行的来源：条件是一个 Bool，
后面跟着若干段讲解字符串，拼成**一整行**打印——文档里因此可以逐字引用它，
检查器（`tools/check_docs.py`）也能拿它和当前 build 输出做逐字比对，防止「改了断言文案忘了改文档」。

```swift
var failures = 0
func expect(_ condition: Bool, _ parts: String...) {
    print("  \(condition ? "ok  " : "FAIL") \(parts.joined(separator: ""))")
    if !condition { failures += 1 }
}
```

理解了这五条，下面 16 节里每一行输出你都能自己复现；本章的 17 个 `ok` 全部来自一次真实运行，
没有一个数字是背出来的。

---

## 1) `import SQLite3`：它从哪来，以及那批返回码到底是几

先把最容易搞错的一件事放前面：**iOS SDK 里就带着 SQLite，而且是带着 module map 的**。
`import SQLite3` 直接可用，不需要桥接头（那是 Objective-C 的事），不需要 `-lsqlite3`，
也不需要像第 19、25 章那样在示例目录里放一个 `Frameworks` 文件。SDK 的
`usr/include` 下有 `SQLite3.modulemap`，顶层 `module.modulemap` 又写了
`extern module "SQLite3"`，Swift 看到这个 C 模块就当库来用。

但**链接期并没有 `libSQLite3.tbd`**。所以 `-framework SQLite3` 是不能写的，`clang` 或 `swiftc`
硬加这一句会直接 `ld: framework 'SQLite3' not found`。这一层「模块存在但没有同名 framework」
的错位，是很多人第一次在 Swift 里用 SQLite 就卡住的原因。

版本要读出来，不要背。这一版工具链给的是 3.43.2 / 3043002 / sourceid 前缀 `2023-10`：

```swift
line("  libversion=\(sp(sqlite3_libversion())) libnumber=\(sqlite3_libversion_number()) "
     + "sourceid 前 8 字符=\(String(cString: sqlite3_sourceid()).prefix(8))")
```

`sqlite3_libversion_number()` 和版本字符串之间有确定的算术关系，可以用来验算自己有没有读错：
`3043002 == 3*1000000 + 43*1000 + 2`。换一份 Xcode 就是另一批数字，所以本章后面凡是涉及
SQLite 行为的结论，都由「跑一遍看看」支撑，而不是「SQLite 文档说」。

真正需要记住的是**返回码的形状**。这一层没有异常，每个函数都返回一个 `Int32`，而它的取值
分成三族：

| 族 | 名字 | 值 | 什么时候拿到 |
| --- | --- | --- | --- |
| 结果码 | `SQLITE_OK` | 0 | 「这事成了」——也包括「什么都没做」 |
| 结果码 | `SQLITE_ROW` | **100** | `step` 出了一行数据，继续 `step` |
| 结果码 | `SQLITE_DONE` | **101** | `step` 说没有更多行了 |
| 错误码 | `SQLITE_ERROR` | 1 | 泛用错误：SQL 写错、列名不存在、不在事务里就 ROLLBACK |
| 错误码 | `SQLITE_MISUSE` | 21 | API 用错了：句柄是 NULL、语句已经 `DONE` 还继续 `step` |
| 错误码 | `SQLITE_RANGE` | 25 | 索引越界：`bind`/`column` 的列号不在 `1...count` |
| 错误码 | `SQLITE_CONSTRAINT` | 19 | 任何约束违约（主键、外键、CHECK、NOT NULL 全用它） |
| 错误码 | `SQLITE_BUSY` | 5 | 库被别的连接锁着，或者 `close` 时还有没 `finalize` 的语句 |
| 值类型码 | `SQLITE_INTEGER` / `FLOAT` / `TEXT` / `BLOB` / `NULL` | 1 / 2 / 3 / 4 / 5 | `column_type`、`value_type` 的返回值 |

三个「形状」必须靠肌肉记忆，因为它们都会伪装成成功或失败：

- `ROW=100`、`DONE=101` **是大数字，不是 0/1**。写过 `if sqlite3_step(st) == 1` 的人都在这里翻过车
  ——`1` 是 `SQLITE_ERROR`，那个判断永远为假。
- `SQLITE_OK` 是 0，也就是 Swift 里的「假」。所以永远写 `!= SQLITE_OK` 或 `== SQLITE_OK`，
  千万别把返回码直接当 Bool 用（`if sqlite3_step(st) { }` 是「不为 0 就成立」，跟直觉正好相反）。
- `MISUSE=21` 和 `RANGE=25` 不挨着，也不在 `1...5` 那个小区间里。

`SQLITE_CONSTRAINT`（19）只是**主码**，它底下还有一整套扩展码，默认拿不到——
主键重复是 `19 + 256*6 = 1555`，这个开关在 §6 现场演示。

本节还顺手量了一件很说明问题的事：对一个**根本没打开的 NULL 连接**调 `prepare`，返回 `MISUSE`
而不崩，而失败之后 `errmsg` 给的是 `'out of memory'`——一句和真实原因毫不相干的话。§2 展开。

```
== 1) import SQLite3：它从哪来，以及那批返回码到底是几 ==
  libversion=3.43.2 libnumber=3043002 sourceid 前 8 字符=2023-10-
  状态码：OK=0 ROW=100 DONE=101 ERROR=1 MISUSE=21 RANGE=25
  约束码：CONSTRAINT=19 PRIMARYKEY 扩展码=1555 BUSY=5
  值类型码：INTEGER=1 FLOAT=2 BLOB=4 NULL=5 TEXT=3
  ok   iOS SDK 里就带着 SQLite：`import SQLite3` 直接可用（本文件第 3 个 import），不需要 -lsqlite3、不需要桥接头，也不需要在本示例的 Frameworks 文件里列它 —— SDK 的 usr/include 下有 SQLite3.modulemap，顶层 module.modulemap 又写了 extern module "SQLite3"，Swift 就把这个 C 模块当库来用；但**链接期并没有 libSQLite3.tbd**，硬写 -framework SQLite3 会直接 ld: framework 'SQLite3' not found。读回来的版本是这台工具链（iPhoneSimulator18.2.sdk）里的 3.43.2 / 3043002 / sourceid 前缀 2023-10，换一份 Xcode 就是另一批数字，所以本章所有常量都是打印出来对照的，不是背出来的。版本号本身有个算术关系可用来验算：3043002 == 3*1000000 + 43*1000 + 2。真正要记住的只有形状：ROW=100、DONE=101 是大数字而不是 0/1（写过 if sqlite3_step(st) == 1 的人都在这里翻过车），MISUSE=21、RANGE=25 也不挨着；CONSTRAINT=19 只是**主码**，它下面还有一整套扩展码（PRIMARYKEY = 19 + 256*6 = 1555），默认拿不到，§6 现场演示那个开关。顺带这一行的 expect 条件也说明了一件事：对一个根本没打开的 NULL 连接调 prepare 也是失败（返回 MISUSE），不会崩 —— 而失败之后 errmsg 给的是 'out of memory'，§2 展开。
```

## 2) 打开连接：三种「打开」都算成功，出厂 PRAGMA 里藏着一个坑

`sqlite3_open(filename, &db)` 是本章唯一的入口，它有三个「看起来没事」的入口形态，
每一个都会让后续代码在错误的假设上跑很久：

```swift
var db: OpaquePointer?
let rc = sqlite3_open(":memory:", &db)   // rc=0，db 有值
```

| 传进去的文件名 | `rc` | 实际得到什么 | 坑在哪 |
| --- | --- | --- | --- |
| `":memory:"` | 0 | 内存库，**同名可被多个连接共享** | 关掉就没了；`journal_mode` 是 `memory` |
| `""`（空串） | 0 | **匿名临时库**，每次都是私有的一份 | 它**不是** `:memory:`：不共享、没路径、关掉即蒸发 |
| `NULL`（Swift 里传 nil） | **0** | 同上，匿名临时库 | 建表插入全部合法，你以为写进了文件 |
| 真实路径 | 0 | 文件库，文件不存在就创建 | 只给文件名时是**相对当前工作目录**，不是相对你的沙盒 |

第三条最要命：`sqlite3_open` **不校验空指针**，传 nil 文件名返回成功，给你一个不在任何路径上的
临时库。数据全在里面，程序以为落盘了。同理，对 NULL 句柄调 `errmsg` 返回 `'out of memory'`
（不崩、也不说真话），调 `sqlite3_close_v2(NULL)` 返回 0。这一层的结论只有一条：
**每一次调用的返回码都要判，判不过立刻停**，因为 SQLite 既不替你兜住「你传了个空」，
也不替你保留真正的失败原因。

四个出厂 PRAGMA 值得单独记，它们决定了「为什么不报错」：

```
  open(":memory:") rc=0 句柄有值=true
  内存库出厂 PRAGMA：journal_mode=memory encoding=UTF-8 foreign_keys=0 user_version=0
  open("")（空串不是魔法文件名）rc=0 句柄有值=true 表数量=0
  open(NULL 文件名) rc=0 句柄有值=true errmsg=not an error
  对 NULL 句柄动真格：exec 返回 21，errmsg(NULL) 给 'out of memory'，close_v2(NULL) 返回 0
  拿这个「打开成功」的句柄执行一条 SQL：rc=0 errmsg=not an error
  user_version 是可以直接写的应用槽位：exec rc=0 读回=7
```

- `journal_mode`：内存库是 `memory`；文件库 CoreData 会给 `wal`（§11 现场对比）。
- `encoding`：`UTF-8`，跟着连接走，不看你的字符串内容。
- **`foreign_keys`：0**。外键约束**默认关闭**——这是「SQLite 为什么不拦住脏数据」最常见的原因，
  §6 用一条 `REFERENCES` 现场验证。
- `user_version`：0。这是留给应用自己的整数槽位，`PRAGMA user_version=7` 写进去就能读回来。
  不用 CoreData 的项目普遍靠它做 schema 迁移（很多 ORM 就是这么干的）；
  §14 会看到 CoreData **完全不维护它**，读完还是 0，CoreData 的版本记在自己的 `Z_METADATA` 里。

```
  ok   SQLite 的 C API **不校验空指针的场合比想象中多**，三条路都通到「看起来没事」：
  · open 传 NULL 文件名 → 返回 0（成功），给你一个**匿名临时库**：建表插入都合法（上面那行 rc=0），只是它不在任何路径上，关掉就没了，也没法再打开一次 —— 你的数据全在里面，而你以为写进了文件；
  · open 传空串 → 同上，和 :memory: 也不是一回事（:memory: 是共享名字，空串是每次私有）；
  · 对根本没打开的 NULL 句柄调 errmsg → 不是 'invalid handle'、也不崩，而是 'out of memory'，一句和真实原因毫不相干的谎。
这三条是同一个教训：这一层的返回值必须**每一次都判**，判不过就立刻停，因为 SQLite 既不替你兜住「你传了个空」，也不替你保留真正的失败原因。另外记四个出厂值：journal_mode 对内存库是 memory（对文件库是 wal，§11 现场对比）；encoding 是 UTF-8（跟连接走，不看你的字符串内容）；**foreign_keys 是 0** —— 外键约束默认关闭，这是「SQLite 为什么不报错」最常见的一个原因（§6 现场验证）；user_version 出厂 0，是给应用自己用的整数槽位，PRAGMA user_version=7 写进去就能读回来，很多不用 CoreData 的项目就靠它做自己的 schema 版本迁移（§14 会看到 CoreData **完全不维护它**，读完还是 0）。
```

## 3) 准备语句：一段文本两条语句，`tail` 才是循环的推进方式

SQLite 的 C API 把「跑一条 SQL」拆成三步：`prepare`（解析并编译成句柄）→ `step`（执行/出一行）
→ `finalize`（释放）。理解 `prepare` 的**边界**是这一节的正题：它**不执行**，
而且它只看得到**第一条语句**。

```swift
let two = "SELECT 1; SELECT 2;"
two.withCString { p in
    var st: OpaquePointer?
    var tail: UnsafePointer<CChar>?
    let rc = sqlite3_prepare_v2(pdb, p, -1, &st, &tail)
    // rc=0，st 是「SELECT 1」，tail 指向原文里剩下的字节
    sqlite3_finalize(st)
    if let t = tail {
        var st2: OpaquePointer?
        let rc2 = sqlite3_prepare_v2(pdb, t, -1, &st2, nil)   // 第二条从这里拿
        sqlite3_finalize(st2)
    }
}
```

`tail` 是一个指向**原字符串内部**的指针，本章用指针相减把偏移量打成字节数：
`' SELECT 2;'` 前面那个空格是原样的——分号之后的空白不属于任何语句，但它留在 tail 里。

于是「一次跑一整段 SQL 文本」的正确循环是：

```swift
// 伪码：p 指向文本开头
while 指针还没走到结尾 {
    prepare(p, ..., &stmt, &tail)   // 出错就报在这一条上
    step 到底
    finalize
    p = tail                        // 推进，而不是重头再来
}
```

不这么写的人会撞到本节的第三种情形，也是排查 SQL 迁移脚本时最费时间的一种：**第一条好、第二条坏**。

```
== 3) 准备语句：一段文本两条语句，tail 与 nByte ==
  "SELECT 1; SELECT 2;" 一次 prepare：rc=0 第一条列数=1 step=100 值=1
  tail 指向原文第 9 个字节，内容=' SELECT 2;'（开头有个空格）
  拿 tail 再 prepare 第二条：rc=0 step=100 值=2
  第一条是 INSERT：step=101（DONE=101，不是 ROW）last_insert_rowid=7 changes=1
  第二条（由 tail 得到）：step=100 值=七
  坏在第二条：第一条 rc=0 tail=' SELEKT 2;' —— prepare 只看第一条
  于是错误要等 prepare 第二条才现形：rc=1 句柄还是 nil=true errmsg=near "SELEKT": syntax error
  nByte=12（正好切在字符串字面量中间）：rc=1 errmsg=unrecognized token: "'abcd"
  nByte=18（只是少了结尾分号）：rc=0 step=100 两列=abcdef/7
  语句级只读判定：stmt_readonly(SELECT)=1 stmt_readonly(INSERT)=0 db_readonly(内存库)=0
```

`prepare` 对 `SELECT 1; SELEKT 2;` 返回 `SQLITE_OK`，句柄给你，坏的那条**一根汗毛都没暴露**；
错误要等拿 tail 再 prepare 才现形，`errmsg` 是 `near "SELEKT": syntax error`。
这就是为什么「执行了一整段 SQL，rc 都是 0，结果表里少一张」这种事会发生——你的循环根本没跑到第二条。

第三个参数 `nByte` 是**按字节硬切**的长度，不是「读几个字符」：`-1` 表示到 NUL 为止，
给正数就在第 N 个字节处切断。切在字符串字面量中间，得到的是 `unrecognized token: "'abcd"`——
一个语法层的错，而不是「少了个分号」这种温和提示；反过来，**少了结尾分号完全没事**
（SQLite 不要求最后一条带分号）。所以 `nByte` 给 `-1` 是唯一安全的选择，除非你在做增量解析。

最后是两个「只读」判定，它们不是同一件事：

```swift
sqlite3_stmt_readonly(st)   // 语句级：这条语句会不会改数据库？SELECT=1，INSERT=0
sqlite3_db_readonly(db)     // 连接级：这个库文件是不是只读打开的？正常打开都是 0
```

判断「这条语句能不能安全地在只读事务里跑」要用**前者**。一个常见误解是把
`sqlite3_stmt_readonly` 当成「BEGIN…COMMIT 包裹的读事务里能用」的保证——它只说明这条语句不写数据。

## 4) 绑定：参数名、越界、没绑的槽位——「数据莫名变空」的成因

`?` 占位符的索引**从 1 开始**，`0` 和 `count+1` 一样越界，越界返回 `SQLITE_RANGE`（25）而不是崩。
这一句本身不危险，危险的是它连起来的那条链路：**`bind` 失败可以「静默过去」**，
因为你接下来照样 `step`，那条 INSERT 会成功，没绑上的槽位按 NULL 存进去。

```
== 4) 绑定：参数名、越界、没绑的槽位 ==
  两个问号：bind_parameter_count=2 name(1)='<nil>' index("?")=0
  具名参数：count=2 name(1)='$AAA' name(2)=':bbb'
  按名字问索引：index("$AAA")=1 index(":bbb")=2 index("$aaa")=0
  越界索引：idx=0 → 25，idx=3 → 25（SQLITE_RANGE=25），当场 errmsg='column index out of range'
  一个都不绑，直接 step：rc=101 表里行数=1 a 列的 typeof=null
  绑 TEXT（第 4 个参数给 -1，即 C 里的 SQLITE_TRANSIENT）rc=0，绑 REAL rc=0
  表里两行原样（第 1 行是没绑就 step 的，第 2 行是绑过的）：1 | <NULL> | <NULL> | null | null ;; 2 | 临时字符串 | 1.5 | text | real
  同一条语句 step 到底之后再 step：rc=21（MISUSE=21）；reset rc=0 再 step rc=101
```

上面第 5 行就是这条链路走完的样子：一个都不绑直接 step，`rc=101`（DONE，成功），
表里多了一行，`typeof` 读回来是 `null`。**这是「数据库里莫名出现空值」的经典成因**：
`bind` 的返回值没判，或者 `if/else` 少走了一分支，SQLite 不会拒绝你。

`errmsg` 在这里帮不上忙。越界那一瞬间它确实是 `'column index out of range'`，
但**一次成功的 step 就把它冲回 `'not an error'`**（§6 末尾同一件事再来一次）。
所以 errmsg 只能用来打日志，**不能用来判断「这次到底成没成」**——判 rc 才对。

参数名这一族也有三个坑，本节全量到了：

```swift
// 两个匿名问号
sqlite3_bind_parameter_count(st)     // 2
sqlite3_bind_parameter_name(st, 1)   // NULL（匿名参数问不出名字）
sqlite3_bind_parameter_index(st, "?")// 0（问号问不出索引，只能按位置绑）

// 具名参数：三种前缀都支持，且大小写敏感
// name(1)='$AAA'  name(2)=':bbb'
// index("$AAA")=1  index(":bbb")=2  index("$aaa")=0  ← 问小写得到 0
```

`$AAA`、`:bbb`、`@ccc` 三种前缀都合法（`?NNN` 是第四种，带编号的问号）。
具名参数的好处是绑错顺序不会静默成功，但**大小写敏感**这一条很容易忘：问不到索引时返回 0，
而 0 是越界值——绑上去就是本节那个 RANGE=25。

第四个参数是本章最「Swift 不友好」的一处。C 里它是两个宏：

```swift
// C：sqlite3_bind_text(st, 1, s, -1, SQLITE_TRANSIENT)
rcBindPair = (sqlite3_bind_text(stQ, 1, cString, -1,
                                 unsafeBitCast(-1, to: sqlite3_destructor_type.self)), …)
```

`SQLITE_TRANSIENT` / `SQLITE_STATIC` 这两个名字在 Swift 里**根本不存在**
（直接写会 `cannot find 'SQLITE_TRANSIENT' in scope`，它们是宏，不进模块接口），
只能像上面这样手搓。两个值的语义差别很大，值得写清：

| 第 4 个参数 | 值 | 含义 | 什么时候用 |
| --- | --- | --- | --- |
| `SQLITE_TRANSIENT` | `-1` | SQLite **立刻自己复制一份**，之后你原来的内存随便改、随便释放 | 绑 Swift 的 `String`、栈上的缓冲、任何你不掌控生命周期的东西 |
| `SQLITE_STATIC` | `0` | SQLite 直接用你给的指针，**假定它在语句用完前一直有效** | 常量字符串、你保证活到 `finalize` 之后的缓冲 |

本章一律用 TRANSIENT，因为 Swift 的 `String.withCString { p in … }` **只在闭包内保证指针有效**，
闭包一返回那块内存就不归你管了。谁在这里图省事写了 `0`（STATIC），拿到的是一个
use-after-free 级别的偶发乱码——它不会当场崩，会在完全不同的地方崩，或者把乱码存进库里。

最后一行是生命周期，也是批量写入的正确节奏：

```
  ok   参数索引**从 1 开始**，0 和 count+1 一样都是越界，越界给的是 RANGE=25 而不是崩溃 —— 也就是说 bind 失败可以「静默过去」：本节接着 step，那条 INSERT 照样成功，两个槽位都按 NULL 存进去（typeof 读回来是 'null'）。**这是「数据莫名变成空」的经典成因**：bind 的返回值没判，或者 if/else 少走了一分支，SQLite 不会拒绝你，它把没绑的槽当 NULL。越界那一瞬间 errmsg 确实是 'column index out of range'，但**一次成功的 step 就把它冲回 'not an error'**（§6 末尾同一件事再来一次），所以 errmsg 只适合打日志，不适合用来判断「这次到底成没成」。三个细节：`?` 这种匿名参数 name 返回 NULL、index("?") 返回 0（问不出来，只能按位置绑）；具名参数大小写敏感（$AAA 与 $aaa 是两个槽，问后者得到 0）；第四个参数在 C 里是 SQLITE_TRANSIENT / SQLITE_STATIC 两个**宏**，Swift 里这两个名字根本不存在（直接写会 cannot find 'SQLITE_TRANSIENT' in scope），只能像本节这样 unsafeBitCast(-1, to: sqlite3_destructor_type.self) 手搓 TRANSIENT 的语义。STATIC（给 0）的意思是「这块内存我保证活得比 stmt 久」，而 Swift 的 String.withCString 只在闭包内保证指针有效，所以本章一律用 TRANSIENT；谁在这里图省事写了 0，就是一个 use-after-free 级别的偶发乱码。最后一行是生命周期：一条语句 step 到 DONE 之后再 step 返回 MISUSE，必须先 reset（返回 0）才能再跑 —— 「绑新参数 → reset → step」就是批量插入的正确节奏，而 CoreData 把这整套节奏都替你做了（§16）。
```

一条语句 step 到 `DONE` 之后再 step，返回 `MISUSE`（21）；必须先 `reset`（返回 0）才能再跑。
所以「绑新参数 → reset → step」是循环插入的标准三步，`reset` 不清空已绑的值、只把语句回到起始状态。
顺带一提：CoreData 把这整套节奏都替你做了——这正是 §16 批量请求快的原因。

## 5) 列的六种读法，与「类型亲和」的真面目

`sqlite3_column_*` 是一族六个函数，它们对**同一列**给六个不同的答案，而这六个答案都不算错：

```swift
sqlite3_column_int(st, i)     // Int32：尽力转，转不动给 0
sqlite3_column_int64(st, i)   // Int64
sqlite3_column_double(st, i)  // Double：尽力转
sqlite3_column_text(st, i)    // UnsafeMutablePointer<UInt8>?：NULL 列给 NULL 指针
sqlite3_column_blob(st, i)    // UnsafeMutablePointer<Void>?：不是 blob 存的东西也可能给 NULL
sqlite3_column_type(st, i)    // 1/2/3/4/5：这一列**此刻**装着哪一族
```

先说这一节最容易埋雷的一条：**TEXT 的 `'hello'` 用 `column_int` 读是 0**，不报错、不返回 nil、
`errmsg` 也不动。REAL 的 `4.0` 用 text 读回来是 `'4.0'`（带小数点），用 int 读是 `4`。
于是「列读出来是 0」有三种可能：数据真是 0、数据是转不成数字的文本、读法不对。
**这一层不会告诉你是哪一种**，能区分的只有 `column_type`。

```
== 5) 列的六种读法，与「类型亲和」 ==
  列名写错在 **prepare** 就失败：rc=1 errmsg=no such column: nosuch
  列数=6 列名=i,r,s,b,n,i+1
  decltype（建表时声明的类型）=INTEGER,REAL,TEXT,BLOB,INTEGER,<nil>
  运行时类型码=1,2,3,4,5,1（INTEGER=1 TEXT=3 BLOB=4 NULL=5）
  同一列的不同取法：int(r)=4 double(r)=4.0 text(r)='4.0' int(s)=0 text(i)='4'
  NULL 列（第 5 列）：type=5 text 指针 nil=true blob 指针 nil=true bytes=0 int=0 double=0.0
  亲和性现场：INTEGER 列存 '24abc' 之后 typeof=text 值='24abc'，REAL 列存 '24' → typeof=real 值=24.0
  BLOB 列（第二行给了整数 42）：typeof=integer length()=2 column_blob 指针 nil=true 先 column_bytes 再取指针 nil=true
  CAST 才是显式转换：CAST(s AS INTEGER)='0'（'hello' 转不成数），CAST('24abc' AS INTEGER)='24'（前缀 24 被吃下来了）
```

第二件事：**列不会把你要的类型当约束**。这就是 SQLite 的「类型亲和」（affinity）——
建表时声明的类型只决定「能不能顺手转换一下」，不决定「不许存什么」：

| 声明 | 塞进去的值 | 实际存成 | 为什么 |
| --- | --- | --- | --- |
| `INTEGER` | `'24abc'` | **TEXT** `'24abc'` | 转不成整数就原样存 |
| `REAL` | `'24'` | REAL `24.0` | 能转，转了 |
| `BLOB` | `42` | **INTEGER** `42` | BLOB 亲和是「什么都不动」，整数本来就不用动 |

想要硬约束只有两条路：建表时写 `CHECK`，或者打开外键（§6，而且它默认是关的）。
注意上表第三行的连带后果：往 BLOB 列塞整数，`length()` 按**字符数**给 2，
而 `column_blob` **直接返回 NULL 指针**——明明有值却读不到字节，先调 `column_bytes` 也一样。
要真拿二进制就存 `X'DEAD'` 这种 blob 字面量，读的时候 `column_blob` + `column_bytes` **成对用**。

第三件事最危险，也是本章所有读取都包一层函数的原因：NULL 那一行
`text` 和 `blob` 两个指针**都是 NULL**，`bytes=0`，`int=0`，`double=0.0`。
所以任何 `String(cString: sqlite3_column_text(st, i))` 都是在赌这列不是 NULL，
赌输的现场是 Swift 的 `Unexpectedly found nil` + signal 4。本章的包装长这样：

```swift
func colText(_ st: OpaquePointer?, _ i: Int32) -> String {
    guard let p = sqlite3_column_text(st, i) else { return "<NULL>" }
    return String(decoding: UnsafeBufferPointer(start: p,
                        count: Int(sqlite3_column_bytes(st, i))), as: UTF8.self)
}
```

这里还藏着一个纯 Swift 侧的坑：`sqlite3_column_text` 的返回类型是
`UnsafeMutablePointer<UInt8>?`，**不是** `UnsafeMutablePointer<CChar>?`（Int8）。
所以它**不能**直接喂给 `String(cString:)`，只能 `String(decoding:as:UTF8.self)`——
按 `column_bytes` 给的长度解码，顺带也避免了「内容里有嵌入 NUL 就被截断」。

第四件事：`decltype` 和 `typeof` 不是一回事。

```
  decltype（建表时声明的类型）=INTEGER,REAL,TEXT,BLOB,INTEGER,<nil>
```

`sqlite3_column_decltype` 给的是**建表时写的声明类型**，表达式列（`i+1`）没有声明类型 → NULL；
而 `sqlite3_column_type` / SQL 的 `typeof()` 给的是**这一行此刻的运行时类型**。
判「这列现在装的是什么」必须用后者，把 decltype 当运行时类型是迁移和报表代码里的常见错。

最后一条时机：列名写错在 **prepare** 就失败（`no such column: nosuch`，rc=1），不是 step。
所以列名拼错会在「建语句句柄」那一步立刻暴露——这也是 CoreData 的 fetch 里
拼错属性名会抛错的原因（§15 那条 nil 陷阱的对照面）。
想要**显式**转换而不是靠亲和，只有 SQL 的 `CAST`：`CAST(s AS INTEGER)` 对 `'hello'` 给 0，
而 `CAST('24abc' AS INTEGER)` 给 **24**（前缀被吃下来了）——这套「尽力取前缀」的规则和
`column_int` 是同一条，理解了它就能预测所有弱类型读法的结果。

## 6) 主码与扩展码：同一个错，两种说法；外键默认是关的

约束违约只有一个主码 19。想知道是「主键重复」「外键没父」「CHECK 失败」还是「NOT NULL 缺失」，
必须知道扩展码这套机制。扩展码的构成是**主码 + 256 × 子序号**，所以：

| 违约类型 | 子序号 | 扩展码 | 怎么算 |
| --- | --- | --- | --- |
| `SQLITE_CONSTRAINT_CHECK` | 1 | 257 | 19 + 256×1 |
| `SQLITE_CONSTRAINT_NOTNULL` | 5 | **1299** | 19 + 256×5 |
| `SQLITE_CONSTRAINT_PRIMARYKEY` | 6 | **1555** | 19 + 256×6 |
| `SQLITE_CONSTRAINT_FOREIGNKEY` | 3 | **787** | 19 + 256×3 |
| `SQLITE_CONSTRAINT_UNIQUE` | 8 | 2056 | 19 + 256×8 |

```
== 6) 主码与扩展码：同一个错，两种说法 ==
  主键重复：exec rc=19 errcode=19 extended_errcode=1555 errmsg=UNIQUE constraint failed: k.id
  不开扩展时拿不到 1555，只有主码 19；扩展码的构成是 主码 + 256*子序号：19 + 256*6 = 1555
  同一层里的 NOT NULL 违约：rc=19，也就是主码 19，**开关没开时看不出色子**；同一时刻 sqlite3_extended_errcode 已经能问出 1299 = 19 + 256*5，errmsg=NOT NULL constraint failed: k.tag
  sqlite3_extended_result_codes(db,1) rc=0 之后再犯同一个错：rc=1555（返回值本身升级了）errmsg=UNIQUE constraint failed: k.id
  开关打开之后 sqlite3_errcode 也跟着返回扩展码：同一时刻 errcode=1555 extended=1555
  errmsg 只记录**最后一次调用**，成功一次就清空：紧跟着插一行 rc=0，errmsg 立刻变回 'not an error'
  外键默认关：往 REFERENCES k(id) 的列插一个不存在的父键 rc=0 errmsg='not an error'
  PRAGMA foreign_keys=ON 之后 foreign_keys=1
  同一个错再犯一次：rc=787 extended=787 errmsg=FOREIGN KEY constraint failed
  ok   这一节的核心是**同一个错误有两种说法**。默认 rc 给的是主码 19（SQLITE_CONSTRAINT），想知道到底是「主键重复」「外键没父」「CHECK 失败」还是「NOT NULL 缺失」，要么看 errmsg 的文本（做产品可以，做逻辑判断不行），要么用 sqlite3_extended_errcode 显式问扩展码，要么调 sqlite3_extended_result_codes(db,1) 让**返回值本身**升一级（19 + 256*子序号，主键重复就是 1555）。注意开关是**连接级**的：换一条连接就得重设一遍。第二件事：NOT NULL 违约的主码也是 19（rc & 0xFF），子序号却是 5（1299 = 19 + 256*5），主键重复是 6，外键没父是 3 —— **想知道是哪一类约束只有扩展码办得到**。还要知道那个开关的副作用：打开之后 sqlite3_errcode **也**返回扩展码（上面倒数第二行两个数字相等就是证据），所以判 `rc == SQLITE_CONSTRAINT` 的代码在有的连接上会突然不再成立 —— 开关要么全局统一，要么用主码掩码。errmsg 只记最后一次调用：紧跟着一次成功的 INSERT 就把它冲回 'not an error'，所以它只能用来打日志，不能当「最近一次错误历史」查，也不能用来判断这次成没成 —— 判 rc 才对。第三件事值得单独抄一遍：**外键默认是关的**（§2 的出厂 PRAGMA 已经给了 0），所以带 REFERENCES 的表照样能插进没有父记录的孤儿子行，rc=0、errmsg 说 'not an error'。这不是 bug，是 SQLite 的历史默认值；要么每条连接都 PRAGMA foreign_keys=ON（CoreData 不给你开，§11 见），要么就别指望这层约束。开了之后同一个错立刻变成 rc=787，扩展码 787，errmsg 变成 'FOREIGN KEY constraint failed' —— 一句之差就是「脏数据静默入库」和「当场拒绝」。
```

三条机制从这段输出里读出来：

**1) 默认只给主码。** `rc=19`，`errcode=19`，想拿 1555 得显式问
`sqlite3_extended_errcode(db)`。也可以让**返回值本身**升一级：

```swift
sqlite3_extended_result_codes(db, 1)   // 之后 rc 直接给 1555
```

两个必须知道的性质：这个开关是**连接级**的（换一条连接就得重设一遍）；
打开之后 `sqlite3_errcode` **也**跟着返回扩展码（上面倒数第二行两个数字相等就是证据），
于是原来写 `rc == SQLITE_CONSTRAINT`（19）的判断会突然不再成立。
所以要么全局统一开，要么判的时候永远先掩码：`rc & 0xFF == SQLITE_CONSTRAINT`。

**2) NOT NULL 违约的主码也是 19。** 子序号是 5，主键重复是 6，外键没父是 3——
**想知道是哪一类约束，只有扩展码办得到**，errmsg 的文本虽然也写着
`NOT NULL constraint failed: k.tag`，但把逻辑建立在文本匹配上是给自己埋雷。

**3) `errmsg` 只记录最后一次调用。** 紧跟着一次成功的 INSERT，它就变回 `'not an error'`。
所以它只能打日志，不能当「最近一次错误历史」查，也不能用来判断这次成没成。

最后是本节最该抄下来的一条：**外键默认是关的**（§2 出厂 `foreign_keys=0`）。
所以带 `REFERENCES k(id)` 的表照样能插进父记录不存在的孤儿子行，`rc=0`，
errmsg 说 `'not an error'`。这不是 bug，是 SQLite 的历史默认值——为了兼容
早期没有外键的数据库文件。对策只有两种：每条连接都 `PRAGMA foreign_keys=ON`
（注意 CoreData 不给你开，§11 见），或者别指望这一层约束。
开了之后同一个错立刻变成 `rc=787`、errmsg 变成 `FOREIGN KEY constraint failed`——
一句之差就是「脏数据静默入库」和「当场拒绝」。

## 7) 事务是扁平的，`changes` 是语句级的，`close` 有两种脾气

SQLite 的事务模型和很多封装层不一样：**它不支持嵌套**。

```
== 7) 事务、changes 计数、close 的两种脾气 ==
  出厂：autocommit=1（1＝每条语句自己就是一个事务）
  BEGIN rc=0 两条 INSERT rc=0 事务内 autocommit=0 changes()=1 total_changes()=2
  事务没结束再 BEGIN：rc=1 errmsg=cannot start a transaction within a transaction（autocommit 还是 0，前两条 INSERT 没被它毁掉）
  要嵌套只能用 SAVEPOINT：rc=0 行数=3
  COMMIT rc=0 之后 autocommit=1 行数=3
  BEGIN/INSERT/ROLLBACK：行数=3 但 total_changes 仍然把回滚掉的算进去了=4
  不在事务里 ROLLBACK：rc=1 errmsg=cannot rollback - no transaction is active
  changes 是**语句级**的：插一行 rc=0 changes=1；紧接着 UPDATE 一行都不命中 rc=0 changes=1 而 x=0 的行数=0
  留着没 finalize 的 stmt 去 close：rc=5 errmsg=unable to close due to unfinalized statements or unfinished backups
  同一个句柄改用 close_v2：rc=0（它答应「有未完成的语句也放行」，见 §11 CoreData 的收尾）
  ok   SQLite 的事务是**扁平**的：事务没结束再 BEGIN 直接 rc=1（ERROR），errmsg 就是上面那行引号里的 'cannot start a transaction within a transaction'（它不带任何「你的数据怎么样了」的信息），好消息是它**不会**把已有事务撕开（autocommit 还是 0），坏消息是很多封装层就是这么把外面的 BEGIN 提前 COMMIT 掉的；要嵌套只有 SAVEPOINT/RELEASE/ROLLBACK TO 这一条路（上面刚跑过，rc=0），或者先查 sqlite3_get_autocommit()：返回 1 才说明当前不在事务里，这时才可以 BEGIN。计数有两个：changes() 只说**上一条语句**影响了几行（UPDATE 不命中就是 0，DDL 也是 0），total_changes() 说这条连接打开以来累计了几行，**连回滚掉的也一并累计**（上面 ROLLBACK 之后它照涨），所以用它判断「这次有没有改到数据」是错的，用它做遥测才对；不在事务里 ROLLBACK 也给 rc=1。还有 close：留着一个没 finalize 的 stmt 去 sqlite3_close，返回 5（SQLITE_BUSY，不是错误码里的 SUCCESS），库**没有被关**，连接还在；这条路径上是内存与文件句柄泄漏的经典来源（Swift 里 OpaquePointer 不走 ARC，忘了 finalize 就是真忘了）。sqlite3_close_v2 则是「有未完成的语句也照样放行，等最后一个游标关掉时再真正释放」，所以本节的第二次调用返回 0。官方建议：新代码一律用 close_v2，除非你确实需要「漏了 finalize」这件事以错误码的形式暴露出来 —— 上面那两行就是让你看见两种脾气的差别。
```

把这几件事分清楚：

- **`BEGIN` 在事务里再 BEGIN 是错误**：`rc=1`（ERROR），errmsg 就是
  `cannot start a transaction within a transaction`。好消息是它**不会**把已有事务撕开
  （`autocommit` 还是 0，前面两条 INSERT 没被毁掉）；坏消息是很多 ORM 封装层
  就是这么把外面的 `BEGIN` 提前 COMMIT 掉的——它们捕获到这个错就直接收尾。
- **要嵌套只有 SAVEPOINT**：`SAVEPOINT sp1` / `RELEASE sp1` / `ROLLBACK TO sp1`，
  语义和 BEGIN/COMMIT 的差别是「可以套在事务里，也可以自成事务」。
- **`sqlite3_get_autocommit(db)`** 是「我现在到底在不在事务里」的唯一权威：返回 1 表示不在
  （出厂就是 1：每条语句自己就是一个事务），这时才可以 `BEGIN`。
- **`ROLLBACK` 不在事务里也给 `rc=1`**，errmsg 是 `cannot rollback - no transaction is active`。

计数有两个，混用是最常见的报表 bug：

| 函数 | 范围 | 回滚的行算不算 | 典型误用 |
| --- | --- | --- | --- |
| `sqlite3_changes(db)` | **上一条语句**影响了几行 | — | 拿它统计「这次导入写了多少行」：它只看最后一条 |
| `total_changes(db)` | 这条连接打开以来累计 | **算**（回滚之后照涨） | 拿它判断「刚才那次有没有改到数据」：回滚了它也涨 |

上面第 8 行量的正是 `changes` 的粒度：`UPDATE` 一行都不命中，`rc` 还是 0，
而 `changes=1` 是**上一条 INSERT** 留下的旧值——`changes` 在语句失败/无命中时的行为
很容易被误读成「改到了 1 行」。DDL（建表、`PRAGMA`）也是 0。

最后是 `close` 的两种脾气，这是 Swift 里最容易泄漏的一处：

```
  留着没 finalize 的 stmt 去 close：rc=5 errmsg=unable to close due to unfinalized statements or unfinished backups
  同一个句柄改用 close_v2：rc=0（它答应「有未完成的语句也放行」，见 §11 CoreData 的收尾）
```

留着一个没 `finalize` 的 stmt 去 `sqlite3_close`，返回 **5（SQLITE_BUSY）**，库**没有被关**，
连接还在——这条路径是内存与文件句柄泄漏的经典来源，因为 Swift 侧的 `OpaquePointer`
**不走 ARC**，忘了 `finalize` 就是真忘了，没有任何 deinit 会替你收尾。
`sqlite3_close_v2` 则是「有未完成的语句也照样放行，等最后一个游标关掉时再真正释放」，
所以本节的第二次调用返回 0。官方建议：新代码一律用 `close_v2`，
除非你确实需要「漏了 finalize」这件事以错误码的形式暴露出来（上面那两行就是让你看见差别）。
§11 会看到 CoreData 内部就是用 `close_v2` 收尾的——所以它从不因为漏了游标而报 5。

## 8) `sqlite3_exec` 的回调，和往 SQL 里塞一个 Swift 函数

`sqlite3_exec` 是「一次跑多条语句」的便捷壳：内部就是 prepare+step 循环，每出一行调一次回调。

```swift
var cbErr: UnsafeMutablePointer<CChar>?
let rc = sqlite3_exec(db, "SELECT id, name FROM s;", { p, n, cols, names in
    // (用户指针, 列数, 值数组, 列名数组) → 返回非 0 中止整个 exec
    return 0
}, Unmanaged.passUnretained(box).toOpaque(), &cbErr)
sqlite3_free(cbErr)   // 第 5 个参数是 SQLite malloc 出来的，必须自己释放
```

```
== 8) sqlite3_exec 的回调，和往 SQL 里塞一个 Swift 函数 ==
  exec 带 callback：rc=0 回调次数=2 每行收到的列数=[2, 2]
  第 1 次回调：列名=id,name 值=1,甲
  回调返回 7（非 0）：rc=4 表里本来有 2 行，回调只被叫了 1 次
  exec 里第二条坏：rc=1 第 5 个参数给='near "SELEKT": syntax error'，db 的 errmsg='near "SELEKT": syntax error'
  sqlite3_create_function("mylen", argc=1) rc=0（第三个参数 SQLITE_ANY=5 在头文件里注释成 Deprecated，所以给 SQLITE_UTF8=1）
  在 SQL 里当普通函数用：mylen('hi')=2 mylen(12345)=5 mylen('中文')=6 typeof(mylen('hi'))=integer
  参数是 NULL：mylen(NULL) 用 column_text 读=<NULL>（result_null → text 指针是 NULL）
  参数个数不对：prepare 'SELECT mylen()' rc=1 errmsg=wrong number of arguments to function mylen()
  多给一个参数：rc=1 errmsg=wrong number of arguments to function mylen()（注册时 argc 写死，问不出来）
  ok   sqlite3_exec 是「一次跑多条语句」的便捷壳：它内部就是 prepare+step 循环，每出一行调一次回调，回调拿到 (用户指针, 列数, 值数组, 列名数组)，返回非 0 就**中止整个 exec**。注意回调里给的值是 C 字符串数组：NULL 列在回调里同样是 NULL 指针，所以 sp() 那个包装在这里也是必需品。错误信息有两份：exec 的第五个参数（要自己 sqlite3_free，否则泄漏）和 db 的 errmsg；本节让第二条语句坏，两份都非空但措辞一样，rc=1（ERROR）—— 第一条其实已经跑完并出了行。自定义函数是 SQLite 最有意思的一块：sqlite3_create_function 注册一个 @convention(c) 函数之后，SQL 里就能写 mylen(...)，而且它会**进到查询计划里**（WHERE 里也能用）。两个必须记住的限制：回调必须是**不捕获任何 Swift 上下文**的函数（本节的 sqlLen 只能读参数、写结果），参数个数在注册时就定死，写错个数是 prepare 期错误（上面那行 'wrong number of arguments to function mylen()'），而不是运行时才崩 —— 这跟 CoreData 的自定义 NSEntityDescription 校验完全不是一个路子。最后：sqlite3_value_text 对 NULL 参数给 NULL 指针，所以本节选择 result_null；如果像很多教程那样直接 strlen(t)，NULL 就会被当成某个长度算进去，得到一个说不清来源的数字。
```

四个要点：

**1) 回调返回非 0 就中止整个 exec**，并且 `exec` 本身返回那个非 0 值（上面 `rc=4` 那行给的是
`SQLITE_ABORT`）。表里有 2 行、回调只被叫了 1 次就是这个中止的样子——它不是 bug，是取消机制。

**2) 回调拿到的是 C 字符串数组，NULL 列同样是 NULL 指针。** 所以 §2 那个 `sp()` 包装在这里
是必需品：`String(cString:)` 直接解包会在 NULL 列上崩。列名数组只在第一行给（DDL/失败时为 NULL）。

**3) 错误信息有两份。** 第 5 个参数（要自己 `sqlite3_free`，否则泄漏）和 db 的 `errmsg`。
本节让第二条语句坏，两份都非空、措辞一样，`rc=1`（ERROR）——**第一条其实已经跑完并出了行**。
这就是「exec 中途失败时数据库处于什么状态」的答案：在 autocommit 下，前面的语句**已经生效**。
多条语句要么自己包 `BEGIN … COMMIT`，要么别指望 exec 是原子的。

**4) 自定义函数是 SQLite 最有意思的一块。** 注册一个 `@convention(c)` 函数之后，
SQL 里就能像普通函数一样调它，而且它会**进到查询计划里**（`WHERE` 里也能用）：

```swift
func sqlLen(_ ctx: OpaquePointer?, _ argc: Int32, _ argv: UnsafeMutablePointer<OpaquePointer?>?) {
    guard argc == 1, let v = argv?[0], sqlite3_value_type(v) != SQLITE_NULL else {
        sqlite3_result_null(ctx); return
    }
    sqlite3_result_int(ctx, sqlite3_value_bytes(v))
}
let rcCreate = sqlite3_create_function(db, "mylen", 1, SQLITE_UTF8, nil, sqlLen, nil, nil)
// SELECT mylen('hi') → 2
```

两个必须记住的限制。**其一，回调必须是不捕获任何 Swift 上下文的函数**——
`@convention(c)` 的闭包不能捕获任何东西（要带状态就通过第 5 个用户指针传
`Unmanaged`，像上面 exec 回调那样）。想在一个 SQL 自定义函数里访问 Swift 对象的属性，
这一层就直接给你划了边界。**其二，参数个数在注册时定死**（第三个参数 `argc`），
写错个数是 **prepare 期错误**：`wrong number of arguments to function mylen()`——
而不是运行时才崩，这跟 CoreData 的自定义实体校验（§12 的 1600、§16 的 1570）完全不是一个路子。

第四个参数 `eTextRep` 这里给 `SQLITE_UTF8`（1）。`SQLITE_ANY`（5）在头文件里被注释成
Deprecated，别用；`SQLITE_UTF16LE/BIG` 只在你确实处理 UTF-16 文本时才需要。
最后一个细节是 NULL 处理：`sqlite3_value_text` 对 NULL 参数给 NULL 指针，
所以本节选择 `result_null`。如果像很多教程那样直接 `strlen(t)`，
NULL 就会被当成某个长度算进去，得到一个说不清来源的数字——
和 §4 那条「没绑的槽位静默变 NULL」是同一类事故的另一半。

## 9) CoreData 的程序化模型：出厂值比想象中多

从这一节起换一层。CoreData 与 SQLite 最大的差别就此成立：**它不看你的字符串，它看对象**。
本章不用 `.xcdatamodeld`、不用 codegen 出来的子类，模型全部代码构造，两个实体互指：

```
Note   { title: String?  (可选)      stars: Int32 (必填)  author → Author (to-one)  }
Author { name: String?   (可选)                              notes  → [Note] (to-many) }
```

```swift
func attr(_ name: String, _ type: NSAttributeType, _ optional: Bool) -> NSAttributeDescription {
    let a = NSAttributeDescription()
    a.name = name; a.attributeType = type; a.isOptional = optional
    return a
}
func rel(_ name: String, _ dest: NSEntityDescription, toMany: Bool, rule: NSDeleteRule) -> NSRelationshipDescription {
    let r = NSRelationshipDescription()
    r.name = name; r.destinationEntity = dest
    r.minCount = 0; r.maxCount = toMany ? 0 : 1   // maxCount = 0 表示「不限个数」
    r.deleteRule = rule
    return r
}
```

`maxCount = 0` 是 to-many 的写法（不是「0 个」），`minCount = 0` 是「可以没有」——
这两个数是后面所有删除规则讨论的前提。读写值一律 KVC：`obj.setValue(5, forKey: "stars")` /
`obj.value(forKey: "stars")`，没有子类就没有编译期检查，这也是本章故意选的：
属性名写错的时候 CoreData 怎么说话，本身就是要量的东西。

```
== 9) CoreData 的程序化模型：出厂值比想象中多 ==
  model.entities 声明顺序=["Note", "Author"] 而 entitiesByName 的键=["Author", "Note"]
  Note.managedObjectClassName=Optional("NSManagedObject") isAbstract=false 属性数=3 父实体=nil
  NSAttributeType 的 rawValue（一百一档）：undefined=0 integer16=100 integer32=200 integer64=300
  …decimal=400 double=500 float=600 string=700 boolean=800 date=900
  …binaryData=1000 UUID=1100 URI=1200 transformable=1800 objectID=2000 composite=2100
  刚 new 出来、什么都没设的 NSAttributeDescription：attributeType=200 isOptional=true isTransient=false defaultValue=nil
  …attributeValueClassName=Optional("NSNumber") versionHash 字节数=32 userInfo 键=[]
  刚 new 出来的 NSRelationshipDescription：deleteRule=1（**不是 0**）isOptional=true minCount=0 maxCount=0 inverse=nil
  NSDeleteRule 四档 rawValue：noAction=0 nullify=1 cascade=2 deny=3
  ok   CoreData 这一层和 SQLite 最大的差别从这里开始：**它不看你的字符串，它看对象**。本节的模型是纯代码构造的（没有 .xcdatamodeld、没有 NSManagedObject 子类，全部用 NSManagedObject + setValue(forKey:)），这样本章每个数字都能自己跑出来给你看。几个出厂值必须记，因为它们跟直觉不合：NSAttributeType 的 rawValue 是**一百一档**（string=700、integer32=200、date=900、transformable=1800），不是从 0 连排的序号，所以拿 rawValue 当数组下标、或者存进自己的设置里再猜含义，一定会猜错；新 new 的属性默认是 integer32（不是 undefined）、isOptional=true、attributeValueClassName 是 NSNumber（只有字符串属性才会变成 NSString），versionHash 是 32 字节 —— 就是 §14 那两个迁移错误 userInfo 里的 NSStoreModelVersionHashes。最反直觉的是关系：**新关系的 deleteRule 默认是 nullify(1)**，不是 noAction(0) —— 也就是说你忘写删除规则时，CoreData 会把关系断开而不是留下悬空引用（§12 用四种规则各跑一遍，看它们在 SQL 层分别做了什么）。还有一个只在代码构造模型时才会撞到的坑：关系**必须**被塞进 entity.properties 里，只给 inverseRelationship 和 destinationEntity 是不够的 —— 探针里直接对没进 properties 的关系调 setValue(forKey:"author")，得到的是 NSUnknownKeyException（"this class is not key value coding-compliant for the key author."）+ signal 6，而报错的对象类名是 NSManagedObject 本身，看起来像是 KVC 用错了字段，其实是模型没装配完整。
```

几个出厂值必须记，因为它们跟直觉不合：

**1) `NSAttributeType` 的 rawValue 是「一百一档」，不是连排序号。**

| 档位 | rawValue | 档位 | rawValue |
| --- | --- | --- | --- |
| `undefined` | 0 | `string` | 700 |
| `integer16` | 100 | `boolean` | 800 |
| `integer32` | 200 | `date` | 900 |
| `integer64` | 300 | `binaryData` | 1000 |
| `decimal` | 400 | `UUID` | 1100 |
| `double` | 500 | `URI` | 1200 |
| `float` | 600 | `transformable` | 1800 |
|  |  | `objectID` | 2000 |
|  |  | `composite` | 2100 |

拿 rawValue 当数组下标、或者把它存进自己的设置里再猜含义，一定会猜错；
而 §15 里 `expressionResultType` 用的正是这套编码。

**2) 新 new 出来的属性默认是 `integer32`（不是 undefined）、`isOptional=true`、
`attributeValueClassName` 是 `NSNumber`**（只有字符串属性才会变成 `NSString`）、
`isTransient=false`、`defaultValue=nil`。`versionHash` 是 32 字节——
就是 §14 那两个迁移错误 userInfo 里那份模型指纹的来源，`userInfo` 出厂是空字典。

**3) 最反直觉的在关系上：`deleteRule` 默认是 `nullify`(1)，不是 `noAction`(0)。**

| 规则 | rawValue | 删父对象时子对象怎么办 |
| --- | --- | --- |
| `noActionDeleteRule` | 0 | **什么都不做**——留下指着已删除行的键（不是 RESTRICT！） |
| `nullifyDeleteRule` | **1（出厂值）** | 把子行的外键列置空，行留着 |
| `cascadeDeleteRule` | 2 | 子行一起删 |
| `denyDeleteRule` | 3 | 拒绝保存，抛校验错误 |

也就是说你**忘写**删除规则时，CoreData 会把关系断开而不是留下悬空引用——一个偏保守的默认值。
§12 会把这四档各自在 SQL 层生成的后果逐一量出来。

**4) 代码构造模型独有的装配坑：关系必须被塞进 `entity.properties`。**
只给 `inverseRelationship` 和 `destinationEntity` 是不够的。探针里对一个没进 `properties` 的关系
调 `setValue(forKey: "author")`，得到的是 `NSUnknownKeyException`
（`this class is not key value coding-compliant for the key author.`）+ signal 6，
而报错的类名是 `NSManagedObject` 本身——看起来像 KVC 用错了字段，其实是模型没装配完整。
用 Xcode 模型编辑器时不会遇到这条，因为它自动帮你装配。

最后一条关于顺序的伏笔：本示例故意把 `Note` 放在 `entities` 数组第一位，
而 `entitiesByName` 的键是排好序的 `["Author", "Note"]`——这个不一致在 §11 兑现成
`Z_ENT` 的编号规则。

## 10) 容器与 store 描述：谁替你填了哪些默认值

`NSPersistentContainer` 是 CoreData 的装配厂：给它一个模型，它给你
「协调器 + store 描述 + viewContext」。这一节把它**替你填的东西**摊开，
因为后面 §14 的迁移、§16 的批量请求，行为都由这些默认值决定。

```swift
let c = NSPersistentContainer(name: "c26", managedObjectModel: model)
let d = NSPersistentStoreDescription(url: url)     // url 在临时目录，本章不打印它
c.persistentStoreDescriptions = [d]
c.loadPersistentStores { _, err in /* 自己从 err 取 domain/code */ }
```

```
== 10) 容器与 store 描述：谁替你填了哪些默认值 ==
  工厂容器自带的描述：count=1 type=SQLite url 有值=true url 末段=c26-bare.sqlite
  迁移两开关：shouldMigrateStoreAutomatically=true shouldInferMappingModelAutomatically=true shouldAddStoreAsynchronously=false
  其它出厂值：timeout=240.0 configuration=nil isReadOnly=false options 键=["NSInferMappingModelAutomaticallyOption", "NSMigratePersistentStoresAutomaticallyOption"] sqlitePragmas 键=[]
  NSPersistentStoreDescription() **无参**构造：type=SQLite url=/dev/null（不是 nil，是 /dev/null）
  内存库 loadPersistentStores：domain=nil（没出错） 回调给的 type=InMemory 实际 store 数=1 换型之后原描述还有 url=true
  isReadOnly=true 打开**不存在**的文件：domain=NSCocoaErrorDomain code=260 userInfo键=["reason"] store 数=0
  isReadOnly=true 打开**已存在**的库：domain=nil（没出错） store 数=1 读得到=Optional(1) 条
  在只读 store 上新增一行再保存：domain=NSCocoaErrorDomain code=513 userInfo键=["NSPersistentStoreOptions", "reason", "storeURL"] 上下文 hasChanges=true
  ok   NSPersistentContainer 的价值全在「它替你填了默认值」，这一节把填的东西摊开。工厂方法给的那一条描述 type 是 SQLite、url 指向 Application Support 下同名文件（本示例的模型没有对应文件，所以只看末段名字），**两个迁移开关默认都开着**（§14 就靠这一条解释：为什么加一列不写 mapping model 也能跑起来），shouldAddStoreAsynchronously 默认 false（同步加载，启动慢一点，但回调一定跑过）。options 出厂就有两个键，正是那两个迁移开关的另一副面孔（同一份设置的 dictionary 形式）；sqlitePragmas 出厂是空的，timeout 是 240 秒而不是「无穷」，configuration=nil 表示用默认配置名。一个坑：NSPersistentStoreDescription() 无参构造出来的对象**不是**「什么都没设」——它的 url 是 file:///dev/null，而 type 仍然报 SQLite（上面那行实测），也就是说这个默认值是「往 /dev/null 写一个 SQLite 库」；要真拿内存库必须显式设 type=NSInMemoryStoreType，反过来把 type 改成内存型之后 url 也照样有值 —— 所以判断「这是文件库还是内存库」只能看 type，不能看 url。还有 options 是**只读属性**，不能 desc.options[k] = v（cannot assign through subscript: 'options' is a get-only property），只有 setOption(_:forKey:) 和 setValue(_:forPragmaNamed:) 两个 setter，后者才是真正往 SQLite 下发 PRAGMA 的那一个（§11 现场对比两者的差别）。最后两条是 isReadOnly：它对**不存在**的文件是直接失败 —— NSCocoaErrorDomain code=260，userInfo 的 reason 写着 'Attempt to open missing file read only'（CoreData 不会替你创建，也不会退化成读写模式），store 数因此是 0；打开**已存在**的文件才成立，读得到数据，但一保存就报错，而且**失败的对象会留在上下文里**（上面 hasChanges 还是 true，跟 §12 的 deny 一模一样要 reset 才能继续）。顺带这一节的两次失败都用 quiet() 包了：CoreData 的失败日志会把整条绝对路径打到 stderr，而判定 3 要 stderr 为空、判定 4 要输出可复现（路径里有设备 UUID），所以错误信息由我们自己从 NSError 里取。
```

工厂容器自带的那一条描述，读回来的默认值是：

| 属性 | 出厂值 | 含义 |
| --- | --- | --- |
| `type` | `NSSQLiteStoreType` | 不显式改就是文件型 SQLite 库 |
| `url` | Application Support 下 `<容器名>.sqlite` | 容器名决定了文件名 |
| `shouldMigrateStoreAutomatically` | **true** | §14 那两个开关之一 |
| `shouldInferMappingModelAutomatically` | **true** | §14 的另一个开关 |
| `shouldAddStoreAsynchronously` | **false** | 同步加载：回调一定跑过才继续 |
| `timeout` | 240.0 秒 | 不是「无穷」 |
| `configuration` | nil | nil = 用默认配置名 |
| `isReadOnly` | false | 下面单测 |
| `options` | 含那两个迁移开关的键 | 开关的另一副面孔（dictionary 形式） |
| `sqlitePragmas` | 空 | 出厂**不下发任何 PRAGMA** |

三个具体的坑：

**1) `NSPersistentStoreDescription()` 无参构造出来的对象不是「什么都没设」**——
它的 url 是 `file:///dev/null`，而 type 仍然报 SQLite。也就是说这个默认值是
「往 /dev/null 写一个 SQLite 库」。要真拿内存库必须显式
`type = NSInMemoryStoreType`；反过来把 type 改成内存型之后 url 也照样有值。
**所以判断「这是文件库还是内存库」只能看 type，不能看 url。**

**2) `options` 是只读属性**，不能 `desc.options[k] = v`
（`cannot assign through subscript: 'options' is a get-only property`）。
只有两个 setter：`setOption(_:forKey:)` 和 `setValue(_:forPragmaNamed:)`，
后者才是真正往 SQLite 下发 PRAGMA 的那一个（§11 现场对比两者的差别）。

**3) `isReadOnly` 的两种失败长得很不一样。** 对**不存在**的文件开只读：直接失败，
`NSCocoaErrorDomain code=260`，userInfo 的 reason 写着
`Attempt to open missing file read only`——CoreData 不会替你创建，也不会退化成读写模式，
store 数因此是 0。打开**已存在**的库才成立，读得到数据，但一保存就报错：
`code=513`，userInfo 是 `NSPersistentStoreOptions/reason/storeURL`，
而且**失败的对象会留在上下文里**（上面 `hasChanges` 还是 true）——
跟 §12 的 deny 一模一样，必须 `reset()` 才能继续。这一条值得单独记住：
CoreData 的保存失败**普遍不会替你清理上下文**。

顺带说明本节的输出形态：两次失败都用 `quiet()` 包了，因为 CoreData 的失败日志会把整条绝对路径
打到 stderr，而判定 3 要 stderr 为空、判定 4 要输出可复现（路径里带设备 UUID），
错误信息由我们自己从 `NSError` 里取 `domain/code/userInfo键`。

## 11) 打开 CoreData 的库文件，用 SQLite 的眼睛看它

本节是全章的枢纽：CoreData 建好库、存了两条 Note 之后，
**用 `sqlite3_open` 直接开同一个文件**，把它的表结构一条条读出来。

```swift
let db = rawHandle(storeURL(c))       // 就是 sqlite3_open(url.path, &db)
dump(db, "SELECT type || ':' || name FROM sqlite_master ORDER BY name")
```

```
== 11) 打开 CoreData 的库文件，用 SQLite 的眼睛看它 ==
  两条 Note + 一条 Author：保存成功（第二条 Note 故意不给 title，它是可选的）
  sqlite_master 里全部条目：table:ZAUTHOR | table:ZNOTE | index:ZNOTE_ZAUTHOR_INDEX | table:Z_METADATA | table:Z_MODELCACHE | table:Z_PRIMARYKEY
  Z_PRIMARYKEY 建表语句：CREATE TABLE Z_PRIMARYKEY (Z_ENT INTEGER PRIMARY KEY, Z_NAME VARCHAR, Z_SUPER INTEGER, Z_MAX INTEGER)
  Z_PRIMARYKEY 内容（Z_ENT,Z_NAME,Z_SUPER,Z_MAX）：1,Author,0,1 | 2,Note,0,2
  ZNOTE 列明细（cid:name:type:notnull:dflt）：0:Z_PK:INTEGER:0:NULL | 1:Z_ENT:INTEGER:0:NULL | 2:Z_OPT:INTEGER:0:NULL | 3:ZSTARS:INTEGER:0:NULL | 4:ZAUTHOR:INTEGER:0:NULL | 5:ZTITLE:VARCHAR:0:NULL
  ZNOTE 的 Z_PK 序列=1 | 2（**哪条内容拿哪个号不保证**：探针连跑三次，同一段代码里 title=甲 的记录过 2 也拿过 1 —— CoreData 保存时按内部集合遍历取号，别把 Z_PK 当业务 ID）
  ZNOTE 内容按 ZSTARS 排序（Z_ENT,Z_OPT,ZAUTHOR 是否空,ZTITLE）：2,1,1,<NULL> | 2,1,0,甲
  建表语句里 FOREIGN KEY 出现的位置=0 而这条连接 PRAGMA foreign_keys=0
  ZNOTE 的建表语句原文：CREATE TABLE ZNOTE ( Z_PK INTEGER PRIMARY KEY, Z_ENT INTEGER, Z_OPT INTEGER, ZSTARS INTEGER, ZAUTHOR INTEGER, ZTITLE VARCHAR )
  连接级 PRAGMA：user_version=0 journal_mode=wal page_size=4096 encoding=UTF-8
  Z_METADATA 列=Z_VERSION:INTEGER | Z_UUID:VARCHAR(255) | Z_PLIST:BLOB 内容只打非空标记=1,1,1
  store 旁边的文件族：主文件=true -wal=true -shm=true
  wal_checkpoint(PASSIVE) 的 busy 位=0（只打第一列；帧数随页面布局变，本章不打印）
  setValue(_:forPragmaNamed:) 建的库，外部读 journal_mode=delete；setOption(_:forKey:) 建的=wal；给 truncate 的=delete
  ok   这一节把「CoreData 底下到底是什么」摊开，六件事一次讲完。第一，表名列名全部 Z 前缀，实体名大写（Note→ZNOTE、Author→ZAUTHOR），属性名直接大写当列名（ZSTARS/ZTITLE/ZAUTHOR），所以改属性名就等于改列名 —— 这正是 §14 迁移问题的来源。第二，除了你的两张表还有三张 CoreData 自己的账本：Z_PRIMARYKEY（每个实体一个 Z_MAX，记「这个实体用到过的最大主键」，新对象从这里取号；**取号的先后次序不保证** —— 探针连跑三次，同一段代码里两条 Note 的 Z_PK 会互换，所以 Z_PK 只能当内部主键，不能拿来当业务顺序或业务 ID）、Z_METADATA（模型版本哈希 + store UUID + plist）、Z_MODELCACHE（模型缓存，BLOB，判定 5 不许打内容）。第三，**Z_ENT 不是声明顺序**：本示例把 Note 写在 entities 数组第一位，但表里 Author=1、Note=2，因为 CoreData 按实体名**字母序**编号，建表顺序也跟着字母序。第四，也是最重要的一条：**ZNOTE 的建表语句里没有 FOREIGN KEY 子句**（instr 找那个词返回 0），关系只是 ZNOTE.ZAUTHOR 一个普通整数列，外加一条建在 (ZAUTHOR) 上的索引；而 PRAGMA foreign_keys 又正好是 0（§6）。所以「删父行会不会级联」SQLite 完全不知道，全是 CoreData 在删之前自己算好一批要一起删的行 —— §12 的四种删除规则因此是在**对象图层面**执行的。第五，journal_mode 是 wal（旁边就有 -wal/-shm 两个文件，上面用 fileExists 验过），user_version 是 0 —— CoreData 不用 SQLite 那个槽位，它自己的版本写在 Z_METADATA.Z_VERSION（§14）。第六，PRAGMA 的两条通道实测差别：setValue(_:forPragmaNamed:) 真的下发到 SQLite（外部读到 delete），setOption(_:forKey:) 只是塞进 CoreData 的 options 字典，键名不属于它认的那一份就完全不生效（外部还是 wal）；而 truncate / memory 这些值 SQLite 会接受但**不会记住**（重新打开读回来是 delete），journal_mode 只有 WAL/delete 这一档是持久的。
```

六件事一次讲完：

**1) 命名规则。** 表名列名全部 `Z` 前缀，实体名大写（`Note→ZNOTE`、`Author→ZAUTHOR`），
属性名直接大写当列名（`ZSTARS` / `ZTITLE` / `ZAUTHOR`）。三列是每个实体都有的固定列：
`Z_PK`（内部主键）、`Z_ENT`（实体编号）、`Z_OPT`（行版本号）。
**改属性名就等于改列名**——这正是 §14 那个「改名等于删数据」的来源。

**2) 三张 CoreData 自己的账本**（`sqlite_master` 里除了你的两张表和一条索引之外就是它们）：

| 表 | 作用 | 本章在哪节用到 |
| --- | --- | --- |
| `Z_PRIMARYKEY` | 每个实体一行，`Z_MAX` 记「这个实体用到过的最大主键」，新对象从这里取号 | §12（撞号）、§16（批量插入也走它） |
| `Z_METADATA` | `Z_VERSION` + `Z_UUID` + `Z_PLIST`（模型指纹） | §14（迁移靠它比对） |
| `Z_MODELCACHE` | 模型缓存，BLOB | 判定 5 不许打内容，只打「存在」 |

**3) `Z_ENT` 不是声明顺序，是字母序。** 本示例把 `Note` 写在 `entities` 数组第一位，
但表里 `Author=1、Note=2`——CoreData 按实体名**字母序**编号，建表顺序也跟着字母序。
而 `Z_PRIMARYKEY` 的建表语句是 `Z_ENT INTEGER PRIMARY KEY, Z_NAME, Z_SUPER, Z_MAX`，
其中 `Z_SUPER` 是给实体继承用的（本章没有继承，全程 0）。

**4) 最重要的一条：`ZNOTE` 的建表语句里没有 `FOREIGN KEY` 子句**（`instr` 找那个词返回 0），
而这条连接的 `PRAGMA foreign_keys` 又正好是 0（§6）。关系只是 `ZNOTE.ZAUTHOR` 一个普通整数列，
外加一条建在 `(ZAUTHOR)` 上的索引 `ZNOTE_ZAUTHOR_INDEX`。
**所以「删父行会不会级联」SQLite 完全不知道，全是 CoreData 在删之前自己算好一批要一起删的行**——
§12 的四种删除规则因此是在**对象图层面**执行的，不是数据库层面的约束。
索引说明 CoreData 确实会为「按关系查」优化：`WHERE ZAUTHOR=?` 是有索引可用的。

**5) `Z_PK` 的取号顺序不保证。** 上面第 7 行是探针连跑三次的结果：同一段代码里
`title=甲` 那条记录过 2 也拿过 1——CoreData 保存时按内部集合遍历取号。
所以 **`Z_PK` 只能当内部主键，不能拿来当业务顺序或业务 ID**。这条对 UI 影响很大：
「按插入顺序显示」必须靠一个真实的时间戳/序号属性，而不是 `Z_PK` 或 `objectID` 里的数字。

**6) journal 与版本槽位。** `journal_mode` 是 `wal`（旁边就有 `-wal`/`-shm` 两个文件，
上面用 `fileExists` 验过，内容不打）；`user_version` 是 **0**——CoreData 不用 SQLite 那个槽位，
它自己的版本写在 `Z_METADATA.Z_VERSION`（§14 会看到它全程是 1）。
`wal_checkpoint(PASSIVE)` 只打第一列（busy 位），因为帧数随页面布局变，不满足可复现判定。

最后一条是 PRAGMA 的两条通道，实测差别很实在：

```
  setValue(_:forPragmaNamed:) 建的库，外部读 journal_mode=delete；setOption(_:forKey:) 建的=wal；给 truncate 的=delete
```

`setValue(_:forPragmaNamed:)` 真的下发到 SQLite（外部读到 `delete`）；
`setOption(_:forKey:)` 只是塞进 CoreData 的 options 字典，键名不属于它认的那一份就**完全不生效**
（外部还是 `wal`）。而 `truncate` / `memory` 这些值 SQLite 会接受但**不会记住**
（重新打开读回来是 `delete`）——`journal_mode` 只有 WAL/delete 这一档是持久的，
因为它记在文件里（WAL 模式还会留 `-wal`/`-shm`）。这就是「设了 PRAGMA 为什么没生效」的标准答案：
先分清你走的是哪条通道，再问 SQLite 记不记得。

## 12) 四种删除规则在 SQL 层各做了什么，和绕开 CoreData 直接改表的四笔账

§11 已经量到 `ZNOTE` 没有 `FOREIGN KEY` 子句、`foreign_keys` 又是 0，
所以「删父行会怎样」SQLite 一概不知，全是 CoreData 在 `save` 时按模型里的删除规则自己生成 SQL。
这一节把四档规则各自的 SQL 后果摊开。每个用例都建同一份数据：1 个 Author 挂 2 条 Note，
然后删那个 Author、存盘，再用裸 SQL 数四件事：

```swift
func shape(_ db: OpaquePointer?) -> String {   // 本节每一行输出里那段「父行=… 子行=…」的来源
    "父行=\(scalar(db, "SELECT count(*) FROM ZAUTHOR"))"
  + " 子行=\(scalar(db, "SELECT count(*) FROM ZNOTE"))"
  + " 子的父键为空=\(scalar(db, "SELECT count(*) FROM ZNOTE WHERE ZAUTHOR IS NULL"))"
  + " 真悬空=\(scalar(db, "SELECT count(*) FROM ZNOTE WHERE ZAUTHOR IS NOT NULL"
                     + " AND ZAUTHOR NOT IN (SELECT Z_PK FROM ZAUTHOR)"))"
  + …
}
```

`真悬空` 那一列的写法本身就是本节最后那个坑的解法，放到最后讲。

### A/B：四档规则各写了什么样的 SQL

```
== 12) 四种删除规则在 SQL 层各做了什么，和绕开 CoreData 直接改表 ==
  -- 删父对象 Author，两侧规则都是 noAction(0) --
    删之前：父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2
    删+存：保存成功  删之后：父行=0 子行=2 子的父键为空=0 真悬空=2 NOT IN 裸写法=2 Z_MAX(按字母序)=Author=1 | Note=2
    从不读 notes 关系，只删父：保存成功  表=父行=0 子行=2 子的父键为空=0 真悬空=2 NOT IN 裸写法=2 Z_MAX(按字母序)=Author=1 | Note=2
  -- 删父对象 Author，两侧规则都是 nullify(1) --
    删之前：父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2
    删+存：保存成功  删之后：父行=0 子行=2 子的父键为空=2 真悬空=0 NOT IN 裸写法=2 Z_MAX(按字母序)=Author=1 | Note=2
    从不读 notes 关系，只删父：保存成功  表=父行=0 子行=2 子的父键为空=2 真悬空=0 NOT IN 裸写法=2 Z_MAX(按字母序)=Author=1 | Note=2
  -- 删父对象 Author，两侧规则都是 cascade(2) --
    删之前：父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2
    删+存：保存成功  删之后：父行=0 子行=0 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2
    从不读 notes 关系，只删父：保存成功  表=父行=0 子行=0 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2
```

四档各自的后果，逐条对着上面的数字看：

- **`noAction` 不是 RESTRICT**。它只删父行，子行留着，`ZAUTHOR` 还指着已经不存在的 `Z_PK`
  （`真悬空=2`）。SQLite 不报错、CoreData 也不报错，数据就此烂掉。
  想要「拦住」得用 `deny`，想要「留个洞」才是 `nullify`——这三个名字在 SQL 语境里的含义
  和 CoreData 里的完全不同，`noAction` 尤其容易按字面理解成「不许动」。
- **`nullify` 把子行的键置空**（`子的父键为空=2`，行都还在）。这也是 §9 量的出厂值。
- **`cascade` 把子行一起删干净**（`子行=0`），而且**跟你有没有遍历过关系无关**：
  上面每一档都跑了两遍，第二遍只 fetch 父对象、从不去读 `author`/`notes`，结果一样——
  CoreData 是自己在 SQL 层查了那批子行的（`DELETE FROM ZNOTE WHERE ZAUTHOR IN (…)` 这类）。
  这条很重要：它意味着**删一个挂了十万子对象的父对象不会先把十万个对象读进内存**。
- **`deny` 不写任何东西**：`save` 抛 `NSCocoaErrorDomain code=1600`，userInfo 的键是
  `NSValidationErrorObject/Key/Value` 那一族。注意它是**校验错误，不是 SQL 错误**——
  domain 不是 `NSSQLiteErrorDomain`，表里父行子行一个没少。

然后是**最容易栽的半步**：deny 失败之后上下文并不干净。

```
  -- 删父对象 Author，两侧规则都是 deny(3) --
    删之前：父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2
    删+存：抛出 domain=NSCocoaErrorDomain code=1600 userInfo键=["NSLocalizedDescription", "NSValidationErrorKey", "NSValidationErrorObject", "NSValidationErrorShouldAttemptRecoveryKey", "NSValidationErrorValue"]  删之后：父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2
    失败之后上下文没干净：hasChanges=true deletedObjects=1
    不 reset 直接再存一次：抛出 domain=NSCocoaErrorDomain code=1600 userInfo键=["NSLocalizedDescription", "NSValidationErrorKey", "NSValidationErrorObject", "NSValidationErrorShouldAttemptRecoveryKey", "NSValidationErrorValue"]
    reset 之后 hasChanges=false，再存：保存成功  表=父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2
    父对象还在库里吗（同上下文 fetch 数）=Optional(1)
    从不读 notes 关系，只删父：抛出 domain=NSCocoaErrorDomain code=1600 userInfo键=["NSLocalizedDescription", "NSValidationErrorKey", "NSValidationErrorObject", "NSValidationErrorShouldAttemptRecoveryKey", "NSValidationErrorValue"]  表=父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2

```

`hasChanges` 还是 true、`deletedObjects` 还是 1，紧接着再 save 会**再抛一次同样的错**；
必须先 `reset()`（或 `discardChanges()`）。上面 `reset` 之后那句「保存成功」是一次**空保存**——
父对象还在库里（fetch 数=1），不是「第二次删成功了」。
这一条是所有 CoreData 保存失败的通则：**失败不会替你回滚上下文的登记簿**。

### 删子对象那一半：规则是双向传播的

```
  -- 反过来删子对象 Note，只把 to-one 侧 Note.author 设成 cascade(2)（Author.notes 固定 nullify）--
    删之前：父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2  删+存：保存成功  删之后：父行=0 子行=1 子的父键为空=1 真悬空=0 NOT IN 裸写法=1 Z_MAX(按字母序)=Author=1 | Note=2
  -- 反过来删子对象 Note，只把 to-one 侧 Note.author 设成 deny(3)（Author.notes 固定 nullify）--
    删之前：父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2  删+存：抛出 domain=NSCocoaErrorDomain code=1600 userInfo键=["NSLocalizedDescription", "NSValidationErrorKey", "NSValidationErrorObject", "NSValidationErrorShouldAttemptRecoveryKey", "NSValidationErrorValue"]  删之后：父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2
  ok   §11 已经量到 ZNOTE 的建表语句里没有 FOREIGN KEY 子句、PRAGMA foreign_keys 又是 0，所以「删父行会怎样」SQLite 一概不知，全是 CoreData 在 save 时按模型里的删除规则自己生成 SQL —— 这一节把四档规则各自的 SQL 后果摊开（上面每一行都是真跑出来的）。**noAction 不是 RESTRICT**：它只删父行，子行留着，ZAUTHOR 还指着已经不存在的 Z_PK（上面「真悬空=2」），SQLite 不报错、CoreData 也不报错，数据就此烂掉 —— 想要「拦住」得用 deny，想要「留个洞」才是 nullify。**nullify 把子行的键置空**（子的父键为空=2），行都还在；这也是 §9 量的出厂值（新关系默认 nullify=1）。**cascade 把子行一起删干净**（子行=0），而且**跟你有没有遍历过关系无关**：上面第二段同一规则、只 fetch 父对象、从不去读 author/notes，结果一样 —— CoreData 是自己在 SQL 层查了那批子行的。**deny 不写任何东西**：save 抛 NSCocoaErrorDomain code=1600，userInfo 的键是 NSValidationErrorObject/Key/Value 那一族（它是**校验错误**，不是 SQL 错误 —— 所以 domain 不是 NSSQLiteErrorDomain），表里父行子行一个没少。然后是最容易栽的半步：deny 失败之后**上下文并不干净**（hasChanges 还是 true、deletedObjects 还是 1），紧接着再 save 会**再抛一次同样的错**；必须先 `reset()`（或 discardChanges），上面 reset 之后那句「保存成功」是一次空保存 —— 父对象还在库里（fetch 数=1），不是「第二次删成功了」。删子对象那一半更值得记：把 to-one 侧 Note.author 设成 cascade，删**一条 Note** 会**把它的 Author 也删掉**（父行=0），然后 Author 自己那条 nullify 规则接着在**另一条 Note** 上生效（子的父键为空=1）—— 删除规则是沿对象图双向传播的，两侧互相影响，最后写成什么样的 SQL 取决于两侧的规则，而不取决于你觉得「谁是父」。同理，to-one 侧设成 deny，那么**任何挂在父对象上的子对象都删不掉**（上面第二次 1600），这是很常见的「我明明只删一条，为什么保存总失败」。
```

把 to-one 侧 `Note.author` 设成 `cascade`，删**一条 Note** 会**把它的 Author 也删掉**（`父行=0`），
然后 Author 自己那条 `nullify` 规则接着在**另一条 Note** 上生效（`子的父键为空=1`）。
**删除规则是沿对象图双向传播的，两侧互相影响**，最后写成什么样的 SQL 取决于两侧的规则，
而不取决于你觉得「谁是父」。同理，to-one 侧设成 `deny`，
那么**任何挂在父对象上的子对象都删不掉**（上面第二次 1600）——
这是很常见的「我明明只删一条，为什么保存总失败」的真实成因。
写关系时的实践结论：先想清楚**两侧各自**的规则，再决定删哪一端。

### C：用 C API 直接读写 CoreData 的表

这是本章最想让所有人看到的一段。同一个文件，`sqlite3_open` 开进去，直接写 CoreData 的表：

```
  -- C) 用 C API 直接读写 CoreData 的表 --
    起点：t1 的 Z_OPT=1 stars=1 | t2 的 Z_OPT=1 stars=2  Z_PK 集合=1 | 2  父行=1 子行=2 子的父键为空=0 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=2
    CoreData 改 stars=1 那条为 50 并存盘：t1 的 Z_OPT=2 stars=50 | t2 的 Z_OPT=1 stars=2
    手工 UPDATE t2 的 stars=99（没碰 Z_OPT）：t1 的 Z_OPT=2 stars=50 | t2 的 Z_OPT=1 stars=99
    手工 INSERT 占住 3 号（Z_MAX 仍是 2）：raw3 的 Z_OPT=1 stars=42 | t1 的 Z_OPT=2 stars=50 | t2 的 Z_OPT=1 stars=99  Z_PK 集合=1 | 2 | 3
    老上下文（它只认识 2 条）count(for:)=3  fetch 到的标题=raw3,t1,t2
    新上下文 count=3（同一条 SQL，只是换了个上下文）
    让 CoreData 自己新增一条（它从 Z_MAX+1 取号，而 3 号已被手工占掉）：抛出 domain=NSCocoaErrorDomain code=133020 userInfo键=["NSExceptionOmitCallstacks", "conflictList"]
    失败之后账本自己动了：父行=1 子行=3 子的父键为空=1 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=3  Z_PK 集合=1 | 2 | 3
    手工把 Z_MAX 抬到 9 再新增：保存成功  Z_PK 集合=1 | 2 | 3 | 10  父行=1 子行=4 子的父键为空=2 真悬空=0 NOT IN 裸写法=0 Z_MAX(按字母序)=Author=1 | Note=10
    两条手工 INSERT 的 rc：Z_ENT=99 那条=0（errmsg=not an error），不给 Z_OPT 那条=0（errmsg=not an error）
    再手工插两行：一行 Z_ENT=99（这个实体编号根本不存在）、一行不给 Z_OPT：表里 6 行，CoreData 的 count(for:)=6  新行的 Z_OPT=NULL
    CoreData 眼里这两行的内容：badEnt:99:1 | noOpt:2:NULL
  ok   C 这一半讲「绕开 CoreData 直接写它的表」要付的四笔账，每一条都是上面真跑出来的。**第一笔：Z_OPT 是 CoreData 的行版本号，只有它自己会维护**。CoreData 改一条并存盘，那行 Z_OPT 从 1 变 2；同一条 SQL 手工 UPDATE 别的列，Z_OPT 纹丝不动（t2 一直是 1）。它不是时间戳，是「这行被 CoreData 存过几次」的计数，用来做 §13 的变更判断和冲突检测；手工插的行给 1 能用（上面 raw3 之后所有查询都正常），干脆不给也能读出来（noOpt 那行 Z_OPT=NULL 照样被 count 到），但那意味着这一行没有版本号可用 —— 属于「别这么干」，不是「没事」。**第二笔：外部写的行 CoreData 立刻看得见**，不用重开 store —— 老上下文 count(for:)=3、fetch 也把 raw3 取了回来，因为 count/fetch 每次都要跑一遍 SQL；反过来说，**它不会通知你这个上下文里已经存在的对象被别人改了**（§13、§17）。**第三笔：取号只看 Z_PRIMARYKEY.Z_MAX，不扫表**。CoreData 新增对象拿的是 Z_MAX+1（这里是 3），而 3 号已经被手工行占了 → save 抛 NSCocoaErrorDomain code=133020，userInfo 键是 conflictList（冲突清单）和 NSExceptionOmitCallstacks。更麻烦的是**这次失败并不回滚账本**：Z_MAX 已经被推到 3（号先预定再插），所以后面把 Z_MAX 抬到 9 再新增，拿到的是 10 而不是 4。手工写它的表就必须**同时**维护这张表（UPDATE Z_PRIMARYKEY SET Z_MAX=(SELECT max(Z_PK) FROM ZNOTE) 之类），或者干脆用 §16 的批量请求走 CoreData 自己的通道。**第四笔：Z_ENT 不是查询条件**。插一行 Z_ENT=99（模型里根本没有这个实体号），Note 的 count(for:) 仍然是 6 行全算、fetch 也把它当 Note 读出来 —— 这个版本的 CoreData 对没有子实体的实体就是 `SELECT … FROM ZNOTE`，不加 Z_ENT 过滤。所以「行藏在别的实体号下面」这种事不会发生，Z_ENT 只在实体继承（Z_SUPER 那条链）时才有意义；有继承时查询会怎么加条件本章没测，留给诚实边界。最后一个小坑，是数悬空行时踩的：nullify 那一档里「子的父键为空=2」但**裸写 `ZAUTHOR NOT IN (SELECT Z_PK FROM ZAUTHOR)` 也数到 2** ——父表已经空了，`NULL NOT IN (空集合)` 在 SQLite 里为真，于是把刚被置空的行也算成悬空。查孤儿一定要写成 `ZAUTHOR IS NOT NULL AND ZAUTHOR NOT IN (…)`，上面两个数分别是 0 和 2 就是这个差。
```

四笔账，每一笔都是上面真跑出来的：

**第一笔：`Z_OPT` 是 CoreData 的行版本号，只有它自己会维护。**
CoreData 改一条并存盘，那行 `Z_OPT` 从 1 变 2；同一条 SQL 手工 UPDATE 别的列，`Z_OPT` 纹丝不动。
它不是时间戳，是「这行被 CoreData 存过几次」的计数，用来做 §13 的变更判断和冲突检测。
手工插的行给 1 能用（`raw3` 之后所有查询都正常），干脆不给也能读出来（`noOpt` 那行 `Z_OPT=NULL`
照样被 `count(for:)` 数到），但那意味着这一行没有版本号可用——属于「别这么干」，不是「没事」。

**第二笔：外部写的行 CoreData 立刻看得见**，不用重开 store——老上下文 `count(for:)=3`、
fetch 也把 `raw3` 取了回来，因为 `count`/`fetch` 每次都要跑一遍 SQL。
反过来说，**它不会通知你这个上下文里已经存在的对象被别人改了**（§13、§16 各撞一次）。

**第三笔：取号只看 `Z_PRIMARYKEY.Z_MAX`，不扫表。** CoreData 新增对象拿的是 `Z_MAX+1`（这里是 3），
而 3 号已经被手工行占了 → `save` 抛 `NSCocoaErrorDomain code=133020`，
userInfo 键是 `conflictList`（冲突清单）和 `NSExceptionOmitCallstacks`。
更麻烦的是**这次失败并不回滚账本**：`Z_MAX` 已经被推到 3（号先预定再插），
所以后面把 `Z_MAX` 抬到 9 再新增，拿到的是 **10** 而不是 4。
手工写它的表就必须**同时**维护这张表
（`UPDATE Z_PRIMARYKEY SET Z_MAX=(SELECT max(Z_PK) FROM ZNOTE WHERE Z_ENT=…)` 之类），
或者干脆用 §16 的批量请求走 CoreData 自己的通道。

**第四笔：`Z_ENT` 不是查询条件。** 插一行 `Z_ENT=99`（模型里根本没有这个实体号），
Note 的 `count(for:)` 仍然是 6 行全算、fetch 也把它当 Note 读出来——
这个版本的 CoreData 对没有子实体的实体就是 `SELECT … FROM ZNOTE`，不加 `Z_ENT` 过滤。
所以「行藏在别的实体号下面」这种事不会发生，`Z_ENT` 只在实体继承（`Z_SUPER` 那条链）时才有意义；
有继承时查询会怎么加条件本章没测，留给诚实边界。

最后一个小坑，是数悬空行时踩的：`nullify` 那一档里「子的父键为空=2」，
而**裸写 `ZAUTHOR NOT IN (SELECT Z_PK FROM ZAUTHOR)` 也数到 2**——父表已经空了，
`NULL NOT IN (空集合)` 在 SQLite 里为真，于是把刚被置空的行也算成悬空。
查孤儿一定要写成 `ZAUTHOR IS NOT NULL AND ZAUTHOR NOT IN (…)`，
上面那两个数分别是 0 和 2 就是这个差。这是 SQL 三值逻辑（TRUE/FALSE/UNKNOWN）
在最常见的一句查询里的现场表现，值得抄下来。

## 13) 对象的身份：objectID 的三段身份、fault 的不可预测、第二个上下文看什么

CoreData 里「一个对象是谁」由 `NSManagedObjectID` 决定，而它有三段身份：

```
临时 ID：x-coredata:///Note/t<内部序号>      insert 之后、拿到永久号之前
永久 ID：x-coredata://<store-UUID>/Note/p<Z_PK>   obtain 或 save 之后
```

```swift
let ob = NSManagedObject(entity: eNote, insertInto: ctx)     // 刚 insert
ob.objectID.isTemporaryID          // true；uri 的 host 是 nil；路径段数 3；末段以 t 开头
try ctx.obtainPermanentIDs(for: [ob])   // 不存盘也能提前换号
ob.objectID.isTemporaryID          // false；host 立刻变成长 36 的 store UUID；末段以 p 开头
```

```
== 13) 对象的身份：objectID、fault、以及第二个上下文 ==
  viewContext 出厂：concurrencyType=2 parent=nil 有 coordinator=true automaticallyMergesChangesFromParent=false includesPendingChanges 默认=true mergePolicy 实际类型=NSMergePolicy 能收成 NSMergePolicy 吗=true mergeType raw=0 undoManager 有吗=false
  刚 insert、还没存：isTemporaryID=true uri.scheme=x-coredata host 有没有=false 路径段数=3 末段首字符=t entity 名=Note
  这时拿它的 objectID 去 existingObject(with:)：拿到了
  没 save 就 obtainPermanentIDs(for:)：成功 isTemporaryID=false host 长度=36 末段首字符=p objectID 的 KVO 触发次数=0
  存盘之后：isTemporaryID=false uri 变成 scheme=x-coredata host 长度=36 路径段数=3 末段首字符=p KVO 累计=0
  拿永久 ID 反查对象：跟原来同一个实例吗=true 标题=idx
  拿 store 描述里另一个 URL 的容器反查同一个 ID：抛出 domain=NSCocoaErrorDomain code=133000 userInfo键=["objectID"]

```

四个坑按代价从低到高排：

**1) 没存盘也能 `existingObject(with:)` 拿到对象。** 别指望这个调用帮你校验「存过没有」。

**2) 拿这个 ID 去另一个容器（另一个 store）反查会抛 `code=133000`，userInfo 只有 `objectID` 一个键。**
ID 里的 host 就是 store 的 UUID，所以 **objectID 只在同一个 store 内有意义**，
不能当跨环境的主键存进设置、URL 或后端。而且这条 URI 形状本身也不稳定：
`p` 后面的数字是 `Z_PK`，而 §11 已经量到 CoreData 给谁分配几号不保证。

**3) KVO 听不到 objectID 变化。** 上面用 KVO 盯 `objectID` 这个键，
临时 → 永久那一次切换全程触发 **0 次**。头文件里能 grep 到的公开通知只有上下文那五个
（`WillSave` / `DidSave` / `ObjectsDidChange` / `DidSaveObjectIDs` / `DidMergeChangesObjectIDs`），
这一版 SDK 根本没有 objectID 变化的通知。想在新建对象上拿到永久 ID，只能在 `save` 之后重新读
`objectID`。（顺带：`automaticallyMergesChangesFromParent` 出厂是 false，`undoManager` 出厂是 nil，
`mergePolicy` 的实际类型就是 `NSMergePolicy` 本身——这几条是后面所有「为什么没自动更新」的前提。）

**4) fault 不是你能预测的开关。** 这是本节最长的一段实测：

```
  -- fault：什么时候才真的去查库 --
    库里有 3 条 Note：行数=3 Z_MAX=3
    fetch 回来 3 条，立刻看 isFault=TTT
    还没读属性值时：hasFault(forRelationshipNamed:author)=true、objectIDs(forRelationshipNamed:author) 给 1 个 ID、changedValues 键=[]，问完再看 isFault=FTT（被问过的那条已经解开了）
    只读 rows[0] 的 title 之后 isFault=FTT（只解开被读的那个）
    读了 author：另一端到手时 isFault=true，再读它的 name=pa；两次读 author 拿到同一个实例吗=true
    同上下文再 fetch 一次：3 条，第一条跟第一次是同一实例吗=true
    同一个容器再开一个**全新**上下文、默认设置 fetch：3 条，isFault=TTT
    还是那个上下文，把 returnsObjectsAsFaults 设成 false 再 fetch：3 条，isFault=FFF（对象已被上下文记住，所以看到的是同一批实例）
    换一个**全新容器**读同一个文件：默认请求 fetch 到 3 条 isFault=FFF，带 sortDescriptors 的也=FFF
    这个新容器上把 returnsObjectsAsFaults 设成 false（默认值 true）：3 条，isFault=FFF —— 跟上面看不出差别
    resultType=.countResultType：fetch 给 1 个元素，元素=3；count(for:) 给 3
```

`isFault` 读回来的是「这条对象此刻还没查过库」的状态（T=占位、F=已解开）。
默认 fetch 在「刚存过这批数据的容器」上给 `TTT`，换成全新容器读同一个文件却直接给 `FFF`；
带不带 `sortDescriptors` 也一样；把 `returnsObjectsAsFaults` 关掉当然是 `FFF`。
**能靠住的只有 `isFault` 这个读出来的状态，不是「设了某个开关就一定懒加载」。**
有两件事是明确的：读一个对象的一个属性只解开**那一个**对象（`FTT`，其余照旧）；
而 `objectIDs(forRelationshipNamed:)` 虽然名义上是「不解开也能拿关系里的 ID」，
实测它把被问过的那条**解开了**，真正不触发读取的是 `hasFault(forRelationshipNamed:)`。
另外**同一个上下文里同一行永远是同一个实例**（两次 fetch 都相等），
不同上下文则各一份实例——CoreData 的身份保证只到上下文为止。
`resultType = .countResultType` 那条也值得记：fetch 会给你**一个元素**，那个元素是数字 3，
而 `count(for:)` 直接给 3——两个 API 的返回形状不同，别混用。

### refresh / rollback：三种「让对象回到库里的样子」的差别

```
  -- refresh / rollback / hasChanges --
    改完没存：stars 读回=999 上下文 hasChanges=true 对象 hasChanges=true hasPersistentChangedValues=true | refresh(mergeChanges:true) 之后 stars=999/上下文 hasChanges=true | refresh(mergeChanges:false) 之后 stars=1/上下文 hasChanges=true/对象 hasChanges=false/updatedObjects=0/changedValues 键=[] | refreshAllObjects + rollback 之后文件=行数=3 Z_MAX=3
```

`refresh(mergeChanges: true)` 保留你的未存改动（stars 还是 999）；
`refresh(mergeChanges: false)` **丢掉**它（回到 1），同时把对象与上下文的 `hasChanges` 都清成 false，
`changedValues` 变空——这是「撤销一处编辑」最省事的做法。
`refreshAllObjects` 只处理「库里变了」的方向，改完没存的东西要靠 `rollback()`。

### 多上下文：谁看得见谁的改动

```
  -- 多上下文：谁看得见谁的改动 --
    store 里 3 条；ctxP 插 1 条没存 → ctxP count=4，同一请求改成 includesPendingChanges=false 再数=3，兄弟上下文 ctxQ count=3（文件里 行数=3 Z_MAX=3）
    child(parent=ctxP) 起始 count=3；child 插 1 条后 成功，此时文件里 行数=3 Z_MAX=3 | parent count=4，parent 成功 之后文件里 行数=4 Z_MAX=4

  -- 同一行被两个上下文改：合并策略与 Z_OPT --
    同一个对象实例吗=false | ctxV 先存：成功 | ctxU 再存：抛出 domain=NSCocoaErrorDomain code=133020 userInfo键=["NSExceptionOmitCallstacks", "conflictList"]（此时 mergeType=1）| ctxU 换成 storeTrump 再存：成功
  ok   这一节全在讲「一个对象到底是谁」，四件事各自有坑。**objectID 有三段身份**：刚 insert 的是临时 ID（isTemporaryID=true，uri 的 host 是 nil，末段以 t 开头）；`obtainPermanentIDs(for:)` 不存盘也能提前换成永久 ID（host 立刻变成长 36 的 store UUID，末段以 p 开头）；存盘之后再量，uri 的形状和 obtain 之后一样。两个坑在这儿：一是**没存盘也能 existingObject(with:) 拿到对象**（上面「拿到了」），别指望它帮你校验存没存；二是拿这个 ID 去**另一个容器**（另一个 store）反查会抛 NSCocoaErrorDomain code=133000，userInfo 只有 objectID 一个键 —— ID 里的 host 就是 store 的 UUID，所以 objectID 只在**同一个 store** 内有意义，不能当跨环境的主键存起来。另外这条 URI 形状（x-coredata://<store-UUID>/Note/p<行号>）本身就不稳定：p 后面的数字是 Z_PK，而 §11 已经量到 CoreData 存盘时给谁分配几号不保证 —— 别拿它当稳定字符串存进设置或 URL。**KVO 听不到 objectID 变化**：上面用 KVO 盯 objectID 这个键全程触发 0 次，而头文件里能 grep 到的公开通知只有上下文那五个（WillSave/DidSave/ObjectsDidChange/DidSaveObjectIDs/DidMergeChangesObjectIDs），这一版 SDK 根本没有 objectID 变化的通知 —— 想在新建对象上拿到永久 ID，只能在 save 之后重新读 objectID。**fault 不是你能预测的开关**：默认 fetch 在「刚存过这批数据的容器」上给 TTT（三条都是没解开的占位），换成全新容器读同一个文件却直接给 FFF；带不带 sortDescriptors 也一样；把 returnsObjectsAsFaults 关掉当然是 FFF。能靠住的只有 isFault 这个**读出来的状态**，不是「设了某个开关就一定懒加载」。不过有两件事是明确的：读一个对象的一个属性只解开**那一个**对象（FTT，其余照旧）；而 `objectIDs(forRelationshipNamed:)` 虽然名义上是「不解开也能拿关系里的 ID」，实测它把被问过的那条**解开了**（FTT 那行），真正不触发读取的是 `hasFault(forRelationshipNamed:)` —— 问完仍然是 TTT 的那个（上面「还没读属性值时」那行是问完之后的形状，被问过的那条已经解开）。另外**同一个上下文里同一行永远是同一个实例**（两次 fetch 都相等），不同上下文则各一份实例（上面「同一个对象实例吗=false」）—— 这就是 CoreData 的身份保证只到上下文为止。**上下文之间只靠 save 和合并传消息**：ctxP 插一条没存，它自己数到 4（includesPendingChanges 默认 true），同一个请求把该开关关了就数到 3，而兄弟上下文 ctxQ 一直是 3、文件里也一直是 3 行；child context（parent=ctxP）save 成功但文件一行没多，得 parent 再存一次才落到 SQLite（Z_MAX 也从 3 变 4，§12 那本账）。**同一行被两个上下文各改一次**：默认 mergePolicy 的 mergeType 就是 0（ NSErrorMergePolicy 那一档），所以 ctxV 先存成功、ctxU 后存抛 133020（跟 §12 撞号同一个码，userInfo 也是 conflictList），换成 storeTrump（mergeType=1）再存就成功，最后文件里 f1 是 **22**、Z_OPT 已经涨到 **3** —— 冲突 CoreData 不替你决定，先把 133020 抛回来；「让谁的值赢」是你换 mergePolicy 定的，而它判断「你手里那份还是不是最新的」用的就是 §12 那本 Z_OPT 账：每次成功存盘给那行加一。
```

上下文之间**只靠 save 和合并传消息**，这一段的四个观测：

- ctxP 插一条没存：它自己数到 4（`includesPendingChanges` 默认 true），
  同一个请求把该开关关了就数到 3，而兄弟上下文 ctxQ 一直是 3、文件里也一直是 3 行。
- child context（`parent = ctxP`）save **成功**但文件一行没多，得 parent 再存一次才落到 SQLite
  （`Z_MAX` 也从 3 变 4，§12 那本账）。这就是层次上下文的语义：**子上下文 save 只是交给父**。
- 同一行被两个上下文各改一次：默认 `mergePolicy` 的 `mergeType` 就是 0（`NSErrorMergePolicy` 那一档），
  所以 ctxV 先存成功、ctxU 后存**抛 133020**（跟 §12 撞号同一个码，userInfo 也是 `conflictList`），
  换成 `storeTrump`（`mergeType=1`）再存就成功，最后文件里那条是 **22**、`Z_OPT` 涨到 **3**。
- 于是这条最值得背下来：**冲突 CoreData 不替你决定，先把 133020 抛回来；
  「让谁的值赢」是你换 mergePolicy 定的**，而它判断「你手里那份还是不是最新的」用的就是
  §12 那本 `Z_OPT` 账：每次成功存盘给那行加一。

四档常用策略按「谁赢」记：`errorMergePolicy`（默认，抛 133020）、
`mergeStoreTrumpMergePolicy`（库里已有的赢，丢掉你的改动）、
`objectStoreTrumpMergePolicy`（同前但对冲突对象整体处理）、
`mergePropertyStoreTrumpMergePolicy`（**按属性**逐列比，两边都没碰的列保留、谁改过的谁赢）。
迁移到 iCloud/多设备时最后那档几乎是唯一合理的选择，因为它不会整块覆盖用户正在编辑的字段。

## 14) 模型改了、旧库怎么办：两个开关的四种组合，改名等于删数据

这一节是全书最贵的一节之一，因为它的失败**多数不报错**。先把两个开关的分工说清：

- `shouldMigrateStoreAutomatically`：开库前先试迁移（默认 true）。
- `shouldInferMappingModelAutomatically`：没有手工做的 mapping model 时，允许它自己推断（默认 true）。

两个都为 true 是出厂值（§10 量的）。实验设计：先用 v1 模型（只有 `title`）建一个库、存一条数据，
然后每个用例都从这个母本**复制一份文件**出来（免得前一个用例迁移过的库污染后一个），
分别用 v2（多加一个可选列 `tag`）、v3（把 `title` 改名成 `title2`）、以及回滚用的 v1 去开它，
四种开关组合各跑一遍，然后把三样东西同时打印：`loadPersistentStores` 的错误、
fetch 结果、以及**文件里此刻的列清单**。

```
== 14) 模型改了、旧库怎么办：两个迁移开关的四种组合 ==
  母本（v1 模型，属性只有 title/stars）：建库 domain=nil（没出错） 存一条 成功
    母本现状：列=Z_PK | Z_ENT | Z_OPT | ZSTARS | ZTITLE  Z_VERSION=1 行数=1 元数据带 plist=1  wal_checkpoint(TRUNCATE) 的 busy 位=0
  v2 多加一个可选列 tag，两开关都开（出厂默认）：domain=nil（没出错）  fetch 1 条 title 读回=Optional(旧数据)  列=Z_PK | Z_ENT | Z_OPT | ZSTARS | ZTITLE | ZTAG  Z_VERSION=1 行数=1 元数据带 plist=1
  v2 同上，migrate 开 / infer 关：domain=NSCocoaErrorDomain code=134140 userInfo键=["destinationModel", "reason", "sourceModel"]  fetch 0 条  列=Z_PK | Z_ENT | Z_OPT | ZSTARS | ZTITLE  Z_VERSION=1 行数=1 元数据带 plist=1
  v2 同上，两开关都关：domain=NSCocoaErrorDomain code=134100 userInfo键=["metadata", "reason"]  fetch 0 条  列=Z_PK | Z_ENT | Z_OPT | ZSTARS | ZTITLE  Z_VERSION=1 行数=1 元数据带 plist=1
  v3 把 title 改名成 title2，两开关都开：domain=nil（没出错）  fetch 1 条 title2 读回=nil  列=Z_PK | Z_ENT | Z_OPT | ZSTARS | ZTITLE2  Z_VERSION=1 行数=1 元数据带 plist=1
  改名那次之后，文件里 ZNOTE 的列明细：Z_PK:INTEGER | Z_ENT:INTEGER | Z_OPT:INTEGER | ZSTARS:INTEGER | ZTITLE2:VARCHAR
  老数据在 SQL 层还找得到吗（问 ZTITLE）：prepare失败:no such column: ZTITLE
  v1 旧模型开在「上面 v2 已经加过 ZTAG 的那个库」上，两开关都开：domain=nil（没出错）  fetch 1 条 title 读回=Optional(旧数据)  列=Z_PK | Z_ENT | Z_OPT | ZSTARS | ZTITLE  Z_VERSION=1 行数=1 元数据带 plist=1
  给 setValue(_:forPragmaNamed:) 塞一个非法值（journal_mode=not-a-mode）：domain=NSCocoaErrorDomain code=256 userInfo键=["NSFilePath", "NSSQLiteErrorDomain"] store 数=0 主文件建了吗=true
```

**1) 两开关都开 + 多加一个可选属性 = 真能用。** both-on 那行文件里多出一个 `ZTAG` 列，
老行还在，`title` 读回「旧数据」。这就是「轻量级自动迁移」的适用范围。

**2) 关掉的两种失败长得不一样，但结论都是 store 没挂上。**

| 组合 | domain / code | userInfo 键 | 含义 |
| --- | --- | --- | --- |
| migrate 开 / infer 关 | `NSCocoaErrorDomain` **134140** | `sourceModel`, `destinationModel`, `reason` | 它想迁移，但没有映射模型可加载 |
| 两开关都关 | `NSCocoaErrorDomain` **134100** | `metadata`, `reason` | 模型指纹和库里存的那份对不上 |

两种情况下 `fetch` 都是 **0 条**而不是「读到旧数据」。
别把「fetch 到空」误读成「库是空的」——上面那两行的列清单还是老五列，文件一动没动。
这是线上事故里最常见的一种误判：用户数据还在文件里，UI 显示「暂无数据」。

**3) 最贵的一课：改属性名不是迁移，是删一列再建一列。** v3 把 `title` 改名成 `title2`，
两开关全开，`loadPersistentStores` 一句错都没报（`domain=nil`），fetch 照样 1 条——
可 `title2` 读回 **nil**，因为文件里那列已经叫 `ZTITLE2`，SQL 层再问 `ZTITLE` 就是
`no such column`。**老数据不是读不到，是不存在了。**
推断只认「加/删可选属性」这种对得上号的差；改名要有语义映射
（`NSMappingModel` 的 attribute renaming，或者手工写迁移策略）才保得住数据。

**4) `Z_VERSION` 帮不上忙。** 这四种组合里 `Z_VERSION` 从头到尾是 1——本章从没给模型设过版本标识
（`versionIdentifiers`）。对得上对不上靠的是 `Z_METADATA` 里那份模型指纹（`Z_PLIST` 非空那 1 行）。
也就是说：**不设版本，CoreData 也能判断模型变没变（靠哈希），但没有任何东西帮你记录
「这是第几版、该走哪条迁移」**。真要写迁移通路，必须显式给模型设版本标识。

**5) 迁移不是只朝前发生的。** 把 v1 旧模型开在「刚才已经加过 `ZTAG` 的那个库」上，
同样两开关全开、同样不报错、`title` 照旧读得到，但文件里的 `ZTAG` 这一列**被删了**——
旧模型开新库会按旧模型重建表结构。**回滚版本时丢的是新属性那部分数据**，
这条在灰度发布/回滚场景里代价极高，而它的表现和「一切正常」完全一样。

**6) 最后一个 store 描述的坑。** 给 `setValue(_:forPragmaNamed:)` 塞一个非法值
（`journal_mode=not-a-mode`），拿到的错误码只有 **256**（一个笼统的写失败），
userInfo 里连 SQLite 的返回码都没有，只有 `NSFilePath` 和 `NSSQLiteErrorDomain`；
而 coordinator 的 `persistentStores` 是空数组、磁盘上的主文件**却已经建好了**——
**失败不会替你清理半成品**，重开前记得自己删干净（本章的 `wipe()` 就是为此而写，
它连 `-wal`/`-shm` 一起删）。

顺带把工程做法说清：这一节的结论不等于「线上可以放心开自动迁移」。
真实项目的通路是——上线前备份 store 文件、给模型显式设版本、改名与结构大动用手工
`NSMappingModel` + `NSEntityMigrationPolicy`（或 `NSMigrationManager`），
自动推断只留给「加一个可选属性」这一种。本章只量到「开关会怎样」，没跑完整通路，
这条写在章末边界第 2 条里。

## 15) 一次问出统计值：聚合表达式、分组与去重

CoreData 不给 SQL，给的是 `NSExpressionDescription`。最小写法：

```swift
let r = NSFetchRequest<NSDictionary>(entityName: "Note")
r.resultType = .dictionaryResultType                    // 不设就是 managedObject，聚合不生效
let cnt = NSExpressionDescription()
cnt.name = "cnt"                                        // 别名：本节第一个坑在它的字符集上
cnt.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "stars")])
cnt.expressionResultType = .integer64AttributeType      // 只决定「你要什么形状」
r.propertiesToFetch = [cnt]
```

本节 fixture：6 条 Note，`stars = [1,2,3,1,2,4]`，第六条故意不给 `title`（它是可选的）。

```
== 15) 一次问出统计值：聚合表达式、分组与去重 ==
  A 单个聚合、别名「个数」：行数=1 个数=6
  B 两个中文别名：个数 + 总和：行数=1 个数=nil值 总和=13
  C 同一个 count: 起两个名字：cnt 与 个数：行数=1 cnt=6 个数=nil值
  D 四个 ASCII 别名一次取（cnt/sum/min/max）：行数=1 cnt=6 max=4 min=1 sum=13
  E1 average 声明 integer64（真实值 13/6）：行数=1 avg64=2
  E2 同一个 average 声明 double：行数=1 avg64=2.166666666666667
  E3 sum 声明 string：行数=1 sum=13.0
     E3 那个值拿到的真实类型=NSTaggedPointerString 值=Optional(13.0)（声明成 string 并不会给你一个字符串）
  F 普通列 title + 聚合 sum，没有 groupBy：行数=6 sum=13 | sum=13 title=第1条 | sum=13 title=第2条 | sum=13 title=第3条 | sum=13 title=第4条 | sum=13 title=第5条
  G 按 stars 分组 + count：行数=4 cnt=2 stars=1 | cnt=2 stars=2 | cnt=1 stars=3 | cnt=1 stars=4
  H 只取 stars + distinct=true：行数=4 stars=1 | stars=2 | stars=3 | stars=4
  H2 同样的请求，distinct 保持出厂值 false：行数=6 stars=1 | stars=1 | stars=2 | stars=2 | stars=3 | stars=4
  I count: 分别是 title(有一条没值) 和 stars：行数=1 cntStars=6 cntTitle=5
  J 空表上四个聚合：行数=1 cnt=0 sum=0
  J2 空表上只取普通列：行数=0 
     J 的字典里按键名排序只有 ["cnt", "sum"]；问它有没有 avg 这个键=false，而 cnt/sum 是有的=true
  K 不设 resultType：request.resultType=0（0=managedObject 1=dictionary 2=objectID 3=section 4=count）distinct=true
     fetch 回来 6 个元素，第一个的真实类型=NSManagedObject —— 同一个请求写成 NSFetchRequest<NSDictionary> 再取元素就是本节讲的崩溃点
  L 实体 Author 上 count: notes（to-many 关系）：行数=1 cnt=3 name=作者甲
  M 实体 Note 上 count: author（to-one）+ sum: stars：行数=1 cntAuthor=3 sumStars=13
```

五个坑，每个都有对应的行：

**1) 别名的字符集。** 只放一个聚合时中文别名完全正常（A 的「个数」给 6），
可只要同一个请求里有**两个以上**聚合表达式，非 ASCII 的别名那一格就开始**静默变 nil**：
B 里「个数」nil 而「总和」有值、C 里同一个 `count:` 起两个名字则 ASCII 的 `cnt` 有值、
中文的 `个数` nil，全部用 ASCII（D 的四个）就一个都没丢。
它不报错也不抛异常，**读到 nil 是唯一线索**。聚合列的 name 请一律用 ASCII。

**2) `expressionResultType` 是「你要什么形状」，不是「它算什么」。**
同一列的 `average`（真实值 13/6）声明 `integer64` 拿到 **2**（截断，不是四舍五入）、
声明 `double` 拿到 2.166666666666667；`sum` 声明 `string` 会真的给你一个字符串「13.0」
（E3 那行量的类型是 `NSTaggedPointerString`）。声明错了不会崩，只会给你一个形状不对的值——
编译器帮不上忙，因为它本来就是运行时数据。

**3) 普通列和聚合混在一起时，不设 `propertiesToGroupBy` 也照样出结果，但是逐行的。**
F 只多写了一个 `title`，就拿到 6 行、每行的 `sum` 都是整表的 13
（它没有分组，等于把聚合当常量贴在每行上）。想要「每组多少」必须显式 `groupBy`
（G 按 `stars` 分组才给 4 行：2/2/1/1）。顺带一件与本章判定直接相关的事：
这类请求的**行序不保证**——不加 `sortDescriptors` 时，同一份代码 debug/release 打出来的先后
就不一样（本章第一次跑就栽在这里），所以 F 那行是加了按 `title` 排序才打得出来的；
排序和「逐行给常量」这个结论无关。

**4) `returnsDistinctResults` 的出厂值是 false，而且只对 dictionary 结果起作用。**
H 开了给 4 个不同值，H2 保持默认给 6 行；而 K 那种「设了 distinct 却没设 resultType」的请求，
`request.resultType` 仍是 0（managedObject），fetch 回来的还是 `NSManagedObject`——distinct 被忽略。
这里顺手讲清本章唯一的崩法：同样这个请求，只要写成 `NSFetchRequest<NSDictionary>` 去取元素，
Swift 侧当场挂掉，探针进程原文是

```
Fatal error: NSArray element failed to match the Swift Array Element type
Expected NSDictionary but found NSManagedObject      ← signal 4
```

**泛型参数只是个断言，运行时不会替你校验。** 示例正文一行都没执行它，
K 那两行用 `NSFetchRequestResult` 收才是安全写法。

**5) 空表和 NULL。** 空表上聚合不报错，给 1 行，`COUNT`/`SUM` 是 0（J），
但 `AVG`/`MAX` 那一格**连键都不在字典里**（allKeys 只有 `cnt` 和 `sum`）——
Swift 侧按键取「avg」和「有键但值是 nil」的 B 一样都读成 nil，**只有 allKeys 能区分这两种**。
另外 `count:` 走的是 SQL `COUNT(列)` 的语义、NULL 不计：I 里 `title` 有第六条没给值
→ `cntTitle=5`，非可选的 `stars` 仍是 6。
关系也算 count：L 在 Author 上 `count: notes` 给 3，M 在 Note 上 `count: author`
只数**有** author 的那 3 条（还有一条 noAuthor 不计）。

写报表时的落地建议：把聚合别名列成 ASCII 常量，`expressionResultType` 一律给 `double`
（避免整型截断），并在读值时区分「键不存在」和「值是 nil」；需要「每组多少」就同时写
`propertiesToGroupBy` + `sortDescriptors`（分组查询不排序时行序同样不保证，见 F）。

## 16) 批量请求：insert / update / delete 走 store，不经过上下文

CoreData 的三种批量请求是「绕过上下文」的官方通道，用于导入、清洗、批量清理：

```swift
try context.execute(NSBatchInsertRequest(entity: eNote, objects: [["stars": 1, "title": "a1"]]))
let bur = NSBatchUpdateRequest(entity: eNote)
bur.propertiesToUpdate = ["stars": 77]                 // 不设 predicate 就是全表
try context.execute(bur)
let bdr = NSBatchDeleteRequest(fetchRequest: someFetchRequest)
try context.execute(bdr)
```

这一节的核心只有一句话：**它走 store 那条通道，所以既不受你的上下文管，也不给你上下文的待遇。**
先把三个请求的出厂值和两条 insert 入口量出来：

```
== 16) 批量请求：insert / update / delete 走 store，不经过上下文 ==
  A 新建 NSBatchInsertRequest：resultType 出厂=0（0=statusOnly 1=objectIDs 2=count）entityName=Note objectsToInsert 回数=1 dictionaryHandler 是否已设=false
  B objects: 版插一条（resultType=.count）：result=Optional(1) 类型=NSBatchInsertResult 上下文 count=1 文件里=a1:1 主键账=Author=Z_MAX:0 | Note=Z_MAX:1
  C objects: 里漏掉非可选的 stars：抛出 domain=NSCocoaErrorDomain code=1570 userInfo键=["NSValidationErrorKey", "NSValidationErrorObject", "NSValidationErrorValue", "reason"] 消息=%{PROPERTY}@ is a required value. 之后文件里=a1:1
  D dictionaryHandler 第三次 return true：result=Optional(2) handler 调了 3 次（第一次进来时那个字典里是空的）之后文件里=a1:1 | h1:101 | h2:102
  F objects: 版两条 + resultType=.objectIDs：拿到 2 个 objectID，URI 末段形状=p4 是否全是永久 ID=true
  F2 这批新行在 viewContext 里的可见性：count(for:)=5（每次都跑 SQL，所以看得见）
  G NSBatchUpdateRequest 出厂：resultType=0（0=statusOnly 1=updatedObjectIDs 2=count）includesSubentities=true predicate=nil
```

`dictionaryHandler` 那两行值得单独展开，因为它的返回值语义和直觉反着：

```swift
let bir = NSBatchInsertRequest(entity: eNote, dictionaryHandler: { (d: NSMutableDictionary) -> Bool in
    dh += 1
    d["stars"] = 100 + dh
    d["title"] = "h\(dh)"
    return dh >= 3      // ← true 表示「够了，别再问我了」
})
```

handler 每次拿到的是一个**空的** `NSMutableDictionary`，你填进去的键值就是一行；
**返回值是「够了吗」而不是「成功吗」**——D 那行第三次 return true，result 就只数到 2
（第三个字典还没写就被丢了）。反过来，一次都不 return true 就是**没有终点的循环**：
探针里 handler 被连调 826 万次、100 秒都没返回，只在磁盘上留下 187 MB 的 WAL
（另一支每调一次打一行日志的探针被杀掉前已经打了 299488 行）。示例正文一行都不执行它，
写的时候请在 handler 里放一个计数器兜底。

再量 update 与「上下文里的老对象」：

```
  G2 batch update 把 stars 全表改成 77：result=Optional(5) 更新前手里那条=Optional(1) 更新后同一个对象再读=Optional(1) 上下文 hasChanges=false
  G3 文件里实际是什么：a1:77:typeof=integer | h1:77:typeof=integer | h2:77:typeof=integer | oid1:77:typeof=integer | oid2:77:typeof=integer
  H propertiesToUpdate 给 integer 属性塞字符串（只改 title==a1 那行）：result=Optional(1) 文件里那行现在=a1:0:typeof=integer
  I NSBatchDeleteRequest(fetchRequest:) 出厂 resultType=0（0=statusOnly 1=objectIDs 2=count）带的 fetch request resultType=1
```

**update 完全不通知你，也不回头改你手里已经拿着的对象**：G2 把全表 `stars` 改成 77，result 数到 5 行，
SQL 层也确实全是 77（G3），可上下文里那个之前就 fetch 到的对象再读还是 **1**，
而且 `ctx.hasChanges` 是 **false**——它没在自己的登记簿上记这笔，所以 save 也不会帮你带出去。
要让它可见得自己 `mergeChanges(fromContextDidSave:)`（用 result 里的 objectIDs）或者 `refresh`；
`count(for:)` 那种「每次都重新跑 SQL」的读法则立刻看得到（F2 从 1 变 5）。
`propertiesToUpdate` 给错类型也不报错，交给 SQLite 的类型亲和去办：H 把 integer 属性 `stars`
设成字符串「文字」，result=1 表示改成功了，文件里那一行的值是 **0**（`typeof` 仍是 integer）——
和 §5 那条「列亲和什么，值就被拧成什么」是同一件事，只是这里拧的人换成了 CoreData 发出去的那条 UPDATE。

最后是 delete，它的两笔账：

```
  I2 用 objectIDs: 版删掉上下文里已经拿着的那条：删 1 条（title=Optional("oid2")）result 回数=1 之后同一个对象读 title=Optional(oid2) 给它改个值再 save：抛出 domain=NSCocoaErrorDomain code=133020 userInfo键=["NSExceptionOmitCallstacks", "conflictList"] 消息=Could not merge changes. 文件里还剩 4 行，主键账=Author=Z_MAX:0 | Note=Z_MAX:5
  J 删之前：作者=1 笔记=3 挂了author=3 悬空=0 主键账=Author=Z_MAX:1 | Note=Z_MAX:3
  J2 批量删完 Author：批量删 Author result=Optional(1) 删之后文件里=作者=0 笔记=0 挂了author=0 悬空=0
  J3 上下文里再 fetch 一次 Note：0 条，而 SQL 层是 0 行
  ok   批量请求这一节的核心只有一句话：它走 store 那条通道，所以它**既不受你的上下文管，也不给你上下文的待遇**。**先说三个请求的出厂值**：NSBatchInsertRequest 的 resultType 出厂是 0（statusOnly，什么都不回），NSBatchUpdateRequest 也是 statusOnly 且 includesSubentities=true、predicate=nil（不设条件就是全表），NSBatchDeleteRequest 更值得注意：它把传给它的 fetchRequest 的 resultType **改写成 objectID（1）**，因为它内部就是靠那批 ID 去删的 —— 上面 I 那行量到的 0 和 1 就是这个改写。**insert 的两条入口脾气不同**。objects: 版是「你给我字典数组」，漏掉非可选属性就直接抛 NSCocoaErrorDomain code=1570，而且它的错误文本里那个占位符根本没替换：消息原文是 `%{PROPERTY}@ is a required value.`（C 那行），userInfo 里倒是给了 NSValidationErrorKey/Object/Value 三个真信息，要用人家得自己拼。dictionaryHandler 版是「CoreData 反过来问你」：它每次给你一个**空的** NSMutableDictionary，你填进去的键值就是一行，**返回值是「够了吗」而不是「成功吗」** —— D 那行第三次 return true，result 就只数到 2（第三个字典还没写就被丢了）。反过来，一次都不 return true 就是**没有终点的循环**：探针里 handler 被连调 826 万次、100 秒都没返回，只在磁盘上留下 187 MB 的 WAL（另一支每调一次打一行日志的探针被杀掉前已经打了 299488 行）；示例正文一行都不执行它，写的时候请在 handler 里放一个计数器兜底。**取号还是走 CoreData 自己的账**：批量插一条之后 Z_PRIMARYKEY 里 Note 的 Z_MAX 从 0 变 1（B 那行），这就是 §12 说的那条路 —— 绕开 CoreData 手工 INSERT 要自己维护那本账，走批量请求就不用。resultType=.objectIDs 也确实拿回 2 个**永久** ID（F 那行：URI 末段是 p4，isTemporaryID 全 false），所以批量插入之后想用这些对象，直接 existingObject(with:) 接上就行。**update 完全不通知你，也不回头改你手里已经拿着的对象**：G 那行先把全表 stars 改成 77，result 数到 5 行，SQL 层也确实全是 77（G3），可上下文里那个之前就 fetch 到的对象再读还是 1，而且 `ctx.hasChanges` 是 false —— 它没在自己的登记簿上记这笔，所以 save 也不会帮你带出去。要让它可见得自己 `mergeChanges(fromContextDidSave:)`（用 result 里的 objectIDs）或者 refresh；count(for:) 那种「每次都重新跑 SQL」的读法则立刻看得到（F2 从 1 变 5）。**propertiesToUpdate 给错类型也不报错，交给 SQLite 的类型亲和去办**：H 把 integer 属性 stars 设成字符串「文字」，result=1 表示改成功了，文件里那一行的值是 **0**（typeof 仍是 integer）—— 和 §5 那条「列亲和什么，值就被拧成什么」是同一件事，只是这里拧的人换成了 CoreData 发出去的那条 UPDATE。**delete 这一半有两笔账**。一是它删得掉 store，删不掉你手里的对象：I2 用 objectIDs: 版删掉上下文正拿着的那条，上下文里那个对象照样读得到 title（它不知道），等给它改了值再 save 才炸出来 —— NSCocoaErrorDomain code=133020、userInfo 带 conflictList，和 §12 撞号、§13 双写同一个码，那句 localizedDescription 是「Could not merge changes.」。二是 Z_MAX 不回收：删完文件里剩 4 行，而 Z_PRIMARYKEY 的 Z_MAX 还是 5（上面最后那行的主键账）。**但它仍然走模型里的删除规则**：J 那对容器里 1 个作者挂着 3 条笔记（Note.author=nullify、Author.notes=cascade，§12 定的），对 Author 发批量删除之后，文件里笔记也一起没了、悬空行 0（J2）—— 批量请求绕的是上下文，不是模型的约束。这一点和 §12 的手工 SQL 正好对照：手工 DELETE 才是真的没人管你，删完留下悬空的 ZAUTHOR。
```

一是**它删得掉 store，删不掉你手里的对象**：I2 用 `objectIDs:` 版删掉上下文正拿着的那条，
上下文里那个对象照样读得到 `title`（它不知道），等给它改了值再 save 才炸出来——
`NSCocoaErrorDomain code=133020`、userInfo 带 `conflictList`，和 §12 撞号、§13 双写同一个码，
那句 `localizedDescription` 是 `Could not merge changes.`。
二是 **`Z_MAX` 不回收**：删完文件里剩 4 行，而 `Z_PRIMARYKEY` 的 `Z_MAX` 还是 5。

**但它仍然走模型里的删除规则**：J 那对容器里 1 个作者挂着 3 条笔记
（`Note.author=nullify`、`Author.notes=cascade`，§12 定的），对 Author 发批量删除之后，
文件里笔记也一起没了、悬空行 0（J2）——**批量请求绕的是上下文，不是模型的约束**。
这一点和 §12 的手工 SQL 正好对照：手工 DELETE 才是真的没人管你，删完留下悬空的 `ZAUTHOR`。

把 §12 的 C 段和本节放在一起，CoreData 的三条写入通路就完整了：

| 通路 | 走上下文吗 | 走模型约束/删除规则吗 | 维护 `Z_PRIMARYKEY` / `Z_OPT` | 通知你吗 |
| --- | --- | --- | --- | --- |
| `insert` + `save` | 是 | 是 | 是 | 是（DidSave 那一族通知） |
| 批量请求（§16） | **否** | 是 | 是 | **否**（要自己 merge） |
| 手工 SQL（§12 C） | 否 | **否** | **否**（得自己维护） | 否（但下次 fetch 读得到） |

选哪条通路其实是「你要不要上下文那套记账」的选择：导入大批数据要快就选批量请求，
但必须接受「UI 不会自动更新」；手工 SQL 只在真的知道自己在做什么、并且同时维护账本时才用。

## 本章的诚实边界

八条，全部对应上文某个具体的没跑过的分支：

```
== 本章的诚实边界 ==
  1) 模型全是代码构造的：本章每一节都用 NSManagedObjectModel + NSEntityDescription 手搓模型、用 KVC 读写值，
     所以 .xcdatamodeld 文件、codegen 出来的 NSManagedObject 子类、@objc dynamic、representedClass 这些
     只在 Xcode 模型编辑器里才有的东西一条都没验；SwiftData/@Model 更不在范围内。
  2) 迁移只量了「两个开关 + 轻量级推断」：真正的 mapping model、自定义 NSEntityMigrationPolicy、
     多版本模型与 versionIdentifiers（§14 里 Z_VERSION 全程是 1，正是因为本章从没给模型设过版本）、
     NSMigrationManager、以及上线前先备份 store 这套工程做法都没跑。
     §14 只证明了「改名会静默丢数据」，没给出保数据的完整通路。
  3) 数量级与性能一条都没量：批量插入的正常路径只有几条记录，正常 handler 分支也没超过三次；
     一万/十万条的耗时、内存峰值、WAL 膨胀、fetchBatchSize 的效果、调 PRAGMA 能省多少，都不在本章证据里。
  4) 并发只量到形状：多上下文可见性、child context、mergePolicy、批量请求绕过上下文都测了，
     但 perform/performAndWait 的队列归属、嵌套 performAndWait 的死锁、跨进程共享同一个 store
     （NSPersistentHistory 那条同步链路）都没做。§16 那个 NSSQLiteErrorDomain 6922 是把磁盘写爆之后的副作用，
     不是受控复现的并发故障 —— 别把它当结论引用。
  5) store 的类型与位置没换过：全程 NSSQLiteStoreType + 临时目录下的单文件；
     InMemory / Binary / XML 三种 store、CloudKit 同步、migratePersistentStore 换位置、
     以及只读 store 被写入的分支都没测（§10 只开了 isReadOnly 这个开关看它默认值）。
  6) SQLite 侧留了很大一块没进：sqlite3_blob_* 的增量读写、FTS5 与虚拟表、自定义 collation、
     authorizer 与 progress handler（这两个和 §16 的 dictionaryHandler 一样，回调不返回就永远卡住）、
     sqlite3_backup、增量 VACUUM、多线程共用一个句柄的语义（§7 只处理了同进程开两个连接的情况）。
  7) 有些数字是这一版 SDK 的脾气，不是永恒事实：Z_PK 的取号顺序不保证（§11）、fault 何时出现随容器而异（§13）、
     聚合别名的静默 nil（§15）都只在 iOS 18.3.1 模拟器 + x86_64 这一套上量到；换 Xcode 版本请重跑示例，别照抄文档里的数字。
  8) UI 层完全没碰：本章不出现 NSFetchedResultsController —— 它的分节、变更差分和列表动画必须
     在真跑起来的列表里才看得出对错，那是 §15（UIKit 列表）和 §11（SwiftUI 列表）的地盘；
     本章给的「上下文不会自动通知你」那几条，正是接 FRC 之前必须先知道的前提。

  一句话：这一章把「同一份 SQLite 文件上，C API 和 CoreData 各自替你做了什么、出事时谁说话」讲透了；
  凡是性能、迁移通路、跨进程同步这三类问题，本章只指出坑在哪，答案得你自己按上面的边界去量。
```

再补一句方法上的边界：本章所有 CoreData 的观测都是**同一进程、同一套临时目录**里量到的，
它告诉你「API 现在怎么说话」，不告诉你「性能是多少」。凡是性能、迁移通路、跨进程同步这三类问题，
本章只指出坑在哪，答案得你自己按上面那八条边界去量。

## 本章要背下来的东西

- **返回码的形状比名字重要**：`ROW=100`、`DONE=101`、`MISUSE=21`、`RANGE=25`、`CONSTRAINT=19`，
  而 `SQLITE_OK` 是 **0**——所以永远写 `== SQLITE_OK` / `!= SQLITE_OK`，别把返回码当 Bool 用。
- **这一层不校验空指针**：`sqlite3_open(NULL)` 返回成功并给你一个匿名临时库；
  对 NULL 句柄调 `errmsg` 说的是 `'out of memory'`。每一次调用的返回码都要判。
- **`prepare` 只看第一条语句**：`rc=0` 不代表整段 SQL 是好的，坏的第二条要等 `tail` 再 prepare
  才现形；跑整段文本的正确循环是「沿 `tail` 推进」。`nByte` 给 `-1`，正数是按字节硬切。
- **`bind` 失败可以静默过去**：没绑上的槽位按 NULL 存进去，INSERT 照样成功；
  `errmsg` 一次成功的 step 就冲干净，只能打日志不能判成败。第 4 个参数在 Swift 里
  只能手搓 `unsafeBitCast(-1, to: sqlite3_destructor_type.self)`（TRANSIENT），
  写 `0`（STATIC）配 `withCString` 就是 use-after-free 级别的偶发乱码。
- **列不会把你要的类型当约束**：`column_int` 读 `'hello'` 给 0、`'24abc'` 存进 INTEGER 列还是 TEXT；
  `decltype` 是声明类型、`typeof`/`column_type` 才是运行时类型；NULL 列的 text 和 blob 指针**都是 NULL**。
  硬约束只有 `CHECK` 或打开外键，而 **`foreign_keys` 默认是 0**。
- **约束违约只有一个主码 19**：想知道是哪一类得问扩展码（`19 + 256×子序号`：NOT NULL 1299、
  主键 1555、外键 787）；`sqlite3_extended_result_codes(db,1)` 会让返回值**和 `errcode` 一起**升级，
  判 `rc == SQLITE_CONSTRAINT` 的代码会突然不再成立——要么全局统一，要么 `rc & 0xFF`。
- **事务是扁平的**，要嵌套只有 `SAVEPOINT`；`changes()` 是语句级、`total_changes()` 连回滚也算；
  留着没 `finalize` 的 stmt 去 `close` 返回 **5** 且库没关（Swift 的 `OpaquePointer` 不走 ARC），
  新代码一律 `close_v2`。
- **CoreData 的出厂值一律读回来**：`NSAttributeType` 是一百一档（string=700），
  新属性默认 `integer32`/`isOptional=true`/`NSNumber`，**新关系 `deleteRule` 默认 nullify(1)**，
  容器自带的 store 描述里两个迁移开关都开、`timeout` 是 240、`sqlitePragmas` 是空、
  无参 `NSPersistentStoreDescription()` 的 url 是 `/dev/null` 而 type 仍报 SQLite。
- **CoreData 底下那张表**：`Z` 前缀、实体号 `Z_ENT` 按**字母序**不是声明序、
  `ZNOTE` **没有 FOREIGN KEY 子句**、关系只是一个整数列 + 一条索引、`journal_mode` 是 wal、
  `user_version` 永远是 0（它记在自己的 `Z_METADATA` 里），而 `Z_PK` 的**取号顺序不保证**。
- **删除规则是对象图层面的、且双向传播**：`noAction` 不是 RESTRICT（它留悬空），
  `cascade` 不需要你先遍历关系，`deny` 抛 1600（校验错误，不是 SQL 错误）之后
  **上下文并不干净**，必须 `reset()` 才能继续。
- **绕过 CoreData 手写它的表要付四笔账**：`Z_OPT` 只有它自己维护、外部写的行下次 fetch 才看得见
  （已存在的对象不会更新）、取号只看 `Z_MAX` 不扫表（撞号就抛 133020 而且账不回滚）、
  `Z_ENT` 根本不是查询条件。
- **objectID 只在同一个 store 内有意义**（换容器反查抛 133000）、没存盘也能 `existingObject`、
  **KVO 听不到临时→永久的切换**；`isFault` 只能读不能预测，身份保证只到上下文为止。
- **上下文之间只靠 save + merge 传消息**：child save 不落盘、兄弟看不见你的未存改动、
  同一行被两边各改一次就抛 133020（默认策略是 error），「让谁赢」由 `NSMergePolicy` 决定，
  而它用的判据就是 `Z_OPT`。
- **两个迁移开关解释不了最贵的那类事故**：加可选列能自动迁移；关掉的两种失败分别是
  134140 / 134100 且 `fetch` 给 0 条（**文件没动**）；**改名不报错、fetch 照样出对象、值全是 nil**，
  等于删一列再建一列；旧模型开新库会**删掉**多出来的列。`Z_VERSION` 全程是 1，
  因为本章从没设过 `versionIdentifiers`。
- **聚合表达式的五个坑**：多聚合时非 ASCII 别名会静默 nil；`expressionResultType` 只决定形状
  （integer64 会把平均值截断）；普通列混聚合不设 groupBy 会给「每行贴一个常量」；
  `returnsDistinctResults` 默认 false 且只对 dictionary 生效；空表上 AVG/MAX **连键都不在字典里**，
  而 `count:` 不数 NULL。泛型参数只是断言，写成 `NSFetchRequest<NSDictionary>` 收 NSManagedObject
  是 signal 4。
- **批量请求绕的是上下文，不是模型约束**：三个请求出厂都是 statusOnly（delete 会把传入
  fetchRequest 的 resultType 改写成 objectID）；`dictionaryHandler` 的返回值是「够了吗」，
  永不返回 true 就是死循环；`objects:` 漏非可选属性抛 1570 且消息里的 `%{PROPERTY}@` 不替换；
  update/delete **不会**回头改你手里的对象（`hasChanges` 还是 false），要自己 merge；
  `Z_MAX` 不回收；而批量删 Author 仍然按模型规则把 Note 一起删掉。

下一章没有了——第 21 到 26 章把这本书的正文走完：UIKit 布局进阶、滚动与容器、核心动画、
音视频、传感器与定位，最后落在这套「数据往下到底存在哪」。往后要修的是既有章节的
索引与深度；而真要写进 App 时，这一章的判据只有一句话：
**凡是「按理说应该」的默认值，一律先读回来打印再写进代码。**
