// ============================================================
// 16_text.io —— 第 16 章：文本处理
// 运行：io examples/16_text/16_text.io
//
// Sequence 上的文本操作。三条必须记住的事：
//   1. 字符串字面量是**不可变**的：strip / replaceSeq / uppercase 这些
//      就地方法直接抛 'xxx' cannot be called on an immutable Sequence，
//      要先 asMutable（而且没有 asImmutable，也没有 replaceSeqInPlace）。
//   2. 编码按内容自动升级：纯 ASCII → uint8、含中文 → uint32；
//      size 数码点、sizeInBytes 数字节、asUTF8 size 才是 UTF-8 字节数。
//      注意读写文件时这里就是第 14 章那个「56 还是 18」的来源。
//   3. interpolate 只对纯 ASCII 安全：中文前缀会丢尾巴、表达式里带括号
//      会**段错误**（rc=139，见下面注释）——本文件里绝不真跑那一条。
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
// 单行展示一块文本：] 里就是原文，避免换行把输出撑散
br := method(s, "[" .. s .. "]")

writeln("==== 16 开始 ====")

sec("16.1 字面量不可变：asMutable 与就地方法")
raw := "  Io Text  "
show("字面量的类型", raw type)
show("isMutable", raw isMutable)
e := try(raw strip)
show("直接 strip 抛异常", e type asString == "Exception")
show("异常消息原文", e error)
show("Sequence 有 asImmutable 吗（没有）", Sequence hasSlot("asImmutable"))
m := raw asMutable
show("asMutable 之后 isMutable", m isMutable)
show("就地 strip 的返回值", br(m strip))
show("同一个对象已经被改掉了", br(m))
chk("不可变字面量上 strip 会抛", (try(raw lstrip) type asString == "Exception"), true)
chk("asMutable 之后 strip 生效", ("  x  " asMutable strip), "x")

sec("16.2 编码三件套与 at(i)：码点、字节、字符")
s := "中文 abc"
show("itemType（含中文 → uint32）", s itemType)
show("size（数的是码点）", s size)
show("sizeInBytes", s sizeInBytes)
show("asUTF8 size（才是 UTF-8 字节数）", (s asUTF8) size)
show("asUTF8 之后的 itemType", (s asUTF8) itemType)
ascii := "abc"
show("纯 ASCII 的 itemType", ascii itemType)
show("纯 ASCII 的 size == sizeInBytes", ascii size == ascii sizeInBytes)
chk("中文串每码点 4 字节", s sizeInBytes, s size * 4)
chk("asUTF8 之后是字节串", (s asUTF8) itemType asString, "uint8")
c := s at(0)
show("s at(0) 的类型", c type)
show("s at(0) 的值（Unicode 码点）", c)
show("s at(0) asCharacter", c asCharacter)
show("asUTF8 之后 at(0) 给的是一个字节", (s asUTF8) at(0))
chk("at(0) 是 Number", c type asString, "Number")
chk("码点 20013 就是「中」", c, 20013)

sec("16.3 interpolate 的三个坑（段错误那条只写在注释里）")
x := 3
show("纯 ASCII 模板正常", ("n = #{1 + 2}" interpolate))
show("只含 ASCII 的模板 + .. 拼接，也正常", ("n = " .. "#{1 + 2}" interpolate))
// ↓ 下面这行如果去掉注释并运行，会直接把解释器打挂：rc=139（段错误），
//   而且 stdout/stderr 什么都不打。这就是本示例不敢真跑它的原因。
//   "中文#{(1 + 2)}" interpolate
show("中文前缀：结果尾巴被吃掉", br("中文#{1 + 2}" interpolate))
show("它只返回了 3 个字符", ("中文#{1 + 2}" interpolate) size)
bad := try("中文#{list(1,2) size}" interpolate)
show("非 ASCII 前缀 + 标识符 → 抛异常", bad type asString == "Exception")
show("异常消息原文", bad error)
show("替代写法：.. 接 asString", "n = " .. x asString)
chk("纯 ASCII 模板给出 n = 3", ("n = #{1 + 2}" interpolate), "n = 3")
chk("中文前缀模板只拿到 3 个字符", ("中文#{1 + 2}" interpolate) size, 3)

sec("16.4 切分：split 保留空段，splitNoEmpties 不保留")
show("\"a,b,,c\" split(\",\") 的元素数", ("a,b,,c" split(",")) size)
show("内容（空段被保留）", ("a,b,,c" split(",")) asString)
show("splitNoEmpties(\",\") 的元素数", ("a,b,,c" splitNoEmpties(",")) size)
show("内容", ("a,b,,c" splitNoEmpties(",")) asString)
show("\"a b  c\" split（按空白切，空段照留）", ("a b  c" split) asString)
show("它的元素数", ("a b  c" split) size)
show("splitNoEmpties 的元素数", ("a b  c" splitNoEmpties) size)
show("按换行切", ("l1\nl2\nl3" split("\n")) asString)
// 最要命的一条：**不传分隔符**时 split 是按**字节**扫空白的，不是按码点。
// 只要某个码位的低位字节落在 \t\n\v\f\r 或空格里，它就会被当成分隔符切开。
show("\"上\" 的码位与低字节", list("上" at(0), "上" at(0) % 256) asString)
show("\"上\" split（低字节 0x0A 被当成换行）", ("上" split) asString)
show("\"ab上cd\" split（在 上 中间被切开）", ("ab上cd" split) asString)
show("\"字段不够\" split（不 的低字节是 0x0D）", ("字段不够" split) asString)
show("\"上\" split(\" \")（显式给分隔符就没事）", ("上" split(" ")) asString)
chk("两个连续逗号留下一个空段", ("a,b,,c" split(",")) size, 4)
chk("双空格也留下空段", ("a b  c" split) size, 4)
chk("无参 split 在非 ASCII 上是错的", ("ab上cd" split) size, 2)
chk("显式给分隔符才安全", ("上" split(" ")) asString, "list(\"上\")")

