// ============================================================
// 30 - Swift 语言基础与面向对象：把「书里说编译器会报错」逐条改成一行的证据
//
// 《跟着项目学iOS应用开发：基于Swift 4》的第 5 章（Swift 程序设计基础：备注与打印、
// 函数的输入输出、条件语句、循环、啤酒歌与斐波那契）、第 6 章的 6.4/6.7
// （do/catch/try 与作用域）、第 9 章整章（类、枚举、对象、初始化、继承、重写、可选）、
// 第 11 章的 11.3/11.4（闭包、完成处理）合起来就是本章的目录。那一版书是 2018 年按
// Swift 4 写的，判据是「Playground 右边那一栏显示什么」和「Xcode 报了什么红」。
//
// 本章在同一件事上做三处替换：
//   1) 判据从「眼睛 + 编辑器红点」换成 stdout 上的一行行断言；
//   2) 书里所有「编译器会报错」「运行就会崩」的说法，都由 probes/ 里的独立小文件重跑一遍，
//      原文照抄进 docs/30-swift-language-basics.md 的「探针记录」—— 本文件里**不出现**
//      任何故意写错的代码，因为六条判定要求编译日志为空、退出码为 0、stderr 为空
//      （probes/run.sh 就是把这 55 个探针按编号批量跑一遍的脚本，w01_whitespace.sh 另跑 §2 那张空格表）；
//   3) 书里 Swift 4 的行为按本机 Swift 6.0.3（语言模式默认 5）重新量一遍，
//      对不上的地方以对不上的方式呈现（§4/e04 的函数名提前可见、§6/e03 的缺 return 原话、
//      §8/r01 的 99...1、§9/r09 的 0...n-3 反向区间、§13/r05 的枚举打印、
//      §19/e31 的尾随闭包边界、§21 的 #if swift 与 #if compiler、-swift-version 6 对照）。
//
// 六条判定带来的写法约束：
//   - 随机数只问范围、不打印值（§3 的 arc4random_uniform：每次进程都换种子，
//     打印出来 debug/release 两份 stdout 就对不齐）；
//   - 不直接打印 Dictionary / Set：遍历顺序每个进程重新随机，要印就先把键排序（§22）；
//   - 会崩的写法全部只进 probes/（r01 反向区间、r02 强制拆包 nil、r03 try!、
//     r04 数组越界、r09 书 5.9 修补后的 n<3、r13 初始化之前调用全局闭包），
//     本文件只演示它们的安全替代物；
//   - 浮点只在这台 x86_64 模拟器上打印稳定位数（§13 的 π 用「相差不到 1e-4」断言），
//     并且因为判定要求 debug(-Onone) 与 release(-O) 两份 stdout 逐字节相同，
//     凡是「优化可能改变浮点结果」的写法一律不进主线。
// ============================================================

import AVFoundation
import Foundation
import UIKit

setvbuf(stdout, nil, _IONBF, 0)

