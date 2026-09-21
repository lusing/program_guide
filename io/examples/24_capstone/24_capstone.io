// ============================================================
// 24_capstone.io —— 第 24 章：实战，一个完整的 Io 程序
// 运行：io examples/24_capstone/24_capstone.io
//
// 目标：把前 23 章的东西拼成一个能用的东西 —— 一个「访问日志分析器」。
//
//   · 原型 + 方法（07/08）：Record 是一份可以被 clone 的模板
//   · 文本处理（04/16）：按空白切字段、对齐渲染
//   · 集合（09/10/12）：用 Map 计数、用 List 排序，且顺序可复现
//   · 块（11）：聚合与排序靠块传行为
//   · 异常（13）：一条坏行不许毁掉整批数据
//   · 文件（14/21）：报告落盘、序列化往返校验
//   · 命令行（15）：System args 分派子命令
//   · 测试（20）：最后一段自检就是本仓库的回归骨架
//
// 全程不依赖任何外部文件：日志样本内嵌在源码里。
// ============================================================

fails := 0
chk := method(tag, got, want,
    if(got asString != want asString,
        fails = fails + 1
        writeln("  [FAIL] ", tag, " 得到 ", got asString, "，期望 ", want asString)
    )
)
sec := method(title, writeln(""); writeln("-- ", title))
show := method(label, value, writeln(label, " = ", value asString))

writeln("==== 24 开始 ====")

// ------------------------------------------------------------
// 数据模型：一份可以被克隆的记录模板
// ------------------------------------------------------------
// 槽名刻意避开 Io 的常用消息名（不叫 method、不叫 time、不叫 at），
// 免得把 Object/method 这类核心消息遮住。
Record := Object clone do(
    ts := ""
    verb := ""
    path := ""
    status := 0
    ms := 0
    parse := method(line,
        // 必须显式写分隔符！无参 split 是**按字节**扫空白的，
        // 非 ASCII 码位只要低位字节落在 \t\n\v\f\r 或空格里就会被切开
        // （"上" 的 U+4E0A 低字节就是 0x0A，`"上" split` 得到 list("")）。
        // 见第 16 章 16.4。
        f := line split(" ")
        if(f size != 5, Exception raise("字段数不对（" .. f size asString .. "），期望 5"))
        st := f at(3) asNumber
        // asNumber 对非数字是「静默给 0」，所以必须自己兜范围
        if(st < 100 or(st > 599), Exception raise("状态码不成样子：" .. f at(3)))
        r := Record clone
        r ts = f at(0)
        r verb = f at(1)
        r path = f at(2)
        r status = st
        r ms = f at(4) asNumber
        r
    )
    // 覆盖 asString，让记录能安全地拼进字符串（07.8 的做法）
    asString := method(verb .. " " .. path .. " -> " .. status asString)
)

// ------------------------------------------------------------
// 输入数据：12 行，其中 3 行是坏的，各有各的坏法
// ------------------------------------------------------------
sampleLines := list(
    "2026-09-21T10:00:01 GET /index 200 12",
    "2026-09-21T10:00:02 GET /index 200 15",
    "2026-09-21T10:00:03 POST /login 302 93",
    "2026-09-21T10:00:04 GET /about 200 11",
    "2026-09-21T10:01:05 GET /index 500 240",
    "字段不够",
    "2026-09-21T10:01:07 POST /login 200 88",
    "2026-09-21T10:01:08 GET /missing 404 7",
    "2026-09-21T10:02:09 GET /index 200 13",
    "2026-09-21T10:02:10 DELETE /item 403 5",
    "2026-09-21T10:02:11 GET /about abc 10",
    "2026-09-21T10:03:12 GET /about 999 10"
)

sec("24.1 解析：一条记录就是一个 clone 出来的原型")
one := Record parse(sampleLines at(0))
show("第一条记录", one)
show("one type", one type)
show("one path", one path)
show("one status", one status)
show("one ms", one ms)
show("覆盖过 asString 的拼接", "记录：" .. one)

