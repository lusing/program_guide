// 04 · 控制流——guard、switch 穷尽与模式匹配、Range、循环、标签跳转

import Foundation

// ═══ 4.1 纯函数区（供测试）
func diceName(_ pips: Int) -> String {
    switch pips {
    case 1: return "一点"
    case 2: return "二点"
    case 3: return "三点"
    case 4: return "四点"
    case 5: return "五点"
    case 6: return "六点"
    default: return "不是骰子"
    }
}

func quadrant(x: Double, y: Double) -> String {
    switch (x, y) {
    case (0, 0): return "原点"
    case (let px, 0) where px != 0: return "x 轴"
    case (0, _): return "y 轴"
    case (let px, let py) where px > 0 && py > 0: return "第一象限"
    case (let px, let py) where px < 0 && py > 0: return "第二象限"
    case (let px, let py) where px < 0 && py < 0: return "第三象限"
    default: return "第四象限"
    }
}

func scoreLevel(_ score: Int) -> String {
    switch score {
    case ..<60: return "不及格"
    case 60..<80: return "及格"
    case 80..<90: return "良好"
    case 90...: return "优秀"
    default: fatalError("unreachable")
    }
}

/// guard 提前退出：解包后的值在函数余下部分持续可用（对比 if let 的作用域局限）
func describeTraffic(light: String?) -> String {
    guard let light, !light.isEmpty else { return "没有信号" }
    return "信号灯是\(light)"
}

func fizzBuzz(_ n: Int) -> String {
    switch (n % 3, n % 5) {
    case (0, 0): return "FizzBuzz"
    case (0, _): return "Fizz"
    case (_, 0): return "Buzz"
    default: return "\(n)"
    }
}

// ═══ 4.2 switch：穷尽 + 值绑定 + where + 区间
print("掷出 5 → \(diceName(5))")
print("(−1, 2) 在\(quadrant(x: -1, y: 2))")
print("分数 85 → \(scoreLevel(85))")
print("describeTraffic(nil) → \(describeTraffic(light: nil))")
print("describeTraffic(\"红\") → \(describeTraffic(light: "红"))")

// ═══ 4.3 元组模式匹配：FizzBuzz 的无 if 版本
let fizzList = (1...15).map(fizzBuzz).joined(separator: " ")
print("1…15 → \(fizzList)")

// ═══ 4.4 for-in 与 Range 家族（闭区间 / 半开 / stride）
var sum = 0
for i in 1...100 { sum += i }
precondition(sum == 5050, "高斯断言失败")
let evens = stride(from: 0, through: 10, by: 2).map { $0 }
print("偶数 stride：\(evens)")
let letters = Array("甲乙丙丁")
for (index, char) in letters.enumerated() {
    print("第 \(index + 1) 位：\(char)", terminator: " ")
}
print("")

// ═══ 4.5 while / repeat-while（至少执行一次）
var remaining = 3
var countdown: [String] = []
while remaining > 0 {
    countdown.append("\(remaining)")
    remaining -= 1
}
var attempts = 0
repeat { attempts += 1 } while attempts < 3
print("countdown=\(countdown.joined(separator: ","))  attempts=\(attempts)")

// ═══ 4.6 标签跳转：多层循环一次break
var hit: String?
outer: for i in 1...5 {
    for j in 1...5 {
        if i * j >= 12 {
            hit = "\(i)×\(j)"
            break outer
        }
    }
}
print("首个积≥12 的组合：\(hit ?? "无")")

// ═══ 4.7 三元与 ??（06 章深讲可选）
let name: String? = nil
print("访客：\(name ?? "匿名")")

print("==== 04 结束 ====")