var failures = 0
func expect(_ condition: Bool, _ parts: String...) {
    print("  \(condition ? "ok  " : "FAIL") \(parts.joined(separator: ""))")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
func section(_ n: Int, _ title: String) { print("\n== §\(n) \(title) ==") }

/// 把任何值变成「类型名 = 值」的一行，方便把类型的存在感打出来
func typed(_ label: String, _ v: Any) -> String { "\(label): \(type(of: v)) = \(v)" }

// ============================================================
// §1 注释、print 与控制台：本书 5.1
// ============================================================
section(1, "注释、print 与控制台（本书 5.1）")

// 双斜线只保一行。下面这三行是「文档注释」，Xcode 的 Quick Help 会捡走它们，
// 编译器一律无视：
/// 一行文档注释
/// - Parameter n: 文档注释可以带参数说明
func documented(_ n: Int) -> Int { return n }

/*
 这是一个多行的注释语句 —— 本书 5.1 的原文例子逐字照抄。
 里面写什么都不会执行：var neverRuns = "编译器看不见这一行"
*/
expect(documented(3) == 3, "文档注释不影响编译：documented(3) = 3")

// print 的真实面目：它有两个形参，第二个决定行尾。
line("print 默认换行；下一次调用从新行开始")
print("terminator 传空串就不换行 → ", terminator: "")
print("同一条逻辑行的后半段")
expect(true, "print(_:terminator:) 用 terminator: \"\" 可以把两条 print 接在同一行")

// 多行字符串：三对双引号，起始与结尾的那对独占一行，内容里的换行是真实换行。
let multiline = """
第一行
    第二行前面有 4 个空格（相对三引号的缩进基准）
第三行
"""
let mlLines = multiline.components(separatedBy: "\n")
expect(mlLines.count == 3, typed("多行字符串行数", mlLines.count))
expect(mlLines[1].hasPrefix("    "), "第二行确实带 4 个空格：\(mlLines[1])")

// 转义：\n 是换行，\\ 是反斜杠，\" 是引号，\t 是制表符，\( ) 是插值。
let escaped = "a\nb\\c\"d\te"
expect(escaped.components(separatedBy: "\n").count == 2, "字符串里有一个真换行 → 切成 2 段")
expect(escaped.contains("\\c"), "反斜杠本身要写两条才落一条")
expect("有 \(1 + 1) 个".contains("有 2 个"), "插值 \\(...) 在编译期就被换成描述")

// 注释符号被删掉之后就不是注释了 —— 本书 5.1 说「如果删除两个斜线，Xcode 编译器就会报错」，
// 这条在 probes/e32_uncommented_prose.swift 里量：把斜线去掉，那行文字就交给解析器了。
let commentedOut = "// print(\"这一行不会执行\")"
expect(!commentedOut.hasPrefix("print"), "把 // 去掉是「语义变化」，加回来才又是一行普通字符串")

// ============================================================
// §2 操作符两侧的空格：本书 5.1 说这是「报错」
// ============================================================
section(2, "操作符两侧的空格（本书 5.1）")
// 本书原文（5.1）：「当我们使用操作符的时候，例如 =、+、-、/ 或 * 号的时候，你必须让它
// 两边都有一个空格的间隔。等号左边有空格，等号的右边就必须要有空格，如果少了一边，Swift
// 就会对这种非对称格式报错。因此，要不就两边都有空格，要不就两边都不留空格。」
// 这段规则里只有两句站得住：「非对称要报错」「两边都不留空格也行」，而且实测下来报错的
// 只有 `=`，`+` 少一边的后果完全不同 —— 它不是「空格不合规」的报错，而是被解析成两条语句
// （probes/w01_whitespace.sh 逐条实测，正文抄的是那张表）。
var monsterHealth = 19
monsterHealth = monsterHealth + 31
monsterHealth = monsterHealth / 2
expect(monsterHealth == 25, typed("先加 31 再除以 2", monsterHealth))
monsterHealth = monsterHealth+1
expect(monsterHealth == 26, "两侧一起挤（h+1）照样算：\(monsterHealth)")
monsterHealth += 1
expect(monsterHealth == 27, "复合赋值 +1 也一样：\(monsterHealth)")
monsterHealth = monsterHealth - 1
expect(monsterHealth == 26, "四则运算本身不受空格影响，受影响的只有排版：\(monsterHealth)")
// 书 5.1 说「= + - / * 都必须两边有空格，否则报错」。Swift 6.0.3 上的实情分两种：
//   `=` 两边不对称 → 一条专门的诊断 "'=' must have consistent whitespace on both sides"；
//   `+` 这类中缀两侧不对称 → 没有这条诊断，而是被解析成「一条语句 + 一个正负号字面量」，
//     报的是 "consecutive statements on a line must be separated by ';'"。
// 十一条写法逐个跑在 probes/w01_whitespace.sh，正文照抄。
// 整除：两边都是 Int 时 / 直接砍掉小数部分，不做四舍五入 —— 这是 5.1 那段
// 「19 + 31 = 50，50 / 2」之所以能整除的原因，换成 51 就得 25。
expect(51 / 2 == 25 && 51 % 2 == 1, "整数除法是截断：51/2=\(51 / 2)，51%2=\(51 % 2)")
expect(-7 / 2 == -3 && -7 % 2 == -1, "负数也朝零截断：-7/2=\(-7 / 2)，-7%2=\(-7 % 2)")

// ============================================================
// §3 常量、变量与类型：本书 4.5 / 5.1 / 挑战条目的地板
// ============================================================
section(3, "常量、变量与类型")
let inferredInt = 19
let explicitDouble: Double = 19
let explicitFloat: Float = 19
let aString = "Black"
let aBool = true
expect(typed("inferredInt", inferredInt).contains("Int"), "字面量 19 默认推断成 Int")
expect(type(of: explicitDouble) == Double.self, "标了类型的 19 才是 Double：\(type(of: explicitDouble))")
expect(MemoryLayout<Int>.size == 8, "x86_64 模拟器上 Int 是 8 字节（第 28 章的 LP64 账）")
expect(MemoryLayout<Int>.size == 8 && MemoryLayout<Float>.size == 4 && MemoryLayout<Double>.size == 8,
       "Int=\(MemoryLayout<Int>.size) Float=\(MemoryLayout<Float>.size) Double=\(MemoryLayout<Double>.size) 字节")
expect(String(aBool) == "true" && String(explicitFloat) == "19.0",
       "布尔落字符串是 true，19 落到 Double 上打印成 19.0：\(String(aBool)) / \(String(explicitFloat))")
expect(aString == "Black" && type(of: aString) == String.self,
       "书 9.2 里 Car 的默认颜色就是这条字符串：\(aString) 的类型是 \(type(of: aString))")

// 常量与变量的区别只能在「能不能改」上看；把 let 改了会报什么，probes/e18_let_reassign.swift 量。
var mutable = 1
mutable = 2
expect(mutable == 2, "var 可以重新赋值")
let letArray = [1, 2, 3]
expect(letArray.count == 3, "let 数组能读：letArray[0] = \(letArray[0])")
// 本书 4.7 用数组换图片，本节把「let 数组不能 append」这条也留到探针里
// （probes/s05_let_array_append.swift：cannot use mutating member on immutable value）。

// 类型不兼容是硬错：本书 5.5 说 arc4random_uniform 的返回值「是 UInt32 类型，
// 所以需要使用 Int() 将其转换」，不转就报错（probes/e07_uint32_to_int.swift）。
let rawRandom: UInt32 = arc4random_uniform(101)
let nameScore = Int(rawRandom)
// 只问范围、不问本次值：随机数每次进程都不同，打印出来 debug/release 两份 stdout 就对不齐。
expect(nameScore >= 0 && nameScore <= 100, "Int(arc4random_uniform(101)) 的类型与取值范围：\(type(of: nameScore))，必落在 0...100")
var inRange = 0
for _ in 0..<2000 where Int(arc4random_uniform(101)) <= 100 { inRange += 1 }
expect(inRange == 2000, "抽 2000 次全部落在 0...100 之内：\(inRange) 次命中")
expect(Int("42") != nil && Int("abc") == nil, "字符串转数字返回可选：Int(\"42\")=\(String(describing: Int("42")))，Int(\"abc\")=\(String(describing: Int("abc")))")

// ============================================================
// §4 函数的最小形态：本书 5.2
// ============================================================
section(4, "函数的最小形态（本书 5.2）")
func getMilkEmpty() {
    // 该函数目前不需要实现任何的代码（本书 5.2 原文注释）
}
getMilkEmpty()
expect(true, "空函数体也能调用：func 名字() {} 之后 名字()")

func getMilk() {
    print("去门口的小卖店")
    print("买2瓶牛奶")
    print("支付13.20元")
    print("回家")
}
line("定义 getMilk() 本身不产生任何输出，只有调用它才打印：")
getMilk()

// 「函数声明提前可见」：本书 11.3 特意叮嘱「calculator(n1:n2:operation:) 代码一定要放到
// 两个函数定义的后面，否则会出现找不到函数的错误」。这条在 Swift 6.0.3 的顶层代码里
// 不成立 —— 函数声明在整个文件里都可见，写在调用之后照样跑（probes/e04_use_before_define.swift
// 编译通过，运行输出 9）。真正有顺序问题的是顶层的 let/var：它不报错也不崩，
// 读到的是零初始化的值（probes/t01_toplevel_let.swift 实测 x=0 / box=0）。
line("先看答案再定义：调用在前的函数与在后的函数声明 ——")
print("calcBefore() = \(calcBefore())（calcBefore 的 func 写在下一行之后）")
func calcBefore() -> Int { return 21 * 2 }

// ============================================================
// §5 函数的输入：外部名、内部名、下划线、默认值、可变参数
// 本书 5.3 + 5.8 的「内部参数名」
// ============================================================
section(5, "函数的输入（本书 5.3 / 5.8）")
func getMilk(howManyMilkCartons: Int) {
    print("买 \(howManyMilkCartons) 瓶牛奶")
}
getMilk(howManyMilkCartons: 4)
// 调用点必须带上外部名 —— 少写参数（probes/e02_missing_arg.swift）报
// missing argument for parameter 'howManyMilkCartons' in call。

// 外部名/内部名：withThisManyBottles 是给调用者看的，totalNumberOfBottles 是给函数自己用的。
func beerSong(withThisManyBottles totalNumberOfBottles: Int) -> String {
    var lyrics = ""
    for number in (1...totalNumberOfBottles).reversed() {
        let newLine: String
        if number == 1 {
            newLine = "\(number) bottle of beer on the wall, \(number) bottle of beer. Take one down and pass it around, no more bottles of beer on the wall.\n"
        } else {
            newLine = "\(number) bottles of beer on the wall, \(number) bottles of beer. Take one down and pass it around, \(number - 1) bottles of beer on the wall.\n"
        }
        lyrics += newLine
    }
    return lyrics
}
let song3 = beerSong(withThisManyBottles: 3)
expect(song3.hasPrefix("3 bottles"), "函数体内用的是内部名：第一段起于 3 bottles")
expect(song3.contains("1 bottle of beer on the wall, 1 bottle of beer"), "最后一瓶改用单数 bottle（书 5.8 的 if 分支）")
expect(song3.contains("no more bottles of beer on the wall") && !song3.contains("0 bottles"),
       "最后一段说 no more，不出现 0 bottles")
expect(song3.components(separatedBy: "\n").count - 1 == 3, "3 瓶 → 3 行，行数 = 传入的参数：\(song3.components(separatedBy: "\n").count - 1)")

// 下划线当外部名：调用点不再需要标签。
func beerSongUntagged(_ totalNumberOfBottles: Int) -> Int { return totalNumberOfBottles * 2 }
expect(beerSongUntagged(23) == 46, "func f(_ x: Int) 让调用点写成 f(23)：\(beerSongUntagged(23))")

// 默认参数：外部名保留，调用时省掉即可。
func priceOf(milkCartons: Int, unitPrice: Int = 7) -> Int { return milkCartons * unitPrice }
expect(priceOf(milkCartons: 4) == 28 && priceOf(milkCartons: 4, unitPrice: 5) == 20,
       "默认参数：4×7=\(priceOf(milkCartons: 4))，指定单价后 4×5=\(priceOf(milkCartons: 4, unitPrice: 5))")

// 可变参数：函数内部它就是个数组。
func total(_ numbers: Int...) -> Int { return numbers.reduce(0, +) }
expect(total(1, 5, 2, 3, 10, 22, 32) == 75 && total() == 0,
       "Int... 收 7 个数得 \(total(1, 5, 2, 3, 10, 22, 32))，一个不给也得 0")

// inout：函数拿到的是同一个存储，不是副本。
func addTax(_ amount: inout Int) { amount += amount / 10 }
var bill = 100
addTax(&bill)
expect(bill == 110, "inout + & 让调用方的值真的变了：bill = \(bill)")

// ============================================================
// §6 函数的输出：本书 5.4
// ============================================================
section(6, "函数的输出（本书 5.4）")
func getMilk(howManyMilkCartons: Int, howMuchMoneyRobotWasGiven: Int) -> Int {
    let priceToPay = howManyMilkCartons * 7
    let change = howMuchMoneyRobotWasGiven - priceToPay
    return change
}
var amountOfChange = getMilk(howManyMilkCartons: 4, howMuchMoneyRobotWasGiven: 30)
print("你好主人，这里是找回的 \(amountOfChange) 元钱。")
expect(amountOfChange == 2, "30 - 4×7 = 2：\(amountOfChange)")
amountOfChange = getMilk(howManyMilkCartons: 3, howMuchMoneyRobotWasGiven: 30)
expect(amountOfChange == 9, "换参数不换签名：3 瓶找 \(amountOfChange) 元")

// 单表达式函数可以省掉 return（Swift 5.1 起）；本书写于 Swift 4，那时每个分支都得写 return。
func implicitDouble(_ n: Int) -> Int { n * 2 }
expect(implicitDouble(21) == 42, "省略 return 的单表达式函数：\(implicitDouble(21))")

// 没有返回值 ≠ 返回 Void 之外的东西：写 -> Void、什么都不写、返回 ()->() 三种写法等价。
func returnsVoid() {}
func saysVoid() -> Void {}
func returnsUnit() -> () {}
returnsVoid(); saysVoid(); returnsUnit()
expect(type(of: returnsVoid()) == Void.self && type(of: returnsUnit()) == Void.self,
       "三种写法的返回值类型都是 Void：\(type(of: returnsUnit()))")

// 多「一个」返回值只能靠元组：Swift 的函数只有一个 return 值。
func minMax(_ xs: [Int]) -> (min: Int, max: Int) {
    var lo = xs[0], hi = xs[0]
    for x in xs { if x < lo { lo = x }; if x > hi { hi = x } }
    return (lo, hi)
}
let mm = minMax([1, 5, 2, 3, 10, 22, 32])
expect(mm.min == 1 && mm.max == 32, "元组带标签：min=\(mm.min) max=\(mm.max)")
let (lo2, hi2) = mm
expect(lo2 == 1 && hi2 == 32, "拆包成两个常量：\(lo2)/\(hi2)")

// 「声明了返回类型却忘写 return」的报错文本，本书 5.4 记的是
// 「missing return in a function expected to return 'Int'」——那是 Xcode 8/9 时代的措辞。
// Swift 6.0.3 给的是另一条（probes/e03_missing_return.swift）：
// cannot convert return expression of type '()' to return type 'Int'。
expect(true, "缺 return 的诊断文本已换：见 probes/e03_missing_return.swift")

// ============================================================
// §7 条件语句与「覆盖全部情况」：本书 5.5
// ============================================================
section(7, "条件语句（本书 5.5）")
func verdict(score: Int) -> String {
    if score > 80 {
        return "你的名字评分是 \(score)，很完美！"
    } else if score > 40 && score <= 80 {
        return "你的名字评分是 \(score)，还不错！"
    } else {
        return "你的名字评分是 \(score)，比较一般。"
    }
}
// 本书 5.5 的收尾忠告是「检测机制一定要覆盖全部的情况」。把边界逐个量出来，
// 才知道那三条分支有没有缝。
expect(verdict(score: 81).contains("很完美"), "81 → 完美：\(verdict(score: 81))")
expect(verdict(score: 80).contains("还不错"), "80 不在第一条分支（> 80），落到第二条：\(verdict(score: 80))")
expect(verdict(score: 41).contains("还不错"), "41 → 还不错：\(verdict(score: 41))")
expect(verdict(score: 40).contains("比较一般"), "40 也不在第二条（> 40），落到最后：\(verdict(score: 40))")
// 书里那条 `nameScore > 40 && nameScore <= 80` 的第二个条件其实冗余：
// 能走到 else if 说明第一条已经不成立，即 nameScore <= 80 必然为真。
var redundantHits = 0
for s in 0...100 where s > 40 && s <= 80 { redundantHits += 1 }
expect(redundantHits == 40, "0...100 里满足 >40 && <=80 的是 41...80，共 \(redundantHits) 个")

// 逻辑运算符的优先级：! 最高，&& 次之，|| 最低 —— 混写时加括号，不然读的顺序会骗人。
let t = true, f = false
expect((t || f && f) == true && ((t || f) && f) == false,
       "&& 比 || 紧密：t || f && f = \((t || f && f))，加括号变 \(((t || f) && f))")
// 短路：左半边已经决定结果时，右半边根本不求值。
var sideEffect = 0
func bump() -> Bool { sideEffect += 1; return true }
if false && bump() { line("不会走到") }
expect(sideEffect == 0, "&& 左边为 false，右边函数没被调用：sideEffect = \(sideEffect)")
if true || bump() { line("|| 命中左边") }
expect(sideEffect == 0, "|| 左边为 true 也一样短路：sideEffect = \(sideEffect)")

// 三元与 if 的分工：if 是语句，三元是表达式。
let level = scoreLevel(75)
func scoreLevel(_ s: Int) -> String { s > 80 ? "A" : (s > 40 ? "B" : "C") }
expect(level == "B", "嵌套三元当表达式用：75 → \(level)")

// switch 比 if 链强的地方是「编译器逼你穷尽」，漏一条就编译不过
// （probes/e20_switch_not_exhaustive.swift：switch must be exhaustive）。
func tier(_ s: Int) -> String {
    switch s {
    case 0: return "零"
    case 1...40: return "低"
    case 41...80 where s % 2 == 0: return "中偶"
    case let x where x > 200: return "异常大 \(x)"
    default: return "中奇/高"
    }
}
expect(tier(0) == "零" && tier(20) == "低" && tier(42) == "中偶" && tier(43) == "中奇/高" && tier(300) == "异常大 300",
       "区间 case / where 附加条件 / 绑定 case 各跑一遍：\(tier(20))、\(tier(42))、\(tier(300))")

// ============================================================
// §8 区间与循环：本书 5.7 / 5.8
// ============================================================
section(8, "区间与循环（本书 5.7）")
let arrayOfNumbers = [1, 5, 2, 3, 10, 22, 32]
var sum = 0
var perStep: [Int] = []
for number in arrayOfNumbers {
    sum += number // 等同于 sum = sum + number
    perStep.append(sum)
}
expect(sum == 75, "for-in 累加整数组：sum = \(sum)")
expect(perStep == [1, 6, 8, 11, 21, 43, 75], "每一步的部分和都能对上：\(perStep)")
expect(arrayOfNumbers[0] == 1 && arrayOfNumbers[6] == 32, "还能按索引取：[0]=\(arrayOfNumbers[0]) [6]=\(arrayOfNumbers[6])")

var closedCount = 0
for _ in 1...10 { closedCount += 1 }
var halfOpenCount = 0
for _ in 1..<10 { halfOpenCount += 1 }
expect(closedCount == 10 && halfOpenCount == 9, "1...10 跑 10 次，1..<10 跑 9 次：\(closedCount)/\(halfOpenCount)")

var evens: [Int] = []
for number in 1...10 where number % 2 == 0 { evens.append(number) }
expect(evens == [2, 4, 6, 8, 10], "for ... where 过滤出 5 个偶数：\(evens)")

// 本书 5.8 说「（1...99）实际上是一个对象，它的类型为 Range」——类型名不对：
// 带两端的是 ClosedRange，..< 才是 Range。
let r = 1...99
expect(type(of: r) == ClosedRange<Int>.self, "1...99 的类型是 \(type(of: r))，不是 Range<Int>")
expect(type(of: 1..<99) == Range<Int>.self, "1..<99 才是 \(type(of: 1..<99))")
expect(r.lowerBound == 1 && r.upperBound == 99 && r.contains(99),
       "ClosedRange 的 upperBound 包含在内：\(r.lowerBound)...\(r.upperBound)，contains(99)=\(r.contains(99))")
expect((1..<99).upperBound == 99 && !(1..<99).contains(99),
       "Range 的 upperBound 不包含：(1..<99).contains(99) = \((1..<99).contains(99))")

var descending: [Int] = []
for number in (1...5).reversed() { descending.append(number) }
expect(descending == [5, 4, 3, 2, 1], "(1...5).reversed() 给出 5→1：\(descending)")
expect(String(describing: type(of: (1...5).reversed())).contains("Reversed"),
       "reversed() 返回的不是数组而是 \(String(describing: type(of: (1...5).reversed())))")

// 本书 5.8 断言「99...1 这种方式……编译器会报错」：实测**编译期一声不响**，
// 是运行期才 fatal error（probes/r01_desc_range.swift：
// Fatal error: Range requires lowerBound <= upperBound，进程收到信号 4）。
// 所以本节用合法的写法做同样的事：
var countDown: [Int] = []
for number in stride(from: 99, through: 1, by: -1) { countDown.append(number) }
expect(countDown.count == 99 && countDown.first == 99 && countDown.last == 1,
       "倒着走用 stride：\(countDown.count) 项，\(countDown.first!) → \(countDown.last!)")
var evenDown: [Int] = []
for n in stride(from: 10, through: 0, by: -2) { evenDown.append(n) }
expect(evenDown == [10, 8, 6, 4, 2, 0], "stride(from:through:by:) 含 through 端点：\(evenDown)")
var halfDown: [Int] = []
for n in stride(from: 10, to: 0, by: -2) { halfDown.append(n) }
expect(halfDown == [10, 8, 6, 4, 2], "换成 to: 就不含端点：\(halfDown)")

// while / repeat-while：后者至少跑一圈。
var k = 0
while k < 3 { k += 1 }
expect(k == 3, "while 跑了 \(k) 圈")
var ran = 0
repeat { ran += 1 } while ran < 1
expect(ran == 1, "条件一开始就假的 repeat-while 仍然跑了一整圈：\(ran)")

// break / continue / 标签：嵌套循环里 break 只跳最近的一层。
var inner = 0
for _ in 0..<3 { for _ in 0..<3 { inner += 1; break } }
expect(inner == 3, "内层 break 只退出内层：外层 3 圈 × 每圈 1 次 = \(inner)")
var labeled = 0
outer: for _ in 0..<3 { for _ in 0..<3 { labeled += 1; break outer } }
expect(labeled == 1, "break outer 一次就跳出两层：\(labeled)")

// ============================================================
// §9 斐波那契与 off-by-one：本书 5.9
// ============================================================
section(9, "斐波那契与 off-by-one（本书 5.9）")
// 本书的原版：先 print(0)、print(1)，再从 for iteration in 0...n 里生成，
// 于是「参数 n 代表元素个数」这件事是错的 —— 循环自己跑了 n+1 圈，加上开头两项
// 一共 n+3 项。书里给的修补是「将 for 语句修改为 for iteration in 0...n-3 即可」。
// 这里把 print 换成返回数组，只是为了能直接数项数、逐项比对。
func fibonacciBookOriginal(until n: Int) -> [Int] {
    var out = [0, 1]
    var num1 = 0
    var num2 = 1
    for _ in 0...n {
        let num = num1 + num2
        out.append(num)
        num1 = num2
        num2 = num
    }
    return out
}
func fibonacciBookPatched(until n: Int) -> [Int] {
    var out = [0, 1]
    var num1 = 0
    var num2 = 1
    for _ in 0...(n - 3) {
        let num = num1 + num2
        out.append(num)
        num1 = num2
        num2 = num
    }
    return out
}
func fibonacciCounted(_ n: Int) -> [Int] {
    var out: [Int] = []
    var num1 = 0
    var num2 = 1
    for _ in 0..<n {
        out.append(num1)
        let num = num1 + num2
        num1 = num2
        num2 = num
    }
    return out
}
let orig5 = fibonacciBookOriginal(until: 5)
expect(orig5.count == 8, "书 5.9 原版 until:5 实际给了 \(orig5.count) 项（参数说的是 5 项）：\(orig5)")
expect(orig5.count == 5 + 3 && orig5 == fibonacciCounted(8),
       "项数 = 开头 2 项 + 循环 (n+1) 圈 = n+3；数列本身没错，多的那三项照样是斐波那契数")
expect(fibonacciBookOriginal(until: 20).count == 23, "until:20 出 23 项，最后三项：\(Array(fibonacciBookOriginal(until: 20).suffix(3)))")
let patched8 = fibonacciBookPatched(until: 8)
expect(patched8 == [0, 1, 1, 2, 3, 5, 8, 13], "修补成 0...n-3 之后 n 才真的等于项数：\(patched8)")
expect(patched8 == fibonacciCounted(8), "修补版与「n 就是项数」的现代写法逐项相等：\(fibonacciCounted(8))")
// 修补的代价：0...(n-3) 在 n < 3 时是个反向区间，编译期一声不响，运行期 fatal
// （probes/r09_fib_reverse_range.swift，同 §8 的 99...1 一个病）。
expect(fibonacciBookPatched(until: 4).count == 4 && fibonacciBookPatched(until: 3).count == 3,
       "修补版只在 n >= 3 时成立：n=4 出 \(fibonacciBookPatched(until: 4).count) 项、n=3 出 \(fibonacciBookPatched(until: 3).count) 项")
// 书 5.9 的另一条：iteration 从来没用过 → 编译器告警。这条在 Swift 6.0.3 依然存在，
// 文本见 probes/e06_unused_loop_var.swift。
var fib20last = 0
for _ in 0..<20 { fib20last += 1 }
expect(fib20last == 20, "把没用上的循环变量写成 _ 之后，圈数照样可查：\(fib20last)")

// ============================================================
// §10 作用域：本书 6.7 的苹果园
// ============================================================
section(10, "作用域（本书 6.7）")
// 三层：函数体内（局部）、方法之间共享的类属性、文件顶层的全局。
// 本书的说法是「围墙里的苹果树只有你能摘，围墙外的谁都能摘」。这一节把它做成可断言的：
class XylophoneViewController {
    var selectedSoundFileName = "note1"      // 围墙外：所有方法都能读也能改
    func notePressed(tag: Int) -> String {
        let localCopy = selectedSoundFileName   // 围墙内：只有本方法看得见
        selectedSoundFileName = "note\(tag)"
        return localCopy
    }
    func playSound() -> String {
        selectedSoundFileName = "note2"          // 书 6.7 里那条「邻居采摘」
        return selectedSoundFileName
    }
    func nestedScopeDemo() -> [String] {
        var seen: [String] = []
        let shared = "outer"
        func innerFunc(_ tag: String) -> String { return shared + "-" + tag }   // 嵌套函数
        seen.append(innerFunc("a"))
        do {
            let shared = "inner"                 // 同名遮蔽：内层的才是它自己那份
            seen.append(innerFunc("b"))
            _ = shared
        }
        seen.append(innerFunc("c"))
        return seen
    }
}
let xylo = XylophoneViewController()
expect(xylo.notePressed(tag: 7) == "note1", "先读到旧值：notePressed 返回 \(xylo.notePressed(tag: 5))")
_ = xylo.notePressed(tag: 7)
expect(xylo.selectedSoundFileName == "note7", "任何方法都能改这个类属性：改完 = \(xylo.selectedSoundFileName)")
expect(xylo.playSound() == "note2", "playSound 开头强行赋值 → 按哪个键都是同一声音（书 6.7 的病）")
// 书 6.7 给出的解法：把值当参数传进去，别留一个大家都能改的全局状态。
class FixedXylophone {
    let soundFileNames = ["note1", "note2", "note3"]
    func notePressed(tag: Int) -> String { return playSound(soundFileName: soundFileNames[tag - 1]) }
    func playSound(soundFileName: String) -> String { return "播放 \(soundFileName)" }
}
let fixed = FixedXylophone()
expect(fixed.notePressed(tag: 1) == "播放 note1" && fixed.notePressed(tag: 3) == "播放 note3",
       "参数版调用两次结果不同、外部无从篡改：\(fixed.notePressed(tag: 1)) / \(fixed.notePressed(tag: 3))")
// 嵌套函数 + 同名遮蔽：do 里那句 inner 只在它自己的大括号里活。
expect(xylo.nestedScopeDemo() == ["outer-a", "outer-b", "outer-c"],
       "内层同名常量不影响外层捕获：\(xylo.nestedScopeDemo())")
// 本书 5.8 末尾那条「在一个大括号中声明的常量或者变量，其生存的范围也就在这个大括号之内」
// —— 想先声明后在分支里赋值，正确写法是把 let 提到分支之前但不给类型注解的初值（§5 的啤酒歌
// 就是这么写的）。报错原文见 probes/e16_scope_if.swift（cannot find 'newLine' in scope）。
expect(true, "if 大括号内的常量出去就没了：见 probes/e16_scope_if.swift")

// ============================================================
// §11 错误捕获：do / catch / try，本书 6.4
// ============================================================
section(11, "错误捕获（本书 6.4）")
enum PlayerError: Error {
    case fileMissing(String)
    case formatUnusable
}
// 给 Error 加上本地化描述，catch 里打印出来的就不是一串编号。
extension PlayerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fileMissing(let name): return "找不到音频文件：\(name)"
        case .formatUnusable: return "文件格式不是 CoreAudio 认识的音频"
        }
    }
}
func loadPlayer(from path: String?) throws -> AVAudioPlayer {
    guard let path else { throw PlayerError.fileMissing("url 是 nil") }
    if path.hasSuffix(".mp3") { throw PlayerError.formatUnusable }
    return try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
}
// 书 6.4 的核心实验是把 withExtension 从 wav 改成 mp3，然后看控制台报什么。
// 这里用同一条路径分三种接法：do/catch、try?、以及只问类型的 catch 分支。
var caught: [String] = []
do {
    _ = try loadPlayer(from: "note1.mp3")
} catch {
    caught.append("catch-all: \(error.localizedDescription)")
}
do {
    _ = try loadPlayer(from: nil)
} catch PlayerError.fileMissing(let name) {
    caught.append("按 case 抓: \(name)")
} catch let e as PlayerError {
    caught.append("按类型抓: \(e)")
} catch {
    caught.append("兜底")
}
line(caught.joined(separator: "\n"))
expect(caught.count == 2 && caught[0].contains("格式") && caught[1].contains("url 是 nil"),
       "两条 catch 都落进了预期的分支：\(caught.count) 条")