// 先把 asNumber 的兜底行为钉死。它不是「转不动就给 0」——
show("\"abc\" asNumber", "abc" asNumber)
show("-- 它 isNan 吗", ("abc" asNumber) isNan)
show("-- nan < 100", ("abc" asNumber) < 100)
show("-- nan > 599", ("abc" asNumber) > 599)
show("-- nan >= 100 and(nan <= 599)",
     ("abc" asNumber) >= 100 and(("abc" asNumber) <= 599))
chk("asNumber 转不动给 nan，不是 0", "abc" asNumber isNan, true)
chk("nan 的比较结果恒走同一边（< 为真、> 为假）",
    list(("abc" asNumber) < 100, ("abc" asNumber) > 599) asString, "list(true, false)")
chk("所以只写单边 if(st > 599) 是拦不住 nan 的",
    ("abc" asNumber) >= 100 and(("abc" asNumber) <= 599), false)

// 坏行的异常消息要能拿到，且不能中断整批
bad1 := try(Record parse("字段不够"))
bad2 := try(Record parse("2026-09-21T10:02:11 GET /about abc 10"))
bad3 := try(Record parse("2026-09-21T10:02:11 GET /about 999 10"))
show("坏行 1 的消息", bad1 error)
show("坏行 2 的消息", bad2 error)
show("坏行 3 的消息", bad3 error)
chk("解析出来的是一份独立对象", one type asString, "Record")
chk("类型就是原型名", one isKindOf(Record), true)
chk("字段数不对会被拒绝", bad1 error, "字段数不对（1），期望 5")
chk("非数字状态码会被拒绝（asNumber 给 nan，靠 nan < 100 兜住）", bad2 error, "状态码不成样子：abc")
chk("越界状态码会被拒绝", bad3 error, "状态码不成样子：999")

sec("24.2 批量解析：坏行进「拒收单」，好行进结果集")
// 关键点：**先把 try 的结果拿到手，再决定收不收**。
// Record parse 抛异常时，`good append(...)` 这个表达式整个不成立，
// 而 try 又「成功也返回 nil」——所以唯一的判据是 e != nil（有异常）。
parseAll := method(lines,
    good := List clone
    bad := List clone
    lines foreach(line,
        e := try(good append(Record parse(line)))
        if(e != nil, bad append(list(line, e error)))
    )
    // 注意是 lexicalDo 不是 do：do(...) 把作用域切到接收者，只接得到 Lobby 的槽，
    // **看不到本方法的局部槽** good / bad（会报 "Object does not respond to 'good'"）。
    // lexicalDo 才是在「词法环境」里求值，能读到调用方的 locals。见第 07 章 7.10。
    Object clone lexicalDo(records := good; rejected := bad)
)
parsed := parseAll(sampleLines)
show("总行数", sampleLines size)
show("收下的行数", parsed records size)
show("拒收的行数", parsed rejected size)
show("拒收的第 1 条原因", parsed rejected at(0) at(1))
show("拒收的第 2 条原因", parsed rejected at(1) at(1))
show("拒收的第 3 条原因", parsed rejected at(2) at(1))
chk("12 行进 9 行出", parsed records size, 9)
chk("3 行被拒", parsed rejected size, 3)
chk("拒收单里留着原始行", parsed rejected at(0) at(0), "字段不够")

sec("24.3 聚合：Map 计数，但顺序不可依赖")
countBy := method(records, keyBlock,
    m := Map clone
    records foreach(r,
        k := keyBlock call(r)
        if(m hasKey(k), m atPut(k, m at(k) + 1), m atPut(k, 1))
    )
    m
)
byPath := countBy(parsed records, block(r, r path))
byStatus := countBy(parsed records, block(r, r status asString))
show("不同路径数", byPath size)
show("不同状态码数", byStatus size)
show("路径计数（排序后）", byPath keys sort map(k, k .. "=" .. byPath at(k) asString) join(" "))
show("状态码计数（排序后）", byStatus keys sort map(k, k .. "=" .. byStatus at(k) asString) join(" "))
show("Map 默认 asString 会带地址，所以永远不直接打它",
     (byPath asString containsSeq("0x")))