sec("16.5 查找与替换")
w := "banana"
show("findSeq(\"a\") 给第一个下标", w findSeq("a"))
show("reverseFindSeq(\"a\") 给最后一个（没有 findLastSeq）", w reverseFindSeq("a"))
show("Sequence 有 findLastSeq 吗（没有）", Sequence hasSlot("findLastSeq"))
show("找不到给 nil", w findSeq("zz") == nil)
show("occurrencesOfSeq(\"a\")", w occurrencesOfSeq("a"))
show("containsSeq(\"nan\")", w containsSeq("nan"))
show("beginsWithSeq(\"ban\")", w beginsWithSeq("ban"))
show("endsWithSeq(\"na\")", w endsWithSeq("na"))
show("Sequence 有 replaceSeqInPlace 吗（没有，replaceSeq 本身就是就地）", Sequence hasSlot("replaceSeqInPlace"))
bad2 := try(w replaceSeq("a", "o"))
show("对字面量调 replaceSeq 抛异常", bad2 type asString == "Exception")
show("异常消息原文", bad2 error)
show("asMutable 之后再 replaceSeq", "banana" asMutable replaceSeq("a", "o"))
show("replaceFirstSeq 只换第一个", "banana" asMutable replaceFirstSeq("a", "o"))
chk("findSeq 给 1", w findSeq("a"), 1)
chk("reverseFindSeq 给 5", w reverseFindSeq("a"), 5)
chk("a 出现 3 次", w occurrencesOfSeq("a"), 3)

sec("16.6 切片、大小写、对齐")
show("exSlice(1, 3)（左闭右开）", "abcdef" exSlice(1, 3))
show("exSlice(0, -1)", "abcdef" exSlice(0, -1))
show("exSlice(-3, -1)", "abcdef" exSlice(-3, -1))
show("exSlice(2, 2) 是空串", br("abcdef" exSlice(2, 2)))
show("asUppercase（非就地）", "AbC" asUppercase)
show("asLowercase", "AbC" asLowercase)
show("中文不受大小写影响", "中文abc" asUppercase)
show("reverse（按码点整体反转）", "abc" reverse)
show("中文也一起反转", "中文abc" reverse)
show("strip 家族：strip / lstrip / rstrip（没有 stripLeft/stripRight）", Sequence hasSlot("stripLeft"))
show("strip", br("  ab  " asMutable strip))
show("lstrip", br("  ab  " asMutable lstrip))
show("rstrip", br("  ab  " asMutable rstrip))
show("alignLeft(5)", br("ab" alignLeft(5)))
show("alignRight(5)", br("ab" alignRight(5)))
show("alignCenter(6)", br("ab" alignCenter(6)))
show("asCapitalized", "hello world" asCapitalized)
chk("exSlice 左闭右开", "abcdef" exSlice(1, 3), "bc")
chk("alignLeft 补齐到 5 列", "ab" alignLeft(5) size, 5)
chk("alignRight 右对齐", "ab" alignRight(5), "   ab")

sec("16.7 与 List / Number 互转")
show("asList", "abc" asList)
show("asList 的类型", "abc" asList type)
show("List asString", list(1, 2, 3) asString)
show("List join(\"-\")", list("a", "b", "c") join("-"))
show("字符串 asNumber", "42" asNumber)
show("带 0x 前缀也认", "0x10" asNumber)
show("Number asString", 42 asString)
show("小数 asString", 3.5 asString)
show("中文 asNumber 给 nan，不抛异常", "中文" asNumber)
chk("asList 得到 3 个元素", "abc" asList size, 3)
chk("asNumber 认识十六进制", "0x10" asNumber, 16)
chk("List join 拼回来", list("a", "b", "c") join("-"), "a-b-c")

sec("16.8 中文的排序与比较")
words := list("中", "啊", "b", "A", "1") sort
show("sort 之后的顺序", words asString)
show("逐个看它们的码点", words map(c, c at(0)) asString)
show("\"中\" > \"啊\"", "中" > "啊")
show("结论：按 Unicode 码点排，不是拼音", true)
chk("最小的在最前（1 < A < b < 中 < 啊）", words at(0), "1")
chk("码点 20013 的「中」排在码点 21834 的「啊」前面", words at(3), "中")
chk("中 不大于 啊", "中" > "啊", false)

sec("16.9 自检")
chk("16 自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 16 结束 ====")
if(fails != 0, System exit(1))
