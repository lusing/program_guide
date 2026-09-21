// ============================================================
// 03_numbers.io —— 第 03 章：数值与运算
// 运行：io examples/03_numbers/03_numbers.io
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

writeln("==== 03 开始 ====")

sec("3.1 只有一种数值类型：Number")
// Io 不分 int/float 两个类，都是 Number；proto 都是同一个 Number 原型
show("1   isKindOf(Number)", 1 isKindOf(Number))
show("1.0 isKindOf(Number)", 1.0 isKindOf(Number))
show("1   proto isIdenticalTo(Number)", 1 proto isIdenticalTo(Number))
show("1.0 proto isIdenticalTo(Number)", 1.0 proto isIdenticalTo(Number))
show("1 asString  ", 1 asString)
// 陷阱：浮点的 asString 不补小数点
show("1.0 asString", 1.0 asString)
show("1.5 asString", 1.5 asString)
show("1 == 1.0", 1 == 1.0)
show("1 isIdenticalTo(1)", 1 isIdenticalTo(1))
chk("整数与浮点值相等", 1 == 1.0, true)
chk("1.0 打印出来和 1 一样", 1.0 asString == "1", true)

sec("3.2 除法永远给浮点，取模带符号")
show("7 / 2", 7 / 2)
show("7 / 2.0", 7 / 2.0)
show("7 % 2", 7 % 2)
show("-7 / 2", -7 / 2)
show("-7 % 3", -7 % 3)
show("7 % -3", 7 % -3)
chk("没有整除运算符", 7 / 2, 3.5)
chk("取模跟被除数符号走（同 C）", -7 % 3, -1)

sec("3.3 运算符优先级与结合性：** 是左结合")
show("2 + 3 * 4", 2 + 3 * 4)
show("(2 + 3) * 4", (2 + 3) * 4)
show("10 - 2 - 3", 10 - 2 - 3)
show("2 ** 3 ** 2", 2 ** 3 ** 2)
show("2 ** (3 ** 2)", 2 ** (3 ** 2))
show("2 ** -1", 2 ** -1)
chk("幂运算左结合（与数学惯例相反）", 2 ** 3 ** 2, 64)
chk("指数可以是负数", 2 ** -1, 0.5)

sec("3.4 陷阱：一元负号比消息绑定松")
// -4 abs 解析成 -(4 abs)，不是 (-4) abs
show("-4 abs   ", -4 abs)
show("(-4) abs ", (-4) abs)
show("-4 squared", -4 squared)
chk("要取负数的绝对值必须加括号", (-4) abs, 4)
chk("不加括号就是 -(4 abs)", -4 abs, -4)

sec("3.5 浮点格式化与误差")
show("1 / 3", 1 / 3)
show("(1 / 3) asString(0, 6)", (1 / 3) asString(0, 6))
show("2 sqrt", 2 sqrt)
show("2 sqrt squared", 2 sqrt squared)
show("0.1 + 0.2", 0.1 + 0.2)
// 浮点是 IEEE754 双精度：不要用 == 比较结果
chk("sqrt 再平方不等于原数", 2 sqrt squared == 2, false)
chk("误差量级 1e-16", ((2 sqrt squared - 2) abs) < 1e-15, true)
show("(0.1 + 0.2) == 0.3", (0.1 + 0.2) == 0.3)

sec("3.6 无穷与 NaN")
show("1 / 0", 1 / 0)
show("0 / 0", 0 / 0)
show("(0 / 0) isNan", (0 / 0) isNan)
show("(1 / 0) isNan", (1 / 0) isNan)
show("(0 / 0) == (0 / 0)", (0 / 0) == (0 / 0))
chk("除零不报错，给 inf", (1 / 0) asString, "inf")
chk("NaN 不等于自己", (0 / 0) == (0 / 0), false)
show("Number constants pi", Number constants pi asString(0, 10))
show("Number constants e ", Number constants e asString(0, 10))

sec("3.7 取整族与比较")
show("3.7 floor", 3.7 floor)
show("3.2 ceil ", 3.2 ceil)
// round 是「四舍五入，.5 一律远离零」——不是银行家舍入（不是四舍六入五成双）
show("[3.5 2.5 1.5 0.5 -2.5] round",
     list(3.5 round, 2.5 round, 1.5 round, 0.5 round, (-2.5) round) asString)
show("2.5 floor / 2.5 ceil", list(2.5 floor, 2.5 ceil) asString)
show("5 max(3)", 5 max(3))
show("5 min(3)", 5 min(3))
show("5 minMax(1, 3)", 5 minMax(1, 3))
show("2 between(1, 3)", 2 between(1, 3))
show("7 isEven", 7 isEven)
show("7 isOdd", 7 isOdd)
chk(".5 一律远离零舍入：2.5 得 3（银行家舍入会给 2）", 2.5 round, 3)
chk("负数同理：-2.5 得 -3", (-2.5) round, -3)
chk("floor/ceil 不看符号，分别向 -inf/+inf 走", list(2.5 floor, 2.5 ceil) asString, "list(2, 3)")
chk("Number 没有 truncate，往零取整要自己写", Number hasSlot("truncate"), false)

sec("3.8 进制转换与字符码")
show("255 toBase(16)", 255 toBase(16))
show("42 toBase(2)", 42 toBase(2))
show("97 asHex", 97 asHex)
show("42 asBinary", 42 asBinary)
show("436 asOctal", 436 asOctal)
show("65 asCharacter", 65 asCharacter)
show("\"7\".asNumber + 1", "7" asNumber + 1)
show("\"3.5\" asNumber", "3.5" asNumber)
chk("asHex 会补齐整字节", 7 asHex, "07")
chk("字符串转数字", "12abc" asNumber, 12)

sec("3.9 位运算")
show("6 & 3", 6 & 3)
show("6 | 3", 6 | 3)
show("6 ^ 3", 6 ^ 3)
show("1 << 4", 1 << 4)
show("256 >> 4", 256 >> 4)
show("6 bitwiseAnd(3)", 6 bitwiseAnd(3))
show("6 bitwiseXor(3)", 6 bitwiseXor(3))
show("6 bitwiseComplement", 6 bitwiseComplement)
chk("& | ^ 就是位运算消息的语法糖", 6 & 3, 6 bitwiseAnd(3))

sec("3.10 陷阱：integerMax 是 32 位常量，不是溢出边界")
show("Number integerMax", Number integerMax)
show("Number integerMax + 1", Number integerMax + 1)
show("Number longMax", Number longMax)
// Io 内部按 64 位整数存，拿 32 位常量当边界会得到错误结论
chk("加一不会回绕", Number integerMax + 1 > Number integerMax, true)

sec("3.11 数学方法")
show("10 factorial", 10 factorial)
show("5 squared", 5 squared)
show("2 pow(10)", 2 pow(10))
show("5 choose(2)", 5 combinations(2))
show("5 permute(2)", 5 permutations(2))
show("16 sqrt", 16 sqrt)
show("(2 sqrt) floor", (2 sqrt) floor)
chk("factorial", 10 factorial, 3628800)
chk("floor 把无理数收成整数", (2 sqrt) floor, 1)

sec("3.12 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 03 结束 ====")
if(fails != 0, System exit(1))