chk("5 个不同路径", byPath size, 5)
chk("/index 出现 4 次", byPath at("/index"), 4)
chk("5 个不同状态码", byStatus size, 5)
chk("200 出现 5 次", byStatus at("200"), 5)
// 想按「计数降序、同分按键升序」排：比较器必须是两参的块
rank := method(m,
    pairs := m keys sort map(k, list(k, m at(k)))
    pairs sortBy(block(x, y,
        if(x at(1) != y at(1), x at(1) > y at(1), x at(0) < y at(0))
    )
)
)
show("路径排行", rank(byPath) map(p, p at(0) .. "(" .. p at(1) asString .. ")") join(" "))
show("状态码排行", rank(byStatus) map(p, p at(0) .. "(" .. p at(1) asString .. ")") join(" "))
chk("排行第一是 /index", rank(byPath) at(0) at(0), "/index")
chk("排行按计数降序", rank(byPath) at(0) at(1), 4)
chk("同分时按键升序（/login 在 /about 之前，/item 在 /missing 之前）",
    rank(byPath) map(p, p at(0)) join(","), "/index,/login,/about,/item,/missing")

sec("24.4 渲染：用对齐拼出确定性表格")
// 两参形式的绑定顺序是「先下标、后值」：map(i, v, 体) —— 和大多数语言相反！
// 写反不会报错，只是 i 拿到值、v 拿到下标，最后在 at(i) 上炸。
// 单参形式 map(v, 体) 里的 v 是值（没有下标）。
tableRow := method(cols, widths,
    cols map(i, v, v asString alignLeft(widths at(i))) join("")
)
pathTable := method(m,
    header := tableRow(list("路径", "次数"), list(20, 6))
    rule := "-" repeated(26)
    body := rank(m) map(p, tableRow(list(p at(0), p at(1)), list(20, 6)))
    lines := list(header, rule)
    body foreach(l, lines append(l))
    lines
)
rendered := pathTable(byPath)
rendered foreach(l, writeln("  ", l))
show("表格行数（表头 + 分隔线 + 5 行数据）", rendered size)
chk("表头 + 分隔线 + 数据行", rendered size, 7)
chk("每行都是 26 个码点宽", rendered select(i, v, v size != 26) size, 0)
chk("表头以「路径」开头", rendered at(0) beginsWithSeq("路径"), true)
chk("表头右列是补齐到 6 码点的「次数」", rendered at(0) endsWithSeq("次数    "), true)

sec("24.5 汇总指标：算平均数与最大值")
totalMs := 0
maxMs := 0
maxMsPath := ""
parsed records foreach(r,
    totalMs = totalMs + r ms
    if(r ms > maxMs, maxMs = r ms; maxMsPath = r path)
)
slowCount := parsed records select(r, r ms >= 90) size
errorCount := parsed records select(r, r status >= 400) size
show("总耗时（ms）", totalMs)
show("平均耗时（ms，整数）", (totalMs / parsed records size) floor)
show("最慢的一条（ms）", maxMs)
show("最慢的那条是谁", maxMsPath)
show("耗时 ≥ 90ms 的条数", slowCount)
show("4xx/5xx 条数", errorCount)
chk("总耗时是 9 条之和", totalMs, 12 + 15 + 93 + 11 + 240 + 88 + 7 + 13 + 5)
chk("平均耗时取整", (totalMs / parsed records size) floor, 53)
chk("最慢的是 240ms", maxMs, 240)
chk("最慢的是 /index", maxMsPath, "/index")
chk("耗时 ≥ 90ms 的有 2 条", slowCount, 2)
chk("4xx/5xx 一共 3 条", errorCount, 3)