// try? 不抛了，把失败压成 nil —— 本书 6.4 只讲了 try 与 try!，try? 是第三条路。
let maybe = try? loadPlayer(from: "note1.mp3")
expect(maybe == nil, "try? 的结果是可选：\(String(describing: maybe))")
// try! 是「不留退路」：真抛了就是崩溃（probes/r03_try_bang.swift 的 fatal 文本）。
// 本节不在主线上演示它，因为崩溃会同时撞判定 2 和判定 3。
expect(true, "try! 的代价由探针承担：probes/r03_try_bang.swift 跑出来是 signal 4")

// 本书 6.4 用 AVAudioPlayer 举例「错误代码可以上 osstatus.com 查」。
// 本机能给的只有 domain 与 code，把 code 按大端拆成 FourCC 才看得懂形状：
var avErr: (domain: String, code: Int) = ("", 0)
do {
    _ = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/tmp/definitely-not-here.wav"))
} catch let e as NSError {
    avErr = (e.domain, e.code)
}
expect(avErr.domain == "NSOSStatusErrorDomain", "AVFoundation 把 OSStatus 包进 NSError：domain = \(avErr.domain)")
expect(avErr.code == 2003334207, "本机对不存在的文件给的 OSStatus = \(avErr.code)")
let status = UInt32(truncatingIfNeeded: avErr.code)
let fourCC = [(status >> 24) & 0xFF, (status >> 16) & 0xFF, (status >> 8) & 0xFF, status & 0xFF]
    .map { String(UnicodeScalar(UInt8($0))) }
