// ============================================================
// 10_maps.io —— 第 10 章：映射
// 运行：io examples/10_maps/10_maps.io
//
// Map 是 Io 的哈希表：atPut / at / hasKey / removeAt / keys / values / foreach。
// 缺键不报错，at 给 nil；键必须是 Sequence（字符串），拿数字当键直接抛异常。
// Map 同时继承了 Object 的槽机制：`m x := 1` 建的**不是条目**而是普通槽，
// size 和 hasKey 都看不见它。keys / values 的顺序不做任何承诺——同一进程里
// 同样插入序是稳定的，换个插入顺序就变，所以凡是要打印的地方都得先 sort。
// Map 默认 asString 打的是 Map_0x...（内存地址），永远不要打进输出。
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

writeln("==== 10 开始 ====")

// 本章反复用到两个确定性打印工具：kv 把表拼成 "k=v,..."（键排过序），
// rankedPairs 把表转成 [键, 值] 列表并按 value 降序、同值按 key 升序排好。
kv := method(m, (m keys sort) map(k, k .. "=" .. (m at(k) asString)) join(","))
rankedPairs := method(m,
    (m keys map(k, list(k, m at(k)))) sortBy(block(p, q,
        if(p at(1) == q at(1), (p at(0)) < (q at(0)), (p at(1)) > (q at(1)))))
)

sec("10.1 Map clone 建表：atPut 写入、at 读取、hasKey 判断、size 计数")
m := Map clone
show("空表的 size", m size)
show("空表的 isEmpty", m isEmpty)
m atPut("b", 2)
m atPut("a", 1)
m atPut("c", 3)
show("写入三个之后的 size", m size)
show("m at(\"a\")", m at("a"))
show("hasKey(\"a\") / hasKey(\"zz\")", list(m hasKey("a"), m hasKey("zz")) join(","))
show("hasValue(3) / hasValue(9)", list(m hasValue(3), m hasValue(9)) join(","))
show("排序后的键", m keys sort join(","))
show("排序后的值", m values sort join(","))
chk("size 数的是条目", m size, 3)
chk("hasKey 能分辨有无", list(m hasKey("a"), m hasKey("zz")) join(","), "true,false")
chk("keys 排完是 a,b,c", m keys sort join(","), "a,b,c")

sec("10.2 缺键给 nil、键必须是 Sequence、删不存在的键不报错")
m = Map clone
m atPut("a", 1)
show("m at(\"zz\") 是 nil 吗", (m at("zz")) isNil)
e := try(m atPut(1, "x"))
show("拿数字当键的异常消息", e error)
show("atIfAbsentPut(\"b\", 9) 返回", m atIfAbsentPut("b", 9))
show("再 atIfAbsentPut(\"b\", 100) 返回的是老值", m atIfAbsentPut("b", 100))
show("这时候的 size", m size)
r := m removeAt("zz")
show("删一个不存在的键之后 size 还是", m size)
show("removeAt 返回的是表自己吗", r isIdenticalTo(m))
m removeAt("a")
show("再删掉 a，剩下的键是", m keys sort join(","))
chk("缺键给 nil 而不是抛异常", m at("zz") asString, "nil")
chk("数字键会被拒绝", e error, "argument 0 to method 'atPut' must be a Sequence, not a 'Number'")
chk("atIfAbsentPut 不覆盖老值", m atIfAbsentPut("b", 100), 9)
chk("removeAt 返回自身，可以接着链式调用", r isIdenticalTo(m), true)

sec("10.3 Map 默认 asString 打的是地址，永远不要打进输出")
m = Map clone
m atPut("x", 1)
n := Map clone
n atPut("x", 1)
show("m asString 里有 Map_0x 这种地址前缀吗", (m asString) containsSeq("Map_0x"))
show("内容一样的两张表，asString 相同吗", (m asString) == (n asString))
show("要确定性就自己拼", kv(m))
chk("默认 asString 带地址前缀", (m asString) containsSeq("Map_0x"), true)
chk("内容一样但地址不同", (m asString) == (n asString), false)
chk("自己拼出来的字符串是确定的", kv(m), "x=1")

sec("10.4 keys / values 的顺序不可依赖：先 sort 再打")
a := Map clone
list("a", "b", "c", "d", "e", "f") foreach(k, a atPut(k, 1))
b := Map clone
list("a", "b", "c", "d", "e", "f") foreach(k, b atPut(k, 1))
c := Map clone
list("f", "e", "d", "c", "b", "a") foreach(k, c atPut(k, 1))
show("同一进程、同样插入序的两份表，keys 顺序相同吗", (a keys join(",")) == (b keys join(",")))
show("换一个插入顺序，keys 顺序还相同吗", (a keys join(",")) == (c keys join(",")))
show("keys 顺序就是插入顺序吗", (a keys join(",")) == "a,b,c,d,e,f")
show("sort 之后两份表一定一样吗", (a keys sort join(",")) == (c keys sort join(",")))
show("排序后的键才是可以打的东西", a keys sort join(","))
chk("插入顺序不同，keys 顺序就不同", (a keys join(",")) == (c keys join(",")), false)
chk("keys 不等于插入顺序", (a keys join(",")) == "a,b,c,d,e,f", false)
chk("sort 之后内容可比", (a keys sort join(",")) == (c keys sort join(",")), true)

