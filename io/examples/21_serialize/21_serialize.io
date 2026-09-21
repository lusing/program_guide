// ============================================================
// 21_serialize.io —— 第 21 章：序列化与持久化
// 运行：io examples/21_serialize/21_serialize.io
//
// Io 的序列化只有一条路：Object 上的 serialized 槽（io/Serialize.io）。
// 它把对象写成一串**可回读的 Io 源码**。本章的实测结论有一条很扎人：
// 这个实现只对「没有本地槽」的对象成立 —— 一旦对象有槽，它自己会递归到栈溢出。
// 另外：没有 Serialize 对象（toString/toObject 都不存在）、没有版本号、
// 没有循环引用检测（SerializationStream 里的 seen 是死代码）。
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

writeln("==== 21 开始 ====")

sec("21.1 serialized 是唯一入口：没有 Serialize 对象")
// 有 serialized（对象槽）和 justSerialized（写进流），但没有 Serialize 这个对象。
show("Object 上有 serialized", Object hasSlot("serialized"))
show("Object 上有 justSerialized", Object hasSlot("justSerialized"))
show("Object 上有 serializedSlots", Object hasSlot("serializedSlots"))
show("Lobby 上有 Serialize 这个槽", Lobby hasSlot("Serialize"))
show("Lobby 上有 SerializationStream 这个槽", Lobby hasSlot("SerializationStream"))
show("try(Serialize toString(list(1))) 的结果", (try(Lobby doString("Serialize toString(list(1))"))) type)
show("同上，异常消息", (try(Lobby doString("Serialize toObject(\"x\")"))) error)
show("serialized 的参数是流，不是 nil 才用它", (Object getSlot("serialized")) code)
chk("序列化入口只有 serialized", Object hasSlot("serialized"), true)
chk("没有 Serialize 对象", Lobby hasSlot("Serialize"), false)
chk("SerializationStream 是缓冲区对象", SerializationStream type, "SerializationStream")
chk("序列化流上的 seen 槽存在但没人用（见 21.5）",
    (SerializationStream clone hasSlot("seen")), true)

sec("21.2 各类型的产物：写出来的是可回读的 Io 源码")
// 每种类型有自己的 justSerialized：数字直接写、串加引号、List 写 list(...)、
// Map 写 Map clone do(atPut(...))、Block 直接写代码。
show("数字 serialized", 42 serialized)
show("浮点 serialized", 3.5 serialized)
show("nil serialized", nil serialized)
show("true serialized", true serialized)
show("false serialized", false serialized)
show("字符串 serialized", "hi" serialized)
show("带引号的串 serialized", "say \"hi\"" serialized)
show("List serialized", list(1, 2, 3) serialized)
show("嵌套 List serialized", list(list(1, 2), 3) serialized)
show("Map serialized", (Map clone atPut("b", 2) atPut("a", 1)) serialized)
show("Block serialized", (block(v, v + 1)) serialized)
show("固定 Date serialized",
     (Date clone setYear(2020) setMonth(1) setDay(2) setHour(3) setMinute(4) setSecond(5)) serialized)
chk("数字写自己", 42 serialized asString, "42")
chk("nil/true/false 写出来就是各自的字面量",
    list(nil serialized, true serialized, false serialized) asString,
    "list(\"nil\", \"true\", \"false\")")
chk("字符串被加上引号，所以可回读", "hi" serialized asString, "\"hi\"")
chk("List 的产物以 list( 开头", (list(1, 2, 3) serialized containsSeq("list(1, 2, 3)")), true)
chk("Map 的产物是 Map clone do(atPut(...))",
    ((Map clone atPut("a", 1)) serialized containsSeq("Map clone do(atPut(")), true)
chk("Block 写的是代码，不带作用域", (block(v, v + 1)) serialized asString, "block(v, v +(1))\n")
// 嵌套 List 的产物里，内层的结束分号留在了参数位置 —— 好在 Io 容忍它
nested := list(list(1, 2), 3)
show("嵌套 List 的产物（内层多了个分号）", nested serialized)
show("回读后与原值相等", (Lobby doString(nested serialized)) == nested)
show("但它 asString 出来把内层的数字印成带引号的串", Lobby doString(nested serialized))
show("其实内层元素还是 Number", ((Lobby doString(nested serialized)) at(0) at(0)) isKindOf(Number))
chk("嵌套 List 的产物内层多了个分号",
    (nested serialized containsSeq("list(1, 2);")), true)
chk("可它回读后仍然相等（Io 容忍这个分号）",
    (Lobby doString(nested serialized)) == nested, true)
chk("内层元素仍然是 Number",
    ((Lobby doString(nested serialized)) at(0) at(0)) isKindOf(Number), true)
chk("List asString 会把嵌套里的数字印成字符串（显示假象）",
    ((Lobby doString(nested serialized)) asString containsSeq("list(\"1\", \"2\")")), true)