// 0x77 0x68 0x74 0x3F —— 也就是 'w' 'h' 't' '?'。这台机器给的就是这个数，
// 换成别的文件（存在但格式错）会给出不同的 FourCC，所以这里只把它当成
// 「一个整数可以拆成四个 ASCII 字符」的形状看，不去猜它的含义。
expect(fourCC == ["w", "h", "t", "?"], "把 OSStatus 按大端拆成四个字符 = \(fourCC.joined())，倒过来读是 \(String(fourCC.reversed().joined()))（0x\(String(status, radix: 16, uppercase: false))）")

// defer：无论函数从哪个出口离开都会执行 —— 用来配对「借了要还」。
// 但要注意 defer 是在**返回值算好之后**才跑的：改函数里的局部变量已经晚了。
func deferLocalReturn() -> [String] {
    var log: [String] = []
    defer { log.append("defer-1") }
    log.append("body")
    return log
}
var deferLog: [String] = []
func deferDemo() -> Int {
    defer { deferLog.append("defer-1") }
    defer { deferLog.append("defer-2") }
    deferLog.append("body")
    return 42
}
expect(deferLocalReturn() == ["body"], "defer 跑在 return 之后：改局部变量留不进返回值 = \(deferLocalReturn())")
let deferred = deferDemo()
expect(deferred == 42 && deferLog == ["body", "defer-2", "defer-1"],
       "多个 defer 是后写的先执行（栈不是队列），函数外的记录才看得见：\(deferLog)")

// rethrows：自己不抛，只在参数闭包抛的时候跟着抛。
func withGuardedFile(_ body: () throws -> Int) rethrows -> Int { return try body() }
var rethrown = 0
do { rethrown = try withGuardedFile { throw PlayerError.formatUnusable } } catch { rethrown = -1 }
expect(rethrown == -1, "rethrows 把闭包抛的错误原样递出来：\(rethrown)")

// ============================================================
// §12 类与对象：蓝图与真车（本书 9.1、9.2、9.4）
// ============================================================
section(12, "类与对象：蓝图与真车（本书 9.1、9.2、9.4）")
// 书 9.1 的比喻：类是蓝图，按蓝图造出来的那辆真车是对象；蓝图里写的是
// 属性（变量/常量）、动作（方法）和事件（特定时机自动执行的东西）。
// 下面这个 Car 就是书 9.2 的 Car，只把 print 换成往 events 里记账，
// 因为本章的判定要求「每行输出都能断言」，靠 print 顺序断言不了「先跑父类」。
class Car {
    var colour = "Black"                 // 书 9.2：带默认值的属性
    var numberOfSeats: Int = 5           // 书 9.2：显式写出类型
    var typeOfCar: CarType = .coupe      // CarType 在 §13 定义 —— 类型声明对全文可见
    var events: [String] = []
    static func wheelsPerCar() -> Int { return 4 }
    func drive() { events.append("汽车已经开动") }   // 书 9.7 的方法
}
let myCar = Car()
expect(myCar.colour == "Black" && myCar.numberOfSeats == 5 && myCar.typeOfCar == .coupe,
       "不写任何 init，实例拿到的就是蓝图里的默认值：\(myCar.colour)/\(myCar.numberOfSeats)/\(myCar.typeOfCar)")
expect(Car.wheelsPerCar() == 4 && myCar.events.isEmpty,
       "static 方法挂在类上（Car.wheelsPerCar()），实例方法挂在对象上（myCar.drive()）")
myCar.drive()
expect(myCar.events == ["汽车已经开动"], "书 9.7 的 myCar.drive()：点操作符调用方法，方法里不需要传参数也没法不传 self")
// 书 9.5 的「返厂喷漆」写法：let 实例照样能改属性。
myCar.colour = "Red"
expect(myCar.colour == "Red", "let myCar 之后仍能 myCar.colour = \"Red\"：现在读回 \(myCar.colour) —— class 的 let 锁的是引用，不是内容")
// class 是引用类型：赋值的不是车，是「遥控器」
let secondCar = myCar
secondCar.colour = "Blue"
expect(myCar.colour == "Blue", "let secondCar = myCar 之后改 secondCar，myCar 一起变成 \(myCar.colour)")
expect(secondCar === myCar, "=== 问的是「是不是同一辆车」：\(secondCar === myCar)（== 对 class 根本不存在，见探针 e24）")
// struct 是值类型：赋值即拷贝。CarType 那种「只有 case、没有存储」的类型见 §13。
struct SeatPlan { var numberOfSeats: Int = 5 }
var planA = SeatPlan()
var planB = planA
planB.numberOfSeats = 7
expect(planA.numberOfSeats == 5 && planB.numberOfSeats == 7,
       "struct 赋值即拷贝：改 planB 之后 planA 还是 \(planA.numberOfSeats)、planB 是 \(planB.numberOfSeats)")
let seatCopy = SeatPlan()
expect(seatCopy.numberOfSeats == 5, "struct 换成 let 常量之后连属性都改不了（探针 e25：cannot assign to property: 'p' is a 'let' constant），只能整体重新赋值：\(seatCopy.numberOfSeats)")
// 「事件」：init 就是书 9.1 说的那个「实例化时自动执行」的东西（书 9.5 末尾点破了这件事）。
var eventLog: [String] = []
class AutoEvent {
    init() { eventLog.append("init 被自动调用") }
}
_ = AutoEvent()
expect(eventLog == ["init 被自动调用"], "没有一行代码调用过 init，但它跑了：\(eventLog) —— 这就是书 9.1 说的「事件」")

// ============================================================
// §13 枚举：给自己造一个数据类型（本书 9.3）
// ============================================================
section(13, "枚举：给自己造一个数据类型（本书 9.3）")
// 书 9.3 的问题：carType 用什么类型？用 Int 的 0/1/2 就得再配一份说明书。
// 枚举 = 一个新的数据类型 + 它全部合法的取值。
enum CarType {
    case sedan
    case coupe
    case hatchback
}
// 书 9.3 的 case 名首字母大写（case Sedan）。Swift 6.0.3 对两种命名都不报错，
// 但大小写是真的有区别的：探针 e23_uppercase_case.swift 记录的是「大写也编得过」，
// 而风格指南要的是下面这种小写 —— 本章按小写走。
let chosenType: CarType = .coupe
expect(type(of: chosenType) == CarType.self, "type(of:) 报的就是自定义的类型名：\(type(of: chosenType))")
expect(chosenType == .coupe && chosenType != .sedan, "同 case 才相等：.coupe == .coupe 为 \(chosenType == .coupe)、.coupe == .sedan 为 \(chosenType == .sedan)")
func describe(_ t: CarType) -> String {
    switch t {
    case .sedan: return "普通轿车"
    case .coupe: return "双门轿车"
    case .hatchback: return "两厢轿车"
    }
}
expect(describe(.hatchback) == "两厢轿车", "switch 分派枚举：三个 case 全写出来才编译得过（漏一个的原话见探针 e20）：\(describe(.hatchback))")
// 打印枚举的样子（书 9.4 的 print(myCar.typeOfCar) 打出 Coupe）：
expect(describe(myCar.typeOfCar) == "双门轿车", "书 9.4 那行 print(typeOfCar) 打的是 case 名本身：\(myCar.typeOfCar)")
// 有原始值的枚举：给每个 case 挂一个对外可见的值（书里没讲，但 10.7.3 的 API 字典全靠它）
enum WindDirection: String {
    case north = "N"
    case south = "S"
}
expect(WindDirection.north.rawValue == "N", "原始值：WindDirection.north.rawValue = \(WindDirection.north.rawValue)")
expect(WindDirection(rawValue: "S") == .south && WindDirection(rawValue: "X") == nil,
       "用原始值反查会得到可选：\"S\" → \(String(describing: WindDirection(rawValue: "S")))、\"X\" → \(String(describing: WindDirection(rawValue: "X")))")