sec("10.5 遍历：foreach(k, v, ...) 与 keys sort + foreach")
m = Map clone
m atPut("b", 2)
m atPut("a", 1)
m atPut("c", 3)
total := 0
m foreach(k, v, total = total + v)
show("foreach 求和（与顺序无关，可以放心用）", total)
lines := List clone
(m keys sort) foreach(k, lines append(k .. ":" .. (m at(k) asString)))
show("keys sort 之后逐项收集", lines join(","))
show("m map(k, v, ...) 的结果排序后", (m map(k, v, v * 10)) sort join(","))
show("select 出来的也是 Map，键排序后", (m select(k, v, v != 2)) keys sort join(","))
chk("foreach 求和", total, 6)
chk("排序之后收集结果确定", lines join(","), "a:1,b:2,c:3")
chk("map 的结果排序后确定", (m map(k, v, v * 10)) sort join(","), "10,20,30")

sec("10.6 Map 与对象：:= 建的是槽，atPut 建的才是条目")
m = Map clone
m atPut("a", 1)
m b := 2
show("m size（只数条目）", m size)
show("hasKey(\"a\") / hasKey(\"b\")", list(m hasKey("a"), m hasKey("b")) join(","))
show("hasSlot(\"a\") / hasSlot(\"b\")", list(m hasSlot("a"), m hasSlot("b")) join(","))
show("m at(\"b\") 是 nil 吗", (m at("b")) isNil)
show("但 m b 能取到", m b)
show("keys 里只有条目键", m keys sort join(","))
o := m asObject
show("asObject 之后的 type", o type)
show("o a（条目变成了槽）", o a)
show("Object clone do(...) 才是造对象的写法，槽有", (Object clone do(x := 1; y := 2)) slotNames sort join(","))
chk(":= 不进哈希表", m size, 1)
chk(":= 建的是普通槽", m hasSlot("b"), true)
chk("asObject 把条目变成槽", o a, 1)
chk("Object clone do 里用分号分隔多个槽", (Object clone do(x := 1; y := 2)) slotNames sort join(","), "x,y")

sec("10.7 与 List 互转、按 value 排序、分组、merge")
m = Map clone
m atPut("x", 3)
m atPut("y", 1)
m atPut("z", 3)
show("asList 每项是 [键, 值]，排序后拼出来", (m asList) map(p, (p at(0)) .. ":" .. (p at(1) asString)) sort join(" "))
show("按 value 降序、同值按 key 升序", rankedPairs(m) map(p, (p at(0)) .. ":" .. (p at(1) asString)) join(","))
show("select 留下 value > 1，键是", (m select(k, v, v > 1)) keys sort join(","))
show("map 只取 value * 10，返回的是 List", (m map(k, v, v * 10)) sort join(","))
show("detect 返回 [键, 值]", (m detect(k, v, v == 1)) asString)
nn := Map clone
nn atPut("z", 9)
nn atPut("w", 4)
show("merge 返回新表", (m merge(nn)) keys sort join(","))
show("m 自己没被改", m keys sort join(","))
g := list(1, 2, 3, 4, 5) groupBy(v, (v % 2) asString)
show("groupBy 的键（是 asString 出来的字符串）", g keys sort join(","))
show("所以偶数齿在 \"0\"、奇数齿在 \"1\"", list(g at("0"), g at("1")) join(" "))
chk("asList 是 [键, 值] 形状", (m asList) map(p, p at(0)) sort join(","), "x,y,z")
chk("按 value 排序的结果确定", rankedPairs(m) map(p, (p at(0)) .. ":" .. (p at(1) asString)) join(","), "x:3,z:3,y:1")
chk("Map 的 select 返回 Map", (m select(k, v, v > 1)) isKindOf(Map), true)
chk("Map 的 map 返回 List", (m map(k, v, v * 10)) isKindOf(List), true)
chk("merge 不改原表", m keys sort join(","), "x,y,z")
chk("groupBy 返回 Map", g isKindOf(Map), true)
chk("groupBy 的键是字符串", list(g at("0"), g at("1")) join(" "), "list(2, 4) list(1, 3, 5)")

sec("10.8 实战：词频计数器")
words := list("io", "is", "small", "io", "is", "io")
counts := Map clone
words foreach(w,
    c := counts at(w)
    if(c == nil, c = 0)
    counts atPut(w, c + 1)
)
show("不同词的个数", counts size)
show("总词数（values 求和）", counts values reduce(x, y, x + y))
show("按词排序输出", kv(counts))
show("按次数降序、同次数按词升序", rankedPairs(counts) map(p, (p at(0)) .. "x" .. (p at(1) asString)) join(","))
chk("一共三个不同的词", counts size, 3)
chk("一共六个词", counts values reduce(x, y, x + y), 6)
chk("io 出现 3 次", counts at("io"), 3)
chk("排第一的是 io", rankedPairs(counts) at(0) at(0), "io")

sec("10.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 10 结束 ====")
if(fails != 0, System exit(1))