sec("21.3 往返：proto 是「同一个」还是「重新求值」")
// 产物是 `<proto 名> clone do(...)`，回读时靠 Lobby doString 重新求值，
// 所以 proto 是**按名字重新查找**的：名字还在 → 同一个 proto（isIdenticalTo 为真）。
Point := Object clone
pt := Point clone
pointText := pt serialized
show("pt type", pt type)
show("pt serialized 原文", pointText)
show("回读后 proto 是同一个 Point", (Lobby doString(pointText)) proto isIdenticalTo(Point))
// 把名字抢走，回读结果就指向新对象 —— 这就是「按名字求值」的直接证据
oldPoint := Point
Point = Object clone
show("重绑定 Point 后，回读仍是老 Point 吗", (Lobby doString(pointText)) proto isIdenticalTo(oldPoint))
show("重绑定 Point 后，回读是新 Point 吗", (Lobby doString(pointText)) proto isIdenticalTo(Point))
show("名字不存在时", (try(Lobby doString("NoSuchProto clone do(\n)\n"))) error)
chk("proto 按名字重新求值", (Lobby doString(pointText)) proto isIdenticalTo(Point), true)
chk("抢走名字后指向新对象", (Lobby doString(pointText)) proto isIdenticalTo(oldPoint), false)
chk("名字不存在就报 does not respond",
    (try(Lobby doString("NoSuchProto clone do(\n)\n"))) error,
    "Object does not respond to 'NoSuchProto'")

sec("21.4 大坑：对象一旦有本地槽，serialized 直接栈溢出")
// 这是本章最重要的实测：Object serialized 只对「没有本地槽」的对象成立。
// serializedSlotsWithNames 里那句 `self getSlot(slotName) serialized(stream)`
// 会让内层 serialized 里的裸消息 justSerialized 解析回父对象，递归到爆栈。
empty := Object clone
show("无本地槽的对象 serialized 原文", "[" .. empty serialized .. "]")
show("无本地槽的对象 slotNames", empty slotNames)
oneSlot := Object clone do(x := 1)
show("有本地槽的对象 slotNames", oneSlot slotNames)
show("有本地槽的对象 serialized 的异常消息", (try(oneSlot serialized)) error)
twoSlots := Object clone do(x := 1; y := "abc")
show("两个槽也一样", (try(twoSlots serialized)) error)
show("嵌套在 List 里的对象也一样",
     (try(list(Object clone do(x := 1)) serialized)) error)
chk("空对象能序列化", (empty serialized containsSeq("Object clone do(")), true)
chk("空对象的产物是 Object clone do()", empty serialized size, 19)
chk("有槽对象爆栈", (try(oneSlot serialized)) error, "Stack overflow: frame depth exceeded 10000")
chk("槽里的对象也爆栈",
    (try(list(Object clone do(x := 1)) serialized)) error,
    "Stack overflow: frame depth exceeded 10000")
// 正解：绕开 Object 的自动遍历，自己点名要哪些槽（serializedSlotsWithNames 是安全的）
st := SerializationStream clone
oneSlot serializedSlotsWithNames(list("x"), st)
show("手工点名槽位就不会爆栈", "[" .. st output .. "]")
chk("自己点名槽位可以工作", st output containsSeq("x := 1"), true)

sec("21.5 循环引用与不可序列化的对象")
// SerializationStream 里有个 seen 槽，看名字是要做「已见过」去重，
// 但全文件里它只在 init 里被赋值一次 —— 没有循环引用检测。
l := list(1, 2)
l append(l)
show("自引用 List 的异常", (try(l serialized)) error)
m := Map clone
m atPut("self", m)
show("自引用 Map 的异常", (try(m serialized)) error)
show("File serialized（路径没进去）", "[" .. (File with("/tmp") serialized) .. "]")
show("File 的 path 是", (File with("/tmp") path))
show("Coroutine serialized 的异常", (try(Coroutine currentCoroutine serialized)) error)
chk("没有循环引用检测，自引用直接爆栈",
    (try(l serialized)) error, "Stack overflow: frame depth exceeded 10000")
chk("File 序列化成功但丢掉了 path", (File with("/tmp") serialized containsSeq("path")), false)
chk("File clone do() 是它唯一的产物", (File with("/tmp") serialized asString),
    "File clone do(\n)\n")
chk("Coroutine 不可序列化",
    (try(Coroutine currentCoroutine serialized)) error,
    "CFunction defined for type Coroutine but called on type Object")