sec("24.6 持久化：serialized 落盘、读回来、往返校验")
report := Map clone
report atPut("total", parsed records size)
report atPut("rejected", parsed rejected size)
report atPut("maxMs", maxMs)
report atPut("paths", byPath)
report atPut("ranking", rank(byPath) map(p, p at(0)))

reportPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_ch24_report.io")
reportFile := File with(reportPath)
reportFile remove
// 又一次 asUTF8：setContents 写的是字符串的内部表示，含非 ASCII 会变 4 字节一码点
reportFile setContents(report serialized asUTF8)
show("落盘字节数 > 0", reportFile size > 0)
show("落盘文件里有地址吗", (reportFile contents containsSeq("0x")))
loaded := doString(reportFile contents)
show("读回来的 type", loaded type)
show("读回来的 total", loaded at("total"))
show("读回来的 ranking", loaded at("ranking"))
reportFile remove
show("临时文件已经删掉", File with(reportPath) exists not)
chk("读回来还是 Map", loaded type asString, "Map")
chk("total 往返一致", loaded at("total"), parsed records size)
chk("嵌套的 Map 也往返一致", loaded at("paths") at("/index"), 4)
chk("List 也往返一致", loaded at("ranking") join(","), "/index,/login,/about,/item,/missing")
chk("临时文件已清理", File with(reportPath) exists, false)

sec("24.7 命令行入口：System args 与子命令分派")
// System args 是 C 风格 argv：args[0] 是脚本路径
show("System args size", System args size)
show("args[0] 是脚本自己", System args at(0) endsWithSeq("24_capstone.io"))
show("System launchScript 就是 args[0]", System launchScript == System args at(0))
analyze := method(lines,
    p := parseAll(lines)
    // 同样必须 lexicalDo：这里要读局部的 p
    Object clone lexicalDo(
        total := p records size
        rejected := p rejected size
        byStatus := countBy(p records, block(r, r status asString))
    )
)
runCommand := method(name, lines,
    if(name == "analyze", return analyze(lines))
    if(name == "reject", return analyze(lines) rejected)
    if(name == "status", return analyze(lines) byStatus keys sort join(","))
    Exception raise("未知子命令：" .. name)
)
show("子命令 analyze 的 total", (runCommand("analyze", sampleLines)) total)
show("子命令 reject 的结果", runCommand("reject", sampleLines))
show("子命令 status 的结果", runCommand("status", sampleLines))
unknown := try(runCommand("nope", sampleLines))
show("未知子命令的报错", unknown error)
chk("args 只有脚本路径一个元素（由 run-all.sh 这样调用）", System args size, 1)
chk("launchScript 指向脚本自己", System launchScript == System args at(0), true)
chk("分派 analyze", (runCommand("analyze", sampleLines)) total, 9)
chk("分派 reject", runCommand("reject", sampleLines), 3)
chk("未知子命令抛异常而不是静默", unknown error, "未知子命令：nope")
sec("24.8 端到端：一份完整报告")
emitReport := method(lines, title,
    p := parseAll(lines)
    out := List clone
    out append("== " .. title .. " ==")
    out append("收下 " .. p records size asString .. " 行，拒收 " .. p rejected size asString .. " 行")
    byS := countBy(p records, block(r, r status asString))
    rank(byS) foreach(item,
        out append("  HTTP " .. item at(0) .. "  " .. item at(1) asString .. " 次")
    )
    out
)
emitReport(sampleLines, "访问日志速览") foreach(l, writeln(l))
reportLines := emitReport(sampleLines, "访问日志速览")
chk("报告 7 行（标题 + 计数 + 5 个状态码）", reportLines size, 7)
chk("第一行是标题", reportLines at(0), "== 访问日志速览 ==")
chk("第二行是收/拒计数", reportLines at(1), "收下 9 行，拒收 3 行")
chk("状态码按次数降序", reportLines at(2), "  HTTP 200  5 次")
chk("最后一行是 500", reportLines at(6), "  HTTP 500  1 次")

sec("24.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 24 结束 ====")
if(fails != 0, System exit(1))