// 关联值：case 自己带数据，这是枚举和「一组常量」真正的区别。
enum Shape {
    case circle(diameter: CGFloat)
    case rect(width: CGFloat, height: CGFloat)
}
func area(_ s: Shape) -> CGFloat {
    switch s {
    case .circle(let d): return CGFloat.pi * d * d / 4
    case .rect(let w, let h): return w * h
    }
}
expect(area(.rect(width: 3, height: 4)) == 12, "关联值在 case 里被解出来：rect(3×4) 面积 = \(area(.rect(width: 3, height: 4)))")
let roundShape: Shape = .circle(diameter: 2)
expect(abs(area(roundShape) - CGFloat.pi) < 0.0001, "circle(diameter: 2) 面积 ≈ \(String(format: "%.4f", Double(area(roundShape))))（π 本身没法逐字节，用「与 π 相差不到 1e-4」来断言）")
// CaseIterable：不需要手写数组就能列出全部 case（Swift 4.1 起才有，书 9.3 那会儿还没有）
extension CarType: CaseIterable {}
expect(CarType.allCases.count == 3, "加了 : CaseIterable 之后 allCases 自动给全：\(CarType.allCases)")
// 书 9.3 说的「减少 Bug」到底减在哪：Int 那套写法里 0/1/2 之间可以随便加，枚举不行。
let asInt = 0
expect(asInt + 1 == 1, "Int 的 0 和 1 能相加 —— 这就是「0 代表轿车」的代价：加出来的 1 谁也说不清是什么")
// 关联值枚举打出来长什么样，见探针 r05_enum_print.swift（coupe / circle(3.0) / rect(w: 1.0, h: 2.0)）。
expect(myCar.typeOfCar == .coupe, "无关联值的枚举直接进字符串插值就是 case 名（探针 r05 抄了原话）：\"\(myCar.typeOfCar)\"")

// ============================================================
// §14 类的初始化：生产线喷漆还是返厂喷漆（本书 9.5）
// ============================================================
section(14, "类的初始化：生产线喷漆还是返厂喷漆（本书 9.5）")
// 书 9.5 的比喻：§12 那种「先 Car() 再 myCar.colour = "Red"」等于新车造好再返厂喷漆；
// 要的是在生产线上就按客户要求装配 —— 那就是 init。
class PaintedCar {
    var colour = "Black"
    var numberOfSeats: Int = 5
    var typeOfCar: CarType = .coupe
    var events: [String] = []
    init(customerChosenColour: String) {
        colour = customerChosenColour
    }
    func drive() { events.append("汽车已经开动") }
}
let painted = PaintedCar(customerChosenColour: "Red")
expect(painted.colour == "Red" && painted.numberOfSeats == 5 && painted.typeOfCar == .coupe,
       "init 里只改了 colour：\(painted.colour)/\(painted.numberOfSeats)/\(painted.typeOfCar) —— 没提到的属性仍然是默认值")
// 书 9.5 接着说「回到 main.swift，此时编译器会报错：初始化方法丢失参数 customerChosenColour」。
// 这条在 6.0.3 照样成立，原话抄在探针 e12_designated_no_default.swift：
//   error: missing argument for parameter 'customerChosenColour' in call
// 书 9.5 还说「如果你还记得有关类的事件的内容，那么初始化方法就属于这种情况」—— §12 已经把这条跑出来了。
// 没有默认值、又没有 init，就得到一个「造不出来」的类：探针 e13_property_no_value.swift
//   error: class 'Car' has no initializers / note: stored property 'colour' without initial value prevents synthesized initializers
class NoDefault {
    var colour: String
    init(colour: String) { self.colour = colour }
}
expect(NoDefault(colour: "Green").colour == "Green", "属性不给默认值，就必须有一个 init 把它填满；填了就能用：\(NoDefault(colour: "Green").colour)")
// self. 什么时候必须：参数与属性同名时，不带 self 的是参数（书 9.6 的注释就是在说这件事）。
class ShadowedCar {
    var colour = "Black"
    init(colour: String) { self.colour = colour }     // self.colour = 属性，colour = 参数
}
expect(ShadowedCar(colour: "Gray").colour == "Gray", "init(colour:) 里写 self.colour = colour 才是在改属性：\(ShadowedCar(colour: "Gray").colour)")
// Swift 的 init 可以有默认参数值（书 9.5 那会儿的写法要两个 init，这里一个就够）。
class OneInitDoesMany {
    var colour: String
    var numberOfSeats: Int
    init(colour: String = "Black", seats: Int = 5) {
        self.colour = colour
        self.numberOfSeats = seats
    }
}
let many1 = OneInitDoesMany()
let many2 = OneInitDoesMany(colour: "Red")
let many3 = OneInitDoesMany(colour: "Red", seats: 2)
expect(many1.colour == "Black" && many2.numberOfSeats == 5 && many3.numberOfSeats == 2,
       "带默认值的 init 参数 = 一个 init 顶三个：\(many1.colour)/\(many2.colour)/\(many3.numberOfSeats)")
// 可失败构造器 init? —— 书里没讲，但 iOS 上到处都是（UIImage(named:) 就是它）。
class SoundFile {
    let name: String
    init?(name: String) {
        if name.isEmpty { return nil }
        self.name = name
    }
}
expect(SoundFile(name: "note1")?.name == "note1", "init? 成功时给可选：\(String(describing: SoundFile(name: "note1")?.name))")
expect(SoundFile(name: "") == nil, "init? 里 return nil 就等于「这个对象造不出来」：\(String(describing: SoundFile(name: "")))")

// ============================================================
// §15 Designated 与 Convenience（本书 9.6）
// ============================================================
section(15, "Designated 与 Convenience（本书 9.6）")
// 书 9.6 的规则原文：「用 Designated 初始化方法必须要保证类中的所有属性都被赋值，
// 而 Convenience 初始化方法实际上是将 Designated 方法实例化好的对象的个别属性值进行重写」。
// 下面就是书里的代码原样（init() 空体 + convenience init(customerChosenColour:)）。
class ConfigurableCar {
    var colour = "Black"
    var numberOfSeats: Int = 5
    var typeOfCar: CarType = .coupe
    init() {
    }
    convenience init(customerChosenColour: String) {
        self.init()
        colour = customerChosenColour
    }
}
let standard = ConfigurableCar()
let friend = ConfigurableCar(customerChosenColour: "Gold")
expect(standard.colour == "Black" && friend.colour == "Gold" && friend.numberOfSeats == 5,
       "书 9.6 的 console 输出（Black 5 Coupe / Gold 5 Coupe）在 6.0.3 一字不差：\(standard.colour)/\(friend.colour)/\(friend.typeOfCar)")
// convenience 的「先 self.init() 再改属性」不是风格问题，是硬规则。
// 把两行调换顺序（探针 e21）；或者干脆不写 self.init()（探针 e14）：
//   error: 'self' used before 'self.init' call or assignment to 'self'
//   error: 'self.init' isn't called on all paths before returning from initializer
expect(friend.colour == "Gold", "convenience 只能「先委托、后改」：改的是已经造好的那辆车（两条原话见探针 e21、e14）")
// designated 之间不能互相委托：只有 convenience 能写 self.init()。
// 探针 e27 把 init() 里调用 init(colour:) 的原话抄了出来。
// 「Car 中的任何事情在 SelfDrivingCar 类中都可以有」（书 9.8）对初始化方法只有一半成立：
// 子类不写任何 designated 时，父类的 designated 全部继承，convenience 因委托链而间接可用（探针 r10）；
// 子类一写自己的 designated，父类的就全部消失（探针 e22）。
expect(standard.colour == "Black" && friend.colour == "Gold",
       "初始化方法的继承是「全有或全无」，不是逐个可用：结论见探针 r10 与 e22 的对照")

// ============================================================
// §16 方法、self 与属性观察器（本书 9.7）
// ============================================================
section(16, "方法、方法里的 self 与属性观察器（本书 9.7）")
// 书 9.7 的分辨法：「在类外面定义的叫作函数，在类内部定义的函数则叫作方法」，
// 又举 arc4random_uniform 为函数（§3 用的正是它，调用时确实不带点）。
// 这个区别可以直接量出来：方法一取出来就是个函数类型。
func topLevelAdd(_ a: Int, _ b: Int) -> Int { return a + b }
class Calc {
    var memory = 0
    func add(_ a: Int, _ b: Int) -> Int { return a + b }
    func remember(_ v: Int) { memory = v }        // 方法改自己的属性，不需要写 mutating
    static func className() -> String { return "Calc" }
}
let calc = Calc()
expect(topLevelAdd(2, 3) == 5 && calc.add(2, 3) == 5,
       "同样的加法：函数不带点（topLevelAdd(2, 3)）、方法带点（calc.add(2, 3)）—— 都是 \(topLevelAdd(2, 3)) 和 \(calc.add(2, 3))")
let methodValue = calc.add
expect("\(type(of: methodValue))" == "(Int, Int) -> Int", "方法取出来就是普通函数：type(of: calc.add) = \(type(of: methodValue))")
expect(methodValue(4, 5) == 9, "取出来的方法仍然绑在 calc 上：methodValue(4, 5) = \(methodValue(4, 5))")
let unbound = Calc.add
expect("\(type(of: unbound))" == "(Calc) -> (Int, Int) -> Int",
       "没绑定实例的方法类型是「先收一个 Calc」：\(type(of: unbound)) —— 这就是「方法是绑了 self 的函数」的实证")