sec("21.6 写进文件再读回来：别忘了 asUTF8")
// File setContents 写的是字符串的**内部表示**；纯 ASCII 产物正好一字一字节，
// 但含中文的串内部是 UCS4，直接写就是每码点 4 字节的垃圾。所以统一 asUTF8。
persist := Map clone
persist atPut("port", 8080)
persist atPut("name", "io-demo")
persist atPut("tags", list("a", "b"))
text := persist serialized
tmpPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_ch21_persist.io")
f := File with(tmpPath)
f remove
f setContents(text asUTF8)
show("写出去的字节数", f size)
show("产物本身的码点数", text size)
back := File with(tmpPath) contents
show("读回来的字节数与产物码点数相同", back size == text size)
reloaded := Lobby doString(back)
show("读回后 port", reloaded at("port"))
show("读回后 name", reloaded at("name"))
show("读回后 tags", reloaded at("tags"))
chk("序列化产物是纯 ASCII", text sizeInBytes, text size)
chk("asUTF8 后字节数与码点数一致", f size, text size)
chk("读回来是同一份数据", reloaded at("name"), "io-demo")
chk("嵌套 List 也能读回来", (reloaded at("tags")) at(1), "b")
f remove
// 反例：不 asUTF8 会写出 4 字节一码点（第 14 章的坑），这里用带中文的串演示
cn := "中文"
f2 := File with(tmpPath)
f2 remove
f2 setContents(cn)
show("含中文的串直接 setContents 的字节数（码点数的 4 倍）", f2 size)
show("它的码点数", cn size)
chk("中文串的内部表示是 UCS4", f2 size, cn size * 4)
chk("asUTF8 才是真正的 UTF-8 字节数", cn asUTF8 size, 6)
f2 remove

sec("21.7 asString 是给人看的，不可逆；自己写一份键值持久化")
// asString 只负责好看：Map 打地址、字符串把引号摘掉，都回读不了。
show("字符串 asString（引号没了）", "hi" asString)
show("它的 serialized（引号还在）", "hi" serialized)
show("doString(\"hi\") 的结果", (try(Lobby doString("hi"))) error)
show("doString(\"hi\" serialized) 的结果", Lobby doString("hi" serialized))
show("Map asString 里有地址", (Map clone atPut("a", 1)) asString containsSeq("0x"))
show("Map serialized 里没有地址", (Map clone atPut("a", 1)) serialized containsSeq("0x"))
// 不带 Serialize 也能持久化：自己定一个白名单格式（键=值，串带引号）
toKV := method(m,
    parts := List clone
    m keys sort foreach(k,
        v := m at(k)
        if(v isKindOf(Number),
            parts append(k .. "=" .. v asString),
            parts append(k .. "=" .. "\"" .. v asString .. "\"")
        )
    )
    parts join("\n")
)
fromKV := method(text,
    out := Map clone
    text split("\n") foreach(line,
        kv := line split("=")
        if(kv size == 2,
            v := kv at(1)
            if(v size > 0 and v at(0) == 34,
                out atPut(kv at(0), v exSlice(1, -1)),
                out atPut(kv at(0), v asNumber)
            )
        )
    )
    out
)
cfg := Map clone
cfg atPut("port", 8080)
cfg atPut("name", "io-demo")
cfg atPut("debug", 1)
enc := toKV(cfg)
writeln("自制的键值格式（键按 sort 排过，顺序确定）：")
writeln(enc)
dec := fromKV(enc)
show("解出来 port 的类型", (dec at("port")) type)
show("解出来 name", dec at("name"))
chk("自制格式可逆且类型保住了", (dec at("port")) isKindOf(Number), true)
chk("字符串原样回来", dec at("name"), "io-demo")
chk("asString 不可逆：引号丢了", (try(Lobby doString("hi"))) error,
    "Object does not respond to 'hi'")
chk("serialized 可逆", Lobby doString("hi" serialized), "hi")

sec("21.8 版本兼容：序列化串里没有版本号")
// 产物就是一句 Io 源码，没有任何「格式版本」字段。这意味着：
//   · 换 Io 版本后旧文件能不能读，取决于那句源码在新 VM 里还解析得出来
//   · 库升级改名（Point 改名 Point2）→ 老文件直接 does not respond
//   · 想稳，就自己带版本（21.7 的白名单格式里加一行 v=1）
big := Map clone atPut("k", list(1, 2, 3))
show("Map 产物里含 version 字样", (big serialized containsSeq("version")))
show("List 产物里含 version 字样", (list(1, 2, 3) serialized containsSeq("version")))
show("Date 产物里含 version 字样",
     ((Date clone setYear(2020)) serialized containsSeq("version")))
show("产物第一行的类型名就是唯一的「格式标记」", (list(1, 2, 3) serialized exSlice(0, 4)))
show("Io 自己的版本号在别处", System version)
chk("serialized 里没有版本字段", (big serialized containsSeq("version")), false)
chk("产物是纯源码，没有魔数头", (list(1, 2, 3) serialized exSlice(0, 5)), "list(")
chk("版本信息只能自己带", (System version isKindOf(Sequence)), true)

sec("21.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 21 结束 ====")
if(fails != 0, System exit(1))
