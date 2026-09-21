// ============================================================
// 04_sequences.io —— 第 04 章：字符串与 Sequence
// 运行：io examples/04_sequences/04_sequences.io
//
// 一条主线：Sequence 是**可变的字节/码点容器**，字符串字面量是它的
// **不可变**特例。所有「就地修改」的方法都只认可变序列。
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

writeln("==== 04 开始 ====")

sec("4.1 不可变字面量：type 都是 Sequence，不可变是个对象标志")
// 别指望靠 type 区分：字面量、Sequence clone、asMutable 三者 type 完全一样
show("\"abc\" type", "abc" type)
show("Sequence clone type", Sequence clone type)
show("\"abc\" asMutable type", "abc" asMutable type)
show("\"abc\" isMutable", "abc" isMutable)
show("\"abc\" asMutable isMutable", "abc" asMutable isMutable)
// String 是 ImmutableSequence 的别名，但它只是个几乎空的 proto，
// 和字面量的 proto 链没有关系（isKindOf 也是 false）
show("String isIdenticalTo(ImmutableSequence)", String isIdenticalTo(ImmutableSequence))
show("ImmutableSequence slotNames", ImmutableSequence slotNames sort)
show("\"abc\" isKindOf(ImmutableSequence)", "abc" isKindOf(ImmutableSequence))
// 就地方法在不可变序列上直接报错，这是本仓库最常踩的一条
e := try("  pad  " strip)
show("try(\"  pad  \" strip) 的异常类型", e type)
show("异常消息", e error)
chk("type 区分不出可变性", "abc" type asString, (Sequence clone) type asString)
chk("不可变是挂在对象上的标志", "abc" isMutable, false)
chk("asMutable 给的是同一个 proto 上的可变副本", "abc" asMutable isMutable, true)
chk("ImmutableSequence 是个空壳 proto", ImmutableSequence slotNames sort asString, "list(\"type\")")
chk("就地方法拒绝不可变串", e error, "'strip' cannot be called on an immutable Sequence")
show("\"  pad  \" asMutable strip", "  pad  " asMutable strip)

sec("4.2 size 数的是码点，sizeInBytes 才是字节")
a := "hello"
b := "héllo"
c := "你好"
show("a size / sizeInBytes / encoding", list(a size, a sizeInBytes, a encoding) asString)
show("b size / sizeInBytes / encoding", list(b size, b sizeInBytes, b encoding) asString)
show("c size / sizeInBytes / encoding", list(c size, c sizeInBytes, c encoding) asString)
show("c asUTF8 size", c asUTF8 size)
chk("纯 ASCII 一字节一码点", a sizeInBytes, a size)
chk("带重音字母升到 ucs2", b itemType, "uint16")
chk("汉字升到 ucs4", c itemType, "uint32")
chk("UTF-8 下汉字 3 字节", c asUTF8 size, 6)

sec("4.3 at 给码点，asCharacter 才给字符")
show("\"Hello\" at(1)", "Hello" at(1))
show("\"Hello\" at(1) asCharacter", "Hello" at(1) asCharacter)
show("\"你好\" at(0)", "你好" at(0))
show("65 asCharacter", 65 asCharacter)
show("\"A\" at(0)", "A" at(0))
chk("ASCII 下码点就是字节值", "A" at(0), 65)
chk("汉字给的是 Unicode 码位", "你好" at(0), 20320)

sec("4.4 切片 exSlice：左闭右开，支持负索引")
s := "abcdef"
show("s exSlice(1, 3)", s exSlice(1, 3))
show("s exSlice(1)", s exSlice(1))
show("s exSlice(-2)", s exSlice(-2))
show("s exSlice(0, -1)", s exSlice(0, -1))
// slice 是被废弃的旧名，调用会往 stdout 打警告（见第 22 章坑位）
show("s exSlice(2, 4) == s at(2)..at(3)", s exSlice(2, 4) == (s at(2) asCharacter .. s at(3) asCharacter))
chk("exSlice 左闭右开", s exSlice(1, 3), "bc")
chk("负索引从尾部算", s exSlice(-2), "ef")

sec("4.5 就地方法的正确姿势：先 asMutable 或 clone")
m := "abc" asMutable
m appendSeq("def")
show("asMutable + appendSeq", m)
show("原字面量不受影响", "abc")
n := Sequence clone appendSeq("  pad  ")
n strip
show("Sequence clone 也是可变序列", n)
show("n size", n size)
chk("asMutable 返回可变副本", ("abc" asMutable isMutable), true)
chk("字面量本身不可变", ("abc" isMutable), false)

sec("4.6 切分与拼接")
csvLine := "a,b,,c"
show("split(\",\")", csvLine split(","))
show("splitNoEmpties(\",\")", csvLine splitNoEmpties(","))
show("\"a b  c\" split", "a b  c" split)
show("list 的 join", list(1, 2, 3) join("-"))
show("\"1,2\".asList", "1,2" split(","))
show("两段拼接用 ..", "abc" .. "def")
show(".. 的右侧会被 asString", "n=" .. 7)
chk("split 保留空段", csvLine split(",") size, 4)
chk("splitNoEmpties 去掉空段", csvLine splitNoEmpties(",") size, 3)
chk("不传分隔符按空白切，但空段照留", "a b  c" split size, 4)
chk("split() 与 splitNoEmpties() 的差别就在空段", "a b  c" splitNoEmpties size, 3)

sec("4.7 查找、替换、大小写、对齐")
t := "Hello, Io"
show("findSeq(\"Io\")", t findSeq("Io"))
show("findSeq(\"zz\")", t findSeq("zz"))
show("occurrencesOfSeq(\"o\")", t occurrencesOfSeq("o"))
show("beginsWithSeq(\"Hello\")", t beginsWithSeq("Hello"))
show("endsWithSeq(\"Io\")", t endsWithSeq("Io"))
show("containsSeq(\"lo,\")", t containsSeq("lo,"))
show("asUppercase", t asUppercase)
show("asLowercase", t asLowercase)
show("repeated(2)", "ab" repeated(2))
show("alignRight(8, \".\")", "ab" alignRight(8, "."))
show("alignLeft(8, \".\")", "ab" alignLeft(8, "."))
show("replaceSeq 需要可变串", "a-b-c" asMutable replaceSeq("-", "+"))
chk("找不到返回 nil", t findSeq("zz"), nil)
chk("replaceSeq 返回可变串自己", "a-b-c" asMutable replaceSeq("-", "+"), "a+b+c")

sec("4.8 陷阱：interpolate 只对纯 ASCII 安全")
// 插值本身没问题：
show("\"1 + 2 = #{1 + 2}\" interpolate", "1 + 2 = #{1 + 2}" interpolate)
// 但一旦串里有非 ASCII 字节，本构建的 #{} 定位就错位。
// 下面三句请逐句取消注释单独跑（第三句会直接段错误，把整个进程带走）：
//   writeln("中文#{1 + 2}" interpolate)              → 中文1      （丢了 " + 2"）
//   writeln("中文#{list(1,2) size}" interpolate)     → 报 'l' 不响应（chunk 被截成 l）
//   writeln("中文#{(1 + 2)}" interpolate)            → 段错误，退出码 139
// 结论：带中文的文案不要用 interpolate，用 writeln 的多参数形式或 ..
writeln("中文文案改用多参数：", "值 = ", 1 + 2)
writeln("中文文案改用 ..：", "值 = " .. (1 + 2) asString)
chk("多参数形式可以安全带中文", "值 = " .. 3 asString, "值 = 3")

sec("4.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 04 结束 ====")
if(fails != 0, System exit(1))