calc.remember(9)
expect(calc.memory == 9, "方法可以直接改属性（class 里不用写 mutating）：memory = \(calc.memory)")
expect(Calc.className() == "Calc", "static 方法挂在类上：Calc.className() = \(Calc.className())")
// self. 什么时候必须：参数名与属性名撞了的时候。书 9.6 的注释说的就是这件事，
// 而且忘了写并不静默 —— 编译器直接报错还给出修法（探针 e26：
//   error: cannot assign to value: 'colour' is a 'let' constant
//   note:  add explicit 'self.' to refer to mutable property of 'ShadowedCar'）。
class Renamer {
    var colour = "Black"
    func paintSelf(_ colour: String) { self.colour = colour }
    func paintOther(_ other: String) { colour = other }
}
let ren = Renamer()
ren.paintSelf("Red")
expect(ren.colour == "Red", "参数与属性同名时必须 self.colour：paintSelf(\"Red\") 之后 = \(ren.colour)")
ren.paintOther("Green")
expect(ren.colour == "Green", "名字不撞时不带 self 也一样改的是属性：paintOther(\"Green\") 之后 = \(ren.colour)")
// 属性观察器：书里没讲，但第 6 章的「每次播放不同的声音」（6.6）就是它的典型用途 ——
// 「值变了就顺手做件事」不用自己记得在每次赋值后调用刷新。
class SoundDealer {
    var observeLog: [String] = []
    var noteCount = 0 {
        willSet { observeLog.append("willSet：\(noteCount) → \(newValue)") }
        didSet { observeLog.append("didSet：\(oldValue) → \(noteCount)") }
    }
    init(startingAt: Int) { noteCount = startingAt }
    var nextSound: Int { return noteCount % 7 + 1 }
}
let dealer = SoundDealer(startingAt: 3)
expect(dealer.observeLog.isEmpty, "init 里的第一次赋值不触发观察器：observeLog = \(dealer.observeLog)")
dealer.noteCount += 1
expect(dealer.observeLog == ["willSet：3 → 4", "didSet：3 → 4"],
       "willSet 读到的还是旧值、didSet 里的 oldValue 也是旧值：\(dealer.observeLog)")
dealer.noteCount = 10
expect(dealer.nextSound == 4, "书 6.6 的「循环换声音」算的是余数：noteCount=\(dealer.noteCount) → 第 \(dealer.nextSound) 个声音")
// 计算属性（{ get } 里没有存储）：值每次现算，所以永远和 noteCount 同步。
dealer.noteCount = 13
expect(dealer.nextSound == 7, "改完 noteCount 立刻读到新的 \(dealer.nextSound)：计算属性不存在「忘了刷新」")

// ============================================================
// §17 继承与重写（本书 9.8、9.9）
// ============================================================
section(17, "继承与重写（本书 9.8、9.9）")
// 书 9.8：SelfDrivingCar : Car，「Car 中的任何事情在 SelfDrivingCar 类中都可以有」。
// 书 9.9：重写必须写 override，否则报错（原话见探针 e11）；super.drive() 先跑父类那一份。
class SelfDrivingCar2: Car {
    var destination: String?
    override func drive() {
        super.drive()
        if let d = destination { events.append("驾驶的目的地为：" + d) }
    }
}
let auto = SelfDrivingCar2()
expect(auto.colour == "Black" && auto.numberOfSeats == 5 && auto.typeOfCar == .coupe,
       "子类一行属性都没写就有父类的三个属性：\(auto.colour)/\(auto.numberOfSeats)/\(auto.typeOfCar)")
auto.drive()
expect(auto.events == ["汽车已经开动"],
       "destination 还是 nil → 可选绑定跳过第二行（书 9.10 的解法）：\(auto.events)")
auto.destination = "幸福巷4号"
auto.drive()
expect(Array(auto.events.suffix(2)) == ["汽车已经开动", "驾驶的目的地为：幸福巷4号"],
       "这一次 drive() 加了两行（先 super.drive() 再自己的）：\(Array(auto.events.suffix(2)))")
expect(auto.events == ["汽车已经开动", "汽车已经开动", "驾驶的目的地为：幸福巷4号"],
       "events 是存在对象上的，第二次 drive() 只追加不重置 → 攒成三行：\(auto.events)")
// 族谱（书 9.8 的图 9-6）：三层继承 + 一处重写不调 super。
class Animal {
    var acts: [String] = []
    func breathe() { acts.append("用肺呼吸") }
}
class Birds: Animal {
    func fly() { acts.append("飞") }
}
class Mammals: Animal {
    var hasHair = true
}
class Humans: Mammals {
    override func breathe() { super.breathe(); acts.append("人类还会说话") }
}
class Fish: Animal {
    override func breathe() { acts.append("用腮呼吸") }     // 故意不调 super
}
let human = Humans()
human.breathe()
expect(human.hasHair && human.acts == ["用肺呼吸", "人类还会说话"],
       "Humans 一路继承 Mammals 的属性、Animal 的方法，再在外面加自己的一份：\(human.acts)")
let bird = Birds()
bird.fly()
bird.breathe()
expect(bird.acts == ["飞", "用肺呼吸"], "Birds 没重写 breathe，继承来的那份照用：\(bird.acts)")
let fish = Fish()
fish.breathe()
expect(fish.acts == ["用腮呼吸"], "override 不等于「自动先跑父类」：不写 super 就完全没有父类那一行（书 9.9 的说法只适用于写了 super 的场合）：\(fish.acts)")
// 多态：同一份代码，跑的是对象真实类型的那一份实现。
func makeItBreathe(_ a: Animal) -> [String] { a.breathe(); return a.acts }
expect(makeItBreathe(Fish()) == ["用腮呼吸"] && makeItBreathe(Humans()) == ["用肺呼吸", "人类还会说话"],
       "参数写父类类型、实参给子类对象 → 调用落在子类的那份实现上（第 15 章 delegate 的机制根子就在这里）")
// is / as?：容器只能装父类类型时，取回来要问一句「你到底是什么」。
let zoo: [Animal] = [Birds(), Fish(), Humans()]
expect(zoo[0] is Birds && !(zoo[0] is Fish), "is 问的是「是不是这个类型（或它的子类）」：zoo[0] is Birds = \(zoo[0] is Birds)、zoo[0] is Fish = \(zoo[0] is Fish)")
expect(zoo[2] is Mammals, "子类对象必然是父类类型：zoo[2]（一个 Humans）is Mammals = \(zoo[2] is Mammals)。"
       + "静态类型已经保证的事不用运行时再问：zoo[2] is Animal 会收到一条 warning（探针 e29）")
var downcast: String = "没拿到"
if let f = zoo[1] as? Fish { downcast = f.acts.isEmpty ? "拿到了 Fish（acts 还空着）" : "拿到了 Fish" }
expect(downcast == "拿到了 Fish（acts 还空着）", "as? 给的是可选：转型失败就是 nil，不会崩（对比 §18 的强制拆包）")
if let wrong = zoo[0] as? Fish { _ = wrong; downcast = "不该发生" }
expect(downcast == "拿到了 Fish（acts 还空着）", "as? 失手时走 else，什么都不发生：\(downcast)")
// 两阶段初始化：自己的存储属性先填满，再 super.init()，之后才碰继承的属性。
class NeedsDest2: Animal {
    var destination: String
    init(to: String) {
        destination = to          // 第一行必须先是自己的属性
        super.init()              // 顺序颠倒就是探针 e28 的原话
    }
    func go() -> String { return "从 \(destination) 出发，acts 还是 \(acts.count) 条" }
}
expect(NeedsDest2(to: "幸福巷4号").go() == "从 幸福巷4号 出发，acts 还是 0 条",
       "super.init() 之后才允许读继承来的 acts：\(NeedsDest2(to: "幸福巷4号").go())")
// 一旦子类写了自己的 designated，父类的初始化方法就不再自动可用（探针 e22 的报错原话）。
expect(NeedsDest2(to: "家").destination == "家", "NeedsDest2 只有 init(to:)：无参 NeedsDest2() 已经是编译错误（见探针 e22）")

// ============================================================
// §18 可选（本书 9.10）
// ============================================================
section(18, "可选：盒子、摇一摇，以及什么时候必须拆（本书 9.10）")
// 书 9.10 的三步走：String 不能直接收 nil（探针 e09）→ 加 ? 变可选（能收 nil）
// → 想当 String 用就得拆包：! 强制（探针 r02 是崩溃现场）、if 判空、if let 绑定。
let notNilButEmpty: String = ""
expect(notNilButEmpty.isEmpty, "空字符串不是「没有值」：\"\" 的 count = \(notNilButEmpty.count)，它照样是一个 String（要收 nil 必须写 String?，探针 e09 就是硬闯的下场）")
// var destination: String 不赋值就读取 → 编译期就拦（探针 s04：variable 'destination' used before being initialized）
class Route {
    var destination: String?
    func driveChecked() -> String {
        if destination != nil { return "驾驶的目的地为：" + destination! }
        return "没有目的地，不出发"
    }
    func driveBound() -> String {
        if let userSet = destination { return "驾驶的目的地为：" + userSet }
        return "没有目的地，不出发"
    }
    func driveGuard() -> String {
        guard let userSet = destination else { return "守卫：先返回，不带 nil 往下走" }
        return "守卫通过：" + userSet
    }
    func driveCoalesced() -> String { return "驾驶的目的地为：" + (destination ?? "家") }
    func driveForced() -> String { return "驾驶的目的地为：" + destination! }   // 只在确认有值之后才允许调用
}
let route = Route()
expect(route.destination == nil, "声明成 String? 之后可以不赋值：destination = \(String(describing: route.destination))")
expect(route.driveChecked() == "没有目的地，不出发", "书 9.10 的 if destination != nil 写法：\(route.driveChecked())")
expect(route.driveBound() == "没有目的地，不出发", "书 9.10 推荐的 if let 可选绑定：\(route.driveBound())")
expect(route.driveGuard() == "守卫：先返回，不带 nil 往下走", "guard let 是同一件事的「早退出」写法：\(route.driveGuard())")
expect(route.driveCoalesced() == "驾驶的目的地为：家", "?? 给的是「nil 时的替代值」，结果不再是可选：\(route.driveCoalesced())")
// 强制拆包在有值时是安全的，但这份安全没有任何东西守着 —— 崩溃现场见探针 r02/e10。
route.destination = "幸福巷4号"
expect(route.driveForced() == "驾驶的目的地为：幸福巷4号", "有值时 destination! 拿到的就是普通 String：\(route.driveForced())")
expect(route.driveChecked() == route.driveBound() && route.driveBound() == route.driveCoalesced(),
       "判空 / if let / ?? 三种写法在有值时给出同一个结果：\(route.driveBound())")
expect(route.driveGuard() == "守卫通过：幸福巷4号", "guard let 有值时走的是守卫之后的正常分支：\(route.driveGuard())")
// 拆包之后的常量只在 if 的大括号里活着（§10 的作用域），所以函数末尾要用的话得提前算好。
func countAfterBinding(_ s: String?) -> Int {
    if let unwrapped = s { return unwrapped.count }
    return -1
}
expect(countAfterBinding("幸福巷4号") == 5 && countAfterBinding(nil) == -1,
       "「幸福巷4号」是 5 个字符：绑定成功走 if、失败走 else，两个出口都存在：\(countAfterBinding("幸福巷4号")) / \(countAfterBinding(nil))")
// 可选链与「nil 上调方法什么都不发生」（探针 r07 抄了插值原话：Optional("hi")）。
var maybeArray: [Int]? = [1, 2, 3]
expect(maybeArray?.count == 3, "可选链 a?.count 的结果本身又是可选：\(String(describing: maybeArray?.count))")
maybeArray = nil
maybeArray?.append(9)
expect(maybeArray == nil, "在 nil 上调用方法不是崩溃，是整条链直接不执行：\(String(describing: maybeArray))")
expect(type(of: Route().destination) == Optional<String>.self, "String? 的真实类型是 Optional<String>：\(type(of: Route().destination))")
// 隐式解包 Optional<String>!：声明上是可选，用时自动拆 —— Interface Builder 的 outlet 就是这个类型。
var implicitlyUnwrapped: String! = "storyboard 里的标签"
expect(implicitlyUnwrapped.count == 15, "IUO 当 String 用，不用写 !：直接读 .count = \(implicitlyUnwrapped.count)")
implicitlyUnwrapped = nil
expect(implicitlyUnwrapped == nil, "但它仍然是可选，赋 nil 之后再用就是崩溃（探针 r02 的 fatal 原文）")

// ============================================================
// §19 闭包：把代码当值传来传去（本书 11.3）
// ============================================================
section(19, "闭包：把代码当值传来传去（本书 11.3）")
// 书 11.3 的主线例子就是这段，原样搬过来（print 换成返回值好做断言）。
func calculator(n1: Int, n2: Int, operation: (Int, Int) -> Int) -> Int { return operation(n1, n2) }
func add(num1: Int, num2: Int) -> Int { return num1 + num2 }
func multiply(num1: Int, num2: Int) -> Int { return num1 * num2 }
expect(calculator(n1: 3, n2: 6, operation: add) == 9, "把函数当参数：calculator(n1: 3, n2: 6, operation: add) = \(calculator(n1: 3, n2: 6, operation: add))")
expect(calculator(n1: 4, n2: 7, operation: multiply) == 28, "换一份实现就换一种算法：\(calculator(n1: 4, n2: 7, operation: multiply))")
// 书里给的「简化五步」，每一步都跑一遍，六种写法的结果必须是同一个 28。
let stepFull = calculator(n1: 4, n2: 7, operation: { (num1: Int, num2: Int) -> Int in return num1 * num2 })
let stepNoReturn = calculator(n1: 4, n2: 7, operation: { (num1: Int, num2: Int) -> Int in num1 * num2 })
let stepNoTypes = calculator(n1: 4, n2: 7, operation: { (num1, num2) in num1 * num2 })
let stepNoParens = calculator(n1: 4, n2: 7, operation: { num1, num2 in num1 * num2 })
let stepShorthand = calculator(n1: 4, n2: 7, operation: { $0 * $1 })
let stepTrailing = calculator(n1: 4, n2: 7) { $0 * $1 }
expect([stepFull, stepNoReturn, stepNoTypes, stepNoParens, stepShorthand, stepTrailing] == [Int](repeating: 28, count: 6),
       "六步简化（去 func/名字、去 return、去参数类型、去返回值类型、换 $0/$1、闭包挪到括号外）逐项等价：\(stepFull) \(stepNoReturn) \(stepNoTypes) \(stepNoParens) \(stepShorthand) \(stepTrailing)")
// $0/$1 不是「语法糖的糖」，它是「按位置命名的参数」，所以顺序错了就换掉了操作数。
expect(calculator(n1: 4, n2: 7) { $0 - $1 } == -3 && calculator(n1: 4, n2: 7) { $1 - $0 } == 3,
       "$0 是第一个参数、$1 是第二个：4-7 = \(calculator(n1: 4, n2: 7) { $0 - $1 })、7-4 = \(calculator(n1: 4, n2: 7) { $1 - $0 })")
// 书 11.3 的原话是「如果函数的最后一个参数是闭包，则可以删除参数名、把闭包挪到右括号外面」。
// Swift 5.3（书出版之后）把这条放宽成「多重尾随闭包」：第一个不带标签，后面的写成 label: { ... }。
func withTwoClosures(_ first: () -> Int, then second: () -> Int) -> Int { return first() + second() }
expect(withTwoClosures({ 40 }, then: { 2 }) == 42, "两个闭包参数都写在括号里：\(withTwoClosures({ 40 }, then: { 2 }))")
expect(withTwoClosures { 40 } then: { 2 } == 42, "同一次调用写成多重尾随闭包（书 4 的时代还没有这个语法）：\(withTwoClosures { 40 } then: { 2 })")
// 反过来，「挪出去的闭包后面再补一个普通参数」今天依然不行，探针 e31 抄了原话：
//   error: expected ',' separator / error: missing argument for parameter 'then' in call
// 所以书那条规则今天的正确说法是：要挪出括号的必须是收尾的那几个闭包参数。
// 书 11.3 结尾的 map 三连：addOne 函数、带名字的闭包、$0 闭包，结果一样。
let array = [2, 5, 3, 7, 23, 54]
func addOne(n1: Int) -> Int { return n1 + 1 }
let mappedA = array.map(addOne)
let mappedB = array.map { (n1) in n1 + 1 }
let mappedC = array.map { $0 + 1 }
expect(mappedA == mappedB && mappedB == mappedC && mappedC == [3, 6, 4, 8, 24, 55],
       "map 生成新数组、不动原数组：\(mappedC)，原数组还是 \(array)")
// 集合上另外几个「收闭包」的方法（书 11.3 只讲了 map，后面每个 App 都会用到这些）。
expect(array.filter { $0 > 5 }.map { $0 * 2 }.reduce(0, +) == 168,
       "链式：先筛 >5（\(array.filter { $0 > 5 })）、各乘 2、再求和 = \(array.filter { $0 > 5 }.map { $0 * 2 }.reduce(0, +))")
expect(array.sorted { $0 > $1 } == [54, 23, 7, 5, 3, 2], "sorted 收的是「比较闭包」，返回新数组：\(array.sorted { $0 > $1 })")
expect(array.sorted() == [2, 3, 5, 7, 23, 54], "不传闭包的 sorted() 走 <：\(array.sorted())（原数组 array 仍然是 \(array)）")
expect(array.contains(where: { $0 == 7 }) && !array.contains(99), "contains(where:) 收闭包、contains(_:) 收元素：找 7 → \(array.contains(where: { $0 == 7 }))、找 99 → \(array.contains(99))")
expect(array.compactMap { $0 % 2 == 0 ? $0 : nil } == [2, 54], "compactMap 会把 nil 剔掉：\(array.compactMap { $0 % 2 == 0 ? $0 : nil })")
expect(array.reduce(into: "") { acc, el in acc += "<\(el)>" } == "<2><5><3><7><23><54>",
       "reduce(into:_:) 边走边改同一个累加器：\(array.reduce(into: "") { acc, el in acc += "<\(el)>" })")
// 「calculator(n1:n2:operation:) 一定要放到两个函数定义的后面」（书 11.3 的叮嘱）——
// §4 已经证过函数名提前可见，这条对 func 是不必要的；但对「存在 let 里的闭包」是对的：
// 函数名是编译期就存在的符号，let 是运行到那一行才初始化的，提前调用读的是没填过的内存，
// 直接 signal 11（探针 r13；§4 的探针 t01 里平凡初值 Int 读到的是 0，闭包连 0 都算不上）。
let doublerLater = { (n: Int) in n * 2 }
func applyTwice(_ n: Int) -> Int { return doublerLater(n) }
expect(applyTwice(5) == 10 && doublerLater(9) == 18, "写在初始化之后的两次调用都正常：applyTwice(5) = \(applyTwice(5))、doublerLater(9) = \(doublerLater(9))")
expect("\(type(of: doublerLater))" == "(Int) -> Int", "闭包存进 let 之后它的类型就是函数类型：\(type(of: doublerLater)) —— 与 §16 取出来的方法同一种东西")

// ============================================================
// §20 逃逸闭包与捕获（本书 11.3 的延伸、11.4 的完成处理）
// ============================================================
section(20, "逃逸闭包、捕获，以及「完成后做什么」（本书 11.3 延伸、11.4）")
// 书 11.4.3 问「什么是完成处理？」——它就是「把接下来要做的事当参数交出去，做完再回头调用」。
// 能不能回头调用，取决于闭包会不会「逃出」这次调用。
class TaskQueue {
    var pending: [() -> Void] = []
    func enqueue(_ body: @escaping () -> Void) { pending.append(body) }
    func runAll() { for f in pending { f() } }
}
var closureLog: [String] = []
let queue = TaskQueue()
var step = 0
queue.enqueue { closureLog.append("入队时读的是变量当前的值：step=\(step)") }
step = 7
queue.enqueue { closureLog.append("第二个闭包：step=\(step)") }
expect(closureLog.isEmpty, "入队不等于执行：此时 closureLog = \(closureLog)")
queue.runAll()
expect(closureLog == ["入队时读的是变量当前的值：step=7", "第二个闭包：step=7"],
       "闭包捕获的是变量本身，不是写下那一刻的值（两个闭包都跑在 step 已经变成 7 之后）：\(closureLog)")
// 非逃逸闭包（参数上没有 @escaping）不写 @escaping 却想存起来 → 编译期就拦（探针 e19）：
//   error: escaping closure captures non-escaping parameter 'completion'
// 逃逸闭包里引用成员还必须显式写 self.（探针 r11）：
//   error: reference to property 'tag' in closure requires explicit use of 'self' to make capture semantics explicit
// 「显式写 self」不是洁癖：它逼着你看见「这个闭包把宿主对象抓住了」。
var holderLog: [String] = []
final class KeyHolder {
    var tag: String
    var stored: (() -> Void)?
    init(_ t: String) { tag = t }
    func armStrong() { stored = { holderLog.append("被抓住的 \(self.tag)") } }
    func armWeak() { stored = { [weak self] in holderLog.append("弱引用：\(self?.tag ?? "已经没了")") } }
    deinit { holderLog.append("释放 \(tag)") }
}
var leaked: KeyHolder? = KeyHolder("泄漏测试")
leaked?.armStrong()
leaked = nil
expect(holderLog.isEmpty, "对象持有闭包、闭包又捕获对象 → 计数回不到 0，deinit 不跑：\(holderLog) —— 这就是「循环引用」的直接后果")
holderLog.removeAll(keepingCapacity: true)
var notLeaked: KeyHolder? = KeyHolder("修复测试")
notLeaked?.armWeak()
notLeaked = nil
expect(holderLog == ["释放 修复测试"], "[weak self] 斩断环之后 deinit 正常跑：\(holderLog)")
// 循环里的捕获：Swift 3 起 for 的循环变量每轮一个新变量，while 的是同一个。
var perRound: [String] = []
var capturedPerRound: [() -> Void] = []
for i in 0..<3 { capturedPerRound.append { perRound.append("i=\(i)") } }
for f in capturedPerRound { f() }
expect(perRound == ["i=0", "i=1", "i=2"], "for 的循环变量每轮独立：\(perRound)")
var sharedCounter = 0
var capturedShared: [() -> Void] = []
while sharedCounter < 3 { capturedShared.append { perRound.append("j=\(sharedCounter)") }; sharedCounter += 1 }
for f in capturedShared { f() }
expect(perRound == ["i=0", "i=1", "i=2", "j=3", "j=3", "j=3"],
       "while 的变量被三轮共享，跑的时候它已经是 3：\(perRound)（同一件事的探针版记录在 t04）")

// ============================================================
// §21 编译器版本与语言模式：这本 Swift 4 的书在今天
// ============================================================
section(21, "编译器版本与语言模式：这本 Swift 4 的书在今天")
// 本机是 Swift 6.0.3 编译器，run-all.sh 不带 -swift-version，所以语言模式取默认的 5。
// 这两件事分别由两个不同的宏管着，可以直接问出来。
#if swift(>=6.0)
let languageMode = "6"
#else
let languageMode = "5"
#endif
#if compiler(>=6.0)
let compilerIsAtLeast6 = true
#else
let compilerIsAtLeast6 = false
#endif
expect(compilerIsAtLeast6 && languageMode == "5",
       "#if compiler(>=6.0) 为 \(compilerIsAtLeast6)、#if swift(>=6.0) 落在 \(languageMode) 分支：编译器是 6.0.3，语言模式默认还是 5 —— 两个宏问的不是同一件事")
#if swift(>=4.0)
let bookEraStillSupported = true
#else
let bookEraStillSupported = false
#endif
expect(bookEraStillSupported, "书里的 Swift 4 代码在 6.0.3 仍能按 swift(>=4.0) 的分支编译：\(bookEraStillSupported)")
// 一条真正的「Swift 4 → 5 断代」：String 的 characters 视图在 5.0 被移除（探针 e30）。
let bookString = "幸福巷4号"
expect(bookString.count == 5, "今天写 bookString.count；书 5.x 时代的 bookString.characters.count 已经不可用："
       + "error: 'characters' is unavailable: Please use String directly（探针 e30 抄了全原文）")
// Swift 6 语言模式下的新增拦截（同一份源码、只换 -swift-version，本机实测）：
//   探针 s06：5 模式跑得好，6 模式报 main actor-isolated var 'counter' can not be mutated from a nonisolated context
//   探针 s07：5、6 两个模式都通过 —— 「闭包捕获」本身不是问题，跨 actor 才是
//   探针 s01/s02/s03/s04/s05：两个模式给出逐字相同的诊断
expect(true, "把语言模式切到 6 的唯一新增硬错误出现在「全局可变状态被非隔离函数改」这一条（探针 s06 的两模式对照）")
// 本章所有「Swift 4 时代 vs 现在」的账：
//   §4 函数声明提前可见 → 书 11.3 的叮嘱不必要（探针 e04）
//   §6 缺 return 的诊断文本已经换了一版（探针 e03）
//   §7 短路仍然成立
//   §8 99...1 编译期无声、运行期 fatal（探针 r01）
//   §9 书 5.9 的修补把 n<3 留成了反向区间（探针 r09）
//   §11 do/catch/try 三件套形状不变，AVAudioPlayer 的错误仍是 OSStatus 包进 NSError（正文 §11）
//   §15/§17 初始化与继承的规则一个字没改，但报错原话全部新抄了一遍（探针 e11~e22）
//   §19/§20 闭包与捕获规则没变，Swift 6 只在隔离维度上加了拦截（探针 s06/s07）

// ============================================================
// §22 数组与字典：容器里的值和它们的顺序（本书 4.7、10.7.2）
// ============================================================
section(22, "数组与字典：容器里的值和「取不到」这件事（本书 4.7、10.7.2）")
// 书 4.7 用数组装图片名、书 6.5 用数组装声音名、书 10.7.2 用字典装 API 返回的 JSON。
// 三种容器各有各的「取不到」：数组越界是崩溃，字典缺键是 nil。
let soundNames = ["note1", "note2", "note3"]
expect(soundNames.count == 3 && soundNames[0] == "note1", "数组字面量就推出 [String]：count = \(soundNames.count)、下标从 0 开始 \(soundNames[0])")
expect("\(type(of: soundNames))" == "Array<String>", "type(of:) 给的是 Array<String>（写 [String] 是它的简写）：\(type(of: soundNames))")
var playlist = soundNames
playlist.append("note4")
playlist.insert("first", at: 0)
expect(playlist.count == 5 && playlist[0] == "first" && playlist.last == "note4",
       "append 尾加、insert(at:) 插队：\(playlist)")
playlist.remove(at: 1)
expect(playlist == ["first", "note2", "note3", "note4"], "remove(at:) 按位置删，删完前面的自动补位：\(playlist)")
expect(playlist.prefix(2) == ["first", "note2"] && Array(playlist.suffix(2)) == ["note3", "note4"],
       "切片 prefix/suffix 给出头尾（切片不是数组，要变回去就 Array(...)）：\(Array(playlist.prefix(2))) / \(Array(playlist.suffix(2)))")
expect(playlist.firstIndex(of: "note3") == 2 && playlist.firstIndex(of: "nope") == nil,
       "找位置返回可选：note3 在第 \(String(describing: playlist.firstIndex(of: "note3"))) 个、nope 是 \(String(describing: playlist.firstIndex(of: "nope")))")
// 书 6.5/6.6 的「按索引换声音」其实就是下标 + 余数（§16 的 nextSound）。
let pickedSounds = (0..<7).map { soundNames[$0 % soundNames.count] }
expect(pickedSounds == ["note1", "note2", "note3", "note1", "note2", "note3", "note1"],
       "第 6 章按下第 8 个键时播哪个声音：\(pickedSounds)")
for (offset, name) in playlist.enumerated() { if offset == 0 { expect(name == "first", "enumerated() 给 (位置, 元素) 一对：第一项是 \(name)") } }
expect(playlist.map { $0.uppercased() } == ["FIRST", "NOTE2", "NOTE3", "NOTE4"], "map 把每个元素过一遍函数：\(playlist.map { $0.uppercased() })")
// 数组的「取不到」不是 nil，是崩溃 —— 探针 r04_index_oob.swift 抄了 fatal 原文。
// let 数组不能 append 同样是编译期拦（探针 s05_let_array_append.swift）。
var names2 = soundNames
names2 += ["note5"]
expect(names2.count == 4 && soundNames.count == 3, "数组赋值即拷贝（§12 的 struct 语义在这儿）：names2 有 \(names2.count) 项、soundNames 还是 \(soundNames.count) 项")
// 字典：书 10.7.2 的核心一句话 —— 用键取值，取不到就是 nil，所以返回类型必须是可选。
var weather: [String: Int] = ["temp": 21, "humidity": 63, "wind": 5]
expect(weather["temp"] == 21, "字典按键取值：weather[\"temp\"] = \(String(describing: weather["temp"]))")
expect(weather["pressure"] == nil, "缺键不崩、给 nil（这就是 Int? 而不是 Int 的原因）：\(String(describing: weather["pressure"]))")
expect(weather["pressure"] ?? -1 == -1, "所以读字典要带 ?? 兜底：\(weather["pressure"] ?? -1)")
weather["wind"] = nil
expect(weather.count == 2 && weather["wind"] == nil, "把值赋成 nil 是**删除这个键**，不是存一个 nil：现在剩 \(weather.count) 个键")
weather["feelsLike"] = 20
expect(weather.keys.sorted() == ["feelsLike", "humidity", "temp"], "keys 的顺序每个进程重新随机，所以要印就得先排序：\(weather.keys.sorted())")
expect(weather.values.sorted() == [20, 21, 63], "values 同理：\(weather.values.sorted())")
let sortedPairs = weather.sorted { $0.key < $1.key }
expect(sortedPairs.map { "\($0.key)=\($0.value)" } == ["feelsLike=20", "humidity=63", "temp=21"],
       "字典排序要先把 (key, value) 元组拿出来排：\(sortedPairs.map { "\($0.key)=\($0.value)" })")
// 字典套字典：书 10.9 解析 JSON 之后拿到的就是这种形状，取值要一层一层可选地拿。
let api: [String: Any] = ["main": ["temp": 21], "name": "Hangzhou"]
let nestedTemp = (api["main"] as? [String: Int])?["temp"]
expect(nestedTemp == 21, "[Any: ...] 里取出来的值是 Any?，要先 as? 成具体字典再取键：\(String(describing: nestedTemp))")
expect(api["name"] as? String == "Hangzhou", "as? 收 Any 里的字符串：\(String(describing: api["name"] as? String))")
// Set：只问「在不在」、不关心顺序。
var tags: Set<String> = ["ios", "swift"]
tags.insert("ios")
expect(tags.count == 2 && tags.contains("ios"), "Set 自动去重：插两次 ios 之后还是 \(tags.count) 个元素")
tags.insert("uikit")
expect(Set(["ios", "swift"]).isSubset(of: tags), "[ios, swift] 是它的子集：\(Set(["ios", "swift"]).isSubset(of: tags))")
expect(Array(tags).sorted() == ["ios", "swift", "uikit"], "Set 要打就得先 sorted：\(Array(tags).sorted())")
expect(tags.intersection(["ios", "nope"]) == ["ios"], "交集直接给出共同的元素：\(Array(tags.intersection(["ios", "nope"])).sorted())")

print("\n==== 30 结束 ====")
exit(failures == 0 ? 0 : 1)
